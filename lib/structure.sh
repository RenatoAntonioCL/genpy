#!/bin/bash
set -euo pipefail

# =============================================================================
# GenPy — lib/structure.sh
#
# Crea la estructura de carpetas y archivos base del proyecto generado.
#
# Estructura resultante:
#   <project>/
#   ├── src/
#   │   └── main.py        → punto de entrada de la aplicación
#   ├── tests/
#   │   └── .gitkeep       → mantiene la carpeta en git aunque esté vacía
#   ├── requirements.txt   → dependencias (se llena en libs.sh)
#   └── README.md          → documentación inicial
# =============================================================================

# -----------------------------------------------------------------------------
# create_structure
#
# Argumentos:
#   $1 — ruta absoluta al directorio del proyecto (ya debe existir)
# -----------------------------------------------------------------------------
create_structure() {
  local project_dir="$1"

  # Extraer solo el nombre del proyecto para usarlo en los archivos de texto
  local project_name
  project_name="$(basename "$project_dir")"

  # ── Carpetas ──────────────────────────────────────────────────────────────

  mkdir -p "$project_dir/src"    # código fuente de la aplicación
  mkdir -p "$project_dir/tests"  # tests unitarios e integración

  # ── README.md ─────────────────────────────────────────────────────────────
  # Usa el nombre real del proyecto en el título
  cat > "$project_dir/README.md" <<EOF
# $project_name

Proyecto generado con [GenPy](https://github.com/RenatoAntonioCL/genpy).

## Requisitos

- Python 3.10+

## Instalación

\`\`\`bash
pip install -r requirements.txt
\`\`\`

## Uso

\`\`\`bash
python src/main.py
\`\`\`
EOF

  # ── requirements.txt ──────────────────────────────────────────────────────
  # Se crea vacío aquí; libs.sh lo llenará con las librerías seleccionadas
  touch "$project_dir/requirements.txt"

  # ── src/main.py ───────────────────────────────────────────────────────────
  # Punto de entrada mínimo y correcto: función main() con guard __main__
  cat > "$project_dir/src/main.py" <<'EOF'
def main():
    print("Hello from GenPy")


if __name__ == "__main__":
    main()
EOF

  # ── tests/.gitkeep ────────────────────────────────────────────────────────
  # Git no trackea carpetas vacías. .gitkeep es una convención para forzarlo.
  touch "$project_dir/tests/.gitkeep"

  echo "✔ Estructura de proyecto creada"
}
