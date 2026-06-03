#!/usr/bin/env bash
set -euo pipefail

# Include guard
[[ -n "${_GENPY_ASSEMBLER_LOADED:-}" ]] && return 0
_GENPY_ASSEMBLER_LOADED=1

# =============================================================================
# GenPy — lib/assembler.sh (v1.0.0-alpha)
#
# Context, prompt and file reassembly.
# Implements ARCHITECTURE.md §5.4 steps [4], [5] and [8].
#
# Public API:
#   build_review_context FILE STRATEGY_FILE  → stdout (context blob)
#   assemble_prompt CONTEXT_FILE FOCAL_CHUNK_FILE GOAL → stdout (prompt)
#   reassemble_file ORIGINAL REVISED_CHUNK START END   → stdout (file)
#
# Strategy contract (must provide):
#   extract_signatures(file)  → prints signatures
#   get_prompt_rules()        → prints language rules
# =============================================================================

# Section markers in the context blob (must be unique lines)
_ASSEMBLER_MARK_RULES="__GENPY_RULES__"
_ASSEMBLER_MARK_IMPORTS="__GENPY_IMPORTS__"
_ASSEMBLER_MARK_SIGNATURES="__GENPY_SIGNATURES__"
_ASSEMBLER_MARK_END="__GENPY_END__"

# ─── build_review_context ────────────────────────────────────────────────────

