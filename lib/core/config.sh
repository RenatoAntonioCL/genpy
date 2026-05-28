#!/usr/bin/env bash
set -euo pipefail
# =============================================================================
# GenPy — lib/core/config.sh (v1.0.0-alpha)
#
# Fuente única de verdad del sistema.
# Define blueprints, áreas, aditivos y metadatos en un solo lugar.
#
# REGLA: Ningún otro archivo debe hardcodear nombres de blueprints,
# puertos, stacks o descripciones. Todo se lee desde aquí.
# =============================================================================

[[ -n "${_GENPY_CONFIG_LOADED:-}" ]] && return 0
_GENPY_CONFIG_LOADED=1

# ─── Versión ──────────────────────────────────────────────────────────────────

readonly GENPY_VERSION="1.0.0-alpha"

# ─── Áreas disponibles ────────────────────────────────────────────────────────
#
# Formato: AREAS[id]="emoji  Nombre"
# El id es el número que el usuario ingresa en el menú principal.

declare -A AREAS=(
  [1]="🌐  Web & APIs"
  [2]="🤖  AI Labs"
  [3]="💀  Security"
  [4]="🛠️   Infra"
)
readonly AREAS

# ─── Blueprints por área ──────────────────────────────────────────────────────
#
# Formato: AREA_BLUEPRINTS[area_id]="blueprint1 blueprint2 ..."
# El orden determina el número de submenú (1, 2, 3...).

declare -A AREA_BLUEPRINTS=(
  [1]="web-fastapi-postgres web-node-nest-mongo web-go-gin-clean"
  [2]="ai-ml-pytorch ai-llm-rag"
  [3]="cyber-attacker-kali cyber-lab-victim-win7"
  [4]="infra-local-cluster infra-monitoring-stack"
)
readonly AREA_BLUEPRINTS

# ─── Metadatos de blueprints ──────────────────────────────────────────────────
#
# Formato de clave: BLUEPRINT_META[blueprint.campo]
# Campos: label, description, stack, libs, ports, lang, area_warning

