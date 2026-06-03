# genpy — Architecture Document

Version:       1.0.0-alpha
Updated:       2026-05-28
Status:        Week 2 nearly complete — review engine without AI operational
Author:        Renato

---

## 1. Vision and Goals

genpy is a modular Bash CLI tool that automates
the deployment, management, and review of software architectures
via containerized blueprints (Docker).

v1.0.0 goals:
  1. Friction-free installation on Linux, macOS, and WSL2.
  2. genpy create generates complete projects in < 60s.
  3. genpy review reviews code with AI in a safe,
     traceable, and fully reversible way.
  4. Indestructible: no operation leaves the user's project
     in an unrecoverable state.

---

## 2. Design Principles (Inviolable)

  P1 — ABSOLUTE RESILIENCE
    No change touches live files directly.
    Mandatory flow:
    Sandbox(.tmp) → Guardians → Git → User.

  P2 — PURE AND MODULAR BASH
    No Python/Node dependencies in the CLI core.
    Functions with single responsibility.
    trap at every critical failure point.

  P3 — ISOLATED CONTAINERS
    Self-contained blueprints via docker-compose.yml.
    No global host dependencies beyond
    Bash 4.3+, Docker, Git, and Ollama.

  P4 — INCREMENTAL PROGRESS
    The system validates the environment before proceeding.
    If a change cannot be validated, it is rejected.

---

## 3. Stack and Constraints

  Runtime:        Bash 4.3+ (namerefs used in libs.sh, guardians.sh and menus.sh;
                  compat.sh validates Bash >= 4.3 at runtime)
  Platforms:      Linux, macOS, Windows WSL2
  Dependencies:   Docker, Git, Ollama (review only)
  Testing:        pure bash, no bats (148 tests)
  CI:             GitHub Actions (active)
  Versioning:     Strict semver

  Constraints:
    The CLI does not depend on Python, Node, or Go on the host.
    Semantic detection helper scripts MAY use the target
    language runtime as a fallback (decision C2).

---

## 4. Project Structure

  genpy/
  ├── bin/
  │   └── genpy
  ├── lib/
  │   ├── core/
  │   │   ├── compat.sh
  │   │   ├── config.sh
  │   │   ├── errors.sh
  │   │   └── preflight.sh
  │   ├── i18n/
  │   │   ├── en.sh
  │   │   └── es.sh
  │   ├── ui/
  │   │   ├── banner.sh
  │   │   ├── card.sh
  │   │   └── menus.sh
  │   ├── providers/           ← Week 3
  │   │   ├── ollama.sh
  │   │   └── api.sh
  │   ├── review_strategies/   ← Week 2
  │   │   ├── python.sh
  │   │   ├── go.sh
  │   │   └── javascript.sh
  │   ├── assembler.sh         ← Week 2
  │   ├── docker.sh
  │   ├── git_manager.sh
  │   ├── guardians.sh         ← Week 2
  │   ├── libs.sh
  │   ├── resolver.sh          ← Week 2
  │   ├── review.sh            ← Week 3
  │   ├── template.sh
  │   ├── utils.sh
  │   └── wizard.sh
  ├── scripts/
  │   ├── install.sh
  │   ├── uninstall.sh
  │   ├── update.sh
  │   └── doctor.sh            ← Week 4
  ├── templates/
  │   ├── web-fastapi-postgres/
  │   │   ├── .genpy/
  │   │   │   └── blueprint.toml  ← Week 2 (first)
  │   │   └── ...
  │   └── ... (8 more blueprints)
  ├── tests/                   ← Week 2
  │   ├── fixtures/
  │   ├── mocks/
  │   │   └── ollama_mock.sh
  │   ├── unit/
  │   └── integration/
  ├── decisions/               ← ADRs 0001–0012
  ├── docs/
  │   ├── INSTALL.md
  │   ├── CONTRIBUTING.md
  │   └── SECURITY.md
  ├── .github/
  │   ├── workflows/
  │   │   └── ci.yml
  │   └── CONTEXT.md
  ├── ARCHITECTURE.md
  ├── CHANGELOG.md
  └── README.md

---

## 5. Module Architecture

