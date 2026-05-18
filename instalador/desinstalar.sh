#!/bin/bash
set -euo pipefail

# =============================================================================
# GenPy — Desinstalador
#
# Elimina completamente GenPy del sistema: el directorio de instalación
# y el comando global. No afecta los proyectos que el usuario ya generó.
#
# Uso:
#   genpy uninstall
#   bash instalador/desinstalar.sh
#
# Requiere: sudo
# =============================================================================

# Rutas de instalación definidas en instalar.sh
readonly INSTALL_BIN="/usr/local/bin/genpy"
readonly INSTALL_DIR="/usr/local/share/genpy"

echo "🧹 Desinstalando GenPy..."

# ─── Verificar que GenPy está instalado ──────────────────────────────────────
# Salir limpiamente si ya fue desinstalado o nunca se instaló

if [[ ! -f "$INSTALL_BIN" ]] && [[ ! -d "$INSTALL_DIR" ]]; then
  echo "⚠️  GenPy no está instalado en este sistema"
  exit 0
fi

# ─── Eliminar archivos del sistema ───────────────────────────────────────────

sudo rm -f  "$INSTALL_BIN"   # comando global
sudo rm -rf "$INSTALL_DIR"   # directorio con todos los scripts

echo "✔ GenPy eliminado completamente"
