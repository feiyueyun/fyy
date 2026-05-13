# FYY Community Edition (CE)

Deploy your own FYY control plane for free with Docker Compose.
The CE distribution includes all core services needed to run a private Agent Skill Mesh.

## Architecture

The CE control plane runs these services:

| Service | Role | Port |
|---------|------|------|
| PostgreSQL 16 | Primary database | 5432 (internal) |
| Redis 7 | Cache, rate limiting, locks | 6379 (internal) |
| NATS JetStream | Event bus | 4222 (internal) |
| IAM Service | Auth, Agent identity, JWT | 50051 (gRPC) |
| Device Service | Device registration, IP allocation | 50052 (gRPC) |
| Mesh Controller | WireGuard mesh, NetworkMap | 8080 (HTTP) |
| Open API Service | REST + WebSocket gateway | 8090 (HTTP) |
| Policy Service | Grants CRUD | 50060 (gRPC) |
| Policy Compiler | Grants → PacketFilter | 50061 (gRPC) |
| Skill Service Center | Skill registry | 50080 (gRPC) |
| Tag Service | Tag management | 50090 (gRPC) |
| Follow Service | Follow/friend | 50100 (gRPC) |
| DERP Relay | NAT traversal relay | 8443 (HTTPS), 3478 (STUN) |

## Prerequisites

- Docker 24+
- Docker Compose v2
- Minimum: 4 GB RAM, 20 GB disk, 2 CPU cores
- Recommended: 8 GB RAM, 50 GB disk, 4 CPU cores

## Quick Start

### 1. Get the CE distribution

```bash
git clone https://github.com/feiyueyun/fyy.git
cd fyy/ce
```

### 2. Configure environment

```bash
cp .env.example .env
```

Edit `.env` and set strong passwords:

```bash
# Required: generate strong passwords
POSTGRES_PASSWORD=<your-strong-password>
PLATFORM_ADMIN_PASSWORD=<your-strong-password>
JWT_MASTER_KEY=<generate-with-openssl-rand-hex-32>
MINIO_SECRET_KEY=<your-strong-password>
```

Generate a JWT master key:

```bash
openssl rand -hex 32
```

### 3. Start the platform

```bash
docker compose up -d
```

Wait 30–60 seconds for all services to initialize. Check status:

```bash
docker compose ps
```

All services should show `Up` or `running`.

### 4. Access the control plane

The control plane exposes these endpoints:

| Endpoint | Port | Purpose |
|----------|------|---------|
| Mesh Controller | 8080 | Device registration (ts2021) |
| Open API Service | 8090 | REST API + WebSocket |

### 5. Create an AuthKey

```bash
docker compose exec iam-service-1 feiyueyun-admin authkey create
```

This outputs an AuthKey like `tskey-auth-<base64>`. Use it to connect devices.

### 6. Connect a device

On any machine with fyy CLI installed:

```bash
fyy join --auth-key=<key> --server=http://<your-server-ip>:8080
```

If your server has a public domain and TLS, use `https://`:

```bash
fyy join --auth-key=<key> --server=https://ts.your-domain.com
```

### 7. Verify

```bash
# On the server: list registered devices
docker compose exec iam-service-1 feiyueyun-admin device list

# On the device: check connection
fyy status
```

## Configuration

### Enable Auto-Provisioning

Auto-provisioning is enabled by default (`AUTHKEY_AUTO_ENABLED=true` in `.env`).
It allows devices to obtain temporary AuthKeys automatically via:

```bash
curl -X POST http://<your-server>:8090/v1/auth/auto-provision-authkey \
  -H "Content-Type: application/json" -d '{}'
```

To disable: set `AUTHKEY_AUTO_ENABLED=false` in `.env` and restart.

### TLS / HTTPS

For production, put a reverse proxy (nginx, Caddy) in front of the control plane
with valid TLS certificates. Example nginx config:

```nginx
server {
    listen 443 ssl;
    server_name ts.your-domain.com;
    ssl_certificate /path/to/cert.pem;
    ssl_certificate_key /path/to/key.pem;

    location /ts2021 { proxy_pass http://127.0.0.1:8080; }
    location / { proxy_pass http://127.0.0.1:8080; }
}

server {
    listen 443 ssl;
    server_name api.your-domain.com;
    ssl_certificate /path/to/cert.pem;
    ssl_certificate_key /path/to/key.pem;

    location /v1/ { proxy_pass http://127.0.0.1:8090; }
    location /ws/ { proxy_pass http://127.0.0.1:8090; }
}
```

### Persistent Data

All data is stored in Docker volumes. Back up regularly:

```bash
# Backup PostgreSQL
docker compose exec postgres pg_dump -U feiyueyun feiyueyun > backup.sql

# Backup volumes
docker run --rm -v fyy_postgres_data:/data -v $(pwd):/backup alpine \
  tar czf /backup/postgres_backup.tar.gz -C /data .
```

## Management

```bash
# View logs for a specific service
docker compose logs -f iam-service-1

# View all logs
docker compose logs -f

# Restart a service
docker compose restart iam-service-1

# Stop the platform
docker compose down

# Stop and remove all data (WARNING: destructive)
docker compose down -v
```

## Upgrading

```bash
# Pull latest images
docker compose pull

# Restart with new images
docker compose up -d
```

## Troubleshooting

**Services fail to start**: Check logs — `docker compose logs`. Most issues are
missing environment variables or port conflicts.

**Database migration fails**: The iam-service runs migrations on startup. Check its
logs — `docker compose logs iam-service-1`.

**Devices can't connect**: Verify your firewall allows inbound traffic on port 8080
(and 8443 for DERP). Check that `FYY_CONTROL_PLANE_HOST` in `.env` matches your
server's public address.

**Rate limit on auto-provision**: Default is 10 requests/minute/IP.
Adjust with `AUTHKEY_AUTO_RATE_LIMIT` env var.

## Support

- [GitHub Issues](https://github.com/feiyueyun/fyy/issues)
- [Discord](https://discord.gg/feiyueyun)
- [Documentation](../docs/)
