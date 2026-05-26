# {{PROJECT_NAME}}

> Pipeline RAG generado con [GenPy](https://github.com/RenatoAntonioCL/genpy) — LangChain + ChromaDB + OpenAI

## Inicio rápido

```bash
export OPENAI_API_KEY=sk-...
docker compose build
docker compose run --rm rag python src/embed.py
docker compose run --rm rag python src/main.py
```

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
