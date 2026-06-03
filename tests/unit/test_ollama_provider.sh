#!/usr/bin/env bash
# =============================================================================
# GenPy — tests/unit/test_ollama_provider.sh
#
# Unit tests for lib/providers/ollama.sh.
# Does not require Ollama running — tests internal functions
# with local fixtures.
#
# Run from the repo root:
#   bash tests/unit/test_ollama_provider.sh
# =============================================================================
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"

source "$REPO_ROOT/lib/providers/ollama.sh"

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

_assert_nonempty() {
  local desc="$1" val="$2"
  if [[ -n "$val" ]]; then
    _ok "$desc"
  else
    _fail "$desc" "expected non-empty value"
  fi
}

# ─── _ollama_detect_model ─────────────────────────────────────────────────────

echo ""
echo "─── _ollama_detect_model ──────────────────────────────────────────────────"

(
  GENPY_MODEL="mistral:7b"
  result=$(_ollama_detect_model)
  [[ "$result" == "mistral:7b" ]] \
    && { echo "  PASS  respects GENPY_MODEL when set"; (( _PASS++ )) || true; } \
    || { echo "  FAIL  GENPY_MODEL not respected — got: $result"; (( _FAIL++ )) || true; }
)

(
  # Without GENPY_MODEL and Ollama unavailable → must return fallback
  unset GENPY_MODEL 2>/dev/null || true
  OLLAMA_HOST="http://127.0.0.1:1"  # closed port, immediate failure
  result=$(_ollama_detect_model)
  [[ "$result" == "qwen2.5:3b" ]] \
    && { echo "  PASS  fallback to qwen2.5:3b when Ollama does not respond"; (( _PASS++ )) || true; } \
    || { echo "  FAIL  wrong fallback — got: $result"; (( _FAIL++ )) || true; }
)

# ─── _ollama_json_encode ──────────────────────────────────────────────────────

echo ""
echo "─── _ollama_json_encode ───────────────────────────────────────────────────"

result=$(printf 'hello world' | _ollama_json_encode)
_assert_eq "plain text" "$result" '"hello world"'

result=$(printf 'line1\nline2' | _ollama_json_encode)
_assert_eq "encoded newlines" "$result" '"line1\nline2"'

result=$(printf 'say "hi"' | _ollama_json_encode)
_assert_eq "encoded double quotes" "$result" '"say \"hi\""'

result=$(printf 'path\\file' | _ollama_json_encode)
_assert_eq "encoded backslash" "$result" '"path\\file"'

result=$(printf '' | _ollama_json_encode)
_assert_eq "empty string" "$result" '""'

# ─── _ollama_extract_response ─────────────────────────────────────────────────

echo ""
echo "─── _ollama_extract_response ──────────────────────────────────────────────"

tmpdir=$(mktemp -d)

# Valid response with response field
cat > "$tmpdir/resp_ok.json" <<'JSON'
{"model":"qwen2.5:3b","response":"def foo():\n    pass","done":true}
JSON

result=$(_ollama_extract_response "$tmpdir/resp_ok.json")
_assert_eq "extracts .response from valid JSON" "$result" 'def foo():
    pass'

# Response with empty response
cat > "$tmpdir/resp_empty.json" <<'JSON'
{"model":"qwen2.5:3b","response":"","done":true}
JSON

result=$(_ollama_extract_response "$tmpdir/resp_empty.json")
_assert_eq "empty response returns empty string" "$result" ""

# JSON without response field
cat > "$tmpdir/resp_nofield.json" <<'JSON'
{"model":"qwen2.5:3b","done":true}
JSON

result=$(_ollama_extract_response "$tmpdir/resp_nofield.json")
_assert_eq "JSON without .response returns empty string" "$result" ""

# Malformed JSON
cat > "$tmpdir/resp_bad.json" <<'JSON'
{not valid json}
JSON

if ! _ollama_extract_response "$tmpdir/resp_bad.json" &>/dev/null; then
  _ok "malformed JSON returns error (rc != 0)"
else
  _fail "malformed JSON should fail" "rc was 0"
fi

rm -rf "$tmpdir"

# ─── ai_complete with mock ────────────────────────────────────────────────────

echo ""
echo "─── ai_complete (using ollama_mock) ─────────────────────────────────────"

# Override ai_complete with the mock for this test block
source "$REPO_ROOT/tests/mocks/ollama_mock.sh"

tmpdir=$(mktemp -d)

# Prompt with Section 4 defined
cat > "$tmpdir/prompt_with_s4.txt" <<'EOF'
=== SECTION 1: ROLE AND CONSTRAINTS ===
You are an expert reviewer.

=== SECTION 2: REVIEW GOAL ===
Improve quality.

=== SECTION 3: CONTEXT (READ-ONLY) ===
import os

=== SECTION 4: TARGET FRAGMENT ===
def hello():
    print("hi")
EOF

ai_complete "$tmpdir/prompt_with_s4.txt" "$tmpdir/output.txt" ""
got=$(cat "$tmpdir/output.txt")

if [[ "$got" == *"def hello"* ]]; then
  _ok "mock extracts only the content of Section 4"
else
  _fail "mock did not extract Section 4" "got: $got"
fi

if [[ "$got" == *"ROLE AND CONSTRAINTS"* ]]; then
  _fail "output contains text from Section 1 (should not)" "got: $got"
else
  _ok "output does not contain prompt sections"
fi

# Prompt without Section 4 → copies everything
cat > "$tmpdir/prompt_no_s4.txt" <<'EOF'
Plain code without section markers
def bar():
    return 42
EOF

ai_complete "$tmpdir/prompt_no_s4.txt" "$tmpdir/output2.txt" ""
got2=$(cat "$tmpdir/output2.txt")
if [[ "$got2" == *"def bar"* ]]; then
  _ok "mock without Section 4 copies the full prompt"
else
  _fail "mock without Section 4 did not copy the prompt" "got: $got2"
fi

# Empty prompt file → rc 1 (file does not exist)
if ! ai_complete "$tmpdir/nonexistent.txt" "$tmpdir/out.txt" "" 2>/dev/null; then
  _ok "ai_complete fails (rc != 0) with nonexistent prompt"
else
  _fail "should have failed with nonexistent prompt" "rc was 0"
fi

rm -rf "$tmpdir"

# ─── Result ───────────────────────────────────────────────────────────────────

echo ""
echo "─────────────────────────────────────────────────────────────────────────"
printf "  Result: %d PASS  /  %d FAIL\n" "$_PASS" "$_FAIL"
[[ "$_FAIL" -eq 0 ]]
