#!/usr/bin/env bash
# =============================================================================
# GenPy — tests/unit/test_guardians.sh
#
# Pruebas unitarias para lib/guardians.sh.
# Ejecutar desde la raíz del repo:
#   bash tests/unit/test_guardians.sh
# =============================================================================
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"

source "$REPO_ROOT/lib/guardians.sh"

GUARDIAN_NON_INTERACTIVE=1   # sin prompts interactivos en tests

# ─── Mini framework ───────────────────────────────────────────────────────────

_PASS=0; _FAIL=0

_assert_pass() {
  local desc="$1"; shift
  if "$@" 2>/dev/null; then
    echo "  PASS  $desc"
    (( _PASS++ )) || true
  else
    echo "  FAIL  $desc (esperaba éxito, devolvió fallo)"
    (( _FAIL++ )) || true
  fi
}

_assert_fail() {
  local desc="$1" exp_gate="$2"; shift 2
  if ! "$@" 2>/dev/null; then
    if [[ -n "$exp_gate" && "$GUARDIAN_FAILED_GATE" != "$exp_gate" ]]; then
      echo "  FAIL  $desc (falló OK pero gate='${GUARDIAN_FAILED_GATE}', esperaba '${exp_gate}')"
      (( _FAIL++ )) || true
    else
      echo "  PASS  $desc (fallo esperado, gate=${GUARDIAN_FAILED_GATE})"
      (( _PASS++ )) || true
    fi
  else
    echo "  FAIL  $desc (debía fallar pero pasó)"
    (( _FAIL++ )) || true
  fi
}

_assert_eq() {
  local desc="$1" expected="$2" actual="$3"
  if [[ "$actual" == "$expected" ]]; then
    echo "  PASS  $desc"
    (( _PASS++ )) || true
  else
    echo "  FAIL  $desc (esperado='$expected' obtenido='$actual')"
    (( _FAIL++ )) || true
  fi
}

# ─── Estrategia mock ─────────────────────────────────────────────────────────
# validate_syntax falla si el archivo contiene SYNTAX_ERROR_MARKER.
# Autónoma — no requiere python3.

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

# ─── G1: Output no vacío ─────────────────────────────────────────────────────

echo ""
echo "── G1: not_empty ────────────────────────────────────────────────────────"

f=$(_tmp)
_assert_fail "archivo vacío"          "G1"  guardian_g1_not_empty "$f"
_assert_eq   "FAILED_GATE=G1"         "G1"  "$GUARDIAN_FAILED_GATE"

printf 'def foo():\n    pass\n' > "$f"
_assert_pass "archivo con contenido"        guardian_g1_not_empty "$f"

GONE=$(mktemp /tmp/genpy_grd_XXXXX); rm -f "$GONE"
_assert_fail "archivo inexistente"    "G1"  guardian_g1_not_empty "$GONE"

# ─── G2: Sin markdown ni texto conversacional ─────────────────────────────────

echo ""
echo "── G2: no_markdown ──────────────────────────────────────────────────────"

f=$(_tmp)

# Fence ``` — usar heredoc para evitar problemas de escape en printf
cat > "$f" <<'PY'
```python
def foo(): pass
```
PY
_assert_fail "fence de código \`\`\`"   "G2"  guardian_g2_no_markdown "$f"

# Regla horizontal --- (heredoc evita que printf lo interprete como opción)
cat > "$f" <<'PY'
---
def foo(): pass
PY
_assert_fail "regla horizontal ---"     "G2"  guardian_g2_no_markdown "$f"

# Regla horizontal ===
cat > "$f" <<'PY'
===
def foo(): pass
PY
_assert_fail "regla horizontal ==="     "G2"  guardian_g2_no_markdown "$f"

# Texto conversacional: "Here is"
cat > "$f" <<'PY'
Here is the updated function:
def foo(): pass
PY
_assert_fail "apertura 'Here is'"       "G2"  guardian_g2_no_markdown "$f"

# Texto conversacional: "Sure,"
cat > "$f" <<'PY'
Sure, here it is:
def foo(): pass
PY
_assert_fail "apertura 'Sure,'"         "G2"  guardian_g2_no_markdown "$f"

# Texto conversacional: "The following"
cat > "$f" <<'PY'
The following function has been updated:
def foo(): pass
PY
_assert_fail "apertura 'The following'" "G2"  guardian_g2_no_markdown "$f"

# Código Python válido con # (comentario, no heading)
cat > "$f" <<'PY'
## módulo principal
def foo():
    # comentario interno
    return 42
PY
_assert_pass "Python con # y ##"        guardian_g2_no_markdown "$f"

# **kwargs: el doble asterisco no es markdown bold
cat > "$f" <<'PY'
def foo(**kwargs):
    return kwargs
PY
_assert_pass "Python con **kwargs"      guardian_g2_no_markdown "$f"

# async + type hints
cat > "$f" <<'PY'
async def fetch(url: str) -> dict:
    return {}
