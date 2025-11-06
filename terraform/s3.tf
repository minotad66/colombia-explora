# Generar nombre único para bucket si no se proporciona
resource "random_id" "bucket_suffix" {
  byte_length = 4
}

locals {
  bucket_name = var.frontend_bucket_name != "" ? var.frontend_bucket_name : "${var.project_name}-frontend-${random_id.bucket_suffix.hex}"
}

# S3 Bucket para Frontend
resource "aws_s3_bucket" "frontend" {
  bucket = local.bucket_name

  # Permitir eliminar bucket aunque tenga objetos (útil para destroy)
  force_destroy = true

  tags = merge(
    local.s3_tags,
    {
      Name = "${var.project_name}-frontend"
    }
  )
}

# S3 Bucket Versioning
resource "aws_s3_bucket_versioning" "frontend" {
  bucket = aws_s3_bucket.frontend.id

  versioning_configuration {
    status = "Disabled" # Habilitar si quieres versionado
  }
}

# S3 Bucket Server-Side Encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "frontend" {
  bucket = aws_s3_bucket.frontend.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# S3 Bucket Public Access Block
# Si CloudFront está habilitado, bloqueamos acceso público
# Si no, permitimos acceso público para website hosting
resource "aws_s3_bucket_public_access_block" "frontend" {
  bucket = aws_s3_bucket.frontend.id

  block_public_acls       = var.enable_cloudfront
  block_public_policy     = var.enable_cloudfront
  ignore_public_acls      = var.enable_cloudfront
  restrict_public_buckets = var.enable_cloudfront
}

# S3 Bucket Policy - Permitir acceso público solo si CloudFront NO está habilitado
resource "aws_s3_bucket_policy" "frontend" {
  count  = var.enable_cloudfront ? 0 : 1
  bucket = aws_s3_bucket.frontend.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "PublicReadGetObject"
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:GetObject"
        Resource  = "${aws_s3_bucket.frontend.arn}/*"
      }
    ]
  })

  depends_on = [aws_s3_bucket_public_access_block.frontend]
}

# S3 Bucket Website Configuration
resource "aws_s3_bucket_website_configuration" "frontend" {
  bucket = aws_s3_bucket.frontend.id

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "index.html" # Importante para Angular routing
  }
}

# S3 Bucket CORS Configuration
resource "aws_s3_bucket_cors_configuration" "frontend" {
  bucket = aws_s3_bucket.frontend.id

  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["GET", "HEAD"]
    allowed_origins = ["*"]
    expose_headers  = ["ETag"]
    max_age_seconds = 3000
  }
}

