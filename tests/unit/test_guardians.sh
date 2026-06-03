#!/usr/bin/env bash
# =============================================================================
# GenPy — tests/unit/test_guardians.sh
#
# Unit tests for lib/guardians.sh.
# Run from the repo root:
#   bash tests/unit/test_guardians.sh
# =============================================================================
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"

source "$REPO_ROOT/lib/guardians.sh"

GUARDIAN_NON_INTERACTIVE=1   # no interactive prompts in tests

# ─── Mini framework ───────────────────────────────────────────────────────────

_PASS=0; _FAIL=0

_assert_pass() {
  local desc="$1"; shift
  if "$@" 2>/dev/null; then
    echo "  PASS  $desc"
    (( _PASS++ )) || true
  else
    echo "  FAIL  $desc (expected success, got failure)"
    (( _FAIL++ )) || true
  fi
}

_assert_fail() {
  local desc="$1" exp_gate="$2"; shift 2
  if ! "$@" 2>/dev/null; then
    if [[ -n "$exp_gate" && "$GUARDIAN_FAILED_GATE" != "$exp_gate" ]]; then
      echo "  FAIL  $desc (failed OK but gate='${GUARDIAN_FAILED_GATE}', expected '${exp_gate}')"
      (( _FAIL++ )) || true
    else
      echo "  PASS  $desc (expected failure, gate=${GUARDIAN_FAILED_GATE})"
      (( _PASS++ )) || true
    fi
  else
    echo "  FAIL  $desc (should have failed but passed)"
    (( _FAIL++ )) || true
  fi
}

_assert_eq() {
  local desc="$1" expected="$2" actual="$3"
  if [[ "$actual" == "$expected" ]]; then
    echo "  PASS  $desc"
    (( _PASS++ )) || true
  else
    echo "  FAIL  $desc (expected='$expected' got='$actual')"
    (( _FAIL++ )) || true
  fi
}

# ─── Mock strategy ────────────────────────────────────────────────────────────
# validate_syntax fails if the file contains SYNTAX_ERROR_MARKER.
# Self-contained — does not require python3.

MOCK_STRATEGY=$(mktemp /tmp/genpy_mock_strat_XXXXX.sh)
cat > "$MOCK_STRATEGY" <<'STRAT'
validate_syntax() {
  ! grep -q "SYNTAX_ERROR_MARKER" "$1"
}
extract_signatures() {
  grep -E '^((async )?def |class )' "$1" || true
}
get_prompt_rules() { echo "mock rules"; }
STRAT

_TMPFILES=()
_cleanup() { rm -f "${_TMPFILES[@]}" "$MOCK_STRATEGY" 2>/dev/null || true; }
trap _cleanup EXIT

_tmp() {
  local f; f=$(mktemp /tmp/genpy_grd_XXXXX)
  _TMPFILES+=("$f"); echo "$f"
}

# ─── G1: Non-empty output ─────────────────────────────────────────────────────

echo ""
echo "── G1: not_empty ────────────────────────────────────────────────────────"

f=$(_tmp)
_assert_fail "empty file"          "G1"  guardian_g1_not_empty "$f"
_assert_eq   "FAILED_GATE=G1"      "G1"  "$GUARDIAN_FAILED_GATE"

printf 'def foo():\n    pass\n' > "$f"
_assert_pass "file with content"        guardian_g1_not_empty "$f"

GONE=$(mktemp /tmp/genpy_grd_XXXXX); rm -f "$GONE"
_assert_fail "nonexistent file"    "G1"  guardian_g1_not_empty "$GONE"

# ─── G2: No markdown or conversational text ───────────────────────────────────

echo ""
echo "── G2: no_markdown ──────────────────────────────────────────────────────"

f=$(_tmp)

# Fence ``` — use heredoc to avoid escape issues with printf
cat > "$f" <<'PY'
```python
def foo(): pass
```
PY
_assert_fail "code fence \`\`\`"        "G2"  guardian_g2_no_markdown "$f"

# Horizontal rule --- (heredoc avoids printf interpreting it as an option)
cat > "$f" <<'PY'
---
def foo(): pass
PY
_assert_fail "horizontal rule ---"      "G2"  guardian_g2_no_markdown "$f"

# Horizontal rule ===
cat > "$f" <<'PY'
===
def foo(): pass
PY
_assert_fail "horizontal rule ==="      "G2"  guardian_g2_no_markdown "$f"

# Conversational text: "Here is"
cat > "$f" <<'PY'
Here is the updated function:
def foo(): pass
PY
_assert_fail "opener 'Here is'"         "G2"  guardian_g2_no_markdown "$f"

# Conversational text: "Sure,"
cat > "$f" <<'PY'
Sure, here it is:
def foo(): pass
PY
_assert_fail "opener 'Sure,'"           "G2"  guardian_g2_no_markdown "$f"

# Conversational text: "The following"
cat > "$f" <<'PY'
The following function has been updated:
def foo(): pass
PY
_assert_fail "opener 'The following'"   "G2"  guardian_g2_no_markdown "$f"

