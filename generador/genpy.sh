#!/opt/homebrew/bin/bash
set -euo pipefail

# =============================================================================
# GenPy v3.0.0 — Orquestador de Proyectos Multi-Stack
#
# Lanza el flujo interactivo de configuración y procesa de forma secuencial
# e idiopática la construcción de proyectos locales y despliegues remotos.
# =============================================================================

# Raíz de la instalación de GenPy resuelta de manera dinámica y relativa
BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Directorio de ejecución desde donde el usuario invoca la herramienta
WORKDIR="$(pwd)"

# ─── Carga de Módulos Modulares (Librerías externas) ──────────────────────────
source "$BASE_DIR/lib/validate.sh"   # Validación de strings (is_valid_name)
source "$BASE_DIR/lib/language.sh"   # Gestión de stacks (select_language, get_template_dir)
source "$BASE_DIR/lib/template.sh"   # Motor de clonación de plantillas (copy_template)
source "$BASE_DIR/lib/git.sh"        # Inicialización de VCS (git_init, git_first_commit)
source "$BASE_DIR/lib/docker.sh"     # Infraestructura de contenedores (create_dockerfile)
source "$BASE_DIR/lib/libs.sh"       # Manejador de dependencias (select_libraries)
source "$BASE_DIR/lib/venv.sh"       # Aislamiento Python (create_venv)
source "$BASE_DIR/lib/github.sh"     # Integración remota API Cloud (push_to_github)
source "$BASE_DIR/lib/ui.sh"         # Utilidades de terminal (ask_yes_no)

echo ""
echo "🛠️  GenPy v3.0.0 (Core Multilenguaje)"
echo "══════════════════════════════════════════════════"
echo ""

# =============================================================================
# FASE I — Captura y Validación de Entradas
# =============================================================================

# ── Paso 1: Identificador del Proyecto ───────────────────────────────────────
read -rp "📁 Nombre del proyecto: " project_name


if ! is_valid_name "$project_name"; then
  echo "❌ Formato inválido: Usa únicamente letras, números, guiones (-) o guiones bajos (_)"
  exit 1
fi


PROJECT_DIR="$WORKDIR/$project_name"

# Validación defensiva del sistema de archivos
if [[ -d "$PROJECT_DIR" ]]; then
  echo "❌ Conflicto de espacio: El directorio ya existe en $PROJECT_DIR"
  exit 1
fi

echo ""

# ── Paso 2: Selección del Ecosistema de Desarrollo ───────────────────────────
SELECTED_LANGUAGE=""
select_language SELECTED_LANGUAGE

TEMPLATE_DIR=""
get_template_dir "$BASE_DIR" "$SELECTED_LANGUAGE" TEMPLATE_DIR

echo ""

# ── Paso 3: Configuración de Entornos Locales y Remotos ──────────────────────
ask_yes_no "🐳 ¿Deseas incluir soporte para Docker?" && USE_DOCKER=true || USE_DOCKER=false
echo ""

# El entorno venv nativo solo aplica si el stack técnico es Python
USE_VENV=false
if [[ "$SELECTED_LANGUAGE" == "python" ]]; then
  ask_yes_no "🐍 ¿Deseas inicializar un entorno virtual aislado (venv)?" && USE_VENV=true || USE_VENV=false
  echo ""
fi

ask_yes_no "🐙 ¿Deseas publicar este proyecto de forma automática en GitHub?" && PUSH_GITHUB=true || PUSH_GITHUB=false
echo ""

IS_PRIVATE_REPO=true
if [[ "$PUSH_GITHUB" == true ]]; then
  ask_yes_no "🔒 ¿El repositorio en GitHub debe ser PRIVADO?" && IS_PRIVATE_REPO=true || IS_PRIVATE_REPO=false
  echo ""
fi

# =============================================================================
# FASE II — Declaración del Pipeline Arquitectónico
#
# Nota de Diseño: El orden es milimétrico. Las variables de metadatos se inyectan 
# DESPUÉS de escribir el Dockerfile para asegurar la limpieza mutua de placeholders, 
# y los commits locales ocurren ANTES de subir los datos a la nube (Fase 3).
# =============================================================================

PIPELINE=(
  "libs_select"    # 1. Menú interactivo de paquetes del ecosistema
  "template"       # 2. Despliegue de archivos base desde /templates
  "docker_setup"   # 3. Inyección del Dockerfile adecuado (Estrategia B)
  "inject_meta"    # 4. Reemplazo general in-place de {{PROJECT_NAME}}
  "libs_install"   # 5. Volcado final de librerías al manifiesto del proyecto
  "git"            # 6. Apertura del repositorio Git y congelamiento del primer commit
  "build_envs"     # 7. Compilación de recursos pesados (Docker builds / venv installs)
  "github_push"    # 8. Sincronización final con GitHub Cloud
)

