# ADR-0009: Decoradores y comentarios incluidos por defecto (C3)

- **Estado:** Aceptada
- **Origen:** `CONTEXT.md` → "Decisiones Cerradas" (C3)

## Contexto

Al extraer un símbolo (función/método) para review, hay que decidir si se arrastran sus
decoradores y comentarios asociados o solo el cuerpo.

## Decisión

**Incluir decoradores y comentarios por defecto**, configurable en `blueprint.toml`.

## Consecuencias

- (+) El contexto enviado al review es completo y fiel al código real.
- (+) Quien necesite otro comportamiento lo ajusta por blueprint, sin cambiar el motor.
- (−) Aumenta levemente el tamaño del chunk enviado al modelo.
