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

## Red Docker

- La API se publica solo en `127.0.0.1:8080` (no en todas las interfaces del host).
- MySQL no expone puertos al host; la API se conecta por la red interna `app-network` (`db:3306`).

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