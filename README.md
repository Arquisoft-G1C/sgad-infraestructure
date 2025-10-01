# SGAD – Infrastructure

Infraestructura base del **SGAD (Sistema de Gestión de Árbitros y Designaciones)**.  
Este repositorio contiene la configuración necesaria para levantar las **bases de datos** que utilizan los microservicios del sistema.

---

## 📖 ¿Qué hace?

Levanta las 3 bases de datos necesarias para el funcionamiento de SGAD:

- **PostgreSQL** → Usuarios, árbitros, partidos, asignaciones.  
- **MongoDB** → Logs, notificaciones, documentos.  
- **Redis** → Cache y colas de mensajes para mejorar el rendimiento.  

---

## 📂 Estructura del Proyecto

```
sgad-infrastructure/
│── docker-compose.yml   # Orquestación de bases de datos
│── .env.example         # Variables de entorno (credenciales y puertos)
│── db/                  # Configuración inicial (scripts de creación)
```

---

## ⚙️ Requisitos

- **Docker** 20+  
- **Docker Compose** 1.29+  

---

## ▶️ ¿Cómo usar?

1. Clonar este repositorio:
   ```bash
   git clone https://github.com/Arquisoft-G1C/sgad-infraestructure.git
   cd sgad-infraestructure
   ```

2. Copiar el archivo de ejemplo `.env.example` a `.env` y personalizar credenciales (usuario, contraseñas, nombres de BD).

3. Levantar las bases de datos con Docker:
   ```bash
   docker-compose up -d
   ```

4. ¡Listo! Las bases ya estarán corriendo en tu máquina.  

---

## 🔑 Puertos por defecto

- **PostgreSQL** → `localhost:5432`  
- **MongoDB** → `localhost:27017`  
- **Redis** → `localhost:6379`  

*(Pueden modificarse en `.env` y `docker-compose.yml`)*

---

## 🔗 Conexión desde otros servicios

Todos los microservicios de SGAD utilizan estas bases de datos mediante las **URLs configuradas en `.env`**.  
Ejemplos de cadenas de conexión:

```env
# PostgreSQL
DATABASE_URL=postgresql://postgres:password@localhost:5432/sgad

# MongoDB
MONGO_URL=mongodb://mongo:password@localhost:27017/sgad_logs

# Redis
REDIS_URL=redis://:password@localhost:6379
```

---

## 🐳 Comandos útiles

- Ver contenedores corriendo:
  ```bash
  docker ps
  ```

- Detener la infraestructura:
  ```bash
  docker-compose down
  ```

- Reiniciar servicios:
  ```bash
  docker-compose restart
  ```

---

## 📡 Integración con SGAD

Esta infraestructura es consumida por:

- `sgad-match-management` (usa **PostgreSQL**)  
- `sgad-referee-management` (usa **MongoDB**)  
- `sgad-auth-service` (usa **PostgreSQL**)  
- API Gateway y otros microservicios pueden usar **Redis** para cache y colas.  

---
