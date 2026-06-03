#!/usr/bin/env bash
set -euo pipefail
# =============================================================================
# GenPy — lib/ui/banner.sh (v5.0.0)
#
# Application startup banner.
# Extracted from utils.sh to separate responsibilities.
# =============================================================================

print_banner() {
  clear
  echo -e "\n"
  echo -e "${MAGENTA_BG}${WHITE} ██████  ███████ ███    ██ ██████  ██    ██  ${NC}"
  echo -e "${MAGENTA_BG}${WHITE} ██       ██      ████   ██ ██   ██  ██  ██   ${NC}"
  echo -e "${MAGENTA_BG}${WHITE} ██   ███ █████   ██ ██  ██ ██████    ████    ${NC}"
  echo -e "${MAGENTA_BG}${WHITE} ██    ██ ██      ██  ██ ██ ██         ██     ${NC}"
  echo -e "${MAGENTA_BG}${WHITE}  ██████  ███████ ██   ████ ██         ██     ${NC}${CYAN} v${GENPY_VERSION}${NC}"
  echo -e "${DIM}  ════════════════════════════════════════════════${NC}"
  echo -e "        ${CYAN}UNIVERSAL SOFTWARE FACTORY & SANDBOX${NC}"
  echo -e "${DIM}  ════════════════════════════════════════════════${NC}\n"
}
