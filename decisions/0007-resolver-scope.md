# ADR-0007: Alcance del resolver v1 (C1)

- **Estado:** Aceptada
- **Origen:** `CONTEXT.md` → "Decisiones Cerradas" (C1)

## Contexto

`lib/resolver.sh` traduce selectores (`--lines`, `--function`, `--class`,
`--method Clase.método`) a un rango de líneas. Hay que acotar qué casos cubre la v1 para
no perseguir todos los selectores posibles de entrada.

## Decisión

Resolver v1 soporta **símbolos top-level + `Clase.método`**.

## Consecuencias

- (+) Cubre los casos de uso más frecuentes con una implementación acotada.
- (−) Quedan fuera (por ahora) anidamientos más profundos o símbolos no top-level.
