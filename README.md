<div align="center">

# GenPy

### Proyectos Docker listos para correr, en una sola orden.

GenPy genera **9 stacks oficiales** (web · AI · infra · security) con **credenciales
únicas por proyecto** ya inyectadas. Sin `changeme`, sin placeholders, sin cablear el
`.env` a mano.

[![CI](https://github.com/RenatoAntonioCL/genpy/actions/workflows/ci.yml/badge.svg)](https://github.com/RenatoAntonioCL/genpy/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/license-MIT-green.svg)](./LICENSE)
[![Version](https://img.shields.io/badge/version-1.0.0--alpha-blue.svg)](./CHANGELOG.md)
[![Bash](https://img.shields.io/badge/bash-4.3%2B-lightgrey.svg)](#requisitos)

[**🌐 Sitio**](https://genpy-cli.vercel.app/) · [Instalación](#instalación) · [Blueprints](#blueprints) · [Arquitectura](ARCHITECTURE.md)

</div>

---

## El problema

Arrancar un proyecto nuevo son 30 minutos de copiar `docker-compose`, inventar
contraseñas, cablear variables de entorno y cruzar los dedos para que levante a la
primera. **GenPy lo resuelve en una orden** y te entrega un proyecto que ya corre.

```bash
genpy create
#  ├─ elegís un stack            (ej. FastAPI + PostgreSQL)
#  ├─ GenPy lo genera            con credenciales únicas ya inyectadas en el .env
#  └─ queda listo para levantar:
cd mi-proyecto && docker compose up -d --build
curl localhost:8000              # ✅ responde
```

## Por qué GenPy

- 🔐 **Credenciales únicas por proyecto** — secretos generados con `openssl rand` e
  inyectados en el `.env`. Cero `changeme`, cero placeholders.
- 📦 **9 blueprints oficiales** listos para `docker compose up` — web, AI/LLM, infra y
  labs de seguridad.
- 🧩 **Sin dependencias en el host** más allá de Bash, Docker y Git. La CLI no necesita
  Python, Node ni Go.
- 🛡️ **Determinista y testeado** — preflight de entorno, 148 tests en bash puro y CI en
  verde.
- 🌎 **Bilingüe (es/en)** desde la v1.

> Estado: **v1.0.0-alpha** · el motor de review sin IA está casi completo (Semana 2).

## Requisitos

- Bash 4.3+, Git, Docker
- macOS, Linux o WSL2

## Instalación

```bash
git clone https://github.com/RenatoAntonioCL/genpy.git
cd genpy
bash scripts/install.sh
```

Más detalle: [docs/INSTALL.md](docs/INSTALL.md).

## Comandos

| Comando | Estado |
|---------|--------|
| `genpy create` | Estable |
| `genpy version` | Estable |
| `genpy update` / `genpy uninstall` | Estable |
| `genpy review` | Semana 3 — motor sin IA listo, providers pendientes |
| `genpy doctor` | Semana 4 (pendiente) |

## Blueprints

| Área | Stacks |
|------|--------|
| Web | FastAPI + PostgreSQL, NestJS + MongoDB, Go + Gin + MySQL |
| AI | PyTorch, LLM RAG |
| Security | Kali attacker, Win7 victim (solo labs) |
| Infra | Traefik cluster, Prometheus + Grafana |

**Modelo A:** Dockerfile en raíz · **Modelo B:** Dockerfile en `backend/`

## Documentación

- [CONTEXT.md](CONTEXT.md) — brief para agentes / sesiones de trabajo
- [ARCHITECTURE.md](ARCHITECTURE.md) — diseño, flujos, roadmap
- [decisions/](decisions/) — ADRs (decisiones de arquitectura, A1–D3)
- [CHANGELOG.md](CHANGELOG.md) — historial de versiones

## Estructura del repositorio

```
genpy/
├── bin/genpy
├── lib/core/          # config, compat, errors, preflight
├── lib/i18n/          # es, en
├── lib/ui/            # banner, card, menus
├── lib/               # wizard, template, docker, git_manager, …
├── lib/review_strategies/
├── lib/providers/
├── scripts/           # install, update, uninstall, doctor (stub)
├── templates/         # 9 blueprints
├── tests/             # bash puro + mocks (148 tests, sin bats)
├── decisions/         # ADRs formales (A1–D3)
└── docs/
```

## Desarrollo local (smoke Docker)

```bash
cd templates/web-fastapi-postgres
docker compose up -d --build
curl -s http://127.0.0.1:8000/
```

## Problemas conocidos

- `lib/resolver.sh` puede disparar un **falso positivo** de here-document bajo
  `bash -n` (un heredoc de Python embebido en una sustitución de comando). Es un
  *warning*, no un error.
- **No afecta el comportamiento en runtime**: `bash -n` retorna 0 y el CI queda verde.
- Cubierto por tests (`tests/unit/test_resolver.sh`).

## Licencia

MIT © [Renato Antonio](https://github.com/RenatoAntonioCL)
