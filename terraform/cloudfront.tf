# CloudFront Origin Access Control (OAC) - Reemplaza OAI (legacy)
resource "aws_cloudfront_origin_access_control" "frontend" {
  count                             = var.enable_cloudfront ? 1 : 0
  name                              = "${var.project_name}-oac"
  description                       = "OAC for ${var.project_name} frontend"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

# CloudFront Distribution
resource "aws_cloudfront_distribution" "frontend" {
  count = var.enable_cloudfront ? 1 : 0

  enabled             = true
  is_ipv6_enabled     = true
  comment             = "CloudFront distribution for ${var.project_name} frontend"
  default_root_object = "index.html"
  price_class         = var.cloudfront_price_class

  # Solo usar aliases si NO estamos usando CNAME (porque CNAME no requiere alias en CloudFront)
  aliases = var.custom_domain != "" && !var.use_cname_instead_of_alias ? [var.custom_domain] : []

  origin {
    domain_name              = aws_s3_bucket.frontend.bucket_regional_domain_name
    origin_id                = "S3-${aws_s3_bucket.frontend.id}"
    origin_access_control_id = aws_cloudfront_origin_access_control.frontend[0].id
  }

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "S3-${aws_s3_bucket.frontend.id}"

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
    compress               = true
  }

  # Cache behavior para assets estáticos (JS, CSS, imágenes)
  ordered_cache_behavior {
    path_pattern     = "*.js"
    allowed_methods = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "S3-${aws_s3_bucket.frontend.id}"

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 31536000 # 1 año
    max_ttl                = 31536000
    compress               = true
  }

  ordered_cache_behavior {
    path_pattern     = "*.css"
    allowed_methods = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "S3-${aws_s3_bucket.frontend.id}"

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 31536000 # 1 año
    max_ttl                = 31536000
    compress               = true
  }

  # Custom error response para Angular routing
  custom_error_response {
    error_code         = 404
    response_code      = 200
    response_page_path = "/index.html"
  }

  custom_error_response {
    error_code         = 403
    response_code      = 200
    response_page_path = "/index.html"
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  # Configuración de certificado SSL
  dynamic "viewer_certificate" {
    for_each = var.custom_domain != "" && var.enable_cloudfront ? [1] : []
    content {
      acm_certificate_arn      = aws_acm_certificate_validation.cloudfront[0].certificate_arn
      ssl_support_method       = "sni-only"
      minimum_protocol_version = "TLSv1.2_2021"
    }
  }

  # Si no hay dominio personalizado, usar certificado por defecto
  dynamic "viewer_certificate" {
    for_each = var.custom_domain == "" && var.enable_cloudfront ? [1] : []
    content {
      cloudfront_default_certificate = true
    }
  }

  tags = merge(
    local.cloudfront_tags,
    {
      Name = "${var.project_name}-cloudfront"
    }
  )

  depends_on = [aws_cloudfront_origin_access_control.frontend]
}

# Actualizar S3 Bucket Policy para CloudFront OAC
resource "aws_s3_bucket_policy" "cloudfront" {
  count  = var.enable_cloudfront ? 1 : 0
  bucket = aws_s3_bucket.frontend.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowCloudFrontServicePrincipal"
        Effect = "Allow"
        Principal = {
          Service = "cloudfront.amazonaws.com"
        }
        Action   = "s3:GetObject"
        Resource = "${aws_s3_bucket.frontend.arn}/*"
        Condition = {
          StringLike = {
            "AWS:SourceArn" = "${aws_cloudfront_distribution.frontend[0].arn}*"
          }
        }
      },
      {
        Sid    = "AllowCloudFrontServicePrincipalList"
        Effect = "Allow"
        Principal = {
          Service = "cloudfront.amazonaws.com"
        }
        Action   = "s3:ListBucket"
        Resource = aws_s3_bucket.frontend.arn
        Condition = {
          StringLike = {
            "AWS:SourceArn" = "${aws_cloudfront_distribution.frontend[0].arn}*"
          }
        }
      }
    ]
  })

  depends_on = [aws_cloudfront_distribution.frontend]
}

