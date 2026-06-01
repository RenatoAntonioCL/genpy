# ADR-0012: Solo blueprints oficiales en v1 (D3)

- **Estado:** Aceptada
- **Origen:** `CONTEXT.md` → "Decisiones Cerradas" (D3)

## Contexto

GenPy genera proyectos desde blueprints. Permitir blueprints arbitrarios de terceros
desde el día uno abre superficie de seguridad y soporte difícil de garantizar.

## Decisión

En la v1, **solo blueprints oficiales** del propio repositorio (`templates/`).

## Consecuencias

- (+) Cada stack generado está versionado, probado y con credenciales únicas
  garantizadas por el proyecto.
- (+) Reduce el riesgo de ejecutar plantillas no confiables.
- (−) No hay (todavía) blueprints de la comunidad ni rutas externas; queda como
  posible evolución post-v1.
