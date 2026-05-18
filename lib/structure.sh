create_structure() {
  local dir=$1
  local lang=${2:-python}

  mkdir -p "$dir/src" "$dir/test"

  case "$lang" in
    python)
      echo 'print("Hello Python")' > "$dir/src/main.py"
      ;;
    node)
      echo 'console.log("Hello Node")' > "$dir/src/main.js"
      ;;
    cpp)
      echo '#include <iostream>\nint main(){ std::cout << "Hello"; }' > "$dir/src/main.cpp"
      ;;
  esac

  echo "# GenPy Project" > "$dir/README.md"
  touch "$dir/requirements.txt"
}
