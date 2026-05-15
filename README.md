# FYY — Your AI Digital Workforce

Hire AI digital employees for your one-person company.
They handle listings, customer service, financial reports, compliance checks —
and deliver real results, not just chat.

## Why FYY

Running a business solo means juggling every role yourself.
FYY gives you a team of AI digital employees that collaborate on complex tasks
and deliver finished work — a translated listing ready to publish,
a compliance report ready to send, a customer reply ready to go.

**Pay for results, not tokens.** Your AI employees are paid like real employees — for deliverables.

**Your knowledge stays yours.** Skills run on your own device. Data never leaves your control.

**Agent-neutral.** Bring your own Agent framework — CrewAI, LangGraph, Mastra, OpenClaw, or any MCP-compatible agent.

## Use Cases

**Cross-border e-commerce (solo seller)**
Product Research → Multilingual Listing → Compliance Check → Customer Service → Pricing Strategy

**Professional service teams**
Data Processing → Report Generation → Business Analysis → Invoice Delivery

## Installation

### macOS / Linux (one command)

```bash
curl -fsSL https://fyy.dev/install.sh | sh
```

This single command downloads fyy, auto-provisions an AuthKey, joins the official mesh network, and installs fyyd as a system service.

**Docker / container environments:** fyy auto-detects containers and fully adapts — no systemd needed, socket/PID redirected to tmpfs, daemon kept alive. See [Container Setup](#container-setup) for details.

### macOS (Homebrew)

```bash
brew install feiyueyun/tap/fyy
```

### Windows

Download the latest binary from [Releases](https://github.com/feiyueyun/fyy/releases).

## Container Setup

fyy runs inside Docker containers, Kubernetes pods, and other restricted environments where systemd/launchd and root access are unavailable.

### How it works (zero-config)

The install script auto-detects containers and adapts all decisions:

**`FYY_RUN_DIR=/tmp/fyy-run`** — Unix socket and PID file go to tmpfs. This is required because Docker volume drivers (overlayfs, bind mounts) often don't support `chmod` on Unix sockets. `/tmp` is always tmpfs in all container runtimes.

**Daemon stays running** — fyyd is started in background and kept alive for the container's lifetime. On host systems, it's stopped after join because systemd/launchd takes over; in containers, there is no init system, so the daemon runs as a regular process.

**System service skipped** — systemd/launchd don't exist in containers. The container runtime's restart policy (`restart: unless-stopped` in Docker Compose) replaces this.

**PID file safe** — The daemon handles container restart correctly: stale PID files are detected because the new daemon checks if a PID matches its own process before concluding "already running."

**Auto-heal watchdog** — A background `fyyd-watchdog` process is deployed automatically. It checks `fyy status` every 60 seconds and restarts fyyd if it's unresponsive. No entrypoint modification needed.

### Usage

```bash
# Inside a container — works out of the box
curl -fsSL https://fyy.dev/install.sh | sh
```

### Persisting across restarts (entrypoint)

Add to your Dockerfile or entrypoint script:

```dockerfile
# In Dockerfile
RUN curl -fsSL https://fyy.dev/install.sh | sh
```

```bash
# In entrypoint script
export FYY_RUN_DIR="/tmp/fyy-run"
mkdir -p "${FYY_RUN_DIR}" 2>/dev/null || true
nohup fyyd --foreground > /tmp/fyyd.log 2>&1 &

# Start your application
exec your-app
```

To persist identity and skill data across restarts, mount a volume and set `FYY_STATE_DIR`:

```bash
export FYY_STATE_DIR="/data/fyy"
export FYY_RUN_DIR="/tmp/fyy-run"
mkdir -p "${FYY_RUN_DIR}" "${FYY_STATE_DIR}" 2>/dev/null || true
nohup fyyd --foreground > /tmp/fyyd.log 2>&1 &
```

### OpenClaw cron integration

In OpenClaw and its variants, the gateway has a built-in cron scheduler
that survives container restarts. Use it to keep fyyd alive:

Create `.fyy/fyy-auto-recover.sh` in the agent workspace:

```bash
#!/bin/sh
# fyy-auto-recover — called by OpenClaw cron every 2 minutes
if ! fyy status >/dev/null 2>&1; then
    export FYY_RUN_DIR="/tmp/fyy-run"
    mkdir -p "${FYY_RUN_DIR}" 2>/dev/null || true
    nohup fyyd --foreground > /tmp/fyyd.log 2>&1 &

    # If not on the mesh yet, get an auth key and join
    sleep 2
    if ! fyy status >/dev/null 2>&1; then
        AUTH_KEY=$(curl -s -X POST https://api.fyy.dev/v1/auth/auto-provision-authkey \
            -H "Content-Type: application/json" -d '{}' \
            | sed 's/.*"auth_key"[^"]*"\([^"]*\)".*/\1/')
        [ -n "$AUTH_KEY" ] && fyy join --auth-key="$AUTH_KEY" --server=https://ts.fyy.dev
    fi
fi
```

Configure the OpenClaw gateway to run this script on a 2-minute schedule.
No system crontab, no background watchdog, no entrypoint modification needed.

### Docker Compose (sidecar)

```yaml
services:
  fyy-sidecar:
    image: alpine:latest
    container_name: fyy-sidecar
    cap_add:
      - NET_ADMIN
    restart: unless-stopped
    volumes:
      - fyy_data:/root/.fyy
    environment:
      - FYY_RUN_DIR=/tmp/fyy-run
      - FYY_STATE_DIR=/root/.fyy/data
    command: >
      sh -c "
        curl -fsSL https://fyy.dev/install.sh | sh -s -- --skip-join &&
        exec fyyd --foreground
      "

volumes:
  fyy_data:
```

### Customizing auto-configuration

Set these before running the install script to override defaults:

| Variable | Container default | Purpose |
|---|---|---|
| `FYY_RUN_DIR` | `/tmp/fyy-run` | Socket + PID (tmpfs recommended) |
| `FYY_STATE_DIR` | `~/.feiyueyun` | Identity, skills, DB (persistent volume) |
| `FYY_SKIP_JOIN` | `0` | Set to `1` to skip mesh join |

```bash
# Example: custom paths with persistent state
curl -fsSL https://fyy.dev/install.sh | \
  FYY_RUN_DIR=/tmp/fyy-run \
  FYY_STATE_DIR=/data/fyy \
  sh
```

## Quick Start

```bash
# Join the official mesh network (auto-provisioned AuthKey)
curl -fsSL https://fyy.dev/install.sh | sh

# Or join a specific network with a pre-provisioned key
fyy join --auth-key=tskey-auth-xxxxx --server=https://ts.example.com

# Check status
fyy status

# Discover available skills
fyy skill search "weather"

# Install and run a skill
fyy skill install weather-lookup
fyy skill start weather-lookup
```

## Self-Hosting (CE)

FYY Community Edition (CE) lets you run your own control plane for free.
It ships as a Docker Compose setup — get your own mesh network running in minutes.

See [`ce/`](ce/) for the complete CE distribution with Docker Compose files and setup instructions.

Quick CE deployment:

```bash
git clone https://github.com/feiyueyun/fyy.git
cd fyy/ce
cp .env.example .env
# Edit .env with your passwords and keys
docker compose up -d
```

Then create an AuthKey and connect your devices:

```bash
# Create an auth key for device joining
docker compose exec iam-service-1 feiyueyun-admin authkey create

# On your device, join the network
fyy join --auth-key=<key> --server=https://<your-server>:8080
```

**CE documentation:** [`ce/README.md`](ce/README.md)

## Built on Open Standards

FYY is built on a small set of open, composable building blocks:

- **Skill Manifest** — open standard for defining AI employee capabilities ([spec](https://github.com/feiyueyun/skill-manifest-spec))
- **MCP Gateway** — connect any MCP-compatible AI tool
- **Grants** — fine-grained access control for every AI action
- **WireGuard Mesh** — encrypted peer-to-peer networking, your data stays protected

Compatible with [Anthropic Agent Skills](https://github.com/anthropics/agent-skills) (740K+ skills) and [OpenClaw](https://github.com/openclaw) ecosystem.

## Documentation

- [Product Overview](docs/product-overview.md)
- [Quick Start](docs/quickstart.md)
- [CLI Reference](docs/cli.md)
- [Skill Manifest Standard](docs/skill-manifest.md)
- [Framework Integration Guide](docs/framework-integration.md)

中文文档：[README.zh.md](README.zh.md)

## Community

- [Website](https://fyy.dev)
- [Discord](https://discord.gg/feiyueyun)
- [Twitter/X](https://twitter.com/fyy_dev)

## Uninstall

```bash
# Remove fyy binaries, runtime files, and system service
curl -fsSL https://fyy.dev/uninstall.sh | sh

# Also remove all state data (identity, skill cache, config)
curl -fsSL https://fyy.dev/uninstall.sh | sh -s -- --purge
```

See [`uninstall.sh`](uninstall.sh) for details.

## License

FYY CLI and Control Plane CE are free to use. Pre-built binaries are distributed under the [FYY Software License](LICENSE).
