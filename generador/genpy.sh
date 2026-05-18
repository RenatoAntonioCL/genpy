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

LANGUAGE=${1:-python}
shift || true

# =========================
# FLAGS
# =========================

ENABLE_GIT=false
ENABLE_DOCKER=false
ENABLE_VENV=false

for arg in "$@"; do
  case "$arg" in
    --git) ENABLE_GIT=true ;;
    --docker) ENABLE_DOCKER=true ;;
    --venv) ENABLE_VENV=true ;;
  esac
done

# =========================
# INPUT
# =========================

echo "🛠️ GenPy v2.2.0"
echo ""

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

# =========================
# CORE
# =========================

echo "📦 Creating structure..."
create_structure "$PROJECT_DIR" "$LANGUAGE"

# =========================
# FEATURES
# =========================

if $ENABLE_GIT; then
  echo "📁 Git enabled"
  init_git "$PROJECT_DIR"
  first_commit "$PROJECT_DIR"
fi

if $ENABLE_DOCKER; then
  echo "🐳 Docker enabled"
  create_dockerfile "$PROJECT_DIR"
fi

if $ENABLE_VENV; then
  echo "🐍 Venv enabled"
  create_venv "$PROJECT_DIR"
fi

echo ""
echo "🎉 Project created at:"
echo "$PROJECT_DIR"