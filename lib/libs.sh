#!/opt/homebrew/bin/bash
set -euo pipefail

# =============================================================================
# GenPy — lib/libs.sh
#
# Funciones para seleccionar librerías Python de una lista curada
# y escribirlas en el requirements.txt del proyecto.
#
# Diseño importante:
#   Las librerías seleccionadas NO se guardan en una variable global.
#   En su lugar, el llamador declara su propio array y lo pasa por nombre
#   usando namerefs (local -n). Esto evita contaminación entre ejecuciones
#   y hace el flujo de datos explícito y predecible.
#
# Ejemplo de uso:
#   declare -a MY_LIBS
#   select_libraries MY_LIBS
#   add_libraries "$PROJECT_DIR" MY_LIBS
# =============================================================================

# -----------------------------------------------------------------------------
# select_libraries
#
# Muestra un menú interactivo para elegir librerías Python.
# El usuario puede escribir varios números en una sola línea (ej: "1 3 6").
# Escribe "0" o presiona Enter después de "0" para terminar la selección.
#
# Argumentos:
#   $1 — nombre del array donde se guardarán las librerías elegidas (nameref)
# -----------------------------------------------------------------------------
select_libraries() {
  # local -n crea una referencia al array del llamador por su nombre.
  # Cualquier modificación a _selected_libs modifica el array original.
  local -n _selected_libs="$1"

  # Limpiar el array antes de llenar, por si el llamador lo reutiliza
  _selected_libs=()

  echo ""
  echo "📦 Selecciona librerías (escribe los números separados por espacio):"
  echo ""
  echo "  1) fastapi          5) loguru"
  echo "  2) flake8           6) pytest"
  echo "  3) python-dotenv    7) numpy"
  echo "  4) requests         8) pandas"
  echo ""
  echo "  0) Listo — continuar sin agregar más"
  echo ""

  while true; do
    read -rp ">>> " raw_input

    # Flag para saber si el usuario escribió "0" en esta línea
    local user_is_done=false

    # Iterar sobre cada token del input (permite "1 3 6" en una sola línea)
    for option in $raw_input; do
      case "$option" in
        1) _selected_libs+=("fastapi")        ;;
        2) _selected_libs+=("flake8")         ;;
        3) _selected_libs+=("python-dotenv")  ;;
        4) _selected_libs+=("requests")       ;;
        5) _selected_libs+=("loguru")         ;;
        6) _selected_libs+=("pytest")         ;;
        7) _selected_libs+=("numpy")          ;;
        8) _selected_libs+=("pandas")         ;;
        0) user_is_done=true                  ;;
        *) echo "  ⚠️  Opción '$option' no válida, ignorada" ;;
      esac
    done

    # Salir del loop solo cuando el usuario escriba "0"
    if [[ "$user_is_done" == true ]]; then
      break
    fi
  done
}

# -----------------------------------------------------------------------------
# add_libraries
#
# Escribe las librerías seleccionadas en el requirements.txt del proyecto.
# Una librería por línea, formato estándar de pip.
#
# Argumentos:
#   $1 — ruta absoluta al directorio del proyecto
#   $2 — nombre del array con las librerías a escribir (nameref)
# -----------------------------------------------------------------------------
add_libraries() {
  local project_dir="$1"

  # Nameref al array de librerías pasado por el llamador
  local -n _libs_to_write="$2"

  # Si no se eligió ninguna librería, dejar requirements.txt vacío
  if [[ ${#_libs_to_write[@]} -eq 0 ]]; then
    echo "📦 Sin librerías seleccionadas — requirements.txt quedará vacío"
    return 0
  fi

  echo "📦 Librerías añadidas al proyecto:"
  for lib in "${_libs_to_write[@]}"; do
    echo "   • $lib"
  done

  # Escribir una librería por línea en requirements.txt
  printf "%s\n" "${_libs_to_write[@]}" > "$project_dir/requirements.txt"
}
