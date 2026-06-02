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

  # Simula respuesta: extrae el contenido de la Sección 4 (FRAGMENTO OBJETIVO)
  # que es lo que el modelo devolvería: solo el código, sin el prompt completo.
  local section4_marker="=== SECCIÓN 4: FRAGMENTO OBJETIVO ==="
  if grep -qF "$section4_marker" "$prompt_file" 2>/dev/null; then
    awk -v marker="$section4_marker" 'found{print} $0==marker{found=1}' \
      "$prompt_file" >"$output_file"
  else
    cp "$prompt_file" "$output_file"
  fi

  [[ -s "$output_file" ]] || return 2
  return 0
}
