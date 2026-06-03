# ADR-0011: Testing and CI Strategy (D2)

- **Status:** Accepted (revises the original intent of D2)
- **Source:** `CONTEXT.md` → "Closed Decisions" (D2)

## Context

The project needs an automated test suite running on every change. The original decision
(D2) planned for **bats-core**, but in practice it was dropped: bats adds an external
dependency and the tests were better solved in **pure bash** with custom mocks (including
an Ollama mock), without needing python3.

## Decision

- **Tests in pure bash, no bats.** Each `tests/unit/*.sh` file runs standalone and
  prints its summary `N PASS / M FAIL`.
- **CI on GitHub Actions** (`.github/workflows/ci.yml`): a syntax job (`bash -n` +
  `docker-compose` validation of the templates) and a `unit` job that runs the four
  test files with `GUARDIAN_NON_INTERACTIVE=1`.

## Consequences

- (+) No testing dependencies outside of Bash; consistent with the rule "the CLI does
  not depend on Python/Node/Go on the host".
- (+) Automatic validation on every push/PR to `main`; green CI as a health signal.
- (−) No framework sugar (TAP, tags, parallelism): the runner is homegrown.

## Suite Status

148 tests passing: `test_resolver.sh` (24), `test_guardians.sh` (44),
`test_assembler.sh` (48), `test_checkpoint.sh` (32).

## Note

Supersedes the "bats-core" part of D2. The D2 code is preserved for traceability.
