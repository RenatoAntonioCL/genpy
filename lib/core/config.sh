#!/usr/bin/env bash
set -euo pipefail
# =============================================================================
# GenPy — lib/core/config.sh (v1.0.0-alpha)
#
# Single source of truth for the system.
# Defines blueprints, areas, add-ons and metadata in a single place.
#
# RULE: No other file should hardcode blueprint names,
# ports, stacks or descriptions. Everything is read from here.
# =============================================================================

[[ -n "${_GENPY_CONFIG_LOADED:-}" ]] && return 0
_GENPY_CONFIG_LOADED=1

# ─── Version ──────────────────────────────────────────────────────────────────

readonly GENPY_VERSION="1.0.0-alpha"

# ─── Available areas ──────────────────────────────────────────────────────────
#
# Format: AREAS[id]="emoji  Name"
# The id is the number the user enters in the main menu.

declare -A AREAS=(
  [1]="🌐  Web & APIs"
  [2]="🤖  AI Labs"
  [3]="💀  Security"
  [4]="🛠️   Infra"
)
readonly AREAS

# ─── Blueprints by area ───────────────────────────────────────────────────────
#
# Format: AREA_BLUEPRINTS[area_id]="blueprint1 blueprint2 ..."
# The order determines the submenu number (1, 2, 3...).

declare -A AREA_BLUEPRINTS=(
  [1]="web-fastapi-postgres web-node-nest-mongo web-go-gin-clean"
  [2]="ai-ml-pytorch ai-llm-rag"
  [3]="cyber-attacker-kali cyber-lab-victim-win7"
  [4]="infra-local-cluster infra-monitoring-stack"
)
readonly AREA_BLUEPRINTS

# ─── Blueprint metadata ───────────────────────────────────────────────────────
#
# Key format: BLUEPRINT_META[blueprint.field]
# Fields: label, description, stack, libs, ports, lang, area_warning

declare -A BLUEPRINT_META=(
  # ── Web & APIs ──────────────────────────────────────────────────────────────
  ["web-fastapi-postgres.label"]="FastAPI + PostgreSQL"
  ["web-fastapi-postgres.hint"]="Python · SQLAlchemy · uvicorn · alembic"
  ["web-fastapi-postgres.description"]="REST API with relational database"
  ["web-fastapi-postgres.stack"]="Python 3.11  FastAPI  PostgreSQL 15  SQLAlchemy 2"
  ["web-fastapi-postgres.libs"]="uvicorn, pydantic, alembic, psycopg2-binary"
  ["web-fastapi-postgres.ports"]="8000 (API, localhost)"
  ["web-fastapi-postgres.lang"]="python"

  ["web-node-nest-mongo.label"]="NestJS + MongoDB"
  ["web-node-nest-mongo.hint"]="TypeScript · Mongoose · class-validator"
  ["web-node-nest-mongo.description"]="REST API with document database"
  ["web-node-nest-mongo.stack"]="Node 20  NestJS  TypeScript  MongoDB 7  Mongoose"
  ["web-node-nest-mongo.libs"]="@nestjs/core, class-validator, class-transformer"
  ["web-node-nest-mongo.ports"]="3000 (API, localhost)"
  ["web-node-nest-mongo.lang"]="node"

  ["web-go-gin-clean.label"]="Go + Gin"
  ["web-go-gin-clean.hint"]="Go 1.21 · GORM · MySQL · clean architecture"
  ["web-go-gin-clean.description"]="REST API with clean architecture"
  ["web-go-gin-clean.stack"]="Go 1.21  Gin  MySQL 8  GORM"
  ["web-go-gin-clean.libs"]="gin-gonic, gorm, godotenv"
  ["web-go-gin-clean.ports"]="8080 (API, localhost)"
  ["web-go-gin-clean.lang"]="go"

  # ── AI Labs ─────────────────────────────────────────────────────────────────
  ["ai-ml-pytorch.label"]="ML / PyTorch"
  ["ai-ml-pytorch.hint"]="PyTorch 2.3 · Jupyter Lab · numpy · scikit-learn"
  ["ai-ml-pytorch.description"]="Machine learning environment with notebooks"
  ["ai-ml-pytorch.stack"]="Python 3.11  PyTorch 2.3  Jupyter Lab"
  ["ai-ml-pytorch.libs"]="torch, torchvision, numpy, pandas, scikit-learn, matplotlib"
  ["ai-ml-pytorch.ports"]="8888 (Jupyter Lab, localhost)"
  ["ai-ml-pytorch.lang"]="python"

  ["ai-llm-rag.label"]="LLM RAG"
  ["ai-llm-rag.hint"]="LangChain · ChromaDB · OpenAI · tiktoken"
  ["ai-llm-rag.description"]="Retrieval-augmented pipeline with LLMs"
  ["ai-llm-rag.stack"]="Python 3.11  LangChain  ChromaDB  OpenAI"
  ["ai-llm-rag.libs"]="langchain, chromadb, openai, tiktoken, python-dotenv"
  ["ai-llm-rag.ports"]="Sin puertos — pipeline batch"
  ["ai-llm-rag.lang"]="python"

  # ── Security ────────────────────────────────────────────────────────────────
  ["cyber-attacker-kali.label"]="Attacker (Kali)"
  ["cyber-attacker-kali.hint"]="Kali Linux · nmap · netcat · Python 3 · scapy"
  ["cyber-attacker-kali.description"]="Offensive environment — for authorized labs only"
  ["cyber-attacker-kali.stack"]="Kali Linux  Python 3  nmap  netcat"
  ["cyber-attacker-kali.libs"]="scapy, requests"
  ["cyber-attacker-kali.ports"]="Sin puertos expuestos"
  ["cyber-attacker-kali.lang"]="python"

  ["cyber-lab-victim-win7.label"]="Victim (Win7)"
  ["cyber-lab-victim-win7.hint"]="Docker Wine · simulated Windows 7 · isolated network"
  ["cyber-lab-victim-win7.description"]="Simulated victim machine — for authorized labs only"
  ["cyber-lab-victim-win7.stack"]="Docker Wine  Windows 7 simulado"
  ["cyber-lab-victim-win7.libs"]="N/A"
  ["cyber-lab-victim-win7.ports"]="Red interna (lab-network)"
  ["cyber-lab-victim-win7.lang"]="infra"

  # ── Infra ───────────────────────────────────────────────────────────────────
  ["infra-local-cluster.label"]="Cluster Local"
  ["infra-local-cluster.hint"]="Traefik v3 · HTTP/HTTPS · Dashboard · Docker Compose"
  ["infra-local-cluster.description"]="Local cluster with reverse proxy and SSL"
  ["infra-local-cluster.stack"]="Traefik v3  Docker Compose"
  ["infra-local-cluster.libs"]="N/A"
  ["infra-local-cluster.ports"]="80 (HTTP, localhost)   8082 (Traefik dashboard, localhost)"
  ["infra-local-cluster.lang"]="infra"

  ["infra-monitoring-stack.label"]="Monitoring Stack"
  ["infra-monitoring-stack.hint"]="Prometheus · Grafana · metrics and alerts"
  ["infra-monitoring-stack.description"]="Complete observability stack"
  ["infra-monitoring-stack.stack"]="Prometheus  Grafana  Docker Compose"
  ["infra-monitoring-stack.libs"]="N/A"
  ["infra-monitoring-stack.ports"]="9090 (Prometheus, localhost)   3000 (Grafana, localhost)"
  ["infra-monitoring-stack.lang"]="infra"
)
readonly BLUEPRINT_META

