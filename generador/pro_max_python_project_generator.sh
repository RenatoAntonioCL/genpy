#!/bin/bash

# ───────────────
# Pro Max Python Project Generator
# Crea una estructura profesional con Git, Docker, .env, README, Makefile y librerías opcionales.
# ───────────────

# Variables Globales
BASE_DIR="$PWD"
PROJECT_DIR=""
SRC_DIR=""
TEST_DIR=""
DOCKER_AVAILABLE=false
SELECTED_LIBS=()

# Función: Mostrar menú para seleccionar librerías con selección múltiple
function show_menu() {
  echo -e "\nSelecciona las librerías que quieres instalar (por número, separados por espacio):"
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
    read -p "Escribe los números (ej: 1 3 6) o 9 para terminar: " -a choices
    for choice in "${choices[@]}"; do
      if [[ "$choice" == "9" ]]; then
        return
      elif [[ "$choice" =~ ^[1-8]$ ]]; then
        lib="${options[$((choice-1))]}"
        if [[ ! " ${selected[*]} " =~ " $lib " ]]; then
          selected+=("$lib")
          echo "✅ $lib agregado."
        else
          echo "⚠️  $lib ya estaba seleccionado."
        fi
      else
        echo "❌ Opción inválida: $choice"
      fi
    done
  done
}

# Función: Verificar si Docker está instalado
function check_docker() {
  if ! command -v docker &> /dev/null; then
    echo "⚠️  Docker no está instalado. Se omitirá la creación de la imagen Docker."
    docker_available=false
  else
    docker_available=true
  fi
}

# Función: Validar nombre de proyecto
function validate_project_name() {
  if [[ "$project_name" =~ [^a-zA-Z0-9_-] ]]; then
    echo "❌ Nombre inválido. Usa solo letras, números, guiones o guiones bajos."
    exit 1
  fi
}

# Función: Crear la estructura de carpetas
function create_directories() {
  mkdir -p "$PROJECT_DIR/$project_name" "$SRC_DIR" "$TEST_DIR"
  echo "✅ Estructura de carpetas creada."
}

# Función: Crear archivos básicos del proyecto
function create_files() {
  touch "$SRC_DIR/__init__.py"
  echo 'print("👋 Bienvenido al proyecto")' > "$SRC_DIR/main.py"
  echo -e 'def test_example():\n    assert True' > "$TEST_DIR/test_main.py"

  # Crear README.md
  echo "# $project_name" > "$PROJECT_DIR/README.md"
  echo "Este es un proyecto generado automáticamente con buenas prácticas de desarrollo." >> "$PROJECT_DIR/README.md"

  # Crear .env y .env.example
  echo "# Variables de entorno\nDEBUG=True" > "$PROJECT_DIR/.env"
  echo "# Copia este archivo como .env y completa los valores\nDEBUG=True" > "$PROJECT_DIR/.env.example"

  # Crear requirements.txt
  touch "$PROJECT_DIR/requirements.txt"
}

# Función: Crear .gitignore profesional
function create_gitignore() {
  cat <<EOF > "$PROJECT_DIR/.gitignore"
__pycache__/
.env
*.pyc
*.pyo
*.pyd
.Python
env/
venv/
ENV/
build/
develop-eggs/
dist/
.eggs/
*.egg-info/
.installed.cfg
*.egg
.mypy_cache/
.pytest_cache/
.cache/
*.log
.DS_Store
EOF
  echo "✅ .gitignore creado."
}

# Función: Crear Dockerfile
function create_dockerfile() {
  cat <<EOF > "$PROJECT_DIR/Dockerfile"
FROM python:3.10-slim

WORKDIR /app
COPY . /app

RUN pip install --no-cache-dir -r requirements.txt

CMD ["python", "src/main.py"]
EOF
  echo "✅ Dockerfile creado."
}

# Función: Crear Makefile
function create_makefile() {
  cat <<EOF > "$PROJECT_DIR/Makefile"
PROJECT_NAME=$project_name

install:
	pip install -r requirements.txt

test:
	pytest

run:
	python src/main.py

docker-build:
	docker build -t \$(PROJECT_NAME):latest .

docker-run:
	docker run -it --rm --env-file .env \$(PROJECT_NAME):latest

lint:
	flake8 src test

format:
	autopep8 --in-place --recursive src test
EOF
  echo "✅ Makefile creado."
}

# Función: Crear LEEME-GITHUB.txt
function create_github_instructions() {
  cat <<EOF > "$PROJECT_DIR/LEEME-GITHUB.txt"
Pasos para conectar este proyecto con GitHub:

1. Crea un repositorio en GitHub (sin README ni .gitignore).
2. En este directorio, ejecuta:
   git remote add origin https://github.com/TU_USUARIO/TU_REPO.git
3. Cambia el nombre de la rama principal (si es necesario):
   git branch -M main
4. Sube el proyecto:
   git push -u origin main
EOF
  echo "✅ LEEME-GITHUB.txt creado."
}

# Función: Inicializar repositorio Git
function init_git_repo() {
  git init "$PROJECT_DIR"
  echo "✅ Repositorio Git inicializado."
}

# Función: Agregar librerías seleccionadas al requirements.txt
function add_libraries_to_requirements() {
  for lib in "${SELECTED_LIBS[@]}"; do
    echo "$lib" >> "$PROJECT_DIR/requirements.txt"
    echo "✅ $lib agregado."
  done
}

# Función: Realizar primer commit
function first_commit() {
  git add .
  git commit -m "Primer commit - Estructura profesional generada automáticamente"
  echo "✅ Primer commit realizado."
}

# Función: Instalar librerías si el entorno virtual está activado
function install_libraries() {
  if [[ -d "$PROJECT_DIR/env" ]]; then
    source "$PROJECT_DIR/env/bin/activate"
    pip install -r "$PROJECT_DIR/requirements.txt"
    echo "✅ Librerías instaladas en el entorno virtual."
  fi
}

# Función: Crear entorno virtual
function create_virtualenv() {
  python3 -m venv "$PROJECT_DIR/env"
  echo "✅ Entorno virtual creado."
}

# Mensaje de bienvenida
echo "🛠️  Bienvenido al generador de proyectos Python Pro Max"

# Solicitar nombre del proyecto
read -p "📁 ¿Cómo se llamará tu proyecto? " project_name

# Validar nombre del proyecto
validate_project_name

# Crear directorios y archivos básicos
PROJECT_DIR="$BASE_DIR/$project_name"
SRC_DIR="$PROJECT_DIR/src"
TEST_DIR="$PROJECT_DIR/test"
create_directories
create_files
create_gitignore
create_dockerfile
create_makefile
create_github_instructions

# Inicializar repositorio Git
init_git_repo

# Mostrar menú para librerías
show_menu

# Agregar librerías al requirements.txt
add_libraries_to_requirements

# Crear primer commit
first_commit

# Verificar Docker y ofrecer construir la imagen
check_docker
if [ "$docker_available" = true ]; then
  read -p "¿Quieres construir la imagen Docker ahora? (s/n): " build_now
  if [[ $build_now == "s" ]]; then
    docker build -t "$project_name:latest" .
    echo "✅ Imagen Docker construida."
  else
    echo "ℹ️  Puedes construirla luego con: make docker-build"
  fi
fi

# Verificar entorno virtual y ofrecer instalación de librerías
create_virtualenv
install_libraries

# Mensaje final
echo -e "\n🎉 \033[1;32mProyecto '$project_name' creado exitosamente.\033[0m"
echo "📄 Revisa el archivo LEEME-GITHUB.txt para subir tu proyecto a GitHub."
