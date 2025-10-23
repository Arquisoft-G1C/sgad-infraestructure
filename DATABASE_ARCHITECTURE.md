# 🗄️ SGAD Database Architecture

Este documento describe la arquitectura de base de datos del sistema SGAD, que utiliza **4 bases de datos separadas** para lograr aislamiento de datos y escalabilidad.

---

## 📊 Resumen de Bases de Datos

| Database | Tipo | Puerto | Servicio(s) que la usan | Propósito |
|----------|------|--------|-------------------------|-----------|
| **users_db** | PostgreSQL | 5432 | Auth Service | Usuarios y autenticación |
| **referee_db** | PostgreSQL | 5433 | Referee Service, Availability Service | Árbitros, disponibilidad, tarifas |
| **match_db** | PostgreSQL | 5434 | Match Management Service | Partidos, equipos, asignaciones |
| **certificados_db** | MongoDB | 27017 | Referee Service | Certificados, documentos, logs |
| **redis** | Redis | 6379 | Todos los servicios | Cache y colas |

---

## 1️⃣ users_db (PostgreSQL)

**Puerto:** 5432  
**Servicio:** Auth Service  
**Propósito:** Gestión de usuarios y autenticación

### Tablas:
- `users` - Usuarios del sistema (arbitro, administrador, presidente)

### Datos Almacenados:
- Email, password hash
- Rol del usuario
- Información personal (nombre, teléfono)
- Estado activo/inactivo
- Timestamps de creación y actualización

### Inicialización:
```bash
./db/postgres/init-users.sql
```

---

## 2️⃣ referee_db (PostgreSQL)

**Puerto:** 5433  
**Servicios:** Referee Service, Availability Service  
**Propósito:** Gestión de árbitros y su disponibilidad

### Tablas:
- `referees` - Información de árbitros
- `availability` - Disponibilidad de árbitros por fecha
- `tariffs` - Tarifas por rol y deporte
- `billing_periods` - Períodos de facturación

### Datos Almacenados:
- Licencias y certificaciones
- Especialidades (fútbol, futsal)
- Información bancaria
- Disponibilidad por fechas
- Tarifas y cobros

### Nota Importante:
- `referee.user_id` hace referencia a `users_db.users.id` (sin FK cross-database)
- La integridad referencial debe manejarse a nivel de aplicación

### Inicialización:
```bash
./db/postgres/init-referee.sql
```

---

## 3️⃣ match_db (PostgreSQL)

**Puerto:** 5434  
**Servicio:** Match Management Service  
**Propósito:** Gestión de partidos y equipos

### Tablas:
- `teams` - Equipos deportivos
- `matches` - Partidos programados
- `match_assignments` - Asignación de árbitros a partidos
- `match_results` - Resultados de partidos

### Datos Almacenados:
- Equipos y sus categorías
- Partidos (fecha, lugar, estado)
- Asignaciones de árbitros
- Resultados y estadísticas

### Nota Importante:
- `match_assignments.referee_id` referencia `referee_db.referees.id`
- `match_assignments.assigned_by` referencia `users_db.users.id`
- Sin FKs cross-database, integridad a nivel de aplicación

### Inicialización:
```bash
./db/postgres/init-match.sql
```

---

## 4️⃣ certificados_db (MongoDB)

**Puerto:** 27017  
**Servicio:** Referee Service  
**Propósito:** Almacenamiento de documentos y certificados

### Colecciones:
- `certificates` - Certificados y licencias
- `referee_documents` - Documentos administrativos
- `processing_logs` - Logs de procesamiento de archivos
- `audit_logs` - Logs de auditoría
- `notifications` - Notificaciones del sistema

### Datos Almacenados:
- PDFs y documentos escaneados
- Certificados médicos y de seguro
- Licencias de árbitros
- Logs de operaciones del sistema
- Notificaciones para usuarios

### Ventajas de MongoDB:
- Almacenamiento flexible de documentos
- Esquemas dinámicos para diferentes tipos de certificados
- Mejor rendimiento para operaciones de logs
- Almacenamiento de datos no estructurados

### Inicialización:
```bash
./db/mongo/init-certificados.js
```

---

## 🔄 Redis (Cache & Queues)

**Puerto:** 6379  
**Servicios:** Todos  
**Propósito:** Cache y colas de mensajes

### Uso:
- Cache de sesiones JWT
- Cache de consultas frecuentes
- Cola de tareas asíncronas
- Rate limiting
- Sincronización entre servicios

---

## 🔗 Conexiones entre Bases de Datos

### Relaciones Cross-Database

Dado que las bases de datos están separadas, las relaciones se manejan a nivel de aplicación:

