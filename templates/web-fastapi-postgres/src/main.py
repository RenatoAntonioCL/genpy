from fastapi import FastAPI
from src.database import engine, Base
from src.routers import users

# Crear tablas al iniciar si no existen
Base.metadata.create_all(bind=engine)

app = FastAPI(
    title="{{PROJECT_NAME}}",
    description="API generada con GenPy",
    version="0.1.0",
)

app.include_router(users.router, prefix="/users", tags=["users"])


@app.get("/")
def health_check():
    return {"status": "ok", "project": "{{PROJECT_NAME}}"}