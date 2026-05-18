#!/bin/bash

DOCKER_AVAILABLE=false

check_docker() {
  echo "🐳 Verificando Docker..."

  if ! command -v docker &>/dev/null; then
    DOCKER_AVAILABLE=false
    echo "⚠️ Docker no instalado"
    return 1
  fi

  if ! docker info &>/dev/null; then
    DOCKER_AVAILABLE=false
    echo "⚠️ Docker no está corriendo"
    return 1
  fi

  DOCKER_AVAILABLE=true
  echo "✅ Docker listo"
}

build_docker() {
  local dir=$1
  local name=$(echo "$2" | tr '[:upper:]' '[:lower:]')

  echo "🐳 Construyendo Docker en $dir"
  echo "🐳 Imagen: $name"

  docker build -t "$name" "$dir"
}

create_dockerfile() {
  local dir=$1

  cat > "$dir/Dockerfile" <<EOF
FROM python:3.10-slim

WORKDIR /app
COPY . /app

RUN pip install --no-cache-dir -r requirements.txt

CMD ["python", "src/main.py"]
EOF

  echo "🐳 Dockerfile creado"
}