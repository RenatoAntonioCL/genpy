# {{PROJECT_NAME}}

> Pipeline RAG generado con [GenPy](https://github.com/RenatoAntonioCL/genpy) — LangChain + ChromaDB + OpenAI

## Inicio rápido

```bash
export OPENAI_API_KEY=sk-...
docker compose build
docker compose up -d

# 1. Indexar documentos (solo la primera vez o cuando cambie data/)
docker exec -it {{PROJECT_NAME}}-rag python src/embed.py

# 2. Iniciar el pipeline RAG de forma interactiva
docker exec -it {{PROJECT_NAME}}-rag python src/main.py
```

> El contenedor arranca en modo idle (`tail -f /dev/null`) para no hacer restart loop
> cuando `main.py` requiere una terminal. Ejecuta los scripts con `docker exec -it`.

Los vectores se guardan en `data/chroma` (volumen `./data`).

## Red Docker

- Sin puertos publicados en el host (pipeline batch/interactivo).
- Chroma usa almacenamiento local persistente (`CHROMA_PATH=/app/data/chroma`).

## Estructura

```
{{PROJECT_NAME}}/
├── Dockerfile
├── requirements.txt
├── docker-compose.yml
├── data/
│   └── context.txt
└── src/
    ├── embed.py
    └── main.py
```
