# SGAD Infrastructure

Infraestructura base del Sistema de Gestión de Árbitros Deportivos.

## ¿Qué hace?

Levanta las 3 bases de datos necesarias:

* **PostgreSQL** : Usuarios, árbitros, partidos, asignaciones
* **MongoDB** : Logs, notificaciones, documentos
* **Redis** : Cache y colas de mensajes

## ¿Cómo usar?

1. Clona este repo
2. Cambia las passwords en `.env`
3. Ejecuta: `docker-compose up`
4. Listo! Las bases están funcionando

## Puertos

* PostgreSQL: `localhost:5432`
* MongoDB: `localhost:27017`
* Redis: `localhost:6379`

## Conecta desde otros servicios

Todos los servicios SGAD se conectan a estas bases de datos usando las URLs en `.env`.
