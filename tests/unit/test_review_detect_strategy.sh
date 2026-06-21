#!/usr/bin/env bash
# =============================================================================
# GenPy — tests/unit/test_review_detect_strategy.sh
#
# Unit tests for _review_detect_strategy in lib/review.sh.
# Verifies blueprint.toml detection and extension fallback.
#
# Run from the repo root:
#   bash tests/unit/test_review_detect_strategy.sh
# =============================================================================
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
export LIB_DIR="$REPO_ROOT/lib"

source "$REPO_ROOT/lib/review.sh"

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

tmpdir=$(mktemp -d)

# ─── blueprint.toml detection ────────────────────────────────────────────────

echo ""
echo "─── blueprint.toml detection ────────────────────────────────────────────"

# Create a fake project with blueprint.toml
mkdir -p "$tmpdir/project/.genpy"
cat > "$tmpdir/project/.genpy/blueprint.toml" <<'TOML'
[meta]
language = "python"
TOML
touch "$tmpdir/project/main.unknown"

(
  cd "$tmpdir/project"
  result=$(_review_detect_strategy "main.unknown")
  if [[ "$result" == *"/review_strategies/python.sh" ]]; then
    echo "  PASS  blueprint.toml language = python detected"
  else
    echo "  FAIL  expected python strategy, got: $result"; exit 1
  fi
)
_PASS=$(( _PASS + 1 ))

# blueprint.toml with language = go
cat > "$tmpdir/project/.genpy/blueprint.toml" <<'TOML'
[meta]
language = "go"
TOML

(
  cd "$tmpdir/project"
  result=$(_review_detect_strategy "main.unknown")
  if [[ "$result" == *"/review_strategies/go.sh" ]]; then
    echo "  PASS  blueprint.toml language = go detected"
  else
    echo "  FAIL  expected go strategy, got: $result"; exit 1
  fi
)
_PASS=$(( _PASS + 1 ))

# blueprint.toml with unsupported language falls through to extension
cat > "$tmpdir/project/.genpy/blueprint.toml" <<'TOML'
[meta]
language = "rust"
TOML
touch "$tmpdir/project/main.py"

(
  cd "$tmpdir/project"
  result=$(_review_detect_strategy "main.py")
  if [[ "$result" == *"/review_strategies/python.sh" ]]; then
    echo "  PASS  unsupported blueprint language falls back to extension"
  else
    echo "  FAIL  expected python strategy from extension fallback, got: $result"; exit 1
  fi
)
_PASS=$(( _PASS + 1 ))

# ─── Extension fallback ─────────────────────────────────────────────────────

echo ""
echo "─── extension fallback ──────────────────────────────────────────────────"

rm -f "$tmpdir/project/.genpy/blueprint.toml"

for ext_case in "py:python" "go:go" "js:javascript" "ts:javascript" "jsx:javascript" "tsx:javascript"; do
  ext="${ext_case%%:*}"
  strategy="${ext_case##*:}"
  touch "$tmpdir/project/test_file.${ext}"
  (
    cd "$tmpdir/project"
    result=$(_review_detect_strategy "test_file.${ext}")
    if [[ "$result" == *"/review_strategies/${strategy}.sh" ]]; then
      echo "  PASS  .${ext} → ${strategy}"
    else
      echo "  FAIL  .${ext} expected ${strategy}, got: $result"; exit 1
    fi
  )
  _PASS=$(( _PASS + 1 ))
  rm -f "$tmpdir/project/test_file.${ext}"
done

# Unknown extension without blueprint → error
(
  cd "$tmpdir/project"
  if ! _review_detect_strategy "main.unknown" 2>/dev/null; then
    echo "  PASS  unknown extension without blueprint fails"
  else
    echo "  FAIL  should have failed for unknown extension"; exit 1
  fi
)
_PASS=$(( _PASS + 1 ))

rm -rf "$tmpdir"

# ─── Result ───────────────────────────────────────────────────────────────────

echo ""
echo "─────────────────────────────────────────────────────────────────────────"
printf "  Result: %d PASS  /  %d FAIL\n" "$_PASS" "$_FAIL"
[[ "$_FAIL" -eq 0 ]]
