# 🚀 Despliegue Serverless en AWS

## 🏗️ Arquitectura Serverless Completa

### Componentes de la Arquitectura:

```
┌─────────────────────────────────────────────────────────────────┐
│                     ARQUITECTURA SERVERLESS                      │
└─────────────────────────────────────────────────────────────────┘

                          USUARIO
                             ↓
                    ┌────────────────┐
                    │  CloudFront    │ ← Dominio (CDN)
                    │  (Distribución)│
                    └────────┬───────┘
                             ↓
            ┌────────────────┴────────────────┐
            │                                 │
    ┌───────▼───────┐              ┌─────────▼─────────┐
    │   S3 Bucket   │              │   API Gateway     │
    │   (Frontend)  │              │  (REST API)       │
    │   Angular     │              └─────────┬─────────┘
    │   Estáticos   │                        │
    └───────────────┘                        ↓
                              ┌──────────────┴──────────────┐
                              │                             │
                    ┌─────────▼─────────┐    ┌─────────────▼────────┐
                    │  Lambda Function  │    │  Lambda Function     │
                    │  (Auth Service)   │    │  (API Service)       │
                    └─────────┬─────────┘    └─────────┬────────────┘
                              │                        │
                              └────────────┬───────────┘
                                           ↓
                              ┌────────────────────────┐
                              │   RDS PostgreSQL       │
                              │   (Base de Datos)      │
                              └────────────┬───────────┘
                                           │
                              ┌────────────▼───────────┐
                              │   SNS (Simple          │
                              │   Notification Service)│
                              │   (Alertas)            │
                              └────────────┬───────────┘
                                           ↓
                              ┌────────────────────────┐
                              │   CloudWatch           │
                              │   (Logs + Métricas)    │
                              └────────────────────────┘
```

---

## 📋 Componentes Explicados

### 1. **CloudFront** (CDN - Content Delivery Network)
- **Función**: Punto de entrada principal con dominio personalizado
- **Ventaja**: Cacheo global, HTTPS gratis, mejor rendimiento
- **Dominio**: `tuapp.tudominio.com`

### 2. **S3 Bucket** (Simple Storage Service)
- **Función**: Almacenar el frontend compilado (Angular build)
- **Contenido**: HTML, CSS, JavaScript estáticos
- **Acceso**: Público (solo lectura) vía CloudFront

### 3. **API Gateway**
- **Función**: Manejo de rutas/endpoints HTTP
- **Rutas**: `/auth/*`, `/api/*`
- **Características**: 
  - Control de permisos (IAM, Cognito)
  - Rate limiting
  - CORS
  - Transformación de requests/responses

### 4. **Lambda Functions** (Serverless compute)
- **Auth Lambda**: Maneja autenticación y autorización
- **API Lambda**: Maneja lógica de negocio (destinos, reservas)
- **Ventaja**: Pago por uso (solo cuando se ejecuta)
- **Runtime**: Python 3.11

### 5. **RDS PostgreSQL**
- **Función**: Base de datos relacional
- **Tipo**: PostgreSQL 15
- **Configuración**: 
  - Free Tier: db.t3.micro
  - Storage: 20 GB
  - Multi-AZ: No (para Free Tier)

### 6. **SNS** (Simple Notification Service)
- **Función**: Envío de alertas y notificaciones
- **Usos**:
  - Errores de Lambda
  - Métricas críticas
  - Notificaciones a administradores

### 7. **CloudWatch**
- **Función**: Monitoreo y logs centralizados
- **Características**:
  - Logs de Lambda
  - Métricas de API Gateway
  - Alarmas personalizadas
  - Dashboards

---

## 🎯 Paso a Paso: Despliegue Completo

### FASE 1: Configuración de RDS PostgreSQL

#### 1.1 Crear Base de Datos RDS

```bash
# En AWS Console → RDS → Create database

Configuración:
- Engine: PostgreSQL 15
- Template: Free tier
- DB instance identifier: explora-postgres
- Master username: explora_user
- Master password: [CONTRASEÑA SEGURA]
- DB instance class: db.t3.micro
- Storage: 20 GB (Free tier)
- Public access: No (seguridad)
- VPC: Default VPC
- Security group: Crear nuevo "explora-db-sg"
- Database name: explora_db
```

#### 1.2 Configurar Security Group de RDS

