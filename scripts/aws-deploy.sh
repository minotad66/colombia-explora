#!/bin/bash

# Script de despliegue automático para AWS EC2
# Este script debe ejecutarse EN LA INSTANCIA EC2 después de conectarte por SSH

set -e

echo "🚀 Script de Despliegue - Colombia Explora en AWS"
echo "================================================"
echo ""

# Colores para output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Función para imprimir con color
print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Verificar que estamos en Ubuntu/Debian
if ! command -v apt-get &> /dev/null; then
    print_error "Este script solo funciona en sistemas basados en Debian/Ubuntu"
    exit 1
fi

# Paso 1: Actualizar sistema
echo "📦 Paso 1/7: Actualizando sistema..."
sudo apt-get update -qq
sudo apt-get upgrade -y -qq
print_success "Sistema actualizado"

# Paso 2: Instalar Docker
echo "🐳 Paso 2/7: Instalando Docker..."
if ! command -v docker &> /dev/null; then
    curl -fsSL https://get.docker.com -o get-docker.sh
    sudo sh get-docker.sh
    sudo usermod -aG docker $USER
    rm get-docker.sh
    print_success "Docker instalado"
else
    print_warning "Docker ya está instalado"
fi

# Paso 3: Instalar Docker Compose
echo "🐳 Paso 3/7: Instalando Docker Compose..."
if ! docker compose version &> /dev/null; then
    sudo apt-get install docker-compose-plugin -y -qq
    print_success "Docker Compose instalado"
else
    print_warning "Docker Compose ya está instalado"
fi

# Paso 4: Instalar Git
echo "📥 Paso 4/7: Instalando Git..."
if ! command -v git &> /dev/null; then
    sudo apt-get install git -y -qq
    print_success "Git instalado"
else
    print_warning "Git ya está instalado"
fi

# Paso 5: Clonar repositorio
echo "📂 Paso 5/7: Clonando repositorio..."
if [ ! -d "colombia-explora" ]; then
    git clone https://github.com/SebaxtriUTP/colombia-explora.git
    cd colombia-explora
    print_success "Repositorio clonado"
else
    print_warning "Repositorio ya existe, actualizando..."
    cd colombia-explora
    git pull
fi

# Paso 6: Configurar variables de entorno
echo "⚙️  Paso 6/7: Configurando variables de entorno..."

# Obtener IP pública de la instancia
PUBLIC_IP=$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)

if [ -f ".env.production" ]; then
    print_warning "Archivo .env.production ya existe"
    read -p "¿Quieres sobrescribirlo? (y/n): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_warning "Manteniendo configuración existente"
        SKIP_ENV=true
    fi
fi

if [ "$SKIP_ENV" != "true" ]; then
    # Generar secretos aleatorios
    POSTGRES_PASSWORD=$(openssl rand -hex 16)
    JWT_SECRET=$(openssl rand -hex 32)

    cat > .env.production << EOF
# PostgreSQL
POSTGRES_USER=explora_user
POSTGRES_PASSWORD=${POSTGRES_PASSWORD}
POSTGRES_DB=explora_db

# JWT
JWT_SECRET=${JWT_SECRET}

# URLs
API_URL=http://${PUBLIC_IP}:8000
AUTH_URL=http://${PUBLIC_IP}:8001
FRONTEND_URL=http://${PUBLIC_IP}:4200
EOF

    print_success "Variables de entorno configuradas"
    echo ""
    print_warning "GUARDA ESTAS CREDENCIALES:"
    echo "PostgreSQL Password: ${POSTGRES_PASSWORD}"
    echo "JWT Secret: ${JWT_SECRET}"
    echo "IP Pública: ${PUBLIC_IP}"
    echo ""
fi

# Paso 7: Crear docker-compose.prod.yml si no existe
if [ ! -f "docker-compose.prod.yml" ]; then
    print_warning "Creando docker-compose.prod.yml..."
    cat > docker-compose.prod.yml << 'EOF'
