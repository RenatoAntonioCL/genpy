#!/bin/bash
set -e

REPO_URL="https://github.com/RenatoAntonioCL/genpy.git"
TMP_DIR=$(mktemp -d)

INSTALL_DIR="/usr/local/share/genpy"
INSTALL_BIN="/usr/local/bin/genpy"

echo "⬇️ Actualizando GenPy..."

git clone "$REPO_URL" "$TMP_DIR"

sudo rm -rf "$INSTALL_DIR"
sudo mkdir -p "$INSTALL_DIR"

sudo cp -R "$TMP_DIR/"* "$INSTALL_DIR/"

cat <<EOF | sudo tee "$INSTALL_BIN" > /dev/null
#!/bin/bash
bash "$INSTALL_DIR/bin/genpy" "\$@"
EOF

sudo chmod +x "$INSTALL_BIN"

rm -rf "$TMP_DIR"

echo "✅ GenPy actualizado correctamente"