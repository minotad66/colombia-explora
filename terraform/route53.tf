# Registro Route 53 para apuntar el dominio personalizado a CloudFront
# Opción A: Usar CNAME (más simple, no requiere certificado SSL)
resource "aws_route53_record" "cloudfront_cname" {
  count = var.custom_domain != "" && var.enable_cloudfront && var.create_route53_record && local.hosted_zone_id != "" && var.use_cname_instead_of_alias ? 1 : 0

  zone_id = local.hosted_zone_id
  name    = var.custom_domain
  type    = "CNAME"
  ttl     = 300
  records = [aws_cloudfront_distribution.frontend[0].domain_name]
}

# Opción B: Usar A alias (requiere certificado SSL en CloudFront)
resource "aws_route53_record" "cloudfront" {
  count = var.custom_domain != "" && var.enable_cloudfront && var.create_route53_record && local.hosted_zone_id != "" && !var.use_cname_instead_of_alias ? 1 : 0

  zone_id = local.hosted_zone_id
  name    = var.custom_domain
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.frontend[0].domain_name
    zone_id                = aws_cloudfront_distribution.frontend[0].hosted_zone_id
    evaluate_target_health = false
  }
}

# Registro AAAA para IPv6 (solo si usamos alias, no CNAME)
resource "aws_route53_record" "cloudfront_ipv6" {
  count = var.custom_domain != "" && var.enable_cloudfront && var.create_route53_record && local.hosted_zone_id != "" && !var.use_cname_instead_of_alias ? 1 : 0

  zone_id = local.hosted_zone_id
  name    = var.custom_domain
  type    = "AAAA"

  alias {
    name                   = aws_cloudfront_distribution.frontend[0].domain_name
    zone_id                = aws_cloudfront_distribution.frontend[0].hosted_zone_id
    evaluate_target_health = false
  }
}

