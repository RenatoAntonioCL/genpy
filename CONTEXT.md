# genpy — AI Context Brief

> Load this file at the start of each work session.
> Last updated: 2026-06-02
> Status: Week 3 complete — genpy review functional with Ollama (177 tests)

---

## What is genpy?

Modular Bash CLI to automate the deployment and management
of software architectures via containerized blueprints
(Docker). It generates complete projects from templates
and, in future versions, reviews them with local AI (Ollama)
or external APIs.

Current version:  1.0.0-alpha
Distribution:     git clone + install.sh / brew / apt

---

## Current Status

Working today:
  genpy create → complete and stable flow
    - Preflight: validates Docker, Git, disk, permissions
    - Bilingual UI: Spanish and English via i18n/
    - 9 blueprints with aligned docker-compose (Model A/B)
    - Port policy: APIs on 127.0.0.1, DB on internal network only
    - Per-blueprint injectable add-ons
    - Automatic git init (local/private/public → creates GitHub repo via API)
    - Automatic port remapping for occupied ports in docker-compose.yml
    - web/AI templates with corrected, buildable Dockerfiles

  genpy review → 10-step flow functional with Ollama
    - Selectors: --lines N-M, --function, --class, --method Clase.método
    - Ollama provider (localhost:11434) with automatic model detection
    - Preflight: clean git tree + Ollama accessible
    - Automatic git checkpoint + rollback on abort/error
    - 5 AI output validation guardians (G1–G5)
    - Visual diff + confirmation [A]ccept/[R]eject/[E]dit
    - Options: --goal, --provider, --model

Not yet implemented:
  genpy doctor  → Week 4
  providers/api.sh → Week 5 (external API: OpenAI/Anthropic/custom)
  review_strategies/go.sh and javascript.sh → Week 5 (non-blocking stubs)
  Semantic chunking (§5.6) → Week 5 (files > 500 lines)

Week 3 complete:
  ollama.sh ✅, review.sh ✅, preflight_mode_review ✅, bin/genpy review ✅
  177 tests in pure bash:
    24 resolver + 44 guardians + 48 assembler + 32 checkpoint
    13 ollama_provider + 16 review_flow (integration)

---

