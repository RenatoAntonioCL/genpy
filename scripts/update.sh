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

echo "⬇️  Fetching the latest version of GenPy..."

# 1. Detect the tag of the latest release published on GitHub.
#    If there is no API access, clone from main as fallback.
TARGET_REF="main"
if command -v curl &>/dev/null; then
  LATEST_TAG=$(curl -sf \
    "https://api.github.com/repos/RenatoAntonioCL/genpy/releases/latest" \
    | grep '"tag_name"' | cut -d'"' -f4 || true)
  if [[ -n "$LATEST_TAG" ]]; then
    TARGET_REF="$LATEST_TAG"
    echo "  → Latest version: $LATEST_TAG"
  else
    echo "  → Could not detect the latest release; using main branch."
  fi
fi

git clone --depth 1 --branch "$TARGET_REF" "$REPO_URL" "$TMP_DIR"

# 2. Verify the integrity of the clone BEFORE touching the current installation.
#    If it comes incomplete or corrupt, it aborts without destroying what already works.
for required in bin/genpy lib/core/config.sh lib/core/compat.sh templates; do
  if [[ ! -e "$TMP_DIR/$required" ]]; then
    echo "❌ Update aborted: clone does not contain '$required'." >&2
    echo "   Your current installation remains intact." >&2
    exit 1
  fi
done
[[ -s "$TMP_DIR/bin/genpy" ]] || {
  echo "❌ Update aborted: 'bin/genpy' is empty. Current installation intact." >&2
  exit 1
}
new_sha="$(git -C "$TMP_DIR" rev-parse --short HEAD 2>/dev/null || echo unknown)"
echo "  ✓ Clone verified (commit $new_sha)."

# 3. Replace files
sudo rm -rf "$INSTALL_DIR"
sudo mkdir -p "$INSTALL_DIR"
sudo cp -R "$TMP_DIR/." "$INSTALL_DIR/"

# 4. Restore execution permissions (only if the file exists)
[[ -f "$INSTALL_DIR/bin/genpy" ]] && sudo chmod +x "$INSTALL_DIR/bin/genpy"
[[ -f "$INSTALL_DIR/scripts/install.sh" ]] && sudo chmod +x "$INSTALL_DIR/scripts/install.sh"
[[ -f "$INSTALL_DIR/scripts/update.sh" ]] && sudo chmod +x "$INSTALL_DIR/scripts/update.sh"
[[ -f "$INSTALL_DIR/scripts/uninstall.sh" ]] && sudo chmod +x "$INSTALL_DIR/scripts/uninstall.sh"

# 5. Recreate the global wrapper
sudo tee "$INSTALL_BIN" > /dev/null <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
exec /usr/local/share/genpy/bin/genpy "$@"
EOF
sudo chmod +x "$INSTALL_BIN"

echo "✅ GenPy updated to $new_sha."
