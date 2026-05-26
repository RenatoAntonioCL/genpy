# Seguridad

## Reportar vulnerabilidades

Abre un issue privado o contacta al mantenedor: [RenatoAntonioCL](https://github.com/RenatoAntonioCL).

## Modelo de amenazas (resumen)

Ver [ARCHITECTURE.md §8](../ARCHITECTURE.md):

- Path traversal en `blueprint.toml` — rutas relativas validadas.
- Prompt injection — el focal chunk se trata como datos, no instrucciones.
- Ollama en red — preflight exige `127.0.0.1` (Semana 3).

## Blueprints de seguridad (cyber)

Solo para laboratorios autorizados. No desplegar en redes de producción.
