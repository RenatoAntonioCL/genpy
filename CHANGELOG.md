# Changelog

Formato basado en [Keep a Changelog](https://keepachangelog.com/).

## [Unreleased]

---

## [1.0.0-alpha] — 2026-06-02

### Added

- `genpy review` — flujo de 10 pasos funcional con Ollama local:
  - Selectores: `--lines N-M`, `--function`, `--class`, `--method Clase.método`
  - Opciones: `--goal`, `--provider ollama|api`, `--model`
  - `lib/providers/ollama.sh`: `ai_complete()` via curl; detección de modelo
    con prioridad `GENPY_MODEL` → `ollama list` → fallback `qwen2.5:3b`
  - `lib/core/preflight.sh`: `preflight_mode_review()` — árbol git limpio +
    Ollama accesible antes de comenzar la revisión
  - Git checkpoint automático (`genpy/review/<timestamp>`) + rollback ante abort
  - 5 guardianes de validación del output IA (G1–G5)
  - Diff visual + confirmación `[A]ceptar / [R]echazar / [E]ditar`
- `lib/resolver.sh` — `resolve_range()`: traduce `--lines N-M`, `--function`,
  `--class`, `--method Clase.método` a rango de líneas 1-based.
  Bash/grep/awk primero; fallback python3 ast (decisión C2). 24 tests.
- `lib/guardians.sh` — `run_guardians()` + G1–G5.
  Retorna 0/1/2; `GUARDIAN_MAX_RETRIES`, `GUARDIAN_NON_INTERACTIVE`. 44 tests.
- `lib/assembler.sh` — `build_review_context()`, `assemble_prompt()`,
  `reassemble_file()`. 48 tests.
- `lib/git_manager.sh` — `create_checkpoint()` / `rollback_to_checkpoint()`.
  32 tests.
- `lib/review_strategies/python.sh` — `validate_syntax`, `extract_signatures`,
  `get_prompt_rules`. Stubs no-bloqueantes para Go y JavaScript.
- `lib/template.sh` — secretos únicos por proyecto: `_generate_secret(bytes)` +
  `_inject_env_secrets()` con resolución de referencias cruzadas en el mismo `.env`.
  5 blueprints con `{{SECRET_HEX_N}}` inyectado.
- `lib/docker.sh` — `_find_free_port()`: remapeo automático de puertos ocupados
  en `docker-compose.yml` al crear un proyecto.
- `lib/git_manager.sh` — creación automática de repositorio en GitHub via API REST
  (`GITHUB_TOKEN` / `GH_TOKEN` / `gh` CLI con degradación grácil).
- 177 tests en bash puro (sin bats); CI con ShellCheck + matriz Ubuntu + macOS.
- Branch protection en `main`: 7 checks requeridos antes de merge.
- Workflow `release.yml`: tarball + sha256 en GitHub Releases al hacer push de un tag.
- Templates de PR e issues en `.github/`.

### Fixed

- `errors.sh`: `Ctrl+C` no salía del wizard — traps `EXIT` e `INT/TERM` separados.
- `libs.sh`: `sed -i ''` (solo macOS) reemplazado por `_sed_inplace()` portable.
- `template.sh`: pipeline `| while read` reemplazado por process substitution;
  valida template y destino antes/después del `rsync`.
- `git_manager.sh`: `git push` silenciaba `stderr`; mensaje de error ahora visible.
- `lib/core/compat.sh`: `export VAR="$(cmd)"` separado en dos líneas (SC2155).
- `tests/mocks/ollama_mock.sh`: marcador de sección incompatible con `assemble_prompt`.

---

## [v1.0.0-alpha-docker] — 2026-05-26

### Added

- Fundación portable: `lib/core/`, `lib/i18n/`, `lib/ui/`
- Documentación `CONTEXT.md` y `ARCHITECTURE.md`
- Política de red Docker: APIs en `127.0.0.1`, BD solo red interna
- `${COMPOSE_PROJECT_NAME}` en todos los `docker-compose.yml`
- Contrato `.genpy/blueprint.toml` en `web-fastapi-postgres`
- `tests/mocks/ollama_mock.sh`, CI básico (syntax + compose config)

### Fixed

- `template.sh` ya no mueve `backend/Dockerfile` a la raíz (Modelo B)
- FastAPI: código en `backend/src/`, `PROJECT_NAME` vía entorno
- Go: `go mod tidy` en build, `email` varchar para MySQL 8
- NestJS: `nest-cli.json` para `nest build`

### Removed

- Prototipos descartados `scripts/review.sh` (curl directo a Ollama)

---

## Procedencia (1ª generación)

GenPy nació como un **generador multi-lenguaje** que evolucionó hasta **v3.0.0**
(soporte Docker dinámico para Go, Rust, Python y Node). La línea actual es una
**reescritura completa en Bash** con blueprints, que reinicia el versionado en
`1.0.0-alpha`.

Por eso el versionado actual no continúa desde v3: es una nueva generación. La primera
se conserva en el tag **`legacy/v3.0.0`** (y en el historial de `main`), para preservar
de dónde viene el proyecto.
