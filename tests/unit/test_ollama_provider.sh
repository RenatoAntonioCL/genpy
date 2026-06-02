#!/usr/bin/env bash
# =============================================================================
# GenPy — tests/unit/test_ollama_provider.sh
#
# Pruebas unitarias para lib/providers/ollama.sh.
# No requiere Ollama en ejecución — testea las funciones internas
# con fixtures locales.
#
# Ejecutar desde la raíz del repo:
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
    _fail "$desc" "esperado: '$want'  obtenido: '$got'"
  fi
}

_assert_nonempty() {
  local desc="$1" val="$2"
  if [[ -n "$val" ]]; then
    _ok "$desc"
  else
    _fail "$desc" "se esperaba valor no vacío"
  fi
}

# ─── _ollama_detect_model ─────────────────────────────────────────────────────

echo ""
echo "─── _ollama_detect_model ──────────────────────────────────────────────────"

(
  GENPY_MODEL="mistral:7b"
  result=$(_ollama_detect_model)
  [[ "$result" == "mistral:7b" ]] \
    && { echo "  PASS  respeta GENPY_MODEL cuando está definido"; (( _PASS++ )) || true; } \
    || { echo "  FAIL  GENPY_MODEL no respetado — got: $result"; (( _FAIL++ )) || true; }
)

(
  # Sin GENPY_MODEL y Ollama no disponible → debe devolver el fallback
  unset GENPY_MODEL 2>/dev/null || true
  OLLAMA_HOST="http://127.0.0.1:1"  # puerto cerrado, falla inmediata
  result=$(_ollama_detect_model)
  [[ "$result" == "qwen2.5:3b" ]] \
    && { echo "  PASS  fallback a qwen2.5:3b cuando Ollama no responde"; (( _PASS++ )) || true; } \
    || { echo "  FAIL  fallback incorrecto — got: $result"; (( _FAIL++ )) || true; }
)

# ─── _ollama_json_encode ──────────────────────────────────────────────────────

echo ""
echo "─── _ollama_json_encode ───────────────────────────────────────────────────"

result=$(printf 'hello world' | _ollama_json_encode)
_assert_eq "texto simple" "$result" '"hello world"'

result=$(printf 'line1\nline2' | _ollama_json_encode)
_assert_eq "newlines codificados" "$result" '"line1\nline2"'

result=$(printf 'say "hi"' | _ollama_json_encode)
_assert_eq "comillas dobles codificadas" "$result" '"say \"hi\""'

result=$(printf 'path\\file' | _ollama_json_encode)
_assert_eq "backslash codificado" "$result" '"path\\file"'

result=$(printf '' | _ollama_json_encode)
_assert_eq "string vacío" "$result" '""'

# ─── _ollama_extract_response ─────────────────────────────────────────────────

echo ""
echo "─── _ollama_extract_response ──────────────────────────────────────────────"

tmpdir=$(mktemp -d)

# Respuesta válida con campo response
cat > "$tmpdir/resp_ok.json" <<'JSON'
{"model":"qwen2.5:3b","response":"def foo():\n    pass","done":true}
JSON

result=$(_ollama_extract_response "$tmpdir/resp_ok.json")
_assert_eq "extrae .response de JSON válido" "$result" 'def foo():
    pass'

# Respuesta con response vacío
cat > "$tmpdir/resp_empty.json" <<'JSON'
{"model":"qwen2.5:3b","response":"","done":true}
JSON

result=$(_ollama_extract_response "$tmpdir/resp_empty.json")
_assert_eq "response vacío devuelve cadena vacía" "$result" ""

# JSON sin campo response
cat > "$tmpdir/resp_nofield.json" <<'JSON'
{"model":"qwen2.5:3b","done":true}
JSON

result=$(_ollama_extract_response "$tmpdir/resp_nofield.json")
_assert_eq "JSON sin .response devuelve cadena vacía" "$result" ""

# JSON malformado
cat > "$tmpdir/resp_bad.json" <<'JSON'
{not valid json}
JSON

if ! _ollama_extract_response "$tmpdir/resp_bad.json" &>/dev/null; then
  _ok "JSON malformado devuelve error (rc != 0)"
else
  _fail "JSON malformado debería fallar" "rc fue 0"
fi

rm -rf "$tmpdir"

# ─── ai_complete con mock ─────────────────────────────────────────────────────

echo ""
echo "─── ai_complete (usando ollama_mock) ─────────────────────────────────────"

# Override ai_complete con el mock para este bloque de tests
source "$REPO_ROOT/tests/mocks/ollama_mock.sh"

tmpdir=$(mktemp -d)

# Prompt con Sección 4 definida
cat > "$tmpdir/prompt_with_s4.txt" <<'EOF'
=== SECCIÓN 1: ROL Y RESTRICCIONES ===
Eres un revisor experto.

=== SECCIÓN 2: OBJETIVO DE REVISIÓN ===
Mejorar calidad.

=== SECCIÓN 3: CONTEXTO (SOLO LECTURA) ===
import os

=== SECCIÓN 4: FRAGMENTO OBJETIVO ===
def hello():
    print("hi")
EOF

ai_complete "$tmpdir/prompt_with_s4.txt" "$tmpdir/output.txt" ""
got=$(cat "$tmpdir/output.txt")

if [[ "$got" == *"def hello"* ]]; then
  _ok "mock extrae solo el contenido de Sección 4"
else
  _fail "mock no extrajo Sección 4" "got: $got"
fi

if [[ "$got" == *"ROL Y RESTRICCIONES"* ]]; then
  _fail "output contiene texto de Sección 1 (no debería)" "got: $got"
else
  _ok "output no contiene secciones del prompt"
fi

# Prompt sin Sección 4 → copia todo
cat > "$tmpdir/prompt_no_s4.txt" <<'EOF'
Solo código sin marcadores de sección
def bar():
    return 42
EOF

ai_complete "$tmpdir/prompt_no_s4.txt" "$tmpdir/output2.txt" ""
got2=$(cat "$tmpdir/output2.txt")
if [[ "$got2" == *"def bar"* ]]; then
  _ok "mock sin Sección 4 copia el prompt completo"
else
  _fail "mock sin Sección 4 no copió el prompt" "got: $got2"
fi

# Archivo prompt vacío → rc 1 (archivo no existe)
if ! ai_complete "$tmpdir/nonexistent.txt" "$tmpdir/out.txt" "" 2>/dev/null; then
  _ok "ai_complete falla (rc != 0) con prompt inexistente"
else
  _fail "debía fallar con prompt inexistente" "rc fue 0"
fi

rm -rf "$tmpdir"

# ─── Resultado ────────────────────────────────────────────────────────────────

echo ""
echo "─────────────────────────────────────────────────────────────────────────"
printf "  Resultado: %d PASS  /  %d FAIL\n" "$_PASS" "$_FAIL"
[[ "$_FAIL" -eq 0 ]]
