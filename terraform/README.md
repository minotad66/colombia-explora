# 🏗️ Terraform - Colombia Explora

Infraestructura como Código (IaC) para desplegar Colombia Explora en AWS usando Terraform.

---

## 📋 Tabla de Contenidos

- [Requisitos](#requisitos)
- [Instalación](#instalación)
- [Configuración](#configuración)
- [Uso](#uso)
- [Estructura](#estructura)
- [Variables](#variables)
- [Outputs](#outputs)
- [Troubleshooting](#troubleshooting)

---

## ✅ Requisitos

### 1. Terraform
```bash
# Instalar Terraform (macOS)
brew install terraform

# Instalar Terraform (Linux)
wget https://releases.hashicorp.com/terraform/1.6.0/terraform_1.6.0_linux_amd64.zip
unzip terraform_1.6.0_linux_amd64.zip
sudo mv terraform /usr/local/bin/

# Verificar instalación
terraform version
```

### 2. AWS CLI
```bash
# Instalar AWS CLI
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install

# Configurar credenciales
aws configure
```

### 3. Credenciales AWS
- AWS Access Key ID
- AWS Secret Access Key
- Permisos IAM para: RDS, Lambda, API Gateway, S3, CloudFront, VPC, IAM

---

## 🚀 Instalación

### 1. Preparar el Proyecto

```bash
# Desde la raíz del proyecto
cd terraform

# Inicializar Terraform
terraform init
```

### 2. (Opcional) Pre-empacar Lambda Functions

Si prefieres empaquetar antes de `terraform apply`:

```bash
# Desde la raíz del proyecto
./scripts/package-lambda.sh
```

**Nota:** Terraform lo hará automáticamente si no existen los ZIPs.

---

## ⚙️ Configuración

### 1. Copiar Archivo de Variables

```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars
```

### 2. Editar Variables

Edita `terraform.tfvars` con tus valores:

```hcl
aws_region = "us-east-1"
environment = "prod"
project_name = "colombia-explora"

# RDS
db_instance_class = "db.t3.micro"
db_allocated_storage = 20
db_username = "explora_admin"
# db_password = "tu-password-seguro"  # Opcional, se genera automáticamente si no se proporciona

# Lambda
lambda_memory_size = 512
lambda_timeout = 30

# CloudFront
enable_cloudfront = true
```

### 3. Variables Sensibles (Opcional)

Para mayor seguridad, puedes usar variables de entorno:

```bash
export TF_VAR_db_password="tu-password-seguro"
export TF_VAR_jwt_secret="tu-jwt-secret"
```

---

## 🎯 Uso

### Plan (Ver qué se va a crear)

```bash
cd terraform
terraform plan
```

### Apply (Crear infraestructura)

```bash
terraform apply
```

Terraform mostrará un plan de ejecución. Escribe `yes` para confirmar.

**⏱️ Tiempo estimado:** 10-15 minutos (RDS tarda ~5-10 minutos)

### Ver Outputs

```bash
terraform output
```

Para ver outputs específicos:
```bash
terraform output api_gateway_url
terraform output frontend_url
terraform output database_url
```

### Destroy (Eliminar todo)

⚠️ **CUIDADO:** Esto eliminará TODOS los recursos.

```bash
terraform destroy
```

---

## 📁 Estructura

```
terraform/
├── main.tf              # Configuración principal y providers
├── variables.tf         # Definición de variables
├── outputs.tf          # Outputs del despliegue
├── rds.tf              # RDS PostgreSQL
├── lambda.tf           # Lambda Functions (Auth y API)
├── api_gateway.tf      # API Gateway HTTP API
├── s3.tf               # S3 Bucket para Frontend
├── cloudfront.tf       # CloudFront Distribution
├── security.tf         # Security Groups e IAM Roles
├── terraform.tfvars.example  # Ejemplo de variables
├── .gitignore         # Archivos a ignorar
└── README.md          # Este archivo
```

---

## 🔧 Variables

### Variables Principales

| Variable | Descripción | Default | Requerido |
|----------|-------------|---------|-----------|
| `aws_region` | Región AWS | `us-east-1` | No |
| `environment` | Entorno (dev/staging/prod) | `prod` | No |
| `project_name` | Nombre del proyecto | `colombia-explora` | No |
| `db_instance_class` | Clase de instancia RDS | `db.t3.micro` | No |
| `db_allocated_storage` | Storage RDS (GB) | `20` | No |
| `db_username` | Usuario RDS | `explora_admin` | No |
| `db_password` | Password RDS | `""` (auto-generado) | No |
| `lambda_memory_size` | Memoria Lambda (MB) | `512` | No |
| `lambda_timeout` | Timeout Lambda (seg) | `30` | No |
| `jwt_secret` | Secret para JWT | `""` (auto-generado) | No |
| `frontend_bucket_name` | Nombre bucket S3 | `""` (auto-generado) | No |
| `enable_cloudfront` | Habilitar CloudFront | `true` | No |

### Ver todas las variables:

```bash
terraform variables
```

---

## 📤 Outputs

Después de `terraform apply`, puedes ver los outputs:

```bash
# URL del API Gateway
terraform output api_gateway_url

# URL del Frontend
terraform output frontend_url

# Database URL (sensible)
terraform output -json database_url

# Instrucciones de despliegue
terraform output deployment_instructions
```

### Outputs Disponibles

- `rds_endpoint` - Endpoint de RDS
- `database_url` - Connection string completo
- `lambda_auth_function_name` - Nombre Lambda Auth
- `lambda_api_function_name` - Nombre Lambda API
- `api_gateway_url` - URL del API Gateway
- `s3_bucket_name` - Nombre del bucket S3
- `cloudfront_domain_name` - Domain de CloudFront
- `frontend_url` - URL del frontend
- `backend_url` - URL del backend
- `jwt_secret` - JWT secret generado
- `deployment_instructions` - Instrucciones post-despliegue

---

## 🔄 Workflow Completo

### 1. Primera vez (Despliegue inicial)

```bash
# 1. Preparar Lambda packages
cd ..
./scripts/package-lambda.sh

# 2. Configurar Terraform
cd terraform
cp terraform.tfvars.example terraform.tfvars
# Editar terraform.tfvars con tus valores

# 3. Inicializar
terraform init

# 4. Plan
terraform plan

# 5. Apply
terraform apply

# 6. Guardar outputs
terraform output > ../outputs.txt
```

### 2. Desplegar Frontend

```bash
# 1. Compilar frontend
cd ../frontend
npm run build -- --configuration production

# 2. Obtener bucket name
cd ../terraform
BUCKET_NAME=$(terraform output -raw s3_bucket_name)

# 3. Subir a S3
cd ../frontend
aws s3 sync dist/explora/ s3://$BUCKET_NAME --delete

# 4. Si usas CloudFront, invalidar cache
DIST_ID=$(cd ../terraform && terraform output -raw cloudfront_distribution_id)
aws cloudfront create-invalidation --distribution-id $DIST_ID --paths "/*"
```

### 3. Actualizar Lambda Functions

```bash
# 1. Re-empaquetar
cd ..
./scripts/package-lambda.sh

# 2. Obtener nombres de funciones
cd terraform
AUTH_FUNC=$(terraform output -raw lambda_auth_function_name)
API_FUNC=$(terraform output -raw lambda_api_function_name)

# 3. Actualizar código
aws lambda update-function-code \
  --function-name $AUTH_FUNC \
  --zip-file fileb://../auth/auth-lambda.zip

aws lambda update-function-code \
  --function-name $API_FUNC \
  --zip-file fileb://../api/api-lambda.zip
```

---

## 🐛 Troubleshooting

### Error: "No valid credential sources found"

**Solución:**
```bash
aws configure
# O usar variables de entorno:
export AWS_ACCESS_KEY_ID="tu-key"
export AWS_SECRET_ACCESS_KEY="tu-secret"
```

### Error: "Error creating DB Instance: InvalidParameterValue"

**Causa:** Parámetros de RDS inválidos

**Solución:**
- Verifica que `db_instance_class` sea válido
- Verifica que `db_allocated_storage` sea >= 20
- Verifica que la región soporte el tipo de instancia

### Error: "Lambda function not found" al hacer apply

**Causa:** Los archivos ZIP no existen

**Solución:**
```bash
cd ..
./scripts/package-lambda.sh
cd terraform
terraform apply
```

### Error: "Bucket name already exists"

**Causa:** El nombre del bucket S3 debe ser único globalmente

**Solución:**
- Cambia `frontend_bucket_name` en `terraform.tfvars`
- O deja vacío para que se genere automáticamente

### Error: "Security group rule already exists"

**Causa:** Regla duplicada en security group

**Solución:**
```bash
terraform refresh
terraform apply
```

### Error: "Timeout waiting for RDS"

**Causa:** RDS tarda mucho en crearse

**Solución:**
- Espera más tiempo (puede tardar 10-15 minutos)
- Verifica que no haya limitaciones en tu cuenta AWS

---

## 🔒 Seguridad

### Variables Sensibles

Nunca commits `terraform.tfvars` con valores reales:

```bash
# .gitignore ya incluye terraform.tfvars
# Usa terraform.tfvars.example como plantilla
```

### Usar AWS Secrets Manager (Opcional)

Para mayor seguridad, puedes usar AWS Secrets Manager:

```hcl
# En variables.tf
variable "secrets_manager_db_password_arn" {
  description = "ARN del secret de RDS password en Secrets Manager"
  type        = string
  default     = ""
}

# En rds.tf
data "aws_secretsmanager_secret_version" "db_password" {
  count     = var.secrets_manager_db_password_arn != "" ? 1 : 0
  secret_id = var.secrets_manager_db_password_arn
}
```

---

## 💰 Costos

### Free Tier (Primer año)
- RDS db.t3.micro: ✅ 750 horas/mes
- Lambda: ✅ 1M requests/mes
- API Gateway: ✅ 1M requests/mes
- S3: ✅ 5GB storage
- CloudFront: ✅ 50GB transfer

### Después del Free Tier
- **RDS db.t3.micro**: ~$15/mes
- **Lambda**: ~$0.20 por 1M requests
- **API Gateway**: ~$1.00 por 1M requests
- **S3**: ~$0.023/GB/mes
- **CloudFront**: ~$0.085/GB transfer

**Total estimado:** ~$20-30/mes para tráfico bajo

---

## 🚀 Despliegue Automático

Terraform ahora despliega **automáticamente** todo el código:

- ✅ **Empaqueta Lambda functions** automáticamente
- ✅ **Sube código a Lambda** automáticamente  
- ✅ **Compila el frontend** automáticamente
- ✅ **Actualiza env.js** con URL del API Gateway
- ✅ **Sube frontend a S3** automáticamente
- ✅ **Invalida cache de CloudFront** automáticamente

**Nota:** El despliegue automático está integrado en este archivo. Ver sección "Despliegue Automático" más abajo.

**Después de `terraform apply`, obtén la URL:**
```bash
terraform output application_url
```

## 📊 Monitoreo

El proyecto incluye monitoreo completo con CloudWatch:

- ✅ **3 Dashboards** (Principal, Lambda Auth, Lambda API)
- ✅ **9 CloudWatch Alarms** (Lambda, RDS, API Gateway)
- ✅ **4 Log Insights Queries** guardadas
- ✅ **Metric Filters** para errores

**Ver documentación completa:** [README-MONITORING.md](README-MONITORING.md)

**Ver URLs de dashboards:**
```bash
terraform output monitoring_dashboards
```

## 📚 Recursos Adicionales

- [Terraform AWS Provider Docs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [Terraform Language Documentation](https://www.terraform.io/docs/language/index.html)
- [AWS Well-Architected Framework](https://aws.amazon.com/architecture/well-architected/)
- [CloudWatch Monitoring](README-MONITORING.md)

---

## ✅ Checklist Pre-Despliegue

- [ ] Terraform instalado (`terraform version`)
- [ ] AWS CLI configurado (`aws configure`)
- [ ] Lambda packages creados (`./scripts/package-lambda.sh`)
- [ ] `terraform.tfvars` configurado
- [ ] `terraform init` ejecutado
- [ ] `terraform plan` revisado
- [ ] Credenciales AWS con permisos suficientes

---

## ✅ Checklist Post-Despliegue

- [ ] RDS creado y accesible
- [ ] Lambda functions creadas
- [ ] API Gateway configurado
- [ ] S3 bucket creado
- [ ] CloudFront configurado (si está habilitado)
- [ ] Frontend compilado y subido a S3
- [ ] Lambda code actualizado
- [ ] Health checks funcionando
- [ ] Frontend accesible
- [ ] Backend responde correctamente

---

**¡Felicidades! 🎉 Tu infraestructura está lista.**

*Creado para Colombia Explora* 🏔️🇨🇴