## Actual Project Structure

  bin/
    genpy                   Entry point. Resolves paths,
                            loads i18n, defines commands.

  lib/core/
    compat.sh               Detects OS, architecture, Bash 4.3+.
                            Provides portable _port_in_use() and
                            _find_free_port() for auto-remapping.
                            Exports: GENPY_OS, GENPY_ARCH.
    config.sh               Single source of truth for the domain.
                            Arrays: AREAS, AREA_BLUEPRINTS,
                            BLUEPRINT_META, ADDON_PACKAGES,
                            ADDON_LABELS, ADDON_INDEX.
                            Function: blueprint_meta().
    errors.sh               trap EXIT/INT/TERM.
                            Own colors: _ERR_RED, _ERR_NC.
                            Functions: die(), require_command(),
                            require_dir().
                            Self-contained: does not depend on utils.sh.
    preflight.sh            preflight_mode_create():
                            validates docker, git, disk >500MB,
                            write permissions.

  lib/i18n/
    en.sh                   English dictionary. Covers: wizard,
                            menus, card, confirmation, errors.
    es.sh                   Spanish dictionary. Same schema.

  lib/ui/
    banner.sh               ASCII banner. Uses GENPY_VERSION.
    card.sh                 Summary card. Zero hardcoding,
                            everything from blueprint_meta().
    menus.sh                Dynamic menus from config.sh.
                            Contains: select_area(),
                            select_blueprint(), select_git_mode(),
                            confirm_creation().

  lib/
    utils.sh                Color palette and print_*().
                            Primitive UI. Single responsibility.
    libs.sh                 Add-on engine. select and inject.
                            _inject_node_addons uses jq (not sed).
                            Docker filter in requirements.txt
                            uses _sed_inplace() (portable).
    template.sh             rsync + portable _sed_inplace().
                            Respects Model A/B (does not move Dockerfiles).
                            Injects {{PROJECT_NAME}} in:
                            .env, *.md, docker-compose.yml, Dockerfile,
                            *.py, *.sh, *.go, go.mod, package.json,
                            nest-cli.json, tsconfig.json
                            _generate_secret(bytes): openssl rand -hex
                            with fallback to /dev/urandom.
                            _inject_env_secrets(env_file): two passes —
                            replaces {{SECRET_HEX_N}} and resolves
                            cross-references {{VAR_NAME}} in the same
                            .env (e.g.: DATABASE_URL uses {{DB_PASSWORD}}).
    wizard.sh               genpy create orchestrator (7 steps).
                            No domain logic or own UI.
    git_manager.sh          setup_git_repository().
                            Creates GitHub repo via REST API
                            (_get_github_token, _create_github_repo).
                            Reads GITHUB_TOKEN / GH_TOKEN / gh CLI.
                            Fallback: manual URL if no token.
                            select_git_mode() removed (lives
                            in menus.sh).
    docker.sh               check_docker_daemon().
                            inspect_blueprint_ports() via
                            blueprint_meta(), _port_in_use().
                            Auto-remaps occupied ports with
                            _find_free_port() and patches
                            docker-compose.yml on the fly.
    review.sh               genpy_review() — 10-step orchestrator.
                            Selectors: --lines N-M, --function,
                            --class, --method Clase.método.
                            Options: --goal, --provider, --model.
                            Allows mock injection in tests
                            (check declare -f ai_complete before
                            sourcing the provider).
    resolver.sh             resolve_range(): --lines, --function,
                            --class, --method Clase.método.
                            Bash + python3 ast fallback (C2).
    guardians.sh            run_guardians() + G1–G5. Returns
                            0=ok / 1=abort / 2=retry.
                            GUARDIAN_NON_INTERACTIVE for CI.
    assembler.sh            build_review_context(), assemble_prompt(),
                            reassemble_file(). Steps [4][5][8].
    review_strategies/      python.sh: functional.
                            go.sh, javascript.sh: non-blocking stubs
                            (validate_syntax returns 0). Week 5.
    providers/              ollama.sh: ai_complete() functional.
                              POST /api/generate, stream:false.
                              Model detection: GENPY_MODEL >
                              ollama list > qwen2.5:3b (fallback).
                              jq with python3 fallback.
                            api.sh: stub Week 5.

  scripts/
    install.sh              Installer. Pending rewrite
                            with 4 phases.
    uninstall.sh            Functional.
    update.sh               Functional. No SHA256 yet.
    doctor.sh               Stub Week 4.

  tests/                    fixtures/sample.py, fixtures/sample_assembler.txt
                            unit/: test_resolver.sh (24), test_guardians.sh (44),
                                   test_assembler.sh (48), test_checkpoint.sh (32),
                                   test_ollama_provider.sh (13)
                            integration/: test_review_flow.sh (16)
                                   — 177 tests, pure bash, no bats
                            mocks/ollama_mock.sh
                              Extracts Section 4 from the assembled prompt
                              (marker: "=== SECTION 4: TARGET FRAGMENT ===")
  decisions/                Formal ADRs A1–D3 migrated (see README).
  docs/                     INSTALL, CONTRIBUTING, SECURITY.
  .github/                  workflows/ci.yml, CONTEXT.md → link.

  templates/                9 official blueprints.
                            web-fastapi-postgres has
                            .genpy/blueprint.toml (reference).

---

## Blueprint Models

  Model A — Single service (Dockerfile at blueprint root):
    ai-ml-pytorch, ai-llm-rag,
    cyber-attacker-kali, cyber-lab-victim-win7

  Model B — Multi-service (Dockerfile in backend/):
    web-fastapi-postgres, web-go-gin-clean,
    web-node-nest-mongo
    docker-compose.yml with context: ./backend

  No Dockerfile — Configuration only in config/:
    infra-local-cluster, infra-monitoring-stack

