#!/bin/bash
# Actualizador de Genpy desde un repositorio Git
set -e

REPO_URL="https://github.com/TU_USUARIO/genpy.git"
TEMP_DIR=$(mktemp -d)
INSTALL_PATH="/usr/local/bin/genpy"

echo "⬇️  Descargando última versión de Genpy..."
git clone "$REPO_URL" "$TEMP_DIR"

echo "📦 Actualizando script en $INSTALL_PATH..."
sudo cp "$TEMP_DIR/generador/pro_max_python_project_generator.sh" "$INSTALL_PATH"
sudo chmod +x "$INSTALL_PATH"

rm -rf "$TEMP_DIR"

echo "✅ Genpy actualizado correctamente."
