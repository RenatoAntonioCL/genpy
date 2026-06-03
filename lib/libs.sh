#!/usr/bin/env bash
# =============================================================================
# GenPy — lib/libs.sh (v1.0.0-alpha)
#
# Add-on selection and injection engine.

source "${LIB_DIR:?}/utils.sh"
#
# Changes from v4:
#   - Hardcoded ADDONS_* dictionaries were removed.
#     Data now lives in ADDON_PACKAGES, ADDON_LABELS and ADDON_INDEX
#     in core/config.sh.
#   - Keys are semantic IDs ("jwt", "tasks") instead of
#     real packages ("passlib python-jose"), separating presentation
#     from installation.
#   - _sed_inplace moved to template.sh where it is used.
# =============================================================================
#
# -----------------------------------------------------------------------------
# select_blueprint_addons
#
# Shows the add-on menu for the given blueprint and saves
# the selected IDs in the caller's array.
#
# Arguments:
#   $1 — target array name (nameref)
#   $2 — blueprint
# -----------------------------------------------------------------------------
select_blueprint_addons() {
  local -n _dest_array="$1"
  local blueprint="$2"

  # If the blueprint has no add-ons, exit silently
  local addon_ids="${ADDON_INDEX[$blueprint]:-}"
  [[ -z "$addon_ids" ]] && return 0

  echo -e "\n⚡ Do you want to add add-ons to your project?"

  # Build ordered array of IDs
  local -a ids
  read -ra ids <<< "$addon_ids"
 for i in "${!ids[@]}"; do
    local id="${ids[$i]}"
    local label="${ADDON_LABELS[${blueprint}.${id}]:-$id}"
    printf "  %d) %s\n" "$((i+1))" "$label"
  done
  echo "  0) None"

  read -rp "👉 Select (e.g.: 1 2): " input

  for item in $input; do

    if [[ "$item" == "0" ]]; then
      break
    elif [[ "$item" =~ ^[0-9]+$ ]] && (( item >= 1 && item <= ${#ids[@]} )); then
      # Save the semantic ID, not the menu number
      _dest_array+=("${ids[$((item-1))]}")
    else
      print_warning "Option '$item' out of range — ignored"
    fi
  done
}

# ─── Internal injectors ───────────────────────────────────────────────────────




_inject_python_addons() {
  local target_dir="$1"
  local packages="$2"

  local req_file="$target_dir/backend/requirements.txt"
  [[ ! -f "$req_file" ]] && req_file="$target_dir/requirements.txt"

  # Remove lines containing Docker commands or garbage
  if [[ -f "$req_file" ]]; then
    for pattern in '/^FROM/d' '/^WORKDIR/d' '/^COPY/d' '/^RUN/d' '/^CMD/d'; do
      _sed_inplace "$pattern" "$req_file"
    done
  fi

  if [[ ! -f "$req_file" ]]; then
    print_warning "requirements.txt not found — skipping: $packages"
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
    print_warning "package.json not found — skipping: $packages"
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
    print_warning "go.mod not found — skipping: $packages"
    return 0
  fi

  if ! command -v go &>/dev/null; then
    print_warning "Go not installed — recording in .genpy_go_deps"
    printf "%s\n" $packages > "$target_dir/.genpy_go_deps"
    return 0
  fi

  local mod_dir
  mod_dir="$(dirname "$go_mod")"

  for pkg in $packages; do
    (cd "$mod_dir" && go get "$pkg" 2>/dev/null) || \
      print_warning "Could not install $pkg — add it with: go get $pkg"
  done
}



# -----------------------------------------------------------------------------
# inject_blueprint_addons
#
# Injects the selected add-ons into the dependency files.
#
# Arguments:
#   $1 — target_dir
#   $2 — name of the array with selected add-on IDs (nameref)
#   $3 — blueprint
# -----------------------------------------------------------------------------
inject_blueprint_addons() {
  local target_dir="$1"
  local -n _addons_ref="$2"
  local blueprint="$3"

  [[ ${#_addons_ref[@]} -eq 0 ]] && return 0

  echo -e "\n💉 Injecting add-ons..."

  local lang
  lang=$(blueprint_meta "$blueprint" "lang")

  for addon_id in "${_addons_ref[@]}"; do
    # Resolve real packages from config.sh
    local packages="${ADDON_PACKAGES[${blueprint}.${addon_id}]:-}"

    if [[ -z "$packages" ]]; then
      print_warning "Add-on '$addon_id' has no packages defined — skipped"
      continue
    fi
    echo "   + $packages"

    case "$lang" in
      python) _inject_python_addons "$target_dir" "$packages" ;;
      node)   _inject_node_addons   "$target_dir" "$packages" ;;
      go)     _inject_go_addons     "$target_dir" "$packages" ;;
    esac
  done

  print_success "Add-ons injected successfully."
}
