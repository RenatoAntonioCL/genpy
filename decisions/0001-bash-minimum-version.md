# ADR-0001: Minimum Bash Version (A1)

- **Status:** Accepted
- **Source:** `CONTEXT.md` → "Closed Decisions" (A1)

## Context

GenPy is a CLI written in Bash. It needs to set a minimum supported interpreter. The
code uses **namerefs** (`local -n`) in `lib/libs.sh`, `lib/guardians.sh` and
`lib/ui/menus.sh`. Namerefs exist **since Bash 4.3**, so that is the real floor,
not 4.0.

## Decision

Bash **4.3+** as the minimum. `lib/core/compat.sh` validates this during preflight and
aborts with a clear message (with a `brew install bash` tip on macOS).

## Consequences

- (+) Allows using namerefs and other Bash 4.3 features without guards.
- (−) Excludes the Bash 3.2 that macOS ships by default: the user must install
  a modern Bash (Homebrew). `compat.sh` detects this and warns.

## History

- Initially documented as "Bash 4.0+" and `compat.sh` only checked the *major*
  (`BASH_VERSINFO < 4`). That was a **bug**: it let Bash 4.0–4.2 pass and then
  failed when executing namerefs. Fixed to require 4.3 (major+minor). README, badge,
  `docs/INSTALL.md` and `ARCHITECTURE.md` were unified at 4.3+.
