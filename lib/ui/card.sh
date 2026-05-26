#!/usr/bin/env bash
set -euo pipefail
# =============================================================================
# GenPy — lib/ui/card.sh (v5.0.0)
#
# Tarjeta visual de resumen del proyecto antes de confirmar la creación.
# Extraído de utils.sh. Lee metadatos desde core/config.sh via blueprint_meta().
#
# Antes: descripción, stack, puertos hardcodeados aquí en un case gigante.
# Ahora: todo se obtiene desde BLUEPRINT_META en config.sh.
# =============================================================================

# -----------------------------------------------------------------------------
# print_blueprint_card
#
# Argumentos:
#   $1 — project_name
#   $2 — blueprint
#   $3 — git_mode: "local" | "private" | "public"
# -----------------------------------------------------------------------------
print_blueprint_card() {
    local project_name="$1"
    local blueprint="$2"
    local git_mode="$3"

    # Leer metadatos desde config.sh
    local description stack libs ports
    description=$(blueprint_meta "$blueprint" "description")
    stack=$(blueprint_meta "$blueprint" "stack")
    libs=$(blueprint_meta "$blueprint" "libs")
    ports=$(blueprint_meta "$blueprint" "ports")

    # Mapeo de Git sin los comentarios grises (limpia la tarjeta)
    local git_label=""
    case "$git_mode" in
        local)   git_label="Local Repository" ;;
        private) git_label="GitHub (Private)" ;;
        public)  git_label="GitHub (Public)" ;;
    esac

    echo ""
    echo -e "  ${CYAN}┌──────────────────────────────────────────────────────────┐${NC}"
    echo -e "  ${CYAN}│${NC}   ${WHITE}${MSG_CARD_TITLE}${NC}                                  ${CYAN}│${NC}"
    echo -e "  ${CYAN}├──────────────────────────────────────────────────────────┤${NC}"
    printf "  ${CYAN}│${NC}   ${WHITE}%-15s${NC} %-39s ${CYAN}│${NC}\n" "$MSG_CARD_PROJECT"    "$project_name"
    printf "  ${CYAN}│${NC}   ${WHITE}%-15s${NC} %-39s ${CYAN}│${NC}\n" "$MSG_CARD_BLUEPRINT"  "$blueprint"
    printf "  ${CYAN}│${NC}   ${WHITE}%-15s${NC} %-39s ${CYAN}│${NC}\n" "$MSG_CARD_DESC"       "$description"
    echo -e "  ${CYAN}├──────────────────────────────────────────────────────────┤${NC}"
    printf "  ${CYAN}│${NC}   ${WHITE}%-15s${NC} %-39s ${CYAN}│${NC}\n" "$MSG_CARD_STACK"      "$stack"
    printf "  ${CYAN}│${NC}   ${WHITE}%-15s${NC} %-39s ${CYAN}│${NC}\n" "$MSG_CARD_LIBS"       "$libs"
    printf "  ${CYAN}│${NC}   ${WHITE}%-15s${NC} %-39s ${CYAN}│${NC}\n" "$MSG_CARD_PORTS"      "$ports"
    echo -e "  ${CYAN}├──────────────────────────────────────────────────────────┤${NC}"
    printf "  ${CYAN}│${NC}   ${WHITE}%-15s${NC} %-39s ${CYAN}│${NC}\n" "$MSG_CARD_GIT"        "$git_label"
    echo -e "  ${CYAN}└──────────────────────────────────────────────────────────┘${NC}"
    echo ""
}