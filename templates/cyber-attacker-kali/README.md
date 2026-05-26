# {{PROJECT_NAME}} — Attacker Lab (Kali)

> Entorno de seguridad ofensiva generado con [GenPy](https://github.com/RenatoAntonioCL/genpy)

⚠️ **USO EXCLUSIVO EN ENTORNOS CONTROLADOS Y CON AUTORIZACIÓN EXPLÍCITA**

## Inicio rápido

```bash
docker compose up -d
docker compose exec kali bash
```

## Herramientas incluidas

- nmap, netcat, curl
- python3 con scripts personalizados

## Estructura

```
{{PROJECT_NAME}}/
├── src/
│   ├── main.py      # Runner principal
│   └── scanner.py   # Módulo de escaneo
└── Dockerfile
```