# Valid Python with # (comment, not heading)
cat > "$f" <<'PY'
## main module
def foo():
    # internal comment
    return 42
PY
_assert_pass "Python with # and ##"     guardian_g2_no_markdown "$f"

# **kwargs: double asterisk is not markdown bold
cat > "$f" <<'PY'
def foo(**kwargs):
    return kwargs
PY
_assert_pass "Python with **kwargs"     guardian_g2_no_markdown "$f"

# async + type hints
cat > "$f" <<'PY'
async def fetch(url: str) -> dict:
    return {}
PY
_assert_pass "async def with type hints" guardian_g2_no_markdown "$f"

# ─── G3: Line count 70%–130% ─────────────────────────────────────────────────

echo ""
echo "── G3: line_count ───────────────────────────────────────────────────────"

orig=$(_tmp); chunk=$(_tmp)

# 10 reference lines
printf '%s\n' {1..10} > "$orig"

printf '%s\n' {1..10} > "$chunk"
_assert_pass "100%: same lines"         guardian_g3_line_count "$chunk" "$orig"

printf '%s\n' {1..7} > "$chunk"
_assert_pass "70%: lower bound"         guardian_g3_line_count "$chunk" "$orig"

printf '%s\n' {1..13} > "$chunk"
_assert_pass "130%: upper bound"        guardian_g3_line_count "$chunk" "$orig"

printf '%s\n' {1..6} > "$chunk"
_assert_fail "60%: below minimum"      "G3"  guardian_g3_line_count "$chunk" "$orig"

printf '%s\n' {1..14} > "$chunk"
_assert_fail "140%: above maximum"     "G3"  guardian_g3_line_count "$chunk" "$orig"

# Empty original → pass (safe edge case)
: > "$orig"; printf 'x\n' > "$chunk"
_assert_pass "empty original: skip"     guardian_g3_line_count "$chunk" "$orig"

# ─── G4: Valid syntax ─────────────────────────────────────────────────────────

echo ""
echo "── G4: syntax ───────────────────────────────────────────────────────────"

f=$(_tmp)

# No marker → validate_syntax returns 0 → pass
cat > "$f" <<'PY'
def foo():
    return 42
PY
_assert_pass "chunk without marker"              guardian_g4_syntax "$f" "$MOCK_STRATEGY"

# With marker → validate_syntax returns 1 → fail
cat > "$f" <<'PY'
def foo():
    SYNTAX_ERROR_MARKER
PY
_assert_fail "chunk with SYNTAX_ERROR_MARKER" "G4"  guardian_g4_syntax "$f" "$MOCK_STRATEGY"

# Indented method chunk → G4 skips it → pass
cat > "$f" <<'PY'
    def bar(self):
        return True
PY
_assert_pass "indented method: G4 skip"          guardian_g4_syntax "$f" "$MOCK_STRATEGY"

# Indented method + marker → G4 still skips due to indentation → pass
cat > "$f" <<'PY'
    def bar(self):
        SYNTAX_ERROR_MARKER
PY
_assert_pass "indented method + marker: G4 skip" guardian_g4_syntax "$f" "$MOCK_STRATEGY"

# ─── G5: Public signatures present ───────────────────────────────────────────

echo ""
echo "── G5: signatures ───────────────────────────────────────────────────────"

orig=$(_tmp); chunk=$(_tmp)

# All public signatures preserved → pass
cat > "$orig" <<'PY'
class ItemService:
    def create_item(self, name):
        return name

    def delete_item(self, id):
        return True

    def _private_helper(self):
        pass
PY
cp "$orig" "$chunk"
_assert_pass "all public signatures present"         guardian_g5_signatures "$chunk" "$orig" "$MOCK_STRATEGY"

# AI removes delete_item → G5 fails
cat > "$chunk" <<'PY'
class ItemService:
    def create_item(self, name):
        return name

    def _private_helper(self):
        pass
PY
_assert_fail "public signature 'delete_item' missing"  "G5"  guardian_g5_signatures "$chunk" "$orig" "$MOCK_STRATEGY"
_assert_eq   "DETAIL mentions delete_item" "1" \
  "$([[ "$GUARDIAN_FAILED_DETAIL" == *"delete_item"* ]] && echo 1 || echo 0)"

# AI removes only the private → pass (privates ignored in G5)
cat > "$chunk" <<'PY'
class ItemService:
    def create_item(self, name):
        return name

    def delete_item(self, id):
        return True
PY
_assert_pass "only private removed: G5 ignores"       guardian_g5_signatures "$chunk" "$orig" "$MOCK_STRATEGY"

# Dunder __init__ is public and must be verified
cat > "$orig" <<'PY'
class Foo:
    def __init__(self, x):
        self.x = x

    def compute(self):
        return self.x
PY
cp "$orig" "$chunk"
_assert_pass "__init__ and compute present"             guardian_g5_signatures "$chunk" "$orig" "$MOCK_STRATEGY"

# AI removes __init__ → G5 must fail
cat > "$chunk" <<'PY'
class Foo:
    def compute(self):
        return 0
