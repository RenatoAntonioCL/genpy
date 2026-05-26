#!/usr/bin/env bash
# lib/core/preflight.sh

# Reutilizar validadores de comando de errors.sh
source "$LIB_DIR/core/errors.sh"

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