```
users_db.users.id
    ↓ (user_id)
    referee_db.referees.user_id
        ↓ (referee_id)
        match_db.match_assignments.referee_id

users_db.users.id
    ↓ (assigned_by)
    match_db.match_assignments.assigned_by
```

### Estrategias de Integridad:
1. **Validación en servicios:** Cada servicio valida IDs antes de insertar
2. **Eventos:** Usar mensajes para sincronizar cambios
3. **Cache:** Redis almacena mapeos frecuentes
4. **Retry logic:** Manejo de inconsistencias temporales

---

## 🚀 Ventajas de esta Arquitectura

### ✅ Aislamiento de Datos
- Cada servicio tiene su propia base de datos
- Cambios en un servicio no afectan otros
- Seguridad mejorada (permisos granulares)

### ✅ Escalabilidad Independiente
- Cada base de datos puede escalar por separado
- PostgreSQL para datos relacionales
- MongoDB para documentos no estructurados
- Redis para cache de alta velocidad

### ✅ Despliegue Independiente
- Los servicios pueden desplegarse sin afectar otros
- Actualizaciones de esquema por servicio
- Rollback independiente

### ✅ Tecnología Apropiada
- PostgreSQL para datos transaccionales
- MongoDB para documentos y logs
- Redis para cache en memoria

---

## 📝 Consideraciones de Desarrollo

### Migraciones de Base de Datos
Cada servicio debe manejar sus propias migraciones:
- `users_db` → Auth Service maneja migraciones
- `referee_db` → Referee/Availability Services
- `match_db` → Match Service
- `certificados_db` → Referee Service (MongoDB schemas)

### Transacciones Distribuidas
⚠️ **No hay transacciones ACID cross-database**

Estrategias:
1. **Saga Pattern:** Transacciones compensatorias
2. **Event Sourcing:** Log de eventos
3. **Eventual Consistency:** Aceptar inconsistencia temporal

### Backup y Recuperación
Cada base de datos requiere su propia estrategia:
```bash
# Backup PostgreSQL
docker exec sgad-postgres-users pg_dump -U sgad_user users_db > backup-users.sql
docker exec sgad-postgres-referee pg_dump -U sgad_user referee_db > backup-referee.sql
docker exec sgad-postgres-match pg_dump -U sgad_user match_db > backup-match.sql

# Backup MongoDB
docker exec sgad-mongodb-certificados mongodump --db=certificados_db --out=/backup
```

---

## 🔧 Configuración de Conexión

### Variables de Entorno

Cada servicio debe configurar sus conexiones:

#### Auth Service
```env
DB_HOST=postgres-users
DB_PORT=5432
DB_NAME=users_db
DB_USER=sgad_user
DB_PASSWORD=***
```

#### Referee Service
```env
# PostgreSQL
DATABASE_URL=postgresql://sgad_user:***@postgres-referee:5432/referee_db

# MongoDB
MONGODB_URL=mongodb://sgad_mongo:***@mongodb-certificados:27017/certificados_db
```

#### Availability Service
```env
DATABASE_URL=postgresql://sgad_user:***@postgres-referee:5432/referee_db
```

#### Match Service
```env
DATABASE_URL=postgresql://sgad_user:***@postgres-match:5432/match_db
```

---

## 📊 Diagrama de Arquitectura

```
┌─────────────────────────────────────────────────────────┐
│                     SGAD Services                        │
├─────────────┬──────────────┬──────────────┬─────────────┤
│   Auth      │   Referee    │ Availability │    Match    │
│  Service    │   Service    │   Service    │   Service   │
└──────┬──────┴──────┬───┬───┴──────┬───────┴──────┬──────┘
       │             │   │          │              │
       ↓             ↓   ↓          ↓              ↓
┌──────────┐  ┌──────────────────┐  ┌──────────┐  ┌──────────┐
│ users_db │  │   referee_db     │  │match_db  │  │certifi.  │
│  (PG)    │  │     (PG)         │  │  (PG)    │  │  (Mongo) │
│  :5432   │  │    :5433         │  │  :5434   │  │  :27017  │
└──────────┘  └──────────────────┘  └──────────┘  └──────────┘
                                                           
                    ┌──────────────┐
                    │    Redis     │
                    │   (Cache)    │
                    │    :6379     │
                    └──────────────┘
```

---

## 🎯 Mejores Prácticas

1. **Nunca hacer JOINs cross-database** - Obtener datos en el servicio
2. **Usar IDs UUID** - Facilita trazabilidad cross-service
3. **Implementar retry logic** - Para manejar inconsistencias
4. **Monitorear lag de datos** - Entre servicios relacionados
5. **Documentar dependencias** - Qué servicios consultan qué datos
6. **Planear rollback** - Estrategias de migración inversa
7. **Backup regular** - Cada database independientemente

---

Para más información sobre la implementación, consulta el [README.md](README.md) principal.

