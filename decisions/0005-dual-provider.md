# ADR-0005: Proveedor dual de IA (B2)

- **Estado:** Aceptada
- **Origen:** `CONTEXT.md` → "Decisiones Cerradas" (B2)

## Contexto

Algunos usuarios prefieren correr modelos localmente (privacidad, costo cero) y otros
quieren la calidad de una API externa.

## Decisión

**Provider dual**: Ollama (local) + API externa, detrás de una **abstracción** común
(`lib/providers/`).

## Consecuencias

- (+) El motor de review no depende del backend; se puede cambiar sin tocar la lógica.
- (+) Habilita tanto el uso offline como el de mayor calidad.
- (−) Hay que mantener la paridad de la interfaz entre ambos providers.
