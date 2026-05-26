# lib/review.sh
genpy_review() {
  local TARGET="${1:-.}"
  local MODEL="qwen2.5-coder:3b"

  echo "🧠 GenPy Review (v1.0.0-alpha)"
  echo "📂 Target: $TARGET"
  echo "🤖 Model: $MODEL"
  echo "-----------------------------------"

  # Buscamos archivos ignorando los que causan problemas
  local FILES=$(find "$TARGET" -type f \
      -not -path "*/.git/*" \
      -not -path "*/node_modules/*" \
      -not -path "*/venv/*" \
      -not -path "*/__pycache__/*" \
      -not -name ".DS_Store" \
      | head -n 20)

  for file in $FILES; do
    echo "🔍 $file"
    
    # Leemos el contenido
    local CONTENT=$(cat "$file" 2>/dev/null)
    [ -z "$CONTENT" ] && continue

    # USAMOS JQ PARA CONSTRUIR EL JSON (Esto es lo que soluciona tu problema)
    # -n: crea un objeto nuevo
    # --arg: pasa las variables de forma segura (escapa comillas y saltos de línea automáticamente)
    local PAYLOAD=$(jq -n \
      --arg model "$MODEL" \
      --arg prompt "Revisa este código como senior engineer. Detecta bugs, malas prácticas y mejoras:\n\n$CONTENT" \
      '{model: $model, prompt: $prompt, stream: false}')

    # Enviamos el PAYLOAD ya construido
    curl -s http://localhost:11434/api/generate -d "$PAYLOAD" | jq -r '.response'

    echo -e "\n-----------------------------------\n"
  done
}