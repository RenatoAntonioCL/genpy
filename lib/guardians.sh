#!/usr/bin/env bash
set -euo pipefail

# Include guard
[[ -n "${_GENPY_GUARDIANS_LOADED:-}" ]] && return 0
_GENPY_GUARDIANS_LOADED=1

# =============================================================================
# GenPy — lib/guardians.sh (v1.0.0-alpha)
#
# Ejecuta los 5 guardianes de validación del output IA, del más barato al
# más caro (ARCHITECTURE.md §5.4 paso [7], decisión B3).
#
# API pública
#   run_guardians CHUNK ORIG STRATEGY [RETRIES_DONE]
#     CHUNK        — archivo con el output del modelo (focal_chunk.tmp)
#     ORIG         — chunk original antes de enviarlo al modelo
#     STRATEGY     — ruta a review_strategies/python.sh (u otro lenguaje)
#     RETRIES_DONE — reintentos de IA ya consumidos (default 0)
#     Retorna: 0=todos pasan, 1=abort, 2=retry (caller re-ejecuta IA)
#
#   guardian_g1_not_empty  CHUNK
#   guardian_g2_no_markdown CHUNK
#   guardian_g3_line_count  CHUNK ORIG
#   guardian_g4_syntax      CHUNK STRATEGY
#   guardian_g5_signatures  CHUNK ORIG STRATEGY
#     Retornan: 0=pass, 1=fail
#     En fallo: establecen GUARDIAN_FAILED_GATE y GUARDIAN_FAILED_DETAIL
#
# Globales de configuración
#   GUARDIAN_MAX_RETRIES    — máx reintentos de IA permitidos (default 2)
#   GUARDIAN_NON_INTERACTIVE=1 — fuerza auto-abort sin prompt (tests/CI)
#
# Globales de salida
#   GUARDIAN_FAILED_GATE    — "G1".."G5"
#   GUARDIAN_FAILED_DETAIL  — descripción humana del fallo
# =============================================================================

_GRD_RED='\033[0;31m'
_GRD_YELLOW='\033[1;33m'
_GRD_NC='\033[0m'

GUARDIAN_FAILED_GATE=""
GUARDIAN_FAILED_DETAIL=""

# ─── Orquestador público ──────────────────────────────────────────────────────

run_guardians() {
  if [[ $# -lt 3 ]]; then
    echo "Uso: run_guardians CHUNK ORIG STRATEGY [RETRIES_DONE]" >&2
    return 1
  fi

  local chunk="$1" orig="$2" strategy="$3"
  local retries_done="${4:-0}"
  local max_retries="${GUARDIAN_MAX_RETRIES:-2}"
  local remaining=$(( max_retries - retries_done ))

  GUARDIAN_FAILED_GATE=""
  GUARDIAN_FAILED_DETAIL=""

  while true; do
    if _grd_run_all "$chunk" "$orig" "$strategy"; then
      return 0
    fi

    _grd_print_failure

    local choice
    _grd_ask_choice choice "$remaining"

    case "$choice" in
      R) return 2 ;;
      A) return 1 ;;
      E)
        "${EDITOR:-vi}" "$chunk"
        GUARDIAN_FAILED_GATE=""
        GUARDIAN_FAILED_DETAIL=""
        ;;
    esac
  done
}

# ─── G1: Output no vacío ─────────────────────────────────────────────────────

guardian_g1_not_empty() {
  local file="$1"

  if [[ ! -s "$file" ]]; then
    GUARDIAN_FAILED_GATE="G1"
    GUARDIAN_FAILED_DETAIL="el output del modelo está vacío o el archivo no existe"
    return 1
  fi
  return 0
}

# ─── G2: Sin markdown ni texto conversacional ─────────────────────────────────

guardian_g2_no_markdown() {
  local file="$1"

  # Fences de código (```), inequívocas en cualquier lenguaje
  if grep -qE '^```' "$file"; then
    GUARDIAN_FAILED_GATE="G2"
    GUARDIAN_FAILED_DETAIL="fence de código markdown detectada (\`\`\` al inicio de línea)"
    return 1
  fi

  # Reglas horizontales markdown
  if grep -qE '^(---+|===+)[[:space:]]*$' "$file"; then
    GUARDIAN_FAILED_GATE="G2"
    GUARDIAN_FAILED_DETAIL="regla horizontal markdown detectada (--- o ===)"
    return 1
  fi

  # Texto conversacional al inicio de línea (case-insensitive)
  # Patrones inequívocamente no-código
  if grep -qiE \
    "^(Here (is|are)|Here's|Sure[,!. ]|Certainly[,!. ]|Of course[,!. ]|I (will|'ll|have) |Below (is|are)|The (following|updated|revised) )" \
    "$file"; then
    GUARDIAN_FAILED_GATE="G2"
    GUARDIAN_FAILED_DETAIL="texto conversacional detectado al inicio de una línea"
    return 1
  fi

  return 0
}

# ─── G3: Line count entre 70% y 130% del original ────────────────────────────

