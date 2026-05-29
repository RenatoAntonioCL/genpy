#!/usr/bin/env bash
set -euo pipefail

# Include guard
[[ -n "${_GENPY_RESOLVER_LOADED:-}" ]] && return 0
_GENPY_RESOLVER_LOADED=1

# =============================================================================
# GenPy — lib/resolver.sh (v1.0.0-alpha)
#
# Traduce un selector semántico a un rango de líneas (RESOLVE_START..RESOLVE_END,
# 1-based, inclusive) para el flujo genpy review (ARCHITECTURE.md §5.4 paso [3]).
#
# Modos:
#   --lines N-M         rango explícito
#   --function nombre   función def/async def al nivel top-level
#   --class nombre      clase top-level
#   --method Cls.mth    método dentro de una clase top-level
#
# Estrategia: grep/awk primero; python3 ast como fallback cuando bash no detecta
# la definición (decisión C2). Requiere python3 >= 3.8 solo si se activa el fallback.
# =============================================================================

# ─── API pública ──────────────────────────────────────────────────────────────

# resolve_range MODE TARGET FILE
# Sets globals: RESOLVE_START, RESOLVE_END
# Returns: 0=ok, 1=error
resolve_range() {
  if [[ $# -ne 3 ]]; then
    echo "Uso: resolve_range --lines|--function|--class|--method TARGET FILE" >&2
    return 1
  fi

  local mode="$1" target="$2" file="$3"

  RESOLVE_START=""
  RESOLVE_END=""

  if [[ ! -f "$file" ]]; then
    echo "Error: archivo no encontrado: $file" >&2
    return 1
  fi

  case "$mode" in
    --lines)    _rr_lines    "$target" "$file" ;;
    --function) _rr_function "$target" "$file" ;;
    --class)    _rr_class    "$target" "$file" ;;
    --method)   _rr_method   "$target" "$file" ;;
    *)
      echo "Error: modo desconocido '$mode'" >&2
      echo "Válidos: --lines  --function  --class  --method" >&2
      return 1
      ;;
  esac
}

# ─── --lines N-M ──────────────────────────────────────────────────────────────

_rr_lines() {
  local range="$1" file="$2"

  if [[ ! "$range" =~ ^([0-9]+)-([0-9]+)$ ]]; then
    echo "Error: --lines requiere formato N-M (ej: 10-25)" >&2
    return 1
  fi

  local n="${BASH_REMATCH[1]}" m="${BASH_REMATCH[2]}"
  local total
  total=$(awk 'END {print NR}' "$file")

  if [[ "$n" -lt 1 || "$n" -gt "$m" || "$m" -gt "$total" ]]; then
    echo "Error: rango $n-$m inválido (archivo tiene $total líneas)" >&2
    return 1
  fi

  RESOLVE_START="$n"
  RESOLVE_END="$m"
}

# ─── --function nombre ────────────────────────────────────────────────────────

_rr_function() {
  local name="$1" file="$2"

  # Bash: def/async def al nivel 0 (columna 0)
  local start
  start=$(grep -En \
    "^(async[[:space:]]+)?def[[:space:]]+${name}[[:space:](]" "$file" \
    | head -1 | cut -d: -f1 || true)

  if [[ -n "$start" ]]; then
    RESOLVE_START="$start"
    RESOLVE_END=$(_rr_top_level_end "$file" "$start")
    return 0
  fi

  # Fallback: Python ast (C2)
  _rr_python "function" "$name" "" "$file" && return 0

  echo "Error: función '${name}' no encontrada en $file" >&2
  return 1
}

# ─── --class nombre ───────────────────────────────────────────────────────────

_rr_class() {
  local name="$1" file="$2"

  local start
  start=$(grep -En \
    "^class[[:space:]]+${name}[[:space:](:]" "$file" \
    | head -1 | cut -d: -f1 || true)

  if [[ -n "$start" ]]; then
    RESOLVE_START="$start"
    RESOLVE_END=$(_rr_top_level_end "$file" "$start")
    return 0
  fi

  _rr_python "class" "$name" "" "$file" && return 0

  echo "Error: clase '${name}' no encontrada en $file" >&2
  return 1
}

# ─── --method Clase.método ────────────────────────────────────────────────────

