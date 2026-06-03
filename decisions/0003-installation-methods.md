# ADR-0003: Installation Methods (A3)

- **Status:** Accepted
- **Source:** `CONTEXT.md` → "Closed Decisions" (A3)

## Context

Users arrive through different paths; forcing a single installation method creates
friction.

## Decision

Support **`git clone` + `install.sh`** *and* package managers.

## Consequences

- (+) Simple path to try it out (clone and install) and an integrated path for those
  who use a package manager.
- (−) More surface to maintain: `scripts/install.sh`, `update.sh`, `uninstall.sh`
  must stay consistent with the package manager path.
