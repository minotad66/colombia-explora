# CloudWatch Monitoring y Métricas
# Configuración profesional para monitoreo completo
# Free tier: 10 custom metrics, 5GB logs, 10 alarms gratis

# ============================================
# CloudWatch Dashboards
# ============================================

# Dashboard principal del proyecto
resource "aws_cloudwatch_dashboard" "main" {
  dashboard_name = "${var.project_name}-main-dashboard"

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 12
        height = 6

        properties = {
          metrics = [
            ["AWS/Lambda", "Invocations", { "stat" = "Sum", "label" = "Lambda Invocations" }],
            ["AWS/Lambda", "Errors", { "stat" = "Sum", "label" = "Lambda Errors" }],
            [".", "Duration", { "stat" = "Average", "label" = "Avg Duration" }],
            [".", "Throttles", { "stat" = "Sum", "label" = "Throttles" }]
          ]
          period = 300
          stat   = "Sum"
          region = var.aws_region
          title  = "Lambda Functions - Overview"
          view   = "timeSeries"
          stacked = false
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 0
        width  = 12
        height = 6

        properties = {
          metrics = [
            ["AWS/RDS", "CPUUtilization", { "stat" = "Average", "label" = "CPU %" }],
            ["AWS/RDS", "DatabaseConnections", { "stat" = "Average", "label" = "Connections" }],
            ["AWS/RDS", "FreeableMemory", { "stat" = "Average", "label" = "Free Memory" }]
          ]
          period = 300
          stat   = "Average"
          region = var.aws_region
          title  = "RDS PostgreSQL - Metrics"
          view   = "timeSeries"
          stacked = false
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 6
        width  = 12
        height = 6

        properties = {
          metrics = [
            ["AWS/ApiGateway", "Count", { "stat" = "Sum", "label" = "API Requests" }],
            ["AWS/ApiGateway", "4XXError", { "stat" = "Sum", "label" = "4XX Errors" }],
            ["AWS/ApiGateway", "5XXError", { "stat" = "Sum", "label" = "5XX Errors" }],
            ["AWS/ApiGateway", "Latency", { "stat" = "Average", "label" = "Avg Latency" }]
          ]
          period = 300
          stat   = "Sum"
          region = var.aws_region
          title  = "API Gateway - Traffic"
          view   = "timeSeries"
          stacked = false
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 6
        width  = 12
        height = 6

        properties = {
          metrics = [
            ["AWS/Lambda", "ConcurrentExecutions", { "stat" = "Maximum", "label" = "Concurrent Executions" }],
            ["AWS/Lambda", "Duration", { "stat" = "Maximum", "label" = "Max Duration" }]
          ]
          period = 300
          stat   = "Maximum"
          region = var.aws_region
          title  = "Lambda - Performance"
          view   = "timeSeries"
          stacked = false
        }
      }
    ]
  })
}

# Dashboard específico para Lambda Auth
resource "aws_cloudwatch_dashboard" "lambda_auth" {
  dashboard_name = "${var.project_name}-lambda-auth"

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "log"
        x      = 0
        y      = 0
        width  = 24
        height = 6

        properties = {
          query = "SOURCE '${aws_cloudwatch_log_group.lambda_auth.name}' | fields @timestamp, @message\n| sort @timestamp desc\n| limit 100"
          region = var.aws_region
          title  = "Lambda Auth - Recent Logs"
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 6
        width  = 6
        height = 6

        properties = {
          metrics = [
            ["AWS/Lambda", "Invocations"]
          ]
          period = 300
          stat   = "Sum"
          region = var.aws_region
          title  = "Auth Service - Invocations"
          view   = "timeSeries"
          annotations = {
            horizontal = []
            vertical   = []
          }
        }
      },
      {
        type   = "metric"
        x      = 6
        y      = 6
        width  = 6
        height = 6

        properties = {
          metrics = [
            ["AWS/Lambda", "Errors"]
          ]
          period = 300
          stat   = "Sum"
          region = var.aws_region
          title  = "Auth Service - Errors"
          view   = "timeSeries"
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 6
        width  = 6
        height = 6

        properties = {
          metrics = [
            ["AWS/Lambda", "Duration"]
          ]
          period = 300
          stat   = "Average"
          region = var.aws_region
          title  = "Auth Service - Duration"
          view   = "timeSeries"
        }
      },
      {
        type   = "metric"
        x      = 18
        y      = 6
        width  = 6
        height = 6

        properties = {
          metrics = [
            ["AWS/Lambda", "Throttles"]
          ]
          period = 300
          stat   = "Sum"
          region = var.aws_region
          title  = "Auth Service - Throttles"
          view   = "timeSeries"
        }
      }
    ]
  })
}

