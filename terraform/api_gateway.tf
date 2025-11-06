# API Gateway HTTP API
resource "aws_apigatewayv2_api" "api_gateway" {
  name          = "${var.project_name}-api"
  protocol_type = "HTTP"
  description   = "API Gateway para Colombia Explora"

  cors_configuration {
    allow_origins = ["*"]
    allow_methods = ["GET", "POST", "PUT", "DELETE", "PATCH", "OPTIONS"]
    allow_headers = ["*"]
    max_age       = 300
  }

  tags = merge(
    local.api_gateway_tags,
    {
      Name = "${var.project_name}-api-gateway"
    }
  )
}

# API Gateway Stage
resource "aws_apigatewayv2_stage" "default" {
  api_id      = aws_apigatewayv2_api.api_gateway.id
  name        = "$default"
  auto_deploy = true

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.api_gateway.arn
    format = jsonencode({
      requestId      = "$context.requestId"
      ip             = "$context.identity.sourceIp"
      requestTime    = "$context.requestTime"
      httpMethod     = "$context.httpMethod"
      routeKey       = "$context.routeKey"
      status         = "$context.status"
      protocol       = "$context.protocol"
      responseLength = "$context.responseLength"
    })
  }

  tags = {
    Name = "${var.project_name}-api-stage"
  }
}

# Integration - Auth Service
resource "aws_apigatewayv2_integration" "auth" {
  api_id = aws_apigatewayv2_api.api_gateway.id

  integration_type   = "AWS_PROXY"
  integration_method = "POST"
  integration_uri    = aws_lambda_function.auth.invoke_arn
  payload_format_version = "2.0"
}

# Integration - API Service
resource "aws_apigatewayv2_integration" "api" {
  api_id = aws_apigatewayv2_api.api_gateway.id

  integration_type   = "AWS_PROXY"
  integration_method = "POST"
  integration_uri    = aws_lambda_function.api.invoke_arn
  payload_format_version = "2.0"
}

# Route - Auth Service
resource "aws_apigatewayv2_route" "auth" {
  api_id    = aws_apigatewayv2_api.api_gateway.id
  route_key = "ANY /auth/{proxy+}"
  target    = "integrations/${aws_apigatewayv2_integration.auth.id}"
}

# Route - API Service
resource "aws_apigatewayv2_route" "api" {
  api_id    = aws_apigatewayv2_api.api_gateway.id
  route_key = "ANY /api/{proxy+}"
  target    = "integrations/${aws_apigatewayv2_integration.api.id}"
}

# Lambda Permission - Auth
resource "aws_lambda_permission" "auth" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.auth.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.api_gateway.execution_arn}/*/*"
}

# Lambda Permission - API
resource "aws_lambda_permission" "api" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.api.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.api_gateway.execution_arn}/*/*"
}

# CloudWatch Log Group para API Gateway
resource "aws_cloudwatch_log_group" "api_gateway" {
  name              = "/aws/apigateway/${aws_apigatewayv2_api.api_gateway.name}"
  retention_in_days = var.log_retention_days

  tags = merge(
    local.common_tags,
    {
      Name        = "${var.project_name}-api-gateway-logs"
      Service     = "api-gateway"
      ServiceType = "CloudWatch"
    }
  )
}

