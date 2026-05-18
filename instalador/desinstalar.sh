#!/bin/bash
set -e

INSTALL_BIN="/usr/local/bin/genpy"
INSTALL_DIR="/usr/local/share/genpy"

echo "🧹 Desinstalando GenPy..."

# Remove launcher
if [[ -f "$INSTALL_BIN" ]]; then
  sudo rm -f "$INSTALL_BIN"
  echo "✔ Binario eliminado"
else
  echo "⚠️ Binario no encontrado"
fi

# Remove full install directory
if [[ -d "$INSTALL_DIR" ]]; then
  sudo rm -rf "$INSTALL_DIR"
  echo "✔ Directorio eliminado"
else
  echo "⚠️ Directorio no encontrado"
fi

# Optional cleanup
echo "🧼 Limpiando referencias en shell..."

# optional safety check
if command -v genpy &>/dev/null; then
  echo "⚠️ genpy aún sigue en PATH (probablemente cache shell)"
fi

sed -i '' '/genpy/d' ~/.zshrc 2>/dev/null || true
sed -i '' '/genpy/d' ~/.bash_profile 2>/dev/null || true

echo "✔ GenPy completamente eliminado"