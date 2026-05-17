#!/bin/bash
# Desinstalador de Genpy
set -e

INSTALL_PATH="/usr/local/bin/genpy"

if [[ -f "$INSTALL_PATH" ]]; then
  echo "🧹 Eliminando Genpy..."
  sudo rm "$INSTALL_PATH"
else
  echo "⚠️  Genpy no está instalado en $INSTALL_PATH"
fi

sed -i '' '/alias genpy=.*/d' ~/.zshrc 2>/dev/null || true
sed -i '' '/alias genpy=.*/d' ~/.bash_profile 2>/dev/null || true

echo "✅ Desinstalación completada."
