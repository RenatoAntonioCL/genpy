#!/usr/bin/env bash
# Mock de provider Ollama para tests Semana 2 (sin red).
# Contrato: ai_complete(prompt_file, output_file, options_file)
#   0=ok  1=fallo  2=vacío  3=timeout
set -euo pipefail

ai_complete() {
  local prompt_file="$1"
  local output_file="$2"
  local _options="${3:-}"

  [[ -f "$prompt_file" ]] || return 1

  # Simula respuesta: devuelve el bloque FOCAL del prompt o el archivo completo.
  if grep -q '^### FOCAL' "$prompt_file" 2>/dev/null; then
    awk '/^### FOCAL$/{flag=1;next} /^### END_FOCAL$/{flag=0} flag' "$prompt_file" >"$output_file"
  else
    cp "$prompt_file" "$output_file"
  fi

  [[ -s "$output_file" ]] || return 2
  return 0
}
