# {{PROJECT_NAME}} — Local Cluster

> Cluster local con Traefik generado con [GenPy](https://github.com/RenatoAntonioCL/genpy)

## Inicio rápido

```bash
docker compose up -d
```

| Servicio        | URL |
|-----------------|-----|
| Traefik Dashboard | http://localhost:8080 |
| HTTP             | http://localhost:80 |

## Estructura

```
{{PROJECT_NAME}}/
├── traefik/
│   └── traefik.yml    # Configuración del proxy
└── docker-compose.yml
```