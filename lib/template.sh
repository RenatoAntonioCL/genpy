#!/opt/homebrew/bin/bash
set -euo pipefail

# =============================================================================
# GenPy — lib/template.sh
#
# Copia el template del lenguaje elegido al directorio del proyecto nuevo
# y reemplaza todas las ocurrencias de {{PROJECT_NAME}} por el nombre real.
#
# El placeholder {{PROJECT_NAME}} puede aparecer en:
#   - Nombres de archivo (ej: en .gitignore de Go)
#   - Contenido de archivos (package.json, go.mod, Cargo.toml, READMEs, etc.)
#
# Uso:
#   copy_template "$template_dir" "$project_dir" "$project_name"
# =============================================================================

# -----------------------------------------------------------------------------
# copy_template
#
# Copia recursivamente el template al directorio del proyecto e inyecta
# el nombre del proyecto en todos los archivos de texto.
#
# Argumentos:
#   $1 — template_dir:  ruta al template del lenguaje (ej: .../templates/node)
#   $2 — project_dir:   ruta al directorio del proyecto nuevo
#   $3 — project_name:  nombre del proyecto para reemplazar {{PROJECT_NAME}}
# -----------------------------------------------------------------------------
copy_template() {
  local template_dir="$1"
  local project_dir="$2"
  local project_name="$3"

  # Copiar todos los archivos del template al proyecto
  # -R: recursivo | -p: preservar permisos y timestamps
  cp -Rp "$template_dir"/. "$project_dir/"

  echo "📋 Template copiado"

  # Inyectar el nombre del proyecto en el contenido de todos los archivos de texto.
  # - find: busca archivos regulares (no directorios, no .gitkeep vacíos)
  # - file: verifica que sea texto antes de procesarlo (evita binarios)
  # - sed: reemplaza {{PROJECT_NAME}} por el nombre real, in-place
  #
  # En macOS, sed -i requiere un sufijo (aunque sea vacío ''): sed -i ''
  while IFS= read -r -d '' filepath; do
    # Saltar archivos vacíos (como .gitkeep)
    [[ -s "$filepath" ]] || continue

    # Verificar que sea un archivo de texto antes de modificarlo
    if file "$filepath" | grep -qE "text|JSON|source"; then
      sed -i '' "s|{{PROJECT_NAME}}|${project_name}|g" "$filepath"
    fi
  done < <(find "$project_dir" -type f -print0)

  # echo "🔧 Nombre del proyecto inyectado: $project_name" #
  
  echo "📋 Archivos base listos para personalización"
}