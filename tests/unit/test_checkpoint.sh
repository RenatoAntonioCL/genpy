#!/usr/bin/env bash
# =============================================================================
# GenPy — tests/unit/test_checkpoint.sh
#
# Pruebas unitarias para create_checkpoint y rollback_to_checkpoint
# (lib/git_manager.sh). Operan sobre repos git temporales reales.
#
# Ejecutar desde la raíz del repo:
#   bash tests/unit/test_checkpoint.sh
# =============================================================================
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"

# git_manager.sh sourcea utils.sh; LIB_DIR debe estar definido antes.
LIB_DIR="$REPO_ROOT/lib"
source "$REPO_ROOT/lib/git_manager.sh"

# ─── Framework ────────────────────────────────────────────────────────────────

_PASS=0; _FAIL=0

_ok() {
  echo "  PASS  $1"
  (( _PASS++ )) || true
}

_fail() {
  local desc="$1" detail="${2:-}"
  echo "  FAIL  $desc${detail:+ — $detail}"
  (( _FAIL++ )) || true
}

_assert_eq() {
  local desc="$1" exp="$2" got="$3"
  [[ "$got" == "$exp" ]] \
    && _ok "$desc" \
    || _fail "$desc" "esperado='$exp' obtenido='$got'"
}

_assert_pass() {
  local desc="$1"; shift
  if "$@" >/dev/null 2>&1; then _ok "$desc"
  else _fail "$desc (debía retornar 0)"; fi
}

_assert_fail() {
  local desc="$1"; shift
  if ! "$@" >/dev/null 2>&1; then _ok "$desc (fallo esperado)"
  else _fail "$desc (debía retornar 1 pero retornó 0)"; fi
}

_assert_branch_exists() {
  local desc="$1" repo="$2" branch="$3"
  if git -C "$repo" show-ref --verify --quiet "refs/heads/${branch}" 2>/dev/null; then
    _ok "$desc"
  else
    _fail "$desc" "rama '${branch}' no existe en el repo"
  fi
}

_assert_branch_gone() {
  local desc="$1" repo="$2" branch="$3"
  if ! git -C "$repo" show-ref --verify --quiet "refs/heads/${branch}" 2>/dev/null; then
    _ok "$desc"
  else
    _fail "$desc" "rama '${branch}' aún existe"
  fi
}

_assert_current_branch() {
  local desc="$1" repo="$2" exp="$3"
  local got
  got=$(git -C "$repo" branch --show-current 2>/dev/null)
  _assert_eq "$desc" "$exp" "$got"
}

# ─── Helper: repo git temporal ────────────────────────────────────────────────
# Usa mktemp -d para cada repo y evita la colisión de paths que ocurriría
# con un contador global en subshell (la expansión $() no propaga variables
# al shell padre).

_TMPBASE=$(mktemp -d)
trap 'rm -rf "$_TMPBASE"' EXIT

_mk_repo() {
  # Crea un repo git con un commit inicial. Imprime la ruta.
  local dir
  dir=$(mktemp -d "$_TMPBASE/repo_XXXXX")
  git -C "$dir" init -b main -q
  git -C "$dir" config --local user.email "test@genpy.test"
  git -C "$dir" config --local user.name  "GenPy Test"
  printf 'initial\n' > "$dir/README.md"
  git -C "$dir" add .
  git -C "$dir" commit -m "initial" -q
  echo "$dir"
}

# ─── create_checkpoint ───────────────────────────────────────────────────────

echo ""
echo "── create_checkpoint ────────────────────────────────────────────────────"