### 5.1 Core Layer

  compat.sh
    Detects: OS (GENPY_OS), architecture (GENPY_ARCH)
    Validates: Bash >= 4.3, aborts with message if not
    Provides: portable _port_in_use()
              (ss → netstat → /dev/tcp fallback)

  config.sh
    Associative arrays (readonly):
      AREAS, AREA_BLUEPRINTS, BLUEPRINT_META
      ADDON_PACKAGES, ADDON_LABELS, ADDON_INDEX
    Public function: blueprint_meta(blueprint, field)
    Rule: no module hardcodes domain data

  errors.sh
    Separate traps:
      EXIT        → _genpy_cleanup() (clears GENPY_CLEANUP_DIR)
      INT / TERM  → prints "Operation cancelled" + exit 130
    The INT trap calls exit, which fires EXIT as a chain.
    Without separation: Ctrl+C did not exit the wizard (the handler returned
    and while true continued from the interrupted read).
    Own colors: _ERR_RED, _ERR_NC (self-contained)
    Functions: die(), require_command(), require_dir()

  preflight.sh
    preflight_mode_create():
      - require_command docker, git
      - check_docker_daemon()
      - free disk > 500MB
      - write permissions in current directory
    preflight_mode_review(): ← Week 3
      - All of the above +
      - Clean Git working tree
      - Ollama accessible at localhost:11434
      - Required model downloaded
      - blueprint.toml valid and parseable

### 5.2 Providers Layer (Week 3)

  Single contract:
    ai_complete(prompt_file, output_file, options_file)
    Returns:
      0 → success, response in output_file
      1 → service failure
      2 → empty or malformed response
      3 → timeout

  ollama.sh
    POST localhost:11434/api/generate
    Model detection per priority B1:
      1. user config
      2. first model in ollama list
      3. fallback: qwen2.5:3b
    Handles: timeout, connection refused,
             malformed JSON

  api.sh
    Requires: GENPY_API_KEY in the environment
    Endpoint: configurable (OpenAI/Anthropic/custom)
    Same return codes as ollama.sh

### 5.3 Review Strategies Layer (Week 2)

  Single contract:
    validate_syntax(file)     → 0=ok, 1=error
    extract_signatures(file)  → prints signatures
    get_prompt_rules()        → prints rules

  python.sh
    validate_syntax:      python -m py_compile
    extract_signatures:   grep "^def \|^class \|
                               ^async def "
    Rules: indentation, type hints, f-strings

  go.sh
    validate_syntax:      go vet ./...
    extract_signatures:   grep "^func "

  javascript.sh
    validate_syntax:      node --check
    extract_signatures:   grep "^export \|
                               ^function \|^const "

### 5.4 The genpy review Flow (10 Steps)

  [0]  preflight_mode_review()
  [1]  Parse blueprint.toml → load strategy
  [2]  Git checkpoint
         git checkout -b genpy/review/<timestamp>
  [3]  Resolve range
         --lines N-M
         --function name
         --class name
         --method Class.method
         → produce START, END
  [4]  Build context
         full imports (fixed top zone)
         summarized signatures (top and bottom zones)
         full focal chunk (START..END)
  [5]  Assemble prompt
         Section 1: Role and constraints
         Section 2: Review goal
         Section 3: Context (read-only)
         Section 4: Target fragment
  [6]  ai_complete() with explicit timeout
         → focal_chunk.tmp
  [7]  5 guardians (cheapest first):
         G1: non-empty output
         G2: no markdown/conversational text
         G3: line count 70%-130% of original
         G4: validate_syntax() from the strategy
         G5: public signatures present
       Failure → [R]etry / [A]bort / [E]dit
       Max retries: 2 (configurable)
  [8]  Re-assemble + full validate_syntax()
         head + focal_chunk.tmp + tail
  [9]  Visual diff + confirmation
         diff --color=always | less -R
         [A]ccept / [R]eject / [E]dit
  [10] Apply or Rollback
         Accept: cp + git commit
         Reject: git checkout + branch delete

### 5.5 The genpy create Flow (7 Steps, Stable)

  [1]  Banner + project name
         Validation: ^[a-zA-Z0-9][a-zA-Z0-9_-]*$
         Rejects: spaces, /, ., $, leading dash
  [2]  preflight_mode_create()
  [3]  select_git_mode()
  [4]  select_area() → select_blueprint()
  [5]  select_blueprint_addons()
  [6]  print_blueprint_card() + confirm_creation()
  [7]  copy_template()
         → rsync of template to destination directory
         → _sed_inplace {{PROJECT_NAME}} in .env and text files
         → _inject_env_secrets(): generates secrets for {{SECRET_HEX_N}}
              and resolves cross-references {{VAR_NAME}} in the same .env
       → inject_blueprint_addons()
       → setup_git_repository()
       → check_docker_daemon() + inspect_blueprint_ports()

  .env secrets per blueprint:
    web-fastapi-postgres  DB_PASSWORD (32 bytes), consistent DATABASE_URL
    web-go-gin-clean      DB_PASSWORD (32 bytes)
    ai-ml-pytorch         JUPYTER_TOKEN (24 bytes)
    web-node-nest-mongo   JWT_SECRET (32 bytes)
    infra-monitoring-stack GF_SECURITY_ADMIN_PASSWORD (16 bytes)

