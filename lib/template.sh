#!/usr/bin/env bash
set -euo pipefail

# =============================================================================
# GenPy — lib/template.sh (v1.0.0-alpha)
#
# Motor de copiado e inyección de variables en los templates.
#
# Bug corregido: la versión anterior guardaba el comando sed en una variable
# de string ("sed -i ''") y lo ejecutaba como $sed_cmd "s/...". En Bash con
# set -euo pipefail esto falla porque el string con espacios no se expande
# como comando. Solución: función wrapper _sed_inplace() que abstrae la
# diferencia entre macOS y Linux sin necesidad de eval.
# =============================================================================

# -----------------------------------------------------------------------------
# _sed_inplace  (función interna)
#
# Abstrae la diferencia de sed -i entre macOS (requiere sufijo '') y Linux.
# Usar esta función en lugar de $sed_cmd elimina el bug de expansión de variables.
#
# Argumentos:
#   $1 — expresión sed
#   $2 — archivo a modificar
# -----------------------------------------------------------------------------
_sed_inplace() {
  local expression="$1"
  local file="$2"

  if [[ "$OSTYPE" == "darwin"* ]]; then
    sed -i '' "$expression" "$file"
  else
    sed -i "$expression" "$file"
  fi
}

# -----------------------------------------------------------------------------
# _generate_secret  (función interna)
#
# Genera un string hexadecimal aleatorio criptográficamente seguro.
# Usa openssl rand si está disponible; cae a /dev/urandom como fallback.
#
# Argumentos:
#   $1 — bytes: número de bytes aleatorios (la salida hex tendrá el doble de chars)
# -----------------------------------------------------------------------------
_generate_secret() {
  local bytes="${1:-32}"
  if command -v openssl &>/dev/null; then
    openssl rand -hex "$bytes"
  else
    LC_ALL=C tr -dc 'a-f0-9' < /dev/urandom | head -c "$((bytes * 2))"
  fi
}

# -----------------------------------------------------------------------------
# _inject_env_secrets  (función interna)
#
# Reemplaza marcadores {{SECRET_HEX_N}} en el .env con valores aleatorios
# generados por _generate_secret. Luego resuelve referencias cruzadas del
# tipo {{VAR_NAME}} (usado por ejemplo en DATABASE_URL para referenciar
# la contraseña generada).
#
# Argumentos:
#   $1 — env_file: ruta al .env a procesar
# -----------------------------------------------------------------------------
_inject_env_secrets() {
  local env_file="$1"
  [[ -f "$env_file" ]] || return 0

  local -A _secret_map
  local tmp generated=0
  tmp=$(mktemp)

  # Pasada 1: generar secretos para cada {{SECRET_HEX_N}}.
  # Guarda el valor generado en _secret_map keyed por nombre de variable.
  while IFS= read -r line || [[ -n "$line" ]]; do
    if [[ "$line" =~ ^([A-Z_][A-Z0-9_]*)=.*\{\{SECRET_HEX_([0-9]+)\}\} ]]; then
      local var_name="${BASH_REMATCH[1]}"
      local bytes="${BASH_REMATCH[2]}"
      local secret
      secret=$(_generate_secret "$bytes")
      _secret_map["$var_name"]="$secret"
      line="${line//\{\{SECRET_HEX_${bytes}\}\}/$secret}"
      generated=1
    fi
    printf '%s\n' "$line"
  done < "$env_file" > "$tmp"

  # Pasada 2: sustituir referencias cruzadas {{VAR_NAME}} (ej: en DATABASE_URL).
  # Usa sustitución de strings en bash — ${#arr[@]} con arrays vacíos dispara
  # nounset en bash 5.3; el flag 'generated' evita ese path para blueprints sin secretos.
  if [[ "$generated" -eq 1 ]]; then
    local content
    content=$(< "$tmp")
    for var_name in "${!_secret_map[@]}"; do
      content="${content//\{\{${var_name}\}\}/${_secret_map[$var_name]}}"
    done
    printf '%s\n' "$content" > "$env_file"
    local vars_list
    vars_list=$(printf '%s, ' "${!_secret_map[@]}")
    echo "🔐 Secretos generados en .env: ${vars_list%, }"
  else
    mv "$tmp" "$env_file"
    return 0
  fi

  rm -f "$tmp"
}

