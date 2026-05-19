#!/opt/homebrew/bin/bash
set -euo pipefail

# =============================================================================
# GenPy — lib/git_manager.sh (v4.1.0)
#
# Gestión del repositorio git del proyecto generado.
# Git siempre se inicializa — la pregunta es solo sobre el remoto.
#
# Retorna la elección del usuario en GIT_MODE (local | private | public)
# para que wizard.sh pueda mostrarla en la tarjeta de resumen antes de fabricar.
# =============================================================================

# Importar utils solo si aún no fue cargado
if ! declare -f print_success &>/dev/null; then
  source "$LIB_DIR/utils.sh"
fi

# Variable global que wizard.sh lee para el resumen previo a la confirmación
GIT_MODE="local"

# -----------------------------------------------------------------------------
# select_git_mode
#
# Pregunta al usuario cómo quiere gestionar el repositorio y guarda
# la elección en GIT_MODE. Se llama ANTES de fabricar el proyecto
# para incluir la info en el resumen de confirmación.
# -----------------------------------------------------------------------------
select_git_mode() {
  print_section "Control de Versiones (Git)"

  echo -e "  ${WHITE}1)${NC} 💻  Solo local       ${DIM}— git init sin remoto${NC}"
  echo -e "  ${WHITE}2)${NC} 🔐  Remoto privado    ${DIM}— push a repo privado en GitHub${NC}"
  echo -e "  ${WHITE}3)${NC} 🌐  Remoto público    ${DIM}— push a repo público en GitHub${NC}"
  echo ""

  while true; do
    read -rp "  >>> " git_choice
    case "$git_choice" in
      1) GIT_MODE="local";   break ;;
      2) GIT_MODE="private"; break ;;
      3) GIT_MODE="public";  break ;;
      *) print_warning "Elige 1, 2 o 3." ;;
    esac
  done
}

# -----------------------------------------------------------------------------
# setup_git_repository
#
# Ejecuta el flujo git completo en el directorio del proyecto ya creado.
# Si el modo es privado o público, pide la URL del remoto y hace el push.
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

  # Inicializar en rama main (estándar moderno, evita el warning de "master")
  git init -b main -q

  # .gitignore estándar que cubre todos los blueprints disponibles
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

  # Primer commit en formato Conventional Commits
  git commit -m "feat: initial project scaffold — $project_name (GenPy v4.1.0)" -q
  print_success "Repositorio inicializado en rama main"

  # ── Modo remoto ───────────────────────────────────────────────────────────
  if [[ "$GIT_MODE" == "private" || "$GIT_MODE" == "public" ]]; then

    local visibility
    [[ "$GIT_MODE" == "private" ]] && visibility="PRIVADO" || visibility="PÚBLICO"

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

    git remote add origin "$repo_url"
    git branch -M main

    echo -e "  📤 Subiendo a repositorio $visibility..."
    if git push -u origin main 2>/dev/null; then
      print_success "Código subido a repositorio $visibility exitosamente."
    else
      print_error "Fallo al subir. Verifica tus llaves SSH o token de acceso."
      echo -e "  ${DIM}Para reintentar: git push -u origin main${NC}"
    fi
  fi
}