### 5.6 Chunking with Semantic Sort (Week 5)

  Active when: file > 500 lines
  Processing order by level:
    0 → imports and global constants
    1 → models and base classes
    2 → services and repositories
    3 → routers and controllers
    4 → entry point (main/app)
  Cumulative context between chunks:
    accumulated_context += extract_signatures(chunk_revised)
  Reassembly: by original START_LINE,
              not by processing order

---

## 6. The Blueprint Contract

  File: <project>/.genpy/blueprint.toml

  [meta]
  name         = string
  version      = semver
  language     = python|go|javascript|bash|infra
  runtime      = string
  description  = string

  [ai_context]
  editable_files               = [glob patterns]
  protected_files              = [glob patterns]
  include_decorators_in_chunk  = true
  include_block_comments       = true

  [[ai_context.dependency_map]]
  source  = "relative path"
  affects = ["relative paths"]

  [validation]
  syntax_check      = "command with {file}"
  semantic_check    = "optional docker command"
  semantic_timeout  = 60

  [review]
  default_goal    = "optional string"
  max_chunk_lines = 150

  [git]
  checkpoint_prefix    = "chore(genpy): checkpoint"
  review_branch_prefix = "genpy/review"

---

## 7. Cascading Configuration

  Priority (highest wins):
    1. CLI flags
    2. <project>/.genpy/blueprint.toml
    3. ~/.config/genpy/config.toml
    4. Defaults in config.sh

  Scopes:
    /usr/local/lib/genpy/    Installation (read-only)
    ~/.config/genpy/         Global user
    <project>/.genpy/        Project-specific

---

## 8. Threat Model

  A1 — Path traversal in blueprint.toml
       Mitigation: validate relative paths inside
       the project directory. Reject .. and
       absolute paths.

  A2 — Prompt injection via user code
       Mitigation: system prompt establishes that
       the focal chunk is data, not instructions.

  A3 — Ollama exposed on the network
       Mitigation: preflight verifies that Ollama
       listens only on 127.0.0.1.

---

## 9. Roadmap

  Week 0 — Fixes ✅ Complete
    R1-R12 resolved.

  Week 1 — Portable Foundation ✅ Complete
    compat.sh, errors.sh, preflight.sh (create mode)
    i18n/en.sh + es.sh
    CONTEXT.md + ARCHITECTURE.md

  Phase 0 — Create flow stabilization ✅ Complete (2026-05-28)
    Fix Ctrl+C: separate EXIT and INT/TERM traps in errors.sh.
    Fix config.sh: include guard + explicit source in wizard.sh.
    Fix sed Linux: _sed_inplace() in libs.sh (requirements.txt filter).
    Fix implicit dependencies: utils.sh sourced in docker.sh,
      libs.sh, git_manager.sh with include guard.
    Fix project name validation: regex + i18n.
    Fix rsync: copy_template() validates template_dir and non-empty copy.
    Fix subshell: pipe → process substitution in template.sh.
    Fix git push: 2>/dev/null removed, real error visible.
    .env secrets: _generate_secret() + _inject_env_secrets() in
      template.sh. 5 blueprints with unique per-project credentials.

  Week 2 — Review Engine without AI ✅ Complete
    blueprint.toml integrated in genpy create ✅
    resolver.sh — resolve_range() with 4 modes ✅ (24 tests)
    guardians.sh — G1-G5 + run_guardians() ✅ (44 tests)
    assembler.sh — context/prompt/reassemble ✅ (48 tests)
    review_strategies/python.sh functional ✅
    git_manager.sh — create_checkpoint/rollback ✅ (32 tests)
    Total: 148 tests in pure bash, 148 PASS / 0 FAIL

  Week 3 — AI Integration ⏳ Pending
    providers/ollama.sh + api.sh
    review.sh orchestrator (10 steps)
    preflight_mode_review()
    Circuit breaker for Ollama
    Tag v1.1.0-beta

  Week 4 — Distribution ⏳ Pending
    install.sh rewritten (4 phases)
    doctor.sh
    update.sh with SHA256
    Public README + docs/
    Tag v1.1.0 stable

  Week 5 — Expansion ⏳ Pending
    review_strategies/go.sh + javascript.sh
    Semantic chunking with sort by level
    providers/api.sh complete
    brew formula draft
    Tag v1.2.0

---

## 10. Known Limitations of v1

  - Nested functions and closures are out of scope
    for the resolver in v1.
  - TypeScript uses the javascript strategy.
  - 3B models degrade with files > 200 lines
    without chunking.
  - infra and cyber blueprints have no review
    strategy (language = infra).
  - Third-party blueprints not supported in v1.
  - tests/ in pure bash (148 tests); bats-core discarded, CI active.
  - doctor.sh pending Week 4.
