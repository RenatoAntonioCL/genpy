# ADR-0008: Detección semántica híbrida (C2)

- **Estado:** Aceptada
- **Origen:** `CONTEXT.md` → "Decisiones Cerradas" (C2)

## Contexto

Para resolver símbolos y armar contexto hay que entender la estructura del archivo. Un
parser completo en cada lenguaje es caro; depender de un runtime (python3) en todos lados
no es portable.

## Decisión

**Detección híbrida**: Bash/grep/awk como **camino principal**, y el **runtime nativo
(python3 `ast`) como fallback** cuando hace falta precisión.

## Consecuencias

- (+) Funciona sin dependencias en el caso común; usa el parser real solo cuando se
  necesita.
- (+) Coherente con la estrategia de chunking semántico que evita alucinaciones de
  modelos chicos (ver "Lo que sabemos que no funciona").
- (−) Dos caminos de código a mantener y mantener consistentes.

## Nota

Referenciada con el código `(C2)` en comentarios de `lib/resolver.sh` y
`lib/assembler.sh`; conservar ese código facilita la trazabilidad.
