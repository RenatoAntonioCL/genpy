#!/usr/bin/env bash
# =============================================================================
# GenPy — tests/integration/test_review_flow.sh
#
# Prueba de integración del flujo genpy review de extremo a extremo.
# Usa ollama_mock.sh como provider (sin Ollama real).
#
# Ejecutar desde la raíz del repo:
#   bash tests/integration/test_review_flow.sh
# =============================================================================
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
export LIB_DIR="$REPO_ROOT/lib"

# ─── Mini framework ───────────────────────────────────────────────────────────

_PASS=0; _FAIL=0

_ok()   { echo "  PASS  $1"; (( _PASS++ )) || true; }
_fail() { echo "  FAIL  $1"; echo "        $2"; (( _FAIL++ )) || true; }

# Ejecuta un bloque en subshell; registra PASS/FAIL según el exit code.
_run() {
  local desc="$1"; shift
  if "$@" 2>/dev/null; then
    _ok "$desc"
  else
    _fail "$desc" "rc=$(( $? )) — ejecuta con 'bash -x' para detalles"
  fi
}

# ─── Helpers de proyecto git temporal ─────────────────────────────────────────

_make_project() {
  local dir
  dir=$(mktemp -d)

  git -C "$dir" init -q
  git -C "$dir" config user.email "test@genpy.test"
  git -C "$dir" config user.name "GenPy Test"

  cat > "$dir/sample.py" <<'PYEOF'
import os


def greet(name: str) -> str:
    return "Hello " + name


def add(a, b):
    return a+b
PYEOF

  git -C "$dir" add sample.py
  git -C "$dir" commit -q -m "initial"

  echo "$dir"
}

# ─── Helpers de test ──────────────────────────────────────────────────────────

# Entorno base: mock que devuelve el código sin modificar (camino "sin cambios")
_review_env() {
  source "$REPO_ROOT/tests/mocks/ollama_mock.sh"
  preflight_mode_review() { return 0; }
  export GUARDIAN_NON_INTERACTIVE=1
  export GENPY_REVIEW_NON_INTERACTIVE=1
}

# Entorno con mock que añade un comentario al final del chunk (camino "con cambios")
_review_env_with_change() {
  ai_complete() {
    local prompt_file="$1" output_file="$2"
    local marker="=== SECCIÓN 4: FRAGMENTO OBJETIVO ==="
    if grep -qF "$marker" "$prompt_file" 2>/dev/null; then
      awk -v m="$marker" 'found{print} $0==m{found=1}' "$prompt_file" >"$output_file"
      # El mock añade un comentario para generar un diff real (1 línea, dentro de G3)
      printf '# reviewed by genpy\n' >> "$output_file"
    else
      cp "$prompt_file" "$output_file"
    fi
    return 0
  }
  preflight_mode_review() { return 0; }
  export GUARDIAN_NON_INTERACTIVE=1
  export GENPY_REVIEW_NON_INTERACTIVE=1
}

# ─── Tests: _review_detect_strategy ──────────────────────────────────────────

echo ""
echo "─── _review_detect_strategy ───────────────────────────────────────────────"

source "$REPO_ROOT/lib/review.sh"

_check_strategy_py()  { [[ "$(_review_detect_strategy "/tmp/foo.py")"  == *"/python.sh"      ]]; }
_check_strategy_go()  { [[ "$(_review_detect_strategy "/tmp/foo.go")"  == *"/go.sh"          ]]; }
_check_strategy_ts()  { [[ "$(_review_detect_strategy "/tmp/foo.ts")"  == *"/javascript.sh"  ]]; }
_check_strategy_err() { ! _review_detect_strategy "/tmp/foo.rs" 2>/dev/null; }

_run "detecta python por extensión .py"          _check_strategy_py
_run "detecta go por extensión .go"              _check_strategy_go
_run "detecta javascript por extensión .ts"      _check_strategy_ts
_run "extensión desconocida devuelve error"       _check_strategy_err

# ─── Tests: _review_abspath ──────────────────────────────────────────────────

echo ""
echo "─── _review_abspath ──────────────────────────────────────────────────────"

