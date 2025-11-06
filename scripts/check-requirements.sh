#!/bin/bash

# Script para verificar requisitos antes del despliegue

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

print_success() { echo -e "${GREEN}✅ $1${NC}"; }
print_warning() { echo -e "${YELLOW}⚠️  $1${NC}"; }
print_error() { echo -e "${RED}❌ $1${NC}"; }
print_info() { echo -e "${BLUE}ℹ️  $1${NC}"; }

echo "============================================"
echo "🔍 Verificando Requisitos para Despliegue"
echo "============================================"
echo ""

ALL_OK=true

# Terraform
if command -v terraform &> /dev/null; then
    print_success "Terraform: $(terraform version | head -n1 | awk '{print $2}')"
else
    print_error "Terraform no está instalado"
    echo "  Instala: https://www.terraform.io/downloads"
    echo "  macOS: brew install terraform"
    ALL_OK=false
fi

# AWS CLI
if command -v aws &> /dev/null; then
    print_success "AWS CLI: $(aws --version | awk '{print $1}')"
    
    # Verificar credenciales
    if aws sts get-caller-identity &> /dev/null; then
        AWS_ACCOUNT=$(aws sts get-caller-identity --query Account --output text)
        print_success "AWS Credentials: Configuradas (Account: $AWS_ACCOUNT)"
    else
        print_warning "AWS CLI instalado pero credenciales no configuradas"
        echo "  Ejecuta: aws configure"
        echo "  Necesitas: Access Key ID y Secret Access Key"
        ALL_OK=false
    fi
else
    print_error "AWS CLI no está instalado"
    echo ""
    echo "📦 Instalación AWS CLI (macOS):"
    echo "  curl \"https://awscli.amazonaws.com/AWSCLIV2.pkg\" -o \"AWSCLIV2.pkg\""
    echo "  sudo installer -pkg AWSCLIV2.pkg -target /"
    echo ""
    echo "  O con Homebrew:"
    echo "  brew install awscli"
    echo ""
    echo "📦 Instalación AWS CLI (Linux):"
    echo "  curl \"https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip\" -o \"awscliv2.zip\""
    echo "  unzip awscliv2.zip"
    echo "  sudo ./aws/install"
    echo ""
    ALL_OK=false
fi

# Node.js
if command -v node &> /dev/null; then
    NODE_VERSION=$(node --version)
    print_success "Node.js: $NODE_VERSION"
    
    # Verificar versión mínima
    NODE_MAJOR=$(echo $NODE_VERSION | cut -d. -f1 | sed 's/v//')
    if [ "$NODE_MAJOR" -ge 16 ]; then
        print_success "Node.js versión OK (>= 16)"
    else
        print_warning "Node.js versión $NODE_VERSION (se recomienda >= 16)"
    fi
else
    print_error "Node.js no está instalado"
    echo "  Instala: https://nodejs.org/"
    echo "  macOS: brew install node"
    ALL_OK=false
fi

# npm
if command -v npm &> /dev/null; then
    print_success "npm: $(npm --version)"
else
    print_error "npm no está instalado"
    echo "  npm viene con Node.js"
    ALL_OK=false
fi

# Python
if command -v python3 &> /dev/null; then
    print_success "Python: $(python3 --version)"
else
    print_error "Python 3 no está instalado"
    echo "  Instala Python 3"
    ALL_OK=false
fi

# zip
if command -v zip &> /dev/null; then
    print_success "zip: $(zip --version | head -n1)"
else
    print_error "zip no está instalado"
    echo "  macOS: ya viene instalado"
    echo "  Linux: sudo apt-get install zip"
    ALL_OK=false
fi

echo ""

if [ "$ALL_OK" = true ]; then
    print_success "¡Todos los requisitos están instalados!"
    echo ""
    echo "🚀 Puedes proceder con el despliegue:"
    echo "   ./scripts/setup-aws-deploy.sh"
else
    print_error "Faltan algunos requisitos. Por favor instálalos primero."
    echo ""
    echo "📚 Ver: INSTRUCCIONES-DESPLIEGUE.md para más detalles"
fi