# -----------------------------------------------------------------------------
# copy_template
#
# Copia el template del blueprint elegido al directorio de destino e inyecta
# el nombre del proyecto en todos los archivos relevantes.
#
# Argumentos:
#   $1 — template_dir:   ruta absoluta al template (ej: .../templates/web-fastapi-postgres)
#   $2 — target_dir:     ruta ABSOLUTA donde se creará el proyecto
#   $3 — project_name:   nombre del proyecto para reemplazar {{PROJECT_NAME}}
#
# Bug corregido: el llamador ahora debe pasar target_dir como ruta absoluta.
# wizard.sh usa "$(pwd)/$PROJECT_NAME" para garantizarlo.
# -----------------------------------------------------------------------------
copy_template() {
  local template_dir="$1"
  local target_dir="$2"
  local project_name="$3"

  [[ -d "$template_dir" ]] || { echo "Template no encontrado: $template_dir" >&2; return 1; }

  echo "📁 Copiando template desde $template_dir a $target_dir..."
  mkdir -p "$target_dir"

  # Copia los archivos (respeta Modelo A: Dockerfile en raíz / Modelo B: en backend/)
  rsync -a --delete --exclude='.git' --exclude='.DS_Store' --exclude='__pycache__' \
    "$template_dir/" "$target_dir/"

  if [[ -z "$(ls -A "$target_dir")" ]]; then
    echo "El template se copió vacío: $template_dir" >&2
    return 1
  fi

  echo "✅ Estructura copiada."

  # --- NUEVO: Inyección de variables ---
  echo "🔧 Inyectando nombre de proyecto: $project_name"
  
  # Buscar solo archivos de texto para evitar corromper binarios
  while IFS= read -r file; do
    _sed_inplace "s/{{PROJECT_NAME}}/$project_name/g" "$file"
  done < <(find "$target_dir" -type f \( \
    -name ".env" -o \
    -name "*.md" -o -name "docker-compose.yml" -o -name "Dockerfile" \
    -o -name "*.py" -o -name "*.sh" -o -name "*.go" -o -name "go.mod" \
    -o -name "package.json" -o -name "nest-cli.json" -o -name "tsconfig.json" \
    \))

  _inject_env_secrets "$target_dir/.env"

  local blueprint_toml="$target_dir/.genpy/blueprint.toml"
  if [[ -f "$blueprint_toml" ]]; then
    if ! _validate_blueprint_toml "$blueprint_toml"; then
      echo "Error: blueprint.toml inválido en el proyecto generado." >&2
      return 1
    fi
    echo "✅ blueprint.toml validado."
  fi

  echo "✨ Configuración completada."
}

# -----------------------------------------------------------------------------
# _validate_blueprint_toml  (función interna)
#
# Verifica que el blueprint.toml copiado existe, no está vacío y contiene
# los campos mínimos requeridos por el contrato GenPy (sección [meta] con
# language y version). Usa solo grep/bash — sin dependencias externas.
#
# Argumentos:
#   $1 — toml_file: ruta al .genpy/blueprint.toml a validar
# Retorna:
#   0 — válido y parseable
#   1 — inválido (imprime motivo a stderr)
# -----------------------------------------------------------------------------
_validate_blueprint_toml() {
  local toml_file="$1"

  if [[ ! -f "$toml_file" ]]; then
    echo "Error: blueprint.toml no encontrado: $toml_file" >&2
    return 1
  fi

  if [[ ! -s "$toml_file" ]]; then
    echo "Error: blueprint.toml está vacío: $toml_file" >&2
    return 1
  fi

  if ! grep -q '^\[meta\]' "$toml_file"; then
    echo "Error: blueprint.toml: falta sección [meta]" >&2
    return 1
  fi

  if ! grep -qE '^version[[:space:]]*=' "$toml_file"; then
    echo "Error: blueprint.toml: falta campo version" >&2
    return 1
  fi

  if ! grep -qE '^language[[:space:]]*=[[:space:]]*"(python|go|javascript|bash|infra)"' "$toml_file"; then
    echo "Error: blueprint.toml: campo language ausente o valor desconocido" >&2
    return 1
  fi

  return 0
}