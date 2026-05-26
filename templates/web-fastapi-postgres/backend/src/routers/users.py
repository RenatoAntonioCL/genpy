from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from src.database import get_db
from src import crud, schemas

router = APIRouter()

@router.post("/", response_model=schemas.UserResponse)
def create_user(user: schemas.UserCreate, db: Session = Depends(get_db)):
    return crud.create_user(db=db, user=user)

# Nuevo endpoint: POST /users/{user_id}/posts
@router.post("/{user_id}/posts", response_model=schemas.PostResponse)
def create_post_for_user(user_id: int, post: schemas.PostCreate, db: Session = Depends(get_db)):
    return crud.create_user_post(db=db, post=post, user_id=user_id)