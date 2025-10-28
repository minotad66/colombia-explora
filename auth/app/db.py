from sqlmodel import SQLModel, Session, create_engine
from sqlalchemy.engine import Engine
import os
import ssl

# Para Lambda, usamos postgresql+pg8000 (driver puro Python, sin dependencias compiladas)
DATABASE_URL = os.environ.get("DATABASE_URL", "postgresql://explora_user:explora_pass@postgres/explora_db")

# Reemplazar postgresql:// por postgresql+pg8000:// para usar pg8000
if DATABASE_URL.startswith("postgresql://") and "+pg8000" not in DATABASE_URL:
    DATABASE_URL = DATABASE_URL.replace("postgresql://", "postgresql+pg8000://")
elif "+asyncpg" in DATABASE_URL:
    DATABASE_URL = DATABASE_URL.replace("postgresql+asyncpg://", "postgresql+pg8000://")

# Configurar SSL para RDS (requerido por AWS)
ssl_context = ssl.create_default_context()
ssl_context.check_hostname = False
ssl_context.verify_mode = ssl.CERT_NONE

engine: Engine = create_engine(
    DATABASE_URL, 
    echo=False,
    connect_args={"ssl_context": ssl_context}
)


def get_session():
    with Session(engine) as session:
        yield session
