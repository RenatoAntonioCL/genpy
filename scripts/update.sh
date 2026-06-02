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

echo "⬇️  Buscando la última versión de GenPy..."

# 1. Detectar el tag del último release publicado en GitHub.
#    Si no hay acceso a la API, clonar desde main como fallback.
TARGET_REF="main"
if command -v curl &>/dev/null; then
  LATEST_TAG=$(curl -sf \
    "https://api.github.com/repos/RenatoAntonioCL/genpy/releases/latest" \
    | grep '"tag_name"' | cut -d'"' -f4 || true)
  if [[ -n "$LATEST_TAG" ]]; then
    TARGET_REF="$LATEST_TAG"
    echo "  → Última versión: $LATEST_TAG"
  else
    echo "  → No se pudo detectar el último release; usando rama main."
  fi
fi

git clone --depth 1 --branch "$TARGET_REF" "$REPO_URL" "$TMP_DIR"

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
