# 🚀 SGAD - Quick Start Guide

Guía rápida para levantar toda la infraestructura de SGAD en minutos.

---

## Prerequisitos

✅ Docker y Docker Compose instalados  
✅ Todos los repos de SGAD clonados en el mismo directorio padre

---

## 3 Pasos para Iniciar

### 1️⃣ Configurar Entorno

```bash
cd sgad-infraestructure
cp env.template .env
```

Edita `.env` y cambia las contraseñas por valores seguros:
- `POSTGRES_PASSWORD`
- `MONGO_PASSWORD`
- `REDIS_PASSWORD`
- `JWT_SECRET` (mínimo 32 caracteres)

### 2️⃣ Construir Imágenes

```bash
./build-images.sh
```

Este comando construye las imágenes Docker de todos los servicios (~5-10 minutos).

### 3️⃣ Levantar Todo

```bash
docker-compose up -d
```

---

## ✅ Verificar

```bash
docker-compose ps
```

Todos los servicios deben estar en estado `running` o `healthy`.

---

## 🌐 Acceder a los Servicios

- **Frontend Web:** http://localhost:3000
- **API Gateway:** http://localhost:8080
- **Auth Service:** http://localhost:3001

---

## 🛑 Detener Todo

```bash
docker-compose down
```

---

## 📋 Comandos Útiles

```bash
# Ver logs en tiempo real
docker-compose logs -f

# Ver logs de un servicio específico
docker-compose logs -f frontend
docker-compose logs -f api-gateway

# Reiniciar un servicio
docker-compose restart auth-service

# Ver estado de servicios
docker-compose ps

# Reconstruir un servicio específico
docker-compose up -d --build frontend
```

---

## ⚠️ Problemas Comunes

### "Image not found"
```bash
./build-images.sh
```

### "Port already in use"
Verifica qué proceso usa el puerto y detenlo, o cambia el puerto en `docker-compose.yml`.

### "Cannot connect to database"
```bash
docker-compose logs postgres
docker-compose logs mongodb
```

Verifica que los servicios de base de datos estén `healthy`.

---

## 🔄 Actualizar Servicios

Cuando hagas cambios en el código de algún servicio:

```bash
# 1. Reconstruir la imagen del servicio actualizado
cd ../sgad-auth-service  # o el servicio que modificaste
docker build -t sgad-auth-service:latest .

# 2. Reiniciar solo ese servicio
cd ../sgad-infraestructure
docker-compose up -d auth-service
```

---

## 📚 Más Información

Lee el [README.md](README.md) completo para documentación detallada.

---

