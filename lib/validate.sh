is_valid_name() {
  local name="$1"

  if [[ -z "$name" ]]; then
    return 1
  fi

  if [[ "$name" =~ [^a-zA-Z0-9_-] ]]; then
    return 1
  fi

  return 0
}
