#!/opt/homebrew/bin/bash
set -euo pipefail

# =============================================================================
# GenPy — lib/template.sh (v4.0.0)
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

  # Validar que el template exista antes de intentar copiar
  if [[ ! -d "$template_dir" ]]; then
    print_error "Template no encontrado en: $template_dir"
    exit 1
  fi

  echo -e "\n  Fabricando entorno para: \033[1;36m$project_name\033[0m"
  mkdir -p "$target_dir"

  # Copiar archivos visibles y ocultos del template
  # El "2>/dev/null || true" en los dotfiles evita error si no hay archivos ocultos
  cp -R "$template_dir/"* "$target_dir/"
  cp -R "$template_dir/."* "$target_dir/" 2>/dev/null || true

  echo "📂 Estructura de archivos copiada."
  echo "⚙️  Inyectando variables del proyecto..."

  # Normalizar el nombre: minúsculas y caracteres especiales → guión
  # Esto garantiza compatibilidad con Docker image names, npm, go modules, etc.
  local clean_name
  clean_name=$(echo "$project_name" \
    | tr '[:upper:]' '[:lower:]' \
    | sed 's/[^a-zA-Z0-9-]/-/g' \
    | sed 's/--*/-/g'           \
    | sed 's/^-//;s/-$//')

  # Extensiones y archivos donde puede aparecer {{PROJECT_NAME}}
  local -a patterns=(
    "*.yml" "*.yaml"
    "*.json" "*.toml" "*.mod"
    "*.env" "*.txt" "*.md"
    "*.go" "*.ts" "*.js" "*.py" "*.rs"
    "Dockerfile"
  )

  # Procesar cada patrón de archivo
  for pattern in "${patterns[@]}"; do
    while IFS= read -r -d '' file; do

      # Reemplazar {{PROJECT_NAME}} por el nombre limpio
      _sed_inplace "s|{{PROJECT_NAME}}|${clean_name}|g" "$file"

      # Limpiar campo "version:" obsoleto en docker-compose
      # (deprecado en Compose v2, genera warnings innecesarios)
      if [[ "$(basename "$file")" == "docker-compose.yml" ]]; then
        _sed_inplace '/^version:/d' "$file"
      fi

    done < <(find "$target_dir" -type f -name "$pattern" -print0)
  done

  echo "📝 Variables inyectadas correctamente."
  print_success "¡Proyecto $project_name generado exitosamente!"
}