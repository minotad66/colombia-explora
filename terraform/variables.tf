variable "aws_region" {
  description = "AWS region donde se desplegarán los recursos"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Entorno de despliegue (dev, staging, prod)"
  type        = string
  default     = "prod"
}

variable "project_name" {
  description = "Nombre del proyecto (usado para naming de recursos)"
  type        = string
  default     = "colombia-explora"
}

# RDS Variables
variable "db_instance_class" {
  description = "Clase de instancia RDS"
  type        = string
  default     = "db.t3.micro" # Free tier compatible
}

variable "db_allocated_storage" {
  description = "Storage asignado a RDS (GB)"
  type        = number
  default     = 20
}

variable "db_name" {
  description = "Nombre de la base de datos"
  type        = string
  default     = "colombiaexplora"
}

variable "db_username" {
  description = "Usuario master de RDS"
  type        = string
  default     = "explora_admin"
  sensitive   = true
}

variable "db_password" {
  description = "Password de RDS (si no se proporciona, se genera automáticamente)"
  type        = string
  default     = ""
  sensitive   = true
}

variable "db_port" {
  description = "Puerto de PostgreSQL"
  type        = number
  default     = 5432
}

variable "db_backup_retention_period" {
  description = "Días de retención de backups (0 para free tier)"
  type        = number
  default     = 7
}

variable "db_publicly_accessible" {
  description = "Si RDS debe ser accesible públicamente"
  type        = bool
  default     = true
}

# Lambda Variables
variable "lambda_runtime" {
  description = "Runtime de Python para Lambda"
  type        = string
  default     = "python3.11"
}

variable "lambda_memory_size" {
  description = "Memoria asignada a Lambda (MB)"
  type        = number
  default     = 512
}

variable "lambda_timeout" {
  description = "Timeout de Lambda (segundos)"
  type        = number
  default     = 30
}

variable "jwt_secret" {
  description = "Secret key para JWT (si no se proporciona, se genera automáticamente)"
  type        = string
  default     = ""
  sensitive   = true
}

# S3 Variables
variable "frontend_bucket_name" {
  description = "Nombre del bucket S3 para el frontend (debe ser único globalmente)"
  type        = string
  default     = ""
}

variable "enable_cloudfront" {
  description = "Habilitar CloudFront distribution"
  type        = bool
  default     = true
}

variable "cloudfront_price_class" {
  description = "Price class de CloudFront (PriceClass_100, PriceClass_200, PriceClass_All)"
  type        = string
  default     = "PriceClass_100" # Solo US, Canada, Europe (más barato)
}

variable "custom_domain" {
  description = "Dominio personalizado completo para CloudFront (ej: colombia-explora.frontend.com)"
  type        = string
  default     = ""
}

variable "route53_hosted_zone_id" {
  description = "ID del hosted zone de Route 53 (si no se proporciona y hay custom_domain, se buscará por nombre)"
  type        = string
  default     = ""
}

variable "route53_hosted_zone_name" {
  description = "Nombre del dominio para buscar el hosted zone (ej: frontend.com.) - debe terminar en punto"
  type        = string
  default     = ""
}

variable "create_route53_record" {
  description = "Crear registro A en Route 53 para el dominio personalizado"
  type        = bool
  default     = true
}

variable "use_cname_instead_of_alias" {
  description = "Usar CNAME en lugar de A alias (útil para subdominios sin certificado SSL)"
  type        = bool
  default     = false
}

# VPC Variables
variable "vpc_id" {
  description = "ID de la VPC (si no se proporciona, se usa default)"
  type        = string
  default     = ""
}

variable "subnet_ids" {
  description = "IDs de subnets para Lambda y RDS (si no se proporcionan, se detectan automáticamente)"
  type        = list(string)
  default     = []
}

# Tags
variable "additional_tags" {
  description = "Tags adicionales para los recursos"
  type        = map(string)
  default     = {}
}

# Monitoring
variable "enable_detailed_monitoring" {
  description = "Habilitar monitoreo detallado (tiene costo adicional)"
  type        = bool
  default     = false  # Free tier: false
}

variable "log_retention_days" {
  description = "Días de retención de logs en CloudWatch"
  type        = number
  default     = 30  # Free tier: 5GB, 30 días es razonable
}

variable "enable_cloudwatch_alarms" {
  description = "Habilitar CloudWatch Alarms"
  type        = bool
  default     = true
}

variable "auto_setup_iam_permissions" {
  description = "Intentar crear y adjuntar automáticamente los permisos IAM necesarios al usuario actual"
  type        = bool
  default     = true
}

