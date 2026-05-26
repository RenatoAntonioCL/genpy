# {{PROJECT_NAME}}

> API REST generada con [GenPy](https://github.com/RenatoAntonioCL/genpy) — Stack: NestJS + MongoDB + Docker

## Stack

| Capa | Tecnología |
|------|------------|
| API  | NestJS + TypeScript |
| BD   | MongoDB 7 + Mongoose |
| Contenedor | Docker Compose |

## Inicio rápido

```bash
docker compose up -d
```

API disponible en `http://localhost:3000`

## Red Docker

- La API se publica solo en `127.0.0.1:3000` (no en todas las interfaces del host).
- MongoDB no expone puertos al host; la API se conecta por la red interna `app-network` (`mongo:27017`).

## Estructura

```
{{PROJECT_NAME}}/
├── backend/
│   ├── Dockerfile
│   ├── package.json
│   ├── tsconfig.json
│   └── src/
│       ├── main.ts
│       ├── app.module.ts
│       ├── users/
│       └── cache/
└── docker-compose.yml
```

## Variables de entorno

```env
MONGODB_URI=mongodb://mongo:27017/{{PROJECT_NAME}}
NODE_ENV=development
```