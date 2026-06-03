#!/usr/bin/env bash
set -euo pipefail

# Include guard
[[ -n "${_GENPY_GUARDIANS_LOADED:-}" ]] && return 0
_GENPY_GUARDIANS_LOADED=1

# =============================================================================
# GenPy — lib/guardians.sh (v1.0.0-alpha)
#
# Runs the 5 AI output validation guardians, from cheapest to
# most expensive (ARCHITECTURE.md §5.4 step [7], decision B3).
#
# Public API
#   run_guardians CHUNK ORIG STRATEGY [RETRIES_DONE]
#     CHUNK        — file with model output (focal_chunk.tmp)
#     ORIG         — original chunk before sending to the model
#     STRATEGY     — path to review_strategies/python.sh (or other language)
#     RETRIES_DONE — AI retries already consumed (default 0)
#     Returns: 0=all pass, 1=abort, 2=retry (caller re-runs AI)
#
#   guardian_g1_not_empty  CHUNK
#   guardian_g2_no_markdown CHUNK
#   guardian_g3_line_count  CHUNK ORIG
#   guardian_g4_syntax      CHUNK STRATEGY
#   guardian_g5_signatures  CHUNK ORIG STRATEGY
#     Return: 0=pass, 1=fail
#     On failure: set GUARDIAN_FAILED_GATE and GUARDIAN_FAILED_DETAIL
#
# Configuration globals
#   GUARDIAN_MAX_RETRIES    — max AI retries allowed (default 2)
#   GUARDIAN_NON_INTERACTIVE=1 — forces auto-abort without prompt (tests/CI)
#
# Output globals
#   GUARDIAN_FAILED_GATE    — "G1".."G5"
#   GUARDIAN_FAILED_DETAIL  — human-readable failure description
# =============================================================================

_GRD_RED='\033[0;31m'
_GRD_YELLOW='\033[1;33m'
_GRD_NC='\033[0m'

GUARDIAN_FAILED_GATE=""
GUARDIAN_FAILED_DETAIL=""

# ─── Public orchestrator ─────────────────────────────────────────────────────

run_guardians() {
  if [[ $# -lt 3 ]]; then
    echo "Usage: run_guardians CHUNK ORIG STRATEGY [RETRIES_DONE]" >&2
    return 1
  fi

  local chunk="$1" orig="$2" strategy="$3"
  local retries_done="${4:-0}"
  local max_retries="${GUARDIAN_MAX_RETRIES:-2}"
  local remaining=$(( max_retries - retries_done ))

  GUARDIAN_FAILED_GATE=""
  GUARDIAN_FAILED_DETAIL=""

  while true; do
    if _grd_run_all "$chunk" "$orig" "$strategy"; then
      return 0
    fi

    _grd_print_failure

    local choice
    _grd_ask_choice choice "$remaining"

    case "$choice" in
      R) return 2 ;;
      A) return 1 ;;
      E)
        "${EDITOR:-vi}" "$chunk"
        GUARDIAN_FAILED_GATE=""
        GUARDIAN_FAILED_DETAIL=""
        ;;
    esac
  done
}

# ─── G1: Non-empty output ─────────────────────────────────────────────────────

guardian_g1_not_empty() {
  local file="$1"

  if [[ ! -s "$file" ]]; then
    GUARDIAN_FAILED_GATE="G1"
    GUARDIAN_FAILED_DETAIL="model output is empty or file does not exist"
    return 1
  fi
  return 0
}

# ─── G2: No markdown or conversational text ───────────────────────────────────

guardian_g2_no_markdown() {
  local file="$1"

  # Code fences (```), unambiguous in any language
  if grep -qE '^```' "$file"; then
    GUARDIAN_FAILED_GATE="G2"
    GUARDIAN_FAILED_DETAIL="markdown code fence detected (\`\`\` at line start)"
    return 1
  fi

  # Markdown horizontal rules
  if grep -qE '^(---+|===+)[[:space:]]*$' "$file"; then
    GUARDIAN_FAILED_GATE="G2"
    GUARDIAN_FAILED_DETAIL="markdown horizontal rule detected (--- or ===)"
    return 1
  fi

  # Conversational text at line start (case-insensitive)
  # Unambiguously non-code patterns
  if grep -qiE \
    "^(Here (is|are)|Here's|Sure[,!. ]|Certainly[,!. ]|Of course[,!. ]|I (will|'ll|have) |Below (is|are)|The (following|updated|revised) )" \
    "$file"; then
    GUARDIAN_FAILED_GATE="G2"
    GUARDIAN_FAILED_DETAIL="conversational text detected at line start"
    return 1
  fi

  return 0
}

# ─── G3: Line count between 70% and 130% of original ─────────────────────────

