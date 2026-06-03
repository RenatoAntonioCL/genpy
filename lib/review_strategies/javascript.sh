#!/usr/bin/env bash
# GenPy — review strategy: JavaScript/TypeScript (Week 5)
# Contract: validate_syntax, extract_signatures, get_prompt_rules
set -euo pipefail

validate_syntax() {
  # Week 5: node --check or tsc --noEmit
  return 0
}

extract_signatures() {
  local file="$1"
  grep -E '^(export |function |const |async function )' "$file" || true
}

get_prompt_rules() {
  cat <<'EOF'
- Prefer const over let; avoid var.
- Explicitly type parameters and return values in TypeScript.
- Use async/await instead of callbacks or .then() chains.
EOF
}
