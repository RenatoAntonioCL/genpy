#!/opt/homebrew/bin/bash
set -euo pipefail

# =============================================================================
# GenPy — lib/docker.sh (v4.0.0)
# Diagnóstico de salud Docker y análisis de puertos.
# =============================================================================

check_docker_daemon() {
  if ! command -v docker &>/dev/null; then
    print_warning "Docker CLI no instalado. Diagnósticos saltados."
    return 1
  fi
  if ! docker info &>/dev/null; then
    print_warning "Docker Desktop apagado o demonio inactivo."
    return 1
  fi
  return 0
}

inspect_blueprint_ports() {
  local blueprint="$1"
  local -a target_ports=()

  case "$blueprint" in
    "web-fastapi-postgres") target_ports=(8000 5432) ;;
    "web-node-nest-mongo")  target_ports=(3000 27017) ;;
    "web-go-gin-clean")     target_ports=(8080 3306) ;;
    "infra-local-cluster")  target_ports=(80 443 8080) ;;
    "infra-monitoring-stack") target_ports=(9090 3000) ;;
    *) return 0 ;;
  esac

  local conflict_found=0
  for port in "${target_ports[@]}"; do
    if lsof -Pi :"$port" -sTCP:LISTEN -t &>/dev/null; then
      echo -e "   🚨 \033[1;31mColisión Detectada:\033[0m El puerto \033[1;33m$port\033[0m está ocupado."
      conflict_found=1
    fi
  done

  if [ "$conflict_found" -eq 1 ]; then
    echo -e "   💡 \033[1;36mTip:\033[0m Apaga los servicios locales antes de ejecutar el build.\n"
  else
    echo -e "   🛡️  \033[1;32mPuertos Libres:\033[0m Todo despejado para el despliegue."
  fi
}