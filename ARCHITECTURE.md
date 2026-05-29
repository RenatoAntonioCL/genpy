# genpy — Architecture Document

Version:       1.0.0-alpha
Actualización: 2026-05-28
Estado:        Semana 2 casi completa — motor de review sin IA operativo
Autor:         Renato

---

## 1. Visión y Objetivos

genpy es una herramienta CLI modular en Bash que automatiza
el despliegue, gestión y revisión de arquitecturas de software
mediante blueprints contenerizados (Docker).

Objetivos de v1.0.0:
  1. Instalable sin fricción en Linux, macOS y WSL2.
  2. genpy create genera proyectos completos en < 60s.
  3. genpy review revisa código con IA de forma segura,
     trazable y completamente reversible.
  4. Indestructible: ninguna operación deja el proyecto
     del usuario en un estado irrecuperable.

---

## 2. Principios de Diseño (Inviolables)

  P1 — RESILIENCIA ABSOLUTA
    Ningún cambio toca archivos vivos directamente.
    Flujo obligatorio:
    Sandbox(.tmp) → Guardianes → Git → Usuario.

  P2 — BASH PURO Y MODULAR
    Sin dependencias de Python/Node en el core del CLI.
    Funciones con responsabilidad única.
    trap en todos los puntos de fallo críticos.

  P3 — CONTENEDORES AISLADOS
    Blueprints autónomos via docker-compose.yml.
    Sin dependencias globales en el host más allá de
    Bash 4+, Docker, Git y Ollama.

  P4 — PROGRESO INCREMENTAL
    El sistema valida el entorno antes de avanzar.
    Si un cambio no es validable, se rechaza.

---

## 3. Stack y Restricciones

  Runtime:        Bash 4.3+ (namerefs usados en libs.sh y menus.sh;
                  compat.sh valida Bash >= 4 en tiempo de ejecución)
  Plataformas:    Linux, macOS, Windows WSL2
  Dependencias:   Docker, Git, Ollama (solo review)
  Testing:        bats-core (pendiente)
  CI:             GitHub Actions (pendiente)
  Versioning:     Semver estricto

  Restricciones:
    El CLI no depende de Python, Node ni Go en el host.
    Los scripts auxiliares de detección semántica SÍ
    pueden usar el runtime del lenguaje target como
    fallback (decisión C2).

---

## 4. Estructura del Proyecto

  genpy/
  ├── bin/
  │   └── genpy
  ├── lib/
  │   ├── core/
  │   │   ├── compat.sh
  │   │   ├── config.sh
  │   │   ├── errors.sh
  │   │   └── preflight.sh
  │   ├── i18n/
  │   │   ├── en.sh
  │   │   └── es.sh
  │   ├── ui/
  │   │   ├── banner.sh
  │   │   ├── card.sh
  │   │   └── menus.sh
  │   ├── providers/           ← Semana 3
  │   │   ├── ollama.sh
  │   │   └── api.sh
  │   ├── review_strategies/   ← Semana 2
  │   │   ├── python.sh
  │   │   ├── go.sh
  │   │   └── javascript.sh
  │   ├── assembler.sh         ← Semana 2
  │   ├── docker.sh
  │   ├── git_manager.sh
  │   ├── guardians.sh         ← Semana 2
  │   ├── libs.sh
  │   ├── resolver.sh          ← Semana 2
  │   ├── review.sh            ← Semana 3
  │   ├── template.sh
  │   ├── utils.sh
  │   └── wizard.sh
  ├── scripts/
  │   ├── install.sh
  │   ├── uninstall.sh
  │   ├── update.sh
  │   └── doctor.sh            ← Semana 4
  ├── templates/
  │   ├── web-fastapi-postgres/
  │   │   ├── .genpy/
  │   │   │   └── blueprint.toml  ← Semana 2 (primero)
  │   │   └── ...
  │   └── ... (8 blueprints más)
  ├── tests/                   ← Semana 2
  │   ├── fixtures/
  │   ├── mocks/
  │   │   └── ollama_mock.sh
  │   ├── unit/
  │   └── integration/
  ├── decisions/               ← Pendiente
  ├── docs/
  │   ├── INSTALL.md
  │   ├── CONTRIBUTING.md
  │   └── SECURITY.md
  ├── .github/
  │   ├── workflows/
  │   │   └── ci.yml
  │   └── CONTEXT.md
  ├── ARCHITECTURE.md
  ├── CHANGELOG.md
  └── README.md

---

## 5. Arquitectura de Módulos

