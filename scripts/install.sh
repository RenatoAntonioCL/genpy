#!/usr/bin/env bash
set -euo pipefail

# =============================================================================
# GenPy — Official System Installer v1.0.0-alpha
# =============================================================================

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
readonly INSTALL_DIR="/usr/local/share/genpy"
readonly INSTALL_BIN="/usr/local/bin/genpy"

echo "📦 Installing GenPy v1.0.0-alpha globally..."

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

echo "✔ GenPy v1.0.0-alpha successfully installed!"
echo "  Run it from anywhere with: genpy create"
