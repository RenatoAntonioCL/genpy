# ADR-0001: Versión mínima de Bash (A1)

- **Estado:** Aceptada
- **Origen:** `CONTEXT.md` → "Decisiones Cerradas" (A1)

## Contexto

GenPy es una CLI escrita en Bash. Necesita fijar un intérprete mínimo soportado. El
código usa **namerefs** (`local -n`) en `lib/libs.sh`, `lib/guardians.sh` y
`lib/ui/menus.sh`. Los namerefs existen **desde Bash 4.3**, así que ese es el piso real,
no 4.0.

## Decisión

Bash **4.3+** como mínimo. `lib/core/compat.sh` lo valida en el preflight y aborta con
un mensaje claro (con tip de `brew install bash` en macOS).

## Consecuencias

- (+) Permite usar namerefs y demás features de Bash 4.3 sin guardas.
- (−) Excluye el Bash 3.2 que macOS trae por defecto: el usuario debe instalar Bash
  moderno (Homebrew). `compat.sh` lo detecta y avisa.

## Historial

- Inicialmente se documentó "Bash 4.0+" y `compat.sh` solo chequeaba el *major*
  (`BASH_VERSINFO < 4`). Eso era un **bug**: permitía pasar con Bash 4.0–4.2 y luego
  fallaba al ejecutar namerefs. Corregido para exigir 4.3 (major+minor). README, badge,
  `docs/INSTALL.md` y `ARCHITECTURE.md` quedaron unificados en 4.3+.