```
Reglas de entrada (Inbound):
- Type: PostgreSQL (5432)
- Source: Lambda Security Group (se creará después)
- Description: Allow Lambda access
```

---

### FASE 2: Preparar Código para Lambda

#### 2.1 Adaptar Auth Service para Lambda

Crear `auth/lambda_handler.py`:

```python
import json
import os
from mangum import Mangum
from app.main import app

# Mangum adapta FastAPI para AWS Lambda
handler = Mangum(app, lifespan="off")

# Variables de entorno desde Lambda:
# - DATABASE_URL
# - JWT_SECRET
```

#### 2.2 Adaptar API Service para Lambda

Crear `api/lambda_handler.py`:

```python
import json
import os
from mangum import Mangum
from app.main import app

handler = Mangum(app, lifespan="off")
```

#### 2.3 Actualizar requirements.txt

Agregar a `auth/requirements.txt` y `api/requirements.txt`:

```txt
mangum==0.17.0  # Adaptador FastAPI → Lambda
```

#### 2.4 Crear Scripts de Empaquetado

Crear `scripts/package-lambda.sh`:

```bash
#!/bin/bash
# Script para empaquetar Lambda functions

echo "📦 Empaquetando Lambda Functions..."

# Auth Service
echo "Empaquetando Auth Service..."
cd auth
mkdir -p lambda_package
pip install -r requirements.txt -t lambda_package/
cp -r app lambda_package/
cp lambda_handler.py lambda_package/
cd lambda_package
zip -r ../auth-lambda.zip . -q
cd ../..
echo "✅ auth-lambda.zip creado"

# API Service
echo "Empaquetando API Service..."
cd api
mkdir -p lambda_package
pip install -r requirements.txt -t lambda_package/
cp -r app lambda_package/
cp lambda_handler.py lambda_package/
cd lambda_package
zip -r ../api-lambda.zip . -q
cd ../..
echo "✅ api-lambda.zip creado"

echo "✅ Empaquetado completado!"
echo "Archivos creados:"
echo "  - auth/auth-lambda.zip"
echo "  - api/api-lambda.zip"
```

---

### FASE 3: Crear Lambda Functions

#### 3.1 Crear Auth Lambda

```bash
# AWS Console → Lambda → Create function

Configuración:
- Function name: explora-auth
- Runtime: Python 3.11
- Architecture: x86_64
- Execution role: Create new role "explora-lambda-role"

Después de crear:
1. Upload: auth-lambda.zip
2. Handler: lambda_handler.handler
3. Timeout: 30 segundos
4. Memory: 512 MB
5. Environment variables:
   - DATABASE_URL=postgresql+asyncpg://explora_user:PASSWORD@RDS_ENDPOINT/explora_db
   - JWT_SECRET=[TU_SECRET]
```

#### 3.2 Crear API Lambda

```bash
Configuración:
- Function name: explora-api
- Runtime: Python 3.11
- Upload: api-lambda.zip
- Handler: lambda_handler.handler
- Timeout: 30 segundos
- Memory: 512 MB
- Environment variables:
   - DATABASE_URL=postgresql+asyncpg://explora_user:PASSWORD@RDS_ENDPOINT/explora_db
   - AUTH_URL=https://[API_GATEWAY_URL]/auth
   - JWT_SECRET=[TU_SECRET]
```

#### 3.3 Configurar VPC y Security Groups para Lambda

```bash
# En cada Lambda → Configuration → VPC

VPC: Default VPC
Subnets: Seleccionar 2+ subnets privadas
Security groups: Crear nuevo "explora-lambda-sg"

Security Group Rules (explora-lambda-sg):
Outbound:
- Type: PostgreSQL (5432) → Destination: RDS Security Group
- Type: HTTPS (443) → Destination: 0.0.0.0/0 (para llamadas externas)
```

---

### FASE 4: Configurar API Gateway

#### 4.1 Crear API REST

```bash
# AWS Console → API Gateway → Create API

Tipo: REST API
Name: explora-api-gateway
Endpoint Type: Regional
```

#### 4.2 Crear Recursos y Métodos

