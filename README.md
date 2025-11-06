# 🌄 Colombia Explora - Despliegue en AWS

Plataforma web moderna para reservas de destinos turísticos, desplegada en AWS con arquitectura serverless.

---

## 🚀 Despliegue Rápido en AWS

### Requisitos Previos

1. **Terraform** instalado
   ```bash
   brew install terraform  # macOS
   # o descarga desde https://www.terraform.io/downloads
   ```

2. **AWS CLI** instalado y configurado
   ```bash
   brew install awscli  # macOS
   aws configure  # Ingresa tus credenciales AWS
   ```

3. **Permisos IAM** en AWS
   - Necesitas permisos para crear: RDS, Lambda, API Gateway, S3, CloudFront, VPC, IAM
   - Si no los tienes, consulta `terraform/PERMISOS-IAM.md`

### Paso 1: Verificar Requisitos

```bash
./scripts/check-requirements.sh
```

### Paso 2: Configurar Variables

```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars
# Edita terraform.tfvars con tus valores (región, subnets, etc.)
```

### Paso 3: Desplegar

```bash
# Inicializar Terraform
terraform init

# Ver plan de despliegue
terraform plan

# Aplicar despliegue (crea toda la infraestructura)
terraform apply
```

⏱️ **Tiempo estimado:** 10-15 minutos

### Paso 4: Acceder a la Aplicación

Después del despliegue, Terraform mostrará las URLs:

```bash
# Ver todas las URLs
terraform output

# URL principal de la aplicación
terraform output application_url

# URL del API Gateway
terraform output api_gateway_url
```

### Paso 5: Verificar que Todo Funciona

1. **Abre la URL del frontend** en tu navegador
2. **Deberías ver 6 destinos de ejemplo** ya creados:
   - Valle del Cocora (Quindío)
   - Salento (Quindío)
   - Termales de Santa Rosa (Risaralda)
   - Parque Nacional Natural Los Nevados (Tolima)
   - Manizales (Caldas)
   - Pereira (Risaralda)

3. **Prueba el registro de usuario:**
   - Haz clic en "Únete Ahora" o "Registrarse"
   - Crea una cuenta nueva
   - Inicia sesión

4. **Prueba crear una reserva:**
   - Selecciona un destino
   - Haz clic en "Reservar Ahora"
   - Completa el formulario de reserva

**Usuario Admin por Defecto:**
- Username: `admin`
- Password: `admin123`
- ⚠️ **Importante:** Cambia esta contraseña en producción

---

## 📚 Documentación Completa

Para instrucciones detalladas, consulta:

- **[terraform/README.md](terraform/README.md)** - Guía completa de despliegue con Terraform
- **[terraform/PERMISOS-IAM.md](terraform/PERMISOS-IAM.md)** - Configuración de permisos IAM

---

## 🏗️ Arquitectura

```
┌─────────────────────────────────────────────────────────────┐
│                         CloudFront                           │
│                    (CDN + SSL Gratuito)                      │
└───────────────────────────┬─────────────────────────────────┘
                            │
                    ┌───────▼────────┐
                    │   S3 Bucket    │
                    │   (Frontend)   │
                    └────────────────┘
                            │
        ┌───────────────────┴───────────────────┐
        │                                       │
┌───────▼────────┐                  ┌───────────▼────────┐
│  API Gateway   │                  │   API Gateway      │
│   (Auth API)   │                  │   (Main API)       │
└───────┬────────┘                  └───────────┬────────┘
        │                                       │
┌───────▼────────┐                  ┌───────────▼────────┐
│ Lambda (Auth)  │                  │  Lambda (API)      │
└───────┬────────┘                  └───────────┬────────┘
        │                                       │
        └───────────────┬───────────────────────┘
                        │
                ┌───────▼────────┐
                │   RDS          │
                │  PostgreSQL     │
                └─────────────────┘
```

### Componentes

- **Frontend (Angular)**: Alojado en S3, servido por CloudFront
- **Backend (FastAPI)**: Lambda Functions invocadas por API Gateway
- **Base de Datos**: PostgreSQL en RDS
- **Autenticación**: JWT con servicio Auth separado