---

## Inviolable Principles

  P1 — ABSOLUTE RESILIENCE
    AI never touches live files directly.
    Every change goes through:
    Sandbox(.tmp) → Guardians → Git → User.

  P2 — PURE AND MODULAR BASH
    Functions with single responsibility.
    trap at every failure point.
    No host dependencies beyond
    Bash 4.3+, Docker, Git, and Ollama.

  P3 — ISOLATED CONTAINERS
    Each blueprint is self-contained via docker-compose.yml.
    No global host dependencies.

  P4 — INCREMENTAL PROGRESS
    The system always moves forward, never backward.
    If a change cannot be validated, it is rejected.

---

## Architecture Invariants

  - config.sh is the single source of truth for the domain.
    No module hardcodes blueprints, ports,
    stacks, or descriptions.

  - errors.sh is self-contained. Does not depend on utils.sh.

  - AI never touches live files directly.

  - Providers (ollama/api) are interchangeable
    without touching review.sh.
    Contract: ai_complete(prompt_file, output_file,
                          options_file)
    Returns: 0=ok 1=failure 2=empty 3=timeout

  - Strategies (python/go/js) are interchangeable
    without touching review.sh.
    Contract: validate_syntax(file)
              extract_signatures(file)
              get_prompt_rules()

  - The review flow has exactly 10 steps.
    Its order does not change without a new ADR.

  - Official blueprints are defined in config.sh.
    No third-party blueprints in v1.

---

## Closed Decisions

  > Formal and detailed version in `decisions/` (ADR-0001…0012). This list is the
  > quick summary; in case of discrepancies, the ADR prevails.

  A1  Bash 4.3+ minimum (namerefs). compat.sh detects and validates.
  A2  Linux + macOS + WSL2 from v1.
  A3  git clone + install.sh AND package managers.
  B1  Model: detect what is available in Ollama.
      Guaranteed fallback: qwen2.5:3b.
  B2  Dual provider: Ollama + abstracted external API.
  B3  Guardian failure:
      [R]etry / [A]bort / [E]dit manually.
  C1  Resolver v1: top-level + Class.method.
  C2  Hybrid semantic detection:
      Bash first, native runtime as fallback.
  C3  Decorators and comments: included by default,
      configurable in blueprint.toml.
  D1  i18n: English + Spanish from v1.
  D2  Tests in pure bash (no bats) + CI GitHub Actions.
  D3  Only official repo blueprints in v1.

---

## Known Limitations

  - Ollama 3B hallucinates with files > 300 lines
    without semantic chunking.
  - diff/patch format is fragile with small models.
    Use full file with compensating guardians.
  - Line-number-based chunks break context.
    Use semantic boundaries with sort by level.
  - sed for JSON modification is fragile. Use jq.
  - lsof not available on all Linux distros.
    Resolved with _port_in_use() in compat.sh.

---

## Week 0 Fixes — 100% Complete

  ✅ R1  Universal shebang in all files
  ✅ R2  errors.sh: trap INT/TERM + own _ERR_RED
  ✅ R3  Duplicate select_git_mode removed
  ✅ R4  Portable _port_in_use() in compat.sh
  ✅ R5  Prueba11 → {{PROJECT_NAME}} in main.py
  ✅ R6  TEMPLATE_BASE_DIR fallback fixed
  ✅ R7  source vs bash consistent in bin/genpy
  ✅ R8  Version 1.0.0-alpha unified
  ✅ R9  jq in _inject_node_addons
  ✅ R10 README.md in ai-llm-rag
  ✅ R11 docker-compose.yml in cyber-attacker-kali
  ✅ R12 Dockerfile ai-ml-pytorch moved to root

---

