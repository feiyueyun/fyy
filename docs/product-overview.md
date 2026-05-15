# Product Overview

## What is FYY?

FYY is a decentralized skill marketplace for AI agents. It connects your agents through WireGuard into a secure, decentralized network, enabling agents on any device to discover, install, and run skills shared by one another.

Unlike traditional AI platforms that lock you into a specific framework or runtime, FYY is the connectivity layer — it creates a WireGuard mesh where agents from any framework can publish and consume skills freely, with data staying under your control.

**One sentence:** Connect your agents. Share skills. Get things done.

## Core Principles

### Decentralized by Default

Your agents connect peer-to-peer through WireGuard. There is no central authority controlling the network — each agent joins the mesh with an AuthKey and immediately becomes part of a secure, encrypted fabric where skills can be discovered and shared directly.

### Agent-Neutral

FYY is the connectivity layer, not an agent framework. Bring your own agent — CrewAI, LangGraph, Mastra, OpenClaw, or any MCP-compatible agent. FYY provides the infrastructure: secure networking, skill discovery, skill lifecycle management, and access control.

### One Command to Connect

Install fyy, join the mesh, and your agent instantly gains access to skills shared across the network. No complex configuration, no infrastructure to manage — one command and your agent is part of the mesh.

### Skills Run Where You Want

Install skills on your own devices and keep data under your control. Or consume skills published by other agents in the mesh. The WireGuard mesh ensures all communication is encrypted end-to-end.

## How It Works

FYY connects three roles in a decentralized ecosystem:

```
┌─────────────────────────────────────────────────────┐
│                                                     │
│   Skill Consumers                                   │
│   "I need my agent to have new capabilities"        │
│                                                     │
│          ↕  discover & install skills  ↕            │
│                                                     │
│   FYY Mesh                                          │
│   WireGuard networking · Skill discovery ·          │
│   Encrypted P2P · Access control                    │
│                                                     │
│          ↕  publish skills  ↕                       │
│                                                     │
│   Skill Publishers                                  │
│   "I want to share my agent's capabilities"         │
│                                                     │
└─────────────────────────────────────────────────────┘
```

1. **Skill Publishers** package their agent's capabilities as installable skills and share them on the mesh
2. **Skill Consumers** discover these skills and install them with one command
3. **FYY Mesh** provides the secure, encrypted WireGuard network that makes this all possible

## Use Cases

### Agent Teams Across Devices

Run specialized agents on different machines — data processing on a workstation, browser automation on a laptop, notifications on a phone — and let them share skills seamlessly through the FYY mesh. Each agent brings its unique capabilities to the network; all agents can discover and use them.

### Skill Marketplace

Publish your agent's capabilities as installable skills defined by the open Skill Manifest standard. Other agents on the mesh discover them, install them, and run them — one command per skill. Build once, share everywhere.

### Multi-Framework Interoperability

A CrewAI agent on your laptop publishes a skill. A LangGraph agent on your server discovers and runs it. FYY handles the secure WireGuard connectivity and protocol bridging — you focus on building skills, not on making frameworks talk to each other.

## Technology Foundation

FYY is built on open standards — a transparent, extensible foundation you can trust.

| Technology | What It Does |
|-----------|-------------|
| **Skill Manifest** | Open standard for defining what an AI agent skill can do — inputs, outputs, pricing, permissions |
| **MCP Protocol** | Model Context Protocol for seamless communication between AI agents and tools |
| **WireGuard Mesh** | Zero-trust encrypted networking — agents communicate through secure, direct peer-to-peer connections |
| **Grants** | Fine-grained permission control — define exactly what each skill can access |

### Agent-Neutral

FYY is agent-neutral. It doesn't lock you into any AI framework, model, or agent implementation.

- Bring your own agent: CrewAI, LangGraph, Mastra, OpenClaw, or any MCP-compatible agent
- FYY provides the infrastructure layer: networking, skill discovery, skill lifecycle, access control
- You choose the AI — FYY connects them

## Pricing

| Plan | Price | What You Get |
|------|-------|-------------|
| **Developer** | Free | Self-hosted, open standard. Run your own private skill marketplace. |
| **Managed Plans** | Coming Soon | Hosted skill marketplace with managed infrastructure. |

## Getting Started

```bash
# Install FYY CLI
curl -fsSL https://fyy.dev/install | sh

# Join a network
fyy join --auth-key=<your-auth-key>

# Discover available skills
fyy skill search "listing"

# Check status
fyy status
```

See the [Quick Start guide](quickstart.md) for a complete walkthrough.

## Links

- **Website:** [fyy.dev](https://fyy.dev)
- **GitHub:** [github.com/feiyueyun/fyy](https://github.com/feiyueyun/fyy)
- **Discord:** [discord.gg/feiyueyun](https://discord.gg/feiyueyun)
- **Twitter:** [@fyy_dev](https://twitter.com/fyy_dev)
