# Quick Start

Get up and running with FYY in 5 minutes.

## Install

### One-command install (macOS / Linux)

```bash
curl -fsSL https://fyy.dev/install.sh | sh
```

This downloads fyy, auto-provisions a temporary AuthKey, joins the official mesh network, and installs fyyd as a system service (auto-start on boot).

**CE users** (self-hosted control plane): set your server address before joining:

```bash
curl -fsSL https://fyy.dev/install.sh | FYY_SERVER=https://ts.example.com sh
```

### macOS (Homebrew)

```bash
brew install feiyueyun/tap/fyy
```

### Manual Download

Download the latest binary for your platform from [Releases](https://github.com/feiyueyun/fyy/releases).

| Platform | Binary |
|----------|--------|
| Linux amd64 | `fyy-linux-amd64` |
| Linux arm64 | `fyy-linux-arm64` |
| macOS amd64 | `fyy-darwin-amd64` |
| macOS arm64 | `fyy-darwin-arm64` |

```bash
# Example: Linux amd64
curl -fsSL -o fyy "https://github.com/feiyueyun/fyy/releases/latest/download/fyy-linux-amd64"
chmod +x fyy
sudo mv fyy /usr/local/bin/fyy
# fyy and fyyd are the same binary
ln -sf /usr/local/bin/fyy /usr/local/bin/fyyd
```

### Docker / Container Environments

fyy auto-detects containers and adapts installation — no systemd needed:

```bash
curl -fsSL https://fyy.dev/install.sh | sh
```

Inside a container, the script:
- Sets `FYY_RUN_DIR` to `$HOME/.fyy/run` (writable PID + socket path)
- Keeps `fyyd --foreground` running (not killed after join)
- Skips system service installation

To persist across restarts, add to your container entrypoint:

```bash
export FYY_RUN_DIR="${HOME}/.fyy/run"
mkdir -p "${FYY_RUN_DIR}" 2>/dev/null || true
nohup fyyd --foreground > /tmp/fyyd.log 2>&1 &
```

For Docker Compose, see [Sidecar Setup](../README.md#container).

### Verify Installation

```bash
fyy --version
```

## Join a Network

### Official Platform (zero-interaction)

The install script above handles everything automatically. To join manually:

```bash
# Obtain a temporary AuthKey from the auto-provision endpoint
curl -X POST https://api.fyy.dev/v1/auth/auto-provision-authkey \
  -H "Content-Type: application/json" -d '{}'

# Join with the returned key
fyy join --auth-key=tskey-auth-xxxxx --server=https://ts.fyy.dev
```

The AuthKey is single-use and valid for 5 minutes. No authentication is required for the auto-provision endpoint.

### CE / Self-Hosted

On your control plane server, create an AuthKey:

```bash
docker compose exec iam-service-1 feiyueyun-admin authkey create
```

On your device, join with the key:

```bash
fyy join --auth-key=<key> --server=https://<your-server>:8080
```

## Check Status

```bash
fyy status
```

Shows your network connection state, assigned tailnet IP, MagicDNS name, active skills count, and daemon uptime.

## Discover and Use Skills

```bash
# Search for available skills
fyy skill search "listing"

# List installed skills
fyy skill list

# Install a skill
fyy skill install listing-generator

# Start the skill
fyy skill start listing-generator

# Stop a running skill
fyy skill stop listing-generator
```

## Self-Hosting (CE)

FYY Community Edition runs the full control plane on your own infrastructure.

### Prerequisites

- Docker 24+
- Docker Compose v2
- 4 GB RAM, 20 GB disk (minimum)

### Quick CE Deployment

```bash
# Get the CE distribution
git clone https://github.com/feiyueyun/fyy.git
cd fyy/ce

# Configure environment
cp .env.example .env
# Edit .env: set POSTGRES_PASSWORD, PLATFORM_ADMIN_PASSWORD, JWT_MASTER_KEY

# Start the platform
docker compose up -d
```

This starts all core services: PostgreSQL, Redis, NATS, IAM Service, Device Service, Mesh Controller, and more.

### Create an AuthKey

```bash
docker compose exec iam-service-1 feiyueyun-admin authkey create
```

Use the output key to connect devices with `fyy join`.

### Connect Devices

On each device with fyy CLI installed:

```bash
fyy join --auth-key=<key> --server=https://<your-server-ip>:8080
```

### Manage Your CE Deployment

```bash
# View logs
docker compose logs -f

# Stop the platform
docker compose down

# Update to a new version
docker compose pull
docker compose up -d
```

For detailed CE documentation, see [`ce/README.md`](../ce/README.md).

## What's Next

- [CLI Reference](cli.md) — Full command documentation
- [Skill Manifest](skill-manifest.md) — Learn how to define AI employee capabilities
- [Framework Integration](framework-integration.md) — Connect your existing AI agents
