# GenPy

CLI en Bash para generar proyectos desde **blueprints** Docker (9 stacks oficiales).  
Cada proyecto generado recibe credenciales únicas — sin `changeme`, sin placeholders.

Versión actual: **1.0.0-alpha** · Semana 2 — motor de review sin IA casi completo

```bash
genpy create
```

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
├── tests/             # bats + mocks (en progreso)
├── decisions/         # ADRs (pendiente)
└── docs/
```

## Desarrollo local (smoke Docker)

```bash
cd templates/web-fastapi-postgres
docker compose up -d --build
curl -s http://127.0.0.1:8000/
```

## Licencia

MIT © [Renato Antonio](https://github.com/RenatoAntonioCL)
