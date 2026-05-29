#!/usr/bin/env bash
# =============================================================================
# GenPy — tests/unit/test_assembler.sh
#
# Pruebas unitarias para lib/assembler.sh.
# Ejecutar desde la raíz del repo:
#   bash tests/unit/test_assembler.sh
# =============================================================================
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
FIXTURE_PY="$REPO_ROOT/tests/fixtures/sample.py"
FIXTURE_TXT="$REPO_ROOT/tests/fixtures/sample_assembler.txt"
STRATEGY="$REPO_ROOT/lib/review_strategies/python.sh"

source "$REPO_ROOT/lib/assembler.sh"

# ─── Framework de test ────────────────────────────────────────────────────────

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
    echo "        buscando: $(printf '%q' "$needle")"
    echo "        en:       $(printf '%s' "$haystack" | head -3)"
    (( _FAIL++ )) || true
  fi
}

_assert_not_contains() {
  local desc="$1" haystack="$2" needle="$3"
  if ! printf '%s' "$haystack" | grep -qF "$needle"; then
    echo "  PASS  $desc"
    (( _PASS++ )) || true
  else
    echo "  FAIL  $desc (no debería contener: $(printf '%q' "$needle"))"
    (( _FAIL++ )) || true
  fi
}

_assert_not_empty() {
  local desc="$1" value="$2"
  if [[ -n "$value" ]]; then
    echo "  PASS  $desc"
    (( _PASS++ )) || true
  else
    echo "  FAIL  $desc (valor vacío)"
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
    echo "        esperado: $(printf '%q' "$expected")"
    echo "        obtenido: $(printf '%q' "$actual")"
    (( _FAIL++ )) || true
  fi
}

_assert_error() {
  local desc="$1"; shift
  local fn="$1"; shift
  if ! "$fn" "$@" 2>/dev/null; then
    echo "  PASS  $desc (error esperado)"
    (( _PASS++ )) || true
  else
    echo "  FAIL  $desc (debía fallar pero tuvo éxito)"
    (( _FAIL++ )) || true
  fi
}

# ─── build_review_context ─────────────────────────────────────────────────────

echo ""
echo "── build_review_context ─────────────────────────────────────────────────"

_ctx_file="$_TMPDIR/context.txt"
build_review_context "$FIXTURE_PY" "$STRATEGY" > "$_ctx_file"
_ctx=$(cat "$_ctx_file")

_assert_not_empty "genera output no vacío" "$_ctx"

_assert_contains "incluye import os"                   "$_ctx" "import os"
_assert_contains "incluye import sys"                  "$_ctx" "import sys"
_assert_contains "incluye from typing import Optional" "$_ctx" "from typing import Optional"

_assert_contains "incluye firma def get_config"        "$_ctx" "def get_config"
_assert_contains "incluye firma async def fetch_data"  "$_ctx" "async def fetch_data"
_assert_contains "incluye firma class ItemService"     "$_ctx" "class ItemService"

_assert_contains "incluye reglas del lenguaje"         "$_ctx" "type hints"

_assert_error "falla con archivo inexistente" \
  build_review_context "/no/existe.py" "$STRATEGY"

_assert_error "falla con strategy inexistente" \
  build_review_context "$FIXTURE_PY" "/no/existe.sh"

_assert_error "falla con argumento de menos" \
  build_review_context "$FIXTURE_PY"

# ─── assemble_prompt ──────────────────────────────────────────────────────────

echo ""
echo "── assemble_prompt ──────────────────────────────────────────────────────"

# Preparar fragmento focal de prueba
_chunk_file="$_TMPDIR/focal_chunk.txt"
printf '%s\n' "def get_config(key: str) -> Optional[str]:" \
              "    return os.getenv(key)" > "$_chunk_file"

_goal="Añadir manejo de valor por defecto y validación de tipo"

_prompt_file="$_TMPDIR/prompt.txt"
assemble_prompt "$_ctx_file" "$_chunk_file" "$_goal" > "$_prompt_file"
_prompt=$(cat "$_prompt_file")

_assert_contains "contiene Sección 1"  "$_prompt" "SECCIÓN 1"
_assert_contains "contiene Sección 2"  "$_prompt" "SECCIÓN 2"
_assert_contains "contiene Sección 3"  "$_prompt" "SECCIÓN 3"
_assert_contains "contiene Sección 4"  "$_prompt" "SECCIÓN 4"

_assert_contains "Sección 2 lleva el goal"          "$_prompt" "$_goal"
_assert_contains "Sección 3 lleva imports"           "$_prompt" "import os"
_assert_contains "Sección 3 lleva firmas"            "$_prompt" "def get_config"
_assert_contains "Sección 4 lleva el fragmento"      "$_prompt" "return os.getenv(key)"

_assert_contains "contiene la restricción clave"     "$_prompt" "ÚNICAMENTE el código mejorado"
_assert_not_contains "el prompt no expone marcadores internos" "$_prompt" "__GENPY_RULES__"
_assert_not_contains "el prompt no expone marcadores internos" "$_prompt" "__GENPY_IMPORTS__"

# Fragmento con $ (no debe expandirse como variable de shell)
_dollar_chunk="$_TMPDIR/dollar_chunk.txt"
printf '%s\n' 'x = "${HOME}/path"' > "$_dollar_chunk"
_dollar_prompt=$(assemble_prompt "$_ctx_file" "$_dollar_chunk" "test")
_assert_contains "el signo dolar en el fragmento no se expande" \
  "$_dollar_prompt" '${HOME}'

