import os

import chromadb
from langchain_community.document_loaders import TextLoader
from langchain_openai import OpenAIEmbeddings
from langchain_text_splitters import CharacterTextSplitter


def _chroma_client():
    path = os.getenv("CHROMA_PATH", "/app/data/chroma")
    return chromadb.PersistentClient(path=path)


def run_ingestion():
    print("📥 Iniciando indexación de documentos...")

    chroma_client = _chroma_client()
    loader = TextLoader("data/context.txt")
    documents = loader.load()

    text_splitter = CharacterTextSplitter(chunk_size=200, chunk_overlap=20)
    docs = text_splitter.split_documents(documents)

    embeddings_model = OpenAIEmbeddings()
    collection = chroma_client.get_or_create_collection(name="genpy_knowledge")

    for i, doc in enumerate(docs):
        vector = embeddings_model.embed_query(doc.page_content)
        collection.add(
            ids=[f"id_{i}"],
            embeddings=[vector],
            documents=[doc.page_content],
        )

    print(f"✅ Éxito: {len(docs)} fragmentos vectorizados y guardados en ChromaDB.")


if __name__ == "__main__":
    run_ingestion()