# Happy path: retorna 0, crea la rama, cambia a ella
REPO=$(_mk_repo)
CHECKPOINT_BRANCH=""; CHECKPOINT_ORIGINAL_BRANCH=""
_assert_pass "retorna 0 en repo válido" create_checkpoint "$REPO"
_assert_eq   "CHECKPOINT_ORIGINAL_BRANCH=main" "main" "$CHECKPOINT_ORIGINAL_BRANCH"
[[ "$CHECKPOINT_BRANCH" == genpy/review/* ]] \
  && _ok "CHECKPOINT_BRANCH comienza con genpy/review/" \
  || _fail "CHECKPOINT_BRANCH comienza con genpy/review/" "obtenido='$CHECKPOINT_BRANCH'"
_assert_current_branch "HEAD en rama de revisión tras checkpoint" \
  "$REPO" "$CHECKPOINT_BRANCH"
_assert_branch_exists  "rama de revisión presente en git" \
  "$REPO" "$CHECKPOINT_BRANCH"

# Formato del timestamp: YYYYMMDD_HHMMSS
TS="${CHECKPOINT_BRANCH##*/}"
[[ "$TS" =~ ^[0-9]{8}_[0-9]{6}$ ]] \
  && _ok "timestamp tiene formato YYYYMMDD_HHMMSS" \
  || _fail "formato de timestamp incorrecto" "obtenido='$TS'"

# Prefijo personalizado
REPO=$(_mk_repo)
CHECKPOINT_BRANCH=""; CHECKPOINT_ORIGINAL_BRANCH=""
_assert_pass "acepta prefijo personalizado" create_checkpoint "$REPO" "mi/prefijo"
[[ "$CHECKPOINT_BRANCH" == mi/prefijo/* ]] \
  && _ok "prefijo personalizado respetado" \
  || _fail "prefijo personalizado" "obtenido='$CHECKPOINT_BRANCH'"

# Error: directorio inexistente
CHECKPOINT_BRANCH=""; CHECKPOINT_ORIGINAL_BRANCH=""
_assert_fail "falla con directorio inexistente" create_checkpoint "/no/existe"
_assert_eq   "globals vacíos tras error de directorio" "" "$CHECKPOINT_BRANCH"

# Error: directorio sin git
NO_GIT=$(mktemp -d "$_TMPBASE/nogit_XXXXX")
CHECKPOINT_BRANCH=""; CHECKPOINT_ORIGINAL_BRANCH=""
_assert_fail "falla en directorio sin git" create_checkpoint "$NO_GIT"

# Error: árbol de trabajo sucio (cambio sin commitear)
REPO=$(_mk_repo)
printf 'dirty\n' >> "$REPO/README.md"
CHECKPOINT_BRANCH=""; CHECKPOINT_ORIGINAL_BRANCH=""
_assert_fail "falla con árbol de trabajo sucio" create_checkpoint "$REPO"
_assert_current_branch "HEAD no se movió tras error dirty" "$REPO" "main"
_assert_eq "globals vacíos tras árbol sucio" "" "$CHECKPOINT_BRANCH"

# Error: repo sin commits (HEAD inexistente)
EMPTY=$(mktemp -d "$_TMPBASE/empty_XXXXX")
git -C "$EMPTY" init -b main -q
git -C "$EMPTY" config --local user.email "t@t.t"
git -C "$EMPTY" config --local user.name  "T"
CHECKPOINT_BRANCH=""; CHECKPOINT_ORIGINAL_BRANCH=""
_assert_fail "falla en repo sin commits" create_checkpoint "$EMPTY"

# ─── rollback_to_checkpoint ──────────────────────────────────────────────────

echo ""
echo "── rollback_to_checkpoint ───────────────────────────────────────────────"

# Happy path: vuelve a main, elimina rama de revisión, limpia globals
REPO=$(_mk_repo)
CHECKPOINT_BRANCH=""; CHECKPOINT_ORIGINAL_BRANCH=""
create_checkpoint "$REPO" >/dev/null 2>&1
REVIEW_BRANCH="$CHECKPOINT_BRANCH"

_assert_pass "retorna 0 en rollback válido" rollback_to_checkpoint "$REPO"
_assert_current_branch "HEAD vuelve a main"          "$REPO" "main"
_assert_branch_gone    "rama de revisión eliminada"  "$REPO" "$REVIEW_BRANCH"
_assert_eq "CHECKPOINT_BRANCH limpio"          "" "$CHECKPOINT_BRANCH"
_assert_eq "CHECKPOINT_ORIGINAL_BRANCH limpio" "" "$CHECKPOINT_ORIGINAL_BRANCH"

# Rollback con cambios sin commitear en la rama de revisión
# (git permite el checkout porque ambas ramas comparten el mismo contenido HEAD)
REPO=$(_mk_repo)
CHECKPOINT_BRANCH=""; CHECKPOINT_ORIGINAL_BRANCH=""
create_checkpoint "$REPO" >/dev/null 2>&1
REVIEW_BRANCH="$CHECKPOINT_BRANCH"
printf 'ai output\n' >> "$REPO/README.md"   # cambio local sin commitear

_assert_pass "rollback OK con cambios sin commitear" rollback_to_checkpoint "$REPO"
_assert_current_branch "HEAD en main tras rollback con cambios" "$REPO" "main"
_assert_branch_gone    "rama eliminada con -D (force)"          "$REPO" "$REVIEW_BRANCH"
_assert_eq "CHECKPOINT_BRANCH limpio"          "" "$CHECKPOINT_BRANCH"
_assert_eq "CHECKPOINT_ORIGINAL_BRANCH limpio" "" "$CHECKPOINT_ORIGINAL_BRANCH"

# Error: CHECKPOINT_BRANCH no definido
REPO=$(_mk_repo)
CHECKPOINT_BRANCH=""; CHECKPOINT_ORIGINAL_BRANCH=""
_assert_fail "falla sin CHECKPOINT_BRANCH" rollback_to_checkpoint "$REPO"

# Error: CHECKPOINT_ORIGINAL_BRANCH no definido
REPO=$(_mk_repo)
CHECKPOINT_BRANCH=""; CHECKPOINT_ORIGINAL_BRANCH=""
create_checkpoint "$REPO" >/dev/null 2>&1
CHECKPOINT_ORIGINAL_BRANCH=""    # borrar solo el original
_assert_fail "falla sin CHECKPOINT_ORIGINAL_BRANCH" rollback_to_checkpoint "$REPO"
CHECKPOINT_BRANCH=""; CHECKPOINT_ORIGINAL_BRANCH=""  # limpiar estado

# Error: directorio inexistente
CHECKPOINT_BRANCH="genpy/review/fake"; CHECKPOINT_ORIGINAL_BRANCH="main"
_assert_fail "falla con directorio inexistente" rollback_to_checkpoint "/no/existe"
CHECKPOINT_BRANCH=""; CHECKPOINT_ORIGINAL_BRANCH=""

# ─── Ciclo completo: create → rollback → create de nuevo ─────────────────────

echo ""
echo "── Ciclo completo ───────────────────────────────────────────────────────"

REPO=$(_mk_repo)
CHECKPOINT_BRANCH=""; CHECKPOINT_ORIGINAL_BRANCH=""

create_checkpoint "$REPO" >/dev/null 2>&1
FIRST_BRANCH="$CHECKPOINT_BRANCH"
rollback_to_checkpoint "$REPO" >/dev/null 2>&1

# Pequeña pausa para que el timestamp difiera si el reloj va a segundos
sleep 1

create_checkpoint "$REPO" >/dev/null 2>&1
SECOND_BRANCH="$CHECKPOINT_BRANCH"

_assert_current_branch "segunda revisión: HEAD en nueva rama" "$REPO" "$SECOND_BRANCH"
[[ "$FIRST_BRANCH" != "$SECOND_BRANCH" ]] \
  && _ok "dos checkpoints producen ramas distintas" \
  || _fail "dos checkpoints distintos" "ambas='$FIRST_BRANCH'"
_assert_branch_gone "primera rama eliminada tras primer rollback" "$REPO" "$FIRST_BRANCH"

rollback_to_checkpoint "$REPO" >/dev/null 2>&1
_assert_current_branch "de vuelta en main tras segundo rollback" "$REPO" "main"

# ─── Resumen ──────────────────────────────────────────────────────────────────

echo ""
echo "─────────────────────────────────────────────────────────────────────────"
echo "  Resultado: ${_PASS} PASS  /  ${_FAIL} FAIL"
[[ "$_FAIL" -gt 0 ]] && echo "" && exit 1
echo ""