declare -A BLUEPRINT_META=(
  # ── Web & APIs ──────────────────────────────────────────────────────────────
  ["web-fastapi-postgres.label"]="FastAPI + PostgreSQL"
  ["web-fastapi-postgres.hint"]="Python · SQLAlchemy · uvicorn · alembic"
  ["web-fastapi-postgres.description"]="API REST con base de datos relacional"
  ["web-fastapi-postgres.stack"]="Python 3.11  FastAPI  PostgreSQL 15  SQLAlchemy 2"
  ["web-fastapi-postgres.libs"]="uvicorn, pydantic, alembic, psycopg2-binary"
  ["web-fastapi-postgres.ports"]="8000 (API, localhost)"
  ["web-fastapi-postgres.lang"]="python"

  ["web-node-nest-mongo.label"]="NestJS + MongoDB"
  ["web-node-nest-mongo.hint"]="TypeScript · Mongoose · class-validator"
  ["web-node-nest-mongo.description"]="API REST con base de datos documental"
  ["web-node-nest-mongo.stack"]="Node 20  NestJS  TypeScript  MongoDB 7  Mongoose"
  ["web-node-nest-mongo.libs"]="@nestjs/core, class-validator, class-transformer"
  ["web-node-nest-mongo.ports"]="3000 (API, localhost)"
  ["web-node-nest-mongo.lang"]="node"

  ["web-go-gin-clean.label"]="Go + Gin"
  ["web-go-gin-clean.hint"]="Go 1.21 · GORM · MySQL · arquitectura limpia"
  ["web-go-gin-clean.description"]="API REST con arquitectura limpia"
  ["web-go-gin-clean.stack"]="Go 1.21  Gin  MySQL 8  GORM"
  ["web-go-gin-clean.libs"]="gin-gonic, gorm, godotenv"
  ["web-go-gin-clean.ports"]="8080 (API, localhost)"
  ["web-go-gin-clean.lang"]="go"

  # ── AI Labs ─────────────────────────────────────────────────────────────────
  ["ai-ml-pytorch.label"]="ML / PyTorch"
  ["ai-ml-pytorch.hint"]="PyTorch 2.3 · Jupyter Lab · numpy · scikit-learn"
  ["ai-ml-pytorch.description"]="Entorno de machine learning con notebooks"
  ["ai-ml-pytorch.stack"]="Python 3.11  PyTorch 2.3  Jupyter Lab"
  ["ai-ml-pytorch.libs"]="torch, torchvision, numpy, pandas, scikit-learn, matplotlib"
  ["ai-ml-pytorch.ports"]="8888 (Jupyter Lab, localhost)"
  ["ai-ml-pytorch.lang"]="python"

  ["ai-llm-rag.label"]="LLM RAG"
  ["ai-llm-rag.hint"]="LangChain · ChromaDB · OpenAI · tiktoken"
  ["ai-llm-rag.description"]="Pipeline de recuperación aumentada con LLMs"
  ["ai-llm-rag.stack"]="Python 3.11  LangChain  ChromaDB  OpenAI"
  ["ai-llm-rag.libs"]="langchain, chromadb, openai, tiktoken, python-dotenv"
  ["ai-llm-rag.ports"]="Sin puertos — pipeline batch"
  ["ai-llm-rag.lang"]="python"

  # ── Security ────────────────────────────────────────────────────────────────
  ["cyber-attacker-kali.label"]="Attacker (Kali)"
  ["cyber-attacker-kali.hint"]="Kali Linux · nmap · netcat · Python 3 · scapy"
  ["cyber-attacker-kali.description"]="Entorno ofensivo — solo para labs controlados"
  ["cyber-attacker-kali.stack"]="Kali Linux  Python 3  nmap  netcat"
  ["cyber-attacker-kali.libs"]="scapy, requests"
  ["cyber-attacker-kali.ports"]="Sin puertos expuestos"
  ["cyber-attacker-kali.lang"]="python"

  ["cyber-lab-victim-win7.label"]="Victim (Win7)"
  ["cyber-lab-victim-win7.hint"]="Docker Wine · Windows 7 simulado · red aislada"
  ["cyber-lab-victim-win7.description"]="Máquina víctima simulada — solo para labs controlados"
  ["cyber-lab-victim-win7.stack"]="Docker Wine  Windows 7 simulado"
  ["cyber-lab-victim-win7.libs"]="N/A"
  ["cyber-lab-victim-win7.ports"]="Red interna (lab-network)"
  ["cyber-lab-victim-win7.lang"]="infra"

  # ── Infra ───────────────────────────────────────────────────────────────────
  ["infra-local-cluster.label"]="Cluster Local"
  ["infra-local-cluster.hint"]="Traefik v3 · HTTP/HTTPS · Dashboard · Docker Compose"
  ["infra-local-cluster.description"]="Cluster local con reverse proxy y SSL"
  ["infra-local-cluster.stack"]="Traefik v3  Docker Compose"
  ["infra-local-cluster.libs"]="N/A"
  ["infra-local-cluster.ports"]="80 (HTTP, localhost)   8082 (Traefik dashboard, localhost)"
  ["infra-local-cluster.lang"]="infra"

  ["infra-monitoring-stack.label"]="Monitoring Stack"
  ["infra-monitoring-stack.hint"]="Prometheus · Grafana · métricas y alertas"
  ["infra-monitoring-stack.description"]="Stack de observabilidad completo"
  ["infra-monitoring-stack.stack"]="Prometheus  Grafana  Docker Compose"
  ["infra-monitoring-stack.libs"]="N/A"
  ["infra-monitoring-stack.ports"]="9090 (Prometheus, localhost)   3000 (Grafana, localhost)"
  ["infra-monitoring-stack.lang"]="infra"
)
readonly BLUEPRINT_META

# ─── Aditivos por blueprint ───────────────────────────────────────────────────
#
# Formato: ADDON_PACKAGES[blueprint.id]="paquete1 paquete2"
#          ADDON_LABELS[blueprint.id]="emoji Nombre → Descripción"
#
# Separar el key semántico (id) de los paquetes reales resuelve
# el bug de diseño original donde el key era los paquetes mismos.

