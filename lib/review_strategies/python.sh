#!/usr/bin/env bash
# GenPy — review strategy: Python
# Contrato: validate_syntax, extract_signatures, get_prompt_rules
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
- Mantener indentación de 4 espacios.
- Preferir type hints en funciones públicas.
- Usar f-strings en lugar de concatenación.
- No eliminar decoradores de FastAPI (@router.*, @app.*).
EOF
}
