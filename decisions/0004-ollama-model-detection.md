# ADR-0004: Detección de modelo en Ollama (B1)

- **Estado:** Aceptada
- **Origen:** `CONTEXT.md` → "Decisiones Cerradas" (B1)

## Contexto

El motor de review puede usar modelos locales vía Ollama, pero no se puede asumir qué
modelo tiene instalado el usuario.

## Decisión

**Detectar el modelo disponible** en Ollama en tiempo de ejecución, con un **fallback
garantizado a `qwen2.5:3b`**.

## Consecuencias

- (+) Funciona sin configuración: usa lo que haya, y si no hay nada usable, cae a un
  modelo pequeño conocido.
- (−) `qwen2.5:3b` es un modelo chico con límites conocidos (ver ADR-0008 y "Lo que
  sabemos que no funciona"): alucina con archivos largos sin chunking semántico.
