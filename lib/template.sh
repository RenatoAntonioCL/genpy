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

  echo "📁 Copiando template desde $template_dir a $target_dir..."
  mkdir -p "$target_dir"

  # Copia los archivos (respeta Modelo A: Dockerfile en raíz / Modelo B: en backend/)
  rsync -av --delete --exclude='.git' --exclude='.DS_Store' --exclude='__pycache__' \
    "$template_dir/" "$target_dir/"

  echo "✅ Estructura copiada."

  # --- NUEVO: Inyección de variables ---
  echo "🔧 Inyectando nombre de proyecto: $project_name"
  
  # Buscar solo archivos de texto para evitar corromper binarios
  find "$target_dir" -type f \( \
    -name "*.md" -o -name "docker-compose.yml" -o -name "Dockerfile" \
    -o -name "*.py" -o -name "*.sh" -o -name "*.go" -o -name "go.mod" \
    -o -name "package.json" -o -name "nest-cli.json" -o -name "tsconfig.json" \
    \) | while read -r file; do
    _sed_inplace "s/{{PROJECT_NAME}}/$project_name/g" "$file"
  done
  
  echo "✨ Configuración completada."
}