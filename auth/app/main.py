from fastapi import FastAPI, HTTPException, Depends
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
import jwt
import os
import hashlib
import hmac
from datetime import datetime, timedelta
from .db import engine, get_session
from .models import User
from sqlmodel import SQLModel, select, Session

app = FastAPI(title="explora-auth")
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

SECRET = os.environ.get("JWT_SECRET", "devsecret")

# Funciones de hashing con PBKDF2 (puro Python, sin dependencias compiladas)
def hash_password(password: str) -> str:
    """Hash password usando PBKDF2-SHA256"""
    salt = os.urandom(32)
    pwdhash = hashlib.pbkdf2_hmac('sha256', password.encode('utf-8'), salt, 100000)
    return salt.hex() + pwdhash.hex()

def verify_password(password: str, hashed: str) -> bool:
    """Verificar password contra hash"""
    try:
        salt = bytes.fromhex(hashed[:64])
        stored_hash = bytes.fromhex(hashed[64:])
        pwdhash = hashlib.pbkdf2_hmac('sha256', password.encode('utf-8'), salt, 100000)
        return hmac.compare_digest(pwdhash, stored_hash)
    except:
        return False


class RegisterRequest(BaseModel):
    username: str
    email: str | None = None
    password: str


class TokenRequest(BaseModel):
    username: str
    password: str


@app.on_event("startup")
def on_startup():
    import time
    # Wait for DB to be ready with retries
    retries = 12
    delay = 2
    for attempt in range(1, retries + 1):
        try:
            SQLModel.metadata.create_all(engine)
            # Create default admin user if it doesn't exist
            with Session(engine) as session:
                q = select(User).where(User.username == "admin")
                r = session.exec(q)
                admin = r.first()
                if not admin:
                    hashed = hash_password("admin123")
                    admin = User(username="admin", email="admin@explora.com", hashed_password=hashed, role="admin")
                    session.add(admin)
                    session.commit()
            break
        except Exception as exc:
            if attempt == retries:
                raise
            time.sleep(delay)


@app.get("/health")
def health():
    return {"status": "ok"}


@app.post("/register")
def register(req: RegisterRequest, session: Session = Depends(get_session)):
    q = select(User).where(User.username == req.username)
    r = session.exec(q)
    existing = r.first()
    if existing:
        raise HTTPException(status_code=400, detail="Username already exists")
    hashed = hash_password(req.password)
    user = User(username=req.username, email=req.email, hashed_password=hashed)
    session.add(user)
    session.commit()
    session.refresh(user)
    return {"id": user.id, "username": user.username}


@app.post("/token")
def token(req: TokenRequest, session: Session = Depends(get_session)):
    q = select(User).where(User.username == req.username)
    r = session.exec(q)
    user = r.first()
    if not user or not verify_password(req.password, user.hashed_password):
        raise HTTPException(status_code=401, detail="Invalid credentials")
    now = datetime.utcnow()
    payload = {
        "sub": user.username,
        "user_id": user.id,
        "role": user.role,
        "iat": int(now.timestamp()),
        "exp": int((now + timedelta(hours=4)).timestamp()),
    }
    token = jwt.encode(payload, SECRET, algorithm="HS256")
    return {"access_token": token, "token_type": "bearer"}


@app.get("/verify")
async def verify(token: str = ""):
    try:
        payload = jwt.decode(token, SECRET, algorithms=["HS256"])
        return {"valid": True, "sub": payload.get("sub"), "user_id": payload.get("user_id")}
    except jwt.PyJWTError:
        raise HTTPException(status_code=401, detail="Invalid token")


@app.post("/make-admin/{username}")
def make_admin(username: str, session: Session = Depends(get_session)):
    """Endpoint temporal para hacer admin a un usuario"""
    q = select(User).where(User.username == username)
    r = session.exec(q)
    user = r.first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    user.role = "admin"
    session.add(user)
    session.commit()
    session.refresh(user)
    return {"message": f"User {username} is now admin", "user_id": user.id, "role": user.role}
