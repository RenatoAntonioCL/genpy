#!/bin/bash

# ─────────────────────────────
# GenPy - Stable Version (Clean)
# ─────────────────────────────

WORKDIR="$(pwd)"

DOCKER_AVAILABLE=false
SELECTED_LIBS=()

# =============================
# VALIDACIÓN
# =============================
function validate_project_name() {
  if [[ -z "$project_name" ]]; then
    echo "❌ Nombre vacío"
    exit 1
  fi

  if [[ "$project_name" =~ [^a-zA-Z0-9_-] ]]; then
    echo "❌ Nombre inválido (usa letras, números, - o _)"
    exit 1
  fi
}

# =============================
# DOCKER CHECK
# =============================
function check_docker() {
  echo "🐳 Verificando Docker..."

  if ! command -v docker &>/dev/null; then
    DOCKER_AVAILABLE=false
    echo "⚠️ Docker no está instalado"
    return
  fi

  if ! docker info &>/dev/null; then
    DOCKER_AVAILABLE=false
    echo "⚠️ Docker está instalado pero NO está corriendo"
    echo "👉 Abre Docker Desktop"
    return
  fi

  DOCKER_AVAILABLE=true
  echo "✅ Docker listo"
}

# =============================
# LIBRERÍAS MENU
# =============================
function show_menu() {
  echo -e "\nSelecciona librerías (números separados por espacio):"

  options=(
    "fastapi"
    "flake8"
    "python-dotenv"
    "requests"
    "loguru"
    "pytest"
    "numpy"
    "pandas"
  )

  for i in "${!options[@]}"; do
    echo "$((i+1))) ${options[i]}"
  done

  echo "9) Listo"

  selected=()

  while true; do
    read -p ">>> " -a choices

    for choice in "${choices[@]}"; do
      if [[ "$choice" == "9" ]]; then
        SELECTED_LIBS=("${selected[@]}")
        return
      elif [[ "$choice" =~ ^[1-8]$ ]]; then
        lib="${options[$((choice-1))]}"
        if [[ ! " ${selected[*]} " =~ " $lib " ]]; then
          selected+=("$lib")
          echo "✅ $lib agregado"
        fi
      fi
    done
  done
}

# =============================
# ESTRUCTURA PROYECTO
# =============================
function create_structure() {
  mkdir -p "$PROJECT_DIR/src"
  mkdir -p "$PROJECT_DIR/test"

  echo "# $project_name" > "$PROJECT_DIR/README.md"
  echo "Proyecto generado con GenPy" >> "$PROJECT_DIR/README.md"

  echo "DEBUG=True" > "$PROJECT_DIR/.env"
  echo "DEBUG=True" > "$PROJECT_DIR/.env.example"

  touch "$PROJECT_DIR/requirements.txt"

  echo 'print("👋 Hello from GenPy")' > "$PROJECT_DIR/src/main.py"

  echo -e "def test_example():\n    assert True" > "$PROJECT_DIR/test/test_main.py"

  touch "$PROJECT_DIR/src/__init__.py"
}

# =============================
# DOCKERFILE
# =============================
function create_dockerfile() {
  cat > "$PROJECT_DIR/Dockerfile" <<EOF
FROM python:3.10-slim

WORKDIR /app
COPY . /app

RUN pip install --no-cache-dir -r requirements.txt

CMD ["python", "src/main.py"]
EOF

  echo "🐳 Dockerfile creado"
}

# =============================
# GIT
# =============================
function init_git() {
  cd "$PROJECT_DIR" || exit
  git init -q
}

function first_commit() {
  git add .
  git commit -m "Initial commit - GenPy project"
}

# =============================
# LIBRERÍAS
# =============================
function add_libraries() {
  for lib in "${SELECTED_LIBS[@]}"; do
    echo "$lib" >> "$PROJECT_DIR/requirements.txt"
  done
}

# =============================
# VENV
# =============================
function create_venv() {
  python3 -m venv "$PROJECT_DIR/env"
}

# =============================
# MAIN FLOW
# =============================

echo "🛠️  GenPy - Project Generator"

read -p "📁 Nombre del proyecto: " project_name

validate_project_name

PROJECT_DIR="$WORKDIR/$project_name"

# evitar overwrite
if [[ -d "$PROJECT_DIR" ]]; then
  echo "❌ El proyecto ya existe en $PROJECT_DIR"
  exit 1
fi

mkdir -p "$PROJECT_DIR"

# flujo principal
create_structure
create_dockerfile
init_git
show_menu
add_libraries
first_commit

check_docker

if $DOCKER_AVAILABLE; then
  read -p "Docker build? (s/n): " ans
  if [[ "$ans" == "s" ]]; then
    echo "🐳 Construyendo Docker en $PROJECT_DIR"
    docker build -t "$project_name" "$PROJECT_DIR"
  fi
fi

create_venv

# =============================
# OUTPUT FINAL
# =============================
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━"
echo "📦 Dependencies"
echo "━━━━━━━━━━━━━━━━━━━━━━"

if [[ ${#SELECTED_LIBS[@]} -eq 0 ]]; then
  echo "No external libraries selected"
else
  for lib in "${SELECTED_LIBS[@]}"; do
    echo "• $lib"
  done
fi

echo ""
echo "🎉 Proyecto creado en:"
echo ""
echo "$PROJECT_DIR"
echo ""