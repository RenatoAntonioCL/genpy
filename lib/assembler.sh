#!/usr/bin/env bash
set -euo pipefail

# Include guard
[[ -n "${_GENPY_ASSEMBLER_LOADED:-}" ]] && return 0
_GENPY_ASSEMBLER_LOADED=1

# =============================================================================
# GenPy — lib/assembler.sh (v1.0.0-alpha)
#
# Contexto, prompt y re-ensamblado del archivo.
# Implementa ARCHITECTURE.md §5.4 pasos [4], [5] y [8].
#
# API pública:
#   build_review_context FILE STRATEGY_FILE  → stdout (context blob)
#   assemble_prompt CONTEXT_FILE FOCAL_CHUNK_FILE GOAL → stdout (prompt)
#   reassemble_file ORIGINAL REVISED_CHUNK START END   → stdout (archivo)
#
# Contrato de la strategy (debe proveer):
#   extract_signatures(file)  → imprime firmas
#   get_prompt_rules()        → imprime reglas del lenguaje
# =============================================================================

# Marcadores de sección en el context blob (deben ser líneas únicas)
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
    echo "Uso: build_review_context FILE STRATEGY_FILE" >&2
    return 1
  fi

  local file="$1" strategy="$2"

  if [[ ! -f "$file" ]]; then
    echo "Error: archivo no encontrado: $file" >&2
    return 1
  fi

  if [[ ! -f "$strategy" ]]; then
    echo "Error: strategy no encontrada: $strategy" >&2
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
  # v1 is Python-focused; Go/JS multi-line import blocks: Semana 5.
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
# the 4-section prompt (ARCHITECTURE.md §5.4 paso [5]) to stdout.
#
# CONTEXT_FILE    : context blob file (output of build_review_context)
# FOCAL_CHUNK_FILE: file with the focal chunk (lines START..END from original)
# GOAL            : string describing the review objective
assemble_prompt() {
  if [[ $# -ne 3 ]]; then
    echo "Uso: assemble_prompt CONTEXT_FILE FOCAL_CHUNK_FILE GOAL" >&2
    return 1
  fi

  local context_file="$1" focal_chunk_file="$2" goal="$3"

  if [[ ! -f "$context_file" ]]; then
    echo "Error: contexto no encontrado: $context_file" >&2
    return 1
  fi

  if [[ ! -f "$focal_chunk_file" ]]; then
    echo "Error: fragmento focal no encontrado: $focal_chunk_file" >&2
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

  # ── Sección 1: Rol y restricciones ──
  printf '%s\n' "=== SECCIÓN 1: ROL Y RESTRICCIONES ==="
  printf '%s\n' "Eres un revisor de código experto. Mejora el FRAGMENTO OBJETIVO"
  printf '%s\n' "respetando el CONTEXTO (solo lectura). No alteres la API pública existente."
  printf '\n%s\n' "Reglas:"
  [[ -n "$rules" ]] && printf '%s\n' "$rules"
  printf '\n%s\n' "IMPORTANTE: Devuelve ÚNICAMENTE el código mejorado. Sin markdown,"
  printf '%s\n'   "sin explicaciones ni bloques de código. El fragmento debe ser"
  printf '%s\n'   "válido tal como aparecería en el archivo fuente."

  # ── Sección 2: Objetivo de revisión ──
  printf '\n%s\n' "=== SECCIÓN 2: OBJETIVO DE REVISIÓN ==="
  printf '%s\n' "$goal"

  # ── Sección 3: Contexto (solo lectura) ──
  printf '\n%s\n' "=== SECCIÓN 3: CONTEXTO (SOLO LECTURA) ==="
  if [[ -n "$imports" ]]; then
    printf '%s\n' "# Importaciones y cabecera"
    printf '%s\n' "$imports"
  fi
  if [[ -n "$signatures" ]]; then
    printf '\n%s\n' "# Firmas públicas del archivo"
    printf '%s\n' "$signatures"
  fi

  # ── Sección 4: Fragmento objetivo ──
  printf '\n%s\n' "=== SECCIÓN 4: FRAGMENTO OBJETIVO ==="
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
    echo "Uso: reassemble_file ORIGINAL REVISED_CHUNK START END" >&2
    return 1
  fi

  local original="$1" revised_chunk="$2" start="$3" end="$4"

  if [[ ! -f "$original" ]]; then
    echo "Error: archivo original no encontrado: $original" >&2
    return 1
  fi

  if [[ ! -f "$revised_chunk" ]]; then
    echo "Error: fragmento revisado no encontrado: $revised_chunk" >&2
    return 1
  fi

  if [[ ! "$start" =~ ^[0-9]+$ || ! "$end" =~ ^[0-9]+$ ]]; then
    echo "Error: START y END deben ser enteros positivos" >&2
    return 1
  fi

  local total
  total=$(awk 'END {print NR}' "$original")

  if [[ "$start" -lt 1 || "$end" -gt "$total" || "$start" -gt "$end" ]]; then
    echo "Error: rango $start-$end inválido (archivo tiene $total líneas)" >&2
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
