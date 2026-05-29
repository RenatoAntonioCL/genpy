#!/usr/bin/env bash
set -euo pipefail

# =============================================================================
# GenPy — lib/git_manager.sh (v1.0.0-alpha)
#
# Gestión del repositorio git del proyecto generado.
# Git siempre se inicializa — la pregunta es solo sobre el remoto.
#
# Retorna la elección del usuario en GIT_MODE (local | private | public)
# para que wizard.sh pueda mostrarla en la tarjeta de resumen antes de fabricar.
# =============================================================================

source "${LIB_DIR:?}/utils.sh"

# Variable global que wizard.sh lee para el resumen previo a la confirmación
GIT_MODE="local"

# -----------------------------------------------------------------------------
# _get_github_token
#
# Busca un token de GitHub en: GITHUB_TOKEN, GH_TOKEN, o el CLI `gh`.
# Imprime el token si lo encuentra; retorna 1 si no hay ninguno disponible.
# -----------------------------------------------------------------------------
_get_github_token() {
  [[ -n "${GITHUB_TOKEN:-}" ]] && { printf '%s' "$GITHUB_TOKEN"; return 0; }
  [[ -n "${GH_TOKEN:-}" ]]     && { printf '%s' "$GH_TOKEN";     return 0; }
  if command -v gh &>/dev/null; then
    local token
    token=$(gh auth token 2>/dev/null) && [[ -n "$token" ]] && { printf '%s' "$token"; return 0; }
  fi
  return 1
}

