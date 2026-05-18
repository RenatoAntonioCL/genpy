# GenPy 🛠️

> CLI tool para generar proyectos Python con estructura profesional, git, Docker y entorno virtual — en segundos.

---

## ¿Qué es GenPy?

GenPy es una herramienta de línea de comandos que automatiza la configuración inicial de proyectos Python. En lugar de crear carpetas, inicializar git, escribir un Dockerfile y configurar un entorno virtual a mano cada vez, GenPy lo hace todo en un solo comando interactivo.

```bash
genpy create
```

---

## Instalación

### Requisitos

- macOS o Linux
- Bash 4+
- Git
- Python 3.10+ *(opcional, para entorno virtual)*
- Docker *(opcional, para build de imagen)*

### Instalar desde GitHub

```bash
curl -fsSL https://raw.githubusercontent.com/RenatoAntonioCL/genpy/main/instalador/instalar.sh | bash
```

Esto descarga el proyecto y lo instala en `/usr/local/share/genpy`, dejando el comando `genpy` disponible globalmente.

---

## Uso

### Crear un proyecto nuevo

```bash
genpy create
```

GenPy te guía paso a paso:

1. Pide el nombre del proyecto
2. Pregunta si quieres Docker y/o entorno virtual
3. Muestra una lista de librerías para elegir
4. Crea la estructura, inicializa git y construye los entornos

### Otros comandos

```bash
genpy update      # Actualizar GenPy a la última versión
genpy uninstall   # Desinstalar GenPy del sistema
genpy version     # Ver la versión instalada
genpy help        # Ver todos los comandos disponibles
```

---

## Estructura generada

Al crear un proyecto llamado `mi-app`, GenPy genera lo siguiente:

```
mi-app/
├── src/
│   └── main.py           # Punto de entrada de la aplicación
├── tests/
│   └── .gitkeep          # Carpeta lista para tus tests
├── Dockerfile            # (si elegiste Docker)
├── .dockerignore         # (si elegiste Docker)
├── requirements.txt      # Librerías seleccionadas durante la creación
├── .gitignore            # Python + macOS + venv
└── README.md             # Documentación inicial del proyecto
```

El repositorio git se inicializa automáticamente con un primer commit en rama `main`.

---

## Librerías disponibles

Durante la creación puedes seleccionar una o varias de la siguiente lista:

| # | Librería | Uso |
|---|----------|-----|
| 1 | `fastapi` | APIs REST modernas |
| 2 | `flake8` | Linter de estilo PEP8 |
| 3 | `python-dotenv` | Variables de entorno desde `.env` |
| 4 | `requests` | HTTP client |
| 5 | `loguru` | Logging simplificado |
| 6 | `pytest` | Testing |
| 7 | `numpy` | Computación numérica |
| 8 | `pandas` | Análisis de datos |

---

## Arquitectura del proyecto

```
genpy/
├── bin/
│   └── genpy              # Entry point del CLI — router de comandos
├── generador/
│   └── genpy.sh           # Orquestador del pipeline de creación
├── instalador/
│   ├── instalar.sh        # Instala GenPy en el sistema
│   ├── actualizar.sh      # Descarga y aplica la última versión
│   └── desinstalar.sh     # Elimina GenPy del sistema
└── lib/
    ├── validate.sh        # Validación de entrada del usuario
    ├── structure.sh       # Creación de carpetas y archivos base
    ├── git.sh             # Inicialización del repositorio git
    ├── docker.sh          # Generación de Dockerfile y build de imagen
    ├── libs.sh            # Selección e instalación de librerías
    ├── venv.sh            # Creación del entorno virtual
    └── ui.sh              # Interacción con el usuario en terminal
```

---

## Desinstalar

```bash
genpy uninstall
```

Elimina el directorio de instalación y el comando global. Los proyectos que ya generaste no se ven afectados.

---

## Roadmap

- [ ] Soporte para múltiples lenguajes (Node.js, Go, Rust)
- [ ] Sistema de templates configurables (YAML/TOML)
- [ ] Integración con GitHub API (crear repo + push inicial)
- [ ] Generación de workflows de GitHub Actions (CI/CD)
- [ ] Distribución via Homebrew
- [ ] Binario compilado cross-platform

---

## Licencia

MIT © [Renato Antonio](https://github.com/RenatoAntonioCL)
