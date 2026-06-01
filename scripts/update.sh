#!/usr/bin/env bash
set -euo pipefail

# =============================================================================
# GenPy — Official System Updater v1.0.0-alpha
# =============================================================================

readonly REPO_URL="https://github.com/RenatoAntonioCL/genpy.git"
TMP_DIR="$(mktemp -d)"
readonly INSTALL_DIR="/usr/local/share/genpy"
readonly INSTALL_BIN="/usr/local/bin/genpy"

trap 'rm -rf "$TMP_DIR"' EXIT

echo "⬇️  Actualizando GenPy desde el repositorio..."

# 1. Clonar la nueva versión por HTTPS (rama main explícita, no el default del remoto).
#    La autenticidad la aporta TLS de GitHub.
git clone --depth 1 --branch main "$REPO_URL" "$TMP_DIR"

# 2. Verificar la integridad del clon ANTES de tocar la instalación actual.
#    Si viene incompleto o corrupto, se aborta sin destruir lo que ya funciona.
for required in bin/genpy lib/core/config.sh lib/core/compat.sh templates; do
  if [[ ! -e "$TMP_DIR/$required" ]]; then
    echo "❌ Update abortado: el clon no contiene '$required'." >&2
    echo "   Tu instalación actual queda intacta." >&2
    exit 1
  fi
done
[[ -s "$TMP_DIR/bin/genpy" ]] || {
  echo "❌ Update abortado: 'bin/genpy' está vacío. Instalación actual intacta." >&2
  exit 1
}
new_sha="$(git -C "$TMP_DIR" rev-parse --short HEAD 2>/dev/null || echo desconocido)"
echo "  ✓ Clon verificado (commit $new_sha)."

# 3. Reemplazar archivos
sudo rm -rf "$INSTALL_DIR"
sudo mkdir -p "$INSTALL_DIR"
sudo cp -R "$TMP_DIR/." "$INSTALL_DIR/"

# 4. Restaurar permisos de ejecución (solo si el archivo existe)
[[ -f "$INSTALL_DIR/bin/genpy" ]] && sudo chmod +x "$INSTALL_DIR/bin/genpy"
[[ -f "$INSTALL_DIR/scripts/install.sh" ]] && sudo chmod +x "$INSTALL_DIR/scripts/install.sh"
[[ -f "$INSTALL_DIR/scripts/update.sh" ]] && sudo chmod +x "$INSTALL_DIR/scripts/update.sh"
[[ -f "$INSTALL_DIR/scripts/uninstall.sh" ]] && sudo chmod +x "$INSTALL_DIR/scripts/uninstall.sh"

# 5. Recrear el wrapper global
sudo tee "$INSTALL_BIN" > /dev/null <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
exec /usr/local/share/genpy/bin/genpy "$@"
EOF
sudo chmod +x "$INSTALL_BIN"

echo "✅ GenPy actualizado a $new_sha."
