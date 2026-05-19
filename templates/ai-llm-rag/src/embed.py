import os
import chromadb
from langchain_community.document_loaders import TextLoader
from langchain_text_splitters import CharacterTextSplitter
from langchain_openai import OpenAIEmbeddings

def run_ingestion():
    print("📥 Iniciando indexación de documentos...")
    
    # 1. Conectar a la Base de Datos Vectorial remota en Docker
    chroma_client = chromadb.HttpClient(host=os.getenv("CHROMA_HOST", "localhost"), port=8000)
    
    # 2. Leer el archivo de contexto
    loader = TextLoader("data/context.txt")
    documents = loader.load()
    
    # 3. Fragmentar el texto en bloques pequeños (Chunks)
    text_splitter = CharacterTextSplitter(chunk_size=200, chunk_overlap=20)
    docs = text_splitter.split_documents(documents)
    
    # 4. Inicializar el modelo de embeddings
    embeddings_model = OpenAIEmbeddings()
    
    # 5. Guardar vectores en ChromaDB
    collection = chroma_client.get_or_create_collection(name="genpy_knowledge")
    
    for i, doc in enumerate(docs):
        vector = embeddings_model.embed_query(doc.page_content)
        collection.add(
            ids=[f"id_{i}"],
            embeddings=[vector],
            documents=[doc.page_content]
        )
        
    print(f"✅ Éxito: {len(docs)} fragmentos vectorizados y guardados en ChromaDB.")

if __name__ == "__main__":
    run_ingestion()