declare -A ADDON_PACKAGES=(
  # FastAPI
  ["web-fastapi-postgres.jwt"]="passlib python-jose"
  ["web-fastapi-postgres.tasks"]="celery redis"
  ["web-fastapi-postgres.migrations"]="alembic"

  # NestJS
  ["web-node-nest-mongo.jwt"]="@nestjs/jwt passport-jwt"
  ["web-node-nest-mongo.validation"]="class-validator class-transformer"
  ["web-node-nest-mongo.swagger"]="@nestjs/swagger swagger-ui-express"

  # Go
  ["web-go-gin-clean.jwt"]="github.com/golang-jwt/jwt/v5"
  ["web-go-gin-clean.postgres"]="gorm.io/gorm gorm.io/driver/postgres"
  ["web-go-gin-clean.logger"]="go.uber.org/zap"

  # PyTorch
  ["ai-ml-pytorch.tracking"]="wandb"
  ["ai-ml-pytorch.tuning"]="optuna"
  ["ai-ml-pytorch.vision"]="torchvision"

  # RAG
  ["ai-llm-rag.langchain"]="langchain openai"
  ["ai-llm-rag.vectorstore"]="chromadb"
  ["ai-llm-rag.embeddings"]="sentence-transformers"
)
readonly ADDON_PACKAGES

declare -A ADDON_LABELS=(
  # FastAPI
  ["web-fastapi-postgres.jwt"]="🔐 JWT Auth       → Cifrado y tokens de sesión"
  ["web-fastapi-postgres.tasks"]="⚡ Async Tasks    → Cola de tareas con Redis"
  ["web-fastapi-postgres.migrations"]="🗄️  Migrations     → Control de versiones de BD"

  # NestJS
  ["web-node-nest-mongo.jwt"]="🔐 Nest JWT       → Autenticación con tokens"
  ["web-node-nest-mongo.validation"]="🛡️  Validation     → DTOs con decoradores"
  ["web-node-nest-mongo.swagger"]="📖 OpenAPI        → Documentación automática"

  # Go
  ["web-go-gin-clean.jwt"]="🔐 JWT Auth       → Tokens de sesión"
  ["web-go-gin-clean.postgres"]="🗄️  GORM           → ORM con PostgreSQL"
  ["web-go-gin-clean.logger"]="📋 Zap Logger     → Logging estructurado"

  # PyTorch
  ["ai-ml-pytorch.tracking"]="📊 Weights&Biases → Tracking de experimentos"
  ["ai-ml-pytorch.tuning"]="🔧 Optuna         → Optimización de hiperparámetros"
  ["ai-ml-pytorch.vision"]="🖼️  TorchVision    → Visión computacional"

  # RAG
  ["ai-llm-rag.langchain"]="🦜 LangChain      → Framework RAG completo"
  ["ai-llm-rag.vectorstore"]="🗄️  ChromaDB       → Vector store local"
  ["ai-llm-rag.embeddings"]="🧠 Sentence Trans → Embeddings locales"
)
readonly ADDON_LABELS

# ─── Índice de aditivos por blueprint ────────────────────────────────────────
#
# Lista ordenada de IDs de aditivos para cada blueprint.
# El orden controla los números del menú (1, 2, 3...).

declare -A ADDON_INDEX=(
  ["web-fastapi-postgres"]="jwt tasks migrations"
  ["web-node-nest-mongo"]="jwt validation swagger"
  ["web-go-gin-clean"]="jwt postgres logger"
  ["ai-ml-pytorch"]="tracking tuning vision"
  ["ai-llm-rag"]="langchain vectorstore embeddings"
)
readonly ADDON_INDEX

# ─── Área con advertencia de seguridad ───────────────────────────────────────

readonly SECURITY_AREA_ID=3
readonly SECURITY_WARNING="Estos blueprints son exclusivamente para laboratorios
     con autorización explícita. Uso en redes reales es ilegal."

# ─── Función de consulta ─────────────────────────────────────────────────────
#
# blueprint_meta <blueprint> <campo>
#
# Uso: stack=$(blueprint_meta "web-fastapi-postgres" "stack")
# Evita acceder directamente al array asociativo desde otros módulos.

blueprint_meta() {
  local blueprint="$1"
  local field="$2"
  echo "${BLUEPRINT_META[${blueprint}.${field}]:-}"
}