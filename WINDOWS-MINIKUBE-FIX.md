# 🪟 Guía de Solución: Minikube en Windows

## 🔴 Problema
Después de ejecutar `minikube ip` y abrir esa IP en el navegador, la página no carga.

## ❓ ¿Por qué pasa esto?
En Windows, Minikube corre dentro de una VM (VirtualBox, Hyper-V, o Docker Desktop). La IP que da `minikube ip` es interna a esa VM y **no es directamente accesible** desde el navegador de Windows.

---

## ✅ SOLUCIÓN 1: `minikube tunnel` (RECOMENDADA)

### Paso a paso:

1. **Abrir PowerShell o CMD como Administrador**
   - Busca "PowerShell" en el menú inicio
   - Click derecho → "Ejecutar como Administrador"

2. **Ejecutar el tunnel:**
   ```powershell
   minikube tunnel
   ```

3. **Verás algo como:**
   ```
   Status:
       machine: minikube
       pid: 12345
       route: 10.96.0.0/12 -> 192.168.49.2
       minikube: Running
       services: [frontend-service]
       errors: none
   ```

4. **Dejar esa terminal ABIERTA** (no cerrarla)

5. **Abrir el navegador y acceder a:**
   ```
   http://localhost
   ```
   O verificar con:
   ```powershell
   kubectl get ingress -n explora
   ```

### ⚠️ Importante:
- El tunnel debe estar corriendo mientras uses la app
- Si cierras la terminal, debes volver a ejecutar `minikube tunnel`
- Puede pedir contraseña de administrador

---

## ✅ SOLUCIÓN 2: `minikube service` (MÁS FÁCIL)

### Paso a paso:

1. **Abrir PowerShell o CMD (sin ser administrador)**

2. **Ejecutar:**
   ```powershell
   minikube service frontend-service -n explora
   ```

3. **Automáticamente:**
   - Se abrirá el navegador con la URL correcta
   - Verás la aplicación funcionando
   - La terminal mostrará la URL (ejemplo: `http://127.0.0.1:54321`)

### 💡 Ventaja:
- No necesitas ser administrador
- Abre el navegador automáticamente
- Crea el port-forward por ti

---

## ✅ SOLUCIÓN 3: Port Forward Manual

### Paso a paso:

1. **Abrir PowerShell o CMD**

2. **Ver los servicios disponibles:**
   ```powershell
   kubectl get services -n explora
   ```

3. **Port-forward del frontend:**
   ```powershell
   kubectl port-forward -n explora service/frontend-service 4200:80
   ```

4. **Abrir navegador en:**
   ```
   http://localhost:4200
   ```

5. **Si quieres ver API también (en otra terminal):**
   ```powershell
   kubectl port-forward -n explora service/api-service 8000:8000
   ```

---

## 🔧 SOLUCIÓN 4: Cambiar Driver de Minikube

Si nada funciona, el problema puede ser el driver.

### Drivers recomendados para Windows:

1. **Docker Desktop** (mejor opción)
2. **Hyper-V** (requiere Windows Pro)
3. **VirtualBox** (última opción)

### Cambiar a Docker Desktop:

1. **Instalar Docker Desktop**
   - Descargar de: https://www.docker.com/products/docker-desktop/
   - Instalar y reiniciar Windows

2. **Eliminar Minikube actual:**
   ```powershell
   minikube delete
   ```

3. **Iniciar con driver Docker:**
   ```powershell
   minikube start --driver=docker
   ```

4. **Verificar:**
   ```powershell
   minikube status
   ```

---

## 🧪 Verificar que funciona

### Comandos de diagnóstico:

```powershell
# 1. Ver estado de Minikube
minikube status

# 2. Ver pods corriendo
kubectl get pods -n explora

# 3. Ver servicios
kubectl get services -n explora

# 4. Ver ingress (si usas minikube tunnel)
kubectl get ingress -n explora

# 5. Ver logs si hay problemas
kubectl logs -l app=frontend -n explora
```

---

## 📊 Comparación de Soluciones

| Solución | Facilidad | Requiere Admin | Persistente | Recomendación |
|----------|-----------|----------------|-------------|---------------|
| `minikube tunnel` | ⭐⭐⭐ | ✅ Sí | Solo mientras esté abierto | Para uso con Ingress |
| `minikube service` | ⭐⭐⭐⭐⭐ | ❌ No | Solo mientras esté abierto | **MÁS FÁCIL** |
| `kubectl port-forward` | ⭐⭐⭐⭐ | ❌ No | Solo mientras esté abierto | Para desarrollo |
| Cambiar driver | ⭐⭐ | ✅ Sí | ✅ Sí | Si otras fallan |

---

## 🎯 Recomendación Final

### **Para ver la aplicación YA:**
```powershell
minikube service frontend-service -n explora
```

### **Para usar Ingress (acceso en localhost):**
1. Abrir PowerShell como Administrador
2. Ejecutar: `minikube tunnel`
3. Dejar abierto
4. Ir a: `http://localhost`

---

## 🆘 Si nada funciona

### Alternativa: Usar Docker Compose en vez de Kubernetes

En Windows, Docker Compose es más sencillo:

```powershell
# En la carpeta del proyecto
docker-compose up -d

# Abrir navegador en:
# http://localhost:4200
```

Esto es mucho más simple en Windows y no requiere Minikube.

---

## 📚 Recursos adicionales

- [Minikube Tunnel Documentation](https://minikube.sigs.k8s.io/docs/handbook/accessing/)
- [Minikube Windows Troubleshooting](https://minikube.sigs.k8s.io/docs/drivers/hyperv/)
- [Docker Desktop para Windows](https://docs.docker.com/desktop/install/windows-install/)

---

## ✅ Checklist de solución:

- [ ] Probé `minikube service frontend-service -n explora`
- [ ] Probé `minikube tunnel` como administrador
- [ ] Verifiqué que los pods estén corriendo con `kubectl get pods -n explora`
- [ ] Probé con Docker Compose como alternativa
- [ ] Si nada funciona, cambié el driver a Docker Desktop

---

**¡Suerte! 🚀**