version: '3.8'

services:
  postgres:
    image: postgres:15-alpine
    container_name: explora_postgres
    environment:
      POSTGRES_USER: ${POSTGRES_USER:-explora_user}
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD:-explora_pass}
      POSTGRES_DB: ${POSTGRES_DB:-explora_db}
    volumes:
      - ./data/postgres:/var/lib/postgresql/data
    networks:
      - explora_net
    healthcheck:
      test: [ "CMD-SHELL", "pg_isready -U ${POSTGRES_USER:-explora_user} -d ${POSTGRES_DB:-explora_db}" ]
      interval: 5s
      timeout: 5s
      retries: 5
    restart: always

  auth:
    build: ./auth
    container_name: explora_auth
    depends_on:
      postgres:
        condition: service_healthy
    environment:
      - DATABASE_URL=postgresql+asyncpg://${POSTGRES_USER:-explora_user}:${POSTGRES_PASSWORD:-explora_pass}@postgres/${POSTGRES_DB:-explora_db}
      - JWT_SECRET=${JWT_SECRET:-devsecret}
    ports:
      - "8001:8001"
    networks:
      - explora_net
    restart: always

  api:
    build: ./api
    container_name: explora_api
    depends_on:
      postgres:
        condition: service_healthy
      auth:
        condition: service_started
    environment:
      - DATABASE_URL=postgresql+asyncpg://${POSTGRES_USER:-explora_user}:${POSTGRES_PASSWORD:-explora_pass}@postgres/${POSTGRES_DB:-explora_db}
      - AUTH_URL=http://auth:8001
      - JWT_SECRET=${JWT_SECRET:-devsecret}
    ports:
      - "8000:8000"
    networks:
      - explora_net
    restart: always

  frontend:
    build: ./frontend
    container_name: explora_frontend
    ports:
      - "4200:80"
      - "80:80"
    depends_on:
      api:
        condition: service_started
    networks:
      - explora_net
    restart: always

networks:
  explora_net:
    driver: bridge
EOF
    print_success "docker-compose.prod.yml creado"
fi

# Paso 8: Construir y desplegar
echo "🚀 Paso 7/7: Construyendo y desplegando aplicación..."

# Cargar variables de entorno
export $(cat .env.production | grep -v '^#' | xargs)

# Detener contenedores existentes si existen
if docker compose -f docker-compose.prod.yml ps | grep -q "Up"; then
    print_warning "Deteniendo contenedores existentes..."
    docker compose -f docker-compose.prod.yml down
fi

# Construir e iniciar
print_warning "Construyendo imágenes (esto puede tomar varios minutos)..."
docker compose -f docker-compose.prod.yml up -d --build

print_success "Aplicación desplegada!"

echo ""
echo "================================================"
echo "✅ ¡DESPLIEGUE COMPLETADO!"
echo "================================================"
echo ""
echo "🌐 Accede a tu aplicación en:"
echo "   Frontend: http://${PUBLIC_IP}:4200"
echo "   API Docs: http://${PUBLIC_IP}:8000/docs"
echo "   Auth Docs: http://${PUBLIC_IP}:8001/docs"
echo ""
echo "📊 Comandos útiles:"
echo "   Ver logs: docker compose -f docker-compose.prod.yml logs -f"
echo "   Ver estado: docker compose -f docker-compose.prod.yml ps"
echo "   Reiniciar: docker compose -f docker-compose.prod.yml restart"
echo "   Detener: docker compose -f docker-compose.prod.yml down"
echo ""
echo "⚠️  IMPORTANTE:"
echo "   - Guarda las credenciales mostradas arriba"
echo "   - Configura las reglas del Security Group en AWS"
echo "   - Considera configurar Nginx para acceso en puerto 80"
echo ""

# Mostrar estado final
echo "📊 Estado de los contenedores:"
docker compose -f docker-compose.prod.yml ps

echo ""
print_success "¡Listo! Tu aplicación debería estar corriendo."
