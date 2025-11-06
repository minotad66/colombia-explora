# Certificado SSL para CloudFront
# IMPORTANTE: Los certificados para CloudFront DEBEN estar en us-east-1

# Data source para obtener el dominio raíz del custom_domain
locals {
  # Extraer el dominio raíz del custom_domain (ej: colombia-explora.frontend.com -> frontend.com)
  domain_root = var.custom_domain != "" ? join(".", slice(split(".", var.custom_domain), length(split(".", var.custom_domain)) - 2, length(split(".", var.custom_domain)))) : ""
  # Asegurar que termine en punto para Route 53
  domain_root_with_dot = local.domain_root != "" ? "${local.domain_root}." : ""
}

# Buscar hosted zone existente si no se proporciona ID
data "aws_route53_zone" "selected" {
  count = var.custom_domain != "" && var.route53_hosted_zone_id == "" && var.route53_hosted_zone_name != "" ? 1 : 0
  
  name = var.route53_hosted_zone_name
}

data "aws_route53_zone" "by_id" {
  count = var.custom_domain != "" && var.route53_hosted_zone_id != "" ? 1 : 0
  
  zone_id = var.route53_hosted_zone_id
}

data "aws_route53_zone" "by_domain" {
  count = var.custom_domain != "" && var.route53_hosted_zone_id == "" && var.route53_hosted_zone_name == "" ? 1 : 0
  
  name = local.domain_root_with_dot
}

# Local para obtener el hosted zone ID
locals {
  hosted_zone_id = var.custom_domain != "" ? (
    var.route53_hosted_zone_id != "" ? var.route53_hosted_zone_id : (
      var.route53_hosted_zone_name != "" ? data.aws_route53_zone.selected[0].zone_id : (
        length(data.aws_route53_zone.by_domain) > 0 ? data.aws_route53_zone.by_domain[0].zone_id : ""
      )
    )
  ) : ""
}

# Certificado SSL en ACM (requerido en us-east-1 para CloudFront)
# Solo se crea si NO estamos usando CNAME (porque CNAME no requiere certificado SSL en CloudFront)
resource "aws_acm_certificate" "cloudfront" {
  count = var.custom_domain != "" && var.enable_cloudfront && !var.use_cname_instead_of_alias ? 1 : 0

  domain_name       = var.custom_domain
  validation_method = "DNS"

  # CloudFront requiere certificados en us-east-1
  provider = aws.us_east_1

  lifecycle {
    create_before_destroy = true
  }

  tags = merge(
    local.common_tags,
    {
      Name        = "${var.project_name}-cloudfront-cert"
      Service     = "ACM"
      ServiceType = "Certificate"
    }
  )
}

# Validación del certificado via DNS
# Solo se valida si NO estamos usando CNAME (porque CNAME no requiere certificado)
resource "aws_acm_certificate_validation" "cloudfront" {
  count = var.custom_domain != "" && var.enable_cloudfront && var.create_route53_record && local.hosted_zone_id != "" && !var.use_cname_instead_of_alias ? 1 : 0

  certificate_arn = aws_acm_certificate.cloudfront[0].arn
  provider        = aws.us_east_1

  validation_record_fqdns = [
    for record in aws_route53_record.cert_validation : record.fqdn
  ]

  timeouts {
    create = "5m"
  }
}

# Registro Route 53 para validación del certificado
# Solo se crea si NO estamos usando CNAME
resource "aws_route53_record" "cert_validation" {
  for_each = var.custom_domain != "" && var.enable_cloudfront && var.create_route53_record && local.hosted_zone_id != "" && !var.use_cname_instead_of_alias ? {
    for dvo in aws_acm_certificate.cloudfront[0].domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  } : {}

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = local.hosted_zone_id
}

