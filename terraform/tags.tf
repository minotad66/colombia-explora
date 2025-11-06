# Tags estandarizados para todos los recursos
# Mejores prácticas de tagging para AWS

locals {
  # Tags comunes para todos los recursos
  common_tags = merge(
    {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "Terraform"
      CreatedAt   = timestamp()
    },
    var.additional_tags
  )

  # Tags específicos por tipo de servicio
  lambda_tags = merge(
    local.common_tags,
    {
      ServiceType = "Lambda"
    }
  )

  rds_tags = merge(
    local.common_tags,
    {
      ServiceType = "RDS"
      Database    = "PostgreSQL"
    }
  )

  api_gateway_tags = merge(
    local.common_tags,
    {
      ServiceType = "API Gateway"
    }
  )

  s3_tags = merge(
    local.common_tags,
    {
      ServiceType = "S3"
      Purpose     = "Static Website"
    }
  )

  cloudfront_tags = merge(
    local.common_tags,
    {
      ServiceType = "CloudFront"
      Purpose     = "CDN"
    }
  )

  monitoring_tags = merge(
    local.common_tags,
    {
      ServiceType = "Monitoring"
    }
  )
}

