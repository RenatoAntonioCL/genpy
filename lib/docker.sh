#!/usr/bin/env bash
set -euo pipefail

# =============================================================================
# GenPy — lib/docker.sh (v1.0.0-alpha)
#
# Diagnóstico de salud Docker y análisis de puertos.
#
# Cambio v1.0.0-alpha: inspect_blueprint_ports ya no tiene puertos hardcodeados.
# Los lee desde BLUEPRINT_META[blueprint.ports] en core/config.sh.
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

  # Leer puertos desde config.sh en lugar de un case hardcodeado
  local ports_string
  ports_string=$(blueprint_meta "$blueprint" "ports")

  # Si no hay puertos definidos o es un blueprint sin red, salir
  if [[ -z "$ports_string" || "$ports_string" == "Sin puertos"* ]]; then
    return 0
  fi

  # Extraer solo los números de puerto del string (ej: "8000 (API)   5432 (PostgreSQL)")
  local -a target_ports
  while IFS= read -r num; do
    target_ports+=("$num")
    done < <(echo "$ports_string" | grep -oE '[0-9]{2,5}')

  local conflict_found=0

  for port in "${target_ports[@]}"; do
    # ✅ Usa el "shim" de compat.sh que detecta ss, netstat o usa /dev/tcp
    if _port_in_use "$port"; then
      echo -e "   🚨 \033[1;31mColisión Detectada:\033[0m Puerto \033[1;33m$port\033[0m ocupado."
      conflict_found=1
    fi
  done

  if [[ "$conflict_found" -eq 1 ]]; then
    echo -e "   💡 \033[1;36mTip:\033[0m Apaga los servicios locales antes de ejecutar el build.\n"
  else
    echo -e "   🛡️  \033[1;32mPuertos Libres:\033[0m Todo despejado para el despliegue."
  fi
}