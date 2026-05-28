#!/usr/bin/env bash

# Wizard - Steps & Identification [3, 6]
export MSG_STEP1_TITLE="Project Identification"
export MSG_PROJECT_NAME_PROMPT="  📛 Project name: "
export MSG_ERR_NAME_REQ="Project name is required."
export MSG_ERR_NAME_INVALID="Only letters, numbers, hyphens, and underscores are allowed. Cannot start with a hyphen."
export MSG_ERR_DIR_EXISTS="A directory with that name already exists: "
export MSG_ERR_PREFLIGHT="The system does not meet the minimum requirements to proceed."

# Wizard - Manufacturing & Diagnosis [3, 6]
export MSG_STEP6_TITLE="Manufacturing Project"
export MSG_STEP7_TITLE="Environment Diagnosis"
export MSG_DOCKER_OFF="Start Docker Desktop to run docker compose up."
export MSG_FINISH_SUCCESS="Project successfully created."
export MSG_FINISH_STEPS="   ${WHITE}Next steps:${NC}"

# UI Menus (menus.sh) [1, 6]
export MSG_MENU_AREA_TITLE="Technology Focus Area"
export MSG_MENU_AREA_ERR="Choose between 1 and "
export MSG_MENU_BP_SUFFIX=" — Choose your Stack"
export MSG_MENU_GIT_TITLE="Version Control (Git)"
export MSG_MENU_GIT_LOCAL="💻  Local only         ${DIM}— git init without remote${NC}"
export MSG_MENU_GIT_PRIVATE="🔐  Private remote      ${DIM}— push to private GitHub repo${NC}"
export MSG_MENU_GIT_PUBLIC="🌐  Public remote       ${DIM}— push to public GitHub repo${NC}"
export MSG_MENU_GIT_ERR="Choose 1, 2, or 3."

# UI Card (card.sh) [2, 6]
export MSG_CARD_TITLE="PROJECT SUMMARY"
export MSG_CARD_PROJECT="Project:"
export MSG_CARD_BLUEPRINT="Blueprint:"
export MSG_CARD_DESC="Description:"
export MSG_CARD_STACK="Stack:"
export MSG_CARD_LIBS="Libraries:"
export MSG_CARD_PORTS="Ports:"
export MSG_CARD_GIT="Git:"

# Confirmation [1]
export MSG_CONFIRM_PROMPT="Confirm project creation? (y/n): "
export MSG_CONFIRM_CANCEL="    ${YELLOW}Operation cancelled.${NC}"
export MSG_CONFIRM_ERR="Please answer y (yes) or n (no)."