# Dashboard específico para Lambda API
resource "aws_cloudwatch_dashboard" "lambda_api" {
  dashboard_name = "${var.project_name}-lambda-api"

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "log"
        x      = 0
        y      = 0
        width  = 24
        height = 6

        properties = {
          query = "SOURCE '${aws_cloudwatch_log_group.lambda_api.name}' | fields @timestamp, @message\n| sort @timestamp desc\n| limit 100"
          region = var.aws_region
          title  = "Lambda API - Recent Logs"
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 6
        width  = 6
        height = 6

        properties = {
          metrics = [
            ["AWS/Lambda", "Invocations"]
          ]
          period = 300
          stat   = "Sum"
          region = var.aws_region
          title  = "API Service - Invocations"
          view   = "timeSeries"
        }
      },
      {
        type   = "metric"
        x      = 6
        y      = 6
        width  = 6
        height = 6

        properties = {
          metrics = [
            ["AWS/Lambda", "Errors"]
          ]
          period = 300
          stat   = "Sum"
          region = var.aws_region
          title  = "API Service - Errors"
          view   = "timeSeries"
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 6
        width  = 6
        height = 6

        properties = {
          metrics = [
            ["AWS/Lambda", "Duration"]
          ]
          period = 300
          stat   = "Average"
          region = var.aws_region
          title  = "API Service - Duration"
          view   = "timeSeries"
        }
      },
      {
        type   = "metric"
        x      = 18
        y      = 6
        width  = 6
        height = 6

        properties = {
          metrics = [
            ["AWS/Lambda", "Throttles"]
          ]
          period = 300
          stat   = "Sum"
          region = var.aws_region
          title  = "API Service - Throttles"
          view   = "timeSeries"
        }
      }
    ]
  })
}

# ============================================
# CloudWatch Alarms (condicional)
# ============================================
# Free tier: 10 alarms gratis

# Alarm: Lambda Auth Errors
resource "aws_cloudwatch_metric_alarm" "lambda_auth_errors" {
  alarm_name          = "${var.project_name}-lambda-auth-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "Errors"
  namespace           = "AWS/Lambda"
  period              = 300
  statistic           = "Sum"
  threshold           = 5
  alarm_description   = "This metric monitors lambda auth errors"
  treat_missing_data  = "notBreaching"

  dimensions = {
    FunctionName = aws_lambda_function.auth.function_name
  }

  tags = {
    Name = "${var.project_name}-lambda-auth-errors-alarm"
  }
}

# Alarm: Lambda API Errors
resource "aws_cloudwatch_metric_alarm" "lambda_api_errors" {
  alarm_name          = "${var.project_name}-lambda-api-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "Errors"
  namespace           = "AWS/Lambda"
  period              = 300
  statistic           = "Sum"
  threshold           = 5
  alarm_description   = "This metric monitors lambda api errors"
  treat_missing_data  = "notBreaching"

  dimensions = {
    FunctionName = aws_lambda_function.api.function_name
  }

  tags = {
    Name = "${var.project_name}-lambda-api-errors-alarm"
  }
}

# Alarm: Lambda Auth Duration
resource "aws_cloudwatch_metric_alarm" "lambda_auth_duration" {
  alarm_name          = "${var.project_name}-lambda-auth-duration"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "Duration"
  namespace           = "AWS/Lambda"
  period              = 300
  statistic           = "Average"
  threshold           = 25000  # 25 segundos (casi timeout)
  alarm_description   = "This metric monitors lambda auth duration"
  treat_missing_data  = "notBreaching"

  dimensions = {
    FunctionName = aws_lambda_function.auth.function_name
  }

  tags = {
    Name = "${var.project_name}-lambda-auth-duration-alarm"
  }
}

# Alarm: Lambda API Duration
resource "aws_cloudwatch_metric_alarm" "lambda_api_duration" {
  alarm_name          = "${var.project_name}-lambda-api-duration"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "Duration"
  namespace           = "AWS/Lambda"
  period              = 300
  statistic           = "Average"
  threshold           = 25000  # 25 segundos
  alarm_description   = "This metric monitors lambda api duration"
  treat_missing_data  = "notBreaching"

  dimensions = {
    FunctionName = aws_lambda_function.api.function_name
  }

  tags = {
    Name = "${var.project_name}-lambda-api-duration-alarm"
  }
}

# Alarm: RDS CPU Utilization
resource "aws_cloudwatch_metric_alarm" "rds_cpu" {
  alarm_name          = "${var.project_name}-rds-cpu"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/RDS"
  period              = 300
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "This metric monitors RDS CPU utilization"
  treat_missing_data  = "breaching"

  dimensions = {
    DBInstanceIdentifier = aws_db_instance.postgres.id
  }

  tags = {
    Name = "${var.project_name}-rds-cpu-alarm"
  }
}

