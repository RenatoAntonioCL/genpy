#!/usr/bin/env bash
set -euo pipefail

[[ -n "${_GENPY_OLLAMA_LOADED:-}" ]] && return 0
_GENPY_OLLAMA_LOADED=1

# =============================================================================
# GenPy — lib/providers/ollama.sh
#
# Ollama provider for genpy review.
# Contract: ai_complete(prompt_file, output_file, options_file) → 0|1|2|3
#   0 → success, response in output_file
#   1 → service failure (connection refused, HTTP non-200)
#   2 → empty or malformed response
#   3 → timeout
# =============================================================================

OLLAMA_HOST="${OLLAMA_HOST:-http://localhost:11434}"
OLLAMA_TIMEOUT="${OLLAMA_TIMEOUT:-120}"

# ─── Public API ───────────────────────────────────────────────────────────────

# ai_complete PROMPT_FILE OUTPUT_FILE [OPTIONS_FILE]
ai_complete() {
  if [[ $# -lt 2 ]]; then
    echo "Usage: ai_complete PROMPT_FILE OUTPUT_FILE [OPTIONS_FILE]" >&2
    return 1
  fi

  local prompt_file="$1" output_file="$2"

  if [[ ! -f "$prompt_file" ]]; then
    echo "Error: prompt_file not found: $prompt_file" >&2
    return 1
  fi

  local model
  model=$(_ollama_detect_model) || return 1

  local prompt_json
  prompt_json=$(_ollama_json_encode < "$prompt_file") || return 2

  local payload="{\"model\":\"${model}\",\"prompt\":${prompt_json},\"stream\":false}"

  local tmp_resp curl_rc=0 http_code
  tmp_resp=$(mktemp)

  http_code=$(curl -s \
    --max-time "$OLLAMA_TIMEOUT" \
    --connect-timeout 5 \
    -w "%{http_code}" \
    -o "$tmp_resp" \
    -X POST \
    -H "Content-Type: application/json" \
    -d "$payload" \
    "${OLLAMA_HOST}/api/generate" 2>/dev/null) || curl_rc=$?

  if [[ "$curl_rc" -eq 28 ]]; then
    rm -f "$tmp_resp"; return 3
  elif [[ "$curl_rc" -ne 0 ]]; then
    rm -f "$tmp_resp"; return 1
  fi

  if [[ "$http_code" != "200" ]]; then
    rm -f "$tmp_resp"; return 1
  fi

  local response
  response=$(_ollama_extract_response "$tmp_resp") || { rm -f "$tmp_resp"; return 2; }
  rm -f "$tmp_resp"

  if [[ -z "$response" ]]; then
    return 2
  fi

  printf '%s' "$response" > "$output_file"
  return 0
}

# ─── Internals ────────────────────────────────────────────────────────────────

# Priority: 1. GENPY_MODEL env var  2. first model in ollama list  3. qwen2.5:3b
_ollama_detect_model() {
  if [[ -n "${GENPY_MODEL:-}" ]]; then
    echo "$GENPY_MODEL"; return 0
  fi

  local tags_json
  tags_json=$(curl -s --max-time 5 \
    "${OLLAMA_HOST}/api/tags" 2>/dev/null) || true

  if [[ -n "$tags_json" ]]; then
    local first
    if command -v jq &>/dev/null; then
      first=$(printf '%s' "$tags_json" | jq -r '.models[0].name // empty' 2>/dev/null || true)
    else
      first=$(printf '%s' "$tags_json" \
        | grep -o '"name":"[^"]*"' | head -1 | cut -d'"' -f4 || true)
    fi
    [[ -n "$first" ]] && { echo "$first"; return 0; }
  fi

  echo "qwen2.5:3b"
}

# Reads stdin, prints the JSON string with quotes (e.g.: "hello\nworld")
_ollama_json_encode() {
  if command -v jq &>/dev/null; then
    jq -Rs '.'
  else
    python3 -c 'import json,sys; print(json.dumps(sys.stdin.read()))'
  fi
}

# Extracts .response from Ollama's JSON response
_ollama_extract_response() {
  local file="$1"
  if command -v jq &>/dev/null; then
    jq -r '.response // empty' "$file" 2>/dev/null
  else
    python3 - "$file" 2>/dev/null <<'PYEOF'
import json, sys
try:
    data = json.load(open(sys.argv[1]))
    print(data.get("response", ""), end="")
except Exception:
    sys.exit(1)
PYEOF
  fi
}
