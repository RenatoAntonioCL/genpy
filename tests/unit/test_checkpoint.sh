#!/usr/bin/env bash
# =============================================================================
# GenPy — tests/unit/test_checkpoint.sh
#
# Unit tests for create_checkpoint and rollback_to_checkpoint
# (lib/git_manager.sh). Operate on real temporary git repos.
#
# Run from the repo root:
#   bash tests/unit/test_checkpoint.sh
# =============================================================================
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"

# git_manager.sh sources utils.sh; LIB_DIR must be defined first.
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
    || _fail "$desc" "expected='$exp' got='$got'"
}

_assert_pass() {
  local desc="$1"; shift
  if "$@" >/dev/null 2>&1; then _ok "$desc"
  else _fail "$desc (should return 0)"; fi
}

_assert_fail() {
  local desc="$1"; shift
  if ! "$@" >/dev/null 2>&1; then _ok "$desc (expected failure)"
  else _fail "$desc (should return 1 but returned 0)"; fi
}

_assert_branch_exists() {
  local desc="$1" repo="$2" branch="$3"
  if git -C "$repo" show-ref --verify --quiet "refs/heads/${branch}" 2>/dev/null; then
    _ok "$desc"
  else
    _fail "$desc" "branch '${branch}' does not exist in repo"
  fi
}

_assert_branch_gone() {
  local desc="$1" repo="$2" branch="$3"
  if ! git -C "$repo" show-ref --verify --quiet "refs/heads/${branch}" 2>/dev/null; then
    _ok "$desc"
  else
    _fail "$desc" "branch '${branch}' still exists"
  fi
}

_assert_current_branch() {
  local desc="$1" repo="$2" exp="$3"
  local got
  got=$(git -C "$repo" branch --show-current 2>/dev/null)
  _assert_eq "$desc" "$exp" "$got"
}

# ─── Helper: temporary git repo ──────────────────────────────────────────────
# Uses mktemp -d for each repo to avoid path collisions that would occur
# with a global counter in a subshell ($() expansion does not propagate
# variables to the parent shell).

_TMPBASE=$(mktemp -d)
trap 'rm -rf "$_TMPBASE"' EXIT

