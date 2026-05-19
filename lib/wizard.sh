#!/opt/homebrew/bin/bash
set -euo pipefail

# =============================================================================
# GenPy — lib/wizard.sh (v4.1.0)
#
# Orquestador principal del flujo interactivo de creación de proyectos.
#
# Flujo:
#   1. Banner + nombre del proyecto
#   2. Selección de git mode (local / privado / público)
#   3. Selección de blueprint con stack visible en cada opción
#   4. Selección de aditivos
#   5. Tarjeta de resumen + confirmación (s/n)
#   6. Fabricación: copy_template → inject_addons → git → diagnóstico Docker
# =============================================================================

source "$LIB_DIR/utils.sh"
source "$LIB_DIR/template.sh"
source "$LIB_DIR/libs.sh"
source "$LIB_DIR/docker.sh"
source "$LIB_DIR/git_manager.sh"

# ─── PASO 1: Banner y nombre del proyecto ────────────────────────────────────

print_banner

print_section "Identificación del Proyecto"
PROJECT_NAME=""
while [[ -z "$PROJECT_NAME" ]]; do
  read -rp "  📛 Nombre del proyecto: " PROJECT_NAME
  [[ -z "$PROJECT_NAME" ]] && print_error "El nombre es obligatorio."
done

PROJECT_DIR="$(pwd)/$PROJECT_NAME"

if [[ -d "$PROJECT_DIR" ]]; then
  print_error "Ya existe un directorio con ese nombre: $PROJECT_DIR"
  exit 1
fi

# ─── PASO 2: Modo Git ────────────────────────────────────────────────────────
# Se pregunta ANTES del blueprint para poder mostrarlo en el resumen final

select_git_mode

# ─── PASO 3: Selección de Blueprint ──────────────────────────────────────────

BLUEPRINT=""
while [[ -z "$BLUEPRINT" ]]; do

  print_section "Área de Enfoque Tecnológico"
  echo -e "  ${WHITE}1) 🌐 Web & APIs${NC}     ${WHITE}2) 🤖 AI Labs${NC}     ${WHITE}3) 💀 Security${NC}     ${WHITE}4) 🛠️  Infra${NC}\n"
  read -rp "  >>> " area_choice

  case "$area_choice" in

    # ── Web & APIs ───────────────────────────────────────────────────────────
    1)
      print_section "Web & APIs — Elige tu Stack"
      echo -e "  ${WHITE}1)${NC} FastAPI + PostgreSQL  ${DIM}→ Python · SQLAlchemy · uvicorn · alembic${NC}"
      echo -e "  ${WHITE}2)${NC} NestJS + MongoDB      ${DIM}→ TypeScript · Mongoose · class-validator${NC}"
      echo -e "  ${WHITE}3)${NC} Go + Gin              ${DIM}→ Go 1.21 · GORM · MySQL · arquitectura limpia${NC}"
      echo ""
      read -rp "  >>> " sub_choice
      case "$sub_choice" in
        1) BLUEPRINT="web-fastapi-postgres" ;;
        2) BLUEPRINT="web-node-nest-mongo"  ;;
        3) BLUEPRINT="web-go-gin-clean"     ;;
        *) print_error "Opción inválida." ; BLUEPRINT="" ;;
      esac
      ;;

    # ── AI Labs ──────────────────────────────────────────────────────────────
    2)
      print_section "AI Labs — Elige tu Entorno"
      echo -e "  ${WHITE}1)${NC} ML / PyTorch          ${DIM}→ PyTorch 2.3 · Jupyter Lab · numpy · scikit-learn${NC}"
      echo -e "  ${WHITE}2)${NC} LLM RAG               ${DIM}→ LangChain · ChromaDB · OpenAI · tiktoken${NC}"
      echo ""
      read -rp "  >>> " sub_choice
      case "$sub_choice" in
        1) BLUEPRINT="ai-ml-pytorch" ;;
        2) BLUEPRINT="ai-llm-rag"    ;;
        *) print_error "Opción inválida." ; BLUEPRINT="" ;;
      esac
      ;;

    # ── Security ─────────────────────────────────────────────────────────────
    3)
      print_section "Security Lab — Solo para entornos controlados"
      echo -e "  ${YELLOW}⚠${NC}  Estos blueprints son exclusivamente para laboratorios"
      echo -e "     con autorización explícita. Uso en redes reales es ilegal.\n"
      echo -e "  ${WHITE}1)${NC} Attacker (Kali)       ${DIM}→ Kali Linux · nmap · netcat · Python 3 · scapy${NC}"
      echo -e "  ${WHITE}2)${NC} Victim  (Win7)        ${DIM}→ Docker Wine · Windows 7 simulado · red aislada${NC}"
      echo ""
      read -rp "  >>> " sub_choice
      case "$sub_choice" in
        1) BLUEPRINT="cyber-attacker-kali"   ;;
        2) BLUEPRINT="cyber-lab-victim-win7" ;;
        *) print_error "Opción inválida." ; BLUEPRINT="" ;;
      esac
      ;;

    # ── Infra ─────────────────────────────────────────────────────────────────
    4)
      print_section "Infraestructura — Elige tu Stack"
      echo -e "  ${WHITE}1)${NC} Cluster Local         ${DIM}→ Traefik v3 · HTTP/HTTPS · Dashboard · Docker Compose${NC}"
      echo -e "  ${WHITE}2)${NC} Monitoring Stack      ${DIM}→ Prometheus · Grafana · métricas y alertas${NC}"
      echo ""
      read -rp "  >>> " sub_choice
      case "$sub_choice" in
        1) BLUEPRINT="infra-local-cluster"    ;;
        2) BLUEPRINT="infra-monitoring-stack" ;;
        *) print_error "Opción inválida." ; BLUEPRINT="" ;;
      esac
      ;;

    *)
      print_error "Elige entre 1 y 4."
      ;;
  esac
