# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Supershy is a microservices-based web application with a Pong game, chat system, and user management. The main repository acts as an orchestrator with Git submodules for each service.

## Build and Run Commands

All commands run from the `srcs/` directory:

```bash
# Start all services
make all

# Build and start with fresh images
make build

# Stop all services and remove volumes
make down

# Full cleanup (remove all Docker artifacts + data directories)
make fclean
```

### Frontend Development

The frontend runs webpack-dev-server inside Docker. To rebuild after changes:

```bash
# Rebuild frontend container (picks up .env and source changes)
cd srcs
docker-compose build --no-cache frontend && docker-compose up -d frontend

# Or just rebuild bundle inside running container
docker exec frontend npm run build
```

**Important**: Frontend `.env` must contain actual values (not just comments) for `dotenv-webpack` to inject them at build time.

## Running Tests

```bash
# Run all tests for a service
docker exec -it user python manage.py test
docker exec -it chat python manage.py test
docker exec -it game python manage.py test

# Run specific test module
docker exec -it game python manage.py test arena.tests
docker exec -it game python manage.py test tournament.tests
```

## Git Submodule Workflow

Each service is a separate Git repository. **Changes must be committed in the submodule first**:

```bash
# Example: Making changes to frontend
cd srcs/frontend
git add .
git commit -m "feat: Add new feature"
git push origin main

# Then update main repo reference
cd ../..
git add srcs/frontend
git commit -m "chore: Update frontend submodule"
```

Check submodule status: `git submodule status`

## Architecture

### Microservices Structure

```
srcs/
├── api_gateway/     # Nginx reverse proxy (ports 80/443)
├── user/            # User management + friends (Django)
├── chat/            # Chat service (Django + WebSocket)
├── game/            # Game service with reception/arena/tournament (Django + WebSocket)
├── frontend/        # Custom React-like framework ("supereact")
├── database_*/      # PostgreSQL (one per service for isolation)
```

### Backend Error Handling Pattern

All Django services use a consistent error handling pattern:

```python
# Define errors in config/error_type.py
class ErrorType(Enum):
    USER_NOT_FOUND = (status.HTTP_404_NOT_FOUND, "User not found.")

# Raise in serializers/services
from config.custom_validation_error import CustomValidationError
raise CustomValidationError(ErrorType.USER_NOT_FOUND)

# Return in views using response_builder.py
from config.response_builder import response_ok, response_error, response_errors
return response_error(e)  # For CustomValidationError
return response_errors(serializer.errors)  # For serializer validation errors
```

### Frontend Stack (Supereact)

Custom React-like framework with:

- Virtual DOM with Fiber reconciliation (`src/ft_react/supereact-reconciler/`)
- Hooks: `useState`, `useEffect`, `useRef`, `useMemo`, `useCallback`
- Custom JSX runtime

Import hooks from `ft_react`:

```javascript
import { useState, useEffect, useRef } from 'ft_react';
```

### API Gateway Routing

Nginx routes requests:

- `/api/user/*` → user:8000
- `/api/chat/*` → chat:8000
- `/api/game/*` → game:8000
- `/ws/*` → WebSocket upgrade to respective services
- `/*` → frontend:3000

### Game Service Structure

- **reception**: Lobby/matchmaking with WebSocket consumers
- **arena**: Game sessions and match logic (NormalMatch model)
- **tournament**: Tournament bracket management (Tournament, TournamentMatch, TournamentParticipant)

## Environment Configuration

- Main config: `srcs/.env`
- Service-specific: `srcs/{service}/.env`
- Frontend env vars are read by `dotenv-webpack` at build time
- Data persists to `~/supershy/data/{user,chat,game}/`

## Dev Tools

- **Dozzle**: <http://localhost:8080> (Docker log viewer)
- **Adminer**: <http://localhost:8081> (Database admin)
- **Swagger UI**: <https://localhost/api/schema/swagger-ui/>

## Debugging

```bash
# View service logs
docker-compose logs --tail=50 user
docker-compose logs --tail=50 frontend

# Access service shell
docker exec -it user bash
docker exec -it game python manage.py shell

# Check API gateway logs for routing issues
docker logs api_gateway
```

## JWT Authentication

Services validate JWT tokens independently using shared `JWT_SIGNING_KEY`. Game service middleware uses `verify_signature=False` for simpler token parsing (trusts API gateway).
