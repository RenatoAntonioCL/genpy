<div align="center">

# GenPy

### Docker projects ready to run, in a single command.

GenPy generates **9 official stacks** (web · AI · infra · security) with **unique
per-project credentials** already injected. No `changeme`, no placeholders, no wiring
the `.env` by hand.

[![CI](https://github.com/RenatoAntonioCL/genpy/actions/workflows/ci.yml/badge.svg)](https://github.com/RenatoAntonioCL/genpy/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/license-MIT-green.svg)](./LICENSE)
[![Version](https://img.shields.io/badge/version-1.0.0--alpha-blue.svg)](./CHANGELOG.md)
[![Bash](https://img.shields.io/badge/bash-4.3%2B-lightgrey.svg)](#requirements)

[**🌐 Website**](https://genpy-cli.vercel.app/) · [Installation](#installation) · [Try It in 60 Seconds](#try-it-in-60-seconds) · [Blueprints](#blueprints)

</div>

---

## The Problem

Starting a new project means 30 minutes of copying `docker-compose`, inventing
passwords, wiring environment variables, and hoping it starts on the first try.
**GenPy solves it in one command** and delivers a project that already runs.

```bash
genpy create
#  ├─ choose a stack             (e.g. FastAPI + PostgreSQL)
#  ├─ GenPy generates it         with unique credentials already injected in .env
#  └─ ready to start:
cd mi-proyecto && docker compose up -d --build
curl localhost:8000              # ✅ responds
```

## Why GenPy

- 🔐 **Unique per-project credentials** — secrets generated with `openssl rand` and
  injected into `.env`. Zero `changeme`, zero placeholders.
- 📦 **9 official blueprints** ready for `docker compose up` — web, AI/LLM, infra, and
  security labs.
- 🧩 **No host dependencies** beyond Bash, Docker, and Git. The CLI requires no Python,
  Node, or Go.
- 🛡️ **Deterministic and tested** — environment preflight, 177 tests in pure bash, and
  CI passing (Ubuntu + macOS).
- 🌎 **Bilingual (es/en)** from v1.

> Status: **v1.0.0-alpha** · `genpy create` and `genpy review` (Ollama) are functional.

## Requirements

- Bash 4.3+, Git, Docker
- macOS, Linux or WSL2

## Installation

```bash
git clone https://github.com/RenatoAntonioCL/genpy.git
cd genpy
bash scripts/install.sh
```

More details: [docs/INSTALL.md](docs/INSTALL.md).

## Try It in 60 Seconds

With GenPy installed, a single command leaves a project running. The wizard guides you
through 6 steps:

```bash
genpy create
#  1) Project name              → mi-api
#  2) Git mode                  → local
#  3) Area and blueprint        → Web · FastAPI + PostgreSQL
#  4) Add-ons (optional)
#  5) Confirm the summary
#  6) GenPy builds the project and injects the credentials
```

The blueprint's `.env` contains **placeholders**; your generated project has **real,
unique secrets** (`openssl rand -hex 32`):

```diff
# blueprint template
- DB_PASSWORD={{SECRET_HEX_32}}

# your generated project (mi-api/.env)
+ DB_PASSWORD=9f2c4b1e7a...  (64 unique hex chars, different in each project)
```

And it's ready to start and verify:

```bash
cd mi-api
docker compose up -d --build
curl localhost:8000        # ✅ responds
```

> Want to try it without installing anything? Any blueprint runs on its own:
> ```bash
> cd templates/web-fastapi-postgres
> docker compose up -d --build
> curl -s http://127.0.0.1:8000/
> ```

## Commands

| Command | Status |
|---------|--------|
| `genpy create` | Stable |
| `genpy review` | Stable — requires Ollama at `localhost:11434` |
| `genpy version` | Stable |
| `genpy update` / `genpy uninstall` | Stable |

## Blueprints

| Area | Stacks |
|------|--------|
| Web | FastAPI + PostgreSQL, NestJS + MongoDB, Go + Gin + MySQL |
| AI | PyTorch, LLM RAG |
| Security | Kali attacker, Win7 victim (labs only) |
| Infra | Traefik cluster, Prometheus + Grafana |

**Model A:** Dockerfile at root · **Model B:** Dockerfile in `backend/`

## Documentation

- [CONTEXT.md](CONTEXT.md) — brief for agents / work sessions
- [ARCHITECTURE.md](ARCHITECTURE.md) — design, flows, roadmap
- [decisions/](decisions/) — ADRs (architecture decisions, A1–D3)
- [CHANGELOG.md](CHANGELOG.md) — version history

## Repository Structure

```
genpy/
├── bin/genpy
├── lib/core/          # config, compat, errors, preflight
├── lib/i18n/          # es, en
├── lib/ui/            # banner, card, menus
├── lib/               # wizard, template, docker, git_manager, …
├── lib/review_strategies/
├── lib/providers/
├── scripts/           # install, update, uninstall
├── templates/         # 9 blueprints
├── tests/             # pure bash + mocks (177 tests, no bats)
├── decisions/         # formal ADRs (A1–D3)
└── docs/
```

## Known Issues

- `lib/resolver.sh` may trigger a **false positive** here-document warning under
  `bash -n` (a Python heredoc embedded in a command substitution). It is a *warning*,
  not an error.
- **Does not affect runtime behavior**: `bash -n` returns 0 and CI stays green.
- Covered by tests (`tests/unit/test_resolver.sh`).

## License

MIT © [Renato Antonio](https://github.com/RenatoAntonioCL)