# Alarm: RDS Database Connections
resource "aws_cloudwatch_metric_alarm" "rds_connections" {
  alarm_name          = "${var.project_name}-rds-connections"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "DatabaseConnections"
  namespace           = "AWS/RDS"
  period              = 300
  statistic           = "Average"
  threshold           = 50  # Ajustar según tu instancia
  alarm_description   = "This metric monitors RDS database connections"
  treat_missing_data  = "notBreaching"

  dimensions = {
    DBInstanceIdentifier = aws_db_instance.postgres.id
  }

  tags = {
    Name = "${var.project_name}-rds-connections-alarm"
  }
}

# Alarm: RDS Free Storage Space
resource "aws_cloudwatch_metric_alarm" "rds_storage" {
  alarm_name          = "${var.project_name}-rds-storage"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 1
  metric_name         = "FreeStorageSpace"
  namespace           = "AWS/RDS"
  period              = 300
  statistic           = "Average"
  threshold           = 2000000000  # 2GB en bytes
  alarm_description   = "This metric monitors RDS free storage space"
  treat_missing_data  = "breaching"

  dimensions = {
    DBInstanceIdentifier = aws_db_instance.postgres.id
  }

  tags = {
    Name = "${var.project_name}-rds-storage-alarm"
  }
}

# Alarm: API Gateway 5XX Errors
resource "aws_cloudwatch_metric_alarm" "api_gateway_5xx" {
  alarm_name          = "${var.project_name}-api-gateway-5xx"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "5XXError"
  namespace           = "AWS/ApiGateway"
  period              = 300
  statistic           = "Sum"
  threshold           = 10
  alarm_description   = "This metric monitors API Gateway 5XX errors"
  treat_missing_data  = "notBreaching"

  dimensions = {
    ApiName = aws_apigatewayv2_api.api_gateway.name
  }

  tags = {
    Name = "${var.project_name}-api-gateway-5xx-alarm"
  }
}

# Alarm: API Gateway Latency
resource "aws_cloudwatch_metric_alarm" "api_gateway_latency" {
  alarm_name          = "${var.project_name}-api-gateway-latency"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "Latency"
  namespace           = "AWS/ApiGateway"
  period              = 300
  statistic           = "Average"
  threshold           = 5000  # 5 segundos
  alarm_description   = "This metric monitors API Gateway latency"
  treat_missing_data  = "notBreaching"

  dimensions = {
    ApiName = aws_apigatewayv2_api.api_gateway.name
  }

  tags = {
    Name = "${var.project_name}-api-gateway-latency-alarm"
  }
}

# ============================================
# CloudWatch Log Insights Queries (Saved)
# ============================================

# Query: Lambda Auth Error Analysis
resource "aws_cloudwatch_query_definition" "lambda_auth_errors" {
  name = "${var.project_name}-lambda-auth-errors"

  log_group_names = [
    aws_cloudwatch_log_group.lambda_auth.name
  ]

  query_string = <<-EOF
fields @timestamp, @message
| filter @message like /(?i)(error|exception|failed|failure)/
| sort @timestamp desc
| limit 100
  EOF
}

# Query: Lambda API Error Analysis
resource "aws_cloudwatch_query_definition" "lambda_api_errors" {
  name = "${var.project_name}-lambda-api-errors"

  log_group_names = [
    aws_cloudwatch_log_group.lambda_api.name
  ]

  query_string = <<-EOF
fields @timestamp, @message
| filter @message like /(?i)(error|exception|failed|failure)/
| sort @timestamp desc
| limit 100
  EOF
}

# Query: Lambda Performance Analysis
resource "aws_cloudwatch_query_definition" "lambda_performance" {
  name = "${var.project_name}-lambda-performance"

  log_group_names = [
    aws_cloudwatch_log_group.lambda_auth.name,
    aws_cloudwatch_log_group.lambda_api.name
  ]

  query_string = <<-EOF
fields @timestamp, @message, @duration
| filter @type = "REPORT"
| stats avg(@duration), max(@duration), min(@duration) by @logStream
| sort @timestamp desc
  EOF
}

# Query: API Gateway Request Analysis
resource "aws_cloudwatch_query_definition" "api_gateway_requests" {
  name = "${var.project_name}-api-gateway-requests"

  log_group_names = [
    aws_cloudwatch_log_group.api_gateway.name
  ]

  query_string = <<-EOF
fields @timestamp, @requestId, @httpMethod, @path, @status
| stats count() by @status
| sort @timestamp desc
  EOF
}

