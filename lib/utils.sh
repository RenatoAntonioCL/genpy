#!/usr/bin/env bash
# =============================================================================
# GenPy — lib/utils.sh (v1.0.0-alpha)
#
# Paleta de colores y funciones de impresión.
# Responsabilidad única: UI primitiva (colores, print_*, separadores).
#
# Lo que se fue:
#   - print_banner     → lib/ui/banner.sh
#   - print_blueprint_card → lib/ui/card.sh
# =============================================================================

[[ -n "${_GENPY_UTILS_LOADED:-}" ]] && return 0
_GENPY_UTILS_LOADED=1

# ─── Paleta de colores ────────────────────────────────────────────────────────

MAGENTA='\033[38;2;255;0;255m'
MAGENTA_BG='\033[48;2;255;0;255m'
CYAN='\033[38;2;0;255;255m'
YELLOW='\033[1;33m'
GREEN='\033[1;32m'
WHITE='\033[1;37m'
DIM='\033[2m'
NC='\033[0m'

export MAGENTA MAGENTA_BG CYAN YELLOW GREEN WHITE DIM NC

# ─── Funciones de impresión ───────────────────────────────────────────────────

print_success() { echo -e " ${CYAN}✔${NC}  $1"; }
print_error()   { echo -e " ${MAGENTA_BG}${WHITE} ❌ Error: $1 ${NC}"; }
print_warning() { echo -e " ${YELLOW}⚠${NC}   $1"; }
print_info()    { echo -e " ${DIM}ℹ${NC}   $1"; }

# ─── Separadores ─────────────────────────────────────────────────────────────

print_line() {
  echo -e "${DIM}──────────────────────────────────────────────────${NC}"
}

print_section() {
  local title="$1"
  echo -e "\n${CYAN}▸ ${WHITE}${title}${NC}"
  echo -e "${DIM}──────────────────────────────────────────────────${NC}"
}

# En lib/utils.sh
show_progress() {
    local msg="$1"
    printf "\r  \033[36m⚙\033[0m %s..." "$msg"
}

# En lib/utils.sh
log_status() {
  printf "\r\033[K  \033[0;32m✔\033[0m %s" "$1"
}