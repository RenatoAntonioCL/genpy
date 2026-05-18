create_venv() {
  local dir="$1"

  python3 -m venv "$dir/env"
  echo "🐍 venv creado en $dir/env"
}