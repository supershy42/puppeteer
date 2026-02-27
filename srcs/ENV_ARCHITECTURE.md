# Environment Variables Architecture

This document explains the design patterns and conventions used for environment variables in the supershy project.

## 📁 File Structure

```
srcs/
├── .env                    # Main environment file (shared across all services)
├── .env.example            # Template for main .env
├── user/.env               # User service-specific configuration
├── chat/.env               # Chat service-specific configuration
├── chat/.env.example       # Template for chat service
├── game/.env               # Game service-specific configuration
├── frontend/.env           # Frontend service-specific configuration (overrides main .env)
└── docker-compose.yml      # Service-specific infrastructure vars (POSTGRES_HOST, etc.)
```

> **Note:** `.env.example` files for `user/`, `game/`, and `frontend/` are not yet created.

## 🎯 Design Principles

### 1. Separation of Concerns

**Main `.env` (`srcs/.env`)**
- Shared infrastructure configuration (PostgreSQL, Redis)
- Inter-service communication URLs
- Frontend API URLs
- Database credentials for all services
- Docker volume paths

**Service-specific `.env` files**
- Service-specific secrets (Django SECRET_KEY)
- Service-specific features (email config for user service)
- Debug flags per service
- Development overrides

### 2. Avoid Duplication (DRY Principle)

❌ **Bad** - Don't duplicate the same value across multiple files:
```bash
# In srcs/.env
REDIS_HOST=redis_websockets

# In srcs/user/.env
REDIS_HOST=redis_websockets  # ❌ Duplication!
```

✅ **Good** - Define once in the appropriate scope:
```bash
# In srcs/.env
REDIS_HOST=redis_websockets

# Services inherit this automatically via docker-compose env_file
```

### 3. Configuration Layering in Docker Compose

Docker Compose loads `.env` files in order:

```yaml
frontend:
  env_file:
    - ./.env              # Loaded first (base configuration)
    - ./frontend/.env     # Loaded second (can override base)
```

**Inheritance rule**: Later files override earlier files for the same variable.

### 4. Explicit vs Environment File

**Use `environment:` in `docker-compose.yml` when:**
- Value is infrastructure-specific and varies per service
- Example: `POSTGRES_HOST=database_user` (different for each microservice)
- Example: `POSTGRES_USER=${DB_USER_USER}` (credentials mapped from main .env)

**Use `.env` files when:**
- Value is shared across services
- Value might change between environments (dev/staging/prod)
- Value contains secrets
- Example: API URLs, database passwords, Redis configuration

### 5. Frontend .env Override Behavior

The frontend `srcs/frontend/.env` is loaded **after** the main `srcs/.env` by docker-compose, so it overrides shared values:

```bash
# Main .env defines:
USER_API_URL=http://localhost/api/user   # Absolute URL
USER_WS_URL=ws://localhost/ws            # WS protocol

# Frontend .env overrides with:
USER_API_URL=/api/user                   # Relative URL (works with HTTPS)
USER_WS_URL=wss://localhost/ws/user      # WSS protocol + specific path
```

This allows backend services to use absolute URLs for inter-service communication while the frontend uses relative/secure paths appropriate for browser use.

### 6. Naming Conventions

✅ **Good**:
```bash
# No spaces around =
DATABASE_URL=postgres://user:pass@host:5432/db
REDIS_HOST=redis_websockets
DEBUG=True
```

❌ **Bad**:
```bash
# Spaces around = (inconsistent)
DATABASE_URL = postgres://user:pass@host:5432/db
REDIS_HOST =redis_websockets
DEBUG= True
```

## 🔒 Security Best Practices

### 1. Never Commit Real Secrets

- ✅ `.env` files are in `.gitignore`
- ✅ `.env.example` files show structure but use placeholders
- ❌ Never commit files with real passwords, API keys, or SECRET_KEYs

### 2. Use .env.example as Templates

When onboarding a new developer:
```bash
cd srcs
cp .env.example .env
cp chat/.env.example chat/.env

# For user, game, and frontend, create .env files manually
# (no .env.example templates yet)
# Then update all .env files with actual values
```

### 3. Rotate Secrets Regularly

Generate new Django SECRET_KEYs:
```bash
python -c 'from django.core.management.utils import get_random_secret_key; print(get_random_secret_key())'
```

## 📊 Variable Scope Reference

| Variable Type | Location | Example |
|--------------|----------|---------|
| Database credentials | `srcs/.env` | `DB_USER_PASSWORD` |
| Redis configuration | `srcs/.env` | `REDIS_HOST`, `REDIS_PORT` |
| Inter-service URLs | `srcs/.env` | `USER_SERVICE_URL` |
| Frontend API URLs (base) | `srcs/.env` | `USER_API_URL` |
| Frontend API URLs (override) | `srcs/frontend/.env` | `/api/user` (relative) |
| JWT configuration | `srcs/.env` | `JWT_SIGNING_KEY`, `JWT_ALGORITHM` |
| Django SECRET_KEY | `srcs/{service}/.env` | Each service has its own |
| DEBUG flag | `srcs/{service}/.env` | Can vary per service |
| Email config | `srcs/user/.env` | User service specific |
| Service-specific DB host | `docker-compose.yml` | `POSTGRES_HOST=database_user` |
| Service DB credentials | `docker-compose.yml` | `POSTGRES_USER`, `POSTGRES_PASSWORD`, `POSTGRES_DB` |

## 🔄 Migration from Old Pattern

If you're updating old code:

1. **Remove duplicates** - If a variable is in both main `.env` and service `.env`, keep it only in main `.env`
2. **Standardize formatting** - Remove spaces around `=` signs
3. **Move to appropriate scope** - Shared configs go in main `.env`, service-specific in service `.env`
4. **Remove from docker-compose** - If it's in `.env`, don't hardcode in `docker-compose.yml`

## 🚀 Quick Setup Guide

```bash
# 1. Copy all example files
cd srcs
for dir in . user chat game frontend; do
  if [ -f "$dir/.env.example" ]; then
    cp "$dir/.env.example" "$dir/.env"
  fi
done

# 2. Update all .env files with your actual values
# Edit srcs/.env - update passwords and paths
# Edit srcs/user/.env - update SECRET_KEY and email
# Edit srcs/chat/.env - update SECRET_KEY
# Edit srcs/game/.env - update SECRET_KEY

# 3. Start services
docker-compose up -d
```

## ❓ FAQ

**Q: Why move API URLs from docker-compose.yml to .env?**  
A: Configuration management. URLs might change between dev/staging/prod. Having them in `.env` makes it easier to manage and follows the 12-factor app methodology.

**Q: When should I use docker-compose environment: section?**  
A: Only for values that are truly infrastructure-specific and different per service, like `POSTGRES_HOST=database_user` (which is different for user/chat/game services).

**Q: Why separate service .env files?**  
A: Each microservice has its own Django SECRET_KEY and might have service-specific configurations. This maintains service isolation.

**Q: Can I override main .env values in service .env?**  
A: Yes! Docker Compose loads them in order, so service `.env` values override main `.env` values. This is useful for local development.

## 🔗 References

- [12-Factor App: Config](https://12factor.net/config)
- [Docker Compose Environment Variables](https://docs.docker.com/compose/environment-variables/)
- [Django Secret Key Best Practices](https://docs.djangoproject.com/en/stable/ref/settings/#secret-key)
