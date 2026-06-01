#!/usr/bin/env bash
# lib/core/compat.sh

# Detectar OS y Arquitectura
export GENPY_OS="$(uname -s | tr '[:upper:]' '[:lower:]')"
export GENPY_ARCH="$(uname -m)"

# Validar versión de Bash (Invariante A1 / ADR-0001)
# Mínimo 4.3: se usan namerefs (local -n) en libs.sh, guardians.sh y menus.sh.
if (( BASH_VERSINFO[0] < 4 || (BASH_VERSINFO[0] == 4 && BASH_VERSINFO[1] < 3) )); then
    echo "❌ Error: GenPy requiere Bash 4.3 o superior (usa namerefs: local -n)."
    echo "Tu versión actual es: $BASH_VERSION"
    [[ "$GENPY_OS" == "darwin" ]] && echo "Tip: Ejecuta 'brew install bash' para actualizar."
    exit 1
fi

# Shim portable para detectar si un puerto está en uso.
# Comprueba tanto listeners del SO como contenedores Docker activos.
_port_in_use() {
    local port="$1"
    # Listeners del sistema operativo
    if command -v ss &>/dev/null; then
        ss -tuln | grep -q ":$port " && return 0
    elif command -v netstat &>/dev/null; then
        netstat -tuln | grep -q ":$port " && return 0
    else
        (echo > /dev/tcp/localhost/"$port") &>/dev/null && return 0
    fi
    # Puertos enlazados por contenedores Docker (de cualquier proyecto)
    if command -v docker &>/dev/null; then
        docker ps --format '{{.Ports}}' 2>/dev/null | grep -q ":$port->" && return 0
    fi
    return 1
}

# Devuelve el primer puerto >= $1 que esté libre.
# Imprime el puerto encontrado; retorna 1 si se agota el rango.
_find_free_port() {
    local port="$1"
    while _port_in_use "$port"; do
        (( port++ ))
        if (( port > 65535 )); then
            echo "0"
            return 1
        fi
    done
    echo "$port"
}