# ADR-0001: Versión mínima de Bash (A1)

- **Estado:** Aceptada
- **Origen:** `CONTEXT.md` → "Decisiones Cerradas" (A1)

## Contexto

GenPy es una CLI escrita en Bash. Necesita fijar un intérprete mínimo soportado para
poder usar características modernas (arrays asociativos, `${var,,}`, etc.) sin romper en
entornos viejos.

## Decisión

Bash **4.x** como mínimo. `lib/core/compat.sh` detecta la versión y la valida en el
preflight.

## Consecuencias

- (+) Permite usar features de Bash 4 sin guardas por todos lados.
- (−) Excluye el Bash 3.2 que macOS trae por defecto: el usuario debe instalar Bash
  moderno (Homebrew). `compat.sh` lo detecta y avisa.

## Nota

Hay una inconsistencia a resolver: `CONTEXT.md` registra "Bash 4.0+" mientras que
`README.md` (sección Requisitos) y el badge piden "Bash 4.3+". Conviene unificar el
número exacto en código (`compat.sh`), README y este ADR.
