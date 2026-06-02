#!/usr/bin/env bash
# lib/core/preflight.sh

source "$LIB_DIR/core/errors.sh"
source "$LIB_DIR/docker.sh"

preflight_mode_review() {
  local status=0
  print_section "Preflight — genpy review"

  require_command "curl" "curl es necesario para comunicarse con el provider IA."

  # Árbol de trabajo limpio — create_checkpoint lo verifica también, pero
  # es mejor fallar aquí con un mensaje claro antes de crear la rama.
  local git_dirty
  git_dirty=$(git status --porcelain 2>/dev/null || true)
  if [[ -n "$git_dirty" ]]; then
    print_error "El árbol de trabajo tiene cambios sin commitear. Haz commit o stash primero."
    status=1
  fi

  # Ollama accesible
  local ollama_host="${OLLAMA_HOST:-http://localhost:11434}"
  if ! curl -s --max-time 3 "${ollama_host}/api/tags" &>/dev/null; then
    print_error "Ollama no responde en ${ollama_host}. Verifica que esté en ejecución."
    status=1
  fi

  return "$status"
}

preflight_mode_create() {
    local status=0
    echo -e "\n🔍 Ejecutando chequeos preventivos..."

    # 1. Validar comandos esenciales (Invariante P2)
    require_command "docker" "Instala Docker Desktop para continuar."
    require_command "git" "Git es obligatorio para el control de versiones."

    # 2. Salud del demonio Docker (Reutiliza lib/docker.sh)
    if ! check_docker_daemon; then
        status=1
    fi

    # 3. Espacio en disco (>500MB) para evitar fallos de rsync
    local free_kb
    free_kb=$(df -k . | awk 'NR==2 {print $4}')
    if [[ $free_kb -lt 512000 ]]; then
        print_warning "Espacio en disco bajo (<500MB). El build podría fallar."
    fi

    # 4. Permisos de escritura en el directorio actual
    if [[ ! -w "." ]]; then
        print_error "No tienes permisos de escritura en este directorio."
        status=1
    fi

    return $status
}