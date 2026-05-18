#!/bin/bash

LIBS=()

select_libraries() {
  echo ""
  echo "📦 Selecciona librerías:"
  echo "1) fastapi"
  echo "2) flake8"
  echo "3) python-dotenv"
  echo "4) requests"
  echo "5) loguru"
  echo "6) pytest"
  echo "7) numpy"
  echo "8) pandas"
  echo "9) Listo"
  echo ""

  while true; do
    read -p ">>> " input

    for opt in $input; do
      case $opt in
        1) LIBS+=("fastapi") ;;
        2) LIBS+=("flake8") ;;
        3) LIBS+=("python-dotenv") ;;
        4) LIBS+=("requests") ;;
        5) LIBS+=("loguru") ;;
        6) LIBS+=("pytest") ;;
        7) LIBS+=("numpy") ;;
        8) LIBS+=("pandas") ;;
        9) return ;;
      esac
    done
  done
}

add_libraries() {
  local dir="$1"

  if [ ${#LIBS[@]} -eq 0 ]; then
    echo "📦 No libraries selected"
    return
  fi

  echo "📦 Librerías instaladas:"
  for lib in "${LIBS[@]}"; do
    echo "• $lib"
  done

  printf "%s\n" "${LIBS[@]}" > "$dir/requirements.txt"
}
