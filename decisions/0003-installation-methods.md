# ADR-0003: Métodos de instalación (A3)

- **Estado:** Aceptada
- **Origen:** `CONTEXT.md` → "Decisiones Cerradas" (A3)

## Contexto

Los usuarios llegan por distintos caminos; forzar un único método de instalación
genera fricción.

## Decisión

Soportar **`git clone` + `install.sh`** *y* gestores de paquetes.

## Consecuencias

- (+) Camino simple para probar (clonar e instalar) y camino integrado para quienes
  usan un package manager.
- (−) Más superficie a mantener: `scripts/install.sh`, `update.sh`, `uninstall.sh`
  deben quedar coherentes con la vía de package manager.
