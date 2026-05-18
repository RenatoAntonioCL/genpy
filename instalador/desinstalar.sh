#!/bin/bash
set -e

INSTALL_BIN="/usr/local/bin/genpy"
INSTALL_DIR="/usr/local/share/genpy"

echo "🧹 Desinstalando GenPy..."

sudo rm -f "$INSTALL_BIN"
sudo rm -rf "$INSTALL_DIR"

echo "✔ GenPy eliminado completamente"