### 5.1 Capa Core

  compat.sh
    Detecta: OS (GENPY_OS), arquitectura (GENPY_ARCH)
    Valida: Bash >= 4.0, aborta con mensaje si no
    Provee: _port_in_use() portable
            (ss → netstat → /dev/tcp fallback)

  config.sh
    Arrays asociativos (readonly):
      AREAS, AREA_BLUEPRINTS, BLUEPRINT_META
      ADDON_PACKAGES, ADDON_LABELS, ADDON_INDEX
    Función pública: blueprint_meta(blueprint, field)
    Regla: ningún módulo hardcodea datos de dominio

  errors.sh
    Traps separados:
      EXIT        → _genpy_cleanup() (limpia GENPY_CLEANUP_DIR)
      INT / TERM  → imprime "Operación cancelada" + exit 130
    El trap de INT llama exit, que dispara el de EXIT como cadena.
    Sin separación: Ctrl+C no salía del wizard (el handler retornaba
    y el while true continuaba desde el read interrumpido).
    Colores propios: _ERR_RED, _ERR_NC (autónomo)
    Funciones: die(), require_command(), require_dir()

  preflight.sh
    preflight_mode_create():
      - require_command docker, git
      - check_docker_daemon()
      - disco libre > 500MB
      - permisos de escritura en directorio actual
    preflight_mode_review(): ← Semana 3
      - Todo lo anterior +
      - Git working tree limpio
      - Ollama accesible en localhost:11434
      - Modelo requerido descargado
      - blueprint.toml válido y parseable

### 5.2 Capa de Providers (Semana 3)

  Contrato único:
    ai_complete(prompt_file, output_file, options_file)
    Returns:
      0 → éxito, respuesta en output_file
      1 → fallo de servicio
      2 → respuesta vacía o malformada
      3 → timeout

  ollama.sh
    POST localhost:11434/api/generate
    Detección de modelo según prioridad B1:
      1. config del usuario
      2. primer modelo en ollama list
      3. fallback: qwen2.5:3b
    Maneja: timeout, conexión rechazada,
            JSON malformado

  api.sh
    Requiere: GENPY_API_KEY en el entorno
    Endpoint: configurable (OpenAI/Anthropic/custom)
    Mismos códigos de retorno que ollama.sh

### 5.3 Capa de Review Strategies (Semana 2)

  Contrato único:
    validate_syntax(file)     → 0=ok, 1=error
    extract_signatures(file)  → imprime firmas
    get_prompt_rules()        → imprime reglas

  python.sh
    validate_syntax:      python -m py_compile
    extract_signatures:   grep "^def \|^class \|
                               ^async def "
    Reglas: indentación, type hints, f-strings

  go.sh
    validate_syntax:      go vet ./...
    extract_signatures:   grep "^func "

  javascript.sh
    validate_syntax:      node --check
    extract_signatures:   grep "^export \|
                               ^function \|^const "

### 5.4 El Flujo genpy review (10 Pasos)

  [0]  preflight_mode_review()
  [1]  Parse blueprint.toml → cargar strategy
  [2]  Git checkpoint
         git checkout -b genpy/review/<timestamp>
  [3]  Resolve range
         --lines N-M
         --function name
         --class name
         --method Class.method
         → produce START, END
  [4]  Build context
         imports completos (zona superior fija)
         firmas resumidas (zonas sup e inf)
         focal chunk completo (START..END)
  [5]  Assemble prompt
         Sección 1: Rol y restricciones
         Sección 2: Objetivo de revisión
         Sección 3: Contexto (solo lectura)
         Sección 4: Fragmento objetivo
  [6]  ai_complete() con timeout explícito
         → focal_chunk.tmp
  [7]  5 guardianes (barato primero):
         G1: output no vacío
         G2: sin markdown/texto conversacional
         G3: line count 70%-130% del original
         G4: validate_syntax() de la strategy
         G5: firmas públicas presentes
       Fallo → [R]eintentar / [A]bortar / [E]ditar
       Máx reintentos: 2 (configurable)
  [8]  Re-assemble + validate_syntax() completo
         head + focal_chunk.tmp + tail
  [9]  Diff visual + confirmación
         diff --color=always | less -R
         [A]ceptar / [R]echazar / [E]ditar
  [10] Apply o Rollback
         Aceptar: cp + git commit
         Rechazar: git checkout + branch delete

### 5.5 El Flujo genpy create (7 Pasos, Estable)

  [1]  Banner + nombre del proyecto
         Validación: ^[a-zA-Z0-9][a-zA-Z0-9_-]*$
         Rechaza: espacios, /, ., $, guion inicial
  [2]  preflight_mode_create()
  [3]  select_git_mode()
  [4]  select_area() → select_blueprint()
  [5]  select_blueprint_addons()
  [6]  print_blueprint_card() + confirm_creation()
  [7]  copy_template()
         → rsync del template al directorio destino
         → _sed_inplace {{PROJECT_NAME}} en .env y archivos de texto
         → _inject_env_secrets(): genera secretos para {{SECRET_HEX_N}}
              y resuelve referencias cruzadas {{VAR_NAME}} en el mismo .env
       → inject_blueprint_addons()
       → setup_git_repository()
       → check_docker_daemon() + inspect_blueprint_ports()

  Secretos .env por blueprint:
    web-fastapi-postgres  DB_PASSWORD (32 bytes), DATABASE_URL consistente
    web-go-gin-clean      DB_PASSWORD (32 bytes)
    ai-ml-pytorch         JUPYTER_TOKEN (24 bytes)
    web-node-nest-mongo   JWT_SECRET (32 bytes)
    infra-monitoring-stack GF_SECURITY_ADMIN_PASSWORD (16 bytes)

