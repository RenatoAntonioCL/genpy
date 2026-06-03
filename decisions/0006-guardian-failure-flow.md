# ADR-0006: Guardian Failure Flow (B3)

- **Status:** Accepted
- **Source:** `CONTEXT.md` → "Closed Decisions" (B3)

## Context

The guardians (`lib/guardians.sh`, G1–G5) validate the review output. When one
fails, we need to decide what to do without losing user control or corrupting the file.

## Decision

On guardian failure, offer: **[R]etry / [A]bort / [E]dit manually**.
Configurable with `GUARDIAN_MAX_RETRIES` and `GUARDIAN_NON_INTERACTIVE`.

## Consequences

- (+) The user decides; output that did not pass the gates is never applied blindly.
- (+) Non-interactive mode allows use in CI/scripts.
- (−) Adds interaction steps to the happy path when a small model fails repeatedly.
