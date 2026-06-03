# ADR-0008: Hybrid Semantic Detection (C2)

- **Status:** Accepted
- **Source:** `CONTEXT.md` → "Closed Decisions" (C2)

## Context

To resolve symbols and build context, the file structure must be understood. A full
per-language parser is expensive; depending on a runtime (python3) everywhere is not
portable.

## Decision

**Hybrid detection**: Bash/grep/awk as the **main path**, and the **native runtime
(python3 `ast`) as fallback** when precision is needed.

## Consequences

- (+) Works without dependencies in the common case; uses the real parser only when
  needed.
- (+) Consistent with the semantic chunking strategy that avoids hallucinations from
  small models (see "Known Limitations").
- (−) Two code paths to maintain and keep consistent.

## Note

Referenced with the code `(C2)` in comments in `lib/resolver.sh` and
`lib/assembler.sh`; preserving that code facilitates traceability.
