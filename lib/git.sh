#!/bin/bash
set -euo pipefail

# =============================================================================
# GenPy — lib/git.sh
#
# Funciones para inicializar y hacer el primer commit del repositorio git
# del proyecto que se está generando.
# =============================================================================

# -----------------------------------------------------------------------------
# git_init
#
# Inicializa un repositorio git en el directorio del proyecto.
# Usa "main" como nombre de la rama principal (estándar moderno).
#
# Argumentos:
#   $1 — ruta absoluta al directorio del proyecto
# -----------------------------------------------------------------------------
git_init() {
  local project_dir="$1"

  cd "$project_dir"

  # -b main: nombre de la rama inicial (evita el warning de "master" por defecto)
  # -q: modo silencioso, sin output innecesario
  git init -b main -q
}

# -----------------------------------------------------------------------------
# git_first_commit
#
# Agrega todos los archivos del proyecto al staging area y hace el primer commit.
# Si por alguna razón no hay archivos que commitear, avisa y sale sin error.
#
# El mensaje de commit sigue la convención de Conventional Commits:
#   feat: para nuevas funcionalidades
#   fix:  para correcciones
#   ...etc
#
# Argumentos:
#   $1 — ruta absoluta al directorio del proyecto
# -----------------------------------------------------------------------------
git_first_commit() {
  local project_dir="$1"

  cd "$project_dir"

  # Agregar todos los archivos generados al staging area
  git add .

  # Verificar que haya algo para commitear antes de intentarlo.
  # "git diff --cached --quiet" sale con código 0 si no hay cambios staged.
  if git diff --cached --quiet; then
    echo "⚠️  Sin cambios para commitear — el directorio está vacío"
    return 0
  fi

  # Primer commit con mensaje en formato Conventional Commits
  git commit -m "feat: initial project scaffold (GenPy)" -q

  echo "✔ Repositorio git inicializado en rama main"
}
