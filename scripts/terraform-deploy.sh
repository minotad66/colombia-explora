#!/bin/bash

# Script para desplegar Colombia Explora usando Terraform
# Automatiza el proceso completo de despliegue

set -e

# Colores
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_info() {
    echo -e "${YELLOW}ℹ️  $1${NC}"
}

# Verificar que estamos en el directorio correcto
if [ ! -d "terraform" ]; then
    print_error "Ejecuta este script desde la raíz del proyecto"
    exit 1
fi

echo "============================================"
echo "🚀 Despliegue de Colombia Explora con Terraform"
echo "============================================"
echo ""

# 1. Verificar Terraform instalado
print_info "Verificando Terraform..."
if ! command -v terraform &> /dev/null; then
    print_error "Terraform no está instalado"
    echo "Instala Terraform: https://www.terraform.io/downloads"
    exit 1
fi
print_success "Terraform instalado: $(terraform version | head -n1)"

# 2. Verificar AWS CLI
print_info "Verificando AWS CLI..."
if ! command -v aws &> /dev/null; then
    print_error "AWS CLI no está instalado"
    echo "Instala AWS CLI: https://aws.amazon.com/cli/"
    exit 1
fi
print_success "AWS CLI instalado: $(aws --version)"

# 3. Verificar credenciales AWS
print_info "Verificando credenciales AWS..."
if ! aws sts get-caller-identity &> /dev/null; then
    print_error "Credenciales AWS no configuradas"
    echo "Ejecuta: aws configure"
    exit 1
fi
AWS_ACCOUNT=$(aws sts get-caller-identity --query Account --output text)
print_success "AWS Account: $AWS_ACCOUNT"

# 4. Verificar Lambda packages
print_info "Verificando Lambda packages..."
if [ ! -f "auth/auth-lambda.zip" ] || [ ! -f "api/api-lambda.zip" ]; then
    print_warning "Lambda packages no encontrados. Creándolos..."
    ./scripts/package-lambda.sh
else
    print_success "Lambda packages encontrados"
fi

# 5. Verificar terraform.tfvars
print_info "Verificando configuración..."
cd terraform
if [ ! -f "terraform.tfvars" ]; then
    print_warning "terraform.tfvars no existe"
    if [ -f "terraform.tfvars.example" ]; then
        print_info "Copiando terraform.tfvars.example..."
        cp terraform.tfvars.example terraform.tfvars
        print_warning "⚠️  IMPORTANTE: Edita terraform.tfvars antes de continuar"
        echo ""
        read -p "¿Has editado terraform.tfvars? (y/n) " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            print_error "Por favor edita terraform.tfvars primero"
            exit 1
        fi
    else
        print_error "terraform.tfvars.example no existe"
        exit 1
    fi
fi
print_success "Configuración encontrada"

# 6. Inicializar Terraform
print_info "Inicializando Terraform..."
if [ ! -d ".terraform" ]; then
    terraform init
    print_success "Terraform inicializado"
else
    print_success "Terraform ya inicializado"
fi

# 7. Plan
echo ""
print_info "Ejecutando terraform plan..."
echo ""
terraform plan

# 8. Confirmar
echo ""
read -p "¿Deseas continuar con el despliegue? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    print_info "Despliegue cancelado"
    exit 0
fi

# 9. Apply
echo ""
print_info "Ejecutando terraform apply..."
echo "⏱️  Esto puede tardar 10-15 minutos..."
echo ""
terraform apply -auto-approve

# 10. Mostrar outputs
echo ""
echo "============================================"
print_success "Despliegue completado!"
echo "============================================"
echo ""

# Mostrar URL principal
APP_URL=$(terraform output -raw application_url 2>/dev/null || echo "N/A")
if [ "$APP_URL" != "N/A" ] && [ ! -z "$APP_URL" ]; then
    echo ""
    echo "🎯 ============================================"
    echo "   URL DE LA APLICACIÓN:"
    echo "   👉 $APP_URL"
    echo "   ============================================"
    echo ""
    print_success "¡Abre esta URL en tu navegador para probar la aplicación!"
    echo ""
fi

# Mostrar resumen
echo "📋 Resumen del despliegue:"
echo ""
terraform output -json deployment_summary 2>/dev/null | jq -r '.' || terraform output deployment_summary

echo ""
echo "🔗 Enlaces rápidos:"
terraform output -json quick_access 2>/dev/null | jq -r 'to_entries[] | "  \(.key): \(.value)"' || echo "  (usa: terraform output quick_access)"

echo ""
print_info "Todos los outputs:"
terraform output

echo ""
echo "⏱️  Si usas CloudFront, espera 5-10 minutos para que se propague"
echo ""

cd ..

