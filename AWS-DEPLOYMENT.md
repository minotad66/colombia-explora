# 🚀 Despliegue en AWS Free Tier

## 📋 Requisitos Previos

- ✅ Cuenta de AWS (Free Tier activo primer año)
- ✅ Proyecto Colombia Explora (este repositorio)
- ✅ Conocimientos básicos de terminal

---

## 🎯 OPCIÓN 1: EC2 + Docker Compose (RECOMENDADA)

### Paso 1: Crear Instancia EC2

#### 1.1 Ir a AWS Console
1. Inicia sesión en https://console.aws.amazon.com
2. Busca "EC2" en la barra de búsqueda
3. Click en "Launch Instance" (Lanzar Instancia)

#### 1.2 Configurar la Instancia
```
Nombre: explora-app
AMI: Ubuntu Server 22.04 LTS (Free tier eligible)
Tipo de instancia: t2.micro (Free tier eligible)
Par de claves: Crear nuevo par (descarga el archivo .pem)
Nombre del par: explora-key.pem
```

#### 1.3 Configurar Grupo de Seguridad
Crear un nuevo grupo de seguridad con estas reglas:

| Tipo | Puerto | Origen | Descripción |
|------|--------|--------|-------------|
| SSH | 22 | Tu IP | Acceso SSH |
| HTTP | 80 | 0.0.0.0/0 | Frontend/Nginx |
| Custom TCP | 4200 | 0.0.0.0/0 | Frontend Angular |
| Custom TCP | 8000 | 0.0.0.0/0 | API FastAPI |
| Custom TCP | 8001 | 0.0.0.0/0 | Auth Service |

#### 1.4 Configurar Almacenamiento
```
Tamaño: 20 GB (puedes usar hasta 30 GB en Free Tier)
Tipo: gp3 (General Purpose SSD)
```

#### 1.5 Lanzar Instancia
- Click en "Launch Instance"
- Descarga el archivo `.pem` de la clave (¡IMPORTANTE! No lo pierdas)

---

### Paso 2: Conectar a la Instancia EC2

#### 2.1 Obtener IP Pública
1. En EC2 Dashboard, selecciona tu instancia
2. Copia la "Public IPv4 address" (ejemplo: 54.123.45.67)

#### 2.2 Configurar Permisos de la Clave
```bash
# En tu máquina local
chmod 400 ~/Downloads/explora-key.pem
```

#### 2.3 Conectar por SSH
```bash
ssh -i ~/Downloads/explora-key.pem ubuntu@TU_IP_PUBLICA

# Ejemplo:
# ssh -i ~/Downloads/explora-key.pem ubuntu@54.123.45.67
```

---

### Paso 3: Instalar Docker y Docker Compose en EC2

Una vez conectado a la instancia, ejecuta:

```bash
# Actualizar sistema
sudo apt-get update
sudo apt-get upgrade -y

# Instalar Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# Agregar usuario al grupo docker
sudo usermod -aG docker ubuntu

# IMPORTANTE: Cerrar sesión y volver a conectar
exit
# Volver a conectar con SSH
ssh -i ~/Downloads/explora-key.pem ubuntu@TU_IP_PUBLICA

# Verificar Docker
docker --version

# Instalar Docker Compose
sudo apt-get install docker-compose-plugin -y

# Verificar Docker Compose
docker compose version
```

---

### Paso 4: Clonar el Proyecto

```bash
# Instalar git si no está
sudo apt-get install git -y

# Clonar el repositorio
git clone https://github.com/SebaxtriUTP/colombia-explora.git

# Entrar al directorio
cd colombia-explora

# Ver los archivos
ls -la
```

---

### Paso 5: Configurar Variables de Entorno para Producción

Crear archivo de variables de entorno:

```bash
# Crear archivo .env.production
cat > .env.production << 'EOF'
# PostgreSQL
POSTGRES_USER=explora_user
POSTGRES_PASSWORD=CAMBIAR_ESTE_PASSWORD_SEGURO
POSTGRES_DB=explora_db

# JWT
JWT_SECRET=CAMBIAR_ESTE_SECRET_MUY_LARGO_Y_SEGURO

# URLs (reemplaza con tu IP pública de EC2)
API_URL=http://TU_IP_PUBLICA:8000
AUTH_URL=http://TU_IP_PUBLICA:8001
EOF

# Editar el archivo con tu IP
nano .env.production
```

---

### Paso 6: Modificar docker-compose.yml para Producción

Crear una versión de producción:

```bash
cp docker-compose.yml docker-compose.prod.yml
nano docker-compose.prod.yml
```

Modificar para agregar los puertos de PostgreSQL si necesitas acceso externo:

```yaml
services:
  postgres:
    image: postgres:15-alpine
    container_name: explora_postgres
    environment:
      POSTGRES_USER: ${POSTGRES_USER}
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD}
      POSTGRES_DB: ${POSTGRES_DB}
    volumes:
      - ./data/postgres:/var/lib/postgresql/data
    networks:
      - explora_net
    healthcheck:
      test: [ "CMD-SHELL", "pg_isready -U ${POSTGRES_USER} -d ${POSTGRES_DB}" ]
      interval: 5s
      timeout: 5s
      retries: 5
    # OPCIONAL: Si quieres acceso externo a PostgreSQL
    # ports:
    #   - "5432:5432"

  auth:
    build: ./auth
    container_name: explora_auth
    depends_on:
      postgres:
        condition: service_healthy
    environment:
      - DATABASE_URL=postgresql+asyncpg://${POSTGRES_USER}:${POSTGRES_PASSWORD}@postgres/${POSTGRES_DB}
      - JWT_SECRET=${JWT_SECRET}
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
      - DATABASE_URL=postgresql+asyncpg://${POSTGRES_USER}:${POSTGRES_PASSWORD}@postgres/${POSTGRES_DB}
      - AUTH_URL=http://auth:8001
      - JWT_SECRET=${JWT_SECRET}
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
      - "80:80"  # También en puerto 80 para acceso estándar
    depends_on:
      api:
        condition: service_started
    networks:
      - explora_net
    restart: always

networks:
  explora_net:
    driver: bridge
```

