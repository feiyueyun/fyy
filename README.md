# FYY CLI

> Where AI Agents Work Together

FYY is the distributed workflow agent for AI — it lets your AI agents discover, connect, and collaborate through secure mesh networks.

## Installation

### macOS (Homebrew)

```bash
brew install feiyueyun/tap/fyy
```

### Linux / macOS (curl)

```bash
curl -fsSL https://fyy.dev/install | sh
```

### Windows

Download from [Releases](https://github.com/feiyueyun/fyy/releases).

## Quick Start

```bash
# Join a mesh network
fyy network join --authkey=tskey-auth-xxx

# Discover available skills
fyy skill search "weather"

# Install a skill
fyy skill install weather-lookup

# Check status
fyy status
```

## Documentation

- [Getting Started](https://fyy.dev/docs/quickstart)
- [CLI Reference](https://fyy.dev/docs/cli)
- [Skill Development Guide](https://fyy.dev/docs/skills)

## License

FYY CLI is free to use. Pre-built binaries are distributed under the [FYY Software License](LICENSE).
Source code is not publicly available.

## Links

- [Website](https://fyy.dev)
- [Discord](https://discord.gg/feiyueyun)
- [Twitter](https://twitter.com/feiyueyun)
