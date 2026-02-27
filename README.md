# Supershy - Microservices Pong Game Platform

A real-time multiplayer Pong game platform built with microservices architecture, featuring live chat, tournaments, and friend management.

## Architecture Overview

```
                                    ┌─────────────────────────────────────────────────────────────┐
                                    │                        CLIENTS                              │
                                    │              (Browser / Mobile / Desktop)                   │
                                    └─────────────────────────┬───────────────────────────────────┘
                                                              │
                                                              │ HTTPS (443) / WSS
                                                              ▼
┌─────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
│                                         API GATEWAY (Nginx)                                                 │
│  ┌─────────────────────────────────────────────────────────────────────────────────────────────────────┐   │
│  │  • SSL Termination           • WebSocket Upgrade Handling        • Request Routing                 │   │
│  │  • Load Balancing            • CORS Headers                      • Rate Limiting (planned)         │   │
│  └─────────────────────────────────────────────────────────────────────────────────────────────────────┘   │
│                                                                                                             │
│    /api/user/*  ──►  USER SERVICE        /ws/user/*  ──►  USER SERVICE (WebSocket)                        │
│    /api/chat/*  ──►  CHAT SERVICE        /ws/chat/*  ──►  CHAT SERVICE (WebSocket)                        │
│    /api/game/*  ──►  GAME SERVICE        /ws/game/*  ──►  GAME SERVICE (WebSocket)                        │
│    /*           ──►  FRONTEND                                                                              │
└─────────────────────────────────────────────────────────────────────────────────────────────────────────────┘
                                                              │
                    ┌─────────────────────────────────────────┼─────────────────────────────────────────┐
                    │                                         │                                         │
                    ▼                                         ▼                                         ▼
┌─────────────────────────────┐   ┌─────────────────────────────┐   ┌─────────────────────────────────────┐
│      USER SERVICE           │   │       CHAT SERVICE          │   │          GAME SERVICE               │
│      (Django + DRF)         │   │       (Django + DRF)        │   │          (Django + DRF)             │
├─────────────────────────────┤   ├─────────────────────────────┤   ├─────────────────────────────────────┤
│ • User Registration/Login   │   │ • Direct Messaging          │   │ • Reception (Lobby)                 │
│ • JWT Authentication        │   │ • Chat Room Management      │   │ • Arena (Match Engine)              │
│ • Friend Management         │   │ • Real-time WebSocket       │   │ • Tournament Brackets               │
│ • Profile & Avatar          │   │ • Message History           │   │ • Matchmaking                       │
│ • Email Verification        │   │                             │   │ • Real-time Game State              │
│ • Win/Loss Statistics       │   │                             │   │                                     │
├─────────────────────────────┤   ├─────────────────────────────┤   ├─────────────────────────────────────┤
│     Daphne (ASGI)           │   │     Daphne (ASGI)           │   │     Daphne (ASGI)                   │
└──────────────┬──────────────┘   └──────────────┬──────────────┘   └──────────────────┬──────────────────┘
               │                                  │                                     │
               ▼                                  ▼                                     ▼
┌─────────────────────────────┐   ┌─────────────────────────────┐   ┌─────────────────────────────────────┐
│     PostgreSQL (user_db)    │   │     PostgreSQL (chat_db)    │   │     PostgreSQL (game_db)            │
│     Isolated Database       │   │     Isolated Database       │   │     Isolated Database               │
└─────────────────────────────┘   └─────────────────────────────┘   └─────────────────────────────────────┘

                    │                             │                                     │
                    └─────────────────────────────┼─────────────────────────────────────┘
                                                  │
                                                  ▼
              ┌───────────────────────────────────────────────────────────────────────┐
              │                           REDIS CLUSTER                               │
              │  ┌─────────────────────────────┐   ┌─────────────────────────────┐   │
              │  │   redis_events              │   │   redis_websockets          │   │
              │  │   (Pub/Sub Messaging)       │   │   (Channel Layer)           │   │
              │  │                             │   │                             │   │
              │  │   • Inter-service events    │   │   • WebSocket groups        │   │
              │  │   • Notifications           │   │   • Real-time broadcast     │   │
              │  │   • Game state sync         │   │   • Session management      │   │
              │  └─────────────────────────────┘   └─────────────────────────────┘   │
              └───────────────────────────────────────────────────────────────────────┘
```

