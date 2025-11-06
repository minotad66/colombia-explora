from fastapi import FastAPI, Depends, HTTPException, Header
from pydantic import BaseModel
from fastapi.middleware.cors import CORSMiddleware
from sqlmodel import SQLModel, select, Session
from .db import engine, get_session
from .models import User, Destination, Reservation
from datetime import date
import os
import jwt

app = FastAPI(title="explora-api")
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


JWT_SECRET = os.environ.get("JWT_SECRET", os.environ.get("AUTH_JWT_SECRET", "devsecret"))


def require_token(authorization: str | None = Header(default=None)):
    if not authorization:
        raise HTTPException(status_code=401, detail="Missing Authorization header")
    try:
        scheme, token = authorization.split()
        if scheme.lower() != "bearer":
            raise HTTPException(status_code=401, detail="Invalid auth scheme")
    except ValueError:
        raise HTTPException(status_code=401, detail="Malformed Authorization header")
    try:
        payload = jwt.decode(token, JWT_SECRET, algorithms=["HS256"])
        return payload
    except jwt.PyJWTError:
        raise HTTPException(status_code=401, detail="Invalid token")


def require_admin(authorization: str | None = Header(default=None)):
    payload = require_token(authorization)
    if payload.get("role") != "admin":
        raise HTTPException(status_code=403, detail="Admin access required")
    return payload


class ReservationCreate(BaseModel):
    destination_id: int
    people: int = 1
    check_in: date
    check_out: date


class DestinationUpdate(BaseModel):
    name: str | None = None
    description: str | None = None
    region: str | None = None
    price: float | None = None


# Variable global para asegurar que las tablas se creen solo una vez
_tables_created = False

def ensure_tables():
    """Asegurar que las tablas existan (llamar antes de cada operación DB)"""
    global _tables_created
    if not _tables_created:
        try:
            SQLModel.metadata.create_all(engine)
            _tables_created = True
        except Exception as exc:
            # Si falla, intentar de nuevo en la próxima request
            pass


@app.get("/health")
def health():
    try:
        ensure_tables()  # Verificar que las tablas existan
        return {"status": "ok", "database": "connected"}
    except Exception as e:
        return {"status": "error", "database": "disconnected", "error": str(e)}


@app.get("/destinations")
def list_destinations(session: Session = Depends(get_session)):
    ensure_tables()  # Asegurar que las tablas existan
    result = session.exec(select(Destination))
    return result.all()


@app.post("/destinations")
def create_destination(dest: Destination, session: Session = Depends(get_session), payload=Depends(require_admin)):
    ensure_tables()  # Asegurar que las tablas existan
    # only admin users can create destinations
    session.add(dest)
    session.commit()
    session.refresh(dest)
    return dest


@app.patch("/destinations/{destination_id}")
def update_destination(
    destination_id: int, 
    updates: DestinationUpdate, 
    session: Session = Depends(get_session), 
    payload=Depends(require_admin)
):
    ensure_tables()  # Asegurar que las tablas existan
    # only admin users can update destinations
    q = select(Destination).where(Destination.id == destination_id)
    r = session.exec(q)
    dest = r.first()
    if not dest:
        raise HTTPException(status_code=404, detail="Destination not found")
    
    # Apply updates only for fields that were provided
    if updates.name is not None:
        dest.name = updates.name
    if updates.description is not None:
        dest.description = updates.description
    if updates.region is not None:
        dest.region = updates.region
    if updates.price is not None:
        dest.price = updates.price
    
    session.add(dest)
    session.commit()
    session.refresh(dest)
    return dest


@app.delete("/destinations/{destination_id}")
def delete_destination(
    destination_id: int, 
    session: Session = Depends(get_session), 
    payload=Depends(require_admin)
):
    ensure_tables()  # Asegurar que las tablas existan
    # only admin users can delete destinations
    q = select(Destination).where(Destination.id == destination_id)
    r = session.exec(q)
    dest = r.first()
    if not dest:
        raise HTTPException(status_code=404, detail="Destination not found")
    
    session.delete(dest)
    session.commit()
    return {"message": "Destination deleted successfully"}

@app.post("/reservations")
def create_reservation(body: 'ReservationCreate', session: Session = Depends(get_session), payload=Depends(require_token)):
    ensure_tables()  # Asegurar que las tablas existan
    # Validate dates
    if body.check_out <= body.check_in:
        raise HTTPException(status_code=400, detail="Check-out date must be after check-in date")
    
    # Ensure destination exists and get price
    q = select(Destination).where(Destination.id == body.destination_id)
    r = session.exec(q)
    dest = r.first()
    if not dest:
        raise HTTPException(status_code=404, detail="Destination not found")
    
    if not dest.price:
        raise HTTPException(status_code=400, detail="Destination has no price set")
    
    # Calculate total price: (price per person per day) * people * days
    days = (body.check_out - body.check_in).days
    total_price = dest.price * body.people * days
    
    res = Reservation(
        user_id=payload.get("user_id"), 
        destination_id=body.destination_id, 
        people=body.people,
        check_in=body.check_in,
        check_out=body.check_out,
        total_price=total_price
    )
    session.add(res)
    session.commit()
    session.refresh(res)
    return res


@app.get("/reservations")
def list_reservations(session: Session = Depends(get_session), payload=Depends(require_token)):
    ensure_tables()  # Asegurar que las tablas existan
    user_id = payload.get("user_id")
    result = session.exec(select(Reservation).where(Reservation.user_id == user_id))
    return result.all()

