#!/usr/bin/env bash
# =============================================================================
# GenPy — tests/unit/test_resolver.sh
#
# Unit tests for lib/resolver.sh.
# Run from the repo root:
#   bash tests/unit/test_resolver.sh
# =============================================================================
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
FIXTURE="$REPO_ROOT/tests/fixtures/sample.py"

source "$REPO_ROOT/lib/resolver.sh"

# ─── Mini test framework ──────────────────────────────────────────────────────

_PASS=0; _FAIL=0

_assert_range() {
  local desc="$1" exp_start="$2" exp_end="$3"
  if [[ "$RESOLVE_START" -eq "$exp_start" && "$RESOLVE_END" -eq "$exp_end" ]]; then
    echo "  PASS  $desc"
    (( _PASS++ )) || true
  else
    echo "  FAIL  $desc"
    echo "        expected: START=$exp_start END=$exp_end"
    echo "        got:      START=${RESOLVE_START:-?} END=${RESOLVE_END:-?}"
    (( _FAIL++ )) || true
  fi
}

_assert_error() {
  local desc="$1"; shift
  if ! resolve_range "$@" 2>/dev/null; then
    echo "  PASS  $desc (expected error)"
    (( _PASS++ )) || true
  else
    echo "  FAIL  $desc (should have failed but returned START=$RESOLVE_START END=$RESOLVE_END)"
    (( _FAIL++ )) || true
  fi
}

# ─── --lines ─────────────────────────────────────────────────────────────────

echo ""
echo "── --lines ──────────────────────────────────────────────────────────────"

resolve_range --lines 13-14 "$FIXTURE"
_assert_range "explicit range in the middle of file" 13 14

resolve_range --lines 1-1 "$FIXTURE"
_assert_range "single line (first)" 1 1

resolve_range --lines 38-40 "$FIXTURE"
_assert_range "last lines" 38 40

_assert_error "start > end"             --lines 10-5    "$FIXTURE"
_assert_error "end > total"             --lines 1-999   "$FIXTURE"
_assert_error "invalid format"          --lines 10      "$FIXTURE"
_assert_error "start zero"              --lines 0-5     "$FIXTURE"

# ─── --function ───────────────────────────────────────────────────────────────

echo ""
echo "── --function ───────────────────────────────────────────────────────────"

resolve_range --function get_config "$FIXTURE"
_assert_range "sync top-level function (first)" 9 12

resolve_range --function fetch_data "$FIXTURE"
_assert_range "async top-level function" 13 16

resolve_range --function decorated_func "$FIXTURE"
_assert_range "function with decorator just before" 18 21

_assert_error "nonexistent function"    --function nonexistent "$FIXTURE"

# ─── --class ──────────────────────────────────────────────────────────────────

echo ""
echo "── --class ──────────────────────────────────────────────────────────────"

resolve_range --class ItemService "$FIXTURE"
_assert_range "class with methods (first class)" 22 37

resolve_range --class Config "$FIXTURE"
_assert_range "class at end of file (no next top-level)" 38 40

_assert_error "nonexistent class"       --class NonExistent "$FIXTURE"

# ─── --method ─────────────────────────────────────────────────────────────────

echo ""
echo "── --method ─────────────────────────────────────────────────────────────"

resolve_range --method ItemService.__init__ "$FIXTURE"
_assert_range "first method of the class" 23 25

resolve_range --method ItemService.create_item "$FIXTURE"
_assert_range "sync method in the middle" 26 28

resolve_range --method ItemService.delete_item "$FIXTURE"
_assert_range "async method in the middle" 29 31

resolve_range --method ItemService._private_helper "$FIXTURE"
_assert_range "last method (no next sibling)" 32 37

_assert_error "nonexistent class"       --method Ghost.method      "$FIXTURE"
_assert_error "nonexistent method"      --method ItemService.ghost  "$FIXTURE"
_assert_error "format without dot"      --method ItemService        "$FIXTURE"

# ─── General errors ───────────────────────────────────────────────────────────

echo ""
echo "── General errors ───────────────────────────────────────────────────────"

_assert_error "file not found"          --function get_config "/no/existe.py"
_assert_error "unknown mode"            --unknown get_config   "$FIXTURE"
_assert_error "insufficient arguments (2)"

# ─── Summary ──────────────────────────────────────────────────────────────────

echo ""
echo "─────────────────────────────────────────────────────────────────────────"
echo "  Result: ${_PASS} PASS  /  ${_FAIL} FAIL"
if [[ "$_FAIL" -gt 0 ]]; then
  echo ""
  exit 1
fi
echo ""
