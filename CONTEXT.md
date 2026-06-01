# genpy — AI Context Brief

> Cargar este archivo al inicio de cada sesión de trabajo.
> Última actualización: 2026-05-28
> Estado: Semana 2 completa — motor de review sin IA operativo (148 tests)

---

## ¿Qué es genpy?

CLI modular en Bash para automatizar el despliegue y gestión
de arquitecturas de software mediante blueprints contenerizados
(Docker). Permite generar proyectos completos desde plantillas
y, en versiones futuras, revisarlos con IA local (Ollama)
o APIs externas.

Versión actual:  1.0.0-alpha
Distribución:    git clone + install.sh / brew / apt

---

## Estado Actual

Funciona hoy:
  genpy create → flujo completo y estable
    - Preflight: valida Docker, Git, disco, permisos
    - UI bilingüe: español e inglés via i18n/
    - 9 blueprints con docker-compose alineados (Modelo A/B)
    - Política de puertos: APIs en 127.0.0.1, BD solo red interna
    - Aditivos inyectables por blueprint
    - Git init automático (local/privado/público → crea repo en GitHub vía API)
    - Remapeo automático de puertos ocupados en docker-compose.yml
    - Templates web/AI con Dockerfiles corregidos y buildables

No existe todavía:
  genpy review  → Semana 3 (orchestrador 10 pasos, requiere providers IA)
  genpy doctor  → Semana 4
  decisions/    → ADRs formales A1–D3 (migrados; ver decisions/README.md)
  tests bats    → los tests actuales son bash puro; bats-core pendiente

Semana 2 completa:
  resolver ✅, guardians ✅, assembler ✅, git_manager checkpoints ✅
  review_strategies/python.sh: funcional; go/js Semana 5
  148 tests en bash puro (24 resolver + 44 guardians + 48 assembler + 32 checkpoint)

---

## Estructura Real del Proyecto

  bin/
    genpy                   Entry point. Resuelve rutas,
                            carga i18n, define comandos.

  lib/core/
    compat.sh               Detecta OS, arquitectura, Bash 4+.
                            Provee _port_in_use() portable y
                            _find_free_port() para auto-remapeo.
                            Exporta: GENPY_OS, GENPY_ARCH.
    config.sh               Fuente única de verdad del dominio.
                            Arrays: AREAS, AREA_BLUEPRINTS,
                            BLUEPRINT_META, ADDON_PACKAGES,
                            ADDON_LABELS, ADDON_INDEX.
                            Función: blueprint_meta().
    errors.sh               trap EXIT/INT/TERM.
                            Colores propios: _ERR_RED, _ERR_NC.
                            Funciones: die(), require_command(),
                            require_dir().
                            Autónomo: no depende de utils.sh.
    preflight.sh            preflight_mode_create():
                            valida docker, git, disco >500MB,
                            permisos de escritura.

  lib/i18n/
    en.sh                   Diccionario inglés. Cubre: wizard,
                            menus, card, confirmación, errores.
    es.sh                   Diccionario español. Mismo schema.

  lib/ui/
    banner.sh               Banner ASCII. Usa GENPY_VERSION.
    card.sh                 Tarjeta de resumen. Zero hardcoding,
                            todo desde blueprint_meta().
    menus.sh                Menús dinámicos desde config.sh.
                            Contiene: select_area(),
                            select_blueprint(), select_git_mode(),
                            confirm_creation().

  lib/
    utils.sh                Paleta de colores y print_*().
                            UI primitiva. Responsabilidad única.
    libs.sh                 Motor de aditivos. select y inject.
                            _inject_node_addons usa jq (no sed).
                            Filtro Docker en requirements.txt
                            usa _sed_inplace() (portable).
    template.sh             rsync + _sed_inplace() portable.
                            Respeta Modelo A/B (no mueve Dockerfiles).
                            Inyecta {{PROJECT_NAME}} en:
                            .env, *.md, docker-compose.yml, Dockerfile,
                            *.py, *.sh, *.go, go.mod, package.json,
                            nest-cli.json, tsconfig.json
                            _generate_secret(bytes): openssl rand -hex
                            con fallback a /dev/urandom.
                            _inject_env_secrets(env_file): dos pasadas —
                            reemplaza {{SECRET_HEX_N}} y resuelve
                            referencias cruzadas {{VAR_NAME}} en el mismo
                            .env (ej: DATABASE_URL usa {{DB_PASSWORD}}).
    wizard.sh               Orquestador genpy create (7 pasos).
                            Sin lógica de dominio ni UI propia.
    git_manager.sh          setup_git_repository().
                            Crea repo en GitHub vía API REST
                            (_get_github_token, _create_github_repo).
                            Lee GITHUB_TOKEN / GH_TOKEN / gh CLI.
                            Fallback: URL manual si no hay token.
                            select_git_mode() eliminada (vive
                            en menus.sh).
    docker.sh               check_docker_daemon().
                            inspect_blueprint_ports() via
                            blueprint_meta(), _port_in_use().
                            Auto-remapea puertos ocupados con
                            _find_free_port() y parchea
                            docker-compose.yml en el acto.
    review.sh               Stub Semana 3 (orquestador 10 pasos).
    resolver.sh             resolve_range(): --lines, --function,
                            --class, --method Clase.método.
                            Bash + python3 ast fallback (C2).
    guardians.sh            run_guardians() + G1–G5. Retorna
                            0=ok / 1=abort / 2=retry.
                            GUARDIAN_NON_INTERACTIVE para CI.
    assembler.sh            build_review_context(), assemble_prompt(),
                            reassemble_file(). Pasos [4][5][8].
    review_strategies/      python.sh: validate_syntax, extract_signatures,
                            get_prompt_rules. go/js Semana 5.
    providers/              ollama.sh, api.sh — stubs Semana 3/5.

  scripts/
    install.sh              Instalador. Pendiente reescritura
                            con 4 fases.
    uninstall.sh            Funcional.
    update.sh               Funcional. Sin SHA256 todavía.
    doctor.sh               Stub Semana 4.

  tests/                    fixtures/sample.py, fixtures/sample_assembler.txt
                            unit/: test_resolver.sh (24), test_guardians.sh (44),
                                   test_assembler.sh (48) — bash puro, sin bats
                            mocks/ollama_mock.sh
  decisions/                ADRs formales A1–D3 migrados (ver README).
  docs/                     INSTALL, CONTRIBUTING, SECURITY.
  .github/                  workflows/ci.yml, CONTEXT.md → enlace.

  templates/                9 blueprints oficiales.
                            web-fastapi-postgres tiene
                            .genpy/blueprint.toml (referencia).