# -----------------------------------------------------------------------------
# _create_github_repo
#
# Crea un repositorio en GitHub via API REST.
#
# Argumentos:
#   $1 — token:        Personal Access Token con permisos 'repo'
#   $2 — repo_name:    nombre del repositorio a crear
#   $3 — private_flag: "true" o "false"
#
# Imprime la SSH URL del repositorio creado; retorna 1 en caso de error.
# -----------------------------------------------------------------------------
_create_github_repo() {
  local token="$1"
  local repo_name="$2"
  local private_flag="$3"

  local json_body
  json_body=$(printf '{"name":"%s","private":%s,"auto_init":false}' \
    "$repo_name" "$private_flag")

  local tmpfile http_code body
  tmpfile=$(mktemp)
  http_code=$(curl -s -o "$tmpfile" -w "%{http_code}" \
    -X POST \
    -H "Authorization: token $token" \
    -H "Accept: application/vnd.github.v3+json" \
    -H "Content-Type: application/json" \
    -d "$json_body" \
    https://api.github.com/user/repos 2>/dev/null)
  body=$(cat "$tmpfile")
  rm -f "$tmpfile"

  if [[ "$http_code" == "201" ]]; then
    if command -v jq &>/dev/null; then
      printf '%s' "$body" | jq -r '.ssh_url'
    else
      printf '%s' "$body" | grep -o '"ssh_url":"[^"]*"' | cut -d'"' -f4
    fi
    return 0
  else
    local err_msg="HTTP $http_code"
    if command -v jq &>/dev/null; then
      local api_msg
      api_msg=$(printf '%s' "$body" | jq -r '.message // empty' 2>/dev/null)
      [[ -n "$api_msg" ]] && err_msg="$api_msg"
    fi
    print_error "GitHub API: $err_msg"
    return 1
  fi
}

# -----------------------------------------------------------------------------
# _push_to_remote
#
# Conecta el remoto y hace push. Muestra instrucciones de reintento si falla.
# -----------------------------------------------------------------------------
_push_to_remote() {
  local repo_url="$1"
  local visibility="$2"

  git remote add origin "$repo_url"
  git branch -M main

  echo -e "  📤 Subiendo a repositorio $visibility..."
  if git push -u origin main -q; then
    print_success "Código subido a repositorio $visibility: $repo_url"
  else
    print_error "Fallo al subir. Verifica tus llaves SSH o token de acceso."
    echo -e "  ${DIM}Para reintentar: git push -u origin main${NC}"
  fi
}

# -----------------------------------------------------------------------------
# setup_git_repository
#
# Ejecuta el flujo git completo en el directorio del proyecto ya creado.
# Para modo privado/público intenta crear el repo en GitHub vía API
# (leyendo GITHUB_TOKEN / GH_TOKEN / gh CLI). Si no hay token disponible
# pregunta al usuario; si prefiere omitirlo, cae al flujo manual con URL.
#
# Argumentos:
#   $1 — target_dir:    ruta absoluta al directorio del proyecto
#   $2 — project_name:  nombre del proyecto
# -----------------------------------------------------------------------------
setup_git_repository() {
  local target_dir="$1"
  local project_name="$2"

  print_section "Inicializando Repositorio"

  cd "$target_dir" || {
    print_error "No se pudo acceder al directorio: $target_dir"
    return 1
  }

  git init -b main -q

  cat > .gitignore <<'EOF'
# Dependencias
node_modules/
vendor/

# Builds y compilados
dist/
target/
*.exe

# Variables de entorno — nunca subir al repositorio
.env
.env.local
.env.*.local

# Entornos virtuales Python
env/
venv/

# macOS
.DS_Store

# Logs
*.log

# GenPy — archivos de trabajo interno
.genpy_*
EOF

  git add .

  if git diff --cached --quiet; then
    print_warning "Sin cambios para commitear — directorio vacío"
    return 0
  fi

  git commit -m "feat: initial project scaffold — $project_name (GenPy v1.0.0-alpha)" -q
  print_success "Repositorio inicializado en rama main"

  # ── Modo remoto ───────────────────────────────────────────────────────────
  [[ "$GIT_MODE" != "private" && "$GIT_MODE" != "public" ]] && return 0

  local visibility private_flag
  if [[ "$GIT_MODE" == "private" ]]; then
    visibility="PRIVADO"
    private_flag="true"
  else
    visibility="PÚBLICO"
    private_flag="false"
  fi

  echo ""

  # ── Intentar crear el repositorio automáticamente via API ─────────────────
  if ! command -v curl &>/dev/null; then
    print_warning "curl no está instalado — se omite la creación automática."
    _fallback_manual_remote "$visibility"
    return 0
  fi

  local token=""
  token=$(_get_github_token 2>/dev/null) || true

  if [[ -z "$token" ]]; then
    echo -e "  ${DIM}No se encontró GITHUB_TOKEN. Ingresa tu Personal Access Token${NC}"
    echo -e "  ${DIM}(permisos 'repo' requeridos — deja vacío para ingresar URL manualmente):${NC}"
    IFS= read -rsp "  >>> " token
    echo ""
  fi

  if [[ -z "$token" ]]; then
    _fallback_manual_remote "$visibility"
    return 0
  fi

  echo -e "  🌐 Creando repositorio $visibility en GitHub..."
  local repo_url
  if repo_url=$(_create_github_repo "$token" "$project_name" "$private_flag"); then
    _push_to_remote "$repo_url" "$visibility"
  else
    print_warning "Creación automática fallida — ingresa la URL manualmente."
    _fallback_manual_remote "$visibility"
  fi
}

# -----------------------------------------------------------------------------
# _fallback_manual_remote  (interno)
# -----------------------------------------------------------------------------
_fallback_manual_remote() {
  local visibility="$1"
  echo ""
  echo -e "  ${DIM}Ingresa la URL del repositorio remoto:${NC}"
  echo -e "  ${DIM}(ej: git@github.com:usuario/repo.git)${NC}"
  read -rp "  >>> " repo_url

  if [[ -z "$repo_url" ]]; then
    print_warning "URL vacía — se omite el push. Puedes conectarlo manualmente:"
    echo -e "  ${DIM}git remote add origin <url>${NC}"
    echo -e "  ${DIM}git push -u origin main${NC}"
    return 0
  fi

  _push_to_remote "$repo_url" "$visibility"
}

# =============================================================================
# Checkpoint de revisión IA — pasos [2] y [10] del flujo genpy review
# (ARCHITECTURE.md §5.4)
#
# Globals de salida:
#   CHECKPOINT_BRANCH           — rama de revisión creada (genpy/review/<ts>)
#   CHECKPOINT_ORIGINAL_BRANCH  — rama donde estaba antes del checkpoint
# =============================================================================

CHECKPOINT_BRANCH=""
CHECKPOINT_ORIGINAL_BRANCH=""

# -----------------------------------------------------------------------------
# create_checkpoint
#
# Crea una rama de revisión desde la rama actual y cambia a ella.
# La rama actúa como punto seguro de retorno: si la revisión IA falla o
# el usuario la rechaza, rollback_to_checkpoint devuelve el proyecto al
# estado anterior sin tocar ningún archivo vivo.
#
# Argumentos:
#   $1 — project_dir:    ruta absoluta al repositorio del proyecto
#   $2 — branch_prefix:  prefijo de la rama (default: genpy/review)
#
# Sets: CHECKPOINT_BRANCH, CHECKPOINT_ORIGINAL_BRANCH
# Returns: 0=ok, 1=error
# -----------------------------------------------------------------------------
create_checkpoint() {
  local project_dir="$1"
  local branch_prefix="${2:-genpy/review}"

  # ── Validaciones ──────────────────────────────────────────────────────────

  if [[ ! -d "$project_dir" ]]; then
    echo "Error: directorio no encontrado: $project_dir" >&2
    return 1
  fi

  if ! git -C "$project_dir" rev-parse --git-dir &>/dev/null 2>&1; then
    echo "Error: no es un repositorio git: $project_dir" >&2
    return 1
  fi

  if ! git -C "$project_dir" rev-parse --verify HEAD &>/dev/null 2>&1; then
    echo "Error: el repositorio no tiene commits — haz al menos un commit antes." >&2
    return 1
  fi

  local original_branch
  original_branch=$(git -C "$project_dir" branch --show-current 2>/dev/null)
  if [[ -z "$original_branch" ]]; then
    echo "Error: HEAD en estado detached — cambia a una rama antes de crear el checkpoint." >&2
    return 1
  fi

  if ! git -C "$project_dir" diff --quiet HEAD 2>/dev/null; then
    echo "Error: el árbol de trabajo tiene cambios sin commitear — haz commit o stash primero." >&2
    return 1
  fi

  # ── Crear rama de revisión ────────────────────────────────────────────────

  local timestamp review_branch
  timestamp=$(date +%Y%m%d_%H%M%S)
  review_branch="${branch_prefix}/${timestamp}"

  if ! git -C "$project_dir" checkout -b "$review_branch" -q 2>/dev/null; then
    echo "Error: no se pudo crear la rama '${review_branch}'." >&2
    return 1
  fi

  CHECKPOINT_BRANCH="$review_branch"
  CHECKPOINT_ORIGINAL_BRANCH="$original_branch"

  print_success "Checkpoint: rama '${review_branch}' creada desde '${original_branch}'"
  return 0
}

# -----------------------------------------------------------------------------
# rollback_to_checkpoint
#
# Vuelve a la rama original y elimina la rama de revisión.
# Seguro incluso si la rama de revisión tiene cambios sin commitear:
# usa -D (force delete) porque el árbol original permanece intacto en HEAD.
#
# Argumentos:
#   $1 — project_dir: ruta absoluta al repositorio del proyecto
#
# Requires: CHECKPOINT_BRANCH y CHECKPOINT_ORIGINAL_BRANCH (set by create_checkpoint)
# Returns: 0=ok, 1=error
# -----------------------------------------------------------------------------
rollback_to_checkpoint() {
  local project_dir="$1"

  if [[ ! -d "$project_dir" ]]; then
    echo "Error: directorio no encontrado: $project_dir" >&2
    return 1
  fi

  if [[ -z "${CHECKPOINT_BRANCH:-}" ]]; then
    echo "Error: CHECKPOINT_BRANCH no definido — llama create_checkpoint primero." >&2
    return 1
  fi

  if [[ -z "${CHECKPOINT_ORIGINAL_BRANCH:-}" ]]; then
    echo "Error: CHECKPOINT_ORIGINAL_BRANCH no definido." >&2
    return 1
  fi

  # ── Volver a la rama original ─────────────────────────────────────────────

  if ! git -C "$project_dir" checkout "$CHECKPOINT_ORIGINAL_BRANCH" -q 2>/dev/null; then
    echo "Error: no se pudo volver a la rama '${CHECKPOINT_ORIGINAL_BRANCH}'." >&2
    return 1
  fi

  # ── Eliminar rama de revisión (force — puede tener trabajo sin commitear) ─

  local deleted_branch="$CHECKPOINT_BRANCH"
  local original_branch="$CHECKPOINT_ORIGINAL_BRANCH"
  if git -C "$project_dir" show-ref --verify --quiet \
      "refs/heads/${CHECKPOINT_BRANCH}" 2>/dev/null; then
    git -C "$project_dir" branch -D "$CHECKPOINT_BRANCH" -q 2>/dev/null || true
  fi

  CHECKPOINT_BRANCH=""
  CHECKPOINT_ORIGINAL_BRANCH=""

  print_success "Rollback: de vuelta en '${original_branch}', rama '${deleted_branch}' eliminada"
  return 0
}