---

### Paso 7: Construir y Desplegar

```bash
# Cargar variables de entorno
export $(cat .env.production | xargs)

# Construir e iniciar los contenedores
docker compose -f docker-compose.prod.yml up -d --build

# Ver el progreso
docker compose -f docker-compose.prod.yml logs -f

# Verificar que todo esté corriendo
docker compose -f docker-compose.prod.yml ps
```

---

### Paso 8: Inicializar Datos (Opcional)

```bash
# Esperar a que todo esté corriendo (~2-3 minutos)
sleep 120

# Puedes crear un script de inicialización o insertar datos manualmente
# Conectar a PostgreSQL:
docker exec -it explora_postgres psql -U explora_user -d explora_db

# Dentro de psql, insertar datos de prueba:
# INSERT INTO destinations (name, description, ...) VALUES (...);
# \q para salir
```

---

### Paso 9: Acceder a la Aplicación

Abre tu navegador y ve a:

```
Frontend: http://TU_IP_PUBLICA:4200
API Docs: http://TU_IP_PUBLICA:8000/docs
Auth Docs: http://TU_IP_PUBLICA:8001/docs
```

---

## 🎯 OPCIÓN 2: Nginx Reverse Proxy (PROFESIONAL)

Para que la aplicación esté en el puerto 80 (sin :4200):

### Instalar Nginx

```bash
sudo apt-get install nginx -y
```

### Configurar Nginx

```bash
sudo nano /etc/nginx/sites-available/explora
```

Agregar:

```nginx
server {
    listen 80;
    server_name TU_IP_PUBLICA;

    # Frontend
    location / {
        proxy_pass http://localhost:4200;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
    }

    # API
    location /api/ {
        proxy_pass http://localhost:8000/;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
    }

    # Auth
    location /auth/ {
        proxy_pass http://localhost:8001/;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
    }
}
```

### Activar Nginx

```bash
sudo ln -s /etc/nginx/sites-available/explora /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl restart nginx
```

Ahora accede solo con: **http://TU_IP_PUBLICA**

---

## 🔒 SEGURIDAD (IMPORTANTE)

### 1. Cambiar Contraseñas
```bash
# Editar .env.production con contraseñas seguras
nano .env.production

# Regenerar secretos
openssl rand -hex 32  # Para JWT_SECRET
```

### 2. Configurar Firewall
```bash
sudo ufw allow 22/tcp    # SSH
sudo ufw allow 80/tcp    # HTTP
sudo ufw allow 443/tcp   # HTTPS (futuro)
sudo ufw enable
```

### 3. Actualizar Sistema Regularmente
```bash
sudo apt-get update && sudo apt-get upgrade -y
```

---

## 📊 Monitoreo

### Ver logs en tiempo real
```bash
docker compose -f docker-compose.prod.yml logs -f
```

### Ver estado de contenedores
```bash
docker compose -f docker-compose.prod.yml ps
```

### Ver uso de recursos
```bash
docker stats
```

---

## 🆘 Troubleshooting

### Contenedores no inician
```bash
# Ver logs
docker compose -f docker-compose.prod.yml logs

# Reiniciar servicios
docker compose -f docker-compose.prod.yml restart

# Reconstruir desde cero
docker compose -f docker-compose.prod.yml down
docker compose -f docker-compose.prod.yml up -d --build
```

### No puedo acceder desde el navegador
```bash
# Verificar que los puertos estén abiertos
sudo netstat -tulpn | grep -E '80|4200|8000|8001'

# Verificar grupo de seguridad en AWS
# Ve a EC2 → Security Groups → Tu grupo → Editar reglas de entrada
```

### PostgreSQL no inicia
```bash
# Ver logs de PostgreSQL
docker logs explora_postgres

# Limpiar datos y reiniciar
docker compose -f docker-compose.prod.yml down
sudo rm -rf data/postgres
docker compose -f docker-compose.prod.yml up -d
```

---

## 💰 Costos Estimados (Free Tier)

| Servicio | Límite Free Tier | Costo después |
|----------|------------------|---------------|
| EC2 t2.micro | 750 horas/mes (1 año) | ~$8/mes |
| EBS Storage | 30 GB | $3/mes por 100 GB |
| Transferencia | 15 GB salida/mes | $0.09/GB |

**Total primer año:** $0 (si estás dentro de los límites)
**Después del primer año:** ~$10-15/mes

---

## 🎓 Mejoras Futuras

1. **Dominio personalizado**: Comprar dominio y configurar Route 53
2. **HTTPS**: Configurar Let's Encrypt con Certbot
3. **CI/CD**: GitHub Actions para deploy automático
4. **Base de datos externa**: AWS RDS PostgreSQL (tiene Free Tier)
5. **CDN**: CloudFront para archivos estáticos
6. **Backups**: Snapshots automáticos de EBS

---

## 📚 Referencias

- [AWS Free Tier](https://aws.amazon.com/free/)
- [EC2 Documentation](https://docs.aws.amazon.com/ec2/)
- [Docker on Ubuntu](https://docs.docker.com/engine/install/ubuntu/)

---

¡Listo para desplegar! 🚀
