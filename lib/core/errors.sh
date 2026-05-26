#!/usr/bin/env bash
set -euo pipefail
# =============================================================================
# GenPy — lib/core/errors.sh (v1.0.0-alpha)
#
# Manejo centralizado de errores y cleanup.
#
# Provee:
#   - trap global para errores inesperados
#   - función die() como punto único de salida con error
#   - cleanup() para tareas de limpieza al salir
# =============================================================================

# ─── Estado de limpieza ───────────────────────────────────────────────────────

GENPY_CLEANUP_DIR=""

# ─── Trap global ─────────────────────────────────────────────────────────────

_genpy_cleanup() {
  local exit_code=$?

  if [[ $exit_code -ne 0 && -n "$GENPY_CLEANUP_DIR" && -d "$GENPY_CLEANUP_DIR" ]]; then
    echo -e "\n  ⚠️  Error detectado — limpiando directorio parcial: $GENPY_CLEANUP_DIR"
    rm -rf "$GENPY_CLEANUP_DIR"
    echo -e "  🗑️  Directorio eliminado."
  fi
}

trap '_genpy_cleanup' EXIT INT TERM

# ─── Colores mínimos propios (sin depender de utils.sh) ──────────────────────

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
  local hint="${2:-Instala '$cmd' antes de continuar.}"

  if ! command -v "$cmd" &>/dev/null; then
    die "$cmd no está instalado. $hint"
  fi
}

# ─── require_dir ─────────────────────────────────────────────────────────────

require_dir() {
  local dir="$1"
  local message="${2:-Directorio requerido no encontrado: $dir}"

  [[ -d "$dir" ]] || die "$message"
}
