#!/usr/bin/env bash  
set -euo pipefail

# =============================================================================
# GenPy — Official Uninstaller
# =============================================================================

readonly INSTALL_BIN="/usr/local/bin/genpy"
readonly INSTALL_DIR="/usr/local/share/genpy"

echo "🧹 Uninstalling GenPy..."

if [[ ! -f "$INSTALL_BIN" ]] && [[ ! -d "$INSTALL_DIR" ]]; then
  echo "⚠️  GenPy is not installed on this system."
  exit 0
fi

sudo rm -f  "$INSTALL_BIN"
sudo rm -rf "$INSTALL_DIR"

echo "✔ GenPy has been uninstalled successfully."  