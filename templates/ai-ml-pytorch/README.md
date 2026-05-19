# {{PROJECT_NAME}}

> Entorno ML generado con [GenPy](https://github.com/RenatoAntonioCL/genpy) — Stack: PyTorch + Jupyter Lab + Docker

## Inicio rápido

```bash
docker compose up -d
```

Jupyter Lab disponible en `http://localhost:8888`

## Estructura

```
{{PROJECT_NAME}}/
├── src/
│   ├── main.py      # Pipeline de entrenamiento
│   └── train.py     # Lógica del modelo
├── notebooks/
│   └── exploration.ipynb
├── requirements.txt
└── docker-compose.yml
```