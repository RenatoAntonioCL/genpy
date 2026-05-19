import os
import chromadb
from langchain_openai import ChatOpenAI

def ask_rag(question: str):
    # 1. Buscar contexto relevante en la base de datos vectorial
    chroma_client = chromadb.HttpClient(host=os.getenv("CHROMA_HOST", "localhost"), port=8000)
    collection = chroma_client.get_collection(name="genpy_knowledge")
    
    # Vectorizar la pregunta para buscar similitud
    from langchain_openai import OpenAIEmbeddings
    query_vector = OpenAIEmbeddings().embed_query(question)
    
    results = collection.query(query_embeddings=[query_vector], n_results=1)
    context = results['documents'][0][0] if results['documents'] else "No hay contexto disponible."
    
    # 2. Construir el Prompt de Ingeniería
    prompt = f"""
    Eres un asistente de IA muy profesional. Responde la pregunta basándote únicamente en el contexto provisto.
    Si no sabes la respuesta, di que no la sabes.
    
    CONTEXTO:
    {context}
    
    PREGUNTA:
    {question}
    
    RESPUESTA:
    """
    
    # 3. Consultar al LLM
    llm = ChatOpenAI(model="gpt-4o-mini", temperature=0)
    response = llm.invoke(prompt)
    
    print("\n🤖 Respuesta de la IA:")
    print(response.content)

if __name__ == "__main__":
    print("🤖 RAG System Activo.")
    user_query = input("❓ Hazle una pregunta a tus documentos: ")
    ask_rag(user_query)