---

## 🛠️ Tecnologías

- **Frontend**: Angular 15, Bootstrap 5
- **Backend**: FastAPI, Python 3.11
- **Base de Datos**: PostgreSQL 15
- **Infraestructura**: AWS (Lambda, API Gateway, S3, CloudFront, RDS)
- **IaC**: Terraform

---

## 📋 Estructura del Proyecto

```
colombia-explora/
├── terraform/           # Infraestructura como Código
│   ├── main.tf         # Configuración principal
│   ├── variables.tf    # Variables de configuración
│   ├── outputs.tf      # URLs y credenciales
│   └── README.md        # Documentación completa
├── api/                # Microservicio API (Lambda)
├── auth/               # Microservicio Auth (Lambda)
├── frontend/           # Aplicación Angular
└── scripts/            # Scripts de utilidad
```

---

## 🔧 Comandos Útiles

### Ver Estado del Despliegue

```bash
cd terraform
terraform show
terraform output
```

### Verificar Destinos Disponibles

```bash
# Ver todos los destinos
curl https://zp9xx62mde.execute-api.us-east-1.amazonaws.com/api/destinations | python3 -m json.tool

# Deberías ver 6 destinos de ejemplo creados automáticamente
```

### Actualizar Infraestructura

```bash
cd terraform
terraform plan   # Ver cambios
terraform apply  # Aplicar cambios
```

### Eliminar Todo (⚠️ Cuidado)

```bash
cd terraform
terraform destroy
```

### Ver Logs

```bash
# Logs de Lambda Auth
aws logs tail /aws/lambda/colombia-explora-auth --follow

# Logs de Lambda API
aws logs tail /aws/lambda/colombia-explora-api --follow

# Logs de API Gateway
aws logs tail /aws/apigateway/colombia-explora-api-gateway --follow
```

---

## 💰 Costos (AWS Free Tier)

Este despliegue está optimizado para usar el AWS Free Tier:

- **RDS**: db.t3.micro (750 horas/mes gratis)
- **Lambda**: 1M requests/mes gratis
- **API Gateway**: 1M requests/mes gratis
- **S3**: 5 GB storage gratis
- **CloudFront**: 1 TB transferencia/mes gratis

Después del free tier, costos estimados: **~$15-30/mes** (según uso)

---

## 🎯 Verificación Post-Despliegue

### Verificar que los Destinos se Muestran

Si no ves destinos en el frontend, verifica:

```bash
# Verificar que el API responde
curl https://zp9xx62mde.execute-api.us-east-1.amazonaws.com/api/destinations

# Deberías ver un array con 6 destinos de ejemplo
```

Si el array está vacío, puedes crear destinos manualmente:

1. **Inicia sesión como admin** en el frontend
2. **Accede al panel de administración** (ruta `/admin`)
3. **Crea nuevos destinos** usando el formulario

O usa el API directamente:

```bash
# 1. Obtener token de admin
TOKEN=$(curl -s -X POST https://zp9xx62mde.execute-api.us-east-1.amazonaws.com/auth/token \
  -H "Content-Type: application/json" \
  -d '{"username":"admin","password":"admin123"}' \
  | python3 -c "import sys, json; print(json.load(sys.stdin)['access_token'])")

# 2. Crear un destino
curl -X POST https://zp9xx62mde.execute-api.us-east-1.amazonaws.com/api/destinations \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"name":"Mi Destino","description":"Descripción","region":"Quindío","price":100000}'
```

---

## 📞 Soporte

Si tienes problemas:

1. Verifica que AWS CLI esté configurado: `aws sts get-caller-identity`
2. Revisa los logs de CloudWatch
3. Consulta `terraform/README.md` para troubleshooting
4. Verifica permisos IAM en `terraform/PERMISOS-IAM.md`
5. Verifica que los destinos existan: `curl https://[API_URL]/api/destinations`

---

**Desarrollado por grupo 9**