_rr_method() {
  local target="$1" file="$2"

  if [[ ! "$target" =~ ^([A-Za-z_][A-Za-z0-9_]*)\.([A-Za-z_][A-Za-z0-9_]*)$ ]]; then
    echo "Error: --method requiere formato Clase.método (ej: ItemService.create_item)" >&2
    return 1
  fi

  local cname="${BASH_REMATCH[1]}" mname="${BASH_REMATCH[2]}"

  # Localizar la clase primero
  local class_start
  class_start=$(grep -En \
    "^class[[:space:]]+${cname}[[:space:](:]" "$file" \
    | head -1 | cut -d: -f1 || true)

  if [[ -z "$class_start" ]]; then
    echo "Error: clase '${cname}' no encontrada en $file" >&2
    return 1
  fi

  local class_end
  class_end=$(_rr_top_level_end "$file" "$class_start")

  # Buscar el método dentro del bloque de la clase (cualquier indentación, no col-0)
  local method_start
  method_start=$(awk \
    -v cs="$class_start" -v ce="$class_end" -v mn="$mname" \
    'NR > cs && NR <= ce &&
     $0 ~ ("^[[:space:]]+(async[[:space:]]+)?def[[:space:]]+" mn "[[:space:](]") {
       print NR; exit
     }' "$file" || true)

  if [[ -n "$method_start" ]]; then
    # Detectar indentación del 'def' para delimitar el fin del método
    local def_line
    def_line=$(sed -n "${method_start}p" "$file")
    local prefix="${def_line%%[! ]*}"   # Leading spaces (solo espacios, no tabs)
    local indent="${#prefix}"

    RESOLVE_START="$method_start"
    RESOLVE_END=$(_rr_method_end "$file" "$method_start" "$indent" "$class_end")
    return 0
  fi

  _rr_python "method" "$mname" "$cname" "$file" && return 0

  echo "Error: método '${cname}.${mname}' no encontrado en $file" >&2
  return 1
}

# ─── Detección de fin de bloque ───────────────────────────────────────────────

# _rr_top_level_end FILE START
# Retorna la última línea del bloque top-level que empieza en START.
# El bloque termina justo antes del siguiente def/class/decorator en col 0.
_rr_top_level_end() {
  local file="$1" start="$2"
  local total
  total=$(awk 'END {print NR}' "$file")

  awk -v s="$start" -v total="$total" '
    BEGIN { result = total }
    NR > s && /^((async[[:space:]]+)?def[[:space:]]|class[[:space:]]|@)/ {
      result = NR - 1; exit
    }
    END { print result }
  ' "$file"
}

# _rr_method_end FILE METHOD_START INDENT CLASS_END
# Retorna la última línea del método.
# El método termina justo antes del siguiente sibling con indent <= INDENT,
# o en CLASS_END si no hay sibling.
# Las líneas en blanco se ignoran al buscar el sibling pero se incluyen en END.
_rr_method_end() {
  local file="$1" start="$2" indent="$3" max="$4"

  awk -v s="$start" -v bi="$indent" -v max="$max" '
    BEGIN { result = max }
    NR > s && NR <= max {
      if ($0 ~ /^[[:space:]]*$/) next
      n = 0
      while (substr($0, n+1, 1) == " ") n++
      if (n <= bi) { result = NR - 1; exit }
    }
    END { print result }
  ' "$file"
}

# ─── Fallback Python (decisión C2) ────────────────────────────────────────────

# _rr_python KIND NAME EXTRA FILE
#   KIND   function | class | method
#   NAME   nombre de la función/clase/método
#   EXTRA  nombre de la clase contenedora (solo para method; vacío si no aplica)
# Establece RESOLVE_START y RESOLVE_END usando python3 ast.
# Requiere python3 >= 3.8 (end_lineno). Retorna 0=ok, 1=fallo.
_rr_python() {
  local kind="$1" name="$2" extra="$3" file="$4"

  command -v python3 &>/dev/null || return 1

  local result
  result=$(python3 - "$kind" "$name" "$extra" "$file" <<'PYEOF' 2>/dev/null) || return 1
import ast, sys

kind, name, extra, path = sys.argv[1], sys.argv[2], sys.argv[3], sys.argv[4]

with open(path, encoding="utf-8") as fh:
    source = fh.read()

tree = ast.parse(source)

if kind in ("function", "class"):
    for node in ast.iter_child_nodes(tree):
        hit = (
            kind == "function"
            and isinstance(node, (ast.FunctionDef, ast.AsyncFunctionDef))
            and node.name == name
        ) or (
            kind == "class"
            and isinstance(node, ast.ClassDef)
            and node.name == name
        )
        if hit:
            print(f"{node.lineno}:{node.end_lineno}")
            sys.exit(0)

elif kind == "method":
    for node in ast.iter_child_nodes(tree):
        if isinstance(node, ast.ClassDef) and node.name == extra:
            for item in ast.iter_child_nodes(node):
                if (
                    isinstance(item, (ast.FunctionDef, ast.AsyncFunctionDef))
                    and item.name == name
                ):
                    print(f"{item.lineno}:{item.end_lineno}")
                    sys.exit(0)

sys.exit(1)
PYEOF

  if [[ "$result" =~ ^([0-9]+):([0-9]+)$ ]]; then
    RESOLVE_START="${BASH_REMATCH[1]}"
    RESOLVE_END="${BASH_REMATCH[2]}"
    return 0
  fi

  return 1
}
