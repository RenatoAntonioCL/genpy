#!/usr/bin/env bash
set -euo pipefail
# =============================================================================
# GenPy — lib/ui/menus.sh (v5.0.0)
#
# Interactive wizard menus.
# Extracted from wizard.sh to separate UI from orchestration.
#
# Before: wizard.sh had area and blueprint menus hardcoded
#         with nested case statements and duplicated strings.
# Now: menus are generated dynamically from AREAS, AREA_BLUEPRINTS
#      and BLUEPRINT_META in config.sh.
# =============================================================================

# -----------------------------------------------------------------------------
# select_area
#
# Shows the area menu and returns the chosen ID in the variable
# passed by name.
#
# Usage:
#   select_area area_id
# -----------------------------------------------------------------------------
select_area() {
  local -n _area_result="$1"

  print_section "$MSG_MENU_AREA_TITLE"

  # Generate menu dynamically from AREAS (defined in config.sh)
  local sorted_ids
  sorted_ids=$(echo "${!AREAS[@]}" | tr ' ' '\n' | sort -n)

  for id in $sorted_ids; do
    printf "  ${WHITE}%d)${NC} %s\n" "$id" "${AREAS[$id]}"
  done
  echo ""

  while true; do
    read -rp "  >>> " choice
    if [[ "$choice" =~ ^[0-9]+$ ]] && [[ -n "${AREAS[$choice]:-}" ]]; then
      _area_result="$choice"
      return 0
    fi
    print_error "$MSG_MENU_AREA_ERR${#AREAS[@]}."
  done
}

# -----------------------------------------------------------------------------
# select_blueprint
#
# Shows the blueprint submenu for the chosen area and returns
# the blueprint name in the variable passed by name.
#
# If the area has a security warning (SECURITY_AREA_ID), it shows it.
#
# Usage:
#   select_blueprint "$area_id" blueprint_name
# -----------------------------------------------------------------------------
select_blueprint() {
  local area_id="$1"
  local -n _blueprint_result="$2"

  local area_name="${AREAS[$area_id]}"
print_section "${area_name}${MSG_MENU_BP_SUFFIX}"
  # Show warning if it's the security area
  if [[ "$area_id" == "$SECURITY_AREA_ID" ]]; then
    echo -e "  ${YELLOW}⚠${NC}  $SECURITY_WARNING\n"
  fi

  # Get area blueprints as an array
  local -a blueprints
  read -ra blueprints <<< "${AREA_BLUEPRINTS[$area_id]}"

  # Generate menu dynamically from BLUEPRINT_META
  for i in "${!blueprints[@]}"; do
    local bp="${blueprints[$i]}"
    local label hint
    label=$(blueprint_meta "$bp" "label")
    hint=$(blueprint_meta "$bp" "hint")
    printf "  ${WHITE}%d)${NC} %-22s ${DIM}→ %s${NC}\n" "$((i+1))" "$label" "$hint"
  done
  echo ""

  while true; do
    read -rp "  >>> " choice
    if [[ "$choice" =~ ^[0-9]+$ ]] && (( choice >= 1 && choice <= ${#blueprints[@]} )); then
      _blueprint_result="${blueprints[$((choice-1))]}"
      return 0
    fi
    print_error "$MSG_MENU_AREA_ERR${#blueprints[@]}."
  done
}

# -----------------------------------------------------------------------------
# select_git_mode
#
# Asks the user how to manage the repository.
# Saves the choice in the global variable GIT_MODE.
# -----------------------------------------------------------------------------
select_git_mode() {
  print_section "$MSG_MENU_GIT_TITLE"

  echo -e "  ${WHITE}1)${NC} $MSG_MENU_GIT_LOCAL"
  echo -e "  ${WHITE}2)${NC} $MSG_MENU_GIT_PRIVATE"
  echo -e "  ${WHITE}3)${NC} $MSG_MENU_GIT_PUBLIC"
  echo ""

  while true; do
    read -rp "  >>> " git_choice
    case "$git_choice" in
      1) GIT_MODE="local";   break ;;
      2) GIT_MODE="private"; break ;;
      3) GIT_MODE="public";  break ;;
      *) print_warning "$MSG_MENU_GIT_ERR" ;;
      esac
  done
}

# -----------------------------------------------------------------------------
# confirm_creation
#
# Shows the confirmation prompt (y/n).
# Returns 0 if confirmed, exits with code 0 if cancelled.
# -----------------------------------------------------------------------------
confirm_creation() {
  while true; do
    read -rp "  ${MSG_CONFIRM_PROMPT}" confirm
    case "$confirm" in
      s|S) return 0 ;;
      n|N)
        echo -e "\n  ${MSG_CONFIRM_CANCEL}"
        exit 0
        ;;
      *) print_warning "$MSG_CONFIRM_ERR" ;;
    esac
  done
}
