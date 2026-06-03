# ADR-0002: Supported Platforms (A2)

- **Status:** Accepted
- **Source:** `CONTEXT.md` → "Closed Decisions" (A2)

## Context

We need to define where GenPy is guaranteed to work, to be able to test and provide
support without spreading too thin.

## Decision

Support for **Linux + macOS + WSL2** from v1.

## Consequences

- (+) Covers common development environments with a single portable codebase.
- (−) Requires careful portability (e.g. `lsof` is not available on all distros → resolved
  with `_port_in_use()` in `compat.sh`). Native Windows (without WSL2) is excluded.
