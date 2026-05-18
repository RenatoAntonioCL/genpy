#!/bin/bash
set -euo pipefail

# =============================================================================
# GenPy v2.3.0 — Generador principal de proyectos
#
# Orquesta el pipeline completo de creación de un proyecto:
#   1. Pide el nombre del proyecto y valida que sea seguro
#   2. Pregunta qué entornos quiere el usuario (Docker, venv)
#   3. Deja seleccionar librerías de una lista curada
#   4. Crea la estructura de carpetas y archivos base
#   5. Inicializa el repositorio git con un primer commit
#   6. Escribe el requirements.txt con las librerías elegidas
#   7. Construye los entornos seleccionados (Docker image, venv)
# =============================================================================

# BASE_DIR: raíz del proyecto GenPy instalado en el sistema.
# Se resuelve de forma relativa al script para que funcione tanto
# desde la instalación global como desde el repo local en desarrollo.
BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Directorio desde donde el usuario ejecuta el comando.
# El proyecto nuevo se creará como subdirectorio aquí.
WORKDIR="$(pwd)"

# ─── Cargar módulos de la librería ───────────────────────────────────────────

source "$BASE_DIR/lib/validate.sh"   # is_valid_name()
source "$BASE_DIR/lib/structure.sh"  # create_structure()
source "$BASE_DIR/lib/git.sh"        # git_init(), git_first_commit()
source "$BASE_DIR/lib/docker.sh"     # create_dockerfile(), build_docker()
source "$BASE_DIR/lib/libs.sh"       # select_libraries(), add_libraries()
source "$BASE_DIR/lib/venv.sh"       # create_venv()
source "$BASE_DIR/lib/ui.sh"         # ask_yes_no()

echo ""
echo "🛠️  GenPy v2.3.0"
echo ""

# =============================================================================
# PASO 1 — Nombre del proyecto
# =============================================================================

read -rp "📁 Nombre del proyecto: " project_name

# Validar que el nombre solo tenga caracteres seguros para carpetas y repos
if ! is_valid_name "$project_name"; then
  echo "❌ Nombre inválido. Usa solo letras, números, guiones (-) y guiones bajos (_)."
  exit 1
fi

# Ruta absoluta donde se creará el nuevo proyecto
PROJECT_DIR="$WORKDIR/$project_name"

# Evitar sobrescribir un proyecto existente
if [[ -d "$PROJECT_DIR" ]]; then
  echo "❌ Ya existe un directorio con ese nombre: $PROJECT_DIR"
  exit 1
fi

mkdir -p "$PROJECT_DIR"

echo ""

# =============================================================================
# PASO 2 — Opciones de entorno
# Recolectadas antes del pipeline para no interrumpir el flujo de creación
# =============================================================================

ask_yes_no "🐳 ¿Usar Docker?" && USE_DOCKER=true || USE_DOCKER=false
echo ""
ask_yes_no "🐍 ¿Crear entorno virtual (venv)?" && USE_VENV=true || USE_VENV=false
echo ""

# =============================================================================
# PIPELINE — Pasos en orden profesional
#
# El orden importa:
#   - Las librerías se eligen ANTES de crear la estructura,
#     para que requirements.txt ya esté listo al hacer el primer commit.
#   - Git se inicializa DESPUÉS de crear la estructura,
#     para que el primer commit capture todos los archivos base.
#   - Los entornos (Docker, venv) se construyen al final,
#     ya que dependen de requirements.txt y de la estructura.
# =============================================================================

PIPELINE=(
  "libs_select"    # 1. Elegir librerías
  "structure"      # 2. Crear carpetas y archivos base
  "libs_install"   # 3. Escribir requirements.txt con las librerías elegidas
  "git"            # 4. git init + primer commit (captura todo lo anterior)
  "build_envs"     # 5. Docker y/o venv
)

# ─── Definición de cada step ─────────────────────────────────────────────────

step_libs_select() {
  echo "📚 Seleccionando librerías..."

  # PROJECT_LIBS es un array global para que step_libs_install pueda leerlo.
  # Se declara con -g (global) porque las funciones en bash tienen scope local por defecto.
  declare -ga PROJECT_LIBS
  select_libraries PROJECT_LIBS
}

step_structure() {
  echo "📦 Creando estructura de carpetas..."
  create_structure "$PROJECT_DIR"
}

step_libs_install() {
  echo "📦 Escribiendo dependencias..."

  # Pasa PROJECT_LIBS por nombre (nameref) para evitar tener una variable global suelta
  add_libraries "$PROJECT_DIR" PROJECT_LIBS
}

step_git() {
  echo "📁 Inicializando repositorio git..."
  git_init "$PROJECT_DIR"
  git_first_commit "$PROJECT_DIR"
}

step_build_envs() {
  # Docker — solo si el usuario lo pidió y está instalado en el sistema
  if [[ "$USE_DOCKER" == true ]]; then
    echo "🐳 Creando Dockerfile..."
    create_dockerfile "$PROJECT_DIR"

    echo "🐳 Construyendo imagen Docker..."
    build_docker "$PROJECT_DIR" "$project_name"
  fi

  # Entorno virtual — solo si el usuario lo pidió
  if [[ "$USE_VENV" == true ]]; then
    echo "🐍 Creando entorno virtual..."
    create_venv "$PROJECT_DIR"
  fi
}

# ─── Runner del pipeline ─────────────────────────────────────────────────────

# Despacha cada step por nombre. Centralizar el dispatch aquí
# facilita agregar logging, manejo de errores o métricas de tiempo en el futuro.
run_step() {
  case "$1" in
    libs_select)  step_libs_select  ;;
    structure)    step_structure    ;;
    libs_install) step_libs_install ;;
    git)          step_git          ;;
    build_envs)   step_build_envs   ;;
    *)
      echo "❌ Step desconocido: '$1'"
      exit 1
      ;;
  esac
}

run_pipeline() {
  for step in "${PIPELINE[@]}"; do
    echo ""
    echo "── $step ──────────────────────────────────────────"
    run_step "$step"
  done
}

# =============================================================================
# EJECUCIÓN
# =============================================================================

run_pipeline

echo ""
echo "══════════════════════════════════════════════════"
echo "🎉 Proyecto listo en:"
echo "   $PROJECT_DIR"
echo ""
