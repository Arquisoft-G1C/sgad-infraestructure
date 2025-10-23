# SGAD – Infrastructure

Infraestructura completa del **SGAD (Sistema de Gestión de Árbitros y Designaciones)**.  
Este repositorio contiene la orquestación completa de **todos los servicios** del sistema mediante Docker Compose.

---

## 📖 ¿Qué incluye?

### **🗄️ Bases de Datos (4 Databases)**
- **PostgreSQL users_db** (Port 5432) → Usuarios y autenticación
- **PostgreSQL referee_db** (Port 5433) → Árbitros, disponibilidad y tarifas
- **PostgreSQL match_db** (Port 5434) → Partidos, equipos y asignaciones
- **MongoDB certificados_db** (Port 27017) → Certificados, documentos y logs
- **Redis** (Port 6379) → Cache y colas de mensajes

### **📡 Message Broker**
- **RabbitMQ** (Ports 5672, 15672) → Event streaming para comunicación asíncrona y actualizaciones en tiempo real

### **🔧 Backend Services**
- **Auth Service** → Autenticación JWT (Node.js)
- **Referee Service** → Gestión de árbitros (Python + FastAPI)
- **Availability Service** → Disponibilidad de árbitros (Python + FastAPI)
- **Match Service** → Gestión de partidos (Python + FastAPI)

### **🌐 API Layer**
- **API Gateway** → Enrutamiento central (Spring Boot + Java)

### **🎨 Frontend**
- **Web Frontend** → Interfaz web (Next.js + React + TypeScript)

---

## 📂 Estructura del Proyecto

```
sgad-infrastructure/
├── docker-compose.yml           # Orquestación completa de servicios
├── env.template                 # Template de variables de entorno
├── build-images.sh              # Script para construir todas las imágenes
├── db/
│   ├── postgres/
│   │   ├── init-users.sql      # users_db initialization
│   │   ├── init-referee.sql    # referee_db initialization
│   │   └── init-match.sql      # match_db initialization
│   └── mongo/
│       └── init-certificados.js # certificados_db initialization
├── README.md
└── QUICK_START.md
```

---

## ⚙️ Requisitos

- **Docker** 20+  
- **Docker Compose** 2.0+  
- Todos los repositorios de SGAD clonados en el mismo directorio padre:
  ```
  SGAD/
  ├── sgad-api-gateway/
  ├── sgad-auth-service/
  ├── sgad-availability-service/
  ├── sgad-frontend/
  ├── sgad-infraestructure/     ← Estás aquí
  ├── sgad-match-management/
  └── sgad-referee-management/
  ```

---

## ▶️ ¿Cómo usar?

### **Paso 1: Configurar Variables de Entorno**

1. Copiar el template de configuración:
   ```bash
   cp env.template .env
   ```

2. Editar `.env` con tus credenciales:
   ```bash
   nano .env  # o usa tu editor favorito
   ```

   **⚠️ IMPORTANTE:** Cambiar todas las contraseñas por defecto en producción.

### **Paso 2: Construir las Imágenes Docker**

Desde el directorio de infraestructura, ejecutar:

```bash
./build-images.sh
```

Este script:
- Navega a cada repositorio de servicio
- Construye la imagen Docker correspondiente
- Etiqueta las imágenes con los nombres correctos

**Alternativa manual:** Construir cada servicio individualmente:
```bash
# Desde cada repositorio de servicio
cd ../sgad-auth-service && docker build -t sgad-auth-service:latest .
cd ../sgad-api-gateway && docker build -t sgad-api-gateway:latest .
cd ../sgad-referee-management && docker build -t sgad-referee-service:latest .
cd ../sgad-availability-service && docker build -t sgad-availability-service:latest .
cd ../sgad-match-management && docker build -t sgad-match-service:latest .
cd ../sgad-frontend && docker build -t sgad-frontend:latest .
```

### **Paso 3: Levantar la Infraestructura**

```bash
docker-compose up -d
```

### **Paso 4: Verificar que todo está corriendo**