PY
_assert_pass "async def con type hints" guardian_g2_no_markdown "$f"

# ─── G3: Line count 70%–130% ─────────────────────────────────────────────────

echo ""
echo "── G3: line_count ───────────────────────────────────────────────────────"

orig=$(_tmp); chunk=$(_tmp)

# 10 líneas de referencia
printf '%s\n' {1..10} > "$orig"

printf '%s\n' {1..10} > "$chunk"
_assert_pass "100%: mismas líneas"      guardian_g3_line_count "$chunk" "$orig"

printf '%s\n' {1..7} > "$chunk"
_assert_pass "70%: límite inferior"     guardian_g3_line_count "$chunk" "$orig"

printf '%s\n' {1..13} > "$chunk"
_assert_pass "130%: límite superior"    guardian_g3_line_count "$chunk" "$orig"

printf '%s\n' {1..6} > "$chunk"
_assert_fail "60%: bajo el mínimo"     "G3"  guardian_g3_line_count "$chunk" "$orig"

printf '%s\n' {1..14} > "$chunk"
_assert_fail "140%: sobre el máximo"   "G3"  guardian_g3_line_count "$chunk" "$orig"

# Original vacío → pass (borde seguro)
: > "$orig"; printf 'x\n' > "$chunk"
_assert_pass "original vacío: skip"     guardian_g3_line_count "$chunk" "$orig"

# ─── G4: Sintaxis válida ──────────────────────────────────────────────────────

echo ""
echo "── G4: syntax ───────────────────────────────────────────────────────────"

f=$(_tmp)

# Sin marcador → validate_syntax retorna 0 → pass
cat > "$f" <<'PY'
def foo():
    return 42
PY
_assert_pass "chunk sin marcador"                guardian_g4_syntax "$f" "$MOCK_STRATEGY"

# Con marcador → validate_syntax retorna 1 → fail
cat > "$f" <<'PY'
def foo():
    SYNTAX_ERROR_MARKER
PY
_assert_fail "chunk con SYNTAX_ERROR_MARKER" "G4"  guardian_g4_syntax "$f" "$MOCK_STRATEGY"

# Chunk de método (indentado) → G4 lo omite → pass
cat > "$f" <<'PY'
    def bar(self):
        return True
PY
_assert_pass "método indentado: G4 skip"        guardian_g4_syntax "$f" "$MOCK_STRATEGY"

# Método indentado + marcador → G4 sigue omitiendo por indentación → pass
cat > "$f" <<'PY'
    def bar(self):
        SYNTAX_ERROR_MARKER
PY
_assert_pass "método indentado + marcador: G4 skip" guardian_g4_syntax "$f" "$MOCK_STRATEGY"

# ─── G5: Firmas públicas presentes ───────────────────────────────────────────

echo ""
echo "── G5: signatures ───────────────────────────────────────────────────────"

orig=$(_tmp); chunk=$(_tmp)

# Todas las firmas públicas conservadas → pass
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
_assert_pass "todas las firmas públicas presentes"    guardian_g5_signatures "$chunk" "$orig" "$MOCK_STRATEGY"

# AI elimina delete_item → G5 falla
cat > "$chunk" <<'PY'
class ItemService:
    def create_item(self, name):
        return name

    def _private_helper(self):
        pass
PY
_assert_fail "firma pública 'delete_item' ausente"   "G5"  guardian_g5_signatures "$chunk" "$orig" "$MOCK_STRATEGY"
_assert_eq   "DETAIL menciona delete_item" "1" \
  "$([[ "$GUARDIAN_FAILED_DETAIL" == *"delete_item"* ]] && echo 1 || echo 0)"

# AI elimina solo el privado → pass (privados ignorados en G5)
cat > "$chunk" <<'PY'
class ItemService:
    def create_item(self, name):
        return name

    def delete_item(self, id):
        return True
PY
_assert_pass "solo privado eliminado: G5 ignora"     guardian_g5_signatures "$chunk" "$orig" "$MOCK_STRATEGY"

# Dunder __init__ es público y debe verificarse
cat > "$orig" <<'PY'
class Foo:
    def __init__(self, x):
        self.x = x

    def compute(self):
        return self.x
PY
cp "$orig" "$chunk"
_assert_pass "__init__ y compute presentes"           guardian_g5_signatures "$chunk" "$orig" "$MOCK_STRATEGY"

# AI elimina __init__ → G5 debe fallar
cat > "$chunk" <<'PY'
class Foo:
    def compute(self):
        return 0
PY
_assert_fail "__init__ dunder ausente → G5 falla"    "G5"  guardian_g5_signatures "$chunk" "$orig" "$MOCK_STRATEGY"

# Sin firmas en el original → pass vacuo
: > "$orig"; printf 'x = 1\n' > "$chunk"
_assert_pass "sin firmas en original: pass vacuo"     guardian_g5_signatures "$chunk" "$orig" "$MOCK_STRATEGY"

