#!/bin/bash

# Script para empaquetar Lambda Functions para AWS
# Crea archivos .zip con todas las dependencias

set -e

echo "📦 Empaquetando Lambda Functions para AWS..."
echo "============================================"
echo ""

# Colores
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

# Verificar que estamos en el directorio correcto
if [ ! -d "auth" ] || [ ! -d "api" ]; then
    echo "❌ Error: Ejecuta este script desde la raíz del proyecto"
    exit 1
fi

# Limpiar empaquetados anteriores
echo "🧹 Limpiando empaquetados anteriores..."
rm -rf auth/lambda_package auth/auth-lambda.zip
rm -rf api/lambda_package api/api-lambda.zip
print_success "Limpieza completada"

# === AUTH SERVICE ===
echo ""
echo "📦 Empaquetando Auth Service..."
cd auth

# Crear directorio temporal
mkdir -p lambda_package
cd lambda_package

# Instalar dependencias
echo "  → Instalando dependencias..."
pip3 install -r ../requirements.txt -t . -q --upgrade
pip3 install mangum==0.17.0 -t . -q

# Copiar código de la aplicación
echo "  → Copiando código de aplicación..."
cp -r ../app ./
cp ../lambda_handler.py ./

# Crear zip
echo "  → Creando archivo ZIP..."
zip -r ../auth-lambda.zip . -q

# Limpiar
cd ..
rm -rf lambda_package

# Mostrar tamaño
SIZE=$(du -h auth-lambda.zip | cut -f1)
print_success "auth-lambda.zip creado (${SIZE})"

cd ..

# === API SERVICE ===
echo ""
echo "📦 Empaquetando API Service..."
cd api

# Crear directorio temporal
mkdir -p lambda_package
cd lambda_package

# Instalar dependencias
echo "  → Instalando dependencias..."
pip3 install -r ../requirements.txt -t . -q --upgrade
pip3 install mangum==0.17.0 -t . -q

# Copiar código de la aplicación
echo "  → Copiando código de aplicación..."
cp -r ../app ./
cp ../lambda_handler.py ./

# Crear zip
echo "  → Creando archivo ZIP..."
zip -r ../api-lambda.zip . -q

# Limpiar
cd ..
rm -rf lambda_package

# Mostrar tamaño
SIZE=$(du -h api-lambda.zip | cut -f1)
print_success "api-lambda.zip creado (${SIZE})"

cd ..

echo ""
echo "============================================"
echo "✅ Empaquetado completado exitosamente!"
echo "============================================"
echo ""
echo "📦 Archivos creados:"
echo "   auth/auth-lambda.zip"
echo "   api/api-lambda.zip"
echo ""
echo "📤 Siguiente paso:"
echo "   1. Ve a AWS Lambda Console"
echo "   2. Crea/actualiza las funciones Lambda"
echo "   3. Sube los archivos .zip correspondientes"
echo ""
echo "💡 O usa AWS CLI:"
echo "   aws lambda update-function-code --function-name explora-auth --zip-file fileb://auth/auth-lambda.zip"
echo "   aws lambda update-function-code --function-name explora-api --zip-file fileb://api/api-lambda.zip"
echo ""
