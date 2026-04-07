# Quick Start

Get up and running with FYY in 5 minutes.

## Install

### macOS (Homebrew)

```bash
brew install feiyueyun/tap/fyy
```

### Linux / macOS (curl)

```bash
curl -fsSL https://fyy.dev/install | sh
```

### Windows

Download the latest binary from [Releases](https://github.com/feiyueyun/fyy/releases).

### Verify Installation

```bash
fyy --version
```

## Join a Network

Every FYY deployment runs on a secure mesh network. To join, you need an auth key from your network administrator.

```bash
fyy join --auth-key=tskey-auth-xxxxx
```

Once connected, your device gets a private IP address and can communicate with other devices on the network through encrypted WireGuard tunnels.

## Check Status

```bash
fyy status
```

This shows your connection status, assigned IP address, and available peers on the network.

## Discover Skills

Browse AI employee skills available on your network:

```bash
# Search for skills by keyword
fyy skill search "listing"

# List all installed skills
fyy skill list
```

## Install and Use a Skill

```bash
# Install a skill
fyy skill install listing-generator

# Start the skill
fyy skill start listing-generator

# Check running skills
fyy skill list --running
```

## Self-Hosting

FYY is free to self-host. To run your own control plane:

### Prerequisites

- Docker 24+
- Docker Compose v2

### Start the Platform

```bash
# Clone the control plane repository
git clone https://github.com/feiyueyun/control-plane.git
cd control-plane

# Copy environment configuration
cp deployments/.env.example deployments/.env

# Start all services
make docker-up
```

This starts the full control plane: PostgreSQL, Redis, NATS, IAM Service, Device Service, Mesh Controller, and a DERP relay node.

### Create an Auth Key

```bash
# Access the admin CLI
docker compose -f deployments/docker-compose.yml exec iam-service \
  feiyueyun-admin authkey create --reusable --max-uses=10
```

Copy the auth key from the output — you'll use it to connect devices.

### Connect a Device

On any device with FYY CLI installed:

```bash
fyy join --auth-key=<your-auth-key> --server=http://<your-server>:8080
```

### Verify

```bash
# On the server: check connected devices
docker compose -f deployments/docker-compose.yml exec iam-service \
  feiyueyun-admin device list

# On the device: check connection
fyy status
```

## What's Next

- [CLI Reference](cli.md) — Full command documentation
- [Skill Manifest](skill-manifest.md) — Learn how to define AI employee capabilities
- [Framework Integration](framework-integration.md) — Connect your existing AI agents