## Checkpoint 2026-05-26 — Docker, templates and documentation

  Goal: usable blueprints with `docker compose` and a coherent layout.

  ✅ Documentation
     CONTEXT.md + ARCHITECTURE.md synchronized (full version 2026-05-21).

  ✅ lib/template.sh
     Removed backend/Dockerfile → root movement (Model B bug).
     Extended {{PROJECT_NAME}} injection to Go/Node/TS.

  ✅ lib/core/config.sh
     Port metadata only for APIs exposed on localhost
     (no 5432/27017/3306 in collision check).

  ✅ Network policy (9 docker-compose.yml)
     Web: API 127.0.0.1, databases with no ports on host.
     AI: Jupyter 127.0.0.1; RAG no ports; PyTorch requirements at root.
     Cyber: Kali compose recreated (no ports); Win7 victim with no network changes.
     Infra: Prometheus/Grafana/Traefik on 127.0.0.1; {{PROJECT_NAME}} in Traefik.

  ✅ Dockerfiles and template code
     web-fastapi-postgres: backend/src/, POSTGRES_* config, Dockerfile backend/.
     web-node-nest-mongo: nest-cli.json, build dist/main.js.
     web-go-gin-clean: app module, DSN from env, multi-stage Dockerfile.
     ai-ml-pytorch: root Dockerfile + root requirements.txt.
     ai-llm-rag: local Chroma PersistentClient, langchain-community deps.

  ✅ Web READMEs
     "Docker Network" section in FastAPI, NestJS and Go.

  ✅ docker-compose uses ${COMPOSE_PROJECT_NAME} for container
     and DB names (valid when testing templates/ without genpy create).

  Pending host verification:
     docker compose build && up on each blueprint with Dockerfile.
     libs.sh uses sed -i '' (macOS only) — fix for Linux.

  Not included in this checkpoint:
     OSI layer security (future roadmap).

---

## Checkpoint 2026-05-28 — Phase 0: create flow stabilization

  Goal: eliminate real bugs that made the flow fragile on Linux
  and in error paths. 8 fixes applied, one discarded (false positive).

  ✅ Fix 1 — config.sh uncommented in wizard.sh
     Explicit dependency declaration. Include guard in config.sh
     (_GENPY_CONFIG_LOADED) prevents readonly error on double source.

  ✅ Fix 2 — sed -i '' in libs.sh → _sed_inplace()
     The requirements.txt security filter was broken on Linux.
     Now uses the portable function from the same module (template.sh).
     template.sh sourcing from libs.sh guaranteed by ordered loading
     in wizard.sh (lines 24-25).

  ✅ Fix 3 — Implicit utils.sh dependencies
     docker.sh, libs.sh and git_manager.sh now source utils.sh
     explicitly via LIB_DIR. Include guard in utils.sh
     (_GENPY_UTILS_LOADED) prevents double redefinition.

  ✅ Fix 4 — Project name validation
     Regex ^[a-zA-Z0-9][a-zA-Z0-9_-]*$ in wizard.sh.
     Rejects: spaces, /, ., $, leading dash, empty string.
     New i18n message: MSG_ERR_NAME_INVALID (es.sh and en.sh).

  ✅ Fix 5 — copy_template() validates template and result
     Fails with a precise message if template_dir does not exist.
     Fails if rsync copied nothing (ls -A post-copy).
     wizard.sh keeps the secondary check as a second line of defense.

  ✅ Fix 6 — Subshell in template.sh pipe
     | while read → while ... done < <(find ...) (process substitution).
     _sed_inplace errors propagate correctly; loop variables
     persist in the main shell.

  ✅ Fix 7 — Backticks in compat.sh
     False positive: code already used $() everywhere.
     Not applicable.

  ✅ Fix 8 — Git push silenced stderr
     Removed 2>/dev/null from _push_to_remote(). The real git message
     (e.g.: "Permission denied (publickey)") is now visible to the user.
     The if/else structure already existed and was correct.

  ✅ Extra fix — Ctrl+C did not exit the wizard
     errors.sh: separated EXIT and INT/TERM traps.
     INT/TERM call exit 130 after cleanup; the wizard's while loop
     no longer continues after Ctrl+C.

---

