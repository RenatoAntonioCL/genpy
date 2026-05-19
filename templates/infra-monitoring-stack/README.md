# {{PROJECT_NAME}} — Monitoring Stack

> Stack de monitoreo generado con [GenPy](https://github.com/RenatoAntonioCL/genpy) — Prometheus + Grafana

## Inicio rápido

```bash
docker compose up -d
```

| Servicio    | URL |
|-------------|-----|
| Prometheus  | http://localhost:9090 |
| Grafana     | http://localhost:3000 (admin/admin) |

## Estructura

```
{{PROJECT_NAME}}/
├── prometheus/
│   └── prometheus.yml   # Configuración de scraping
└── docker-compose.yml
```