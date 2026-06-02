#!/usr/bin/env bash
# GenPy — review strategy: JavaScript/TypeScript (Semana 5)
# Contrato: validate_syntax, extract_signatures, get_prompt_rules
set -euo pipefail

validate_syntax() {
  # Semana 5: node --check o tsc --noEmit
  return 0
}

extract_signatures() {
  local file="$1"
  grep -E '^(export |function |const |async function )' "$file" || true
}

get_prompt_rules() {
  cat <<'EOF'
- Preferir const sobre let; evitar var.
- Tipar explícitamente los parámetros y valores de retorno en TypeScript.
- Usar async/await en lugar de callbacks o cadenas .then().
EOF
}