PY
_assert_fail "__init__ dunder missing → G5 fails"     "G5"  guardian_g5_signatures "$chunk" "$orig" "$MOCK_STRATEGY"

# No signatures in original → vacuous pass
: > "$orig"; printf 'x = 1\n' > "$chunk"
_assert_pass "no signatures in original: vacuous pass" guardian_g5_signatures "$chunk" "$orig" "$MOCK_STRATEGY"

# Top-level function in original
cat > "$orig" <<'PY'
def greet(name: str) -> str:
    return f"Hello, {name}"

def farewell(name: str) -> str:
    return f"Bye, {name}"
PY
cp "$orig" "$chunk"
_assert_pass "top-level functions preserved"           guardian_g5_signatures "$chunk" "$orig" "$MOCK_STRATEGY"

cat > "$chunk" <<'PY'
def greet(name: str) -> str:
    return f"Hello, {name}"
PY
_assert_fail "top-level function 'farewell' missing"   "G5"  guardian_g5_signatures "$chunk" "$orig" "$MOCK_STRATEGY"

# ─── run_guardians: non-interactive mode ─────────────────────────────────────

echo ""
echo "── run_guardians (non-interactive) ──────────────────────────────────────"

orig=$(_tmp); chunk=$(_tmp)

# Fully valid chunk → return 0
cat > "$orig" <<'PY'
def greet(name: str) -> str:
    return f"Hello, {name}"
PY
cp "$orig" "$chunk"
rc=0; run_guardians "$chunk" "$orig" "$MOCK_STRATEGY" 2>/dev/null || rc=$?
_assert_eq "valid chunk → rc=0"   "0" "$rc"

# G1 fails: empty chunk → auto-abort → rc=1, gate=G1
: > "$chunk"
rc=0; run_guardians "$chunk" "$orig" "$MOCK_STRATEGY" 2>/dev/null || rc=$?
_assert_eq "G1 fails → rc=1"      "1" "$rc"
_assert_eq "FAILED_GATE=G1"       "G1" "$GUARDIAN_FAILED_GATE"

# G2 fails: markdown → auto-abort → rc=1, gate=G2
cat > "$chunk" <<'PY'
```python
def greet(): pass
```
PY
rc=0; run_guardians "$chunk" "$orig" "$MOCK_STRATEGY" 2>/dev/null || rc=$?
_assert_eq "G2 fails → rc=1"      "1" "$rc"
_assert_eq "FAILED_GATE=G2"       "G2" "$GUARDIAN_FAILED_GATE"

# G3 fails: too many lines → auto-abort → rc=1, gate=G3
printf '%s\n' {1..100} > "$chunk"
rc=0; run_guardians "$chunk" "$orig" "$MOCK_STRATEGY" 2>/dev/null || rc=$?
_assert_eq "G3 fails → rc=1"      "1" "$rc"
_assert_eq "FAILED_GATE=G3"       "G3" "$GUARDIAN_FAILED_GATE"

# G4 fails: syntax error → auto-abort → rc=1, gate=G4
cat > "$chunk" <<'PY'
def greet(name: str) -> str:
    SYNTAX_ERROR_MARKER
PY
rc=0; run_guardians "$chunk" "$orig" "$MOCK_STRATEGY" 2>/dev/null || rc=$?
_assert_eq "G4 fails → rc=1"      "1" "$rc"
_assert_eq "FAILED_GATE=G4"       "G4" "$GUARDIAN_FAILED_GATE"

# G5 fails: missing signature → auto-abort → rc=1, gate=G5
# orig: 4 lines (no blank lines between functions so G3 tolerates a 3-line chunk)
cat > "$orig" <<'PY'
def greet(name: str) -> str:
    return f"Hello, {name}"
def farewell(name: str) -> str:
    return f"Bye, {name}"
PY
# chunk: 3 lines — within 70-130% of 4 (min=2, max=5) so G3 passes
# farewell missing → G5 fails before G3 catches it
cat > "$chunk" <<'PY'
def greet(name: str) -> str:
    # Improved greeting
    return f"Hello, {name}"
PY
rc=0; run_guardians "$chunk" "$orig" "$MOCK_STRATEGY" 2>/dev/null || rc=$?
_assert_eq "G5 fails → rc=1"      "1" "$rc"
_assert_eq "FAILED_GATE=G5"       "G5" "$GUARDIAN_FAILED_GATE"

# Gate order: G1 evaluated before G2 when both fail
cat > "$orig" <<'PY'
def foo(): pass
PY
: > "$chunk"   # empty → G1 fails before any other
rc=0; run_guardians "$chunk" "$orig" "$MOCK_STRATEGY" 2>/dev/null || rc=$?
_assert_eq "order: G1 before G2"  "G1" "$GUARDIAN_FAILED_GATE"

# ─── Summary ──────────────────────────────────────────────────────────────────

echo ""
echo "─────────────────────────────────────────────────────────────────────────"
echo "  Result: ${_PASS} PASS  /  ${_FAIL} FAIL"
if [[ "$_FAIL" -gt 0 ]]; then
  echo ""
  exit 1
fi
echo ""
