# {{PROJECT_NAME}}

> API REST generada con [GenPy](https://github.com/RenatoAntonioCL/genpy) — Stack: Go + Gin + MySQL + Docker

## Stack

| Capa | Tecnología |
|------|------------|
| API  | Go 1.21 + Gin |
| BD   | MySQL 8 + GORM |
| Build | Multi-stage Docker |

## Inicio rápido

```bash
docker compose up -d
```

API disponible en `http://localhost:8080`

## Estructura

```
{{PROJECT_NAME}}/
├── backend/
│   ├── Dockerfile
│   ├── go.mod
│   └── src/
│       ├── main.go
│       ├── controllers/
│       └── repository/
└── docker-compose.yml
```