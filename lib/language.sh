#!/opt/homebrew/bin/bash
set -euo pipefail

# =============================================================================
# GenPy — lib/language.sh
#
# Presenta el menú de selección de lenguaje y devuelve la ruta al template
# correspondiente dentro de la carpeta templates/.
#
# Uso:
#   select_language SELECTED_LANGUAGE
#   get_template_dir "$BASE_DIR" "$language" TEMPLATE_DIR
# =============================================================================

# Lenguajes soportados y sus etiquetas para el menú.
# Para agregar un nuevo lenguaje: añadir una entrada aquí y crear
# su carpeta correspondiente en templates/.
readonly -A LANGUAGE_LABELS=(
  [python]="Python         → src/main.py, requirements.txt"
  [node]="Node.js        → src/index.js, package.json"
  [go]="Go             → src/main.go, go.mod"
  [rust]="Rust           → src/main.rs, Cargo.toml"
)

# Orden de presentación en el menú (los arrays asociativos no tienen orden)
readonly LANGUAGE_ORDER=(python node go rust)

# -----------------------------------------------------------------------------
# select_language
#
# Muestra el menú interactivo de lenguajes y guarda la elección en el
# array del llamador por nameref.
#
# Argumentos:
#   $1 — nombre de la variable donde guardar el lenguaje elegido (nameref)
# -----------------------------------------------------------------------------
select_language() {
  local -n _selected_language="$1"

  echo ""
  echo "🌐 Selecciona el lenguaje del proyecto:"
  echo ""

  # Mostrar opciones en el orden definido
  local index=1
  for lang in "${LANGUAGE_ORDER[@]}"; do
    printf "  %d) %s\n" "$index" "${LANGUAGE_LABELS[$lang]}"
    (( index++ ))
  done

  echo ""

  while true; do
    read -rp ">>> " user_choice

    # Validar que sea un número dentro del rango
    if [[ "$user_choice" =~ ^[0-9]+$ ]] && \
       (( user_choice >= 1 && user_choice <= ${#LANGUAGE_ORDER[@]} )); then
      # Convertir número de menú a nombre de lenguaje (índice base 0)
      _selected_language="${LANGUAGE_ORDER[$((user_choice - 1))]}"
      echo "   ✔ Lenguaje seleccionado: $_selected_language"
      return 0
    fi

    echo "  ⚠️  Elige un número entre 1 y ${#LANGUAGE_ORDER[@]}"
  done
}

# -----------------------------------------------------------------------------
# get_template_dir
#
# Construye la ruta absoluta al directorio de template del lenguaje elegido
# y verifica que exista.
#
# Argumentos:
#   $1 — BASE_DIR: raíz de la instalación de GenPy
#   $2 — language: nombre del lenguaje (python, node, go, rust)
#   $3 — nombre de la variable donde guardar la ruta (nameref)
# -----------------------------------------------------------------------------
get_template_dir() {
  local base_dir="$1"
  local language="$2"
  local -n _template_dir="$3"

  _template_dir="$base_dir/templates/$language"

  if [[ ! -d "$_template_dir" ]]; then
    echo "❌ Template no encontrado para '$language' en: $_template_dir"
    echo "   Verifica que la carpeta templates/$language exista en la instalación"
    exit 1
  fi
}