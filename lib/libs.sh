#!/usr/bin/env bash
# =============================================================================
# GenPy — lib/libs.sh (v1.0.0-alpha)
#
# Motor de selección e inyección de aditivos.

source "${LIB_DIR:?}/utils.sh"
#
# Cambios respecto a v4:
#   - Los diccionarios ADDONS_* hardcodeados fueron eliminados.
#     Ahora los datos viven en ADDON_PACKAGES, ADDON_LABELS y ADDON_INDEX
#     en core/config.sh.
#   - Los keys son IDs semánticos ("jwt", "tasks") en lugar de
#     paquetes reales ("passlib python-jose"), separando presentación
#     de instalación.
#   - _sed_inplace movida a template.sh donde se usa.
# =============================================================================
# 
# -----------------------------------------------------------------------------
# select_blueprint_addons
#
# Muestra el menú de aditivos para el blueprint dado y guarda
# los IDs seleccionados en el array del llamador.
#
# Argumentos:
#   $1 — nombre del array destino (nameref)
#   $2 — blueprint
# -----------------------------------------------------------------------------
select_blueprint_addons() {
  local -n _dest_array="$1"
  local blueprint="$2"

  # Si el blueprint no tiene aditivos, salir silenciosamente
  local addon_ids="${ADDON_INDEX[$blueprint]:-}"
  [[ -z "$addon_ids" ]] && return 0

  echo -e "\n⚡ ¿Deseas añadir aditivos a tu proyecto?"

  # Construir array ordenado de IDs
  local -a ids
  read -ra ids <<< "$addon_ids"
 for i in "${!ids[@]}"; do
    local id="${ids[$i]}"
    local label="${ADDON_LABELS[${blueprint}.${id}]:-$id}"
    printf "  %d) %s\n" "$((i+1))" "$label"
  done
  echo "  0) Ninguno"

  read -rp "👉 Selecciona (ej: 1 2): " input

  for item in $input; do

    if [[ "$item" == "0" ]]; then
      break
    elif [[ "$item" =~ ^[0-9]+$ ]] && (( item >= 1 && item <= ${#ids[@]} )); then
      # Guardar el ID semántico, no el número del menú
      _dest_array+=("${ids[$((item-1))]}")
    else
      print_warning "Opción '$item' fuera de rango — ignorada"
    fi
  done
}

# ─── Inyectores internos ──────────────────────────────────────────────────────





_inject_python_addons() {
  local target_dir="$1"
  local packages="$2"

  local req_file="$target_dir/backend/requirements.txt"
  [[ ! -f "$req_file" ]] && req_file="$target_dir/requirements.txt"

  # Elimina líneas que contengan comandos de Docker o basura
  if [[ -f "$req_file" ]]; then
    for pattern in '/^FROM/d' '/^WORKDIR/d' '/^COPY/d' '/^RUN/d' '/^CMD/d'; do
      _sed_inplace "$pattern" "$req_file"
    done
  fi

  if [[ ! -f "$req_file" ]]; then
    print_warning "No se encontró requirements.txt — omitiendo: $packages"
    return 0
  fi

  for pkg in $packages; do
    grep -q "^${pkg%% *}" "$req_file" || echo "$pkg" >> "$req_file"
  done
}


_inject_node_addons() {
  local target_dir="$1"
  local packages="$2"

  local pkg_file="$target_dir/backend/package.json"
  [[ ! -f "$pkg_file" ]] && pkg_file="$target_dir/package.json"

  if [[ ! -f "$pkg_file" ]]; then
    print_warning "No se encontró package.json — omitiendo: $packages"
    return 0
  fi

  for pkg in $packages; do
    jq --arg pkg "$pkg" \
       '.dependencies[$pkg] = "latest"' "$pkg_file" > "$pkg_file.tmp" \
       && mv "$pkg_file.tmp" "$pkg_file"
  done
}


_inject_go_addons() {
  local target_dir="$1"
  local packages="$2"

  local go_mod="$target_dir/backend/go.mod"
  [[ ! -f "$go_mod" ]] && go_mod="$target_dir/go.mod"

  if [[ ! -f "$go_mod" ]]; then
    print_warning "No se encontró go.mod — omitiendo: $packages"
    return 0
  fi

  if ! command -v go &>/dev/null; then
    print_warning "Go no instalado — registrando en .genpy_go_deps"
    printf "%s\n" $packages > "$target_dir/.genpy_go_deps"
    return 0
  fi

  local mod_dir
  mod_dir="$(dirname "$go_mod")"

  for pkg in $packages; do
    (cd "$mod_dir" && go get "$pkg" 2>/dev/null) || \
      print_warning "No se pudo instalar $pkg — agrégalo con: go get $pkg"
  done
}



# -----------------------------------------------------------------------------
# inject_blueprint_addons
#
# Inyecta los aditivos seleccionados en los archivos de dependencias.
#
# Argumentos:
#   $1 — target_dir
#   $2 — nombre del array con IDs de aditivos seleccionados (nameref)
#   $3 — blueprint
# -----------------------------------------------------------------------------
inject_blueprint_addons() {
  local target_dir="$1"
  local -n _addons_ref="$2"
  local blueprint="$3"

  [[ ${#_addons_ref[@]} -eq 0 ]] && return 0

  echo -e "\n💉 Inyectando aditivos..."

  local lang
  lang=$(blueprint_meta "$blueprint" "lang")

  for addon_id in "${_addons_ref[@]}"; do
    # Resolver paquetes reales desde config.sh
    local packages="${ADDON_PACKAGES[${blueprint}.${addon_id}]:-}"

    if [[ -z "$packages" ]]; then
      print_warning "Aditivo '$addon_id' no tiene paquetes definidos — omitido"
      continue
    fi
    echo "   + $packages"

    case "$lang" in
      python) _inject_python_addons "$target_dir" "$packages" ;;
      node)   _inject_node_addons   "$target_dir" "$packages" ;;
      go)     _inject_go_addons     "$target_dir" "$packages" ;;
    esac
  done

  print_success "Aditivos inyectados correctamente."
}

