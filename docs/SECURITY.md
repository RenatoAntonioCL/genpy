# Seguridad

## Reportar vulnerabilidades

Abre un issue privado o contacta al mantenedor: [RenatoAntonioCL](https://github.com/RenatoAntonioCL).

## Modelo de amenazas (resumen)

Ver [ARCHITECTURE.md §8](../ARCHITECTURE.md):

- Path traversal en `blueprint.toml` — rutas relativas validadas.
- Prompt injection — el focal chunk se trata como datos, no instrucciones.
- Ollama en red — preflight exige `127.0.0.1` (Semana 3).

## Manejo de secretos

- **Únicos por proyecto.** Cada proyecto generado recibe secretos propios vía
  `openssl rand` (fallback `/dev/urandom`). No hay valores fijos ni `changeme`.
- **Nunca llegan a git.** El `.env` generado se ignora por defecto (el `.gitignore`
  que crea GenPy incluye `.env`) y queda con permisos `600` (solo el dueño lo lee).
- **Plantillas sin secretos reales.** Los `.env` versionados en `templates/` contienen
  solo placeholders (`{{SECRET_HEX_N}}`) o valores dummy; no credenciales reales.
- **Token de GitHub.** Se lee en modo silencioso (`read -rsp`) desde `GITHUB_TOKEN` /
  `GH_TOKEN` / `gh`, y se envía a la API por stdin (`curl -H @-`), nunca como argumento,
  para que no quede visible en la lista de procesos (`ps`).

## Integridad de instalación y updates

- La instalación copia desde el repositorio local; no hay `curl | bash`.
- El updater clona la rama `main` por **HTTPS** (autenticidad por TLS de GitHub) y
  **verifica la integridad estructural del clon** (archivos clave presentes y no vacíos)
  **antes** de reemplazar la instalación: si el clon viene incompleto, aborta sin
  destruir la versión que ya funciona. Reporta el commit al que actualiza.
- Mejora futura: verificación de **firma GPG** de tags / pin a release firmada.

## Blueprints de seguridad (cyber)

Solo para laboratorios autorizados. No desplegar en redes de producción.
