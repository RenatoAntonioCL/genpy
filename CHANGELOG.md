# Changelog

Formato basado en [Keep a Changelog](https://keepachangelog.com/).

## [v1.0.0-alpha-docker] — 2026-05-26

### Added

- Fundación portable: `lib/core/`, `lib/i18n/`, `lib/ui/`
- Documentación `CONTEXT.md` y `ARCHITECTURE.md`
- Política de red Docker: APIs en `127.0.0.1`, BD solo red interna
- `${COMPOSE_PROJECT_NAME}` en todos los `docker-compose.yml`
- Contrato `.genpy/blueprint.toml` en `web-fastapi-postgres`
- Esqueleto Semana 2–5: `resolver`, `guardians`, `assembler`, strategies, providers
- `tests/mocks/ollama_mock.sh`, CI básico (syntax + compose config)

### Fixed

- `template.sh` ya no mueve `backend/Dockerfile` a la raíz (Modelo B)
- FastAPI: código en `backend/src/`, `PROJECT_NAME` vía entorno
- Go: `go mod tidy` en build, `email` varchar para MySQL 8
- NestJS: `nest-cli.json` para `nest build`

### Removed

- Prototipos descartados `scripts/review.sh` (curl directo a Ollama)

## [Historial anterior]

Ver commits previos a la refactorización `1.0.0-alpha`.
