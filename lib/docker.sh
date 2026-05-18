#!/bin/bash
set -euo pipefail

# =============================================================================
# GenPy — lib/docker.sh
#
# Genera el Dockerfile y el .dockerignore para el proyecto,
# y opcionalmente construye la imagen si Docker está disponible.
# =============================================================================

# -----------------------------------------------------------------------------
# create_dockerfile
#
# Escribe un Dockerfile base para proyectos Python en el directorio del proyecto.
# Usa python:3.10-slim como imagen base (buena relación tamaño/compatibilidad).
#
# También crea un .dockerignore para excluir archivos que no deben
# copiarse dentro del contenedor (venv, cache, git).
#
# Argumentos:
#   $1 — ruta absoluta al directorio del proyecto
# -----------------------------------------------------------------------------
create_dockerfile() {
  local project_dir="$1"

  # ── Dockerfile principal ──────────────────────────────────────────────────
  cat > "$project_dir/Dockerfile" <<'EOF'
# Imagen base: Python 3.10 slim (sin paquetes de sistema innecesarios)
FROM python:3.10-slim

# Directorio de trabajo dentro del contenedor
WORKDIR /app

# Copiar primero solo requirements.txt para aprovechar el cache de capas de Docker:
# si el código cambia pero las dependencias no, Docker no reinstala los paquetes.
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copiar el resto del proyecto
COPY . .

# Comando por defecto al correr el contenedor
CMD ["python", "src/main.py"]
EOF

  # ── .dockerignore ─────────────────────────────────────────────────────────
  # Excluye archivos que no deben llegar al contenedor.
  # Reduce el tamaño de la imagen y evita exponer datos locales.
  cat > "$project_dir/.dockerignore" <<'EOF'
# Entornos virtuales locales (las dependencias se instalan en el build)
env/
venv/

# Cache de Python
__pycache__/
*.pyc

# Control de versiones (no necesario dentro del contenedor)
.git/
.gitignore

# Variables de entorno locales (no se deben incluir en la imagen)
.env
EOF

  echo "🐳 Dockerfile y .dockerignore creados"
}

# -----------------------------------------------------------------------------
# build_docker
#
# Construye la imagen Docker del proyecto.
# Si Docker no está instalado, avisa y continúa sin fallar.
#
# Argumentos:
#   $1 — ruta absoluta al directorio del proyecto
#   $2 — nombre base para la imagen (se convierte a minúsculas automáticamente)
# -----------------------------------------------------------------------------
build_docker() {
  local project_dir="$1"

  # Docker requiere que los nombres de imagen estén en minúsculas.
  # ${2,,} es la forma nativa de bash 4+ para convertir a lowercase.
  local image_name="${2,,}"

  # Verificar que Docker esté instalado antes de intentar el build
  if ! command -v docker &>/dev/null; then
    echo "⚠️  Docker no está instalado — se omite el build de la imagen"
    echo "   Instálalo en: https://docs.docker.com/get-docker/"
    return 0
  fi

  echo "🐳 Construyendo imagen Docker: $image_name"
  docker build -t "$image_name" "$project_dir"
}
