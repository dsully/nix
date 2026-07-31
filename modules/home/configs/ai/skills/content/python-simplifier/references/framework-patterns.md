---
description: >-
  Framework-specific simplification patterns for FastAPI:
  dependency injection, response models, QuerySet methods, and manager patterns.
metadata:
  tags: [python, FastAPI, framework, patterns]
---

# Framework-Specific Patterns

## FastAPI - Dependency Injection

```python
# Before - repeated in every route
@app.get("/users")
async def get_users():
    db = SessionLocal()
    try:
        users = db.query(User).all()
        return users
    finally:
        db.close()

# After - use dependencies
def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

@app.get("/users")
async def get_users(db: Session = Depends(get_db)):
    return db.query(User).all()
```

## FastAPI - Response Models

```python
# Before - manual dict construction
@app.get("/users/{user_id}")
async def get_user(user_id: int):
    user = db.query(User).filter(User.id == user_id).first()
    return {
        "id": user.id,
        "name": user.name,
        "email": user.email
    }

# After - Pydantic response model
class UserResponse(BaseModel):
    id: int
    name: str
    email: str

    class Config:
        from_attributes = True

@app.get("/users/{user_id}", response_model=UserResponse)
async def get_user(user_id: int):
    return db.query(User).filter(User.id == user_id).first()
```