### 5.6 Chunking con Sort Semántico (Semana 5)

  Activo cuando: archivo > 500 líneas
  Orden de procesamiento por nivel:
    0 → imports y constantes globales
    1 → modelos y clases base
    2 → servicios y repositorios
    3 → routers y controllers
    4 → punto de entrada (main/app)
  Contexto acumulativo entre chunks:
    accumulated_context += extract_signatures(chunk_revised)
  Re-ensamblado: por START_LINE original,
                 no por orden de procesamiento

---

## 6. El Blueprint Contract

  Archivo: <proyecto>/.genpy/blueprint.toml

  [meta]
  name         = string
  version      = semver
  language     = python|go|javascript|bash|infra
  runtime      = string
  description  = string

  [ai_context]
  editable_files               = [glob patterns]
  protected_files              = [glob patterns]
  include_decorators_in_chunk  = true
  include_block_comments       = true

  [[ai_context.dependency_map]]
  source  = "path relativo"
  affects = ["paths relativos"]

  [validation]
  syntax_check      = "comando con {file}"
  semantic_check    = "comando docker opcional"
  semantic_timeout  = 60

  [review]
  default_goal    = "string opcional"
  max_chunk_lines = 150

  [git]
  checkpoint_prefix    = "chore(genpy): checkpoint"
  review_branch_prefix = "genpy/review"

---

## 7. Configuración en Cascada

  Prioridad (mayor gana):
    1. Flags de CLI
    2. <proyecto>/.genpy/blueprint.toml
    3. ~/.config/genpy/config.toml
    4. Defaults en config.sh

  Espacios:
    /usr/local/lib/genpy/    Instalación (read-only)
    ~/.config/genpy/         Usuario global
    <proyecto>/.genpy/       Proyecto específico

---

## 8. Modelo de Amenazas

  A1 — Path traversal en blueprint.toml
       Mitigación: validar rutas relativas dentro
       del directorio del proyecto. Rechazar .. y
       rutas absolutas.

  A2 — Prompt injection vía código del usuario
       Mitigación: system prompt establece que el
       focal chunk son datos, no instrucciones.

  A3 — Ollama expuesto en red
       Mitigación: preflight verifica que Ollama
       escucha solo en 127.0.0.1.

---

## 9. Roadmap

  Semana 0 — Reparaciones ✅ Completada
    R1-R12 resueltos.

  Semana 1 — Fundación Portable ✅ Completada
    compat.sh, errors.sh, preflight.sh (modo create)
    i18n/en.sh + es.sh
    CONTEXT.md + ARCHITECTURE.md

  Fase 0 — Estabilización flujo create ✅ Completada (2026-05-28)
    Fix Ctrl+C: traps EXIT e INT/TERM separados en errors.sh.
    Fix config.sh: include guard + source explícito en wizard.sh.
    Fix sed Linux: _sed_inplace() en libs.sh (filtro requirements.txt).
    Fix dependencias implícitas: utils.sh sourceado en docker.sh,
      libs.sh, git_manager.sh con include guard.
    Fix validación nombre de proyecto: regex + i18n.
    Fix rsync: copy_template() valida template_dir y copia no vacía.
    Fix subshell: pipe → process substitution en template.sh.
    Fix git push: 2>/dev/null eliminado, error real visible.
    Secretos .env: _generate_secret() + _inject_env_secrets() en
      template.sh. 5 blueprints con credenciales únicas por proyecto.

  Semana 2 — Motor de Review sin IA 🔄 Casi completa
    blueprint.toml integrado en genpy create ✅
    resolver.sh — resolve_range() con 4 modos ✅ (24 tests)
    guardians.sh — G1-G5 + run_guardians() ✅ (44 tests)
    assembler.sh — context/prompt/reassemble ✅ (48 tests)
    review_strategies/python.sh funcional ✅
    git_manager.sh: create_checkpoint/rollback ⏳
    tests integración con ollama_mock.sh ⏳

  Semana 3 — Integración IA ⏳ Pendiente
    providers/ollama.sh + api.sh
    review.sh orquestador (10 pasos)
    preflight_mode_review()
    Circuit breaker para Ollama
    Tag v1.1.0-beta

  Semana 4 — Distribución ⏳ Pendiente
    install.sh reescrito (4 fases)
    doctor.sh
    update.sh con SHA256
    README público + docs/
    Tag v1.1.0 estable

  Semana 5 — Expansión ⏳ Pendiente
    review_strategies/go.sh + javascript.sh
    Chunking semántico con sort por nivel
    providers/api.sh completo
    brew formula draft
    Tag v1.2.0

---

## 10. Limitaciones Conocidas de v1

  - Funciones anidadas y closures fuera del scope
    del resolver en v1.
  - TypeScript usa strategy javascript.
  - Modelos 3B degradan con archivos > 200 líneas
    sin chunking.
  - blueprints infra y cyber no tienen strategy
    de review (language = infra).
  - Blueprints de terceros no soportados en v1.
  - tests/ en bash puro (116 tests); bats-core y CI pendientes.
  - doctor.sh pendiente Semana 4.
  - git_manager.sh checkpoints pendientes (cierre Semana 2).