---

## Modelos de Blueprint

  Modelo A — Servicio único (Dockerfile en raíz del blueprint):
    ai-ml-pytorch, ai-llm-rag,
    cyber-attacker-kali, cyber-lab-victim-win7

  Modelo B — Multi-servicio (Dockerfile en backend/):
    web-fastapi-postgres, web-go-gin-clean,
    web-node-nest-mongo
    docker-compose.yml con context: ./backend

  Sin Dockerfile — Solo configuración en config/:
    infra-local-cluster, infra-monitoring-stack

---

## Principios Inviolables

  P1 — RESILIENCIA ABSOLUTA
    La IA nunca toca archivos vivos directamente.
    Todo cambio pasa por:
    Sandbox(.tmp) → Guardianes → Git → Usuario.

  P2 — BASH PURO Y MODULAR
    Funciones con responsabilidad única.
    trap en todos los puntos de fallo.
    Sin dependencias del host más allá de
    Bash 4+, Docker, Git y Ollama.

  P3 — CONTENEDORES AISLADOS
    Cada blueprint es autónomo via docker-compose.yml.
    Sin dependencias globales en el host.

  P4 — PROGRESO INCREMENTAL
    El sistema siempre avanza, nunca retrocede.
    Si un cambio no es validable, se rechaza.

---

## Invariantes de Arquitectura

  - config.sh es la fuente única de verdad del dominio.
    Ningún módulo hardcodea blueprints, puertos,
    stacks ni descripciones.

  - errors.sh es autónomo. No depende de utils.sh.

  - La IA nunca toca archivos vivos directamente.

  - Los providers (ollama/api) son intercambiables
    sin tocar review.sh.
    Contrato: ai_complete(prompt_file, output_file,
                          options_file)
    Returns: 0=ok 1=fallo 2=vacío 3=timeout

  - Las strategies (python/go/js) son intercambiables
    sin tocar review.sh.
    Contrato: validate_syntax(file)
              extract_signatures(file)
              get_prompt_rules()

  - El flujo review tiene exactamente 10 pasos.
    Su orden no cambia sin un nuevo ADR.

  - Los blueprints oficiales se definen en config.sh.
    No hay blueprints de terceros en v1.

