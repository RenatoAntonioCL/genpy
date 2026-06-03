#!/usr/bin/env bash
set -euo pipefail

# =============================================================================
# GenPy — Official System Installer
# =============================================================================

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
readonly INSTALL_DIR="/usr/local/share/genpy"
readonly INSTALL_BIN="/usr/local/bin/genpy"

# Read the version from the single source of truth
GENPY_VERSION=$(grep -m1 'GENPY_VERSION=' "$REPO_DIR/lib/core/config.sh" \
  | grep -oE '"[^"]+"' | tr -d '"')
readonly GENPY_VERSION

echo "📦 Installing GenPy v${GENPY_VERSION} globally..."

# 1. Clean previous installations
sudo rm -rf "$INSTALL_DIR"
sudo rm -f  "$INSTALL_BIN"

# 2. Copy project files
sudo mkdir -p "$INSTALL_DIR"
sudo cp -R "$REPO_DIR/"* "$INSTALL_DIR/"

# 3. Restore execution permissions
sudo chmod +x "$INSTALL_DIR/bin/genpy"
sudo chmod +x "$INSTALL_DIR/scripts/install.sh"
sudo chmod +x "$INSTALL_DIR/scripts/update.sh"
sudo chmod +x "$INSTALL_DIR/scripts/uninstall.sh"

# 4. Create global wrapper
sudo tee "$INSTALL_BIN" > /dev/null <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
exec /usr/local/share/genpy/bin/genpy "$@"
EOF
sudo chmod +x "$INSTALL_BIN"

echo "✔ GenPy v${GENPY_VERSION} installed!"
echo "  Run it from anywhere with: genpy create"
