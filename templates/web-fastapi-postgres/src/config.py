from pydantic_settings import BaseSettings


class Settings(BaseSettings):
    DATABASE_URL: str = "postgresql://postgres:postgres@db:5432/{{PROJECT_NAME}}"

    class Config:
        env_file = ".env"


settings = Settings()