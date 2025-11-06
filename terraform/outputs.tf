output "rds_endpoint" {
  description = "Endpoint de RDS PostgreSQL"
  value       = aws_db_instance.postgres.endpoint
  sensitive   = true
}

output "rds_address" {
  description = "Address de RDS (sin puerto)"
  value       = aws_db_instance.postgres.address
}

output "database_url" {
  description = "Connection string completo para la base de datos"
  value       = "postgresql+pg8000://${var.db_username}:${random_password.db_password.result}@${aws_db_instance.postgres.address}:${var.db_port}/${var.db_name}"
  sensitive   = true
}

output "lambda_auth_function_name" {
  description = "Nombre de la función Lambda Auth"
  value       = aws_lambda_function.auth.function_name
}

output "lambda_auth_function_arn" {
  description = "ARN de la función Lambda Auth"
  value       = aws_lambda_function.auth.arn
}

output "lambda_api_function_name" {
  description = "Nombre de la función Lambda API"
  value       = aws_lambda_function.api.function_name
}

output "lambda_api_function_arn" {
  description = "ARN de la función Lambda API"
  value       = aws_lambda_function.api.arn
}

output "api_gateway_url" {
  description = "URL del API Gateway"
  value       = aws_apigatewayv2_api.api_gateway.api_endpoint
}

output "api_gateway_id" {
  description = "ID del API Gateway"
  value       = aws_apigatewayv2_api.api_gateway.id
}

output "s3_bucket_name" {
  description = "Nombre del bucket S3 para frontend"
  value       = aws_s3_bucket.frontend.bucket
}

output "s3_bucket_website_endpoint" {
  description = "Website endpoint del bucket S3"
  value       = aws_s3_bucket_website_configuration.frontend.website_endpoint
}

output "cloudfront_distribution_id" {
  description = "ID de la distribución CloudFront"
  value       = var.enable_cloudfront ? aws_cloudfront_distribution.frontend[0].id : null
}

output "cloudfront_domain_name" {
  description = "Domain name de CloudFront"
  value       = var.enable_cloudfront ? aws_cloudfront_distribution.frontend[0].domain_name : null
}

output "cloudfront_url" {
  description = "URL completa de CloudFront"
  value       = var.enable_cloudfront ? (
    var.custom_domain != "" ? "https://${var.custom_domain}" : "https://${aws_cloudfront_distribution.frontend[0].domain_name}"
  ) : null
}

output "custom_domain_url" {
  description = "URL del dominio personalizado (si está configurado)"
  value       = var.custom_domain != "" && var.enable_cloudfront ? "https://${var.custom_domain}" : null
}

output "certificate_arn" {
  description = "ARN del certificado SSL (si está configurado)"
  value       = var.custom_domain != "" && var.enable_cloudfront ? aws_acm_certificate.cloudfront[0].arn : null
}

output "jwt_secret" {
  description = "JWT Secret generado (si no se proporcionó uno)"
  value       = var.jwt_secret != "" ? var.jwt_secret : random_password.jwt_secret[0].result
  sensitive   = true
}

output "frontend_url" {
  description = "URL del frontend (CloudFront si está habilitado, sino S3)"
  value       = var.enable_cloudfront ? "https://${aws_cloudfront_distribution.frontend[0].domain_name}" : "http://${aws_s3_bucket_website_configuration.frontend.website_endpoint}"
}

output "application_url" {
  description = "🎯 URL PRINCIPAL de la aplicación para acceder"
  value       = var.enable_cloudfront ? "https://${aws_cloudfront_distribution.frontend[0].domain_name}" : "http://${aws_s3_bucket_website_configuration.frontend.website_endpoint}"
}

output "api_docs_url" {
  description = "URL de documentación de la API"
  value       = "${aws_apigatewayv2_api.api_gateway.api_endpoint}/docs"
}

output "backend_url" {
  description = "URL del backend (API Gateway)"
  value       = aws_apigatewayv2_api.api_gateway.api_endpoint
}

output "monitoring_dashboards" {
  description = "URLs de los dashboards de CloudWatch"
  value = {
    main_dashboard = "https://${var.aws_region}.console.aws.amazon.com/cloudwatch/home?region=${var.aws_region}#dashboards:name=${aws_cloudwatch_dashboard.main.dashboard_name}"
    lambda_auth_dashboard = "https://${var.aws_region}.console.aws.amazon.com/cloudwatch/home?region=${var.aws_region}#dashboards:name=${aws_cloudwatch_dashboard.lambda_auth.dashboard_name}"
    lambda_api_dashboard = "https://${var.aws_region}.console.aws.amazon.com/cloudwatch/home?region=${var.aws_region}#dashboards:name=${aws_cloudwatch_dashboard.lambda_api.dashboard_name}"
  }
}

