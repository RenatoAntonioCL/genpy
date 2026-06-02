#!/usr/bin/env bash
set -euo pipefail

[[ -n "${_GENPY_REVIEW_LOADED:-}" ]] && return 0
_GENPY_REVIEW_LOADED=1

# =============================================================================
# GenPy — lib/review.sh (v1.0.0-alpha)
#
# Orquestador genpy review — flujo de 10 pasos (ARCHITECTURE.md §5.4).
#
# Uso:
#   genpy review ARCHIVO [SELECTOR] [OPCIONES]
#
# SELECTOR (uno de):
#   --lines N-M              Rango de líneas
#   --function NOMBRE        Función top-level
#   --class NOMBRE           Clase top-level
#   --method CLASE.METODO    Método dentro de una clase
#
# OPCIONES:
#   --goal TEXTO             Objetivo de revisión (default: genérico)
#   --provider ollama|api    Provider IA (default: ollama)
#   --model NOMBRE           Forzar modelo específico (equivale a GENPY_MODEL)
#
# Variables de entorno para testing / CI:
#   GENPY_REVIEW_NON_INTERACTIVE=1   Auto-acepta el diff en paso [9]
#   GUARDIAN_NON_INTERACTIVE=1       Auto-aborta en guardianes (ver guardians.sh)
# =============================================================================

# ─── API pública ──────────────────────────────────────────────────────────────

