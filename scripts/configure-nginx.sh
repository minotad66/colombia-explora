#!/bin/bash

# Script para configurar Nginx como reverse proxy
# Ejecutar DESPUÉS de aws-deploy.sh

set -e

echo "🌐 Configurando Nginx Reverse Proxy"
echo "===================================="
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

# Obtener IP pública
PUBLIC_IP=$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)

# Instalar Nginx
echo "📦 Instalando Nginx..."
sudo apt-get update -qq
sudo apt-get install nginx -y -qq
print_success "Nginx instalado"

# Crear configuración
echo "⚙️  Creando configuración de Nginx..."
sudo tee /etc/nginx/sites-available/explora > /dev/null << EOF
server {
    listen 80;
    server_name ${PUBLIC_IP};

    # Frontend - Ruta principal
    location / {
        proxy_pass http://localhost:4200;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_cache_bypass \$http_upgrade;
    }

    # API - Ruta /api
    location /api/ {
        rewrite ^/api/(.*) /\$1 break;
        proxy_pass http://localhost:8000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_cache_bypass \$http_upgrade;
    }

    # Auth - Ruta /auth
    location /auth/ {
        rewrite ^/auth/(.*) /\$1 break;
        proxy_pass http://localhost:8001;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_cache_bypass \$http_upgrade;
    }

    # Acceso directo a documentación API
    location /docs {
        proxy_pass http://localhost:8000/docs;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_cache_bypass \$http_upgrade;
    }

    # Acceso directo a documentación Auth
    location /auth-docs {
        proxy_pass http://localhost:8001/docs;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_cache_bypass \$http_upgrade;
    }
}
EOF

print_success "Configuración creada"

# Activar el sitio
echo "🔗 Activando configuración..."
sudo ln -sf /etc/nginx/sites-available/explora /etc/nginx/sites-enabled/
sudo rm -f /etc/nginx/sites-enabled/default

# Verificar configuración
echo "✅ Verificando configuración de Nginx..."
if sudo nginx -t; then
    print_success "Configuración válida"
else
    print_error "Error en la configuración de Nginx"
    exit 1
fi

# Reiniciar Nginx
echo "🔄 Reiniciando Nginx..."
sudo systemctl restart nginx
sudo systemctl enable nginx
print_success "Nginx reiniciado y habilitado"

echo ""
echo "===================================="
echo "✅ ¡NGINX CONFIGURADO!"
echo "===================================="
echo ""
echo "🌐 Ahora puedes acceder a:"
echo "   Frontend: http://${PUBLIC_IP}"
echo "   API Docs: http://${PUBLIC_IP}/docs"
echo "   Auth Docs: http://${PUBLIC_IP}/auth-docs"
echo ""
echo "📝 Rutas configuradas:"
echo "   /       → Frontend (Angular)"
echo "   /api/*  → API Backend"
echo "   /auth/* → Auth Service"
echo "   /docs   → API Documentation"
echo ""
echo "💡 Comandos útiles:"
echo "   Verificar Nginx: sudo nginx -t"
echo "   Reiniciar Nginx: sudo systemctl restart nginx"
echo "   Ver logs Nginx: sudo tail -f /var/log/nginx/error.log"
echo "   Ver estado: sudo systemctl status nginx"
echo ""

print_success "¡Todo listo!"
