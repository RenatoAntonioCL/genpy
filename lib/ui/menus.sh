#!/usr/bin/env bash
set -euo pipefail
# =============================================================================
# GenPy — lib/ui/menus.sh (v5.0.0)
#
# Menús interactivos del wizard.
# Extraído de wizard.sh para separar UI de orquestación.
#
# Antes: wizard.sh tenía los menús de área y blueprint hardcodeados
#        con case statements anidados y strings duplicados.
# Ahora: los menús se generan dinámicamente desde AREAS, AREA_BLUEPRINTS
#        y BLUEPRINT_META en config.sh.
# =============================================================================

# -----------------------------------------------------------------------------
# select_area
#
# Muestra el menú de áreas y retorna el ID elegido en la variable
# pasada por nombre.
#
# Uso:
#   select_area area_id
# -----------------------------------------------------------------------------
select_area() {
  local -n _area_result="$1"

  print_section "$MSG_MENU_AREA_TITLE"

  # Generar menú dinámicamente desde AREAS (definido en config.sh)
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
# Muestra el submenú de blueprints para el área elegida y retorna
# el nombre del blueprint en la variable pasada por nombre.
#
# Si el área tiene advertencia de seguridad (SECURITY_AREA_ID), la muestra.
#
# Uso:
#   select_blueprint "$area_id" blueprint_name
# -----------------------------------------------------------------------------
select_blueprint() {
  local area_id="$1"
  local -n _blueprint_result="$2"

  local area_name="${AREAS[$area_id]}"
print_section "${area_name}${MSG_MENU_BP_SUFFIX}"
  # Mostrar advertencia si es el área de seguridad
  if [[ "$area_id" == "$SECURITY_AREA_ID" ]]; then
    echo -e "  ${YELLOW}⚠${NC}  $SECURITY_WARNING\n"
  fi

  # Obtener blueprints del área como array
  local -a blueprints
  read -ra blueprints <<< "${AREA_BLUEPRINTS[$area_id]}"

  # Generar menú dinámicamente desde BLUEPRINT_META
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
# Pregunta al usuario cómo gestionar el repositorio.
# Guarda la elección en la variable global GIT_MODE.
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
# Muestra el prompt de confirmación (s/n).
# Retorna 0 si confirmó, sale con código 0 si canceló.
# -----------------------------------------------------------------------------
confirm_creation() {
  while true; do
    read -rp "  ¿${MSG_CONFIRM_PROMPT}" confirm
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