done

# ─── PASO 4: Aditivos ────────────────────────────────────────────────────────

declare -a selected_addons=()
select_blueprint_addons selected_addons "$BLUEPRINT"

# ─── PASO 5: Resumen y confirmación ──────────────────────────────────────────

print_blueprint_card "$PROJECT_NAME" "$BLUEPRINT" "$GIT_MODE"

CONFIRMED=false
while [[ "$CONFIRMED" == false ]]; do
  read -rp "  ¿Confirmas la creación del proyecto? (s/n): " confirm
  case "$confirm" in
    s|S) CONFIRMED=true ;;
    n|N)
      echo -e "\n  ${YELLOW}Operación cancelada.${NC}\n"
      exit 0
      ;;
    *) print_warning "Responde s (sí) o n (no)." ;;
  esac
done

# ─── PASO 6: Fabricación ─────────────────────────────────────────────────────

print_section "Fabricando Proyecto"

# Copiar template e inyectar nombre
copy_template "$TEMPLATE_BASE_DIR/$BLUEPRINT" "$PROJECT_DIR" "$PROJECT_NAME"

# Verificar que la carpeta se creó correctamente
if [[ ! -d "$PROJECT_DIR" ]] || [[ -z "$(ls -A "$PROJECT_DIR")" ]]; then
  print_error "La carpeta '$PROJECT_NAME' no se creó correctamente."
  exit 1
fi

# Inyectar aditivos seleccionados
inject_blueprint_addons "$PROJECT_DIR" selected_addons "$BLUEPRINT"

# Git — siempre se inicializa, el modo ya fue elegido en PASO 2
setup_git_repository "$PROJECT_DIR" "$PROJECT_NAME"

# ─── PASO 7: Diagnóstico Docker ──────────────────────────────────────────────

print_section "Diagnóstico de Entorno"
if check_docker_daemon; then
  inspect_blueprint_ports "$BLUEPRINT"
else
  print_info "Inicia Docker Desktop para poder ejecutar docker compose up."
fi

# ─── RESUMEN FINAL ───────────────────────────────────────────────────────────

echo ""
print_line
print_success "Proyecto ${WHITE}$PROJECT_NAME${NC} creado en: ${DIM}$PROJECT_DIR${NC}"
echo ""
echo -e "  ${WHITE}Próximos pasos:${NC}"
echo -e "  ${GREEN}cd $PROJECT_NAME${NC}"
echo -e "  ${GREEN}docker compose up -d${NC}"
echo ""
print_line
echo ""