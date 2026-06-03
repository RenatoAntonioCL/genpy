#!/usr/bin/env bash
set -euo pipefail
# =============================================================================
# GenPy — lib/core/errors.sh (v1.0.0-alpha)
#
# Centralized error handling and cleanup.
#
# Provides:
#   - global trap for unexpected errors
#   - die() function as the single error exit point
#   - cleanup() for cleanup tasks on exit
# =============================================================================

# ─── Cleanup state ───────────────────────────────────────────────────────────

GENPY_CLEANUP_DIR=""

# ─── Global trap ─────────────────────────────────────────────────────────────

_genpy_cleanup() {
  local exit_code=$?

  if [[ $exit_code -ne 0 && -n "$GENPY_CLEANUP_DIR" && -d "$GENPY_CLEANUP_DIR" ]]; then
    echo -e "\n  ⚠️  Error detected — cleaning up partial directory: $GENPY_CLEANUP_DIR"
    rm -rf "$GENPY_CLEANUP_DIR"
    echo -e "  🗑️  Directory removed."
  fi
}

trap '_genpy_cleanup' EXIT
trap 'echo -e "\n  Operation cancelled." >&2; exit 130' INT TERM

# ─── Own minimal colors (without depending on utils.sh) ──────────────────────

_ERR_RED='\033[1;31m'
_ERR_NC='\033[0m'

# ─── die ─────────────────────────────────────────────────────────────────────

die() {
  local message="$1"
  local code="${2:-1}"

  if declare -f print_error &>/dev/null; then
    print_error "$message"
  else
    echo -e " ${_ERR_RED}❌ Error:${_ERR_NC} $message" >&2
  fi

  exit "$code"
}

# ─── require_command ─────────────────────────────────────────────────────────

require_command() {
  local cmd="$1"
  local hint="${2:-Install '$cmd' before continuing.}"

  if ! command -v "$cmd" &>/dev/null; then
    die "$cmd is not installed. $hint"
  fi
}

# ─── require_dir ─────────────────────────────────────────────────────────────

require_dir() {
  local dir="$1"
  local message="${2:-Required directory not found: $dir}"

  [[ -d "$dir" ]] || die "$message"
}
