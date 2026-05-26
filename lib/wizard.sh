#!/usr/bin/env bash
# =============================================================================
# GenPy — lib/wizard.sh (v1.0.0-alpha)
#
# Orquestador principal del flujo de creación de proyectos.
# Responsabilidad única: coordinar pasos en orden, sin lógica de UI
# ni datos de dominio hardcodeados.
#
# Flujo:
#   1. Banner + nombre del proyecto
#   2. Modo git
#   3. Selección de área → blueprint (delegado a ui/menus.sh)
#   4. Selección de aditivos (delegado a libs.sh)
#   5. Tarjeta de resumen + confirmación (delegado a ui/card.sh)
#   6. Fabricación: copy_template → inject_addons → git → diagnóstico Docker
# =============================================================================

# source "$LIB_DIR/core/config.sh"
source "$LIB_DIR/core/errors.sh"
source "$LIB_DIR/utils.sh"
source "$LIB_DIR/ui/banner.sh"
source "$LIB_DIR/ui/card.sh"
source "$LIB_DIR/ui/menus.sh"
source "$LIB_DIR/template.sh"
source "$LIB_DIR/libs.sh"
source "$LIB_DIR/docker.sh"
source "$LIB_DIR/git_manager.sh"

# ─── PASO 1: Banner y nombre del proyecto ────────────────────────────────────

print_banner

print_section "$MSG_STEP1_TITLE"
PROJECT_NAME=""
while [[ -z "$PROJECT_NAME" ]]; do
  read -rp "  $MSG_PROJECT_NAME_PROMPT" PROJECT_NAME
  [[ -z "$PROJECT_NAME" ]] && print_error "$MSG_ERR_NAME_REQ"
done

PROJECT_DIR="$(pwd)/$PROJECT_NAME"

# Invocación de Preflight (Nuevo)
source "$LIB_DIR/core/preflight.sh"
if ! preflight_mode_create; then
    die "$MSG_ERR_PREFLIGHT"
fi

if [[ -d "$PROJECT_DIR" ]]; then
  die "$MSG_ERR_DIR_EXISTS$PROJECT_DIR"
fi

# Registrar para limpieza automática en caso de error (ver core/errors.sh)
GENPY_CLEANUP_DIR="$PROJECT_DIR"

# ─── PASO 2: Modo Git ────────────────────────────────────────────────────────


GIT_MODE="local"
select_git_mode

# ─── PASO 3: Selección de Blueprint ──────────────────────────────────────────

BLUEPRINT=""
while [[ -z "$BLUEPRINT" ]]; do
  AREA_ID=""
  select_area AREA_ID
  select_blueprint "$AREA_ID" BLUEPRINT
done

# ─── PASO 4: Aditivos ────────────────────────────────────────────────────────

declare -a selected_addons=()
select_blueprint_addons selected_addons "$BLUEPRINT"

# ─── PASO 5: Resumen y confirmación ──────────────────────────────────────────

print_blueprint_card "$PROJECT_NAME" "$BLUEPRINT" "$GIT_MODE"
confirm_creation

# ─── PASO 6: Fabricación ─────────────────────────────────────────────────────

print_section "$MSG_STEP6_TITLE"


# Definir TEMPLATE_BASE_DIR si no está definido por los archivos fuente
: "${TEMPLATE_BASE_DIR:="$(dirname "$LIB_DIR")/templates"}"

copy_template "$TEMPLATE_BASE_DIR/$BLUEPRINT" "$PROJECT_DIR" "$PROJECT_NAME"


if [[ ! -d "$PROJECT_DIR" ]] || [[ -z "$(ls -A "$PROJECT_DIR")" ]]; then
  die "La carpeta '$PROJECT_NAME' no se creó correctamente."
fi


inject_blueprint_addons "$PROJECT_DIR" selected_addons "$BLUEPRINT"


setup_git_repository "$PROJECT_DIR" "$PROJECT_NAME"

# ─── PASO 7: Diagnóstico Docker ──────────────────────────────────────────────

print_section "$MSG_STEP7_TITLE"
if check_docker_daemon; then
  inspect_blueprint_ports "$BLUEPRINT"
else
  print_info "Inicia Docker Desktop para poder ejecutar docker compose up."
fi

# ─── RESUMEN FINAL ───────────────────────────────────────────────────────────

# Proyecto creado OK — desactivar limpieza automática
GENPY_CLEANUP_DIR=""

echo ""
print_line
print_success "Proyecto ${WHITE}$PROJECT_NAME${NC} creado en: ${DIM}$PROJECT_DIR${NC}"
echo ""
echo -e "  ${WHITE}Próximos pasos:${NC}"
echo -e "  ${GREEN}cd $PROJECT_NAME && docker compose up -d ${NC}"
echo ""
print_line
echo ""