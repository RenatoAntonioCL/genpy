# ADR-0009: Decorators and Comments Included by Default (C3)

- **Status:** Accepted
- **Source:** `CONTEXT.md` → "Closed Decisions" (C3)

## Context

When extracting a symbol (function/method) for review, we need to decide whether to
include its associated decorators and comments or only the body.

## Decision

**Include decorators and comments by default**, configurable in `blueprint.toml`.

## Consequences

- (+) The context sent to the review is complete and faithful to the real code.
- (+) Anyone who needs different behavior can adjust it per blueprint, without changing
  the engine.
- (−) Slightly increases the size of the chunk sent to the model.
