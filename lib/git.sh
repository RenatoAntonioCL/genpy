init_git() {
  local dir=$1
  cd "$dir" || exit
  git init -q
}

first_commit() {
  git add .
  git commit -m "Initial commit - GenPy project"
}
