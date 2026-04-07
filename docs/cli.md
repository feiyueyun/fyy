# CLI Reference

The `fyy` CLI is the primary interface for interacting with the FYY platform. It runs as both a command-line tool and a background daemon that maintains your mesh network connection.

## Global Options

| Option | Description |
|--------|------------|
| `--version` | Print version information |
| `--help` | Show help for any command |

## Network Commands

### `fyy join`

Join a FYY mesh network.

```bash
fyy join --auth-key=<key> [--server=<url>]
```

| Flag | Required | Default | Description |
|------|----------|---------|------------|
| `--auth-key` | Yes | — | Authentication key provided by your network admin |
| `--server` | No | `https://fyy.dev` | Control plane server URL (for self-hosted deployments) |

### `fyy status`

Show current connection status, assigned IP addresses, and network peers.

```bash
fyy status
```

Output includes:
- Connection state (connected / disconnected)
- Assigned IPv4 and IPv6 addresses
- Connected peers and their status
- Active DERP relay information

### `fyy logout`

Disconnect from the current network.

```bash
fyy logout
```

## Skill Commands

### `fyy skill search`

Search for available AI employee skills.

```bash
fyy skill search <query>
```

**Example:**

```bash
fyy skill search "customer service"
```

### `fyy skill list`

List installed skills.

```bash
fyy skill list [--running]
```

| Flag | Description |
|------|------------|
| `--running` | Only show currently running skills |

### `fyy skill install`

Install a skill from the network.

```bash
fyy skill install <skill-name>
```

### `fyy skill start`

Start an installed skill.

```bash
fyy skill start <skill-name>
```

### `fyy skill stop`

Stop a running skill.

```bash
fyy skill stop <skill-name>
```

### `fyy skill uninstall`

Remove an installed skill.

```bash
fyy skill uninstall <skill-name>
```

### `fyy skill import`

Import skills from external sources.

```bash
# Import from Agent Skills (SKILL.md) format
fyy skill import --from=agent-skills <path-to-SKILL.md>

# Batch import from a directory
fyy skill import --from=agent-skills --dir=<path-to-directory>
```

| Flag | Description |
|------|------------|
| `--from` | Source format: `agent-skills` (SKILL.md) |
| `--dir` | Directory to scan for skill files (batch import) |

## Grants Commands

### `fyy grant list`

List active permission grants.

```bash
fyy grant list
```

### `fyy grant revoke`

Revoke a specific grant.

```bash
fyy grant revoke --id=<grant-id>
```

## Examples

### Join a self-hosted network and install a skill

```bash
# Connect to your team's network
fyy join --auth-key=tskey-auth-abc123 --server=http://10.0.1.5:8080

# Check connection
fyy status

# Find and install a listing generator skill
fyy skill search "listing"
fyy skill install listing-generator
fyy skill start listing-generator
```

### Import existing Agent Skills

```bash
# Import a single SKILL.md file
fyy skill import --from=agent-skills ./my-skill/SKILL.md

# Import all skills from a directory
fyy skill import --from=agent-skills --dir=~/.claude/skills/
```
