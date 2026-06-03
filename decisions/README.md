# Architecture Decision Records (ADRs)

Closed design decisions for the GenPy project.

Format: `NNNN-short-title.md`. Each ADR preserves its **original code** in parentheses
(A1–D3) as referenced in `CONTEXT.md` and in code comments (e.g. `(C2)`),
to maintain traceability.

## Index

| ADR | Code | Decision | Status |
|-----|------|----------|--------|
| [0001](0001-bash-minimum-version.md) | A1 | Minimum Bash version | Accepted |
| [0002](0002-supported-platforms.md) | A2 | Supported platforms (Linux/macOS/WSL2) | Accepted |
| [0003](0003-installation-methods.md) | A3 | Installation methods (clone + package managers) | Accepted |
| [0004](0004-ollama-model-detection.md) | B1 | Model detection in Ollama (+ fallback) | Accepted |
| [0005](0005-dual-provider.md) | B2 | Dual provider (Ollama + API) abstracted | Accepted |
| [0006](0006-guardian-failure-flow.md) | B3 | Guardian failure flow (R/A/E) | Accepted |
| [0007](0007-resolver-scope.md) | C1 | Resolver v1 scope | Accepted |
| [0008](0008-hybrid-semantic-detection.md) | C2 | Hybrid semantic detection (bash + ast) | Accepted |
| [0009](0009-decorators-comments-default.md) | C3 | Decorators and comments by default | Accepted |
| [0010](0010-i18n-en-es.md) | D1 | i18n English + Spanish | Accepted |
| [0011](0011-testing-and-ci.md) | D2 | Pure bash tests (no bats) + CI GitHub Actions | Accepted |
| [0012](0012-official-blueprints-only.md) | D3 | Official blueprints only in v1 | Accepted |

> Migration complete: the A1–D3 decisions that lived in `CONTEXT.md` are now formal
> ADRs. ADR-0001 sets the real Bash minimum at 4.3 (namerefs) and ADR-0011
> records the current pure-bash testing strategy (no bats); both reconciled
> with the code and the rest of the documents.