genpy_review() {
  local target_file=""
  local selector_mode=""
  local selector_target=""
  local goal="Mejorar la calidad, legibilidad y robustez del código"
  local provider="${GENPY_PROVIDER:-ollama}"

  # ── Parseo de argumentos ────────────────────────────────────────────────────
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --lines|--function|--class|--method)
        selector_mode="$1"; shift
        if [[ $# -eq 0 ]]; then
          echo "Error: falta el argumento para $selector_mode" >&2
          _review_usage; return 1
        fi
        selector_target="$1"; shift
        ;;
      --goal)
        shift
        if [[ $# -eq 0 ]]; then
          echo "Error: falta el texto del objetivo" >&2
          return 1
        fi
        goal="$1"; shift
        ;;
      --provider)
        shift
        if [[ $# -eq 0 ]]; then
          echo "Error: falta el nombre del provider" >&2
          return 1
        fi
        provider="$1"; shift
        ;;
      --model)
        shift
        if [[ $# -eq 0 ]]; then
          echo "Error: falta el nombre del modelo" >&2
          return 1
        fi
        export GENPY_MODEL="$1"; shift
        ;;
      -*)
        echo "Error: opción desconocida: $1" >&2
        _review_usage; return 1
        ;;
      *)
        if [[ -z "$target_file" ]]; then
          target_file="$1"; shift
        else
          echo "Error: argumento inesperado: $1" >&2
          _review_usage; return 1
        fi
        ;;
    esac
  done

  if [[ -z "$target_file" ]]; then
    _review_usage; return 1
  fi

  # Resolver ruta absoluta del archivo
  target_file="$(_review_abspath "$target_file")" || return 1

  if [[ ! -f "$target_file" ]]; then
    echo "Error: archivo no encontrado: $target_file" >&2
    return 1
  fi

  # Sin selector: revisar el archivo completo
  if [[ -z "$selector_mode" ]]; then
    selector_mode="--lines"
    selector_target="1-$(awk 'END {print NR}' "$target_file")"
  fi

  # ── Cargar módulos ──────────────────────────────────────────────────────────
  source "${LIB_DIR:?}/core/errors.sh"
  source "${LIB_DIR}/utils.sh"
  source "${LIB_DIR}/resolver.sh"
  source "${LIB_DIR}/assembler.sh"
  source "${LIB_DIR}/guardians.sh"
  source "${LIB_DIR}/git_manager.sh"
  # preflight.sh solo si la función no está ya definida (permite mock en tests)
  if ! declare -f preflight_mode_review &>/dev/null; then
    source "${LIB_DIR}/core/preflight.sh"
  fi

  # Cargar provider solo si ai_complete no está ya definida (permite inyección
  # del mock en tests pre-sourciando ollama_mock.sh antes de llamar genpy_review)
  if ! declare -f ai_complete &>/dev/null; then
    case "$provider" in
      ollama) source "${LIB_DIR}/providers/ollama.sh" ;;
      api)    source "${LIB_DIR}/providers/api.sh" ;;
      *)
        echo "Error: provider desconocido: '$provider'. Válidos: ollama, api" >&2
        return 1
        ;;
    esac
  fi

  # Detectar strategy
  local strategy_file
  strategy_file=$(_review_detect_strategy "$target_file") || return 1

  # Project dir = raíz git
  local project_dir
  project_dir=$(git rev-parse --show-toplevel 2>/dev/null) || {
    echo "Error: no se encontró un repositorio git en o por encima de $(dirname "$target_file")" >&2
    return 1
  }

  # ── [0] Preflight ───────────────────────────────────────────────────────────
  preflight_mode_review || return 1

  # ── Setup temp dir ──────────────────────────────────────────────────────────
  local tmpdir
  tmpdir=$(mktemp -d)
  export GENPY_CLEANUP_DIR="$tmpdir"

  local context_file="$tmpdir/context.txt"
  local focal_chunk_file="$tmpdir/focal_chunk.tmp"
  local prompt_file="$tmpdir/prompt.txt"
  local ai_output_file="$tmpdir/ai_output.tmp"
  local reassembled_file="$tmpdir/reassembled.tmp"
  local diff_file="$tmpdir/review.diff"

  # ── [1] Cargar strategy ─────────────────────────────────────────────────────
  print_section "Revisión IA — $(basename "$target_file")"
  # shellcheck source=/dev/null
  source "$strategy_file"

  # ── [2] Git checkpoint ──────────────────────────────────────────────────────
  create_checkpoint "$project_dir" || return 1

  # ── [3] Resolver rango ──────────────────────────────────────────────────────
  resolve_range "$selector_mode" "$selector_target" "$target_file" || {
    rollback_to_checkpoint "$project_dir"
    return 1
  }
  print_info "Fragmento: líneas ${RESOLVE_START}–${RESOLVE_END} de $(basename "$target_file")"

  # Extraer el focal chunk
  sed -n "${RESOLVE_START},${RESOLVE_END}p" "$target_file" > "$focal_chunk_file"

  # ── [4] Build context ───────────────────────────────────────────────────────
  build_review_context "$target_file" "$strategy_file" > "$context_file"

  # ── [5] Assemble prompt ─────────────────────────────────────────────────────
  assemble_prompt "$context_file" "$focal_chunk_file" "$goal" > "$prompt_file"

  # ── [6–7] Bucle IA + Guardianes ─────────────────────────────────────────────
  local retries_done=0
  while true; do
    show_progress "Enviando fragmento al modelo"

    local ai_rc=0
    ai_complete "$prompt_file" "$ai_output_file" || ai_rc=$?
    printf '\r\033[K'  # limpiar la línea de progreso

    case "$ai_rc" in
      0) ;;
      3)
        rollback_to_checkpoint "$project_dir"
        print_error "Timeout esperando la respuesta del modelo (${OLLAMA_TIMEOUT:-120}s)."
        return 1
        ;;
      *)
        rollback_to_checkpoint "$project_dir"
        print_error "El provider falló (rc=${ai_rc}). ¿Está Ollama en ejecución?"
        return 1
        ;;
    esac

    local grd_rc=0
    run_guardians \
      "$ai_output_file" "$focal_chunk_file" "$strategy_file" "$retries_done" \
      || grd_rc=$?

    case "$grd_rc" in
      0) break ;;
      2)
        retries_done=$(( retries_done + 1 ))
        continue
        ;;
      *)
        rollback_to_checkpoint "$project_dir"
        print_warning "Revisión abortada."
        return 1
        ;;
    esac
  done

  # ── [8] Re-ensamblado + validación de sintaxis completa ─────────────────────
  reassemble_file \
    "$target_file" "$ai_output_file" "$RESOLVE_START" "$RESOLVE_END" \
    > "$reassembled_file"

  if declare -f validate_syntax &>/dev/null; then
    if ! validate_syntax "$reassembled_file" 2>/dev/null; then
      print_warning "El archivo reensamblado tiene errores de sintaxis."
      if [[ "${GENPY_REVIEW_NON_INTERACTIVE:-0}" != "1" && -t 0 ]]; then
        printf '  [A]bortar  [E]ditar manualmente → '
        local syn_choice; IFS= read -r syn_choice
        syn_choice="${syn_choice^^}"
        if [[ "$syn_choice" == "E" ]]; then
          "${EDITOR:-vi}" "$reassembled_file"
        else
          rollback_to_checkpoint "$project_dir"
          return 1
        fi
      else
        rollback_to_checkpoint "$project_dir"
        return 1
      fi
    fi
  fi

  # ── [9] Diff visual + confirmación ──────────────────────────────────────────
  diff -u "$target_file" "$reassembled_file" > "$diff_file" || true

  if [[ ! -s "$diff_file" ]]; then
    print_warning "El modelo no introdujo cambios en el fragmento."
    rollback_to_checkpoint "$project_dir"
    return 0
  fi

  printf '\n'
  if [[ "${GENPY_REVIEW_NON_INTERACTIVE:-0}" != "1" && -t 1 ]] \
     && command -v less &>/dev/null; then
    diff --color=always -u "$target_file" "$reassembled_file" | less -R || true
  else
    cat "$diff_file"
  fi

  local final_choice="A"
  if [[ "${GENPY_REVIEW_NON_INTERACTIVE:-0}" != "1" && -t 0 ]]; then
    printf '\n  [A]ceptar cambios  [R]echazar  [E]ditar → '
    IFS= read -r final_choice
    final_choice="${final_choice^^}"
  fi

  # ── [10] Aplicar o revertir ──────────────────────────────────────────────────
  case "$final_choice" in
    A|"")
      _review_apply "$project_dir" "$target_file" "$reassembled_file"
      ;;
    E)
      "${EDITOR:-vi}" "$reassembled_file"
      _review_apply "$project_dir" "$target_file" "$reassembled_file"
      ;;
    *)
      rollback_to_checkpoint "$project_dir"
      print_warning "Revisión rechazada. Restaurado el estado original."
      ;;
  esac
}

