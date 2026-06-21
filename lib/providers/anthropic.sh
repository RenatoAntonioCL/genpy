#!/usr/bin/env bash
set -euo pipefail

[[ -n "${_GENPY_ANTHROPIC_LOADED:-}" ]] && return 0
_GENPY_ANTHROPIC_LOADED=1

# =============================================================================
# GenPy — lib/providers/anthropic.sh
#
# Anthropic Claude API provider for genpy review.
# Contract: ai_complete(prompt_file, output_file) → 0|1|2|3
#   0 → success, response in output_file
#   1 → service failure (connection refused, HTTP non-200, missing API key)
#   2 → empty or malformed response
#   3 → timeout
# =============================================================================

ANTHROPIC_TIMEOUT="${ANTHROPIC_TIMEOUT:-120}"
ANTHROPIC_MAX_TOKENS="${ANTHROPIC_MAX_TOKENS:-4096}"

# ─── Public API ───────────────────────────────────────────────────────────────

ai_complete() {
  if [[ $# -lt 2 ]]; then
    echo "Usage: ai_complete PROMPT_FILE OUTPUT_FILE" >&2
    return 1
  fi

  local prompt_file="$1" output_file="$2"

  if [[ ! -f "$prompt_file" ]]; then
    echo "Error: prompt_file not found: $prompt_file" >&2
    return 1
  fi

  if [[ -z "${ANTHROPIC_API_KEY:-}" ]]; then
    echo "Error: ANTHROPIC_API_KEY is not set" >&2
    return 1
  fi

  local model
  model=$(_anthropic_detect_model)

  local prompt_json
  prompt_json=$(_anthropic_json_encode < "$prompt_file") || return 2

  local payload
  payload="{\"model\":\"${model}\",\"max_tokens\":${ANTHROPIC_MAX_TOKENS},\"messages\":[{\"role\":\"user\",\"content\":${prompt_json}}]}"

  local tmp_resp curl_rc=0 http_code
  tmp_resp=$(mktemp)

  http_code=$(curl -s \
    --max-time "$ANTHROPIC_TIMEOUT" \
    --connect-timeout 5 \
    -w "%{http_code}" \
    -o "$tmp_resp" \
    -X POST \
    -H "Content-Type: application/json" \
    -H "x-api-key: ${ANTHROPIC_API_KEY}" \
    -H "anthropic-version: 2023-06-01" \
    -d "$payload" \
    "https://api.anthropic.com/v1/messages" 2>/dev/null) || curl_rc=$?

  if [[ "$curl_rc" -eq 28 ]]; then
    rm -f "$tmp_resp"; return 3
  elif [[ "$curl_rc" -ne 0 ]]; then
    rm -f "$tmp_resp"; return 1
  fi

  if [[ "$http_code" != "200" ]]; then
    rm -f "$tmp_resp"; return 1
  fi

  local response
  response=$(_anthropic_extract_response "$tmp_resp") || { rm -f "$tmp_resp"; return 2; }
  rm -f "$tmp_resp"

  if [[ -z "$response" ]]; then
    return 2
  fi

  printf '%s' "$response" > "$output_file"
  return 0
}

# ─── Internals ────────────────────────────────────────────────────────────────

_anthropic_detect_model() {
  if [[ -n "${GENPY_MODEL:-}" ]]; then
    echo "$GENPY_MODEL"; return 0
  fi
  echo "claude-haiku-4-5"
}

_anthropic_json_encode() {
  if command -v jq &>/dev/null; then
    jq -Rs '.'
  else
    python3 -c 'import json,sys; print(json.dumps(sys.stdin.read()))'
  fi
}

_anthropic_extract_response() {
  local file="$1"
  if command -v jq &>/dev/null; then
    jq -r '.content[0].text // empty' "$file" 2>/dev/null
  else
    python3 - "$file" 2>/dev/null <<'PYEOF'
import json, sys
try:
    data = json.load(open(sys.argv[1]))
    print(data["content"][0]["text"], end="")
except Exception:
    sys.exit(1)
PYEOF
  fi
}
