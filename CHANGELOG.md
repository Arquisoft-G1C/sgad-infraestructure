# 📝 Changelog - 4 Database Architecture Update

## 🎯 Overview

Updated SGAD infrastructure to support **4 separate databases** as shown in the architecture diagram, replacing the previous single PostgreSQL database approach.

---

## ✅ Changes Made

### 1. Docker Compose Updates

#### Database Services Split:
- ❌ **Removed:** Single `postgres` service
- ✅ **Added:** `postgres-users` (Port 5432)
- ✅ **Added:** `postgres-referee` (Port 5433)
- ✅ **Added:** `postgres-match` (Port 5434)
- ✅ **Updated:** `mongodb` → `mongodb-certificados` (Port 27017)
- ✅ **Kept:** `redis` (Port 6379)

#### Service Connections Updated:
- **Auth Service** → `postgres-users`
- **Referee Service** → `postgres-referee` + `mongodb-certificados`
- **Availability Service** → `postgres-referee`
- **Match Service** → `postgres-match`

### 2. Database Initialization Files

Created separate init scripts for each database:

#### PostgreSQL Init Files:
- ✅ `db/postgres/init-users.sql`
  - Users table
  - Auth-related data

- ✅ `db/postgres/init-referee.sql`
  - Referees table
  - Availability table
  - Tariffs table
  - Billing periods table

- ✅ `db/postgres/init-match.sql`
  - Teams table
  - Matches table
  - Match assignments table
  - Match results table

#### MongoDB Init File:
- ✅ `db/mongo/init-certificados.js`
  - Certificates collection
  - Referee documents collection
  - Processing logs collection
  - Audit logs collection
  - Notifications collection

### 3. Environment Configuration

Updated `env.template` with new database variables:

```env
# Old (single database):
POSTGRES_DB=sgad_db
POSTGRES_USER=sgad_user
POSTGRES_PASSWORD=***

# New (4 databases):
USERS_DB=users_db
USERS_DB_USER=sgad_user
USERS_DB_PASSWORD=***

REFEREE_DB=referee_db
REFEREE_DB_USER=sgad_user
REFEREE_DB_PASSWORD=***

MATCH_DB=match_db
MATCH_DB_USER=sgad_user
MATCH_DB_PASSWORD=***

CERTIFICADOS_DB=certificados_db
CERTIFICADOS_DB_USER=sgad_mongo
CERTIFICADOS_DB_PASSWORD=***
```

### 4. Documentation Updates

#### README.md:
- ✅ Updated database section to show 4 databases
- ✅ Updated ports table
- ✅ Updated architecture diagram
- ✅ Updated configuration examples
- ✅ Updated troubleshooting section

#### New Documentation:
- ✅ `DATABASE_ARCHITECTURE.md` - Complete database architecture guide
- ✅ `CHANGELOG.md` - This file

### 5. Docker Volumes

Updated volume definitions:

```yaml
volumes:
  postgres_users_data:
  postgres_referee_data:
  postgres_match_data:
  mongo_certificados_data:
  redis_data:
```

---

## 🔄 Migration Path

If you were using the old single-database setup:

### Option 1: Fresh Install (Recommended)
```bash
# Stop old containers
docker-compose down -v

# Update configuration
cp env.template .env
# Edit .env with your passwords

# Build and start
./build-images.sh
docker-compose up -d
```

### Option 2: Migrate Existing Data

1. **Backup old database:**
```bash
docker exec sgad-postgres pg_dump -U sgad_user sgad_db > backup.sql
```

2. **Extract and split data by table:**
```bash
# Extract users table
grep -A 1000 "CREATE TABLE users" backup.sql > users-data.sql

# Extract referees, availability, tariffs, billing_periods
grep -A 1000 "CREATE TABLE referees" backup.sql > referee-data.sql

# Extract teams, matches, match_assignments
grep -A 1000 "CREATE TABLE teams" backup.sql > match-data.sql
```

3. **Import into new databases:**
```bash
# Import users
docker exec -i sgad-postgres-users psql -U sgad_user users_db < users-data.sql

# Import referee data
docker exec -i sgad-postgres-referee psql -U sgad_user referee_db < referee-data.sql

# Import match data
docker exec -i sgad-postgres-match psql -U sgad_user match_db < match-data.sql
```

---

## 📊 Database Mapping

### Old Schema → New Databases

| Old Table | New Database | New Location |
|-----------|--------------|--------------|
| `users` | users_db | postgres-users:5432 |
| `referees` | referee_db | postgres-referee:5433 |
| `availability` | referee_db | postgres-referee:5433 |
| `tariffs` | referee_db | postgres-referee:5433 |
| `billing_periods` | referee_db | postgres-referee:5433 |
| `teams` | match_db | postgres-match:5434 |
| `matches` | match_db | postgres-match:5434 |
| `match_assignments` | match_db | postgres-match:5434 |
| MongoDB collections | certificados_db | mongodb-certificados:27017 |

---

## ⚠️ Breaking Changes

### 1. Database Connection Strings
Services must update their connection strings to point to specific database containers.

**Before:**
```
postgresql://user:pass@postgres:5432/sgad_db
```

**After:**
```
# Auth Service
postgresql://user:pass@postgres-users:5432/users_db

# Referee Service
postgresql://user:pass@postgres-referee:5432/referee_db

# Match Service
postgresql://user:pass@postgres-match:5432/match_db
```

### 2. Cross-Database References
Foreign keys between databases are **not supported**. Services must:
- Validate IDs at application level
- Handle consistency with saga patterns
- Use eventual consistency where appropriate

### 3. Environment Variables
All services need updated environment variables as shown in `env.template`.

---

## 🎯 Benefits of New Architecture

### ✅ Isolation
- Each service owns its data
- Schema changes don't affect other services
- Better security boundaries

### ✅ Scalability
- Scale databases independently
- Optimize per workload
- Different backup strategies per database

### ✅ Technology Fit
- PostgreSQL for transactional data
- MongoDB for documents/logs
- Redis for caching

### ✅ Development Velocity
- Services can evolve independently
- Parallel development
- Easier testing

---

## 📝 Post-Update Checklist

- [ ] Copy `env.template` to `.env`
- [ ] Configure all database passwords
- [ ] Run `./build-images.sh` to rebuild service images
- [ ] Run `docker-compose up -d` to start all services
- [ ] Verify all databases are healthy: `docker-compose ps`
- [ ] Check database logs for errors
- [ ] Test service connectivity
- [ ] Verify data initialization
- [ ] Update service configuration files if needed

---

## 🔗 Related Documentation

- [README.md](README.md) - Main documentation
- [DATABASE_ARCHITECTURE.md](DATABASE_ARCHITECTURE.md) - Database design details
- [QUICK_START.md](QUICK_START.md) - Quick setup guide
- [env.template](env.template) - Environment configuration

---

## 📞 Support

If you encounter issues:
1. Check `docker-compose logs <service-name>`
2. Verify all environment variables are set
3. Ensure ports are not in use
4. Review DATABASE_ARCHITECTURE.md for connection details

---

**Date:** October 2025  
**Version:** 2.0 (4-Database Architecture)