# ─── Internos ─────────────────────────────────────────────────────────────────

_review_apply() {
  local project_dir="$1" target_file="$2" reassembled_file="$3"

  cp "$reassembled_file" "$target_file"

  local relative_file="${target_file#${project_dir}/}"
  git -C "$project_dir" add "$relative_file"
  git -C "$project_dir" commit -q \
    -m "chore(genpy): review applied to ${relative_file}"

  print_success "Cambios aplicados y commiteados en '${CHECKPOINT_BRANCH}'."
  print_info   "Para integrar: git checkout <rama-base> && git merge ${CHECKPOINT_BRANCH}"
}

# Detecta la strategy a partir del blueprint.toml o la extensión del archivo
_review_detect_strategy() {
  local file="$1"
  local lib_dir="${LIB_DIR:?}"

  # 1. Intentar leer language del blueprint.toml del proyecto actual
  local toml=".genpy/blueprint.toml"
  if [[ -f "$toml" ]]; then
    local lang
    lang=$(grep -E '^language[[:space:]]*=' "$toml" 2>/dev/null | head -1 \
      | sed 's/.*=[[:space:]]*//' | tr -d '"'"'" | tr -d '[:space:]') || true
    if [[ -n "$lang" ]]; then
      local strategy="${lib_dir}/review_strategies/${lang}.sh"
      if [[ -f "$strategy" ]]; then
        echo "$strategy"; return 0
      fi
    fi
  fi

  # 2. Fallback: extensión del archivo
  local ext="${file##*.}"
  local strategy
  case "$ext" in
    py)            strategy="${lib_dir}/review_strategies/python.sh" ;;
    go)            strategy="${lib_dir}/review_strategies/go.sh" ;;
    js|ts|jsx|tsx) strategy="${lib_dir}/review_strategies/javascript.sh" ;;
    *)
      echo "Error: no se pudo detectar el lenguaje para '${file}'" >&2
      echo "  Usa un blueprint.toml con [meta] language = <lenguaje>" >&2
      return 1
      ;;
  esac

  if [[ ! -f "$strategy" ]]; then
    echo "Error: strategy no encontrada: $strategy" >&2
    return 1
  fi

  echo "$strategy"
}

# Resuelve ruta absoluta portable (misma lógica que bin/genpy _resolve_path)
_review_abspath() {
  local target="$1"
  if command -v realpath &>/dev/null; then
    realpath "$target"
  elif readlink -f "$target" &>/dev/null 2>&1; then
    readlink -f "$target"
  else
    local dir file
    dir="$(cd "$(dirname "$target")" && pwd)"
    file="$(basename "$target")"
    echo "${dir}/${file}"
  fi
}

_review_usage() {
  cat >&2 <<'EOF'
Uso: genpy review ARCHIVO [SELECTOR] [OPCIONES]

SELECTOR (uno de):
  --lines N-M              Rango de líneas (ej: 10-50)
  --function NOMBRE        Función top-level
  --class NOMBRE           Clase top-level
  --method CLASE.METODO    Método dentro de una clase

OPCIONES:
  --goal TEXTO             Objetivo de revisión
  --provider ollama|api    Provider IA (default: ollama)
  --model NOMBRE           Forzar modelo específico

Ejemplos:
  genpy review app.py --function create_user
  genpy review main.py --lines 10-50 --goal "Mejorar manejo de errores"
  genpy review models.py --class UserModel
EOF
}
