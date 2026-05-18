#!/opt/homebrew/bin/bash
set -euo pipefail

# =============================================================================
# GenPy — lib/docker.sh
#
# Gestiona la creación de Dockerfiles optimizados por ecosistema técnico.
# Implementa builds multi-stage para optimizar drásticamente el peso en producción.
# =============================================================================

# -----------------------------------------------------------------------------
# create_dockerfile
#
# Escribe un Dockerfile adaptativo según el lenguaje del proyecto.
# Si existen paquetes declarados en caliente sin compilador local, Docker
# se encarga de resolverlos mediante la lectura de '.genpy_packages'.
#
# Argumentos:
#   $1 — project_dir:      Ruta absoluta al directorio del proyecto
#   $2 — selected_language: El identificador del stack (python, node, go, rust)
# -----------------------------------------------------------------------------
create_dockerfile() {
  local project_dir="$1"
  local selected_language="$2"

  case "$selected_language" in
  python)
      cat > "$project_dir/Dockerfile" <<'EOF'
FROM python:3.10-slim


WORKDIR /app


COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt


COPY . .
# Apunta al nuevo src/main.py
CMD ["python", "src/main.py"]
EOF
      ;;

    node)
      cat > "$project_dir/Dockerfile" <<'EOF'
FROM node:20-slim
WORKDIR /app
COPY package*.json ./
RUN npm install --production
COPY . .
# Asegúrate de que en tu template de package.json el script "start" ejecute: "node src/index.js"
CMD ["npm", "start"]
EOF
      ;;

    go)
      cat > "$project_dir/Dockerfile" <<'EOF'
FROM golang:1.22-alpine AS builder
WORKDIR /app
COPY go.mod ./
COPY .genpy_packages* ./

RUN if [ -f .genpy_packages ]; then \
      while read -r lib; do \
        clean_lib=$(echo "$lib" | xargs); \
        if [ -n "$clean_lib" ]; then \
          echo "📥 Docker instalando módulo: $clean_lib" && go get "$clean_lib"; \
        fi; \
      done < .genpy_packages; \
    fi

RUN go mod tidy
COPY . .
# ¡Aquí está la magia! Compila el archivo que movimos a src/
RUN CGO_ENABLED=0 GOOS=linux go build -o /main ./src/main.go

FROM alpine:3.19
WORKDIR /
COPY --from=builder /main /main
EXPOSE 8080
CMD ["/main"]
EOF
      ;;

    rust)
      cat > "$project_dir/Dockerfile" <<'EOF'
FROM rust:1.76-slim AS builder
WORKDIR /app
COPY Cargo.toml ./
COPY .genpy_packages* ./

# El caché dummy ahora respeta la estructura src/
RUN mkdir src && echo "fn main() {}" > src/main.rs \
    && if [ -f .genpy_packages ]; then \
         while read -r crate; do cargo add "$crate"; done < .genpy_packages; \
       fi \
    && cargo build --release

COPY . .
RUN cargo build --release

FROM debian:bookworm-slim
WORKDIR /app
COPY --from=builder /app/target/release/{{PROJECT_NAME}} ./app_binary
CMD ["./app_binary"]
EOF
      ;;
    

    *)
      echo "❌ Error Crítico: Manifiesto Docker inexistente para '$selected_language'"
      exit 1
      ;;
  esac

  # ── Generación del .dockerignore Universal ────────────────────────────────
  cat > "$project_dir/.dockerignore" <<'EOF'
# Control de versiones
.git/
.gitignore

# Python locales
env/
venv/


__pycache__/
*.pyc

# Node locales
node_modules/
npm-debug.log

# Compilados locales (Go y Rust)
target/
bin/

# Archivos de configuración volátiles de GenPy
.genpy_packages

# Datos secretos locales
.env
EOF

  echo "🐳 Dockerfile y .dockerignore creados para ${selected_language^}"
}

# -----------------------------------------------------------------------------
# build_docker
#
# Dispara la compilación de la imagen en el demonio local de Docker.
#
# Argumentos:
#   $1 — project_dir:  Ruta absoluta al directorio del proyecto
#   $2 — project_name: Nombre asignado a la etiqueta de la imagen (lowercase)
# -----------------------------------------------------------------------------
build_docker() {
  local project_dir="$1"


  local image_name="${2,,}"


  if ! command -v docker &>/dev/null; then
    echo "⚠️  Docker no se encuentra activo o instalado — Se omite el build de la imagen"
    return 0
  fi

  echo "🐳 Construyendo imagen Docker: $image_name"
  docker build -t "$image_name" "$project_dir"
}
