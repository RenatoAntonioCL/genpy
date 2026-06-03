#!/usr/bin/env bash
# =============================================================================
# GenPy — lib/wizard.sh (v1.0.0-alpha)
#
# Main orchestrator for the project creation flow.
# Single responsibility: coordinate steps in order, without UI logic
# or hardcoded domain data.
#
# Flow:
#   1. Banner + project name
#   2. Git mode
#   3. Area → blueprint selection (delegated to ui/menus.sh)
#   4. Add-on selection (delegated to libs.sh)
#   5. Summary card + confirmation (delegated to ui/card.sh)
#   6. Build: copy_template → inject_addons → git → Docker diagnostics
# =============================================================================

source "$LIB_DIR/core/config.sh"
source "$LIB_DIR/core/errors.sh"
source "$LIB_DIR/utils.sh"
source "$LIB_DIR/ui/banner.sh"
source "$LIB_DIR/ui/card.sh"
source "$LIB_DIR/ui/menus.sh"
source "$LIB_DIR/template.sh"
source "$LIB_DIR/libs.sh"
source "$LIB_DIR/docker.sh"
source "$LIB_DIR/git_manager.sh"

# ─── STEP 1: Banner and project name ─────────────────────────────────────────

print_banner

print_section "$MSG_STEP1_TITLE"
PROJECT_NAME=""
while true; do
  read -rp "  $MSG_PROJECT_NAME_PROMPT" PROJECT_NAME
  if [[ -z "$PROJECT_NAME" ]]; then
    print_error "$MSG_ERR_NAME_REQ"
  elif [[ ! "$PROJECT_NAME" =~ ^[a-zA-Z0-9][a-zA-Z0-9_-]*$ ]]; then
    print_error "$MSG_ERR_NAME_INVALID"
    PROJECT_NAME=""
  else
    break
  fi
done

PROJECT_DIR="$(pwd)/$PROJECT_NAME"

# Preflight invocation (new)
source "$LIB_DIR/core/preflight.sh"
if ! preflight_mode_create; then
    die "$MSG_ERR_PREFLIGHT"
fi

if [[ -d "$PROJECT_DIR" ]]; then
  die "$MSG_ERR_DIR_EXISTS$PROJECT_DIR"
fi

# Register for automatic cleanup on error (see core/errors.sh)
GENPY_CLEANUP_DIR="$PROJECT_DIR"

# ─── STEP 2: Git Mode ────────────────────────────────────────────────────────


GIT_MODE="local"
select_git_mode

# ─── STEP 3: Blueprint Selection ─────────────────────────────────────────────

BLUEPRINT=""
while [[ -z "$BLUEPRINT" ]]; do
  AREA_ID=""
  select_area AREA_ID
  select_blueprint "$AREA_ID" BLUEPRINT
done

# ─── STEP 4: Add-ons ─────────────────────────────────────────────────────────

declare -a selected_addons=()
select_blueprint_addons selected_addons "$BLUEPRINT"

# ─── STEP 5: Summary and confirmation ────────────────────────────────────────

print_blueprint_card "$PROJECT_NAME" "$BLUEPRINT" "$GIT_MODE"
confirm_creation

# ─── STEP 6: Build ───────────────────────────────────────────────────────────

print_section "$MSG_STEP6_TITLE"


# Define TEMPLATE_BASE_DIR if not defined by source files
: "${TEMPLATE_BASE_DIR:="$(dirname "$LIB_DIR")/templates"}"

copy_template "$TEMPLATE_BASE_DIR/$BLUEPRINT" "$PROJECT_DIR" "$PROJECT_NAME"


if [[ ! -d "$PROJECT_DIR" ]] || [[ -z "$(ls -A "$PROJECT_DIR")" ]]; then
  die "Directory '$PROJECT_NAME' was not created correctly."
fi


inject_blueprint_addons "$PROJECT_DIR" selected_addons "$BLUEPRINT"


setup_git_repository "$PROJECT_DIR" "$PROJECT_NAME"

# ─── STEP 7: Docker Diagnostics ──────────────────────────────────────────────

print_section "$MSG_STEP7_TITLE"
if check_docker_daemon; then
  inspect_blueprint_ports "$BLUEPRINT" "$PROJECT_DIR"
else
  print_info "Start Docker Desktop to run docker compose up."
fi

# ─── FINAL SUMMARY ───────────────────────────────────────────────────────────

# Project created OK — disable automatic cleanup
GENPY_CLEANUP_DIR=""

echo ""
print_line
print_success "Project ${WHITE}$PROJECT_NAME${NC} created at: ${DIM}$PROJECT_DIR${NC}"
echo ""
echo -e "  ${WHITE}Next steps:${NC}"
echo -e "  ${GREEN}cd $PROJECT_NAME && docker compose up -d ${NC}"
echo ""
print_line
echo ""
