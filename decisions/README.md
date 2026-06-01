# Architecture Decision Records (ADRs)

Decisiones de diseño cerradas del proyecto GenPy.

Formato: `NNNN-titulo-corto.md`. Cada ADR conserva entre paréntesis su **código
original** (A1–D3) tal como se referencia en `CONTEXT.md` y en comentarios del código
(ej. `(C2)`), para mantener la trazabilidad.

## Índice

| ADR | Código | Decisión | Estado |
|-----|--------|----------|--------|
| [0001](0001-bash-minimum-version.md) | A1 | Versión mínima de Bash | Aceptada |
| [0002](0002-supported-platforms.md) | A2 | Plataformas soportadas (Linux/macOS/WSL2) | Aceptada |
| [0003](0003-installation-methods.md) | A3 | Métodos de instalación (clone + package managers) | Aceptada |
| [0004](0004-ollama-model-detection.md) | B1 | Detección de modelo en Ollama (+ fallback) | Aceptada |
| [0005](0005-dual-provider.md) | B2 | Proveedor dual (Ollama + API) abstraído | Aceptada |
| [0006](0006-guardian-failure-flow.md) | B3 | Flujo ante fallo de guardián (R/A/E) | Aceptada |
| [0007](0007-resolver-scope.md) | C1 | Alcance del resolver v1 | Aceptada |
| [0008](0008-hybrid-semantic-detection.md) | C2 | Detección semántica híbrida (bash + ast) | Aceptada |
| [0009](0009-decorators-comments-default.md) | C3 | Decoradores y comentarios por defecto | Aceptada |
| [0010](0010-i18n-en-es.md) | D1 | i18n inglés + español | Aceptada |
| [0011](0011-testing-and-ci.md) | D2 | Tests bash puro (sin bats) + CI GitHub Actions | Aceptada |
| [0012](0012-official-blueprints-only.md) | D3 | Solo blueprints oficiales en v1 | Aceptada |

> Migración completada: las decisiones A1–D3 que vivían en `CONTEXT.md` están ahora como
> ADRs formales. ADR-0001 fija el mínimo real de Bash en 4.3 (namerefs) y ADR-0011
> registra la estrategia vigente de tests en bash puro (sin bats); ambas reconciliadas
> con el código y el resto de los documentos.
