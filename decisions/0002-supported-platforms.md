# ADR-0002: Plataformas soportadas (A2)

- **Estado:** Aceptada
- **Origen:** `CONTEXT.md` → "Decisiones Cerradas" (A2)

## Contexto

Hay que acotar dónde se garantiza que GenPy funciona, para poder testear y dar soporte
sin dispersarse.

## Decisión

Soporte para **Linux + macOS + WSL2** desde la v1.

## Consecuencias

- (+) Cubre los entornos de desarrollo habituales con una sola base de código portable.
- (−) Obliga a cuidar portabilidad (ej. `lsof` no está en todas las distros → se
  resolvió con `_port_in_use()` en `compat.sh`). Windows nativo (sin WSL2) queda fuera.
