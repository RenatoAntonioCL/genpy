# ADR-0011: Estrategia de tests y CI (D2)

- **Estado:** Aceptada, **parcialmente revisada** (ver Nota)
- **Origen:** `CONTEXT.md` → "Decisiones Cerradas" (D2)

## Contexto

El proyecto necesita una suite de tests automatizada corriendo en cada cambio.

## Decisión

Tests con **bats-core** + **CI en GitHub Actions** (`.github/workflows/ci.yml`).

## Consecuencias

- (+) Validación automática en cada push/PR a `main`.
- (+) CI verde como señal de salud del repo.

## Nota — divergencia con la implementación actual

La parte de **CI en GitHub Actions se cumple** (`ci.yml` activo y en verde). Pero la
implementación de tests **divergió de bats-core**: según el `CHANGELOG`, la suite actual
son ~116 tests en **bash puro (sin bats)**, con una estrategia de mocks sin python3
(p. ej. `tests/unit/test_resolver.sh`, `test_guardians.sh`, `test_assembler.sh`).

Acción sugerida: actualizar esta decisión (o abrir un ADR sucesor) para reflejar
"bash puro sin bats" como la estrategia vigente, y alinear `CONTEXT.md`.
