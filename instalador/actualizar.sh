#!/bin/bash
set -euo pipefail

# =============================================================================
# GenPy — Actualizador
#
# Descarga la última versión del repositorio oficial y la instala en el sistema,
# reemplazando la versión anterior por completo.
#
# Uso:
#   genpy update
#   bash instalador/actualizar.sh
#
# Requiere: git, sudo
# =============================================================================

# URL del repositorio oficial en GitHub
readonly REPO_URL="https://github.com/RenatoAntonioCL/genpy.git"

# Directorio temporal para clonar antes de instalar.
# mktemp -d crea un directorio único y seguro en /tmp.
TMP_DIR="$(mktemp -d)"

# Rutas de instalación en el sistema
readonly INSTALL_DIR="/usr/local/share/genpy"
readonly INSTALL_BIN="/usr/local/bin/genpy"

# ─── Limpieza garantizada ────────────────────────────────────────────────────
# trap asegura que el directorio temporal se elimine al salir,
# ya sea por éxito, error, o señal de interrupción (Ctrl+C).
trap 'rm -rf "$TMP_DIR"' EXIT

echo "⬇️  Actualizando GenPy..."

# ─── Descargar la última versión ─────────────────────────────────────────────
# --depth 1 clona solo el último commit (más rápido, sin historial completo)

git clone --depth 1 "$REPO_URL" "$TMP_DIR"

# ─── Reemplazar la instalación anterior ──────────────────────────────────────

sudo rm -rf "$INSTALL_DIR"
sudo mkdir -p "$INSTALL_DIR"
sudo cp -R "$TMP_DIR"/. "$INSTALL_DIR/"

# ─── Restaurar permisos de ejecución ─────────────────────────────────────────

sudo chmod +x "$INSTALL_DIR/bin/genpy"
sudo chmod +x "$INSTALL_DIR/generador/genpy.sh"
sudo chmod +x "$INSTALL_DIR/instalador/actualizar.sh"
sudo chmod +x "$INSTALL_DIR/instalador/desinstalar.sh"

# ─── Recrear el wrapper del sistema ──────────────────────────────────────────
# Idéntico al de instalar.sh para garantizar consistencia.
# Si bin/genpy cambia de ruta en el futuro, solo hay que actualizar aquí y en instalar.sh.

sudo tee "$INSTALL_BIN" > /dev/null <<'EOF'
#!/bin/bash
set -euo pipefail
exec bash "/usr/local/share/genpy/bin/genpy" "$@"
EOF

sudo chmod +x "$INSTALL_BIN"



echo "✅ GenPy actualizado correctamente"