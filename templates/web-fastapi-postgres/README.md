# {{PROJECT_NAME}}

> API REST generada con [GenPy](https://github.com/RenatoAntonioCL/genpy) — Stack: FastAPI + PostgreSQL + Docker

## Stack

| Capa | Tecnología |
|------|------------|
| API  | FastAPI 0.111 |
| BD   | PostgreSQL 15 |
| ORM  | SQLAlchemy 2.0 |
| Contenedor | Docker Compose |

## Inicio rápido

```bash
docker compose up -d
```

La API estará disponible en `http://localhost:8000`
Documentación interactiva en `http://localhost:8000/docs`

## Estructura

```
{{PROJECT_NAME}}/
├── backend/
│   ├── Dockerfile
│   └── requirements.txt
├── src/
│   ├── main.py         # App FastAPI y rutas
│   ├── config.py       # Variables de entorno
│   ├── database.py     # Conexión SQLAlchemy
│   ├── models.py       # Modelos ORM
│   ├── schemas.py      # Schemas Pydantic
│   └── repository.py   # Capa de acceso a datos
└── docker-compose.yml
```

## Variables de entorno

Crea un archivo `.env` en la raíz:

```env
DATABASE_URL=postgresql://postgres:postgres@db:5432/{{PROJECT_NAME}}
```