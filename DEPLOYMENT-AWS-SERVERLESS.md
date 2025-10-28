# 🚀 Despliegue Serverless en AWS - Colombia Explora

**Fecha:** 27 de Octubre de 2025  
**Equipo:** SebaxtriUTP

---

## 📋 Resumen del Despliegue

Este documento detalla el proceso completo de despliegue de la aplicación **Colombia Explora** en AWS usando arquitectura serverless (Lambda + API Gateway + RDS + S3).

---

## 🏗️ Arquitectura Desplegada

```
┌─────────────────────────────────────────────────────────────┐
│                         INTERNET                             │
└──────────────┬────────────────────────────┬─────────────────┘
               │                            │
               │                            │
        ┌──────▼───────┐            ┌──────▼──────┐
        │   S3 Bucket  │            │ API Gateway │
        │   (Frontend) │            │  (HTTP API) │
        │   Angular    │            │             │
        └──────────────┘            └──────┬──────┘
                                           │
                          ┌────────────────┴────────────────┐
                          │                                 │
                   ┌──────▼───────┐              ┌─────────▼────────┐
                   │ Lambda Auth  │              │  Lambda API      │
                   │ (Python 3.11)│              │  (Python 3.11)   │
                   └──────┬───────┘              └─────────┬────────┘
                          │                                │
                          └────────────┬───────────────────┘
                                       │
                                ┌──────▼──────┐
                                │ RDS PostgreSQL│
                                │  (Database)   │
                                └───────────────┘
```

---

## 🎯 URLs de la Aplicación

### Frontend (S3 Static Website)
```
http://colombia-explora-frontend.s3-website-us-east-1.amazonaws.com
```

### Backend API (API Gateway)
```
https://ynhe00xnv9.execute-api.us-east-1.amazonaws.com
```

**Endpoints disponibles:**
- `GET /auth/health` - Health check
- `POST /auth/register` - Registro de usuarios
- `POST /auth/token` - Login y obtención de JWT
- `POST /auth/make-admin/{username}` - Convertir usuario en admin
- `GET /api/health` - Health check
- `GET /api/destinations` - Listar destinos
- `POST /api/destinations` - Crear destino (solo admin)
- `POST /api/reservations` - Crear reservación
- `GET /api/reservations` - Ver mis reservaciones

---

## 🔐 Credenciales de Acceso

### Usuario Administrador
```
Username: superadmin
Password: admin123
Role: admin
```

### Base de Datos RDS
```
Host: colombia-explora-db-prod.cq9w2yq26aau.us-east-1.amazonaws.com
Database: colombiaexploraprod
User: explora_user
Password: ExploraPass123!
Port: 5432
```

---

## 📦 Componentes AWS

### 1. Lambda Functions

#### explora-auth
- Runtime: Python 3.11
- Memoria: 512 MB
- Timeout: 30s
- Handler: `lambda_handler.handler`
- Environment Variables:
  - `DATABASE_URL`: Connection string completo
  - `JWT_SECRET`: ExploraSecretKey2024!

#### explora-api
- Runtime: Python 3.11  
- Memoria: 512 MB
- Timeout: 30s
- Handler: `lambda_handler.handler`
- Environment Variables: Igual que auth

### 2. API Gateway
- Nombre: Colombia-explora-buena
- ID: ynhe00xnv9
- Type: HTTP API
- Stage: $default (auto-deploy)
- CORS: Habilitado (Allow all)

### 3. S3 Bucket
- Nombre: colombia-explora-frontend
- Static Website: Habilitado
- Public Access: Permitido

### 4. RDS PostgreSQL
- Instance: colombia-explora-db-prod
- Engine: PostgreSQL
- VPC: Default
- SSL: Habilitado

---

## 🛠️ Cambios Técnicos Realizados

### 1. Migración a Bibliotecas Puras Python
- ✅ `asyncpg` → `pg8000`
- ✅ `bcrypt` → `hashlib.pbkdf2_hmac`
- ✅ Eliminadas dependencias compiladas

### 2. Conversión Async → Sync
- ✅ `async def` → `def`
- ✅ `AsyncSession` → `Session`
- ✅ Eliminados `await`

### 3. SSL para RDS
```python
ssl_context = ssl.create_default_context()
ssl_context.verify_mode = ssl.CERT_NONE
```

### 4. Mangum Base Path
```python
handler = Mangum(app, lifespan="off", api_gateway_base_path="/auth")
```

### 5. Token Type en Respuesta
```python
return {"access_token": token, "token_type": "bearer"}
```

### 6. Frontend para AWS
```javascript
window.__env.API_URL = 'https://ynhe00xnv9.execute-api.us-east-1.amazonaws.com/api';
window.__env.AUTH_URL = 'https://ynhe00xnv9.execute-api.us-east-1.amazonaws.com/auth';
```

---

## 🔄 Actualizar el Código

### Actualizar Lambdas
```bash
# 1. Modificar código
# 2. Re-empaquetar
./scripts/package-lambda.sh

# 3. Subir a AWS Lambda Console
# Lambda → Code → Upload from → .zip file
```

### Actualizar Frontend
```bash
cd frontend
npm run build -- --configuration production
# Subir archivos de dist/explora/ a S3
```

---

## ✅ Verificación

```bash
# Health checks
curl https://ynhe00xnv9.execute-api.us-east-1.amazonaws.com/auth/health
curl https://ynhe00xnv9.execute-api.us-east-1.amazonaws.com/api/health

# Registro
curl -X POST https://ynhe00xnv9.execute-api.us-east-1.amazonaws.com/auth/register \
  -H "Content-Type: application/json" \
  -d '{"username":"test","email":"test@test.com","password":"test123"}'

# Login
curl -X POST https://ynhe00xnv9.execute-api.us-east-1.amazonaws.com/auth/token \
  -H "Content-Type: application/json" \
  -d '{"username":"superadmin","password":"admin123"}'
```

---

## 🐛 Troubleshooting

### CORS Error
**Solución:** API Gateway → CORS → Headers: `*`

### 404 en rutas Angular
**Solución:** S3 → Static website → Error document: `index.html`

### Database Connection Error
**Solución:** 
- Verificar VPC
- Verificar Security Groups
- Verificar SSL configuration

---

## 💰 Costos Estimados

**Free Tier (primer año):**
- RDS: 750 horas/mes
- Lambda: 1M requests/mes
- API Gateway: 1M llamadas/mes
- S3: 5GB + 20k GET requests

**Después del Free Tier:** ~$20-30/mes

---

## 📚 Recursos

- [AWS Lambda Docs](https://docs.aws.amazon.com/lambda/)
- [API Gateway HTTP API](https://docs.aws.amazon.com/apigateway/)
- [FastAPI](https://fastapi.tiangolo.com/)
- [Mangum](https://mangum.io/)

---

**Última actualización:** 27 de Octubre de 2025  
**Status:** ✅ Desplegado y Funcional