# ─── Add-ons by blueprint ─────────────────────────────────────────────────────
#
# Format: ADDON_PACKAGES[blueprint.id]="package1 package2"
#          ADDON_LABELS[blueprint.id]="emoji Name → Description"
#
# Separating the semantic key (id) from the real packages resolves
# the original design bug where the key was the packages themselves.

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
  ["web-fastapi-postgres.jwt"]="🔐 JWT Auth       → Encryption and session tokens"
  ["web-fastapi-postgres.tasks"]="⚡ Async Tasks    → Task queue with Redis"
  ["web-fastapi-postgres.migrations"]="🗄️  Migrations     → Database version control"

  # NestJS
  ["web-node-nest-mongo.jwt"]="🔐 Nest JWT       → Token-based authentication"
  ["web-node-nest-mongo.validation"]="🛡️  Validation     → DTOs with decorators"
  ["web-node-nest-mongo.swagger"]="📖 OpenAPI        → Automatic documentation"

  # Go
  ["web-go-gin-clean.jwt"]="🔐 JWT Auth       → Session tokens"
  ["web-go-gin-clean.postgres"]="🗄️  GORM           → ORM with PostgreSQL"
  ["web-go-gin-clean.logger"]="📋 Zap Logger     → Structured logging"

  # PyTorch
  ["ai-ml-pytorch.tracking"]="📊 Weights&Biases → Experiment tracking"
  ["ai-ml-pytorch.tuning"]="🔧 Optuna         → Hyperparameter optimization"
  ["ai-ml-pytorch.vision"]="🖼️  TorchVision    → Computer vision"

  # RAG
  ["ai-llm-rag.langchain"]="🦜 LangChain      → Full RAG framework"
  ["ai-llm-rag.vectorstore"]="🗄️  ChromaDB       → Local vector store"
  ["ai-llm-rag.embeddings"]="🧠 Sentence Trans → Local embeddings"
)
readonly ADDON_LABELS

# ─── Add-on index by blueprint ────────────────────────────────────────────────
#
# Ordered list of add-on IDs for each blueprint.
# The order controls the menu numbers (1, 2, 3...).

declare -A ADDON_INDEX=(
  ["web-fastapi-postgres"]="jwt tasks migrations"
  ["web-node-nest-mongo"]="jwt validation swagger"
  ["web-go-gin-clean"]="jwt postgres logger"
  ["ai-ml-pytorch"]="tracking tuning vision"
  ["ai-llm-rag"]="langchain vectorstore embeddings"
)
readonly ADDON_INDEX

# ─── Area with security warning ──────────────────────────────────────────────

readonly SECURITY_AREA_ID=3
readonly SECURITY_WARNING="These blueprints are exclusively for authorized
     labs. Use on real networks is illegal."

# ─── Query function ───────────────────────────────────────────────────────────
#
# blueprint_meta <blueprint> <field>
#
# Usage: stack=$(blueprint_meta "web-fastapi-postgres" "stack")
# Avoids direct access to the associative array from other modules.

blueprint_meta() {
  local blueprint="$1"
  local field="$2"
  echo "${BLUEPRINT_META[${blueprint}.${field}]:-}"
}
