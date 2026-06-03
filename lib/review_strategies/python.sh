#!/usr/bin/env bash
# GenPy — review strategy: Python
# Contract: validate_syntax, extract_signatures, get_prompt_rules
set -euo pipefail

validate_syntax() {
  local file="$1"
  python3 -m py_compile "$file"
}

extract_signatures() {
  local file="$1"
  grep -E '^((async )?def |class )' "$file" || true
}

get_prompt_rules() {
  cat <<'EOF'
- Keep 4-space indentation.
- Prefer type hints on public functions.
- Use f-strings instead of concatenation.
- Do not remove FastAPI decorators (@router.*, @app.*).
EOF
}