---

## Decisiones Cerradas

  > Versión formal y detallada en `decisions/` (ADR-0001…0012). Esta lista es el
  > resumen rápido; ante diferencias, manda el ADR.

  A1  Bash 4.0+ mínimo. compat.sh detecta y valida.
  A2  Linux + macOS + WSL2 desde v1.
  A3  git clone + install.sh Y package managers.
  B1  Modelo: detectar lo disponible en Ollama.
      Fallback garantizado: qwen2.5:3b.
  B2  Provider dual: Ollama + API externa abstraída.
  B3  Fallo de guardián:
      [R]eintentar / [A]bortar / [E]ditar manual.
  C1  Resolver v1: top-level + Class.method.
  C2  Detección semántica híbrida:
      Bash primero, runtime nativo como fallback.
  C3  Decoradores y comentarios: incluidos por defecto,
      configurables en blueprint.toml.
  D1  i18n: inglés + español desde v1.
  D2  Tests con bats-core + CI GitHub Actions.
  D3  Solo blueprints oficiales del repo en v1.

---

## Lo que Sabemos que No Funciona

  - Ollama 3B alucina con archivos > 300 líneas
    sin chunking semántico.
  - Formato diff/patch es frágil con modelos pequeños.
    Usar archivo completo con guardianes compensatorios.
  - Chunks por número de líneas rompen contexto.
    Usar límites semánticos con sort por nivel.
  - sed para modificar JSON es frágil. Usar jq.
  - lsof no disponible en todas las distros Linux.
    Resuelto con _port_in_use() en compat.sh.

---

## Reparaciones Semana 0 — 100% Completadas

  ✅ R1  Shebang universal en todos los archivos
  ✅ R2  errors.sh: trap INT/TERM + _ERR_RED propios
  ✅ R3  select_git_mode duplicada eliminada
  ✅ R4  _port_in_use() portable en compat.sh
  ✅ R5  Prueba11 → {{PROJECT_NAME}} en main.py
  ✅ R6  TEMPLATE_BASE_DIR fallback corregido
  ✅ R7  source vs bash consistente en bin/genpy
  ✅ R8  Versión 1.0.0-alpha unificada
  ✅ R9  jq en _inject_node_addons
  ✅ R10 README.md en ai-llm-rag
  ✅ R11 docker-compose.yml en cyber-attacker-kali
  ✅ R12 Dockerfile ai-ml-pytorch movido a raíz

---

## Checkpoint 2026-05-26 — Docker, templates y documentación

  Objetivo: blueprints utilizables con `docker compose` y layout coherente.

  ✅ Documentación
     CONTEXT.md + ARCHITECTURE.md sincronizados (versión completa 2026-05-21).

  ✅ lib/template.sh
     Eliminado movimiento de backend/Dockerfile → raíz (bug Modelo B).
     Ampliada inyección {{PROJECT_NAME}} a Go/Node/TS.

  ✅ lib/core/config.sh
     Metadatos de puertos solo para APIs expuestas en localhost
     (sin 5432/27017/3306 en chequeo de colisiones).

  ✅ Política de red (9 docker-compose.yml)
     Web: API 127.0.0.1, bases de datos sin ports en host.
     AI: Jupyter 127.0.0.1; RAG sin puertos; PyTorch requirements en raíz.
     Cyber: compose Kali recreado (sin puertos); víctima Win7 sin cambios de red.
     Infra: Prometheus/Grafana/Traefik en 127.0.0.1; {{PROJECT_NAME}} en Traefik.

  ✅ Dockerfiles y código de templates
     web-fastapi-postgres: backend/src/, config POSTGRES_*, Dockerfile backend/.
     web-node-nest-mongo: nest-cli.json, build dist/main.js.
     web-go-gin-clean: módulo app, DSN desde env, Dockerfile multi-stage.
     ai-ml-pytorch: Dockerfile raíz + requirements.txt raíz.
     ai-llm-rag: Chroma PersistentClient local, deps langchain-community.

  ✅ READMEs web
     Sección "Red Docker" en FastAPI, NestJS y Go.

  ✅ docker-compose usa ${COMPOSE_PROJECT_NAME} para nombres de
     contenedor y BD (válido al probar templates/ sin genpy create).

  Pendiente verificar en host:
     docker compose build && up en cada blueprint con Dockerfile.
     libs.sh usa sed -i '' (solo macOS) — corregir para Linux.

  No incluido en este checkpoint:
     Seguridad capas OSI (roadmap futuro).

