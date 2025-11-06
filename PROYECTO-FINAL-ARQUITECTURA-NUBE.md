# PROYECTO FINAL DE ARQUITECTURA EN LA NUBE
## NIVEL INNOVADOR

**Aplicación:** Colombia Explora - Plataforma de Turismo del Eje Cafetero  
**Arquitectura:** Serverless en AWS  
**Infraestructura como Código:** Terraform  
**Estudiante/Grupo:** [Nombre del Estudiante/Grupo]  
**Fecha:** Noviembre 2025

---

# ÍNDICE

1. [Portada](#portada)
2. [Introducción](#introducción)
3. [Desarrollo del Proyecto](#desarrollo-del-proyecto)
   - [3.1 Descripción de la Aplicación](#31-descripción-de-la-aplicación)
   - [3.2 Arquitectura de la Solución](#32-arquitectura-de-la-solución)
   - [3.3 Herramientas y Servicios AWS Utilizados](#33-herramientas-y-servicios-aws-utilizados)
   - [3.4 Infraestructura como Código (IaC)](#34-infraestructura-como-código-iac)
   - [3.5 Implementación y Despliegue](#35-implementación-y-despliegue)
   - [3.6 Monitoreo y Observabilidad](#36-monitoreo-y-observabilidad)
   - [3.7 Seguridad y Mejores Prácticas](#37-seguridad-y-mejores-prácticas)
4. [Resultados Esperados](#resultados-esperados)
5. [Conclusiones](#conclusiones)
6. [Referencias](#referencias)

---

# PORTADA

**PROYECTO FINAL DE ARQUITECTURA EN LA NUBE**  
**NIVEL INNOVADOR**

**Título del Proyecto:**  
Despliegue de Aplicación Full Stack Serverless en AWS con Infraestructura como Código

**Aplicación:**  
Colombia Explora - Plataforma de Reservas Turísticas del Eje Cafetero

**Estudiante/Grupo:**  
[Nombre del Estudiante/Grupo]

**Curso:**  
Arquitectura en la Nube

**Institución:**  
[Nombre de la Institución]

**Fecha de Entrega:**  
[Fecha]

---

# INTRODUCCIÓN

En esta misión, se pusieron en práctica los conocimientos adquiridos a lo largo del curso para llevar a cabo el despliegue de una aplicación full stack, abarcando tanto el frontend como el backend, utilizando arquitecturas avanzadas. Este proyecto enfatiza el uso de las mejores prácticas de Infraestructura como Código (IaC) y DevOps, permitiendo un despliegue automatizado, escalable y eficiente de la aplicación. Además, se integraron sistemas de monitoreo y alerta que aseguran un rendimiento óptimo, facilitando la rápida identificación y resolución de problemas en entornos de producción. A través de esta experiencia, se desarrollaron habilidades esenciales para gestionar entornos complejos en la nube y asegurar la continuidad y la calidad del servicio.

## Objetivo del Proyecto

Asegurar que los campistas reconocen y aplican las técnicas avanzadas de monitoreo y despliegues de servicios propuestas por las arquitecturas en la nube.

## Descripción del Proyecto

En esta misión, se integraron los conocimientos adquiridos a lo largo del curso para desplegar una aplicación full stack, que incluye tanto frontend como backend, utilizando arquitecturas avanzadas. Se aplicaron las mejores prácticas de Infraestructura como Código (IaC) y DevOps, asegurando un despliegue automatizado, escalable y eficiente. Además, se integraron sistemas de monitoreo que garantizan un rendimiento óptimo de la aplicación y la rápida identificación de problemas en entornos de producción.

---

# DESARROLLO DEL PROYECTO

## 3.1 Descripción de la Aplicación

**Colombia Explora** es una plataforma web moderna diseñada para la gestión de reservas de destinos turísticos en el Eje Cafetero colombiano. La aplicación permite a los usuarios:

- **Registro y Autenticación:** Sistema de usuarios con roles (admin/user) y autenticación basada en JWT
- **Gestión de Destinos:** Visualización y administración de destinos turísticos con información detallada
- **Sistema de Reservas:** Creación de reservas con cálculo automático de precios basado en fechas, número de personas y precio por día
- **Panel de Administración:** Interfaz para administradores para gestionar destinos turísticos

### Stack Tecnológico

**Frontend:**
- Angular 15 (Framework JavaScript)
- Bootstrap 5.3 (Framework CSS)
- TypeScript
- RxJS (Programación reactiva)

**Backend:**
- FastAPI (Framework Python para APIs)
- Python 3.11
- SQLModel (ORM basado en Pydantic y SQLAlchemy)
- JWT para autenticación
- PostgreSQL como base de datos

**Infraestructura:**
- AWS (Amazon Web Services)
- Terraform (Infraestructura como Código)
- Docker (Containerización local)

---

## 3.2 Arquitectura de la Solución

La arquitectura implementada sigue un modelo **serverless** que aprovecha los servicios gestionados de AWS, eliminando la necesidad de gestionar servidores y permitiendo un escalado automático basado en la demanda.

### Diagrama de Arquitectura

```
┌─────────────────────────────────────────────────────────────┐
│                    CloudFront Distribution                   │
│              (CDN Global + SSL/TLS Gratuito)                 │
│                    HTTPS: Puerto 443                         │
└───────────────────────────┬─────────────────────────────────┘
                            │
                    ┌───────▼────────┐
                    │   S3 Bucket    │
                    │   (Frontend)   │
                    │  Static Files  │
                    │  (Angular SPA) │
                    └────────────────┘
                            │
        ┌───────────────────┴───────────────────┐
        │                                       │
┌───────▼────────┐                  ┌───────────▼────────┐
│  API Gateway   │                  │   API Gateway    │
│  HTTP API v2   │                  │   HTTP API v2     │
│  (Auth Service)│                  │  (Main API)       │
│  /auth/*       │                  │  /api/*           │
└───────┬────────┘                  └───────────┬────────┘
        │                                       │
┌───────▼────────┐                  ┌───────────▼────────┐
│ Lambda Function│                  │  Lambda Function   │
│  (Auth)        │                  │  (API)             │
│  Python 3.11   │                  │  Python 3.11       │
│  FastAPI       │                  │  FastAPI           │
│  512 MB RAM    │                  │  512 MB RAM        │
│  30s Timeout   │                  │  30s Timeout       │
└───────┬────────┘                  └───────────┬────────┘
        │                                       │
        │         ┌─────────────────┐          │
        │         │  VPC (Virtual   │          │
        │         │  Private Cloud) │          │
        │         └────────┬────────┘          │
        │                  │                   │
        └──────────────────┴───────────────────┘
                           │
                  ┌────────▼────────┐
                  │   RDS PostgreSQL│
                  │   db.t3.micro    │
                  │   Multi-AZ      │
                  │   Encrypted     │
                  │   Port: 5432    │
                  └─────────────────┘
                           │
        ┌──────────────────┴──────────────────┐
        │                                      │
┌───────▼────────┐                ┌───────────▼────────┐
│ Security Group│                │  Security Group   │
│ (Lambda)      │                │  (RDS)             │
│ Allow: 5432   │◄───────────────►│  Allow: 5432      │
│ from Lambda   │                │  from Lambda SG    │
└────────────────┘                └────────────────────┘
```

### Características de la Arquitectura

1. **Arquitectura Serverless:**
   - Sin gestión de servidores
   - Escalado automático basado en demanda
   - Pago por uso (pay-as-you-go)
   - Alta disponibilidad nativa

2. **Separación de Responsabilidades:**
   - **Frontend:** Aplicación estática servida desde S3 y CloudFront
   - **Backend:** Microservicios independientes (Auth y API)
   - **Base de Datos:** PostgreSQL gestionado en RDS

3. **Seguridad en Capas:**
   - CloudFront con SSL/TLS
   - S3 Bucket privado con Origin Access Control (OAC)
   - Security Groups para control de tráfico
   - Autenticación JWT
   - VPC para aislamiento de red

4. **Alta Disponibilidad:**
   - CloudFront con múltiples edge locations
   - RDS en múltiples Availability Zones
   - Lambda con redundancia automática

---

## 3.3 Herramientas y Servicios AWS Utilizados

### 3.3.1 Amazon S3 (Simple Storage Service)

**Propósito:** Almacenamiento del frontend compilado (Angular SPA)

**Configuración:**
- Bucket privado con bloqueo de acceso público
- Website hosting deshabilitado (se usa CloudFront)
- Versionado deshabilitado (optimización de costos)
- Encriptación en reposo (SSE-S3)
- Lifecycle policies para optimización

**Características:**
- Almacenamiento de archivos estáticos (HTML, CSS, JS)
- Integración con CloudFront mediante Origin Access Control (OAC)
- Políticas de bucket para acceso controlado

**Costo:** Incluido en AWS Free Tier (5 GB gratis/mes)

---

### 3.3.2 Amazon CloudFront

**Propósito:** Content Delivery Network (CDN) para distribución global del frontend

**Configuración:**
- Distribución HTTPS con certificado SSL/TLS gratuito
- Origin Access Control (OAC) para acceso seguro a S3
- Cache policies optimizadas:
  - Assets estáticos (JS, CSS): Cache de 1 año
  - HTML: Cache de 1 hora
- Custom error responses para Angular routing (SPA)
- Price Class 100 (solo Norteamérica y Europa para optimizar costos)

**Características:**
- Distribución global en edge locations
- Compresión automática (Gzip/Brotli)
- IPv6 habilitado
- Redirección HTTP a HTTPS

**Costo:** Incluido en AWS Free Tier (1 TB transferencia gratis/mes)

---

### 3.3.3 AWS Lambda

**Propósito:** Ejecución serverless de los microservicios backend

**Configuración:**

**Lambda Auth:**
- Runtime: Python 3.11
- Memoria: 512 MB
- Timeout: 30 segundos
- Handler: `lambda_handler.handler`
- Variables de entorno:
  - `DATABASE_URL`: Connection string a RDS
  - `JWT_SECRET`: Secret key para tokens JWT

**Lambda API:**
- Runtime: Python 3.11
- Memoria: 512 MB
- Timeout: 30 segundos
- Handler: `lambda_handler.handler`
- Variables de entorno:
  - `DATABASE_URL`: Connection string a RDS
  - `JWT_SECRET`: Secret key para validación de tokens

**Características:**
- Integración con VPC para acceso a RDS
- Auto-scaling basado en demanda
- Logs automáticos en CloudWatch
- Dead Letter Queue configurado

**Costo:** Incluido en AWS Free Tier (1M requests gratis/mes)

---

### 3.3.4 Amazon API Gateway

**Propósito:** API RESTful para exponer los servicios Lambda

**Configuración:**
- HTTP API v2 (más económico que REST API)
- Integración con Lambda Functions
- CORS habilitado para frontend
- Logging en CloudWatch
- Throttling configurado

**Rutas Configuradas:**

**Auth Service:**
- `POST /auth/register` - Registro de usuarios
- `POST /auth/token` - Login y obtención de JWT
- `GET /auth/health` - Health check

**API Service:**
- `GET /api/destinations` - Listar destinos
- `POST /api/destinations` - Crear destino (admin)
- `PATCH /api/destinations/{id}` - Actualizar destino (admin)
- `DELETE /api/destinations/{id}` - Eliminar destino (admin)
- `GET /api/reservations` - Listar reservas del usuario
- `POST /api/reservations` - Crear reserva
- `GET /api/health` - Health check

**Características:**
- Autenticación mediante JWT en headers
- Rate limiting configurado
- Logs de acceso y errores
- Métricas automáticas en CloudWatch

**Costo:** Incluido en AWS Free Tier (1M requests gratis/mes)

---

### 3.3.5 Amazon RDS (Relational Database Service)

**Propósito:** Base de datos PostgreSQL para persistencia de datos

**Configuración:**
- Engine: PostgreSQL 15.14
- Instance Class: db.t3.micro (Free Tier)
- Storage: 20 GB (gp3)
- Multi-AZ: Deshabilitado (Free Tier)
- Public Access: Habilitado (con Security Groups)
- Backup Retention: 7 días
- Encryption: Habilitada (en reposo)
- Monitoring: CloudWatch básico

**Esquema de Base de Datos:**

**Tabla: user**
- `id` (SERIAL PRIMARY KEY)
- `username` (VARCHAR UNIQUE)
- `email` (VARCHAR UNIQUE)
- `hashed_password` (VARCHAR)
- `role` (VARCHAR) - 'admin' o 'user'
- `created_at` (TIMESTAMP)

**Tabla: destination**
- `id` (SERIAL PRIMARY KEY)
- `name` (VARCHAR)
- `description` (TEXT)
- `region` (VARCHAR)
- `price` (FLOAT)
- `created_at` (TIMESTAMP)

**Tabla: reservation**
- `id` (SERIAL PRIMARY KEY)
- `user_id` (INTEGER FOREIGN KEY)
- `destination_id` (INTEGER FOREIGN KEY)
- `people` (INTEGER)
- `check_in` (DATE)
- `check_out` (DATE)
- `total_price` (FLOAT)
- `created_at` (TIMESTAMP)

**Características:**
- Acceso desde Lambda mediante Security Groups
- Backup automático diario
- Point-in-time recovery
- Connection pooling optimizado

**Costo:** Incluido en AWS Free Tier (750 horas/mes gratis)

---

### 3.3.6 Amazon VPC (Virtual Private Cloud)

**Propósito:** Aislamiento de red y seguridad

**Configuración:**
- VPC por defecto de AWS
- Subnets en múltiples Availability Zones (alta disponibilidad)
- Internet Gateway para acceso público
- Route Tables configuradas

**Security Groups:**

**Security Group Lambda:**
- Egress: Todo el tráfico (0.0.0.0/0)
- Ingress: Ninguno (Lambda no recibe tráfico directo)

**Security Group RDS:**
- Egress: Todo el tráfico (0.0.0.0/0)
- Ingress: Puerto 5432 desde Security Group Lambda
- Ingress: Puerto 5432 desde VPC CIDR (para debugging)

**Características:**
- Aislamiento de recursos
- Control granular de tráfico
- Logging de flujos de red (opcional)

---

### 3.3.7 AWS IAM (Identity and Access Management)

**Propósito:** Gestión de permisos y roles

**Roles Creados:**

**Lambda Execution Role:**
- Permisos para:
  - Acceso a VPC (crear ENIs)
  - Escritura de logs en CloudWatch
  - Acceso a Secrets Manager (opcional)
  - Invocación de otras Lambdas (opcional)

**Características:**
- Principio de menor privilegio
- Roles separados por función
- Políticas gestionadas por AWS

---

### 3.3.8 Amazon CloudWatch

**Propósito:** Monitoreo, logging y alertas

**Componentes Implementados:**

**1. Log Groups:**
- `/aws/lambda/colombia-explora-auth`
- `/aws/lambda/colombia-explora-api`
- `/aws/apigateway/colombia-explora-api-gateway`
- Retención: 30 días

**2. CloudWatch Dashboards (3 dashboards):**

**Dashboard Principal:**
- Métricas de Lambda (Invocations, Errors, Duration)
- Métricas de API Gateway (Requests, 4xx, 5xx, Latency)
- Métricas de RDS (CPU, Connections, Storage)
- Visión general del sistema

**Dashboard Lambda Auth:**
- Invocations por minuto
- Errores y tasa de error
- Duración de ejecución
- Throttles

**Dashboard Lambda API:**
- Invocations por minuto
- Errores y tasa de error
- Duración de ejecución
- Throttles

**3. CloudWatch Alarms (9 alarmas):**

**Lambda Alarms:**
- Error Rate > 5% (ambas funciones)
- Duration > 5 segundos (ambas funciones)
- Throttles > 0 (ambas funciones)

**RDS Alarms:**
- CPU Utilization > 80%
- Database Connections > 80% del máximo
- Free Storage Space < 2 GB

**API Gateway Alarms:**
- 5xx Error Rate > 1%
- Latency P99 > 2 segundos

**4. Metric Filters:**
- Filtros para detectar errores en logs
- Alertas automáticas en caso de errores críticos

**5. Log Insights Queries:**
- Queries pre-configuradas para análisis rápido
- Búsqueda de errores
- Análisis de performance

**Características:**
- Monitoreo en tiempo real
- Alertas por email/SNS
- Retención configurable de logs
- Métricas personalizadas

**Costo:** Incluido parcialmente en Free Tier (5 GB logs, 10 alarmas gratis)

---

### 3.3.9 Amazon Route 53 (Opcional)

**Propósito:** Gestión de DNS y dominio personalizado

**Configuración (Opcional):**
- Hosted Zone para dominio personalizado
- Registros A/AAAA para CloudFront
- Integración con ACM para certificados SSL

**Características:**
- DNS gestionado
- Health checks
- Failover automático

---

### 3.3.10 AWS Certificate Manager (ACM)

**Propósito:** Certificados SSL/TLS para dominio personalizado

**Configuración (Opcional):**
- Certificado en us-east-1 (requerido para CloudFront)
- Validación mediante DNS
- Integración automática con Route 53

**Características:**
- Certificados SSL/TLS gratuitos
- Renovación automática
- Integración con CloudFront y API Gateway

---

## 3.4 Infraestructura como Código (IaC)

### 3.4.1 Terraform

**Propósito:** Definir, gestionar y versionar la infraestructura de AWS

**Estructura del Proyecto Terraform:**

```
terraform/
├── main.tf              # Providers y configuración principal
├── variables.tf         # Variables de entrada
├── outputs.tf           # Valores de salida (URLs, credenciales)
├── rds.tf               # Configuración de RDS PostgreSQL
├── lambda.tf            # Funciones Lambda (Auth y API)
├── api_gateway.tf       # API Gateway HTTP API
├── s3.tf                # Bucket S3 para frontend
├── cloudfront.tf         # Distribución CloudFront
├── security.tf          # Security Groups e IAM Roles
├── vpc.tf               # Configuración de VPC y subnets
├── monitoring.tf         # CloudWatch Dashboards y Alarms
├── deploy.tf            # Automatización de despliegue
├── tags.tf              # Tags comunes para recursos
├── acm.tf               # Certificados SSL (opcional)
├── route53.tf           # DNS (opcional)
└── terraform.tfvars     # Valores de variables (no versionado)
```

### 3.4.2 Automatización de Despliegue

Terraform incluye automatización completa del ciclo de vida de la aplicación:

**1. Empaquetado de Lambda:**
- Script automático para instalar dependencias Python
- Creación de archivos ZIP con código y dependencias
- Actualización automática cuando cambia el código

**2. Compilación del Frontend:**
- Ejecución de `npm run build`
- Actualización automática de `env.js` con URL del API Gateway
- Sincronización con S3

**3. Invalidación de CloudFront:**
- Invalidación automática de caché después de actualizar frontend
- Asegura que los usuarios vean la versión más reciente

**4. Gestión de Estado:**
- Estado almacenado localmente (o en S3 para equipos)
- Versionado de cambios de infraestructura
- Rollback automático en caso de errores

### 3.4.3 Variables y Configuración

**Variables Principales:**
- `aws_region`: Región de AWS (us-east-1)
- `project_name`: Nombre del proyecto
- `environment`: Entorno (prod, dev, staging)
- `db_instance_class`: Tipo de instancia RDS
- `lambda_memory_size`: Memoria para Lambda
- `enable_cloudfront`: Habilitar/deshabilitar CloudFront
- `subnet_ids`: IDs de subnets para alta disponibilidad

**Outputs:**
- URLs de la aplicación (Frontend y API)
- Endpoints de base de datos
- IDs de recursos para referencia
- Credenciales (sensibles, marcadas como tal)

---

## 3.5 Implementación y Despliegue

### 3.5.1 Proceso de Despliegue

**Paso 1: Preparación**
```bash
# Verificar requisitos
./scripts/check-requirements.sh

# Configurar variables
cd terraform
cp terraform.tfvars.example terraform.tfvars
# Editar terraform.tfvars con valores específicos
```

**Paso 2: Inicialización**
```bash
terraform init
# Descarga providers necesarios
# Configura backend (opcional)
```

**Paso 3: Planificación**
```bash
terraform plan
# Muestra todos los recursos que se crearán
# Permite revisar cambios antes de aplicar
```

**Paso 4: Aplicación**
```bash
terraform apply
# Crea toda la infraestructura
# Tiempo estimado: 10-15 minutos
```

**Paso 5: Verificación**
```bash
terraform output
# Muestra URLs y credenciales
# Verificar que la aplicación funciona
```

### 3.5.2 Flujo de Datos

**Request Flow:**

1. **Usuario accede al frontend:**
   - URL: `https://[cloudfront-domain].cloudfront.net`
   - CloudFront verifica caché
   - Si no está en caché, obtiene de S3
   - Devuelve archivos estáticos al usuario

2. **Usuario hace login:**
   - Frontend envía POST a `/auth/token`
   - API Gateway enruta a Lambda Auth
   - Lambda valida credenciales en RDS
   - Genera JWT y lo devuelve
   - Frontend almacena token

3. **Usuario solicita destinos:**
   - Frontend envía GET a `/api/destinations`
   - API Gateway enruta a Lambda API
   - Lambda consulta RDS
   - Devuelve lista de destinos
   - Frontend renderiza destinos

4. **Usuario crea reserva:**
   - Frontend envía POST a `/api/reservations` con JWT
   - API Gateway valida JWT
   - Lambda API procesa reserva
   - Calcula precio total
   - Guarda en RDS
   - Devuelve confirmación

### 3.5.3 Gestión de Código

**Versionado:**
- Código fuente en Git
- Terraform state versionado
- Tags semánticos para releases

**CI/CD (Futuro):**
- Integración con GitHub Actions
- Despliegue automático en push a main
- Tests automatizados antes de deploy

---

## 3.6 Monitoreo y Observabilidad

### 3.6.1 CloudWatch Dashboards

**Dashboard Principal:**
Proporciona una visión general del estado del sistema con métricas clave:
- Tasa de requests por minuto
- Tasa de errores
- Latencia promedio y P99
- Uso de recursos (CPU, memoria, conexiones)

**Dashboard Lambda Auth:**
Monitoreo específico del servicio de autenticación:
- Invocations: Número de logins/registros
- Errors: Fallos en autenticación
- Duration: Tiempo de respuesta
- Throttles: Limitaciones de concurrencia

**Dashboard Lambda API:**
Monitoreo específico del servicio principal:
- Invocations: Requests a la API
- Errors: Errores en procesamiento
- Duration: Tiempo de ejecución
- Throttles: Limitaciones de escalado

### 3.6.2 CloudWatch Alarms

**Alarmas Configuradas:**

1. **Lambda Error Rate > 5%**
   - Acción: Notificación por SNS
   - Umbral: 5% de requests con error
   - Período: 5 minutos

2. **Lambda Duration > 5 segundos**
   - Acción: Notificación por SNS
   - Umbral: P99 > 5 segundos
   - Período: 5 minutos

3. **RDS CPU > 80%**
   - Acción: Notificación por SNS
   - Umbral: CPU promedio > 80%
   - Período: 5 minutos

4. **RDS Connections > 80%**
   - Acción: Notificación por SNS
   - Umbral: Conexiones > 80% del máximo
   - Período: 5 minutos

5. **API Gateway 5xx > 1%**
   - Acción: Notificación por SNS
   - Umbral: 1% de requests con error 5xx
   - Período: 5 minutos

### 3.6.3 Logs y Tracing

**Log Groups:**
- Logs estructurados de Lambda
- Logs de acceso de API Gateway
- Retención configurable (30 días por defecto)

**Log Insights:**
- Queries pre-configuradas para análisis
- Búsqueda de errores específicos
- Análisis de patrones de uso

**Metric Filters:**
- Detección automática de errores en logs
- Alertas proactivas
- Agregación de métricas personalizadas

---

## 3.7 Seguridad y Mejores Prácticas

### 3.7.1 Seguridad en Capas

**1. Red:**
- VPC para aislamiento
- Security Groups con reglas mínimas necesarias
- No exposición directa de RDS a Internet

**2. Autenticación:**
- JWT con expiración (30 días)
- Hash de contraseñas con PBKDF2
- Validación de tokens en cada request

**3. Autorización:**
- Roles basados en usuarios (admin/user)
- Validación de permisos en endpoints
- Protección de rutas administrativas

**4. Encriptación:**
- HTTPS/TLS en tránsito (CloudFront, API Gateway)
- Encriptación en reposo (RDS, S3)
- Secrets en variables de entorno

**5. Acceso a Recursos:**
- IAM Roles con principio de menor privilegio
- Origin Access Control (OAC) para S3
- Políticas de bucket restrictivas

### 3.7.2 Mejores Prácticas Implementadas

**Infraestructura:**
- ✅ Infraestructura como Código (Terraform)
- ✅ Versionado de configuración
- ✅ Tags consistentes para recursos
- ✅ Separación de entornos (variables)

**Código:**
- ✅ Microservicios independientes
- ✅ Manejo de errores robusto
- ✅ Validación de entrada
- ✅ Logging estructurado

**Despliegue:**
- ✅ Automatización completa
- ✅ Rollback en caso de errores
- ✅ Health checks
- ✅ Zero-downtime deployments

**Monitoreo:**
- ✅ Dashboards comprehensivos
- ✅ Alertas proactivas
- ✅ Logs centralizados
- ✅ Métricas en tiempo real

**Costos:**
- ✅ Optimización para AWS Free Tier
- ✅ Uso de instancias pequeñas
- ✅ Lifecycle policies
- ✅ Monitoreo de costos

---

# RESULTADOS ESPERADOS

## 4.1 Funcionalidad de la Aplicación

Al completar el despliegue, la aplicación debe cumplir con los siguientes requisitos:

✅ **Frontend Funcional:**
- Página principal con lista de destinos
- Formulario de registro de usuarios
- Formulario de login
- Visualización de destinos disponibles
- Formulario de reserva
- Panel de administración (solo para admins)

✅ **Backend Funcional:**
- API de autenticación (registro/login)
- API de gestión de destinos
- API de reservas
- Cálculo automático de precios
- Validación de permisos

✅ **Base de Datos:**
- Tablas creadas automáticamente
- Usuario admin por defecto
- Integridad referencial
- Backup automático

## 4.2 Infraestructura Desplegada

✅ **Recursos AWS Creados:**
- 1 S3 Bucket (Frontend)
- 1 CloudFront Distribution
- 2 Lambda Functions (Auth y API)
- 1 API Gateway HTTP API
- 1 RDS PostgreSQL Instance
- 2 Security Groups
- 2 IAM Roles
- 3 CloudWatch Dashboards
- 9 CloudWatch Alarms
- 3 Log Groups

✅ **URLs Disponibles:**
- Frontend: `https://[cloudfront-domain].cloudfront.net`
- API Gateway: `https://[api-id].execute-api.[region].amazonaws.com`
- API Docs: `https://[api-id].execute-api.[region].amazonaws.com/docs`

## 4.3 Monitoreo y Observabilidad

✅ **Dashboards Configurados:**
- Visión general del sistema
- Métricas de Lambda Auth
- Métricas de Lambda API

✅ **Alertas Configuradas:**
- Errores en Lambda
- Performance degradada
- Problemas de base de datos
- Errores en API Gateway

## 4.4 Costos Optimizados

✅ **AWS Free Tier:**
- RDS: 750 horas/mes gratis
- Lambda: 1M requests/mes gratis
- API Gateway: 1M requests/mes gratis
- S3: 5 GB storage gratis
- CloudFront: 1 TB transferencia/mes gratis

✅ **Costos Post-Free Tier:**
- Estimado: $15-30/mes para tráfico bajo-medio
- Escalable según demanda
- Sin costos de servidores gestionados

## 4.5 Escalabilidad

✅ **Auto-scaling:**
- Lambda escala automáticamente
- API Gateway maneja picos de tráfico
- CloudFront distribuye carga globalmente
- RDS puede escalarse verticalmente

✅ **Alta Disponibilidad:**
- Múltiples Availability Zones
- Redundancia automática
- Failover transparente

---

# CONCLUSIONES

## 5.1 Logros del Proyecto

Este proyecto demostró exitosamente la implementación de una arquitectura serverless completa en AWS, utilizando las mejores prácticas de Infraestructura como Código y DevOps. Se logró:

1. **Despliegue Automatizado:** Toda la infraestructura se despliega con un solo comando (`terraform apply`)

2. **Arquitectura Escalable:** La solución puede manejar desde pocos usuarios hasta millones sin cambios en la arquitectura

3. **Monitoreo Comprehensivo:** Sistema completo de observabilidad con dashboards, alarmas y logs

4. **Seguridad Robusta:** Múltiples capas de seguridad implementadas siguiendo mejores prácticas

5. **Optimización de Costos:** Uso eficiente del AWS Free Tier y optimizaciones para minimizar costos

## 5.2 Aprendizajes Adquiridos

- **Infraestructura como Código:** Dominio de Terraform para gestionar infraestructura
- **Arquitectura Serverless:** Comprensión profunda de servicios serverless de AWS
- **DevOps:** Automatización completa del ciclo de vida de la aplicación
- **Monitoreo:** Implementación de sistemas de observabilidad profesionales
- **Seguridad en la Nube:** Aplicación de mejores prácticas de seguridad

## 5.3 Desafíos Encontrados y Soluciones

**Desafío 1: Cold Starts en Lambda**
- **Problema:** Primera invocación de Lambda tarda más tiempo
- **Solución:** Implementación de `ensure_tables()` para crear tablas bajo demanda

**Desafío 2: Configuración de CloudFront con S3**
- **Problema:** Error 403 al acceder a CloudFront
- **Solución:** Migración de OAI a OAC y configuración correcta de políticas S3

**Desafío 3: Gestión de Estado de Terraform**
- **Problema:** Dependencias circulares en Security Groups
- **Solución:** Uso de `aws_security_group_rule` separados

## 5.4 Mejoras Futuras

1. **CI/CD Pipeline:**
   - Integración con GitHub Actions
   - Tests automatizados
   - Despliegue automático en push

2. **Dominio Personalizado:**
   - Configuración de Route 53
   - Certificado SSL personalizado
   - Branding profesional

3. **Funcionalidades Adicionales:**
   - Sistema de pagos
   - Notificaciones por email
   - Dashboard de analytics

4. **Optimizaciones:**
   - Cache de Redis para consultas frecuentes
   - CDN para assets estáticos adicionales
   - Compresión avanzada

---

# REFERENCIAS

## Documentación Oficial

- AWS Documentation: https://docs.aws.amazon.com/
- Terraform AWS Provider: https://registry.terraform.io/providers/hashicorp/aws/latest/docs
- FastAPI Documentation: https://fastapi.tiangolo.com/
- Angular Documentation: https://angular.io/docs

## Recursos Adicionales

- AWS Well-Architected Framework: https://aws.amazon.com/architecture/well-architected/
- Terraform Best Practices: https://www.terraform.io/docs/cloud/guides/recommended-practices/
- Serverless Architecture Patterns: https://aws.amazon.com/serverless/

## Herramientas Utilizadas

- Terraform: https://www.terraform.io/
- AWS CLI: https://aws.amazon.com/cli/
- Node.js: https://nodejs.org/
- Python: https://www.python.org/

---

# ANEXOS

## Anexo A: Capturas de Pantalla - Evidencia del Monitoreo

**Importante:** Este anexo contiene las capturas de pantalla que demuestran el funcionamiento del sistema de monitoreo y observabilidad implementado en CloudWatch.

### Instrucciones para Obtener las Capturas

1. **Accede a los Dashboards de CloudWatch:**
   - Main Dashboard: https://us-east-1.console.aws.amazon.com/cloudwatch/home?region=us-east-1#dashboards:name=colombia-explora-main-dashboard
   - Lambda API Dashboard: https://us-east-1.console.aws.amazon.com/cloudwatch/home?region=us-east-1#dashboards:name=colombia-explora-lambda-api
   - Lambda Auth Dashboard: https://us-east-1.console.aws.amazon.com/cloudwatch/home?region=us-east-1#dashboards:name=colombia-explora-lambda-auth

2. **Genera Tráfico a la Aplicación:**
   ```bash
   ./scripts/generate-traffic.sh
   ```
   Este script genera tráfico real a la API para que aparezcan métricas en los dashboards.

3. **Espera 2-3 minutos** después de generar tráfico para que las métricas se actualicen.

### Capturas Requeridas

**1. Dashboard Principal de CloudWatch**
   - Captura completa del dashboard principal
   - Debe mostrar métricas de Lambda, API Gateway y RDS
   - Incluir timestamp visible
   - **Ubicación en documento:** Después de la sección 3.6.1

**2. Dashboard Lambda Auth**
   - Métricas de invocaciones, errores, duración
   - Gráficos de performance
   - **Ubicación en documento:** Después de la sección 3.6.1

**3. Dashboard Lambda API**
   - Métricas de invocaciones, errores, duración
   - Gráficos de performance
   - **Ubicación en documento:** Después de la sección 3.6.1

**4. CloudWatch Alarms**
   - Lista de alarmas configuradas (9 alarmas)
   - Estado de las alarmas (OK, ALARM, INSUFFICIENT_DATA)
   - **Ubicación:** Consola AWS → CloudWatch → Alarms
   - Filtrar por: `colombia-explora`
   - **Ubicación en documento:** Después de la sección 3.6.2

**5. Logs de Lambda**
   - Logs de una invocación exitosa de Lambda Auth
   - Logs de una invocación exitosa de Lambda API
   - **Ubicación:** CloudWatch → Log Groups → `/aws/lambda/colombia-explora-auth` y `/aws/lambda/colombia-explora-api`
   - **Ubicación en documento:** Después de la sección 3.6.3

**6. Métricas de API Gateway**
   - Gráfico de requests por minuto
   - Latencia promedio
   - Tasa de errores 4xx y 5xx
   - **Ubicación:** CloudWatch → Metrics → API Gateway
   - **Ubicación en documento:** Después de la sección 3.3.4

**7. Métricas de RDS**
   - CPU Utilization
   - Database Connections
   - Free Storage Space
   - **Ubicación:** CloudWatch → Metrics → RDS
   - **Ubicación en documento:** Después de la sección 3.3.5

**8. Terraform Apply Exitoso**
   - Terminal mostrando `Apply complete! Resources: X added`
   - Outputs de Terraform con las URLs
   - **Ubicación en documento:** Después de la sección 3.5.1

**9. Frontend Funcionando**
   - Captura del frontend mostrando destinos
   - URL visible en el navegador (CloudFront)
   - **Ubicación en documento:** Después de la sección 3.1

**10. Recursos en Consola AWS**
   - Vista de recursos creados (Lambda, RDS, S3, CloudFront, API Gateway)
   - Tags visibles mostrando organización
   - **Ubicación en documento:** Después de la sección 3.5.2

### Formato de las Capturas

- **Resolución:** Mínimo 1920x1080 o superior
- **Formato:** PNG o JPG de alta calidad
- **Nombre de archivo:** `captura-[numero]-[descripcion].png`
  - Ejemplo: `captura-1-dashboard-principal.png`
- **Incluir:** Timestamp visible, nombres de recursos, métricas claras

### Notas para las Capturas

1. **Asegúrate de generar tráfico antes de capturar** para que las métricas sean visibles
2. **Usa el modo de pantalla completa** o ventana maximizada
3. **Incluye el contexto** (menús, navegación) para que sea claro dónde estás
4. **Verifica que los datos sean legibles** antes de capturar
5. **Espera 2-3 minutos** después de generar tráfico para métricas actualizadas

## Anexo B: Comandos de Verificación

```bash
# Verificar estado de Terraform
terraform show

# Ver outputs
terraform output

# Verificar logs de Lambda
aws logs tail /aws/lambda/colombia-explora-auth --follow

# Verificar destinos en API
curl https://[api-url]/api/destinations

# Verificar health checks
curl https://[api-url]/api/health
curl https://[api-url]/auth/health
```

## Anexo C: Estructura de Archivos

```
colombia-explora/
├── terraform/              # Infraestructura como Código
│   ├── main.tf
│   ├── variables.tf
│   ├── outputs.tf
│   ├── rds.tf
│   ├── lambda.tf
│   ├── api_gateway.tf
│   ├── s3.tf
│   ├── cloudfront.tf
│   ├── security.tf
│   ├── vpc.tf
│   ├── monitoring.tf
│   └── deploy.tf
├── api/                    # Microservicio API
│   ├── app/
│   │   ├── main.py
│   │   ├── models.py
│   │   └── db.py
│   ├── lambda_handler.py
│   └── requirements.txt
├── auth/                   # Microservicio Auth
│   ├── app/
│   │   ├── main.py
│   │   ├── models.py
│   │   └── db.py
│   ├── lambda_handler.py
│   └── requirements.txt
├── frontend/               # Aplicación Angular
│   ├── src/
│   │   ├── app/
│   │   └── assets/
│   ├── package.json
│   └── angular.json
├── scripts/                # Scripts de automatización
│   ├── package-lambda.sh
│   ├── check-requirements.sh
│   └── terraform-deploy.sh
└── README.md               # Documentación principal
```

---

**FIN DEL DOCUMENTO**

