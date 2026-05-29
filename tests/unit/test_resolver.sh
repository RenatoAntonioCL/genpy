#!/usr/bin/env bash
# =============================================================================
# GenPy — tests/unit/test_resolver.sh
#
# Pruebas unitarias para lib/resolver.sh.
# Ejecutar desde la raíz del repo:
#   bash tests/unit/test_resolver.sh
# =============================================================================
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
FIXTURE="$REPO_ROOT/tests/fixtures/sample.py"

source "$REPO_ROOT/lib/resolver.sh"

# ─── Mini framework de test ───────────────────────────────────────────────────

_PASS=0; _FAIL=0

_assert_range() {
  local desc="$1" exp_start="$2" exp_end="$3"
  if [[ "$RESOLVE_START" -eq "$exp_start" && "$RESOLVE_END" -eq "$exp_end" ]]; then
    echo "  PASS  $desc"
    (( _PASS++ )) || true
  else
    echo "  FAIL  $desc"
    echo "        esperado: START=$exp_start END=$exp_end"
    echo "        obtenido: START=${RESOLVE_START:-?} END=${RESOLVE_END:-?}"
    (( _FAIL++ )) || true
  fi
}

_assert_error() {
  local desc="$1"; shift
  if ! resolve_range "$@" 2>/dev/null; then
    echo "  PASS  $desc (error esperado)"
    (( _PASS++ )) || true
  else
    echo "  FAIL  $desc (debía fallar pero devolvió START=$RESOLVE_START END=$RESOLVE_END)"
    (( _FAIL++ )) || true
  fi
}

# ─── --lines ─────────────────────────────────────────────────────────────────

echo ""
echo "── --lines ──────────────────────────────────────────────────────────────"

resolve_range --lines 13-14 "$FIXTURE"
_assert_range "rango explícito en medio del archivo" 13 14

resolve_range --lines 1-1 "$FIXTURE"
_assert_range "línea única (primera)" 1 1

resolve_range --lines 38-40 "$FIXTURE"
_assert_range "últimas líneas" 38 40

_assert_error "inicio > fin"         --lines 10-5    "$FIXTURE"
_assert_error "fin > total"          --lines 1-999   "$FIXTURE"
_assert_error "formato inválido"     --lines 10      "$FIXTURE"
_assert_error "inicio cero"          --lines 0-5     "$FIXTURE"

# ─── --function ───────────────────────────────────────────────────────────────

echo ""
echo "── --function ───────────────────────────────────────────────────────────"

resolve_range --function get_config "$FIXTURE"
_assert_range "función sync top-level (primera)" 9 12

resolve_range --function fetch_data "$FIXTURE"
_assert_range "función async top-level" 13 16

resolve_range --function decorated_func "$FIXTURE"
_assert_range "función con decorator justo antes" 18 21

_assert_error "función inexistente"  --function nonexistent "$FIXTURE"

# ─── --class ──────────────────────────────────────────────────────────────────

echo ""
echo "── --class ──────────────────────────────────────────────────────────────"

resolve_range --class ItemService "$FIXTURE"
_assert_range "clase con métodos (primera clase)" 22 37

resolve_range --class Config "$FIXTURE"
_assert_range "clase al final del archivo (sin próximo top-level)" 38 40

_assert_error "clase inexistente"    --class NonExistent "$FIXTURE"

# ─── --method ─────────────────────────────────────────────────────────────────

echo ""
echo "── --method ─────────────────────────────────────────────────────────────"

resolve_range --method ItemService.__init__ "$FIXTURE"
_assert_range "primer método de la clase" 23 25

resolve_range --method ItemService.create_item "$FIXTURE"
_assert_range "método sync en medio" 26 28

resolve_range --method ItemService.delete_item "$FIXTURE"
_assert_range "método async en medio" 29 31

resolve_range --method ItemService._private_helper "$FIXTURE"
_assert_range "último método (sin sibling siguiente)" 32 37

_assert_error "clase inexistente"    --method Ghost.method      "$FIXTURE"
_assert_error "método inexistente"   --method ItemService.ghost  "$FIXTURE"
_assert_error "formato sin punto"    --method ItemService        "$FIXTURE"

# ─── Errores de archivo y modo ────────────────────────────────────────────────

echo ""
echo "── Errores generales ────────────────────────────────────────────────────"

_assert_error "archivo no encontrado"  --function get_config "/no/existe.py"
_assert_error "modo desconocido"       --unknown get_config   "$FIXTURE"
_assert_error "argumentos insuficientes (2)"

# ─── Resumen ──────────────────────────────────────────────────────────────────

echo ""
echo "─────────────────────────────────────────────────────────────────────────"
echo "  Resultado: ${_PASS} PASS  /  ${_FAIL} FAIL"
if [[ "$_FAIL" -gt 0 ]]; then
  echo ""
  exit 1
fi
echo ""