tmpfile=$(mktemp)
_check_abspath() { [[ "$(_review_abspath "$tmpfile")" == /* ]]; }
_run "_review_abspath devuelve ruta absoluta" _check_abspath
rm -f "$tmpfile"

# ─── Tests: flujo completo con mock ──────────────────────────────────────────

echo ""
echo "─── Flujo completo (mock provider, no-interactive) ───────────────────────"

proj=$(_make_project)

# Camino "sin cambios": el mock devuelve el código idéntico → rollback, rc=0
_test_flow_no_diff() {
  cd "$proj"
  _review_env
  genpy_review "sample.py" --function "greet" --goal "test"
}

# Camino "con cambios": el mock añade un comentario → se aplican los cambios
_test_flow_apply() {
  cd "$proj"
  _review_env_with_change
  genpy_review "sample.py" --function "greet" --goal "Mejorar calidad"
}

_test_flow_apply_branch() {
  cd "$proj"
  _review_env_with_change
  genpy_review "sample.py" --function "greet" --goal "test" 2>/dev/null || true
  git -C "$proj" branch --list 'genpy/review/*' | grep -q 'genpy/review/'
}

_test_flow_apply_commits() {
  cd "$proj"
  _review_env_with_change
  genpy_review "sample.py" --function "greet" --goal "test" 2>/dev/null || true
  local n; n=$(git -C "$proj" log --oneline | wc -l | tr -d ' ')
  [[ "$n" -ge 2 ]]
}

_run "camino sin-cambios: genpy_review completa con rc=0"         _test_flow_no_diff
_run "camino con-cambios: genpy_review aplica y completa rc=0"    _test_flow_apply
_run "camino con-cambios: rama genpy/review/* existe"             _test_flow_apply_branch
_run "camino con-cambios: al menos 2 commits tras aplicar"        _test_flow_apply_commits

rm -rf "$proj"

# ─── Tests: selector --lines ──────────────────────────────────────────────────

echo ""
echo "─── Flujo con --lines ────────────────────────────────────────────────────"

proj=$(_make_project)

_test_flow_lines() {
  cd "$proj"
  _review_env
  genpy_review "sample.py" --lines "4-6"
}

_run "genpy_review completa con --lines 4-6" _test_flow_lines

rm -rf "$proj"

# ─── Tests: selector --class ──────────────────────────────────────────────────

echo ""
echo "─── Flujo con --class ────────────────────────────────────────────────────"

proj=$(mktemp -d)
git -C "$proj" init -q
git -C "$proj" config user.email "t@t.com"
git -C "$proj" config user.name "T"

cat > "$proj/models.py" <<'PYEOF'
class User:
    def __init__(self, name):
        self.name = name

    def greet(self):
        return f"Hi {self.name}"
PYEOF

git -C "$proj" add models.py
git -C "$proj" commit -q -m "initial"

_test_flow_class() {
  cd "$proj"
  _review_env
  genpy_review "models.py" --class "User"
}

_run "genpy_review completa con --class User" _test_flow_class

rm -rf "$proj"

# ─── Tests: manejo de errores ────────────────────────────────────────────────

echo ""
echo "─── Manejo de errores ────────────────────────────────────────────────────"

proj=$(_make_project)

_test_err_no_file() {
  cd "$proj"
  _review_env
  ! genpy_review "nonexistent.py" --function "foo"
}

_test_err_no_args() {
  ! genpy_review
}

_test_err_bad_option() {
  cd "$proj"
  _review_env
  ! genpy_review "sample.py" --unknown-flag
}

_run "falla con archivo inexistente"     _test_err_no_file
_run "falla sin argumentos (usage)"      _test_err_no_args
_run "falla con opción desconocida"      _test_err_bad_option

rm -rf "$proj"

# ─── Tests: preflight_mode_review ────────────────────────────────────────────

echo ""
echo "─── preflight_mode_review ────────────────────────────────────────────────"

source "$LIB_DIR/core/errors.sh"
source "$LIB_DIR/utils.sh"
source "$LIB_DIR/core/preflight.sh"

_make_clean_repo() {
  local d; d=$(mktemp -d)
  git -C "$d" init -q
  git -C "$d" config user.email "t@t.com"
  git -C "$d" config user.name "T"
  touch "$d/f"
  git -C "$d" add f
  git -C "$d" commit -q -m "init"
  echo "$d"
}

_test_preflight_ollama_down() {
  local d; d=$(_make_clean_repo)
  cd "$d"
  OLLAMA_HOST="http://127.0.0.1:1" preflight_mode_review 2>/dev/null
  local rc=$?
  rm -rf "$d"
  [[ "$rc" -ne 0 ]]
}

_test_preflight_dirty_tree() {
  local d; d=$(_make_clean_repo)
  echo "dirty" > "$d/f"
  cd "$d"
  OLLAMA_HOST="http://127.0.0.1:1" preflight_mode_review 2>/dev/null
  local rc=$?
  rm -rf "$d"
  [[ "$rc" -ne 0 ]]
}

_run "preflight falla con Ollama caído"        _test_preflight_ollama_down
_run "preflight falla con árbol de trabajo sucio" _test_preflight_dirty_tree

# ─── Resultado ────────────────────────────────────────────────────────────────

echo ""
echo "─────────────────────────────────────────────────────────────────────────"
printf "  Resultado: %d PASS  /  %d FAIL\n" "$_PASS" "$_FAIL"
[[ "$_FAIL" -eq 0 ]]