# build_review_context FILE STRATEGY_FILE
# Sources the strategy, extracts the header zone (imports) and public
# signatures, and writes a structured context blob to stdout.
# Side effect: strategy functions (extract_signatures, get_prompt_rules)
#              are sourced into the current shell for subsequent calls.
build_review_context() {
  if [[ $# -ne 2 ]]; then
    echo "Usage: build_review_context FILE STRATEGY_FILE" >&2
    return 1
  fi

  local file="$1" strategy="$2"

  if [[ ! -f "$file" ]]; then
    echo "Error: file not found: $file" >&2
    return 1
  fi

  if [[ ! -f "$strategy" ]]; then
    echo "Error: strategy not found: $strategy" >&2
    return 1
  fi

  # shellcheck source=/dev/null
  source "$strategy"

  # ── Rules section ──
  echo "$_ASSEMBLER_MARK_RULES"
  if declare -f get_prompt_rules &>/dev/null; then
    get_prompt_rules
  fi

  # ── Imports section: header zone (top of file until first top-level def) ──
  # Covers: blank lines, comments (#, //), Python import/from, Go package.
  # v1 is Python-focused; Go/JS multi-line import blocks: Week 5.
  echo "$_ASSEMBLER_MARK_IMPORTS"
  awk '
    /^[[:space:]]*$/        { print; next }
    /^[[:space:]]*#/        { print; next }
    /^import[[:space:]]/    { print; next }
    /^from[[:space:]]/      { print; next }
    /^package[[:space:]]/   { print; next }
    /^\/\//                 { print; next }
    { exit }
  ' "$file"

  # ── Signatures section ──
  echo "$_ASSEMBLER_MARK_SIGNATURES"
  if declare -f extract_signatures &>/dev/null; then
    extract_signatures "$file" 2>/dev/null || true
  fi

  echo "$_ASSEMBLER_MARK_END"
}

# ─── assemble_prompt ──────────────────────────────────────────────────────────

# assemble_prompt CONTEXT_FILE FOCAL_CHUNK_FILE GOAL
# Reads the context blob produced by build_review_context and writes
# the 4-section prompt (ARCHITECTURE.md §5.4 step [5]) to stdout.
#
# CONTEXT_FILE    : context blob file (output of build_review_context)
# FOCAL_CHUNK_FILE: file with the focal chunk (lines START..END from original)
# GOAL            : string describing the review objective
assemble_prompt() {
  if [[ $# -ne 3 ]]; then
    echo "Usage: assemble_prompt CONTEXT_FILE FOCAL_CHUNK_FILE GOAL" >&2
    return 1
  fi

  local context_file="$1" focal_chunk_file="$2" goal="$3"

  if [[ ! -f "$context_file" ]]; then
    echo "Error: context not found: $context_file" >&2
    return 1
  fi

  if [[ ! -f "$focal_chunk_file" ]]; then
    echo "Error: focal chunk not found: $focal_chunk_file" >&2
    return 1
  fi

  # Parse context blob into sections using exact line matching
  local rules imports signatures
  rules=$(awk \
    -v s="$_ASSEMBLER_MARK_RULES" -v e="$_ASSEMBLER_MARK_IMPORTS" \
    '$0==s{f=1;next} $0==e{f=0} f' "$context_file")
  imports=$(awk \
    -v s="$_ASSEMBLER_MARK_IMPORTS" -v e="$_ASSEMBLER_MARK_SIGNATURES" \
    '$0==s{f=1;next} $0==e{f=0} f' "$context_file")
  signatures=$(awk \
    -v s="$_ASSEMBLER_MARK_SIGNATURES" -v e="$_ASSEMBLER_MARK_END" \
    '$0==s{f=1;next} $0==e{f=0} f' "$context_file")

  # ── Section 1: Role and constraints ──
  printf '%s\n' "=== SECTION 1: ROLE AND CONSTRAINTS ==="
  printf '%s\n' "You are an expert code reviewer. Improve the TARGET FRAGMENT"
  printf '%s\n' "while respecting the CONTEXT (read-only). Do not alter the existing public API."
  printf '\n%s\n' "Rules:"
  [[ -n "$rules" ]] && printf '%s\n' "$rules"
  printf '\n%s\n' "IMPORTANT: Return ONLY the improved code. No markdown,"
  printf '%s\n'   "no explanations or code blocks. The fragment must be"
  printf '%s\n'   "valid as it would appear in the source file."

  # ── Section 2: Review goal ──
  printf '\n%s\n' "=== SECTION 2: REVIEW GOAL ==="
  printf '%s\n' "$goal"

  # ── Section 3: Context (read-only) ──
  printf '\n%s\n' "=== SECTION 3: CONTEXT (READ-ONLY) ==="
  if [[ -n "$imports" ]]; then
    printf '%s\n' "# Imports and header"
    printf '%s\n' "$imports"
  fi
  if [[ -n "$signatures" ]]; then
    printf '\n%s\n' "# Public signatures"
    printf '%s\n' "$signatures"
  fi

  # ── Section 4: Target fragment ──
  printf '\n%s\n' "=== SECTION 4: TARGET FRAGMENT ==="
  cat "$focal_chunk_file"
}

# ─── reassemble_file ─────────────────────────────────────────────────────────

# reassemble_file ORIGINAL REVISED_CHUNK START END
# Rewrites the file as: head (1..START-1) + REVISED_CHUNK + tail (END+1..EOF).
# Writes the reassembled content to stdout. Does NOT modify ORIGINAL in place.
#
# ORIGINAL      : path to the original source file
# REVISED_CHUNK : path to the AI-revised focal chunk
# START         : first line of the focal chunk in ORIGINAL (1-based, inclusive)
# END           : last line of the focal chunk in ORIGINAL (1-based, inclusive)
reassemble_file() {
  if [[ $# -ne 4 ]]; then
    echo "Usage: reassemble_file ORIGINAL REVISED_CHUNK START END" >&2
    return 1
  fi

  local original="$1" revised_chunk="$2" start="$3" end="$4"

  if [[ ! -f "$original" ]]; then
    echo "Error: original file not found: $original" >&2
    return 1
  fi

  if [[ ! -f "$revised_chunk" ]]; then
    echo "Error: revised chunk not found: $revised_chunk" >&2
    return 1
  fi

  if [[ ! "$start" =~ ^[0-9]+$ || ! "$end" =~ ^[0-9]+$ ]]; then
    echo "Error: START and END must be positive integers" >&2
    return 1
  fi

  local total
  total=$(awk 'END {print NR}' "$original")

  if [[ "$start" -lt 1 || "$end" -gt "$total" || "$start" -gt "$end" ]]; then
    echo "Error: range $start-$end invalid (file has $total lines)" >&2
    return 1
  fi

  # Head: lines 1 to start-1 (omitted when start=1)
  if [[ "$start" -gt 1 ]]; then
    awk -v n="$((start - 1))" 'NR <= n' "$original"
  fi

  # Revised chunk (AI output)
  cat "$revised_chunk"

  # Tail: lines end+1 to EOF (omitted when end=total)
  if [[ "$end" -lt "$total" ]]; then
    awk -v n="$((end + 1))" 'NR >= n' "$original"
  fi
}
