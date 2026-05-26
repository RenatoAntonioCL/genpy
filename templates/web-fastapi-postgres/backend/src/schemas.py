from pydantic import BaseModel, EmailStr
from datetime import datetime
from typing import Optional

class UserCreate(BaseModel):
    username: str  # Sincronizado con el modelo
    email: EmailStr

class UserResponse(BaseModel):
    id: int
    username: str
    email: str
    created_at: Optional[datetime] = None

    class Config:
        from_attributes = True

# FALTABA ESTO:
class PostCreate(BaseModel):
    title: str
    content: str

class PostResponse(PostCreate):
    id: int
    owner_id: int

    class Config:
        from_attributes = True