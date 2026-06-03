# ADR-0004: Model Detection in Ollama (B1)

- **Status:** Accepted
- **Source:** `CONTEXT.md` → "Closed Decisions" (B1)

## Context

The review engine can use local models via Ollama, but it cannot assume which model
the user has installed.

## Decision

**Detect the available model** in Ollama at runtime, with a **guaranteed fallback
to `qwen2.5:3b`**.

## Consequences

- (+) Works without configuration: uses whatever is available, and if nothing usable
  is found, falls back to a known small model.
- (−) `qwen2.5:3b` is a small model with known limitations (see ADR-0008 and "Known
  Limitations"): hallucinates with long files without semantic chunking.
