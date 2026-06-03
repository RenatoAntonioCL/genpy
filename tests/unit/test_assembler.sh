#!/usr/bin/env bash
# =============================================================================
# GenPy — tests/unit/test_assembler.sh
#
# Unit tests for lib/assembler.sh.
# Run from the repo root:
#   bash tests/unit/test_assembler.sh
# =============================================================================
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
FIXTURE_PY="$REPO_ROOT/tests/fixtures/sample.py"
FIXTURE_TXT="$REPO_ROOT/tests/fixtures/sample_assembler.txt"
STRATEGY="$REPO_ROOT/lib/review_strategies/python.sh"

source "$REPO_ROOT/lib/assembler.sh"

# ─── Test framework ───────────────────────────────────────────────────────────

_PASS=0; _FAIL=0
_TMPDIR=$(mktemp -d)
trap 'rm -rf "$_TMPDIR"' EXIT

_assert_contains() {
  local desc="$1" haystack="$2" needle="$3"
  if printf '%s' "$haystack" | grep -qF "$needle"; then
    echo "  PASS  $desc"
    (( _PASS++ )) || true
  else
    echo "  FAIL  $desc"
    echo "        looking for: $(printf '%q' "$needle")"
    echo "        in:          $(printf '%s' "$haystack" | head -3)"
    (( _FAIL++ )) || true
  fi
}

_assert_not_contains() {
  local desc="$1" haystack="$2" needle="$3"
  if ! printf '%s' "$haystack" | grep -qF "$needle"; then
    echo "  PASS  $desc"
    (( _PASS++ )) || true
  else
    echo "  FAIL  $desc (should not contain: $(printf '%q' "$needle"))"
    (( _FAIL++ )) || true
  fi
}

_assert_not_empty() {
  local desc="$1" value="$2"
  if [[ -n "$value" ]]; then
    echo "  PASS  $desc"
    (( _PASS++ )) || true
  else
    echo "  FAIL  $desc (empty value)"
    (( _FAIL++ )) || true
  fi
}

_assert_equals() {
  local desc="$1" expected="$2" actual="$3"
  if [[ "$expected" == "$actual" ]]; then
    echo "  PASS  $desc"
    (( _PASS++ )) || true
  else
    echo "  FAIL  $desc"
    echo "        expected: $(printf '%q' "$expected")"
    echo "        got:      $(printf '%q' "$actual")"
    (( _FAIL++ )) || true
  fi
}

_assert_error() {
  local desc="$1"; shift
  local fn="$1"; shift
  if ! "$fn" "$@" 2>/dev/null; then
    echo "  PASS  $desc (expected error)"
    (( _PASS++ )) || true
  else
    echo "  FAIL  $desc (should have failed but succeeded)"
    (( _FAIL++ )) || true
  fi
}

# ─── build_review_context ─────────────────────────────────────────────────────

echo ""
echo "── build_review_context ─────────────────────────────────────────────────"

_ctx_file="$_TMPDIR/context.txt"
build_review_context "$FIXTURE_PY" "$STRATEGY" > "$_ctx_file"
_ctx=$(cat "$_ctx_file")

_assert_not_empty "produces non-empty output" "$_ctx"

_assert_contains "includes import os"                   "$_ctx" "import os"
_assert_contains "includes import sys"                  "$_ctx" "import sys"
_assert_contains "includes from typing import Optional" "$_ctx" "from typing import Optional"

_assert_contains "includes signature def get_config"        "$_ctx" "def get_config"
_assert_contains "includes signature async def fetch_data"  "$_ctx" "async def fetch_data"
_assert_contains "includes signature class ItemService"     "$_ctx" "class ItemService"

_assert_contains "includes language rules"         "$_ctx" "type hints"

_assert_error "fails with nonexistent file" \
  build_review_context "/no/existe.py" "$STRATEGY"

_assert_error "fails with nonexistent strategy" \
  build_review_context "$FIXTURE_PY" "/no/existe.sh"

_assert_error "fails with missing argument" \
  build_review_context "$FIXTURE_PY"

# ─── assemble_prompt ──────────────────────────────────────────────────────────

echo ""
echo "── assemble_prompt ──────────────────────────────────────────────────────"

# Prepare test focal chunk
_chunk_file="$_TMPDIR/focal_chunk.txt"
printf '%s\n' "def get_config(key: str) -> Optional[str]:" \
              "    return os.getenv(key)" > "$_chunk_file"

_goal="Add default value handling and type validation"

_prompt_file="$_TMPDIR/prompt.txt"
assemble_prompt "$_ctx_file" "$_chunk_file" "$_goal" > "$_prompt_file"
_prompt=$(cat "$_prompt_file")

_assert_contains "contains Section 1"  "$_prompt" "SECTION 1"
_assert_contains "contains Section 2"  "$_prompt" "SECTION 2"
_assert_contains "contains Section 3"  "$_prompt" "SECTION 3"
_assert_contains "contains Section 4"  "$_prompt" "SECTION 4"

_assert_contains "Section 2 carries the goal"       "$_prompt" "$_goal"
_assert_contains "Section 3 carries imports"        "$_prompt" "import os"
_assert_contains "Section 3 carries signatures"     "$_prompt" "def get_config"
_assert_contains "Section 4 carries the fragment"   "$_prompt" "return os.getenv(key)"

_assert_contains "contains key constraint"          "$_prompt" "ONLY the improved code"
_assert_not_contains "prompt does not expose internal markers" "$_prompt" "__GENPY_RULES__"
_assert_not_contains "prompt does not expose internal markers" "$_prompt" "__GENPY_IMPORTS__"

