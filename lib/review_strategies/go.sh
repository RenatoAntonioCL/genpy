#!/usr/bin/env bash
# GenPy — review strategy: Go (Semana 5)
# Contrato: validate_syntax, extract_signatures, get_prompt_rules
set -euo pipefail

validate_syntax() {
  # Semana 5: go vet ./...
  return 0
}

extract_signatures() {
  local file="$1"
  grep -E '^func ' "$file" || true
}

get_prompt_rules() {
  cat <<'EOF'
- Seguir las convenciones de formato de gofmt.
- Manejar errores explícitamente; no ignorar el valor de retorno de error.
- Preferir interfaces pequeñas y composición.
EOF
}