guardian_g3_line_count() {
  local chunk_file="$1" orig_file="$2"

  local orig_lines chunk_lines
  orig_lines=$(awk 'END {print NR}' "$orig_file")
  chunk_lines=$(awk 'END {print NR}' "$chunk_file")

  if [[ "$orig_lines" -eq 0 ]]; then
    return 0
  fi

  local min_lines max_lines
  min_lines=$(( orig_lines * 70 / 100 ))
  max_lines=$(( orig_lines * 130 / 100 ))
  [[ "$min_lines" -lt 1 ]] && min_lines=1

  if [[ "$chunk_lines" -lt "$min_lines" || "$chunk_lines" -gt "$max_lines" ]]; then
    GUARDIAN_FAILED_GATE="G3"
    GUARDIAN_FAILED_DETAIL="líneas: output=${chunk_lines} original=${orig_lines} rango=[${min_lines}–${max_lines}]"
    return 1
  fi
  return 0
}

# ─── G4: Sintaxis válida según la strategy ────────────────────────────────────

guardian_g4_syntax() {
  local chunk_file="$1" strategy_file="$2"

  source "$strategy_file"

  # Los chunks de métodos tienen indentación inicial y no son archivos standalone.
  # validate_syntax() completa se ejecuta en el paso [8] tras re-ensamblar.
  local first_line
  first_line=$(grep -m1 -E '.' "$chunk_file" 2>/dev/null || true)
  if [[ "$first_line" =~ ^[[:space:]] ]]; then
    return 0
  fi

  if ! validate_syntax "$chunk_file" 2>/dev/null; then
    GUARDIAN_FAILED_GATE="G4"
    GUARDIAN_FAILED_DETAIL="validate_syntax() falló — error de sintaxis en el chunk"
    return 1
  fi
  return 0
}

# ─── G5: Firmas públicas presentes ───────────────────────────────────────────

guardian_g5_signatures() {
  local chunk_file="$1" orig_file="$2" strategy_file="$3"

  source "$strategy_file"

  # Extraer TODAS las firmas del original: top-level e indentadas (métodos).
  # La strategy define extract_signatures para el nivel top-level; aquí
  # extendemos el patrón para capturar también los métodos indentados.
  local sigs
  sigs=$(grep -E \
    '^[[:space:]]*((async[[:space:]]+)?def[[:space:]]|class[[:space:]])' \
    "$orig_file" || true)

  [[ -z "$sigs" ]] && return 0

  local missing=() name sig
  while IFS= read -r sig; do
    [[ -z "$sig" ]] && continue

    # Extraer el identificador que sigue a def/class
    name=$(printf '%s' "$sig" | \
      grep -oE '(def|class)[[:space:]]+[A-Za-z_][A-Za-z0-9_]*' | \
      grep -oE '[A-Za-z_][A-Za-z0-9_]*$')
    [[ -z "$name" ]] && continue

    # Omitir privados de un guion bajo (_foo), conservar dunders (__init__)
    [[ "$name" =~ ^_[^_] ]] && continue

    # Verificar que el nombre aparece en el output del modelo
    grep -qE "\b${name}\b" "$chunk_file" || missing+=("$name")
  done <<< "$sigs"

  if [[ ${#missing[@]} -gt 0 ]]; then
    GUARDIAN_FAILED_GATE="G5"
    GUARDIAN_FAILED_DETAIL="firmas públicas ausentes en el output: ${missing[*]}"
    return 1
  fi
  return 0
}

# ─── Internos ─────────────────────────────────────────────────────────────────

# Ejecuta G1–G5 en orden; detiene en el primer fallo.
_grd_run_all() {
  local chunk="$1" orig="$2" strategy="$3"
  guardian_g1_not_empty   "$chunk"                    || return 1
  guardian_g2_no_markdown "$chunk"                    || return 1
  guardian_g3_line_count  "$chunk" "$orig"            || return 1
  guardian_g4_syntax      "$chunk" "$strategy"        || return 1
  guardian_g5_signatures  "$chunk" "$orig" "$strategy" || return 1
  return 0
}

_grd_print_failure() {
  printf "\n  ${_GRD_RED}✗ Guardián %s falló${_GRD_NC}: %s\n" \
    "$GUARDIAN_FAILED_GATE" "$GUARDIAN_FAILED_DETAIL" >&2
}

# _grd_ask_choice NAMEREF REMAINING
# Asigna al nameref R, A o E según la elección del usuario.
# Modo no interactivo (no-TTY o GUARDIAN_NON_INTERACTIVE=1): auto-selecciona A.
_grd_ask_choice() {
  local -n _grd_ch="$1"
  local remaining="$2"

  if [[ ! -t 0 || "${GUARDIAN_NON_INTERACTIVE:-0}" == "1" ]]; then
    _grd_ch="A"
    return
  fi

  printf "\n" >&2
  if [[ "$remaining" -gt 0 ]]; then
    printf "  Reintentos restantes: %d  [R]eintentar  [A]bortar  [E]ditar → " \
      "$remaining" >&2
  else
    printf "  Sin reintentos disponibles.  [A]bortar  [E]ditar → " >&2
  fi

  while true; do
    IFS= read -r _grd_ch
    _grd_ch="${_grd_ch^^}"
    if [[ "$remaining" -gt 0 && "$_grd_ch" =~ ^[RAE]$ ]]; then
      break
    elif [[ "$remaining" -le 0 && "$_grd_ch" =~ ^[AE]$ ]]; then
      break
    else
      printf "  Opción no válida → " >&2
    fi
  done
}