# Fragment with $ (must not expand as shell variable)
_dollar_chunk="$_TMPDIR/dollar_chunk.txt"
printf '%s\n' 'x = "${HOME}/path"' > "$_dollar_chunk"
_dollar_prompt=$(assemble_prompt "$_ctx_file" "$_dollar_chunk" "test")
_assert_contains "dollar sign in fragment does not expand" \
  "$_dollar_prompt" '${HOME}'

_assert_error "fails with nonexistent context" \
  assemble_prompt "/no/existe.txt" "$_chunk_file" "$_goal"

_assert_error "fails with nonexistent focal_chunk" \
  assemble_prompt "$_ctx_file" "/no/existe.txt" "$_goal"

_assert_error "fails with insufficient arguments" \
  assemble_prompt "$_ctx_file" "$_chunk_file"

# ─── reassemble_file ──────────────────────────────────────────────────────────

echo ""
echo "── reassemble_file ──────────────────────────────────────────────────────"

# FIXTURE_TXT has 7 lines: ALPHA BRAVO CHARLIE DELTA ECHO FOXTROT GOLF

# Prepare revised chunk — strings different from originals to avoid
# false positives in _assert_not_contains (grep -qF searches substrings)
_revised="$_TMPDIR/revised.txt"
printf '%s\n' "LINE4_NEW" "LINE5_NEW" > "$_revised"

# happy path: head + revised + tail (start=4, end=5)
_result=$(reassemble_file "$FIXTURE_TXT" "$_revised" 4 5)
_assert_contains "head preserved (ALPHA)"   "$_result" "ALPHA"
_assert_contains "head preserved (CHARLIE)" "$_result" "CHARLIE"
_assert_contains "revised chunk present"    "$_result" "LINE4_NEW"
_assert_contains "tail preserved (FOXTROT)" "$_result" "FOXTROT"
_assert_contains "tail preserved (GOLF)"    "$_result" "GOLF"
_assert_not_contains "original DELTA removed" "$_result" "DELTA"
_assert_not_contains "original ECHO removed"  "$_result" "ECHO"

# Order: head before chunk, chunk before tail
_alpha_pos=$(printf '%s' "$_result" | grep -n "ALPHA"    | cut -d: -f1 | head -1 || true)
_rev_pos=$(  printf '%s' "$_result" | grep -n "LINE4_NEW" | cut -d: -f1 | head -1 || true)
_golf_pos=$( printf '%s' "$_result" | grep -n "GOLF"     | cut -d: -f1 | head -1 || true)
if [[ -n "$_alpha_pos" && -n "$_rev_pos" && -n "$_golf_pos" && \
      "$_alpha_pos" -lt "$_rev_pos" && "$_rev_pos" -lt "$_golf_pos" ]]; then
  echo "  PASS  order: head < chunk < tail"
  (( _PASS++ )) || true
else
  echo "  FAIL  wrong order: alpha=$_alpha_pos rev=$_rev_pos golf=$_golf_pos"
  (( _FAIL++ )) || true
fi

# start=1 → no head
_revised_single="$_TMPDIR/revised_single.txt"
printf '%s\n' "FIRST_REVISED" > "$_revised_single"
_result_no_head=$(reassemble_file "$FIXTURE_TXT" "$_revised_single" 1 1)
_assert_contains     "no head: chunk present"      "$_result_no_head" "FIRST_REVISED"
_assert_contains     "no head: tail preserved"     "$_result_no_head" "BRAVO"
_assert_not_contains "no head: original ALPHA gone" "$_result_no_head" "ALPHA"

# end=total → no tail
_total_lines=$(awk 'END{print NR}' "$FIXTURE_TXT")
_result_no_tail=$(reassemble_file "$FIXTURE_TXT" "$_revised_single" "$_total_lines" "$_total_lines")
_assert_contains     "no tail: head preserved" "$_result_no_tail" "ALPHA"
_assert_contains     "no tail: chunk present"  "$_result_no_tail" "FIRST_REVISED"
_assert_not_contains "no tail: GOLF gone"       "$_result_no_tail" "GOLF"

# full replacement (start=1, end=total)
_full_revised="$_TMPDIR/full_revised.txt"
printf '%s\n' "ONLY_LINE" > "$_full_revised"
_result_full=$(reassemble_file "$FIXTURE_TXT" "$_full_revised" 1 "$_total_lines")
_assert_equals     "full replacement: single line" \
  "ONLY_LINE" "$(printf '%s' "$_result_full" | tr -d '\n')"

# Errors
_assert_error "fails with nonexistent original" \
  reassemble_file "/no/existe.txt" "$_revised" 4 5

_assert_error "fails with nonexistent revised" \
  reassemble_file "$FIXTURE_TXT" "/no/existe.txt" 4 5

_assert_error "fails with start > end" \
  reassemble_file "$FIXTURE_TXT" "$_revised" 5 4

_assert_error "fails with end > total" \
  reassemble_file "$FIXTURE_TXT" "$_revised" 1 999

_assert_error "fails with start=0" \
  reassemble_file "$FIXTURE_TXT" "$_revised" 0 3

_assert_error "fails with non-numeric args" \
  reassemble_file "$FIXTURE_TXT" "$_revised" "a" "b"

_assert_error "fails with insufficient arguments" \
  reassemble_file "$FIXTURE_TXT" "$_revised" 4

# ─── Summary ──────────────────────────────────────────────────────────────────

echo ""
echo "─────────────────────────────────────────────────────────────────────────"
echo "  Result: ${_PASS} PASS  /  ${_FAIL} FAIL"
if [[ "$_FAIL" -gt 0 ]]; then
  echo ""
  exit 1
fi
echo ""
