# ADR-0006: Flujo ante fallo de un guardián (B3)

- **Estado:** Aceptada
- **Origen:** `CONTEXT.md` → "Decisiones Cerradas" (B3)

## Contexto

Los guardianes (`lib/guardians.sh`, G1–G5) validan la salida del review. Cuando uno
falla hay que decidir qué hacer sin perder el control el usuario ni romper el archivo.

## Decisión

Ante un fallo de guardián, ofrecer: **[R]eintentar / [A]bortar / [E]ditar manual**.
Configurable con `GUARDIAN_MAX_RETRIES` y `GUARDIAN_NON_INTERACTIVE`.

## Consecuencias

- (+) El usuario decide; nunca se aplica a ciegas una salida que no pasó los gates.
- (+) El modo no interactivo permite usarlo en CI/scripts.
- (−) Suma pasos de interacción en el flujo feliz cuando un modelo chico falla seguido.
