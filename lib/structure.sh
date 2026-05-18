create_structure() {
  local dir=$1

  mkdir -p "$dir/src" "$dir/test"

  echo "# GenPy Project" > "$dir/README.md"
  echo "Proyecto generado con GenPy" >> "$dir/README.md"

  echo "DEBUG=True" > "$dir/.env"
  echo "DEBUG=True" > "$dir/.env.example"

  touch "$dir/requirements.txt"

  echo 'print("👋 Hello from GenPy")' > "$dir/src/main.py"

  echo 'def test_example():\n    pass' > "$dir/test/test_main.py"

  touch "$dir/src/__init__.py"

  # 🐳 ESTO ES LO QUE TE FALTABA
  cat > "$dir/Dockerfile" <<EOF
FROM python:3.10-slim

WORKDIR /app
COPY . /app

RUN pip install --no-cache-dir -r requirements.txt

CMD ["python", "src/main.py"]
EOF

  echo "🐳 Dockerfile creado"
}