```bash
docker-compose ps
```

Deberías ver todos los servicios en estado `running` o `healthy`.

---

## 🔑 Puertos y Servicios

| Servicio | Puerto | URL | Descripción |
|----------|--------|-----|-------------|
| **Frontend** | 3000 | http://localhost:3000 | Interfaz web |
| **Auth Service** | 3001 | http://localhost:3001 | Autenticación |
| **Referee Service** | 3004 | http://localhost:3004 | Gestión de árbitros |
| **Availability Service** | 8000 | http://localhost:8000 | Disponibilidad |
| **Match Service** | 8001 | http://localhost:8001 | Gestión de partidos |
| **API Gateway** | 8080 | http://localhost:8080 | Gateway principal |
| **PostgreSQL users_db** | 5432 | localhost:5432 | Base de datos usuarios |
| **PostgreSQL referee_db** | 5433 | localhost:5433 | Base de datos árbitros |
| **PostgreSQL match_db** | 5434 | localhost:5434 | Base de datos partidos |
| **MongoDB certificados_db** | 27017 | localhost:27017 | Base de datos documentos |
| **Redis** | 6379 | localhost:6379 | Cache y colas |
| **RabbitMQ (AMQP)** | 5672 | localhost:5672 | Message broker |
| **RabbitMQ Management** | 15672 | http://localhost:15672 | Admin UI |

---

## 🐳 Comandos Útiles

### Ver logs de todos los servicios
```bash
docker-compose logs -f
```

### Ver logs de un servicio específico
```bash
docker-compose logs -f auth-service
docker-compose logs -f api-gateway
docker-compose logs -f frontend
```

### Reiniciar un servicio específico
```bash
docker-compose restart auth-service
```

### Detener todo
```bash
docker-compose down
```

### Detener y eliminar volúmenes (⚠️ borra datos)
```bash
docker-compose down -v
```

### Ver estado de los servicios
```bash
docker-compose ps
```

### Reconstruir un servicio
```bash
docker-compose up -d --build frontend
```

---

## 🔧 Configuración de Servicios

### Variables de Entorno Principales

Las siguientes variables deben estar configuradas en tu archivo `.env`:

```env
# PostgreSQL - users_db
USERS_DB=users_db
USERS_DB_USER=sgad_user
USERS_DB_PASSWORD=your_secure_password

# PostgreSQL - referee_db
REFEREE_DB=referee_db
REFEREE_DB_USER=sgad_user
REFEREE_DB_PASSWORD=your_secure_password

# PostgreSQL - match_db
MATCH_DB=match_db
MATCH_DB_USER=sgad_user
MATCH_DB_PASSWORD=your_secure_password

# MongoDB - certificados_db
CERTIFICADOS_DB=certificados_db
CERTIFICADOS_DB_USER=sgad_mongo
CERTIFICADOS_DB_PASSWORD=your_secure_password

# Redis
REDIS_PASSWORD=your_secure_password

# Seguridad
JWT_SECRET=your_jwt_secret_key_min_32_chars
JWT_EXPIRATION=24h

# URLs
NEXT_PUBLIC_API_URL=http://localhost:8080
```

---

## 🔗 Arquitectura de Red

Todos los servicios están conectados en una red Docker llamada `sgad-network`, lo que permite:
- Comunicación entre servicios usando nombres de contenedor
- Aislamiento de la red externa
- Comunicación segura interna

Ejemplo de comunicación interna:
- El frontend llama a `http://api-gateway:8080`
- El API Gateway llama a `http://auth-service:3001`
- Los servicios acceden a bases de datos usando hostnames: `postgres`, `mongodb`, `redis`

---

## 🐛 Troubleshooting

### Problema: "Cannot connect to database"
```bash
# Verificar que las bases de datos estén healthy
docker-compose ps

# Ver logs de las bases de datos
docker-compose logs postgres-users
docker-compose logs postgres-referee
docker-compose logs postgres-match
docker-compose logs mongodb-certificados
```

