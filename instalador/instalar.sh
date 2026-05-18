#!/bin/bash
set -euo pipefail

# =============================================================================
# GenPy — Instalador
#
# Copia el proyecto completo a /usr/local/share/genpy y crea un wrapper
# en /usr/local/bin/genpy para que el comando esté disponible globalmente.
#
# Uso:
#   bash instalador/instalar.sh
#
# Requiere: sudo (para escribir en /usr/local)
# =============================================================================

# REPO_DIR: raíz del repositorio desde donde se está ejecutando el instalador.
# Navega un nivel arriba desde la carpeta "instalador/" para llegar a la raíz.
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Ruta donde vive GenPy una vez instalado en el sistema
readonly INSTALL_DIR="/usr/local/share/genpy"

# Ruta del comando global que el usuario va a ejecutar
readonly INSTALL_BIN="/usr/local/bin/genpy"

echo "📦 Instalando GenPy..."

# ─── Limpiar instalación anterior ────────────────────────────────────────────
# Garantiza un estado limpio antes de copiar. Sin esto, archivos eliminados
# del repo seguirían presentes en la instalación.

sudo rm -rf "$INSTALL_DIR"
sudo rm -f  "$INSTALL_BIN"

# ─── Copiar el proyecto completo ─────────────────────────────────────────────

sudo mkdir -p "$INSTALL_DIR"
sudo cp -R "$REPO_DIR/"* "$INSTALL_DIR/"

# ─── Asegurar permisos de ejecución ──────────────────────────────────────────
# cp no garantiza permisos de ejecución en todos los sistemas,
# así que los establecemos explícitamente.

sudo chmod +x "$INSTALL_DIR/bin/genpy"
sudo chmod +x "$INSTALL_DIR/generador/genpy.sh"
sudo chmod +x "$INSTALL_DIR/instalador/actualizar.sh"
sudo chmod +x "$INSTALL_DIR/instalador/desinstalar.sh"

# ─── Crear el wrapper del sistema ────────────────────────────────────────────
# Este es el script que se ejecuta cuando el usuario escribe "genpy" en la terminal.
# Solo redirige la llamada a bin/genpy dentro de la instalación.
# Usar 'exec' reemplaza el proceso actual en lugar de crear un subproceso hijo.

sudo tee "$INSTALL_BIN" > /dev/null <<'EOF'
#!/opt/homebrew/bin/bash
set -euo pipefail
exec /opt/homebrew/bin/bash "/usr/local/share/genpy/bin/genpy" "$@"
EOF

sudo chmod +x "$INSTALL_BIN"

echo "✔ GenPy instalado correctamente"
echo "  Ejecuta: genpy create"