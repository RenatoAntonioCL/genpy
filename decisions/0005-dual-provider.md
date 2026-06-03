# ADR-0005: Dual AI Provider (B2)

- **Status:** Accepted
- **Source:** `CONTEXT.md` → "Closed Decisions" (B2)

## Context

Some users prefer running models locally (privacy, zero cost) and others want the
quality of an external API.

## Decision

**Dual provider**: Ollama (local) + external API, behind a common **abstraction**
(`lib/providers/`).

## Consequences

- (+) The review engine does not depend on the backend; it can be swapped without
  touching the logic.
- (+) Enables both offline use and higher-quality results.
- (−) Interface parity between both providers must be maintained.
