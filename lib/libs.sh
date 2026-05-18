#!/opt/homebrew/bin/bash
set -euo pipefail

# =============================================================================
# GenPy — lib/libs.sh
#
# Catálogo interactivo de dependencias. Explica de forma concisa y didáctica 
# el propósito de cada herramienta para guiar al desarrollador.
# =============================================================================

# ─── Catálogos Explicativos por Ecosistema ───────────────────────────────────

readonly -A LIBS_PYTHON=(
  [fastapi]="FastAPI      → Framework de alto rendimiento para desarrollo ágil de APIs"
  [requests]="Requests     → Cliente HTTP intuitivo para consumir servicios y APIs externas"
  [pytest]="Pytest       → Estándar para pruebas unitarias automatizadas y aserciones"
  [pandas]="Pandas       → Biblioteca reina para ciencia de datos y manipulación de tablas"
)

readonly -A LIBS_NODE=(
  [dotenv]="Dotenv       → Gestiona credenciales cargando variables desde archivos .env"
  [cors]="CORS         → Controla la seguridad permitiendo peticiones cruzadas entre dominios"
  [jsonwebtoken]="JWT          → Implementa autenticación basada en tokens seguros firmados"
  [mongoose]="Mongoose     → Modelado de datos estructurado y elegante para MongoDB"
)

readonly -A LIBS_GO=(
  [github.com/gin-gonic/gin]="Gin          → Framework HTTP minimalista enfocado en velocidad extrema"
  [github.com/spf13/cobra]="Cobra        → El estándar de la industria para construir potentes herramientas CLI"
  [github.com/stretchr/testify]="Testify      → Añade aserciones sagradas y mocks limpios al testing nativo"
)

readonly -A LIBS_RUST=(
  [tokio]="Tokio        → Motor de ejecución asíncrono para aplicaciones concurrentes"
  [serde]="Serde        → Framework de serialización y deserialización de datos a velocidad luz"
  [reqwest]="Reqwest      → Cliente HTTP robusto para peticiones en red asíncronas"
)

# -----------------------------------------------------------------------------
# select_libraries
# Renders un menú numérico intuitivo adaptado al ecosistema técnico elegido.
# -----------------------------------------------------------------------------
select_libraries() {
  local -n _dest_array="$1"
  local lang="${SELECTED_LANGUAGE}"
  local -n current_catalog

  case "$lang" in
    python) current_catalog=LIBS_PYTHON ;;
    node)   current_catalog=LIBS_NODE   ;;
    go)     current_catalog=LIBS_GO     ;;
    rust)   current_catalog=LIBS_RUST   ;;
    *)      return 0 ;;
  esac

  if [[ ${#current_catalog[@]} -eq 0 ]]; then
    echo "ℹ️  No hay librerías opcionales configuradas para ${lang^}."
    return 0
  fi

  echo "📦 Librerías disponibles para tu stack (${lang^}):"
  echo ""

  # Array indexado para estabilizar el orden numérico de las claves
  local -a lib_keys=("${!current_catalog[@]}")
  local idx=1
  for key in "${lib_keys[@]}"; do
    printf "  %d) %s\n" "$idx" "${current_catalog[$key]}"
    (( idx++ ))
  done
  echo "  0) Ninguna — Continuar con el scaffolding limpio"
  echo ""

  read -rp "👉 Elige una o más opciones (ej: 1 2): " user_input
  echo ""

  for item in $user_input; do
    if [[ "$item" =~ ^[0-9]+$ ]] && (( item >= 1 && item <= ${#lib_keys[@]} )); then
      local selected_key="${lib_keys[$((item - 1))]}"
      _dest_array+=("$selected_key")
      echo "   ➕ Añadido a la lista: $selected_key"
    fi
  done
}

# -----------------------------------------------------------------------------
# add_libraries
# Inyecta las dependencias respetando la sintaxis de cada ecosistema técnico.
# -----------------------------------------------------------------------------
add_libraries() {
  local project_dir="$1"
  local -n _libs_list="$2"
  local lang="${SELECTED_LANGUAGE}"

  if [[ ${#_libs_list[@]} -eq 0 ]]; then
    echo "✔ Sin librerías adicionales seleccionadas."
    return 0
  fi

  local previous_dir; previous_dir="$(pwd)"
  cd "$project_dir"

  case "$lang" in
    python)
      echo "📝 Actualizando 'requirements.txt'..."
      for lib in "${_libs_list[@]}"; do
        echo "$lib" >> "requirements.txt"
      done
      ;;

    node)
      echo "📝 Registrando dependencias en 'package.json'..."
      for lib in "${_libs_list[@]}"; do
        # Inyección quirúrgica con sed respetando el estándar JSON
        if [[ "$OSTYPE" == "darwin"* ]]; then
          sed -i '' "/\"express\":/a\\
    \"$lib\": \"latest\"," "package.json"
        else
          sed -i "/\"express\":/a\\    \"$lib\": \"latest\"," "package.json"
        fi
        echo "   ✔ $lib registrada."
      done
      ;;

    go)
      if command -v go &>/dev/null; then
        echo "📥 Descargando módulos de Go localmente..."
        for lib in "${_libs_list[@]}"; do
          go get "$lib"
        done
      else
        echo "⚠️  Go no está instalado en tu Mac. Las librerías se descargarán"
        echo "   automáticamente dentro del contenedor de Docker durante el build."
        
        # Guardamos la lista temporalmente en un archivo oculto que leerá Dockerfile
        for lib in "${_libs_list[@]}"; do
          echo "$lib" >> ".genpy_packages"
        done
      fi
      ;;

    rust)
      if command -v cargo &>/dev/null; then
        echo "⚙️  Instalando crates de Rust localmente..."
        for lib in "${_libs_list[@]}"; do
          cargo add "$lib"
        done
      else
        echo "⚠️  Rust no está instalado en tu Mac. Las crates se compilarán"
        echo "   automáticamente dentro de Docker."
        for lib in "${_libs_list[@]}"; do
          echo "$lib" >> ".genpy_packages"
        done
      fi
      ;;
  esac

  cd "$previous_dir"
}
