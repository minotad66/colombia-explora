"""
Lambda Handler para Auth Service
Adapta FastAPI para ejecutarse en AWS Lambda usando Mangum
"""
import os
from mangum import Mangum
from app.main import app

# Mangum es el adaptador que convierte requests de API Gateway
# al formato que FastAPI entiende
handler = Mangum(app, lifespan="off")

# Variables de entorno requeridas (configurar en Lambda):
# - DATABASE_URL: postgresql+asyncpg://user:pass@rds-endpoint/db
# - JWT_SECRET: Secret key para JWT tokens
