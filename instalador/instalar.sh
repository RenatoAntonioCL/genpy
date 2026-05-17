[200~#!/bin/bash
# Instalador de Genpy: Pro Max Python Project Generator
set -e

INSTALL_PATH="/usr/local/bin/genpy"
GENPY_REPO_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")/../generador" && pwd)"
GENPY_SCRIPT="$GENPY_REPO_PATH/pro_max_python_project_generator.sh"

echo "🔍 Verificando dependencias..."
for cmd in git python3 curl; do
  if ! command -v "$cmd" &>/dev/null; then
    echo "❌ Falta '$cmd'. Por favor instálalo antes de continuar."
    exit 1
  fi
done

if command -v docker &>/dev/null; then
  echo "✅ Docker disponible."
else
  echo "⚠️  Docker no está instalado. Puedes instalarlo luego si lo deseas."
fi

echo "📦 Instalando Genpy en /usr/local/bin/genpy..."
sudo cp "$GENPY_SCRIPT" "$INSTALL_PATH"
sudo chmod +x "$INSTALL_PATH"

echo "alias genpy='/usr/local/bin/genpy'" >> ~/.bash_profile 2>/dev/null || true
echo "alias genpy='/usr/local/bin/genpy'" >> ~/.zshrc 2>/dev/null || true

echo "✅ Instalación completada. Ya puedes usar el comando 'genpy'."
