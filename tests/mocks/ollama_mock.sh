#!/usr/bin/env bash
# Ollama provider mock for tests (no network).
# Contract: ai_complete(prompt_file, output_file, options_file)
#   0=ok  1=failure  2=empty  3=timeout
set -euo pipefail

ai_complete() {
  local prompt_file="$1"
  local output_file="$2"
  local _options="${3:-}"

  [[ -f "$prompt_file" ]] || return 1

  # Simulates response: extracts the content of Section 4 (TARGET FRAGMENT),
  # which is what the model would return: only the code, without the full prompt.
  local section4_marker="=== SECTION 4: TARGET FRAGMENT ==="
  if grep -qF "$section4_marker" "$prompt_file" 2>/dev/null; then
    awk -v marker="$section4_marker" 'found{print} $0==marker{found=1}' \
      "$prompt_file" >"$output_file"
  else
    cp "$prompt_file" "$output_file"
  fi

  [[ -s "$output_file" ]] || return 2
  return 0
}
