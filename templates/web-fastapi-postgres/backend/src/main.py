from fastapi import FastAPI
from src.models import User, Post  # <--- Esto es vital
from src.database import engine, Base
from src.routers import users

# Crear tablas al iniciar si no existen
Base.metadata.create_all(bind=engine)

app = FastAPI(
    title="{{PROJECT_NAME}} API",
    description="API generada con GenPy",
    version="0.1.0",
)

app.include_router(users.router, prefix="/users", tags=["users"])


@app.get("/")
def read_root():
    return {"status": "ok", "project": "{{PROJECT_NAME}}", "db": "Tablas creadas exitosamente"}
    