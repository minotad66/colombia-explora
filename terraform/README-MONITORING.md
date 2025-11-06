# 📊 Guía de Monitoreo - Colombia Explora

Esta guía explica el sistema completo de monitoreo configurado en Terraform.

---

## 🎯 Componentes de Monitoreo

### 1. CloudWatch Dashboards

Se crean **3 dashboards** automáticamente:

#### Dashboard Principal (`main-dashboard`)
- **Lambda Functions**: Invocations, Errors, Duration, Throttles
- **RDS PostgreSQL**: CPU, Connections, Free Memory
- **API Gateway**: Requests, 4XX/5XX Errors, Latency
- **Lambda Performance**: Concurrent Executions, Max Duration

**Acceso:**
```bash
terraform output monitoring_dashboards
```

#### Dashboard Lambda Auth (`lambda-auth`)
- Logs recientes en tiempo real
- Métricas de invocaciones y errores
- Métricas de performance (duration, throttles)

#### Dashboard Lambda API (`lambda-api`)
- Logs recientes en tiempo real
- Métricas de invocaciones y errores
- Métricas de performance

---

## 🚨 CloudWatch Alarms

Se configuran **9 alarms** automáticamente:

### Lambda Alarms
1. **Lambda Auth Errors** - Alerta si > 5 errores en 10 minutos
2. **Lambda API Errors** - Alerta si > 5 errores en 10 minutos
3. **Lambda Auth Duration** - Alerta si promedio > 25 segundos
4. **Lambda API Duration** - Alerta si promedio > 25 segundos

### RDS Alarms
5. **RDS CPU Utilization** - Alerta si CPU > 80%
6. **RDS Database Connections** - Alerta si connections > 50
7. **RDS Free Storage Space** - Alerta si < 2GB libres

### API Gateway Alarms
8. **API Gateway 5XX Errors** - Alerta si > 10 errores 5XX
9. **API Gateway Latency** - Alerta si latencia promedio > 5 segundos

**Ver todos los alarms:**
```bash
terraform output cloudwatch_alarms
```

**Ver alarms en AWS Console:**
```
https://console.aws.amazon.com/cloudwatch/home?region=us-east-1#alarmsV2:
```

---

## 📝 CloudWatch Log Insights

Se crean **4 queries guardadas** para análisis rápido:

1. **Lambda Auth Error Analysis** - Filtra todos los errores de Auth
2. **Lambda API Error Analysis** - Filtra todos los errores de API
3. **Lambda Performance Analysis** - Análisis de duración de ejecuciones
4. **API Gateway Request Analysis** - Análisis de requests por status code

**Usar las queries:**
1. AWS Console → CloudWatch → Logs Insights
2. Selecciona el log group
3. Busca las queries guardadas con el prefijo del proyecto

---

## 📈 Métricas Custom

Se crean **metric filters** para contar errores específicos:

- `AuthErrorCount` - Contador de errores en Lambda Auth
- `ApiErrorCount` - Contador de errores en Lambda API

Estas métricas aparecen en el namespace `${project_name}/Lambda`

---

## 🔍 Cómo Usar el Monitoreo

### Ver Dashboards

```bash
# Obtener URLs de dashboards
terraform output monitoring_dashboards

# O manualmente en AWS Console
aws cloudwatch list-dashboards --query 'DashboardEntries[?contains(DashboardName, `colombia-explora`)].DashboardName'
```

### Ver Logs en Tiempo Real

```bash
# Lambda Auth logs
aws logs tail /aws/lambda/colombia-explora-auth --follow

# Lambda API logs
aws logs tail /aws/lambda/colombia-explora-api --follow

# API Gateway logs
aws logs tail /aws/apigateway/colombia-explora-api --follow
```

### Ver Métricas

```bash
# Listar métricas de Lambda
aws cloudwatch list-metrics --namespace AWS/Lambda --dimensions Name=FunctionName,Value=colombia-explora-auth

# Obtener métricas específicas
aws cloudwatch get-metric-statistics \
  --namespace AWS/Lambda \
  --metric-name Invocations \
  --dimensions Name=FunctionName,Value=colombia-explora-auth \
  --start-time 2024-01-01T00:00:00Z \
  --end-time 2024-01-02T00:00:00Z \
  --period 3600 \
  --statistics Sum
```

### Ver Estado de Alarms

```bash
# Listar todos los alarms
aws cloudwatch describe-alarms --alarm-name-prefix colombia-explora

# Ver alarms en estado ALARM
aws cloudwatch describe-alarms --state-value ALARM
```

---

## 💰 Costos (Free Tier)

### Incluido en Free Tier:
- ✅ **10 custom metrics** gratis
- ✅ **5GB logs** gratis
- ✅ **10 alarms** gratis
- ✅ **Dashboards** ilimitados (gratis)
- ✅ **Log Insights** - 5 queries gratis/día

### Fuera del Free Tier:
- Custom metrics adicionales: $0.30/metrica/mes
- Logs adicionales: $0.50/GB
- Alarms adicionales: $0.10/alarm/mes
- Log Insights queries adicionales: $0.005/query

**Nuestra configuración usa:**
- 2 custom metrics (dentro de free tier)
- ~1-2GB logs/mes (dentro de free tier)
- 9 alarms (dentro de free tier)
- Dashboards ilimitados (gratis)

**Total estimado: $0/mes** (dentro de free tier)

---

## 🎨 Personalización

### Agregar más métricas

Edita `terraform/monitoring.tf` y agrega:

```hcl
resource "aws_cloudwatch_metric_alarm" "custom_alarm" {
  alarm_name          = "${var.project_name}-custom-metric"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CustomMetric"
  namespace           = "CustomNamespace"
  period              = 300
  statistic           = "Average"
  threshold           = 100
  # ...
}
```

### Agregar más dashboards

```hcl
resource "aws_cloudwatch_dashboard" "custom" {
  dashboard_name = "${var.project_name}-custom-dashboard"
  dashboard_body = jsonencode({
    widgets = [
      # Tu configuración de widgets
    ]
  })
}
```

### Cambiar thresholds de alarms

Edita los valores de `threshold` en `terraform/monitoring.tf`:

```hcl
threshold = 80  # Cambiar según tus necesidades
```

---

## 📚 Recursos Adicionales

- [CloudWatch Dashboards](https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/CloudWatch_Dashboards.html)
- [CloudWatch Alarms](https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/AlarmThatSendsEmail.html)
- [CloudWatch Logs Insights](https://docs.aws.amazon.com/AmazonCloudWatch/latest/logs/AnalyzingLogData.html)
- [CloudWatch Pricing](https://aws.amazon.com/cloudwatch/pricing/)

---

*Monitoreo configurado para Colombia Explora* 🏔️📊

