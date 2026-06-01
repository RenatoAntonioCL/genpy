# ADR-0011: Estrategia de tests y CI (D2)

- **Estado:** Aceptada (revisa la intención original de D2)
- **Origen:** `CONTEXT.md` → "Decisiones Cerradas" (D2)

## Contexto

El proyecto necesita una suite de tests automatizada corriendo en cada cambio. La
decisión original (D2) preveía **bats-core**, pero en la práctica se descartó: bats
añade una dependencia externa y los tests se resolvieron mejor en **bash puro** con
mocks propios (incluido un mock de Ollama), sin necesidad de python3.

## Decisión

- **Tests en bash puro, sin bats.** Cada archivo `tests/unit/*.sh` corre standalone e
  imprime su resumen `N PASS / M FAIL`.
- **CI en GitHub Actions** (`.github/workflows/ci.yml`): job de sintaxis (`bash -n` +
  validación de `docker-compose` de los templates) y job `unit` que ejecuta los cuatro
  archivos de test con `GUARDIAN_NON_INTERACTIVE=1`.

## Consecuencias

- (+) Sin dependencias de testing fuera de Bash; coherente con la regla "el CLI no
  depende de Python/Node/Go en el host".
- (+) Validación automática en cada push/PR a `main`; CI verde como señal de salud.
- (−) Sin el azúcar de un framework (TAP, tags, paralelismo): el runner es casero.

## Estado de la suite

148 tests en verde: `test_resolver.sh` (24), `test_guardians.sh` (44),
`test_assembler.sh` (48), `test_checkpoint.sh` (32).

## Nota

Supersede la parte "bats-core" de D2. Se conserva el código D2 por trazabilidad.
