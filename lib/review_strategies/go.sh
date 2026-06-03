#!/usr/bin/env bash
# GenPy — review strategy: Go (Week 5)
# Contract: validate_syntax, extract_signatures, get_prompt_rules
set -euo pipefail

validate_syntax() {
  # Week 5: go vet ./...
  return 0
}

extract_signatures() {
  local file="$1"
  grep -E '^func ' "$file" || true
}

get_prompt_rules() {
  cat <<'EOF'
- Follow gofmt formatting conventions.
- Handle errors explicitly; do not ignore the error return value.
- Prefer small interfaces and composition.
EOF
}
