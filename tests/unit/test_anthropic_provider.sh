#!/usr/bin/env bash
# =============================================================================
# GenPy — tests/unit/test_anthropic_provider.sh
#
# Unit tests for lib/providers/anthropic.sh.
# Does not require a real API key — tests internal functions and mocks curl.
#
# Run from the repo root:
#   bash tests/unit/test_anthropic_provider.sh
# =============================================================================
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"

source "$REPO_ROOT/lib/providers/anthropic.sh"

# ─── Mini framework ───────────────────────────────────────────────────────────

_PASS=0; _FAIL=0

_ok() {
  echo "  PASS  $1"
  (( _PASS++ )) || true
}

_fail() {
  echo "  FAIL  $1"
  echo "        $2"
  (( _FAIL++ )) || true
}

_assert_eq() {
  local desc="$1" got="$2" want="$3"
  if [[ "$got" == "$want" ]]; then
    _ok "$desc"
  else
    _fail "$desc" "expected: '$want'  got: '$got'"
  fi
}

# ─── _anthropic_detect_model ─────────────────────────────────────────────────

echo ""
echo "─── _anthropic_detect_model ───────────────────────────────────────────────"

(
  GENPY_MODEL="claude-sonnet-4-6"
  result=$(_anthropic_detect_model)
  [[ "$result" == "claude-sonnet-4-6" ]] \
    && { echo "  PASS  respects GENPY_MODEL when set"; } \
    || { echo "  FAIL  GENPY_MODEL not respected — got: $result"; exit 1; }
)

(
  unset GENPY_MODEL 2>/dev/null || true
  result=$(_anthropic_detect_model)
  [[ "$result" == "claude-haiku-4-5" ]] \
    && { echo "  PASS  fallback to claude-haiku-4-5"; } \
    || { echo "  FAIL  wrong fallback — got: $result"; exit 1; }
)
_PASS=$(( _PASS + 2 ))

# ─── _anthropic_json_encode ──────────────────────────────────────────────────

echo ""
echo "─── _anthropic_json_encode ────────────────────────────────────────────────"

result=$(printf 'hello world' | _anthropic_json_encode)
_assert_eq "plain text" "$result" '"hello world"'

result=$(printf 'line1\nline2' | _anthropic_json_encode)
_assert_eq "encoded newlines" "$result" '"line1\nline2"'

result=$(printf 'say "hi"' | _anthropic_json_encode)
_assert_eq "encoded double quotes" "$result" '"say \"hi\""'

result=$(printf '' | _anthropic_json_encode)
_assert_eq "empty string" "$result" '""'

# ─── _anthropic_extract_response ─────────────────────────────────────────────

echo ""
echo "─── _anthropic_extract_response ───────────────────────────────────────────"

tmpdir=$(mktemp -d)

cat > "$tmpdir/resp_ok.json" <<'JSON'
{"content":[{"type":"text","text":"def foo():\n    pass"}],"model":"claude-haiku-4-5","stop_reason":"end_turn"}
JSON

result=$(_anthropic_extract_response "$tmpdir/resp_ok.json")
_assert_eq "extracts .content[0].text from valid JSON" "$result" 'def foo():
    pass'

cat > "$tmpdir/resp_empty.json" <<'JSON'
{"content":[{"type":"text","text":""}],"model":"claude-haiku-4-5","stop_reason":"end_turn"}
JSON

result=$(_anthropic_extract_response "$tmpdir/resp_empty.json")
_assert_eq "empty text returns empty string" "$result" ""

cat > "$tmpdir/resp_nocontent.json" <<'JSON'
{"model":"claude-haiku-4-5","stop_reason":"end_turn"}
JSON

result=$(_anthropic_extract_response "$tmpdir/resp_nocontent.json")
_assert_eq "JSON without .content returns empty string" "$result" ""

cat > "$tmpdir/resp_bad.json" <<'JSON'
{not valid json}
JSON

if ! _anthropic_extract_response "$tmpdir/resp_bad.json" &>/dev/null; then
  _ok "malformed JSON returns error (rc != 0)"
else
  _fail "malformed JSON should fail" "rc was 0"
fi

rm -rf "$tmpdir"

# ─── ai_complete validation ──────────────────────────────────────────────────

echo ""
echo "─── ai_complete (validation) ────────────────────────────────────────────"

tmpdir=$(mktemp -d)

# Missing API key
(
  unset ANTHROPIC_API_KEY 2>/dev/null || true
  cat > "$tmpdir/prompt.txt" <<< "test prompt"
  if ! ai_complete "$tmpdir/prompt.txt" "$tmpdir/out.txt" 2>/dev/null; then
    echo "  PASS  fails without ANTHROPIC_API_KEY"
  else
    echo "  FAIL  should have failed without API key"; exit 1
  fi
)
_PASS=$(( _PASS + 1 ))

# Nonexistent prompt file
if ! ai_complete "$tmpdir/nonexistent.txt" "$tmpdir/out.txt" 2>/dev/null; then
  _ok "fails with nonexistent prompt file"
else
  _fail "should have failed with nonexistent prompt" "rc was 0"
fi

# Missing arguments
if ! ai_complete 2>/dev/null; then
  _ok "fails with no arguments"
else
  _fail "should have failed with no arguments" "rc was 0"
fi

rm -rf "$tmpdir"

# ─── Result ───────────────────────────────────────────────────────────────────

echo ""
echo "─────────────────────────────────────────────────────────────────────────"
printf "  Result: %d PASS  /  %d FAIL\n" "$_PASS" "$_FAIL"
[[ "$_FAIL" -eq 0 ]]
