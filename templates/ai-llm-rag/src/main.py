import os
import sys

import chromadb
from langchain_community.embeddings import HuggingFaceEmbeddings
from langchain_openai import ChatOpenAI


def _chroma_client():
    path = os.getenv("CHROMA_PATH", "/app/data/chroma")
    return chromadb.PersistentClient(path=path)


def ask_rag(question: str):
    chroma_client = _chroma_client()
    collection = chroma_client.get_or_create_collection(name="genpy_knowledge")

    if collection.count() == 0:
        print("⚠️  Colección vacía. Ejecuta primero: python src/embed.py")
        sys.exit(1)

    query_vector = HuggingFaceEmbeddings(model_name="all-MiniLM-L6-v2").embed_query(question)
    results = collection.query(query_embeddings=[query_vector], n_results=1)
    context = (
        results["documents"][0][0]
        if results.get("documents") and results["documents"][0]
        else "No hay contexto disponible."
    )

    prompt = f"""Eres un asistente de IA profesional. Responde solo con el contexto provisto.

CONTEXTO:
{context}

PREGUNTA:
{question}

RESPUESTA:
"""
    llm = ChatOpenAI(model=os.getenv("OPENAI_MODEL", "gpt-4o-mini"), temperature=0)
    response = llm.invoke(prompt)

    print("\n🤖 Respuesta de la IA:")
    print(response.content)


if __name__ == "__main__":
    if not os.getenv("OPENAI_API_KEY"):
        print("❌ Define OPENAI_API_KEY en el entorno o en un archivo .env")
        sys.exit(1)

    print("🤖 RAG System Activo.")
    user_query = input("❓ Hazle una pregunta a tus documentos: ")
    ask_rag(user_query)
