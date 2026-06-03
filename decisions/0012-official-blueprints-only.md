# ADR-0012: Official Blueprints Only in v1 (D3)

- **Status:** Accepted
- **Source:** `CONTEXT.md` → "Closed Decisions" (D3)

## Context

GenPy generates projects from blueprints. Allowing arbitrary third-party blueprints
from day one opens a security and support surface that is hard to guarantee.

## Decision

In v1, **only official blueprints** from the repository itself (`templates/`).

## Consequences

- (+) Every generated stack is versioned, tested, and has unique credentials guaranteed
  by the project.
- (+) Reduces the risk of executing untrusted templates.
- (−) There are no community blueprints or external paths (yet); this remains a possible
  post-v1 evolution.
