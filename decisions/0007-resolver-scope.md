# ADR-0007: Resolver v1 Scope (C1)

- **Status:** Accepted
- **Source:** `CONTEXT.md` → "Closed Decisions" (C1)

## Context

`lib/resolver.sh` translates selectors (`--lines`, `--function`, `--class`,
`--method Clase.método`) to a line range. We need to define what cases v1 covers to
avoid chasing every possible input selector.

## Decision

Resolver v1 supports **top-level symbols + `Clase.método`**.

## Consequences

- (+) Covers the most frequent use cases with a bounded implementation.
- (−) Deeper nesting or non-top-level symbols are out of scope (for now).
