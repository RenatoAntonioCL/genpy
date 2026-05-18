#!/bin/bash
set -e

BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WORKDIR="$(pwd)"

source "$BASE_DIR/lib/validate.sh"
source "$BASE_DIR/lib/structure.sh"
source "$BASE_DIR/lib/git.sh"
source "$BASE_DIR/lib/docker.sh"
source "$BASE_DIR/lib/libs.sh"
source "$BASE_DIR/lib/venv.sh"
source "$BASE_DIR/lib/ui.sh"

echo "🛠️ GenPy v2.2.1"
echo ""

# =========================
# 1. PROJECT NAME
# =========================



read -p "📁 Project name: " project_name

if ! is_valid_name "$project_name"; then
  echo "❌ Invalid name"
  exit 1
fi

PROJECT_DIR="$WORKDIR/$project_name"

if [[ -d "$PROJECT_DIR" ]]; then
  echo "❌ Project already exists"
  exit 1
fi

mkdir -p "$PROJECT_DIR"

echo ""

# =========================
# 2. FLAGS (collected early)
# =========================


ask_yes_no "🐳 ¿Usar Docker?" && RUN_DOCKER=true || RUN_DOCKER=false

echo ""

ask_yes_no "🐍 ¿Crear entorno virtual?" && RUN_VENV=true || RUN_VENV=false

echo ""

# =========================
# PIPELINE (PROFESSIONAL ORDER)
# =========================

PIPELINE=(
  "libs_select"
  "structure"
  "git"
  "libs_install"
  "build_envs"
)

run_step() {
  case "$1" in
    libs_select)
      step_libs_select
      ;;

    structure)
      step_structure
      ;;

    git)
      step_git
      ;;

    libs_install)
      step_libs_install
      ;;

    build_envs)
      step_build_envs
      ;;
  esac
}

run_pipeline() {
  for step in "${PIPELINE[@]}"; do
    echo ""
    echo "🚀 Step: $step"
    run_step "$step"
  done
}

# =========================
# STEPS
# =========================

step_structure() {
  echo "📦 Creating structure..."
  create_structure "$PROJECT_DIR"
}

step_git() {
  echo "📁 Git init..."
  init_git "$PROJECT_DIR"
}

step_libs_select() {
  echo "📚 Selecting libraries..."
  select_libraries
}

step_libs_install() {
  echo "📦 Installing libraries..."
  add_libraries "$PROJECT_DIR"
}

step_build_envs() {

  if [[ "$RUN_DOCKER" == true ]]; then
    echo "🐳 Docker enabled"
    create_dockerfile "$PROJECT_DIR"

    echo "🐳 Building Docker..."
    build_docker "$PROJECT_DIR" "$project_name"
  fi

  if [[ "$RUN_VENV" == true ]]; then
    echo "🐍 Venv enabled"
    create_venv "$PROJECT_DIR"
  fi
}

# =========================
# EXECUTION
# =========================

run_pipeline

echo ""
echo "🎉 Project created at:"
echo "$PROJECT_DIR"
echo ""