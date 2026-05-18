SELECTED_LIBS=()

show_menu() {
  echo ""
  echo "Selecciona librerías:"
  echo "1) fastapi"
  echo "2) flake8"
  echo "3) python-dotenv"
  echo "4) requests"
  echo "5) loguru"
  echo "6) pytest"
  echo "7) numpy"
  echo "8) pandas"
  echo "9) Listo"

  options=("fastapi" "flake8" "python-dotenv" "requests" "loguru" "pytest" "numpy" "pandas")

  selected=()

  while true; do
    read -p ">>> " -a choices

    for c in "${choices[@]}"; do
      if [[ "$c" == "9" ]]; then
        SELECTED_LIBS=("${selected[@]}")
        return
      elif [[ "$c" =~ ^[1-8]$ ]]; then
        lib="${options[$((c-1))]}"
        if [[ ! " ${selected[*]} " =~ " $lib " ]]; then
          selected+=("$lib")
          echo "✅ $lib agregado"
        fi
      fi
    done
  done
}

add_libraries() {
  local dir=$1

  for lib in "${SELECTED_LIBS[@]}"; do
    echo "$lib" >> "$dir/requirements.txt"
  done

  echo ""
  echo "📦 Librerías instaladas:"
  for lib in "${SELECTED_LIBS[@]}"; do
    echo "• $lib"
  done
}