# Función top-level en el original
cat > "$orig" <<'PY'
def greet(name: str) -> str:
    return f"Hello, {name}"

def farewell(name: str) -> str:
    return f"Bye, {name}"
PY
cp "$orig" "$chunk"
_assert_pass "funciones top-level preservadas"        guardian_g5_signatures "$chunk" "$orig" "$MOCK_STRATEGY"

cat > "$chunk" <<'PY'
def greet(name: str) -> str:
    return f"Hello, {name}"
PY
_assert_fail "función top-level 'farewell' ausente"  "G5"  guardian_g5_signatures "$chunk" "$orig" "$MOCK_STRATEGY"

# ─── run_guardians: modo no-interactivo ──────────────────────────────────────

echo ""
echo "── run_guardians (non-interactive) ──────────────────────────────────────"

orig=$(_tmp); chunk=$(_tmp)

# Chunk completamente válido → return 0
cat > "$orig" <<'PY'
def greet(name: str) -> str:
    return f"Hello, {name}"
PY
cp "$orig" "$chunk"
rc=0; run_guardians "$chunk" "$orig" "$MOCK_STRATEGY" 2>/dev/null || rc=$?
_assert_eq "chunk válido → rc=0"  "0" "$rc"

# G1 falla: chunk vacío → auto-abort → rc=1, gate=G1
: > "$chunk"
rc=0; run_guardians "$chunk" "$orig" "$MOCK_STRATEGY" 2>/dev/null || rc=$?
_assert_eq "G1 falla → rc=1"     "1" "$rc"
_assert_eq "FAILED_GATE=G1"      "G1" "$GUARDIAN_FAILED_GATE"

# G2 falla: markdown → auto-abort → rc=1, gate=G2
cat > "$chunk" <<'PY'
```python
def greet(): pass
```
PY
rc=0; run_guardians "$chunk" "$orig" "$MOCK_STRATEGY" 2>/dev/null || rc=$?
_assert_eq "G2 falla → rc=1"     "1" "$rc"
_assert_eq "FAILED_GATE=G2"      "G2" "$GUARDIAN_FAILED_GATE"

# G3 falla: demasiadas líneas → auto-abort → rc=1, gate=G3
printf '%s\n' {1..100} > "$chunk"
rc=0; run_guardians "$chunk" "$orig" "$MOCK_STRATEGY" 2>/dev/null || rc=$?
_assert_eq "G3 falla → rc=1"     "1" "$rc"
_assert_eq "FAILED_GATE=G3"      "G3" "$GUARDIAN_FAILED_GATE"

# G4 falla: sintaxis → auto-abort → rc=1, gate=G4
cat > "$chunk" <<'PY'
def greet(name: str) -> str:
    SYNTAX_ERROR_MARKER
PY
rc=0; run_guardians "$chunk" "$orig" "$MOCK_STRATEGY" 2>/dev/null || rc=$?
_assert_eq "G4 falla → rc=1"     "1" "$rc"
_assert_eq "FAILED_GATE=G4"      "G4" "$GUARDIAN_FAILED_GATE"

# G5 falla: firma ausente → auto-abort → rc=1, gate=G5
# orig: 4 líneas (sin blancos entre funciones para que G3 tolere un chunk de 3 líneas)
cat > "$orig" <<'PY'
def greet(name: str) -> str:
    return f"Hello, {name}"
def farewell(name: str) -> str:
    return f"Bye, {name}"
PY
# chunk: 3 líneas — dentro del 70-130% de 4 (min=2, max=5) para que G3 pase
# farewell ausente → G5 falla sin que G3 lo capture primero
cat > "$chunk" <<'PY'
def greet(name: str) -> str:
    # Improved greeting
    return f"Hello, {name}"
PY
rc=0; run_guardians "$chunk" "$orig" "$MOCK_STRATEGY" 2>/dev/null || rc=$?
_assert_eq "G5 falla → rc=1"     "1" "$rc"
_assert_eq "FAILED_GATE=G5"      "G5" "$GUARDIAN_FAILED_GATE"

# Orden de gates: G1 se evalúa antes que G2 cuando ambos fallan
cat > "$orig" <<'PY'
def foo(): pass
PY
: > "$chunk"   # vacío → G1 falla antes que cualquier otro
rc=0; run_guardians "$chunk" "$orig" "$MOCK_STRATEGY" 2>/dev/null || rc=$?
_assert_eq "orden: G1 antes que G2" "G1" "$GUARDIAN_FAILED_GATE"

# ─── Resumen ──────────────────────────────────────────────────────────────────

echo ""
echo "─────────────────────────────────────────────────────────────────────────"
echo "  Resultado: ${_PASS} PASS  /  ${_FAIL} FAIL"
if [[ "$_FAIL" -gt 0 ]]; then
  echo ""
  exit 1
fi
echo ""
