# Changelog

Format based on [Keep a Changelog](https://keepachangelog.com/).

## [Unreleased]

---

## [1.0.0-alpha] — 2026-06-02

### Added

- `genpy review` — 10-step flow functional with local Ollama:
  - Selectors: `--lines N-M`, `--function`, `--class`, `--method Clase.método`
  - Options: `--goal`, `--provider ollama|api`, `--model`
  - `lib/providers/ollama.sh`: `ai_complete()` via curl; model detection with
    priority `GENPY_MODEL` → `ollama list` → fallback `qwen2.5:3b`
  - `lib/core/preflight.sh`: `preflight_mode_review()` — clean git tree +
    Ollama accessible before starting the review
  - Automatic git checkpoint (`genpy/review/<timestamp>`) + rollback on abort
  - 5 AI output validation guardians (G1–G5)
  - Visual diff + confirmation `[A]ccept / [R]eject / [E]dit`
- `lib/resolver.sh` — `resolve_range()`: translates `--lines N-M`, `--function`,
  `--class`, `--method Clase.método` to a 1-based line range.
  Bash/grep/awk first; python3 ast fallback (decision C2). 24 tests.
- `lib/guardians.sh` — `run_guardians()` + G1–G5.
  Returns 0/1/2; `GUARDIAN_MAX_RETRIES`, `GUARDIAN_NON_INTERACTIVE`. 44 tests.
- `lib/assembler.sh` — `build_review_context()`, `assemble_prompt()`,
  `reassemble_file()`. 48 tests.
- `lib/git_manager.sh` — `create_checkpoint()` / `rollback_to_checkpoint()`.
  32 tests.
- `lib/review_strategies/python.sh` — `validate_syntax`, `extract_signatures`,
  `get_prompt_rules`. Non-blocking stubs for Go and JavaScript.
- `lib/template.sh` — unique per-project secrets: `_generate_secret(bytes)` +
  `_inject_env_secrets()` with cross-reference resolution in the same `.env`.
  5 blueprints with `{{SECRET_HEX_N}}` injected.
- `lib/docker.sh` — `_find_free_port()`: automatic remapping of occupied ports
  in `docker-compose.yml` when creating a project.
- `lib/git_manager.sh` — automatic GitHub repository creation via REST API
  (`GITHUB_TOKEN` / `GH_TOKEN` / `gh` CLI with graceful degradation).
- 177 tests in pure bash (no bats); CI with ShellCheck + Ubuntu + macOS matrix.
- Branch protection on `main`: 7 checks required before merge.
- Workflow `release.yml`: tarball + sha256 on GitHub Releases on tag push.
- PR and issue templates in `.github/`.

### Fixed

- `errors.sh`: `Ctrl+C` did not exit the wizard — separate `EXIT` and `INT/TERM` traps.
- `libs.sh`: `sed -i ''` (macOS only) replaced by portable `_sed_inplace()`.
- `template.sh`: `| while read` pipeline replaced by process substitution;
  validates template and destination before/after `rsync`.
- `git_manager.sh`: `git push` silenced `stderr`; error message is now visible.
- `lib/core/compat.sh`: `export VAR="$(cmd)"` split into two lines (SC2155).
- `tests/mocks/ollama_mock.sh`: section marker incompatible with `assemble_prompt`.

---

## [v1.0.0-alpha-docker] — 2026-05-26

### Added

- Portable foundation: `lib/core/`, `lib/i18n/`, `lib/ui/`
- Documentation `CONTEXT.md` and `ARCHITECTURE.md`
- Docker network policy: APIs on `127.0.0.1`, DB on internal network only
- `${COMPOSE_PROJECT_NAME}` in all `docker-compose.yml`
- `.genpy/blueprint.toml` contract in `web-fastapi-postgres`
- `tests/mocks/ollama_mock.sh`, basic CI (syntax + compose config)

### Fixed

- `template.sh` no longer moves `backend/Dockerfile` to root (Model B)
- FastAPI: code in `backend/src/`, `PROJECT_NAME` via environment
- Go: `go mod tidy` on build, `email` varchar for MySQL 8
- NestJS: `nest-cli.json` for `nest build`

### Removed

- Discarded prototype `scripts/review.sh` (direct curl to Ollama)

---

## Provenance (1st generation)

GenPy started as a **multi-language generator** that evolved up to **v3.0.0**
(dynamic Docker support for Go, Rust, Python, and Node). The current line is a
**complete rewrite in Bash** with blueprints, restarting the version numbering at
`1.0.0-alpha`.

That is why the current versioning does not continue from v3: it is a new generation.
The first one is preserved under the tag **`legacy/v3.0.0`** (and in the history of
`main`), to preserve where the project came from.
