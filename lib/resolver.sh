#!/usr/bin/env bash
set -euo pipefail

# Include guard
[[ -n "${_GENPY_RESOLVER_LOADED:-}" ]] && return 0
_GENPY_RESOLVER_LOADED=1

# =============================================================================
# GenPy — lib/resolver.sh (v1.0.0-alpha)
#
# Translates a semantic selector to a line range (RESOLVE_START..RESOLVE_END,
# 1-based, inclusive) for the genpy review flow (ARCHITECTURE.md §5.4 step [3]).
#
# Modes:
#   --lines N-M         explicit range
#   --function name     def/async def function at the top level
#   --class name        top-level class
#   --method Cls.mth    method inside a top-level class
#
# Strategy: grep/awk first; python3 ast as fallback when bash does not detect
# the definition (decision C2). Requires python3 >= 3.8 only if the fallback is activated.
# =============================================================================

# ─── Public API ───────────────────────────────────────────────────────────────

# resolve_range MODE TARGET FILE
# Sets globals: RESOLVE_START, RESOLVE_END
# Returns: 0=ok, 1=error
resolve_range() {
  if [[ $# -ne 3 ]]; then
    echo "Usage: resolve_range --lines|--function|--class|--method TARGET FILE" >&2
    return 1
  fi

  local mode="$1" target="$2" file="$3"

  RESOLVE_START=""
  RESOLVE_END=""

  if [[ ! -f "$file" ]]; then
    echo "Error: file not found: $file" >&2
    return 1
  fi

  case "$mode" in
    --lines)    _rr_lines    "$target" "$file" ;;
    --function) _rr_function "$target" "$file" ;;
    --class)    _rr_class    "$target" "$file" ;;
    --method)   _rr_method   "$target" "$file" ;;
    *)
      echo "Error: unknown mode '$mode'" >&2
      echo "Valid: --lines  --function  --class  --method" >&2
      return 1
      ;;
  esac
}

# ─── --lines N-M ──────────────────────────────────────────────────────────────

_rr_lines() {
  local range="$1" file="$2"

  if [[ ! "$range" =~ ^([0-9]+)-([0-9]+)$ ]]; then
    echo "Error: --lines requires format N-M (e.g.: 10-25)" >&2
    return 1
  fi

  local n="${BASH_REMATCH[1]}" m="${BASH_REMATCH[2]}"
  local total
  total=$(awk 'END {print NR}' "$file")

  if [[ "$n" -lt 1 || "$n" -gt "$m" || "$m" -gt "$total" ]]; then
    echo "Error: range $n-$m invalid (file has $total lines)" >&2
    return 1
  fi

  RESOLVE_START="$n"
  RESOLVE_END="$m"
}

# ─── --function name ──────────────────────────────────────────────────────────

_rr_function() {
  local name="$1" file="$2"

  # Bash: def/async def at level 0 (column 0)
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

  echo "Error: function '${name}' not found in $file" >&2
  return 1
}

# ─── --class name ─────────────────────────────────────────────────────────────

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

  echo "Error: class '${name}' not found in $file" >&2
  return 1
}

# ─── --method Class.method ────────────────────────────────────────────────────

_rr_method() {
  local target="$1" file="$2"

  if [[ ! "$target" =~ ^([A-Za-z_][A-Za-z0-9_]*)\.([A-Za-z_][A-Za-z0-9_]*)$ ]]; then
    echo "Error: --method requires format Clase.método (e.g.: ItemService.create_item)" >&2
    return 1
  fi

  local cname="${BASH_REMATCH[1]}" mname="${BASH_REMATCH[2]}"

  # Locate the class first
  local class_start
  class_start=$(grep -En \
    "^class[[:space:]]+${cname}[[:space:](:]" "$file" \
    | head -1 | cut -d: -f1 || true)

  if [[ -z "$class_start" ]]; then
    echo "Error: class '${cname}' not found in $file" >&2
    return 1
  fi

  local class_end
  class_end=$(_rr_top_level_end "$file" "$class_start")

  # Search for the method inside the class block (any indentation, not col-0)
  local method_start
  method_start=$(awk \
    -v cs="$class_start" -v ce="$class_end" -v mn="$mname" \
    'NR > cs && NR <= ce &&
     $0 ~ ("^[[:space:]]+(async[[:space:]]+)?def[[:space:]]+" mn "[[:space:](]") {
       print NR; exit
     }' "$file" || true)

  if [[ -n "$method_start" ]]; then
    # Detect indentation of 'def' to delimit the end of the method
    local def_line
    def_line=$(sed -n "${method_start}p" "$file")
    local prefix="${def_line%%[! ]*}"   # Leading spaces (spaces only, not tabs)
    local indent="${#prefix}"

    RESOLVE_START="$method_start"
    RESOLVE_END=$(_rr_method_end "$file" "$method_start" "$indent" "$class_end")
    return 0
  fi

  _rr_python "method" "$mname" "$cname" "$file" && return 0

  echo "Error: method '${cname}.${mname}' not found in $file" >&2
  return 1
}

# ─── End-of-block detection ───────────────────────────────────────────────────

# _rr_top_level_end FILE START
# Returns the last line of the top-level block starting at START.
# The block ends just before the next def/class/decorator at column 0.
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
# Returns the last line of the method.
# The method ends just before the next sibling with indent <= INDENT,
# or at CLASS_END if there is no sibling.
# Blank lines are ignored when searching for the sibling but included in END.
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

# ─── Python fallback (decision C2) ───────────────────────────────────────────

# _rr_python KIND NAME EXTRA FILE
#   KIND   function | class | method
#   NAME   name of the function/class/method
#   EXTRA  name of the containing class (method only; empty if not applicable)
# Sets RESOLVE_START and RESOLVE_END using python3 ast.
# Requires python3 >= 3.8 (end_lineno). Returns 0=ok, 1=failure.
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
