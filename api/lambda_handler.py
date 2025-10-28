"""
Lambda Handler para API Service
Adapta FastAPI para ejecutarse en AWS Lambda usando Mangum
"""
import os
from mangum import Mangum
from app.main import app

# Mangum es el adaptador que convierte requests de API Gateway
# al formato que FastAPI entiende
# api_gateway_base_path="/api" le dice a Mangum que quite /api del path
handler = Mangum(app, lifespan="off", api_gateway_base_path="/api")

# Variables de entorno requeridas (configurar en Lambda):
# - DATABASE_URL: postgresql+asyncpg://user:pass@rds-endpoint/db
# - AUTH_URL: URL del servicio auth (API Gateway)
# - JWT_SECRET: Secret key para JWT tokens
