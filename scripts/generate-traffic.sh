#!/bin/bash

# Script para generar tráfico a la aplicación y generar métricas en CloudWatch
# Uso: ./scripts/generate-traffic.sh

API_URL="https://g9hafoviz0.execute-api.us-east-1.amazonaws.com"
FRONTEND_URL="https://d6l09qihyu4pn.cloudfront.net"

echo "🚀 Generando tráfico a la aplicación..."
echo "📊 API Gateway: $API_URL"
echo "🌐 Frontend: $FRONTEND_URL"
echo ""

# Función para hacer requests
make_request() {
    local endpoint=$1
    local method=${2:-GET}
    local data=${3:-""}
    
    if [ "$method" = "POST" ]; then
        curl -s -X POST "$API_URL$endpoint" \
            -H "Content-Type: application/json" \
            -d "$data" \
            -w "\nHTTP Status: %{http_code}\n" \
            -o /dev/null
    else
        curl -s -X GET "$API_URL$endpoint" \
            -w "\nHTTP Status: %{http_code}\n" \
            -o /dev/null
    fi
}

# Esperar a que RDS esté listo (puede tardar unos minutos)
echo "⏳ Esperando a que la base de datos esté lista..."
sleep 30

# 1. Health checks
echo "1️⃣ Health Checks..."
for i in {1..5}; do
    echo "  → Health API ($i/5)"
    make_request "/api/health"
    sleep 1
    echo "  → Health Auth ($i/5)"
    make_request "/auth/health"
    sleep 1
done

# 2. Login como admin
echo ""
echo "2️⃣ Autenticación..."
echo "  → Login como admin..."
LOGIN_RESPONSE=$(curl -s -X POST "$API_URL/auth/token" \
    -H "Content-Type: application/json" \
    -d '{"username":"admin","password":"admin123"}')

TOKEN=$(echo $LOGIN_RESPONSE | jq -r '.access_token // empty')

if [ -z "$TOKEN" ] || [ "$TOKEN" = "null" ]; then
    echo "  ⚠️  No se pudo obtener token, intentando crear usuario admin..."
    # Intentar crear usuario admin si no existe
    curl -s -X POST "$API_URL/auth/register" \
        -H "Content-Type: application/json" \
        -d '{"username":"admin","email":"admin@explora.com","password":"admin123"}' > /dev/null
    
    # Intentar login de nuevo
    sleep 2
    LOGIN_RESPONSE=$(curl -s -X POST "$API_URL/auth/token" \
        -H "Content-Type: application/json" \
        -d '{"username":"admin","password":"admin123"}')
    TOKEN=$(echo $LOGIN_RESPONSE | jq -r '.access_token // empty')
fi

if [ -n "$TOKEN" ] && [ "$TOKEN" != "null" ]; then
    echo "  ✅ Token obtenido"
    
    # 3. Obtener destinos
    echo ""
    echo "3️⃣ Consultando destinos..."
    for i in {1..10}; do
        echo "  → GET /api/destinations ($i/10)"
        make_request "/api/destinations" "GET"
        sleep 1
    done
    
    # 4. Crear destinos de ejemplo (si es admin)
    echo ""
    echo "4️⃣ Creando destinos de ejemplo..."
    DESTINATIONS=(
        '{"name":"Valle del Cocora","description":"Hermoso valle con palmas de cera","region":"Quindío","price":150000}'
        '{"name":"Salento","description":"Pueblo cafetero tradicional","region":"Quindío","price":120000}'
        '{"name":"Termales de Santa Rosa","description":"Aguas termales relajantes","region":"Risaralda","price":200000}'
        '{"name":"Parque Nacional Natural Los Nevados","description":"Parque natural con nevados","region":"Tolima","price":180000}'
        '{"name":"Manizales","description":"Capital cafetera de Colombia","region":"Caldas","price":130000}'
        '{"name":"Pereira","description":"Ciudad del eje cafetero","region":"Risaralda","price":140000}'
    )
    
    for dest in "${DESTINATIONS[@]}"; do
        echo "  → POST /api/destinations"
        curl -s -X POST "$API_URL/api/destinations" \
            -H "Content-Type: application/json" \
            -H "Authorization: Bearer $TOKEN" \
            -d "$dest" \
            -w "\nHTTP Status: %{http_code}\n" \
            -o /dev/null
        sleep 1
    done
    
    # 5. Consultar destinos múltiples veces
    echo ""
    echo "5️⃣ Generando tráfico continuo (30 requests)..."
    for i in {1..30}; do
        make_request "/api/destinations" "GET"
        if [ $((i % 5)) -eq 0 ]; then
            echo "  → $i/30 requests completadas"
        fi
        sleep 0.5
    done
    
    # 6. Crear reservas
    echo ""
    echo "6️⃣ Creando reservas..."
    for i in {1..5}; do
        RESERVATION='{"destination_id":1,"people":2,"check_in":"2025-12-01","check_out":"2025-12-03"}'
        echo "  → POST /api/reservations ($i/5)"
        curl -s -X POST "$API_URL/api/reservations" \
            -H "Content-Type: application/json" \
            -H "Authorization: Bearer $TOKEN" \
            -d "$RESERVATION" \
            -w "\nHTTP Status: %{http_code}\n" \
            -o /dev/null
        sleep 1
    done
    
    # 7. Consultar reservas
    echo ""
    echo "7️⃣ Consultando reservas..."
    for i in {1..5}; do
        echo "  → GET /api/reservations ($i/5)"
        curl -s -X GET "$API_URL/api/reservations" \
            -H "Authorization: Bearer $TOKEN" \
            -w "\nHTTP Status: %{http_code}\n" \
            -o /dev/null
        sleep 1
    done
    
else
    echo "  ⚠️  No se pudo autenticar, generando tráfico sin autenticación..."
    # Generar tráfico básico sin autenticación
    for i in {1..20}; do
        make_request "/api/health"
        make_request "/auth/health"
        sleep 1
    done
fi

echo ""
echo "✅ Tráfico generado exitosamente!"
echo ""
echo "📊 Espera 2-3 minutos y luego revisa los dashboards de CloudWatch:"
echo "   Main Dashboard: https://us-east-1.console.aws.amazon.com/cloudwatch/home?region=us-east-1#dashboards:name=colombia-explora-main-dashboard"
echo "   Lambda API: https://us-east-1.console.aws.amazon.com/cloudwatch/home?region=us-east-1#dashboards:name=colombia-explora-lambda-api"
echo "   Lambda Auth: https://us-east-1.console.aws.amazon.com/cloudwatch/home?region=us-east-1#dashboards:name=colombia-explora-lambda-auth"
echo ""

