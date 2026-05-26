#!/usr/bin/env bash
set -euo pipefail

# =============================================================================
# GenPy — Official System Updater v1.0.0-alpha (Blindado)
# =============================================================================

readonly REPO_URL="https://github.com/RenatoAntonioCL/genpy.git"
TMP_DIR="$(mktemp -d)"
readonly INSTALL_DIR="/usr/local/share/genpy"
readonly INSTALL_BIN="/usr/local/bin/genpy"

trap 'rm -rf "$TMP_DIR"' EXIT

echo "⬇️  Actualizando GenPy desde el repositorio..."

# 1. Clonar nueva versión
git clone --depth 1 "$REPO_URL" "$TMP_DIR"

# 2. Reemplazar archivos
sudo rm -rf "$INSTALL_DIR"
sudo mkdir -p "$INSTALL_DIR"
sudo cp -R "$TMP_DIR/." "$INSTALL_DIR/"

# 3. VERIFICACIÓN Y PERMISOS: Solo si el archivo existe
[[ -f "$INSTALL_DIR/bin/genpy" ]] && sudo chmod +x "$INSTALL_DIR/bin/genpy"
[[ -f "$INSTALL_DIR/scripts/install.sh" ]] && sudo chmod +x "$INSTALL_DIR/scripts/install.sh"
[[ -f "$INSTALL_DIR/scripts/update.sh" ]] && sudo chmod +x "$INSTALL_DIR/scripts/update.sh"
[[ -f "$INSTALL_DIR/scripts/uninstall.sh" ]] && sudo chmod +x "$INSTALL_DIR/scripts/uninstall.sh"

# 4. Recrear el wrapper global
sudo tee "$INSTALL_BIN" > /dev/null <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
exec /usr/local/share/genpy/bin/genpy "$@"
EOF
sudo chmod +x "$INSTALL_BIN"

echo "✅ GenPy actualizado y blindado correctamente."