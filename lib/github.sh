#!/opt/homebrew/bin/bash
set -euo pipefail

# =============================================================================
# GenPy — lib/github.sh
#
# Automatiza la creación de repositorios remotos en GitHub y realiza el
# primer push utilizando la herramienta oficial GitHub CLI (gh).
# =============================================================================

# -----------------------------------------------------------------------------
# push_to_github
#
# Valida el estado del entorno (instalación y autenticación de 'gh') y
# publica el repositorio local en la cuenta de GitHub del usuario.
#
# Argumentos:
#   $1 — project_dir:  Ruta absoluta al proyecto local
#   $2 — project_name: Nombre del repositorio remoto en GitHub
#   $3 — is_private:   Booleano (true/false) para configurar la visibilidad
# -----------------------------------------------------------------------------
push_to_github() {
  local project_dir="$1"
  local project_name="$2"
  local is_private="$3"

  # Navegar al directorio para que los comandos 'gh' y 'git' apunten al repo correcto
  cd "$project_dir"

  # ── Validación 1: Verificar existencia de GitHub CLI ──────────────────────
  if ! command -v gh &>/dev/null; then
    echo "⚠️  GitHub CLI (gh) no está instalado — se omite la subida al remoto"
    echo "   Sugerencia: Ejecuta 'brew install gh' o visita https://cli.github.com"
    return 0
  fi

  # ── Validación 2: Verificar sesión activa en GitHub ────────────────────────
  # 'gh auth status' devuelve un código de salida != 0 si el token no es válido o no existe
  if ! gh auth status &>/dev/null; then
    echo "⚠️  No estás autenticado en GitHub CLI — se omite la subida al remoto"
    echo "   Sugerencia: Ejecuta 'gh auth login' en tu terminal antes de usar esta opción"
    return 0
  fi

  # ── Configurar visibilidad del repositorio ─────────────────────────────────
  local visibility_flag="--public"
  if [[ "$is_private" == true ]]; then
    visibility_flag="--private"
  fi

  echo "🐙 Creando repositorio remoto: $project_name"

  # ── Creación y Sincronización Remota ───────────────────────────────────────
  # --source=.  -> Vincula el directorio local actual
  # --push      -> Ejecuta el 'git push origin main' automáticamente tras crear el remoto
  # -y          -> Acepta todos los prompts por defecto (modo no-interactivo)
  if gh repo create "$project_name" "$visibility_flag" --source=. --push -y &>/dev/null; then
    echo "✔ Repositorio sincronizado en GitHub con éxito"
  else
    echo "❌ Error al crear el repositorio en GitHub"
    echo "   Verifica que no exista un repositorio con el mismo nombre en tu cuenta"
  fi
}