### Problema: "Image not found"
```bash
# Reconstruir las imágenes
./build-images.sh

# Verificar que las imágenes existen
docker images | grep sgad-
```

### Problema: "Port already in use"
Cambiar los puertos en `docker-compose.yml`:
```yaml
ports:
  - "3001:3001"  # Cambiar a "3002:3001" si el puerto 3001 está ocupado
```

### Problema: Servicio no inicia
```bash
# Ver logs detallados
docker-compose logs <service-name>

# Verificar variables de entorno
docker-compose config
```

---

## 📡 Integración y Dependencias

```
Frontend (3000)
    ↓
API Gateway (8080)
    ↓
┌────┴────┬────────┬──────────┐
│         │        │          │
Auth    Referee  Avail.    Match
(3001)   (3004)  (8000)   (8001)
│         │  │     │          │
│         │  │     │          │
└─────────┼──┼─────┼──────────┘
          ↓  ↓     ↓          ↓
     ┌────────┬─────────┬─────────┐
     │        │         │         │
  users_db referee_db match_db certificados_db
  (5432)    (5433)    (5434)    (27017)
  
  Redis (6379) - usado por todos los servicios
```

### Mapeo de Servicios a Bases de Datos:
- **Auth Service** → `users_db` (PostgreSQL)
- **Referee Service** → `referee_db` (PostgreSQL) + `certificados_db` (MongoDB)
- **Availability Service** → `referee_db` (PostgreSQL)
- **Match Service** → `match_db` (PostgreSQL)
- **Todos** → `redis` (Cache/Queues)

---

## 🚀 Despliegue en Producción

Para producción, considera:

1. **Usar registros de imágenes** (Docker Hub, AWS ECR, etc.)
2. **Configurar secretos** con herramientas como Docker Secrets o Vault
3. **Implementar reverse proxy** (Nginx, Traefik)
4. **Configurar SSL/TLS** para comunicaciones seguras
5. **Implementar monitoreo** (Prometheus, Grafana)
6. **Configurar backups** automáticos de bases de datos
7. **Usar orquestadores** como Kubernetes para alta disponibilidad

---

## 📝 Notas Adicionales

- Los datos persisten en volúmenes Docker incluso si los contenedores se detienen
- Las bases de datos se inicializan automáticamente con datos de prueba
- Todos los servicios tienen health checks configurados
- Los servicios se reinician automáticamente si fallan (`restart: unless-stopped`)

---

## 🔔 Sistema de Eventos en Tiempo Real

SGAD incluye un sistema completo de eventos asíncronos con **RabbitMQ** y **WebSockets** para:

✅ **Comunicación entre servicios** - Los microservicios se comunican mediante eventos  
✅ **Actualizaciones en tiempo real** - El frontend recibe notificaciones instantáneas  
✅ **Tareas programadas** - El scheduler publica eventos automáticamente  
✅ **Escalabilidad** - Arquitectura desacoplada y event-driven

### Casos de Uso

1. **Disponibilidad Cerrada** - Cuando el scheduler cierra disponibilidades los viernes a las 15:00, se publican eventos que:
   - Notifican a los árbitros en tiempo real vía WebSocket
   - Permiten que otros servicios reaccionen al cambio
   - Quedan registrados para auditoría

2. **Asignaciones de Partido** - Cuando se asigna un árbitro:
   - El servicio de Match Management publica evento
   - El Availability Service actualiza disponibilidad
   - El árbitro recibe notificación instantánea en su app

3. **Actualizaciones del Sistema** - Notificaciones broadcast a todos los usuarios conectados

### Configuración

Ver documentación completa en [EVENT_ARCHITECTURE.md](EVENT_ARCHITECTURE.md)

**Acceder a RabbitMQ Management UI:**
```
http://localhost:15672
Usuario: sgad_rabbit (configurado en .env)
```

**Conectar frontend via WebSocket:**
```typescript
const ws = new WebSocket('ws://localhost:8000/ws/{user_id}');
ws.onmessage = (event) => {
  const message = JSON.parse(event.data);
  // Handle real-time updates
};
```

---