_mk_repo() {
  # Creates a git repo with an initial commit. Prints the path.
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

# Happy path: returns 0, creates branch, switches to it
REPO=$(_mk_repo)
CHECKPOINT_BRANCH=""; CHECKPOINT_ORIGINAL_BRANCH=""
_assert_pass "returns 0 on valid repo" create_checkpoint "$REPO"
_assert_eq   "CHECKPOINT_ORIGINAL_BRANCH=main" "main" "$CHECKPOINT_ORIGINAL_BRANCH"
[[ "$CHECKPOINT_BRANCH" == genpy/review/* ]] \
  && _ok "CHECKPOINT_BRANCH starts with genpy/review/" \
  || _fail "CHECKPOINT_BRANCH starts with genpy/review/" "got='$CHECKPOINT_BRANCH'"
_assert_current_branch "HEAD on review branch after checkpoint" \
  "$REPO" "$CHECKPOINT_BRANCH"
_assert_branch_exists  "review branch present in git" \
  "$REPO" "$CHECKPOINT_BRANCH"

# Timestamp format: YYYYMMDD_HHMMSS
TS="${CHECKPOINT_BRANCH##*/}"
[[ "$TS" =~ ^[0-9]{8}_[0-9]{6}$ ]] \
  && _ok "timestamp has format YYYYMMDD_HHMMSS" \
  || _fail "wrong timestamp format" "got='$TS'"

# Custom prefix
REPO=$(_mk_repo)
CHECKPOINT_BRANCH=""; CHECKPOINT_ORIGINAL_BRANCH=""
_assert_pass "accepts custom prefix" create_checkpoint "$REPO" "my/prefix"
[[ "$CHECKPOINT_BRANCH" == my/prefix/* ]] \
  && _ok "custom prefix respected" \
  || _fail "custom prefix" "got='$CHECKPOINT_BRANCH'"

# Error: nonexistent directory
CHECKPOINT_BRANCH=""; CHECKPOINT_ORIGINAL_BRANCH=""
_assert_fail "fails with nonexistent directory" create_checkpoint "/no/existe"
_assert_eq   "globals empty after directory error" "" "$CHECKPOINT_BRANCH"

# Error: directory without git
NO_GIT=$(mktemp -d "$_TMPBASE/nogit_XXXXX")
CHECKPOINT_BRANCH=""; CHECKPOINT_ORIGINAL_BRANCH=""
_assert_fail "fails in directory without git" create_checkpoint "$NO_GIT"

# Error: dirty working tree (uncommitted change)
REPO=$(_mk_repo)
printf 'dirty\n' >> "$REPO/README.md"
CHECKPOINT_BRANCH=""; CHECKPOINT_ORIGINAL_BRANCH=""
_assert_fail "fails with dirty working tree" create_checkpoint "$REPO"
_assert_current_branch "HEAD did not move after dirty error" "$REPO" "main"
_assert_eq "globals empty after dirty tree" "" "$CHECKPOINT_BRANCH"

# Error: repo without commits (HEAD does not exist)
EMPTY=$(mktemp -d "$_TMPBASE/empty_XXXXX")
git -C "$EMPTY" init -b main -q
git -C "$EMPTY" config --local user.email "t@t.t"
git -C "$EMPTY" config --local user.name  "T"
CHECKPOINT_BRANCH=""; CHECKPOINT_ORIGINAL_BRANCH=""
_assert_fail "fails on repo without commits" create_checkpoint "$EMPTY"

# ─── rollback_to_checkpoint ──────────────────────────────────────────────────

echo ""
echo "── rollback_to_checkpoint ───────────────────────────────────────────────"

# Happy path: returns to main, deletes review branch, clears globals
REPO=$(_mk_repo)
CHECKPOINT_BRANCH=""; CHECKPOINT_ORIGINAL_BRANCH=""
create_checkpoint "$REPO" >/dev/null 2>&1
REVIEW_BRANCH="$CHECKPOINT_BRANCH"

_assert_pass "returns 0 on valid rollback" rollback_to_checkpoint "$REPO"
_assert_current_branch "HEAD returns to main"         "$REPO" "main"
_assert_branch_gone    "review branch deleted"        "$REPO" "$REVIEW_BRANCH"
_assert_eq "CHECKPOINT_BRANCH cleared"          "" "$CHECKPOINT_BRANCH"
_assert_eq "CHECKPOINT_ORIGINAL_BRANCH cleared" "" "$CHECKPOINT_ORIGINAL_BRANCH"

# Rollback with uncommitted changes on the review branch
# (git allows checkout because both branches share the same HEAD content)
REPO=$(_mk_repo)
CHECKPOINT_BRANCH=""; CHECKPOINT_ORIGINAL_BRANCH=""
create_checkpoint "$REPO" >/dev/null 2>&1
REVIEW_BRANCH="$CHECKPOINT_BRANCH"
printf 'ai output\n' >> "$REPO/README.md"   # local uncommitted change

_assert_pass "rollback OK with uncommitted changes" rollback_to_checkpoint "$REPO"
_assert_current_branch "HEAD on main after rollback with changes" "$REPO" "main"
_assert_branch_gone    "branch deleted with -D (force)"           "$REPO" "$REVIEW_BRANCH"
_assert_eq "CHECKPOINT_BRANCH cleared"          "" "$CHECKPOINT_BRANCH"
_assert_eq "CHECKPOINT_ORIGINAL_BRANCH cleared" "" "$CHECKPOINT_ORIGINAL_BRANCH"

# Error: CHECKPOINT_BRANCH not set
REPO=$(_mk_repo)
CHECKPOINT_BRANCH=""; CHECKPOINT_ORIGINAL_BRANCH=""
_assert_fail "fails without CHECKPOINT_BRANCH" rollback_to_checkpoint "$REPO"

# Error: CHECKPOINT_ORIGINAL_BRANCH not set
REPO=$(_mk_repo)
CHECKPOINT_BRANCH=""; CHECKPOINT_ORIGINAL_BRANCH=""
create_checkpoint "$REPO" >/dev/null 2>&1
CHECKPOINT_ORIGINAL_BRANCH=""    # clear only the original
_assert_fail "fails without CHECKPOINT_ORIGINAL_BRANCH" rollback_to_checkpoint "$REPO"
CHECKPOINT_BRANCH=""; CHECKPOINT_ORIGINAL_BRANCH=""  # clean state

# Error: nonexistent directory
CHECKPOINT_BRANCH="genpy/review/fake"; CHECKPOINT_ORIGINAL_BRANCH="main"
_assert_fail "fails with nonexistent directory" rollback_to_checkpoint "/no/existe"
CHECKPOINT_BRANCH=""; CHECKPOINT_ORIGINAL_BRANCH=""

# ─── Full cycle: create → rollback → create again ────────────────────────────

echo ""
echo "── Full cycle ───────────────────────────────────────────────────────────"

REPO=$(_mk_repo)
CHECKPOINT_BRANCH=""; CHECKPOINT_ORIGINAL_BRANCH=""

create_checkpoint "$REPO" >/dev/null 2>&1
FIRST_BRANCH="$CHECKPOINT_BRANCH"
rollback_to_checkpoint "$REPO" >/dev/null 2>&1

# Small pause so the timestamp differs if the clock is at second resolution
sleep 1

create_checkpoint "$REPO" >/dev/null 2>&1
SECOND_BRANCH="$CHECKPOINT_BRANCH"

_assert_current_branch "second review: HEAD on new branch" "$REPO" "$SECOND_BRANCH"
[[ "$FIRST_BRANCH" != "$SECOND_BRANCH" ]] \
  && _ok "two checkpoints produce different branches" \
  || _fail "two distinct checkpoints" "both='$FIRST_BRANCH'"
_assert_branch_gone "first branch deleted after first rollback" "$REPO" "$FIRST_BRANCH"

rollback_to_checkpoint "$REPO" >/dev/null 2>&1
_assert_current_branch "back on main after second rollback" "$REPO" "main"

# ─── Summary ──────────────────────────────────────────────────────────────────

echo ""
echo "─────────────────────────────────────────────────────────────────────────"
echo "  Result: ${_PASS} PASS  /  ${_FAIL} FAIL"
[[ "$_FAIL" -gt 0 ]] && echo "" && exit 1
echo ""