```
Estructura:
/
├── /auth
│   ├── /register (POST) → Lambda: explora-auth
│   ├── /login (POST) → Lambda: explora-auth
│   └── /{proxy+} (ANY) → Lambda: explora-auth
│
└── /api
    ├── /destinations (GET, POST) → Lambda: explora-api
    ├── /destinations/{id} (GET, PUT, DELETE) → Lambda: explora-api
    ├── /reservations (GET, POST) → Lambda: explora-api
    └── /{proxy+} (ANY) → Lambda: explora-api
```

#### 4.3 Configurar CORS

Para cada método, habilitar CORS:

```bash
# Actions → Enable CORS

Access-Control-Allow-Origin: '*' (o tu dominio)
Access-Control-Allow-Headers: 'Content-Type,X-Amz-Date,Authorization,X-Api-Key'
Access-Control-Allow-Methods: 'GET,POST,PUT,DELETE,OPTIONS'
```

#### 4.4 Deploy API

```bash
# Actions → Deploy API

Stage name: prod
Description: Production deployment
```

**URL de API Gateway**: `https://[API_ID].execute-api.[REGION].amazonaws.com/prod`

---

### FASE 5: Frontend en S3

#### 5.1 Compilar Angular para Producción

```bash
# En tu máquina local
cd frontend

# Actualizar environment.prod.ts
cat > src/environments/environment.prod.ts << EOF
export const environment = {
  production: true,
  apiUrl: 'https://[API_ID].execute-api.[REGION].amazonaws.com/prod/api',
  authUrl: 'https://[API_ID].execute-api.[REGION].amazonaws.com/prod/auth'
};
EOF

# Compilar
npm run build

# Resultado en: frontend/dist/
```

#### 5.2 Crear S3 Bucket

```bash
# AWS Console → S3 → Create bucket

Bucket name: explora-frontend-[TU_NOMBRE]
Region: us-east-1 (para CloudFront)
Block all public access: DESMARCAR
Bucket Versioning: Disabled
```

#### 5.3 Configurar S3 para Hosting Estático

```bash
# Properties → Static website hosting

Enable: Yes
Index document: index.html
Error document: index.html (para SPA routing)
```

#### 5.4 Bucket Policy (Hacer público)

```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "PublicReadGetObject",
            "Effect": "Allow",
            "Principal": "*",
            "Action": "s3:GetObject",
            "Resource": "arn:aws:s3:::explora-frontend-[TU_NOMBRE]/*"
        }
    ]
}
```

#### 5.5 Subir Archivos

```bash
# Opción 1: Consola web (drag & drop dist/)

# Opción 2: AWS CLI
aws s3 sync frontend/dist/ s3://explora-frontend-[TU_NOMBRE]/ --delete
```

---

### FASE 6: CloudFront (CDN + Dominio)

#### 6.1 Crear Distribución CloudFront

```bash
# AWS Console → CloudFront → Create distribution

Origin domain: explora-frontend-[TU_NOMBRE].s3-website-[REGION].amazonaws.com
Origin path: (dejar vacío)
Name: explora-s3-origin

Default cache behavior:
- Viewer protocol policy: Redirect HTTP to HTTPS
- Allowed HTTP methods: GET, HEAD, OPTIONS
- Cache policy: CachingOptimized

Settings:
- Price class: Use all edge locations
- Alternate domain name (CNAME): tuapp.tudominio.com
- Custom SSL certificate: [Crear en ACM primero]
- Default root object: index.html
```

#### 6.2 Configurar Error Pages (para SPA)

```bash
# Error pages

Error code: 403
Response page path: /index.html
HTTP Response code: 200

Error code: 404
Response page path: /index.html
HTTP Response code: 200
```

---

### FASE 7: SNS + CloudWatch

#### 7.1 Crear Topic SNS

```bash
# AWS Console → SNS → Create topic

Type: Standard
Name: explora-alerts
Display name: Explora Alerts
```

#### 7.2 Crear Suscripción

```bash
# Topic → Create subscription

Protocol: Email
Endpoint: tu-email@ejemplo.com

(Confirmar email)
```

#### 7.3 Configurar CloudWatch Alarms

```bash
# CloudWatch → Alarms → Create alarm

Métricas sugeridas:
1. Lambda Errors > 5 en 5 minutos
2. API Gateway 5XX > 10 en 5 minutos
3. RDS CPU > 80%
4. Lambda Duration > 25 segundos

Action: Send notification to SNS → explora-alerts
```

---

## 💰 Costos Estimados (Free Tier)

