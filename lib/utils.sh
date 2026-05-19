#!/opt/homebrew/bin/bash
set -euo pipefail

# =============================================================================
# GenPy — lib/utils.sh (v4.1.0)
#
# Utilidades de UI: paleta de colores, funciones de impresión,
# separadores, tarjeta de resumen y banner.
#
# Todos los módulos deben importar este archivo primero ya que
# print_success, print_error y print_warning son usadas globalmente.
# =============================================================================

# ─── Paleta de colores ────────────────────────────────────────────────────────

MAGENTA='\033[38;2;255;0;255m'       # Magenta neón — acentos
MAGENTA_BG='\033[48;2;255;0;255m'    # Fondo magenta — errores
CYAN='\033[38;2;0;255;255m'          # Cian neón — éxito y títulos
YELLOW='\033[1;33m'                  # Amarillo — advertencias
GREEN='\033[1;32m'                   # Verde — comandos y confirmaciones
WHITE='\033[1;37m'                   # Blanco brillante
DIM='\033[2m'                        # Texto tenue — descripciones
NC='\033[0m'                         # Reset

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

# ─── Tarjeta de resumen ───────────────────────────────────────────────────────

# print_blueprint_card
#
# Muestra un resumen visual completo del proyecto antes de confirmar.
# Incluye descripción, stack, librerías, puertos y modo git.
#
# Argumentos:
#   $1 — project_name
#   $2 — blueprint
#   $3 — git_mode: "local" | "private" | "public"
print_blueprint_card() {
  local project_name="$1"
  local blueprint="$2"
  local git_mode="$3"

  local description="" stack="" libs="" ports=""

  case "$blueprint" in
    "web-fastapi-postgres")
      description="API REST con base de datos relacional"
      stack="Python 3.11  FastAPI  PostgreSQL 15  SQLAlchemy 2"
      libs="uvicorn, pydantic, alembic, psycopg2-binary"
      ports="8000 (API)   5432 (PostgreSQL)"
      ;;
    "web-node-nest-mongo")
      description="API REST con base de datos documental"
      stack="Node 20  NestJS  TypeScript  MongoDB 7  Mongoose"
      libs="@nestjs/core, class-validator, class-transformer"
      ports="3000 (API)   27017 (MongoDB)"
      ;;
    "web-go-gin-clean")
      description="API REST con arquitectura limpia"
      stack="Go 1.21  Gin  MySQL 8  GORM"
      libs="gin-gonic, gorm, godotenv"
      ports="8080 (API)   3306 (MySQL)"
      ;;
    "ai-ml-pytorch")
      description="Entorno de machine learning con notebooks"
      stack="Python 3.11  PyTorch 2.3  Jupyter Lab"
      libs="torch, torchvision, numpy, pandas, scikit-learn, matplotlib"
      ports="8888 (Jupyter Lab)"
      ;;
    "ai-llm-rag")
      description="Pipeline de recuperación aumentada con LLMs"
      stack="Python 3.11  LangChain  ChromaDB  OpenAI"
      libs="langchain, chromadb, openai, tiktoken, python-dotenv"
      ports="Sin puertos — pipeline batch"
      ;;
    "cyber-attacker-kali")
      description="Entorno ofensivo — solo para labs controlados"
      stack="Kali Linux  Python 3  nmap  netcat"
      libs="scapy, requests (scripts personalizados)"
      ports="Sin puertos expuestos"
      ;;
    "cyber-lab-victim-win7")
      description="Máquina víctima simulada — solo para labs controlados"
      stack="Docker Wine  Windows 7 simulado"
      libs="N/A"
      ports="Red interna (lab-network)"
      ;;
    "infra-local-cluster")
      description="Cluster local con reverse proxy y SSL"
      stack="Traefik v3  Docker Compose"
      libs="N/A"
      ports="80 (HTTP)   443 (HTTPS)   8080 (Dashboard)"
      ;;
    "infra-monitoring-stack")
      description="Stack de observabilidad completo"
      stack="Prometheus  Grafana  Docker Compose"
      libs="N/A"
      ports="9090 (Prometheus)   3000 (Grafana)"
      ;;
  esac

  local git_label=""
  case "$git_mode" in
    local)   git_label="💻  Solo local" ;;
    private) git_label="🔐  Remoto privado" ;;
    public)  git_label="🌐  Remoto público" ;;
  esac

  echo ""
  echo -e "${CYAN}  ╔═══════════════════════════════════════════════════╗${NC}"
  echo -e "${CYAN}  ║${NC}  ${WHITE}RESUMEN DEL PROYECTO${NC}                               ${CYAN}║${NC}"
  echo -e "${CYAN}  ╠═══════════════════════════════════════════════════╣${NC}"
  printf "${CYAN}  ║${NC}  ${WHITE}%-14s${NC}  %-34s${CYAN}║${NC}\n" "Proyecto:"    "$project_name"
  printf "${CYAN}  ║${NC}  ${WHITE}%-14s${NC}  %-34s${CYAN}║${NC}\n" "Blueprint:"   "$blueprint"
  printf "${CYAN}  ║${NC}  ${WHITE}%-14s${NC}  %-34s${CYAN}║${NC}\n" "Descripción:" "$description"
  echo -e "${CYAN}  ╠═══════════════════════════════════════════════════╣${NC}"
  printf "${CYAN}  ║${NC}  ${WHITE}%-14s${NC}  %-34s${CYAN}║${NC}\n" "Stack:"       "$stack"
  printf "${CYAN}  ║${NC}  ${WHITE}%-14s${NC}  %-34s${CYAN}║${NC}\n" "Librerías:"   "$libs"
  printf "${CYAN}  ║${NC}  ${WHITE}%-14s${NC}  %-34s${CYAN}║${NC}\n" "Puertos:"     "$ports"
  echo -e "${CYAN}  ╠═══════════════════════════════════════════════════╣${NC}"
  printf "${CYAN}  ║${NC}  ${WHITE}%-14s${NC}  %-34s${CYAN}║${NC}\n" "Git:"         "$git_label"
  echo -e "${CYAN}  ╚═══════════════════════════════════════════════════╝${NC}"
  echo ""
}

# ─── Banner ───────────────────────────────────────────────────────────────────

print_banner() {
  clear
  echo -e "\n"
  echo -e "${MAGENTA_BG}${WHITE} ██████  ███████ ███    ██ ██████  ██    ██  ${NC}"
  echo -e "${MAGENTA_BG}${WHITE} ██       ██      ████   ██ ██   ██  ██  ██   ${NC}"
  echo -e "${MAGENTA_BG}${WHITE} ██   ███ █████   ██ ██  ██ ██████    ████    ${NC}"
  echo -e "${MAGENTA_BG}${WHITE} ██    ██ ██      ██  ██ ██ ██         ██     ${NC}"
  echo -e "${MAGENTA_BG}${WHITE}  ██████  ███████ ██   ████ ██         ██     ${NC}${CYAN} v4.1.0${NC}"
  echo -e "${DIM}  ════════════════════════════════════════════════${NC}"
  echo -e "        ${CYAN}UNIVERSAL SOFTWARE FACTORY & SANDBOX${NC}"
  echo -e "${DIM}  ════════════════════════════════════════════════${NC}\n"
}