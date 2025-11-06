# Generar JWT Secret si no se proporciona
resource "random_password" "jwt_secret" {
  count   = var.jwt_secret == "" ? 1 : 0
  length  = 64
  special = false
}

# Lambda Layer para dependencias comunes (opcional, para optimizar)
# Por ahora, todas las dependencias van en el ZIP

# Lambda Function - Auth Service
resource "aws_lambda_function" "auth" {
  filename         = "${path.module}/../auth/auth-lambda.zip"
  function_name    = "${var.project_name}-auth"
  role             = aws_iam_role.lambda.arn
  handler          = "lambda_handler.handler"
  runtime          = var.lambda_runtime
  timeout          = var.lambda_timeout
  memory_size      = var.lambda_memory_size
  architectures    = ["x86_64"]
  
  # Si el ZIP no existe, se creará automáticamente
  source_code_hash = fileexists("${path.module}/../auth/auth-lambda.zip") ? filebase64sha256("${path.module}/../auth/auth-lambda.zip") : null

  # VPC Configuration
  vpc_config {
    subnet_ids         = local.subnet_ids
    security_group_ids = [aws_security_group.lambda.id]
  }

  environment {
    variables = {
      DATABASE_URL = "postgresql+pg8000://${var.db_username}:${var.db_password != "" ? var.db_password : random_password.db_password.result}@${aws_db_instance.postgres.address}:${var.db_port}/${var.db_name}"
      JWT_SECRET   = var.jwt_secret != "" ? var.jwt_secret : random_password.jwt_secret[0].result
    }
  }

  # Tags
  tags = merge(
    local.lambda_tags,
    {
      Name    = "${var.project_name}-auth"
      Service = "auth"
    }
  )

  # Lifecycle - no recrear si el código no cambia
  lifecycle {
    ignore_changes = [filename]
  }

  depends_on = [
    aws_iam_role_policy_attachment.lambda_vpc,
    aws_iam_role_policy_attachment.lambda_basic,
    aws_db_instance.postgres,
    null_resource.package_lambda_auth
  ]
}

# Lambda Function - API Service
resource "aws_lambda_function" "api" {
  filename         = "${path.module}/../api/api-lambda.zip"
  function_name    = "${var.project_name}-api"
  role             = aws_iam_role.lambda.arn
  handler          = "lambda_handler.handler"
  runtime          = var.lambda_runtime
  timeout          = var.lambda_timeout
  memory_size      = var.lambda_memory_size
  architectures    = ["x86_64"]
  
  # Si el ZIP no existe, se creará automáticamente
  source_code_hash = fileexists("${path.module}/../api/api-lambda.zip") ? filebase64sha256("${path.module}/../api/api-lambda.zip") : null

  # VPC Configuration
  vpc_config {
    subnet_ids         = local.subnet_ids
    security_group_ids = [aws_security_group.lambda.id]
  }

  environment {
    variables = {
      DATABASE_URL      = "postgresql+pg8000://${var.db_username}:${var.db_password != "" ? var.db_password : random_password.db_password.result}@${aws_db_instance.postgres.address}:${var.db_port}/${var.db_name}"
      JWT_SECRET        = var.jwt_secret != "" ? var.jwt_secret : random_password.jwt_secret[0].result
      AUTH_SERVICE_URL  = "${aws_apigatewayv2_api.api_gateway.api_endpoint}/auth"
    }
  }

  # Tags
  tags = merge(
    local.lambda_tags,
    {
      Name    = "${var.project_name}-api"
      Service = "api"
    }
  )

  # Lifecycle - no recrear si el código no cambia
  lifecycle {
    ignore_changes = [filename]
  }

  depends_on = [
    aws_iam_role_policy_attachment.lambda_vpc,
    aws_iam_role_policy_attachment.lambda_basic,
    aws_db_instance.postgres,
    aws_apigatewayv2_api.api_gateway,
    null_resource.package_lambda_api
  ]
}

# CloudWatch Log Groups con configuración profesional
resource "aws_cloudwatch_log_group" "lambda_auth" {
  name              = "/aws/lambda/${aws_lambda_function.auth.function_name}"
  retention_in_days = var.log_retention_days

  tags = merge(
    local.common_tags,
    {
      Name        = "${var.project_name}-auth-logs"
      Service     = "auth"
      ServiceType = "CloudWatch"
    }
  )
}

resource "aws_cloudwatch_log_group" "lambda_api" {
  name              = "/aws/lambda/${aws_lambda_function.api.function_name}"
  retention_in_days = var.log_retention_days

  tags = merge(
    local.common_tags,
    {
      Name        = "${var.project_name}-api-logs"
      Service     = "api"
      ServiceType = "CloudWatch"
    }
  )
}

