#!/usr/bin/env bash
# lib/core/compat.sh

# Detect OS and Architecture
GENPY_OS="$(uname -s | tr '[:upper:]' '[:lower:]')"
export GENPY_OS
GENPY_ARCH="$(uname -m)"
export GENPY_ARCH

# Validate Bash version (Invariant A1 / ADR-0001)
# Minimum 4.3: namerefs (local -n) are used in libs.sh, guardians.sh and menus.sh.
if (( BASH_VERSINFO[0] < 4 || (BASH_VERSINFO[0] == 4 && BASH_VERSINFO[1] < 3) )); then
    echo "❌ Error: GenPy requires Bash 4.3 or higher (uses namerefs: local -n)."
    echo "Your current version is: $BASH_VERSION"
    [[ "$GENPY_OS" == "darwin" ]] && echo "Tip: Run 'brew install bash' to update."
    exit 1
fi

# Portable shim to detect if a port is in use.
# Checks both OS listeners and active Docker containers.
_port_in_use() {
    local port="$1"
    # OS listeners
    if command -v ss &>/dev/null; then
        ss -tuln | grep -q ":$port " && return 0
    elif command -v netstat &>/dev/null; then
        netstat -tuln | grep -q ":$port " && return 0
    else
        (echo > /dev/tcp/localhost/"$port") &>/dev/null && return 0
    fi
    # Ports bound by Docker containers (from any project)
    if command -v docker &>/dev/null; then
        docker ps --format '{{.Ports}}' 2>/dev/null | grep -q ":$port->" && return 0
    fi
    return 1
}

# Returns the first port >= $1 that is free.
# Prints the found port; returns 1 if the range is exhausted.
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
