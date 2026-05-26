#!/bin/bash
MODEL="qwen2.5-coder:3b"
TARGET="${1:-.}"

echo "🧠 GenPy Review - Modo Interactivo"
echo "📂 Target: $TARGET"
echo "-----------------------------------"

# Obtener archivos (prioriza git, sino find)
if [ -d ".git" ]; then
    FILES=$(git ls-files | grep -E '\.(py|js|ts|go|sh)$')
else
    FILES=$(find "$TARGET" -type f \( -name "*.py" -o -name "*.js" -o -name "*.ts" -o -name "*.go" \))
fi

for file in $FILES; do
    echo -e "\n🔍 Analizando: $file"
    
    # 1. Leer contenido
    CONTENT=$(cat "$file")
    
    # 2. Prompt estricto de verificación
    # Forzamos al modelo a pensar primero (Chain of Thought)
    PROMPT="Eres un Ingeniero Senior. Analiza el siguiente código.
    1. Detecta bugs, errores de lógica o malas prácticas.
    2. Si encuentras errores, verifica la solución propuesta.
    3. Responde estrictamente en este formato:
       [ANALISIS]: Breve explicación del problema.
       [CODIGO]: El código corregido completo (o original si no hay cambios).
       
    Código:
    $CONTENT"

    PAYLOAD=$(jq -n --arg model "$MODEL" --arg prompt "$PROMPT" \
      '{model: $model, prompt: $prompt, stream: false}')

    # 3. Llamada a Ollama
    RESPONSE=$(echo "$PAYLOAD" | curl -s http://localhost:11434/api/generate -d @- | jq -r '.response')

    # 4. Mostrar análisis
    echo "$RESPONSE" | grep -E "\[ANALISIS\]" -A 5
    
    # 5. Aplicación interactiva
    echo -e "\n--- PROPUESTA DE CAMBIOS ---"
    echo "$RESPONSE" | grep -A 1000 "\[CODIGO\]" | sed 's/\[CODIGO\]//g'
    
    read -p "⚠️ ¿Aplicar estos cambios al archivo $file? (y/N): " confirm
    if [[ $confirm == [yY] ]]; then
        echo "$RESPONSE" | grep -A 1000 "\[CODIGO\]" | sed 's/\[CODIGO\]//g' > "$file.tmp"
        mv "$file.tmp" "$file"
        echo "✅ Cambios aplicados."
    else
        echo "⏭️ Cambios omitidos."
    fi
doney