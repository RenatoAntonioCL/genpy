# Contributing

1. Read [CONTEXT.md](../CONTEXT.md) and [ARCHITECTURE.md](../ARCHITECTURE.md) before opening a PR.
2. Pure bash in `lib/` — do not hardcode blueprints outside `lib/core/config.sh`.
3. One change per responsibility; `trap` in flows that touch user files.
4. Tests in pure bash in `tests/` (no bats); run `tests/unit/*.sh` before the PR.

## Branches

- `main` — stable / tagged checkpoints
- Features per roadmap week (`semana-2-review`, etc.)
