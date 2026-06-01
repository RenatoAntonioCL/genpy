# Changelog

Formato basado en [Keep a Changelog](https://keepachangelog.com/).

## [Unreleased — Semana 2] — 2026-05-28

### Added

- `lib/resolver.sh` — `resolve_range()`: traduce `--lines N-M`, `--function`,
  `--class`, `--method Clase.método` a `RESOLVE_START`/`RESOLVE_END` (1-based).
  Bash/grep/awk primero; fallback python3 ast (decisión C2). 24 tests.
- `lib/guardians.sh` — `run_guardians()` + cinco gates independientes:
  G1 not-empty, G2 no-markdown, G3 line-count 70–130%, G4 validate_syntax,
  G5 firmas públicas. Retorna 0/1/2; interacción [R]/[A]/[E].
  `GUARDIAN_MAX_RETRIES`, `GUARDIAN_NON_INTERACTIVE`. 44 tests.
- `lib/assembler.sh` — tres funciones para el flujo review:
  `build_review_context()` (imports + firmas → context blob),
  `assemble_prompt()` (4 secciones), `reassemble_file()` (head+chunk+tail).
  48 tests.
- `lib/template.sh` — `_validate_blueprint_toml()`: valida sección `[meta]`,
  `version` y `language` en bash puro. Llamada desde `copy_template()` si
  `.genpy/blueprint.toml` existe en el proyecto generado.
- `tests/unit/test_resolver.sh`, `test_guardians.sh`, `test_assembler.sh`,
  `test_checkpoint.sh` — 148 tests en bash puro (sin bats). Estrategia mock sin python3.
- `tests/fixtures/sample.py`, `tests/fixtures/sample_assembler.txt`

## [Unreleased — Fase 0] — 2026-05-28

### Added

- `template.sh`: `_generate_secret(bytes)` — genera hex aleatorio con
  `openssl rand -hex`; fallback a `/dev/urandom`
- `template.sh`: `_inject_env_secrets(env_file)` — dos pasadas sobre el `.env`:
  reemplaza `{{SECRET_HEX_N}}` y resuelve referencias cruzadas `{{VAR_NAME}}`
  (ej: `DATABASE_URL` referencia `{{DB_PASSWORD}}` para consistencia)
- `.env` de templates rastreados en git vía excepción `!templates/**/.env`
  en `.gitignore`
- Secretos únicos por proyecto en 5 blueprints:
  - `web-fastapi-postgres` — `DB_PASSWORD` (32 B) + `DATABASE_URL` consistente
  - `web-go-gin-clean` — `DB_PASSWORD` (32 B)
  - `ai-ml-pytorch` — `JUPYTER_TOKEN` (24 B)
  - `web-node-nest-mongo` — `JWT_SECRET` (32 B, nueva variable)
  - `infra-monitoring-stack` — `.env` creado + `GF_SECURITY_ADMIN_PASSWORD` (16 B)
- `infra-monitoring-stack/docker-compose.yml`: Grafana usa `${GF_SECURITY_ADMIN_PASSWORD}`
  en lugar de la contraseña `admin` hardcodeada
- `wizard.sh`: validación del nombre del proyecto con regex
  `^[a-zA-Z0-9][a-zA-Z0-9_-]*$`; nuevo mensaje `MSG_ERR_NAME_INVALID` en i18n es/en
- `config.sh`: include guard `_GENPY_CONFIG_LOADED` — doble source sin error
  en variables `readonly`
- `utils.sh`: include guard `_GENPY_UTILS_LOADED`

### Fixed

- `errors.sh`: `Ctrl+C` no salía del wizard — traps `EXIT` e `INT/TERM` separados;
  el handler de `INT` llama `exit 130` para romper el loop
- `libs.sh`: filtro de seguridad `requirements.txt` usaba `sed -i ''` (solo macOS)
  → ahora usa `_sed_inplace()` portable
- `docker.sh`, `libs.sh`, `git_manager.sh`: dependencia de `utils.sh` era implícita
  (requería carga previa por `wizard.sh`); ahora cada módulo la sourcea explícitamente
- `wizard.sh`: `config.sh` estaba comentado — módulo dependía del caller para cargarlo
- `template.sh` — `copy_template()`:
  - Valida existencia de `template_dir` antes del `rsync`
  - Valida que el destino no quedó vacío tras el `rsync`
  - `.env` añadido a la lista de archivos con inyección de `{{PROJECT_NAME}}`
  - Pipeline `| while read` reemplazado por `while ... done < <(find ...)`
    (process substitution — errores propagan, variables persisten)
- `git_manager.sh`: `git push` tenía `2>/dev/null` — el mensaje real de error
  (ej: "Permission denied (publickey)") era invisible al usuario

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

## Procedencia (1ª generación)

GenPy nació como un **generador multi-lenguaje** que evolucionó hasta **v3.0.0**
(soporte Docker dinámico para Go, Rust, Python y Node). La línea actual es una
**reescritura completa en Bash** con blueprints, que reinicia el versionado en
`1.0.0-alpha`.

Por eso el versionado actual no continúa desde v3: es una nueva generación. La primera
se conserva en el tag **`legacy/v3.0.0`** (y en el historial de `main`), para preservar
de dónde viene el proyecto.