_assert_error "falla con context inexistente" \
  assemble_prompt "/no/existe.txt" "$_chunk_file" "$_goal"

_assert_error "falla con focal_chunk inexistente" \
  assemble_prompt "$_ctx_file" "/no/existe.txt" "$_goal"

_assert_error "falla con argumentos insuficientes" \
  assemble_prompt "$_ctx_file" "$_chunk_file"

# ─── reassemble_file ──────────────────────────────────────────────────────────

echo ""
echo "── reassemble_file ──────────────────────────────────────────────────────"

# FIXTURE_TXT tiene 7 líneas: ALPHA BRAVO CHARLIE DELTA ECHO FOXTROT GOLF

# Preparar chunk revisado — strings distintos de los originales para evitar
# falsos positivos en _assert_not_contains (grep -qF busca substrings)
_revised="$_TMPDIR/revised.txt"
printf '%s\n' "LINE4_NEW" "LINE5_NEW" > "$_revised"

# happy path: head + revised + tail (start=4, end=5)
_result=$(reassemble_file "$FIXTURE_TXT" "$_revised" 4 5)
_assert_contains "head conservado (ALPHA)"   "$_result" "ALPHA"
_assert_contains "head conservado (CHARLIE)" "$_result" "CHARLIE"
_assert_contains "chunk revisado presente"   "$_result" "LINE4_NEW"
_assert_contains "tail conservado (FOXTROT)" "$_result" "FOXTROT"
_assert_contains "tail conservado (GOLF)"    "$_result" "GOLF"
_assert_not_contains "DELTA original eliminado" "$_result" "DELTA"
_assert_not_contains "ECHO original eliminado"  "$_result" "ECHO"

# Orden: head antes que chunk, chunk antes que tail
_alpha_pos=$(printf '%s' "$_result" | grep -n "ALPHA"    | cut -d: -f1 | head -1 || true)
_rev_pos=$(  printf '%s' "$_result" | grep -n "LINE4_NEW" | cut -d: -f1 | head -1 || true)
_golf_pos=$( printf '%s' "$_result" | grep -n "GOLF"     | cut -d: -f1 | head -1 || true)
if [[ -n "$_alpha_pos" && -n "$_rev_pos" && -n "$_golf_pos" && \
      "$_alpha_pos" -lt "$_rev_pos" && "$_rev_pos" -lt "$_golf_pos" ]]; then
  echo "  PASS  orden: head < chunk < tail"
  (( _PASS++ )) || true
else
  echo "  FAIL  orden incorrecto: alpha=$_alpha_pos rev=$_rev_pos golf=$_golf_pos"
  (( _FAIL++ )) || true
fi

# start=1 → no hay head
_revised_single="$_TMPDIR/revised_single.txt"
printf '%s\n' "FIRST_REVISED" > "$_revised_single"
_result_no_head=$(reassemble_file "$FIXTURE_TXT" "$_revised_single" 1 1)
_assert_contains     "sin head: chunk presente"      "$_result_no_head" "FIRST_REVISED"
_assert_contains     "sin head: tail conservado"     "$_result_no_head" "BRAVO"
_assert_not_contains "sin head: ALPHA original gone" "$_result_no_head" "ALPHA"

# end=total → no hay tail
_total_lines=$(awk 'END{print NR}' "$FIXTURE_TXT")
_result_no_tail=$(reassemble_file "$FIXTURE_TXT" "$_revised_single" "$_total_lines" "$_total_lines")
_assert_contains     "sin tail: head conservado" "$_result_no_tail" "ALPHA"
_assert_contains     "sin tail: chunk presente"  "$_result_no_tail" "FIRST_REVISED"
_assert_not_contains "sin tail: GOLF gone"       "$_result_no_tail" "GOLF"

# reemplazo completo (start=1, end=total)
_full_revised="$_TMPDIR/full_revised.txt"
printf '%s\n' "ONLY_LINE" > "$_full_revised"
_result_full=$(reassemble_file "$FIXTURE_TXT" "$_full_revised" 1 "$_total_lines")
_assert_equals     "reemplazo completo: una sola línea" \
  "ONLY_LINE" "$(printf '%s' "$_result_full" | tr -d '\n')"

# Errores
_assert_error "falla con original inexistente" \
  reassemble_file "/no/existe.txt" "$_revised" 4 5

_assert_error "falla con revised inexistente" \
  reassemble_file "$FIXTURE_TXT" "/no/existe.txt" 4 5

_assert_error "falla con start > end" \
  reassemble_file "$FIXTURE_TXT" "$_revised" 5 4

_assert_error "falla con end > total" \
  reassemble_file "$FIXTURE_TXT" "$_revised" 1 999

_assert_error "falla con start=0" \
  reassemble_file "$FIXTURE_TXT" "$_revised" 0 3

_assert_error "falla con args no numéricos" \
  reassemble_file "$FIXTURE_TXT" "$_revised" "a" "b"

_assert_error "falla con argumentos insuficientes" \
  reassemble_file "$FIXTURE_TXT" "$_revised" 4

# ─── Resumen ──────────────────────────────────────────────────────────────────

echo ""
echo "─────────────────────────────────────────────────────────────────────────"
echo "  Resultado: ${_PASS} PASS  /  ${_FAIL} FAIL"
if [[ "$_FAIL" -gt 0 ]]; then
  echo ""
  exit 1
fi
echo ""