## Checkpoint 2026-05-28 — Automatically generated .env secrets

  Goal: eliminate hardcoded passwords in templates;
  each generated project receives unique, secure credentials.

  ✅ lib/template.sh — new functions
     _generate_secret(bytes): uses openssl rand -hex with fallback
     to LC_ALL=C tr < /dev/urandom. Output: pure hex [0-9a-f].
     _inject_env_secrets(env_file): two passes over the copied .env.
       Pass 1: replaces {{SECRET_HEX_N}} with a secret of N bytes.
               Stores var_name → secret in a local map.
       Pass 2: resolves {{VAR_NAME}} (bash string substitution,
               no sed — avoids double-brace bug in BSD sed on macOS).
     Implementation note: ${#array[@]} with an empty associative array
     triggers nounset in bash 5.3; a 'generated=0/1' flag is used instead.
     .env added to the find list for {{PROJECT_NAME}} injection.
     _inject_env_secrets called at the end of copy_template().

  ✅ .gitignore — exception for templates/
     Rule added: !templates/**/.env
     Template .env files are CLI source, not real secrets.

  ✅ Updated templates:

     web-fastapi-postgres:
       DB_PASSWORD={{SECRET_HEX_32}}  (64 chars hex)
       DATABASE_URL uses {{DB_PASSWORD}} as a cross-reference
       → both variables receive the same generated secret

     web-go-gin-clean:
       DB_PASSWORD={{SECRET_HEX_32}}

     ai-ml-pytorch:
       JUPYTER_TOKEN={{SECRET_HEX_24}}
       "you can change it" comment removed (no longer applies)

     web-node-nest-mongo:
       JWT_SECRET={{SECRET_HEX_32}} (new variable)

     infra-monitoring-stack:
       .env created with GF_SECURITY_ADMIN_PASSWORD={{SECRET_HEX_16}}
       docker-compose.yml updated: no longer hardcodes "admin"
       → GF_SECURITY_ADMIN_PASSWORD: ${GF_SECURITY_ADMIN_PASSWORD}

  No changes (justified):
     ai-llm-rag: OPENAI_API_KEY is an external API key,
       not generated. Cannot be automated.
     cyber-attacker-kali: no credentials (AUDIT_MODE, TARGET_SUBNET).
     infra-local-cluster: only PROJECT_NAME.
     cyber-lab-victim-win7: no .env.

---

## Checkpoint 2026-05-28 — Automatic ports and GitHub

  Goal: eliminate manual friction in the two final wizard steps.

  ✅ lib/core/compat.sh
     New function _find_free_port(port): iterates from port+1 until
     a free port is found (<= 65535). Lives next to _port_in_use().

  ✅ lib/docker.sh — inspect_blueprint_ports()
     Accepts second argument project_dir.
     When a port is occupied: calls _find_free_port, reports
     the remapping to the user, and patches docker-compose.yml with sed
     (host port only; container port does not change).
     Wizard.sh updated to pass $PROJECT_DIR.

  ✅ lib/git_manager.sh — GitHub API
     _get_github_token(): searches GITHUB_TOKEN → GH_TOKEN → gh CLI.
     _create_github_repo(): POST /user/repos via curl; extracts ssh_url
     with jq or grep; reports API error on failure.
     _push_to_remote(): connects remote and pushes; retry instructions
     on failure.
     _fallback_manual_remote(): previous flow (manual URL), used
     when there is no curl, no token, or the API fails.
     setup_git_repository(): orchestrates the full flow with graceful
     degradation at each failure point.

  Tag: v1.0.0-alpha

---

## Structural cleanup 2026-05-26

  Goal: align the repo tree with ARCHITECTURE.md.

  Removed:
    - Review prototypes (curl/Ollama) in old scripts/ and lib/.
    - Local .aider* artifacts (gitignore).

  Created:
    - tests/{fixtures,unit,integration,mocks/ollama_mock.sh}
    - decisions/, docs/, .github/workflows/ci.yml
    - Week 2–5 stubs: resolver, guardians, assembler, providers
    - lib/review.sh new (Week 3 stub)
    - templates/web-fastapi-postgres/.genpy/blueprint.toml
    - CHANGELOG.md, README.md updated

  Implemented since then:
    resolver.sh ✅, guardians.sh ✅, assembler.sh ✅
  Pending implementation:
    genpy review (Week 3), doctor (Week 4).

---

## Week 2 — Review Engine without AI

What we built now, in order:

  1. .genpy/blueprint.toml in web-fastapi-postgres  ✅ (template + create flow)
     rsync copies .genpy/ to the generated project.
     _validate_blueprint_toml() validates existence, [meta] section,
     version and language in pure bash (grep). Called from copy_template().

  2. resolver.sh  ✅
     resolve_range() implemented: --lines N-M, --function,
     --class, --method Clase.método for Python top-level.
     Strategy: grep/awk first, python3 ast as fallback (C2).
     24 tests in tests/unit/test_resolver.sh (24 PASS / 0 FAIL).

  3. guardians.sh  ✅
     run_guardians() + G1–G5 implemented.
     G4 skips chunks of indented methods (full validation in step [8]).
     G5 verifies top-level and indented signatures; ignores private (_foo),
     preserves dunders (__init__). [R]/[A]/[E] interaction with GUARDIAN_MAX_RETRIES.
     44 tests in tests/unit/test_guardians.sh (44 PASS / 0 FAIL).

  4. assembler.sh  ✅
     build_review_context(): extracts imports + signatures → context blob.
     assemble_prompt(): 4 sections with role, goal, context and chunk.
     reassemble_file(): head + revised_chunk + tail → stdout.
     48 tests in tests/unit/test_assembler.sh (48 PASS / 0 FAIL).

  5. review_strategies/python.sh  ✅ (functional)
     validate_syntax(): python3 -m py_compile.
     extract_signatures(): grep ^def / ^async def / ^class.
     get_prompt_rules(): indentation, type hints, f-strings, decorators.

  6. git_manager.sh hardening  ✅
     create_checkpoint(project_dir, [branch_prefix]): validates repo, HEAD not
     detached, clean tree; creates branch genpy/review/<YYYYMMDD_HHMMSS> and switches
     to it. Sets CHECKPOINT_BRANCH, CHECKPOINT_ORIGINAL_BRANCH.
     rollback_to_checkpoint(project_dir): returns to the original branch and deletes
     the review branch with -D (force). Clears globals.
     32 tests in tests/unit/test_checkpoint.sh (32 PASS / 0 FAIL).

  Exit criteria:
    Full flow works with ollama_mock.sh.
    No real Ollama yet.

---

## Checkpoint 2026-05-28 — Week 2: review engine without AI

  Goal: build and test the modules that the review.sh orchestrator
  will need in Week 3. No real AI; everything testable with mocks.

  ✅ lib/template.sh — blueprint.toml integration in genpy create
     _validate_blueprint_toml(): verifies [meta], version and language
     in pure bash (grep). copy_template() invokes it if the file exists.

  ✅ lib/resolver.sh — resolve_range()
     Four modes: --lines N-M, --function, --class, --method Clase.método.
     Bash/grep/awk as the main path; python3 ast as fallback (C2).
     Produces globals RESOLVE_START and RESOLVE_END (1-based, inclusive).
     Include guard _GENPY_RESOLVER_LOADED.
     24 tests — 24 PASS / 0 FAIL.

  ✅ lib/guardians.sh — run_guardians() + G1–G5
     G1 not-empty, G2 no-markdown, G3 line-count 70–130%,
     G4 validate_syntax (skip on indented methods),
     G5 public signatures present (ignores _private, preserves __dunders__).
     run_guardians returns 0/1/2; [R]/[A]/[E] interaction.
     GUARDIAN_MAX_RETRIES, GUARDIAN_NON_INTERACTIVE for CI.
     44 tests — 44 PASS / 0 FAIL.

  ✅ lib/assembler.sh — build_review_context / assemble_prompt / reassemble_file
     build_review_context: extracts imports and signatures → context blob with markers.
     assemble_prompt: 4 sections (role, goal, RO context, target fragment).
     reassemble_file: head(1..START-1) + revised_chunk + tail(END+1..EOF) → stdout.
     48 tests — 48 PASS / 0 FAIL.

  ✅ lib/review_strategies/python.sh — functional
     validate_syntax: python3 -m py_compile.
     extract_signatures: grep ^def / ^async def / ^class.
     get_prompt_rules: four Python style rules.

  Week 2 complete. Next: Week 3 — review.sh + Ollama/API providers.

---

## Checkpoint 2026-06-02 — Week 3: genpy review functional

  Goal: implement the 10-step orchestrator and the Ollama provider.
  The full genpy review flow works with real Ollama or with a mock.

  ✅ lib/providers/ollama.sh — ai_complete() functional
     POST http://localhost:11434/api/generate with stream:false.
     Model detection: GENPY_MODEL > first model in ollama list
     > fallback qwen2.5:3b (decision B1).
     JSON encode/decode: jq with python3 fallback.
     Return codes: 0=ok, 1=service failure, 2=empty/malformed, 3=timeout.
     curl exit 28 → return 3 (timeout). Connection refused → return 1.
     13 tests — 13 PASS / 0 FAIL.

  ✅ lib/review.sh — genpy_review() 10-step orchestrator
     Steps [0]–[10] per ARCHITECTURE.md §5.4.
     Selectors: --lines N-M, --function, --class, --method Clase.método.
     Options: --goal, --provider (ollama|api), --model.
     Mock injection: if ai_complete is defined before calling
     genpy_review, the provider is not sourced (allows tests without Ollama).
     Same pattern for preflight_mode_review.
     GENPY_REVIEW_NON_INTERACTIVE=1: auto-accepts the diff (tests/CI).
     No-changes path: empty diff → rollback + rc=0.
     With-changes path: diff → [A]ccept/[R]eject/[E]dit → commit.

  ✅ lib/core/preflight.sh — preflight_mode_review()
     Validates: curl available, clean git tree, Ollama accessible.
     OLLAMA_HOST configurable via env (default: http://localhost:11434).

  ✅ bin/genpy — review command
     shift before case → $@ passes args to genpy_review.
     show_help() updated with genpy review.

  ✅ lib/review_strategies/go.sh, javascript.sh — non-blocking stubs
     validate_syntax returns 0 (does not abort the flow).
     extract_signatures with real grep (^func / ^export).
     get_prompt_rules with basic language rules.

  ✅ tests/unit/test_ollama_provider.sh — 13 tests
     _ollama_detect_model: GENPY_MODEL, fallback without Ollama.
     _ollama_json_encode: plain text, newlines, quotes, backslash.
     _ollama_extract_response: valid JSON, empty, missing field, malformed.
     ai_complete with mock: Section 4, no section, nonexistent file.

  ✅ tests/integration/test_review_flow.sh — 16 tests
     _review_detect_strategy: .py/.go/.ts/unknown.
     No-changes flow: mock returns identical code → rollback, rc=0.
     With-changes flow: mock adds comment → diff → commit applied.
     Branch and commit verification after apply.
     Error handling: nonexistent file, no args, unknown option.
     preflight_mode_review: Ollama down, dirty tree.

  Bugs fixed in this session:
     tests/mocks/ollama_mock.sh: marker ^### FOCAL → real Section 4.
     bin/genpy: stale task comment removed.

  Total tests: 177 (148 Week 2 + 29 Week 3) — 177 PASS / 0 FAIL.
  Week 3 complete. Next: Week 4 — genpy doctor.

---

## Glossary

  focal chunk    Code fragment sent to the AI
  guardian       AI output validation function
  checkpoint     Git commit before an AI operation
  strategy       Language-specific module
  provider       AI service abstraction
  blueprint      Complete, self-contained Docker template
  addon          Optional injectable package
  Model A        Dockerfile at blueprint root
  Model B        Dockerfile in backend/
