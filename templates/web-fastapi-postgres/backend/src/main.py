import os

from fastapi import FastAPI

from src.database import Base, engine
from src.models import Post, User  # noqa: F401 — registra modelos en Base
from src.routers import users

PROJECT_NAME = os.getenv("PROJECT_NAME", "{{PROJECT_NAME}}")

Base.metadata.create_all(bind=engine)

app = FastAPI(
    title=f"{PROJECT_NAME} API",
    description="API generada con GenPy",
    version="0.1.0",
)

app.include_router(users.router, prefix="/users", tags=["users"])


@app.get("/")
def read_root():
    return {
        "status": "ok",
        "project": PROJECT_NAME,
        "db": "Tablas creadas exitosamente",
    }