guardian_g3_line_count() {
  local chunk_file="$1" orig_file="$2"

  local orig_lines chunk_lines
  orig_lines=$(awk 'END {print NR}' "$orig_file")
  chunk_lines=$(awk 'END {print NR}' "$chunk_file")

  if [[ "$orig_lines" -eq 0 ]]; then
    return 0
  fi

  local min_lines max_lines
  min_lines=$(( orig_lines * 70 / 100 ))
  max_lines=$(( orig_lines * 130 / 100 ))
  [[ "$min_lines" -lt 1 ]] && min_lines=1

  if [[ "$chunk_lines" -lt "$min_lines" || "$chunk_lines" -gt "$max_lines" ]]; then
    GUARDIAN_FAILED_GATE="G3"
    GUARDIAN_FAILED_DETAIL="lines: output=${chunk_lines} original=${orig_lines} range=[${min_lines}–${max_lines}]"
    return 1
  fi
  return 0
}

# ─── G4: Valid syntax per the strategy ───────────────────────────────────────

guardian_g4_syntax() {
  local chunk_file="$1" strategy_file="$2"

  source "$strategy_file"

  # Method chunks have initial indentation and are not standalone files.
  # Full validate_syntax() runs at step [8] after reassembly.
  local first_line
  first_line=$(grep -m1 -E '.' "$chunk_file" 2>/dev/null || true)
  if [[ "$first_line" =~ ^[[:space:]] ]]; then
    return 0
  fi

  if ! validate_syntax "$chunk_file" 2>/dev/null; then
    GUARDIAN_FAILED_GATE="G4"
    GUARDIAN_FAILED_DETAIL="validate_syntax() failed — syntax error in chunk"
    return 1
  fi
  return 0
}

# ─── G5: Public signatures present ───────────────────────────────────────────

guardian_g5_signatures() {
  local chunk_file="$1" orig_file="$2" strategy_file="$3"

  source "$strategy_file"

  # Extract ALL signatures from the original: top-level and indented (methods).
  # The strategy defines extract_signatures for the top-level; here
  # we extend the pattern to also capture indented methods.
  local sigs
  sigs=$(grep -E \
    '^[[:space:]]*((async[[:space:]]+)?def[[:space:]]|class[[:space:]])' \
    "$orig_file" || true)

  [[ -z "$sigs" ]] && return 0

  local missing=() name sig
  while IFS= read -r sig; do
    [[ -z "$sig" ]] && continue

    # Extract the identifier following def/class
    name=$(printf '%s' "$sig" | \
      grep -oE '(def|class)[[:space:]]+[A-Za-z_][A-Za-z0-9_]*' | \
      grep -oE '[A-Za-z_][A-Za-z0-9_]*$')
    [[ -z "$name" ]] && continue

    # Skip single-underscore privates (_foo), preserve dunders (__init__)
    [[ "$name" =~ ^_[^_] ]] && continue

    # Verify that the name appears in the model's output
    grep -qE "\b${name}\b" "$chunk_file" || missing+=("$name")
  done <<< "$sigs"

  if [[ ${#missing[@]} -gt 0 ]]; then
    GUARDIAN_FAILED_GATE="G5"
    GUARDIAN_FAILED_DETAIL="public signatures missing from output: ${missing[*]}"
    return 1
  fi
  return 0
}

# ─── Internals ────────────────────────────────────────────────────────────────

# Runs G1–G5 in order; stops at the first failure.
_grd_run_all() {
  local chunk="$1" orig="$2" strategy="$3"
  guardian_g1_not_empty   "$chunk"                    || return 1
  guardian_g2_no_markdown "$chunk"                    || return 1
  guardian_g3_line_count  "$chunk" "$orig"            || return 1
  guardian_g4_syntax      "$chunk" "$strategy"        || return 1
  guardian_g5_signatures  "$chunk" "$orig" "$strategy" || return 1
  return 0
}

_grd_print_failure() {
  printf "\n  ${_GRD_RED}✗ Guardian %s failed${_GRD_NC}: %s\n" \
    "$GUARDIAN_FAILED_GATE" "$GUARDIAN_FAILED_DETAIL" >&2
}

# _grd_ask_choice NAMEREF REMAINING
# Assigns R, A or E to the nameref based on the user's choice.
# Non-interactive mode (no-TTY or GUARDIAN_NON_INTERACTIVE=1): auto-selects A.
_grd_ask_choice() {
  local -n _grd_ch="$1"
  local remaining="$2"

  if [[ ! -t 0 || "${GUARDIAN_NON_INTERACTIVE:-0}" == "1" ]]; then
    _grd_ch="A"
    return
  fi

  printf "\n" >&2
  if [[ "$remaining" -gt 0 ]]; then
    printf "  Retries remaining: %d  [R]etry  [A]bort  [E]dit → " \
      "$remaining" >&2
  else
    printf "  No retries available.  [A]bort  [E]dit → " >&2
  fi

  while true; do
    IFS= read -r _grd_ch
    _grd_ch="${_grd_ch^^}"
    if [[ "$remaining" -gt 0 && "$_grd_ch" =~ ^[RAE]$ ]]; then
      break
    elif [[ "$remaining" -le 0 && "$_grd_ch" =~ ^[AE]$ ]]; then
      break
    else
      printf "  Invalid option → " >&2
    fi
  done
}
