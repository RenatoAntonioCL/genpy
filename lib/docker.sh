#!/usr/bin/env bash
set -euo pipefail

# =============================================================================
# GenPy — lib/docker.sh (v1.0.0-alpha)
#
# Docker health diagnostics and port analysis.
#
# Change v1.0.0-alpha: inspect_blueprint_ports no longer has hardcoded ports.
# It reads them from BLUEPRINT_META[blueprint.ports] in core/config.sh.
# =============================================================================

source "${LIB_DIR:?}/utils.sh"

check_docker_daemon() {
  if ! command -v docker &>/dev/null; then
    print_warning "Docker CLI not installed. Diagnostics skipped."
    return 1
  fi
  if ! docker info &>/dev/null; then
    print_warning "Docker Desktop is off or daemon is inactive."
    return 1
  fi
  return 0
}

inspect_blueprint_ports() {
  local blueprint="$1"
  local project_dir="${2:-}"

  local ports_string
  ports_string=$(blueprint_meta "$blueprint" "ports")

  if [[ -z "$ports_string" || "$ports_string" == "Sin puertos"* ]]; then
    return 0
  fi

  local -a target_ports
  while IFS= read -r num; do
    target_ports+=("$num")
  done < <(echo "$ports_string" | grep -oE '[0-9]{2,5}')

  local conflict_found=0
  local compose_file=""
  [[ -n "$project_dir" ]] && compose_file="$project_dir/docker-compose.yml"

  for port in "${target_ports[@]}"; do
    if _port_in_use "$port"; then
      local free_port
      free_port=$(_find_free_port "$(( port + 1 ))")
      if [[ "$free_port" == "0" ]]; then
        echo -e "   🚨 \033[1;31mCollision:\033[0m Port \033[1;33m$port\033[0m occupied (no free port available)."
        conflict_found=1
        continue
      fi

      echo -e "   🔀 \033[1;33mPort $port occupied\033[0m → remapped to \033[1;32m$free_port\033[0m"

      if [[ -n "$compose_file" && -f "$compose_file" ]]; then
        local tmpfile
        tmpfile=$(mktemp)
        sed "s|127\.0\.0\.1:${port}:|127.0.0.1:${free_port}:|g" "$compose_file" > "$tmpfile" \
          && mv "$tmpfile" "$compose_file" \
          || rm -f "$tmpfile"
        echo -e "   ✅ \033[1;32mdocker-compose.yml updated\033[0m (host: $free_port → container: $port)"
      fi

      conflict_found=1
    fi
  done

  if [[ "$conflict_found" -eq 0 ]]; then
    echo -e "   🛡️  \033[1;32mFree Ports:\033[0m All clear for deployment."
  fi
}
