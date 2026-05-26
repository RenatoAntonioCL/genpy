# Contribuir

1. Lee [CONTEXT.md](../CONTEXT.md) y [ARCHITECTURE.md](../ARCHITECTURE.md) antes de abrir un PR.
2. Bash puro en `lib/` — sin hardcodear blueprints fuera de `lib/core/config.sh`.
3. Un cambio por responsabilidad; `trap` en flujos que toquen archivos del usuario.
4. Tests con bats-core en `tests/` (cuando existan).

## Ramas

- `main` — estable / checkpoints etiquetados
- Features por semana del roadmap (`semana-2-review`, etc.)