# =============================================================================
# FASE III — Definición Atómica de Pasos (Steps)
# =============================================================================

step_libs_select() {
  echo "📚 Evaluando dependencias para ${SELECTED_LANGUAGE^}..."
  declare -ga PROJECT_LIBS
  select_libraries PROJECT_LIBS
}

step_template() {
  echo "📦 Desplegando estructura base del template..."
  # Creamos el directorio aquí para blindar el sistema de carpetas huérfanas si el usuario cancela antes
  mkdir -p "$PROJECT_DIR"
  copy_template "$TEMPLATE_DIR" "$PROJECT_DIR" "${project_name}"
  }

step_docker_setup() {
  if [[ "$USE_DOCKER" == true ]]; then
    echo "🐳 Inyectando manifiesto Docker..."
    create_dockerfile "$PROJECT_DIR" "$SELECTED_LANGUAGE"
  else
    echo "🐳 Configuración de Docker omitida por el usuario"
  fi
}

step_inject_meta() {
  echo "🔧 Personalizando metadatos del proyecto..."
  
  # Escaneo iterativo seguro usando delimitador nulo (-print0) para evitar colisiones de rutas
  local target_dir="$PROJECT_DIR"
  while IFS= read -r -d '' filepath; do
    [[ -s "$filepath" ]] || continue
    
    # El comando 'file' previene la alteración accidental de archivos binarios o imágenes
    if file "$filepath" | grep -qE "text|JSON|source"; then
      if [[ "$OSTYPE" == "darwin"* ]]; then
        sed -i '' "s|{{PROJECT_NAME}}|${project_name}|g" "$filepath"
      else
        sed -i "s|{{PROJECT_NAME}}|${project_name}|g" "$filepath"
      fi
    fi
  done < <(find "$target_dir" -type f -print0)
  
  echo "   ✔ Marcadores de plantilla unificados con el nombre: $project_name"
}

step_libs_install() {
  echo "📦 Registrando librerías seleccionadas..."
  add_libraries "$PROJECT_DIR" PROJECT_LIBS
}

step_git() {
  echo "📁 Configurando Control de Versiones (Git)..."
  git_init "$PROJECT_DIR"
  git_first_commit "$PROJECT_DIR"
}

step_build_envs() {

  if [[ "$USE_DOCKER" == true ]]; then
    echo "🐳 Construyendo imagen en el motor de Docker local..."
    build_docker "$PROJECT_DIR" "$project_name"
  fi


  if [[ "$USE_VENV" == true ]]; then
    echo "🐍 Inicializando entorno de ejecución Python..."
    create_venv "$PROJECT_DIR"
  fi
}

step_github_push() {
  if [[ "$PUSH_GITHUB" == true ]]; then
    echo "🚀 Desplegando repositorio en GitHub Cloud..."
    push_to_github "$PROJECT_DIR" "$project_name" "$IS_PRIVATE_REPO"
  fi
}

# =============================================================================
# FASE IV — Motor de Ejecución (Runner Engine)
# =============================================================================

run_step() {
  case "$1" in
    libs_select)  step_libs_select  ;;
    template)     step_template     ;;
    docker_setup) step_docker_setup ;;
    inject_meta)  step_inject_meta  ;;
    libs_install) step_libs_install ;;
    git)          step_git          ;;
    build_envs)   step_build_envs   ;;
    github_push)  step_github_push  ;;
    *)
      echo "❌ Despachador: Error crítico, paso desconocido '$1'"
      exit 1
      ;;
  esac
}

run_pipeline() {
  for step in "${PIPELINE[@]}"; do
    echo ""
    echo "── [$step] ──────────────────────────────────────────"
    run_step "$step"
  done
}

# ─── Lanzar el proceso unificado ─────────────────────────────────────────────
run_pipeline

echo ""
echo "══════════════════════════════════════════════════"
echo "🎉 ¡Ciclo de creación completado con éxito!"
echo "   📍 Directorio Local: $PROJECT_DIR"
if [[ "$PUSH_GITHUB" == true ]]; then
  echo "   🌐 Nube Sincronizada: Repositorio disponible en tu cuenta de GitHub"
fi
echo "══════════════════════════════════════════════════"
echo ""
