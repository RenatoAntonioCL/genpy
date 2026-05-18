#!/bin/bash
set -e

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

INSTALL_BIN="/usr/local/bin/genpy"
INSTALL_DIR="/usr/local/share/genpy"

echo "📦 Instalando GenPy..."

# =========================
# CLEAN
# =========================

sudo rm -rf "$INSTALL_DIR"
sudo rm -f "$INSTALL_BIN"

sudo mkdir -p "$INSTALL_DIR"

# =========================
# COPY EVERYTHING (CRÍTICO)
# =========================

sudo cp -R "$REPO_DIR"/. "$INSTALL_DIR/"

# =========================
# ENTRYPOINT
# =========================

cat <<EOF | sudo tee "$INSTALL_BIN" > /dev/null
#!/bin/bash

BASE_DIR="/usr/local/share/genpy"

if [[ ! -f "\$BASE_DIR/bin/genpy" ]]; then
  echo "❌ Instalación corrupta (faltan archivos)"
  exit 1
fi

bash "\$BASE_DIR/bin/genpy" "\$@"
EOF

sudo chmod +x "$INSTALL_BIN"

echo "✔ Instalado correctamente"
echo "👉 Ejecuta: genpy create"