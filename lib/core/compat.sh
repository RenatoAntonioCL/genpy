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

# Shim para lsof (Reparación R4 integrada)
# Esta función reemplaza a lsof en docker.sh para ser portable
_port_in_use() {
    local port="$1"
    if command -v ss &>/dev/null; then
        ss -tuln | grep -q ":$port "
    elif command -v netstat &>/dev/null; then
        netstat -tuln | grep -q ":$port "
    else
        # Fallback por si no hay herramientas de red (poco probable en Docker hosts)
        (echo > /dev/tcp/localhost/"$port") &>/dev/null
    fi
}