---

## Checkpoint 2026-05-28 — Fase 0: estabilización del flujo create

  Objetivo: eliminar bugs reales que hacían el flujo frágil en Linux
  y en rutas de error. 8 fixes aplicados, uno descartado (falso positivo).

  ✅ Fix 1 — config.sh descomentado en wizard.sh
     Declaración explícita de dependencia. Include guard en config.sh
     (_GENPY_CONFIG_LOADED) evita error con readonly en doble source.

  ✅ Fix 2 — sed -i '' en libs.sh → _sed_inplace()
     El filtro de seguridad de requirements.txt rompía en Linux.
     Ahora usa la función portable del mismo módulo (template.sh).
     Sourceo de template.sh desde libs.sh garantizado por carga
     ordenada en wizard.sh (líneas 24-25).

  ✅ Fix 3 — Dependencias implícitas de utils.sh
     docker.sh, libs.sh y git_manager.sh ahora sourcean utils.sh
     explícitamente vía LIB_DIR. Include guard en utils.sh
     (_GENPY_UTILS_LOADED) evita redefinición doble.

  ✅ Fix 4 — Validación del nombre del proyecto
     Regex ^[a-zA-Z0-9][a-zA-Z0-9_-]*$ en wizard.sh.
     Rechaza: espacios, /, ., $, guion inicial, string vacío.
     Nuevo mensaje en i18n: MSG_ERR_NAME_INVALID (es.sh y en.sh).

  ✅ Fix 5 — copy_template() valida template y resultado
     Falla con mensaje preciso si template_dir no existe.
     Falla si rsync copió vacío (ls -A post-copia).
     wizard.sh conserva el check secundario como segunda línea de defensa.

  ✅ Fix 6 — Subshell en pipe de template.sh
     | while read → while ... done < <(find ...) (process substitution).
     Los errores de _sed_inplace propagan correctamente; variables del
     loop persisten en el shell principal.

  ✅ Fix 7 — Backticks en compat.sh
     Falso positivo: el código ya usaba $() en todas partes.
     No aplica.

  ✅ Fix 8 — Git push silenciaba stderr
     Eliminado 2>/dev/null de _push_to_remote(). El mensaje real de git
     (ej: "Permission denied (publickey)") ahora es visible al usuario.
     La estructura if/else ya existía y era correcta.

  ✅ Fix extra — Ctrl+C no salía del wizard
     errors.sh: separados los traps EXIT y INT/TERM.
     INT/TERM llaman exit 130 después de limpiar; el loop while del
     wizard ya no continúa tras Ctrl+C.

---

