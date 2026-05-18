#!/bin/bash
set -euo pipefail

# =============================================================================
# GenPy — lib/venv.sh
#
# Crea un entorno virtual de Python dentro del proyecto generado.
# El entorno se llama "env/" y está incluido en el .gitignore por defecto.
# =============================================================================

# -----------------------------------------------------------------------------
# create_venv
#
# Crea un entorno virtual de Python en <project_dir>/env usando el módulo
# estándar venv (disponible en Python 3.3+).
#
# Argumentos:
#   $1 — ruta absoluta al directorio del proyecto
# -----------------------------------------------------------------------------
create_venv() {
  local project_dir="$1"

  # Verificar que python3 esté disponible antes de intentar crear el venv.
  # command -v es más portable que which para este propósito.
  if ! command -v python3 &>/dev/null; then
    echo "❌ python3 no está instalado en este sistema"
    echo "   Instálalo desde https://python.org o con tu gestor de paquetes"
    exit 1
  fi

  # Crear el entorno virtual en la subcarpeta "env/" del proyecto
  python3 -m venv "$project_dir/env"

  echo "🐍 Entorno virtual creado en $project_dir/env"
  echo "   Para activarlo: source $project_dir/env/bin/activate"
}
