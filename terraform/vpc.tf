# VPC Configuration y Subnets
# Configuración profesional con alta disponibilidad

# Data source para obtener VPC seleccionada
# Nota: local.vpc_id se define en security.tf
data "aws_vpc" "selected" {
  id = local.vpc_id
}

# Data source para obtener todas las subnets disponibles
data "aws_subnets" "all" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.selected.id]
  }
  filter {
    name   = "state"
    values = ["available"]
  }
}

# Obtener información de las subnets para seleccionar las mejores
data "aws_subnet" "selected" {
  for_each = toset(length(var.subnet_ids) > 0 ? var.subnet_ids : slice(data.aws_subnets.all.ids, 0, min(2, length(data.aws_subnets.all.ids))))
  id       = each.value
}

# Local para determinar subnets finales
locals {
  # Si se proporcionan subnets, usarlas; sino, usar las primeras 2 disponibles
  subnet_ids = length(var.subnet_ids) > 0 ? var.subnet_ids : slice(data.aws_subnets.all.ids, 0, min(2, length(data.aws_subnets.all.ids)))
  
  # Verificar que tengamos al menos 2 subnets para alta disponibilidad
  subnet_count = length(local.subnet_ids)
}

# Nota: Los outputs de VPC están en outputs.tf

