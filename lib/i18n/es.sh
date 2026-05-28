#!/usr/bin/env bash

# Wizard - Pasos e Identificación [3, 4]
export MSG_STEP1_TITLE="Identificación del Proyecto"
export MSG_PROJECT_NAME_PROMPT="  📛 Nombre del proyecto: "
export MSG_ERR_NAME_REQ="El nombre es obligatorio."
export MSG_ERR_NAME_INVALID="Solo se permiten letras, números, guiones y guiones bajos. No puede empezar con guion."
export MSG_ERR_DIR_EXISTS="Ya existe un directorio con ese nombre: "
export MSG_ERR_PREFLIGHT="El sistema no cumple los requisitos mínimos para continuar."

# Wizard - Fabricación y Diagnóstico [3, 4]
export MSG_STEP6_TITLE="Fabricando Proyecto"
export MSG_STEP7_TITLE="Diagnóstico de Entorno"
export MSG_DOCKER_OFF="Inicia Docker Desktop para poder ejecutar docker compose up."
export MSG_FINISH_SUCCESS="Proyecto creado correctamente."
export MSG_FINISH_STEPS="   ${WHITE}Próximos pasos:${NC}"

# UI Menus (menus.sh) [1, 4]
export MSG_MENU_AREA_TITLE="Área de Enfoque Tecnológico"
export MSG_MENU_AREA_ERR="Elige entre 1 y "
export MSG_MENU_BP_SUFFIX=" — Elige tu Stack"
export MSG_MENU_GIT_TITLE="Control de Versiones (Git)"
export MSG_MENU_GIT_LOCAL="💻  Solo local         ${DIM}— git init sin remoto${NC}"
export MSG_MENU_GIT_PRIVATE="🔐  Remoto privado      ${DIM}— push a repo privado en GitHub${NC}"
export MSG_MENU_GIT_PUBLIC="🌐  Remoto público      ${DIM}— push a repo público en GitHub${NC}"
export MSG_MENU_GIT_ERR="Elige 1, 2 o 3."

# UI Card (card.sh) [2, 4]
export MSG_CARD_TITLE="RESUMEN DEL PROYECTO"
export MSG_CARD_PROJECT="Proyecto:"
export MSG_CARD_BLUEPRINT="Blueprint:"
export MSG_CARD_DESC="Descripción:"
export MSG_CARD_STACK="Stack:"
export MSG_CARD_LIBS="Librerías:"
export MSG_CARD_PORTS="Puertos:"
export MSG_CARD_GIT="Git:"

# Confirmación [1, 4]
export MSG_CONFIRM_PROMPT="Confirmas la creación del proyecto? (s/n): "
export MSG_CONFIRM_CANCEL="    ${YELLOW}Operación cancelada.${NC}"
export MSG_CONFIRM_ERR="Responde s (sí) o n (no)."