| Servicio | Free Tier | Costo después |
|----------|-----------|---------------|
| S3 | 5 GB storage, 20k GET | $0.023/GB |
| CloudFront | 1 TB transferencia | $0.085/GB |
| Lambda | 1M requests, 400k GB-s | $0.20 por 1M requests |
| API Gateway | 1M llamadas | $3.50 por 1M llamadas |
| RDS db.t3.micro | 750 horas/mes (1 año) | $0.018/hora |
| CloudWatch | 10 métricas, 5 GB logs | $0.50/métrica |

**Total primer año (dentro de Free Tier):** $0 - $5/mes
**Después del primer año:** $15-30/mes (tráfico bajo)

---

## 🔐 Seguridad y Mejores Prácticas

### 1. Secrets Manager para Credenciales

```bash
# Guardar DATABASE_URL y JWT_SECRET en Secrets Manager
# Acceder desde Lambda usando IAM roles
```

### 2. IAM Roles Mínimos

```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "logs:CreateLogGroup",
                "logs:CreateLogStream",
                "logs:PutLogEvents",
                "ec2:CreateNetworkInterface",
                "ec2:DescribeNetworkInterfaces",
                "ec2:DeleteNetworkInterface",
                "rds-db:connect"
            ],
            "Resource": "*"
        }
    ]
}
```

### 3. API Gateway con API Keys

```bash
# Para rate limiting por cliente
```

---

## 📊 Monitoreo con CloudWatch

### Dashboards Recomendados

```
1. Overview Dashboard:
   - Lambda invocations
   - API Gateway requests
   - Error rates
   - P99 latency

2. Database Dashboard:
   - RDS CPU
   - Connections
   - Storage
   - IOPS

3. Frontend Dashboard:
   - CloudFront requests
   - Cache hit rate
   - Error rates by location
```

---

## 🚀 CI/CD con GitHub Actions

Crear `.github/workflows/deploy.yml`:

```yaml
name: Deploy to AWS

on:
  push:
    branches: [main]

jobs:
  deploy-lambda:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      
      - name: Package Lambda
        run: ./scripts/package-lambda.sh
      
      - name: Deploy to Lambda
        uses: aws-actions/configure-aws-credentials@v1
        with:
          aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
          aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
          aws-region: us-east-1
      
      - name: Update Lambda functions
        run: |
          aws lambda update-function-code \
            --function-name explora-auth \
            --zip-file fileb://auth/auth-lambda.zip
          
          aws lambda update-function-code \
            --function-name explora-api \
            --zip-file fileb://api/api-lambda.zip
  
  deploy-frontend:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      
      - name: Build Angular
        run: |
          cd frontend
          npm ci
          npm run build
      
      - name: Deploy to S3
        run: |
          aws s3 sync frontend/dist/ s3://explora-frontend/ --delete
      
      - name: Invalidate CloudFront
        run: |
          aws cloudfront create-invalidation \
            --distribution-id ${{ secrets.CLOUDFRONT_ID }} \
            --paths "/*"
```

---

## 🆘 Troubleshooting Común

### Lambda no puede conectar a RDS

```bash
# Verificar:
1. Lambda está en el mismo VPC que RDS
2. Lambda Security Group permite salida a RDS port 5432
3. RDS Security Group permite entrada desde Lambda SG
4. Subnets tienen rutas a Internet (para pip install)
```

### CloudFront no sirve SPA routing

```bash
# Configurar error pages (403, 404) → /index.html con código 200
```

### CORS errors en API Gateway

```bash
# Habilitar CORS en todos los métodos
# Agregar OPTIONS method
# Desplegar cambios
```

---

## ✅ Checklist de Despliegue

- [ ] RDS PostgreSQL creado y accesible
- [ ] Lambda Auth empaquetado y desplegado
- [ ] Lambda API empaquetado y desplegado
- [ ] API Gateway configurado con rutas
- [ ] CORS habilitado en API Gateway
- [ ] Frontend compilado para producción
- [ ] S3 bucket creado y archivos subidos
- [ ] CloudFront distribution creada
- [ ] Dominio configurado (Route 53 o externo)
- [ ] SNS topic creado y email confirmado
- [ ] CloudWatch alarms configuradas
- [ ] Pruebas end-to-end completadas

---

¡Listo para desplegar en arquitectura serverless! 🚀