## Checkpoint 2026-05-28 — Secretos .env generados automáticamente

  Objetivo: eliminar contraseñas hardcodeadas en los templates;
  cada proyecto generado recibe credenciales únicas y seguras.

  ✅ lib/template.sh — nuevas funciones
     _generate_secret(bytes): usa openssl rand -hex con fallback
     a LC_ALL=C tr < /dev/urandom. Output: hex puro [0-9a-f].
     _inject_env_secrets(env_file): dos pasadas sobre el .env copiado.
       Pasada 1: reemplaza {{SECRET_HEX_N}} con secreto de N bytes.
                 Guarda var_name → secret en un mapa local.
       Pasada 2: resuelve {{VAR_NAME}} (bash string substitution,
                 no sed — evita bug de llaves dobles en BSD sed macOS).
     Nota de implementación: ${#array[@]} con array asociativo vacío
     dispara nounset en bash 5.3; se usa flag 'generated=0/1' en su lugar.
     .env añadido a la lista de find para inyección de {{PROJECT_NAME}}.
     _inject_env_secrets llamada al final de copy_template().

  ✅ .gitignore — excepción para templates/
     Regla añadida: !templates/**/.env
     Los .env de templates son fuente del CLI, no secretos reales.

  ✅ Templates actualizados:

     web-fastapi-postgres:
       DB_PASSWORD={{SECRET_HEX_32}}  (64 chars hex)
       DATABASE_URL usa {{DB_PASSWORD}} como referencia cruzada
       → ambas variables reciben el mismo secreto generado

     web-go-gin-clean:
       DB_PASSWORD={{SECRET_HEX_32}}

     ai-ml-pytorch:
       JUPYTER_TOKEN={{SECRET_HEX_24}}
       Comentario "puedes cambiarlo" eliminado (ya no aplica)

     web-node-nest-mongo:
       JWT_SECRET={{SECRET_HEX_32}} (nueva variable)

     infra-monitoring-stack:
       .env creado con GF_SECURITY_ADMIN_PASSWORD={{SECRET_HEX_16}}
       docker-compose.yml actualizado: ya no hardcodea "admin"
       → GF_SECURITY_ADMIN_PASSWORD: ${GF_SECURITY_ADMIN_PASSWORD}

  Sin cambios (justificados):
     ai-llm-rag: OPENAI_API_KEY es una clave de API externa,
       no generada. No se puede automatizar.
     cyber-attacker-kali: sin credenciales (AUDIT_MODE, TARGET_SUBNET).
     infra-local-cluster: solo PROJECT_NAME.
     cyber-lab-victim-win7: sin .env.

---

## Checkpoint 2026-05-28 — Puertos y GitHub automáticos

  Objetivo: eliminar fricción manual en los dos pasos finales del wizard.

  ✅ lib/core/compat.sh
     Nueva función _find_free_port(port): itera desde port+1 hasta
     encontrar un puerto libre (<= 65535). Vive junto a _port_in_use().

  ✅ lib/docker.sh — inspect_blueprint_ports()
     Acepta segundo argumento project_dir.
     Cuando un puerto está ocupado: llama _find_free_port, informa
     el remapeo al usuario y parchea docker-compose.yml con sed
     (solo el puerto host; el del contenedor no cambia).
     Wizard.sh actualizado para pasar $PROJECT_DIR.

  ✅ lib/git_manager.sh — GitHub API
     _get_github_token(): busca en GITHUB_TOKEN → GH_TOKEN → gh CLI.
     _create_github_repo(): POST /user/repos vía curl; extrae ssh_url
     con jq o grep; reporta error de la API si falla.
     _push_to_remote(): conecta remote y hace push; instrucciones de
     reintento si falla.
     _fallback_manual_remote(): flujo anterior (URL manual), usado
     cuando no hay curl, no hay token o la API falla.
     setup_git_repository(): orquesta el flujo completo con degradación
     grácil en cada punto de fallo.

  Tag: v1.0.0-alpha

---

## Limpieza estructural 2026-05-26

  Objetivo: alinear el árbol del repo con ARCHITECTURE.md.

  Eliminado:
    - Prototipos review (curl/Ollama) en scripts/ y lib/ viejos.
    - Artefactos locales .aider* (gitignore).

  Creado:
    - tests/{fixtures,unit,integration,mocks/ollama_mock.sh}
    - decisions/, docs/, .github/workflows/ci.yml
    - Stubs Semana 2–5: resolver, guardians, assembler, providers
    - lib/review.sh nuevo (stub Semana 3)
    - templates/web-fastapi-postgres/.genpy/blueprint.toml
    - CHANGELOG.md, README.md actualizado

  Implementado desde entonces:
    resolver.sh ✅, guardians.sh ✅, assembler.sh ✅
  Pendiente implementar:
    genpy review (Semana 3), git_manager checkpoints, doctor, bats CI.

---

## Semana 2 — Motor de Review sin IA

Lo que construimos ahora, en orden:

  1. .genpy/blueprint.toml en web-fastapi-postgres  ✅ (plantilla + flujo create)
     rsync copia .genpy/ al proyecto generado.
     _validate_blueprint_toml() valida existencia, sección [meta],
     version y language en bash puro (grep). Llamada desde copy_template().

  2. resolver.sh  ✅
     resolve_range() implementado: --lines N-M, --function,
     --class, --method Clase.método para Python top-level.
     Estrategia: grep/awk primero, python3 ast como fallback (C2).
     24 tests en tests/unit/test_resolver.sh (24 PASS / 0 FAIL).

  3. guardians.sh  ✅
     run_guardians() + G1–G5 implementados.
     G4 omite chunks de métodos indentados (validación completa en paso [8]).
     G5 verifica firmas top-level e indentadas; ignora privados (_foo),
     conserva dunders (__init__). Interacción [R]/[A]/[E] con GUARDIAN_MAX_RETRIES.
     44 tests en tests/unit/test_guardians.sh (44 PASS / 0 FAIL).

  4. assembler.sh  ✅
     build_review_context(): extrae imports + firmas → context blob.
     assemble_prompt(): 4 secciones con rol, goal, contexto y chunk.
     reassemble_file(): head + chunk_revisado + tail → stdout.
     48 tests en tests/unit/test_assembler.sh (48 PASS / 0 FAIL).

  5. review_strategies/python.sh  ✅ (funcional)
     validate_syntax(): python3 -m py_compile.
     extract_signatures(): grep ^def / ^async def / ^class.
     get_prompt_rules(): indentación, type hints, f-strings, decoradores.

  6. git_manager.sh robustecer  ✅
     create_checkpoint(project_dir, [branch_prefix]): valida repo, HEAD no
     detached, árbol limpio; crea rama genpy/review/<YYYYMMDD_HHMMSS> y cambia
     a ella. Sets CHECKPOINT_BRANCH, CHECKPOINT_ORIGINAL_BRANCH.
     rollback_to_checkpoint(project_dir): vuelve a la rama original y elimina
     la de revisión con -D (force). Limpia los globals.
     32 tests en tests/unit/test_checkpoint.sh (32 PASS / 0 FAIL).

  Criterio de salida:
    El flujo completo funciona con ollama_mock.sh.
    Sin Ollama real todavía.

---

## Checkpoint 2026-05-28 — Semana 2: motor de review sin IA

  Objetivo: construir y testar los módulos que el orquestador review.sh
  necesitará en Semana 3. Sin IA real; todo testeable con mocks.

  ✅ lib/template.sh — integración blueprint.toml en genpy create
     _validate_blueprint_toml(): verifica [meta], version y language
     en bash puro (grep). copy_template() la invoca si el archivo existe.

  ✅ lib/resolver.sh — resolve_range()
     Cuatro modos: --lines N-M, --function, --class, --method Clase.método.
     Bash/grep/awk como camino principal; python3 ast como fallback (C2).
     Produce globals RESOLVE_START y RESOLVE_END (1-based, inclusive).
     Include guard _GENPY_RESOLVER_LOADED.
     24 tests — 24 PASS / 0 FAIL.

  ✅ lib/guardians.sh — run_guardians() + G1–G5
     G1 not-empty, G2 no-markdown, G3 line-count 70–130%,
     G4 validate_syntax (skip en métodos indentados),
     G5 firmas públicas presentes (ignora _privados, conserva __dunders__).
     run_guardians retorna 0/1/2; interacción [R]/[A]/[E].
     GUARDIAN_MAX_RETRIES, GUARDIAN_NON_INTERACTIVE para CI.
     44 tests — 44 PASS / 0 FAIL.

  ✅ lib/assembler.sh — build_review_context / assemble_prompt / reassemble_file
     build_review_context: extrae imports y firmas → context blob con marcadores.
     assemble_prompt: 4 secciones (rol, goal, contexto RO, fragmento objetivo).
     reassemble_file: head(1..START-1) + chunk_revisado + tail(END+1..EOF) → stdout.
     48 tests — 48 PASS / 0 FAIL.

  ✅ lib/review_strategies/python.sh — funcional
     validate_syntax: python3 -m py_compile.
     extract_signatures: grep ^def / ^async def / ^class.
     get_prompt_rules: cuatro reglas de estilo Python.

  Semana 2 completa. Siguiente: Semana 3 — review.sh + providers Ollama/API.

---

## Glosario

  focal chunk    Fragmento de código enviado a la IA
  guardian       Función de validación del output IA
  checkpoint     Commit Git antes de operación con IA
  strategy       Módulo específico por lenguaje
  provider       Abstracción del servicio IA
  blueprint      Template Docker completo y autónomo
  addon          Paquete opcional inyectable
  Modelo A       Dockerfile en raíz del blueprint
  Modelo B       Dockerfile en backend/

