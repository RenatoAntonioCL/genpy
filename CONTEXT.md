# genpy — AI Context Brief

> Cargar este archivo al inicio de cada sesión de trabajo.
> Última actualización: 2026-05-26
> Estado: Semana 1 completada — Checkpoint Docker/templates — Semana 2 pendiente

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
    - Git init automático (local/privado/público)
    - Templates web/AI con Dockerfiles corregidos y buildables

No existe todavía:
  genpy review  → descartado, reescribir desde cero
  genpy doctor  → pendiente Semana 4
  tests/        → pendiente Semana 1 (próximo paso)
  decisions/    → pendiente (ADRs por generar)
  .genpy/blueprint.toml → en ningún blueprint todavía

---

## Estructura Real del Proyecto

  bin/
    genpy                   Entry point. Resuelve rutas,
                            carga i18n, define comandos.

  lib/core/
    compat.sh               Detecta OS, arquitectura, Bash 4+.
                            Provee _port_in_use() portable.
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
    template.sh             rsync + _sed_inplace() portable.
                            Respeta Modelo A/B (no mueve Dockerfiles).
                            Inyecta {{PROJECT_NAME}} en:
                            *.md, docker-compose.yml, Dockerfile,
                            *.py, *.sh, *.go, go.mod, package.json,
                            nest-cli.json, tsconfig.json
    wizard.sh               Orquestador genpy create (7 pasos).
                            Sin lógica de dominio ni UI propia.
    git_manager.sh          setup_git_repository().
                            select_git_mode() eliminada (vive
                            en menus.sh).
    docker.sh               check_docker_daemon().
                            inspect_blueprint_ports() via
                            blueprint_meta(), _port_in_use().
    review.sh               DESCARTADO. Reescribir desde cero.

  scripts/
    install.sh              Instalador. Pendiente reescritura
                            con 4 fases.
    uninstall.sh            Funcional.
    update.sh               Funcional. Sin SHA256 todavía.
    review.sh               DESCARTADO. Reescribir desde cero.
    doctor.sh               NO EXISTE. Pendiente Semana 4.

  templates/                9 blueprints oficiales.
                            Ninguno tiene .genpy/ todavía.

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

  Pendiente verificar en host (no ejecutado en CI de esta sesión):
     docker compose build && up en cada blueprint con Dockerfile.
     libs.sh usa sed -i '' (solo macOS) — corregir para Linux.

  No incluido en este checkpoint:
     Semana 2 review (resolver, guardians, blueprint.toml).
     Seguridad capas OSI (roadmap futuro).

---

## Semana 2 — Motor de Review sin IA

Lo que construimos ahora, en orden:

  1. .genpy/blueprint.toml en web-fastapi-postgres
     Es el contrato que define todo lo demás.

  2. resolver.sh
     Resuelve rangos: --lines, --function, --class,
     --method Class.method para Python top-level.

  3. guardians.sh
     G1: output no vacío
     G2: sin markdown ni texto conversacional
     G3: line count entre 70% y 130% del original
     G4: validate_syntax() de la strategy
     G5: firmas públicas presentes

  4. assembler.sh
     Extrae contexto (imports + firmas).
     Construye el prompt.
     Re-ensambla el archivo completo.

  5. review_strategies/python.sh
     validate_syntax(), extract_signatures(),
     get_prompt_rules()

  6. git_manager.sh robustecer
     create_checkpoint(), rollback_to_checkpoint()

  Criterio de salida:
    El flujo completo funciona con ollama_mock.sh.
    Sin Ollama real todavía.

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