output "cloudwatch_alarms" {
  description = "Lista de CloudWatch Alarms creados"
  value = [
    aws_cloudwatch_metric_alarm.lambda_auth_errors.alarm_name,
    aws_cloudwatch_metric_alarm.lambda_api_errors.alarm_name,
    aws_cloudwatch_metric_alarm.lambda_auth_duration.alarm_name,
    aws_cloudwatch_metric_alarm.lambda_api_duration.alarm_name,
    aws_cloudwatch_metric_alarm.rds_cpu.alarm_name,
    aws_cloudwatch_metric_alarm.rds_connections.alarm_name,
    aws_cloudwatch_metric_alarm.rds_storage.alarm_name,
    aws_cloudwatch_metric_alarm.api_gateway_5xx.alarm_name,
    aws_cloudwatch_metric_alarm.api_gateway_latency.alarm_name
  ]
}

output "vpc_info" {
  description = "Información de VPC y subnets utilizadas"
  value = {
    vpc_id      = data.aws_vpc.selected.id
    vpc_cidr    = data.aws_vpc.selected.cidr_block
    subnet_ids  = local.subnet_ids
    subnet_count = local.subnet_count
  }
}

output "deployment_summary" {
  description = "🎉 Resumen del despliegue completo"
  sensitive   = true
  value = <<-EOT
    ============================================
    ✅ DESPLIEGUE COMPLETADO EXITOSAMENTE!
    ============================================
    
    🌐 URL DE LA APLICACIÓN:
    👉 ${var.enable_cloudfront ? "https://${aws_cloudfront_distribution.frontend[0].domain_name}" : "http://${aws_s3_bucket_website_configuration.frontend.website_endpoint}"}
    
    📡 BACKEND API:
    - API Gateway: ${aws_apigatewayv2_api.api_gateway.api_endpoint}
    - API Docs: ${aws_apigatewayv2_api.api_gateway.api_endpoint}/docs
    - Auth Docs: ${aws_apigatewayv2_api.api_gateway.api_endpoint}/auth/docs
    
    📊 MONITOREO:
    - Dashboards: terraform output monitoring_dashboards
    - Alarms: terraform output cloudwatch_alarms
    
    🗄️ BASE DE DATOS:
    - Endpoint: ${aws_db_instance.postgres.address}
    - Database: ${var.db_name}
    - Usuario: ${var.db_username}
    
    🔐 CREDENCIALES:
    - Database Password: ${var.db_password != "" ? "*** (configurada)" : "*** (generada automáticamente)"}
    - JWT Secret: ${var.jwt_secret != "" ? "*** (configurado)" : "*** (generado automáticamente)"}
    
    ⚠️  IMPORTANTE: 
    - Guarda las credenciales de forma segura
    - Verifica que el frontend se haya desplegado correctamente
    - Si usas CloudFront, puede tardar 5-10 minutos en propagarse
    
    🧪 PRUEBA LA APLICACIÓN:
    1. Abre la URL del frontend en tu navegador
    2. Intenta registrarte o hacer login
    3. Verifica que puedas ver los destinos
    4. Prueba crear una reserva
    
    📚 DOCUMENTACIÓN:
    - Guía completa: GUIA-DESPLIEGUE-AWS.md
    - Monitoreo: terraform/README-MONITORING.md
  EOT
}

output "quick_access" {
  description = "🔗 Enlaces rápidos de acceso"
  value = {
    application = var.enable_cloudfront ? "https://${aws_cloudfront_distribution.frontend[0].domain_name}" : "http://${aws_s3_bucket_website_configuration.frontend.website_endpoint}"
    api_gateway = aws_apigatewayv2_api.api_gateway.api_endpoint
    api_docs = "${aws_apigatewayv2_api.api_gateway.api_endpoint}/docs"
    auth_docs = "${aws_apigatewayv2_api.api_gateway.api_endpoint}/auth/docs"
    health_check_auth = "${aws_apigatewayv2_api.api_gateway.api_endpoint}/auth/health"
    health_check_api = "${aws_apigatewayv2_api.api_gateway.api_endpoint}/api/health"
  }
}

