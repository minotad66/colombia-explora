# Generar password aleatorio para RDS si no se proporciona
resource "random_password" "db_password" {
  length  = 32
  special = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

# RDS Subnet Group (usa el data source de vpc.tf)

resource "aws_db_subnet_group" "main" {
  name       = "${var.project_name}-db-subnet-group"
  subnet_ids = local.subnet_ids

  tags = {
    Name = "${var.project_name}-db-subnet-group"
  }
}

# RDS PostgreSQL Instance
resource "aws_db_instance" "postgres" {
  identifier = "${var.project_name}-db"

  engine         = "postgres"
  engine_version = "15.14"
  instance_class = var.db_instance_class

  allocated_storage     = var.db_allocated_storage
  max_allocated_storage = var.db_allocated_storage * 2 # Auto-scaling hasta 2x
  storage_type          = "gp3"
  storage_encrypted     = true

  db_name  = var.db_name
  username = var.db_username
  password = var.db_password != "" ? var.db_password : random_password.db_password.result

  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.rds.id]
  publicly_accessible    = var.db_publicly_accessible

  port = var.db_port

  backup_retention_period = var.db_backup_retention_period
  backup_window           = "03:00-04:00"
  maintenance_window      = "mon:04:00-mon:05:00"

  # Performance Insights (opcional, tiene costo)
  performance_insights_enabled = false

  # Monitoring
  monitoring_interval = var.enable_detailed_monitoring ? 60 : 0 # 0 = disabled (free), 60 = enabled (costo adicional)

  # Deletion protection
  deletion_protection = false # Deshabilitado para permitir destroy
  skip_final_snapshot = true # Saltar snapshot final para permitir destroy sin problemas
  # Si necesitas snapshot final, descomenta y ajusta:
  # final_snapshot_identifier = "${var.project_name}-final-snapshot-${formatdate("YYYY-MM-DD-hhmm", timestamp())}"

  # Auto minor version upgrade
  auto_minor_version_upgrade = true

  tags = merge(
    local.rds_tags,
    {
      Name = "${var.project_name}-db"
    }
  )
}

