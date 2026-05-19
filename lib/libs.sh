#!/opt/homebrew/bin/bash
set -euo pipefail

# =============================================================================
# GenPy — lib/libs.sh (v4.0.0)
#
# Catálogo y motor de inyección de aditivos por blueprint.
#
# Bug corregido: inject_blueprint_addons recibía los keys del diccionario
# asociativo (strings como "passlib python-jose") pero hacía case "$choice"
# comparando contra números (1, 2, 3). Nunca hacía match. Ahora el motor
# trabaja directamente con los strings de paquetes, sin re-mapear a números.
# =============================================================================

# ─── Catálogos de aditivos por blueprint ─────────────────────────────────────
#
# Formato de cada entrada:
#   key   = paquetes a instalar (separados por espacio si son varios)
#   value = descripción para el menú
#
# Para agregar un aditivo nuevo: añadir una entrada al diccionario
# y manejar su inyección en _inject_* correspondiente.

declare -A ADDONS_WEB_FASTAPI=(
  ["passlib python-jose"]="🔐 JWT Auth       → Cifrado y tokens de sesión"
  ["celery redis"]="⚡ Async Tasks    → Cola de tareas con Redis"
  ["alembic"]="🗄️  Migrations     → Control de versiones de BD"
)
readonly ADDONS_WEB_FASTAPI

declare -A ADDONS_WEB_NESTJS=(
  ["@nestjs/jwt passport-jwt"]="🔐 Nest JWT       → Autenticación con tokens"
  ["class-validator class-transformer"]="🛡️  Validation     → DTOs con decoradores"
  ["@nestjs/swagger swagger-ui-express"]="📖 OpenAPI        → Documentación automática"
)
readonly ADDONS_WEB_NESTJS

declare -A ADDONS_WEB_GO=(
  ["github.com/golang-jwt/jwt/v5"]="🔐 JWT Auth       → Tokens de sesión"
  ["gorm.io/gorm gorm.io/driver/postgres"]="🗄️  GORM           → ORM con PostgreSQL"
  ["go.uber.org/zap"]="📋 Zap Logger     → Logging estructurado"
)
readonly ADDONS_WEB_GO

declare -A ADDONS_AI_PYTORCH=(
  ["wandb"]="📊 Weights&Biases → Tracking de experimentos"
  ["optuna"]="🔧 Optuna         → Optimización de hiperparámetros"
  ["torchvision"]="🖼️  TorchVision    → Visión computacional"
)
readonly ADDONS_AI_PYTORCH

declare -A ADDONS_AI_RAG=(
  ["langchain openai"]="🦜 LangChain      → Framework RAG completo"
  ["chromadb"]="🗄️  ChromaDB       → Vector store local"
  ["sentence-transformers"]="🧠 Sentence Trans → Embeddings locales"
)
readonly ADDONS_AI_RAG

# Security e Infra no tienen aditivos — sus blueprints son entornos cerrados

# ─── Función pública: select_blueprint_addons ─────────────────────────────────

