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

### macOS (Homebrew)

```bash
brew install feiyueyun/tap/fyy
```

### Windows

Download the latest binary from [Releases](https://github.com/feiyueyun/fyy/releases).

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

## License

FYY CLI and Control Plane CE are free to use. Pre-built binaries are distributed under the [FYY Software License](LICENSE).
