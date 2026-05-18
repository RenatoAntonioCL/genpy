#!/bin/bash

# =========================
# INIT
# =========================

BIN_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BASE_DIR="$(cd "$BIN_DIR/.." && pwd)"
WORKDIR="$(pwd)"

set -e

echo "🛠️ GenPy Pipeline v2.1.3"
echo "BASE_DIR=$BASE_DIR"

# =========================
# LOAD MODULES (SAFE)
# =========================

load_module() {
  local file="$1"

  if [[ ! -f "$file" ]]; then
    echo "❌ Missing module: $file"
    exit 1
  fi

  source "$file"
  echo "✔ Loaded $(basename "$file")"
}

load_module "$BASE_DIR/lib/validate.sh"
load_module "$BASE_DIR/lib/structure.sh"
load_module "$BASE_DIR/lib/git.sh"
load_module "$BASE_DIR/lib/docker.sh"
load_module "$BASE_DIR/lib/libs.sh"
load_module "$BASE_DIR/lib/venv.sh"

# =========================
# INPUT SAFE LOOP
# =========================

get_project_name() {
  while true; do
    read -p "📁 Nombre del proyecto: " project_name

    if is_valid_name "$project_name"; then
      echo "✅ Nombre válido: $project_name"
      break
    fi

    echo "❌ Nombre inválido, intenta de nuevo"
  done
}

get_project_name

PROJECT_DIR="$WORKDIR/$project_name"

# =========================
# SAFETY CHECK
# =========================

if [[ -d "$PROJECT_DIR" ]]; then
  echo "❌ El proyecto ya existe en: $PROJECT_DIR"
  exit 1
fi

mkdir -p "$PROJECT_DIR"

# =========================
# SAFE CALL WRAPPER
# =========================

call() {
  local fn="$1"
  shift

  if ! declare -f "$fn" >/dev/null; then
    echo "❌ Function not found: $fn"
    exit 1
  fi

  "$fn" "$@"
}

# =========================
# PIPELINE STEPS
# =========================

run_structure() {
  echo "📦 Creando estructura..."
  call create_structure "$PROJECT_DIR"
}

run_git() {
  echo "📁 Inicializando git..."
  call init_git "$PROJECT_DIR"
}

run_dockerfile() {
  echo "🐳 Creando Dockerfile..."
  call create_dockerfile "$PROJECT_DIR"
}

run_libs() {
  call show_menu
  call add_libraries "$PROJECT_DIR"
}

run_commit() {
  call first_commit "$PROJECT_DIR"
}

run_docker() {
  call check_docker || return 0

  read -p "🐳 Docker build? (s/n): " ans

  if [[ "$ans" == "s" ]]; then
    call build_docker "$PROJECT_DIR" "$project_name"
  fi
}

run_venv() {
  echo "🐍 Creando entorno virtual..."
  call create_venv "$PROJECT_DIR"
}

# =========================
# PIPELINE EXECUTION
# =========================

echo ""
echo "🚀 Iniciando pipeline..."
echo ""

run_structure
run_git
run_dockerfile
run_libs
run_commit
run_docker
run_venv

# =========================
# OUTPUT
# =========================

echo ""
echo "🎉 Proyecto creado en:"
echo "$PROJECT_DIR"
echo ""