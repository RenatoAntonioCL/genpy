#!/usr/bin/env bash
# lib/core/compat.sh

# Detectar OS y Arquitectura
export GENPY_OS="$(uname -s | tr '[:upper:]' '[:lower:]')"
export GENPY_ARCH="$(uname -m)"

# Validar versión de Bash (Invariante A1)
if (( BASH_VERSINFO < 4 )); then
    echo "❌ Error: GenPy requiere Bash 4.0 o superior."
    echo "Tu versión actual es: $BASH_VERSION"
    [[ "$GENPY_OS" == "darwin" ]] && echo "Tip: Ejecuta 'brew install bash' para actualizar."
    exit 1
fi

# Shim portable para detectar si un puerto está en uso
_port_in_use() {
    local port="$1"
    if command -v ss &>/dev/null; then
        ss -tuln | grep -q ":$port "
    elif command -v netstat &>/dev/null; then
        netstat -tuln | grep -q ":$port "
    else
        (echo > /dev/tcp/localhost/"$port") &>/dev/null
    fi
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