## Key Architecture Decisions

### 1. Database Isolation (Database-per-Service Pattern)

Each microservice owns its data exclusively:

| Service | Database | Rationale |
|---------|----------|-----------|
| User | `user_db` | User credentials and PII isolated for security |
| Chat | `chat_db` | Message data separate for GDPR compliance |
| Game | `game_db` | High-write game state won't affect other services |

**Benefits:**
- Independent scaling (game DB can be optimized for writes)
- Failure isolation (chat DB crash doesn't affect authentication)
- Technology flexibility (could use different DB types per service)

### 2. Dual Redis Architecture

Two separate Redis instances prevent resource contention:

```
redis_events (Pub/Sub)              redis_websockets (Channel Layer)
├── Friend requests                 ├── Chat room groups
├── Game invitations                ├── Game session broadcasts
├── Tournament notifications        └── Live score updates
└── Inter-service communication
```

**Why separate?**
- Pub/Sub traffic patterns differ from channel layer
- Prevents WebSocket message delivery from being delayed by event processing
- Allows independent scaling and monitoring

### 3. API Gateway Pattern

Nginx serves as the single entry point:

```
Client Request → Nginx → Route to Service
                     ↓
              SSL Termination
              WebSocket Upgrade
              CORS Handling
```

**Benefits:**
- Single SSL certificate management point
- Unified logging and monitoring
- Easy service discovery (services don't need to know about each other's locations)

### 4. WebSocket Architecture

All three backend services support WebSocket connections via Django Channels:

```python
# Example: Game WebSocket flow
Client ──WSS──► Nginx ──WS──► Daphne ──► Django Channels ──► Redis Channel Layer
                                                    ↓
                                          Game State Update
                                                    ↓
                                          Broadcast to all players
```

### 5. Authentication Architecture (Distributed Token Validation)

```
┌──────────────────────────────────────────────────────────────────────────────┐
│                         AUTHENTICATION FLOW                                  │
└──────────────────────────────────────────────────────────────────────────────┘

1. LOGIN (Token Issuance)
   ┌────────┐    POST /api/user/login/    ┌──────────────┐
   │ Client │ ─────────────────────────►  │ User Service │
   └────────┘                             └──────┬───────┘
        ▲                                        │
        │         { access_token, refresh_token } │
        └─────────────────────────────────────────┘

2. AUTHENTICATED REQUEST (Token Validation)
   ┌────────┐   Authorization: Bearer <token>   ┌──────────────┐
   │ Client │ ──────────────────────────────►   │ Any Service  │
   └────────┘                                   └──────┬───────┘
                                                       │
                                            ┌──────────▼──────────┐
                                            │ JWT Validation      │
                                            │ (No network call)   │
                                            │ Using shared secret │
                                            └─────────────────────┘
```

**Why Distributed Validation?**

| Pattern | Pros | Cons |
|---------|------|------|
| **Centralized Auth Service** | Single source of truth | Network hop per request, SPOF |
| **API Gateway Auth** | Edge validation | Gateway becomes complex |
| **Distributed Validation** ✓ | No latency, no SPOF | Secret key management |

We chose **Distributed Token Validation** because:
- **Zero latency**: JWT validation is a cryptographic operation, not a network call
- **No single point of failure**: Each service validates independently
- **Simplicity**: Standard `djangorestframework-simplejwt` implementation
- **Scalability**: Adding services doesn't increase auth service load

**Shared Secret Management:**
- Each service has the same `SECRET_KEY` for JWT signature verification
- Keys are injected via environment variables (not hardcoded)
- In production, use a secrets manager (HashiCorp Vault, AWS Secrets Manager)

## Tech Stack

### Backend
- **Framework**: Django 5.1 + Django REST Framework
- **ASGI Server**: Daphne (WebSocket support)
- **WebSocket**: Django Channels + channels_redis
- **Database**: PostgreSQL (one per service)
- **Cache/Messaging**: Redis (dual instance)
- **Authentication**: JWT (djangorestframework-simplejwt)
- **API Documentation**: drf-spectacular (OpenAPI/Swagger)

### Frontend
- **Framework**: Supereact (Custom React-like implementation)
  - Virtual DOM with Fiber reconciliation
  - Custom hooks system (useState, useEffect)
  - Custom JSX runtime
- **Bundler**: Webpack 5

### Infrastructure
- **Containerization**: Docker + Docker Compose
- **Reverse Proxy**: Nginx
- **Log Viewer**: Dozzle
- **DB Admin**: Adminer

## Quick Start

### Prerequisites
- Docker & Docker Compose
- Git

### Setup

```bash
# Clone with submodules
git clone --recursive https://github.com/supershy42/puppeteer.git
cd puppeteer

# Setup environment
cd srcs
cp .env.example .env
# Edit .env with your settings

# Copy service-specific env files
cp user/.env.example user/.env
cp chat/.env.example chat/.env
cp game/.env.example game/.env
cp frontend/.env.example frontend/.env

# Start all services
make all
```

### Access Points

| Service | URL | Description |
|---------|-----|-------------|
| Application | https://localhost | Main application |
| Swagger UI | https://localhost/api/schema/swagger-ui/ | API documentation |
| Dozzle | http://localhost:8080 | Container logs |
| Adminer | http://localhost:8081 | Database admin |

## API Endpoints

### User Service (`/api/user/`)
- `POST /register/` - User registration
- `POST /login/` - Authentication (returns JWT)
- `POST /verify-email/` - Email verification
- `GET /profile/` - Get user profile
- `GET /friend/` - List friends
- `POST /friend/` - Add friend
- `DELETE /friend/{id}/` - Remove friend

### Chat Service (`/api/chat/`)
- `GET /rooms/` - List chat rooms
- `POST /rooms/` - Create chat room
- `GET /rooms/{id}/messages/` - Get message history
- WebSocket: `/ws/chat/{room_id}/`

### Game Service (`/api/game/`)
- `GET /reception/` - List game lobbies
- `POST /reception/` - Create lobby
- `POST /reception/{id}/join/` - Join lobby
- `GET /tournament/` - List tournaments
- `POST /tournament/` - Create tournament
- WebSocket: `/ws/game/{match_id}/`

## Health Checks

All services expose health endpoints:

```bash
# Check service health
curl http://localhost/api/user/health/
curl http://localhost/api/chat/health/
curl http://localhost/api/game/health/
```

Response:
```json
{
  "service": "user",
  "status": "healthy",
  "timestamp": "2024-02-16T12:00:00Z",
  "checks": {
    "database": "ok"
  }
}
```

## Development

### Running Tests

```bash
# Run tests for each service
docker exec -it user python manage.py test
docker exec -it chat python manage.py test
docker exec -it game python manage.py test
```

### Useful Commands

```bash
# View logs
make logs          # or use Dozzle at :8080

# Rebuild services
make build

# Clean everything
make fclean

# Access service shell
docker exec -it user bash
docker exec -it chat bash
docker exec -it game bash
```

### Database Migrations

Migrations run automatically on container startup. For manual migration:

```bash
docker exec -it user python manage.py makemigrations
docker exec -it user python manage.py migrate
```

## Environment Variables

See [ENV_ARCHITECTURE.md](srcs/ENV_ARCHITECTURE.md) for detailed documentation on environment configuration.

Key variables:
- `DATA_PATH` - Host directory for persistent data
- `DB_*_USER`, `DB_*_PASSWORD`, `DB_*_NAME` - Database credentials per service
- `REDIS_EVENTS_URL`, `REDIS_WEBSOCKETS_URL` - Redis connection strings
- `SECRET_KEY` - Django secret key (unique per service)

## Security Considerations

- All traffic encrypted via HTTPS/WSS
- JWT tokens for stateless authentication
- Password hashing using Django's PBKDF2
- Game lobby passwords hashed before storage
- CORS headers configured in API Gateway
- Database credentials isolated per service

## Future Improvements

- [ ] Rate limiting at API Gateway
- [ ] Redis persistence (RDB snapshots)
- [ ] Kubernetes manifests for production
- [ ] CI/CD pipeline with GitHub Actions
- [ ] Let's Encrypt SSL integration
- [ ] Prometheus metrics + Grafana dashboards
- [ ] Message encryption for chat

## License

MIT License - See [LICENSE](LICENSE) for details.

## Contributors

Built as a portfolio project demonstrating microservices architecture, real-time systems, and full-stack development.