# -----------------------------------------------------------------------------
# select_blueprint_addons
#
# Muestra el menú de aditivos correspondiente al blueprint elegido y
# guarda las selecciones en el array del llamador.
#
# Argumentos:
#   $1 — nombre del array donde guardar los aditivos elegidos (nameref)
#   $2 — blueprint: nombre del blueprint activo
# -----------------------------------------------------------------------------
select_blueprint_addons() {
  local -n _dest_array="$1"
  local blueprint="$2"

  # Seleccionar el catálogo correspondiente al blueprint
  local -n current_catalog
  case "$blueprint" in
    "web-fastapi-postgres") current_catalog=ADDONS_WEB_FASTAPI  ;;
    "web-node-nest-mongo")  current_catalog=ADDONS_WEB_NESTJS   ;;
    "web-go-gin-clean")     current_catalog=ADDONS_WEB_GO       ;;
    "ai-ml-pytorch")        current_catalog=ADDONS_AI_PYTORCH   ;;
    "ai-llm-rag")           current_catalog=ADDONS_AI_RAG       ;;
    *)
      # Security e Infra no tienen aditivos configurables
      return 0
      ;;
  esac

  echo -e "\n⚡ ¿Deseas añadir aditivos a tu proyecto?"

  # Construir array ordenado de keys para el menú
  local -a keys=("${!current_catalog[@]}")

  for i in "${!keys[@]}"; do
    printf "  %d) %s\n" "$((i+1))" "${current_catalog[${keys[$i]}]}"
  done
  echo "  0) Ninguno"

  read -rp "👉 Selecciona (ej: 1 2): " input

  for item in $input; do
    # Validar que sea número en rango
    if [[ "$item" == "0" ]]; then
      break
    elif [[ "$item" =~ ^[0-9]+$ ]] && (( item >= 1 && item <= ${#keys[@]} )); then
      # Guardar el KEY del diccionario (los paquetes reales), no el número
      _dest_array+=("${keys[$((item - 1))]}")
    else
      print_warning "Opción '$item' fuera de rango — ignorada"
    fi
  done
}

# ─── Funciones internas de inyección ─────────────────────────────────────────

# _inject_python_addons: agrega paquetes al requirements.txt
_inject_python_addons() {
  local target_dir="$1"
  local packages="$2"   # string con paquetes separados por espacio

  local req_file="$target_dir/backend/requirements.txt"
  [[ ! -f "$req_file" ]] && req_file="$target_dir/requirements.txt"

  if [[ ! -f "$req_file" ]]; then
    print_warning "No se encontró requirements.txt — se omite inyección de: $packages"
    return 0
  fi

  for pkg in $packages; do
    # Evitar duplicados
    if ! grep -q "^${pkg}" "$req_file"; then
      echo "$pkg" >> "$req_file"
    fi
  done
}

# _inject_node_addons: agrega paquetes al dependencies de package.json
_inject_node_addons() {
  local target_dir="$1"
  local packages="$2"

  local pkg_file="$target_dir/backend/package.json"
  [[ ! -f "$pkg_file" ]] && pkg_file="$target_dir/package.json"

  if [[ ! -f "$pkg_file" ]]; then
    print_warning "No se encontró package.json — se omite inyección de: $packages"
    return 0
  fi

  for pkg in $packages; do
    if ! grep -q "\"$pkg\"" "$pkg_file"; then
      _sed_inplace "/\"dependencies\": {/a\\
    \"$pkg\": \"latest\"," "$pkg_file"
    fi
  done
}

# _inject_go_addons: agrega módulos al go.mod via go get (requiere go instalado)
_inject_go_addons() {
  local target_dir="$1"
  local packages="$2"

  local go_mod="$target_dir/backend/go.mod"
  [[ ! -f "$go_mod" ]] && go_mod="$target_dir/go.mod"

  if [[ ! -f "$go_mod" ]]; then
    print_warning "No se encontró go.mod — se omite inyección de: $packages"
    return 0
  fi

  if ! command -v go &>/dev/null; then
    print_warning "Go no está instalado — registrando dependencias en .genpy_go_deps"
    printf "%s\n" $packages > "$target_dir/.genpy_go_deps"
    return 0
  fi

  local mod_dir
  mod_dir="$(dirname "$go_mod")"

  for pkg in $packages; do
    (cd "$mod_dir" && go get "$pkg" 2>/dev/null) || \
      print_warning "No se pudo instalar $pkg — agrégalo manualmente con: go get $pkg"
  done
}

# ─── Función pública: inject_blueprint_addons ────────────────────────────────

# -----------------------------------------------------------------------------
# inject_blueprint_addons
#
# Inyecta los aditivos seleccionados en los archivos de dependencias
# del proyecto según el lenguaje del blueprint.
#
# Bug corregido: ahora itera sobre los keys del diccionario (paquetes reales)
# en lugar de números, eliminando el mismatch del case anterior.
#
# Argumentos:
#   $1 — target_dir:     ruta absoluta al directorio del proyecto
#   $2 — nombre del array con los aditivos seleccionados (nameref)
#   $3 — blueprint:      nombre del blueprint activo
# -----------------------------------------------------------------------------
inject_blueprint_addons() {
  local target_dir="$1"
  local -n _addons_ref="$2"
  local blueprint="$3"

  [[ ${#_addons_ref[@]} -eq 0 ]] && return 0

  echo -e "\n💉 Inyectando aditivos..."

  for packages in "${_addons_ref[@]}"; do
    echo "   + $packages"

    case "$blueprint" in
      "web-fastapi-postgres" | "ai-ml-pytorch" | "ai-llm-rag")
        _inject_python_addons "$target_dir" "$packages"
        ;;
      "web-node-nest-mongo")
        _inject_node_addons "$target_dir" "$packages"
        ;;
      "web-go-gin-clean")
        _inject_go_addons "$target_dir" "$packages"
        ;;
    esac
  done

  print_success "Aditivos inyectados correctamente."
}

