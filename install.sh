#!/bin/sh
# FYY CLI installer
# Usage: curl -fsSL https://fyy.dev/install.sh | sh
#
# Environment variables:
#   FYY_VERSION   Specific version to install (default: latest)
#   FYY_INSTALL   Installation directory (default: /usr/local/bin)
#   FYY_SERVER    Control plane address for auto-join (default: https://ts.fyy.dev)
#   FYY_API       Channel 2 API address for auto-provision (derived from FYY_SERVER)
#   FYY_SKIP_JOIN Set to 1 to skip auto-provision and network join
#   FYY_RUN_DIR   Daemon runtime dir (PID file, socket; auto-set in containers)

set -eu

# --- Colors (when writing to a terminal) ---
if [ -t 1 ]; then
    BOLD="\033[1m"
    GREEN="\033[32m"
    YELLOW="\033[33m"
    RED="\033[31m"
    RESET="\033[0m"
else
    BOLD=""; GREEN=""; YELLOW=""; RED=""; RESET=""
fi

REPO="feiyueyun/fyy"
INSTALL_DIR="${FYY_INSTALL:-/usr/local/bin}"
FYY_SERVER="${FYY_SERVER:-https://ts.fyy.dev}"
FYY_API="${FYY_API:-}"
FYY_SKIP_JOIN="${FYY_SKIP_JOIN:-0}"

# --- Container detection ---
IS_CONTAINER=0
if [ -f /.dockerenv ] 2>/dev/null || grep -qE 'docker|containerd|kubepods' /proc/1/cgroup 2>/dev/null; then
    IS_CONTAINER=1
fi

# When in a container, automatically set FYY_RUN_DIR to a writable location.
FYY_RUN_DIR="${FYY_RUN_DIR:-}"
if [ "$IS_CONTAINER" = "1" ] && [ -z "$FYY_RUN_DIR" ]; then
    FYY_RUN_DIR="${HOME}/.fyy/run"
fi

# --- Step 1: Detect OS and architecture ---
OS=$(uname -s | tr '[:upper:]' '[:lower:]')
ARCH=$(uname -m)

case "$ARCH" in
    x86_64|amd64)  GOARCH="amd64" ;;
    aarch64|arm64) GOARCH="arm64" ;;
    *)
        echo "${RED}Error:${RESET} Unsupported architecture: $ARCH"
        echo "fyy supports amd64 and arm64 only."
        exit 1
        ;;
esac

case "$OS" in
    linux)   GOOS="linux" ;;
    darwin)  GOOS="darwin" ;;
    *)
        echo "${RED}Error:${RESET} Unsupported OS: $OS"
        echo "fyy supports Linux and macOS only."
        exit 1
        ;;
esac

PLATFORM="${GOOS}-${GOARCH}"

# --- Step 2: Determine version ---
if [ -n "${FYY_VERSION:-}" ]; then
    VERSION="$FYY_VERSION"
else
    VERSION=$(curl -fsSL "https://api.github.com/repos/${REPO}/releases/latest" \
        | sed -n 's/.*"tag_name": *"\([^"]*\)".*/\1/p')
    if [ -z "$VERSION" ]; then
        echo "${RED}Error:${RESET} Could not determine latest version from GitHub Releases."
        echo "Set FYY_VERSION to a specific version, or download manually from:"
        echo "  https://github.com/${REPO}/releases"
        exit 1
    fi
fi

# --- Step 3: Check if already installed ---
already_installed=0
if [ -x "${INSTALL_DIR}/fyy" ]; then
    installed_ver=$("${INSTALL_DIR}/fyy" version 2>/dev/null || echo "unknown")
    echo "${YELLOW}fyy ${installed_ver} already installed at ${INSTALL_DIR}/fyy${RESET}"
    echo "To reinstall, set FYY_VERSION or delete the existing binary."
    already_installed=1
fi

if [ "$already_installed" -eq 0 ]; then
    # --- Step 4: Download and install ---
    BINARY="fyy-${PLATFORM}"
    GZIP_URL="https://github.com/${REPO}/releases/download/${VERSION}/${BINARY}.gz"

    echo "${BOLD}==>${RESET} Downloading fyy ${VERSION} for ${PLATFORM}..."
    TMPDIR=$(mktemp -d)
    trap 'rm -rf "$TMPDIR"' EXIT

    if ! curl -fsSL --progress-bar -o "${TMPDIR}/fyy.gz" "$GZIP_URL"; then
        echo "${RED}Error:${RESET} Failed to download from ${GZIP_URL}"
        echo "Available releases: https://github.com/${REPO}/releases"
        exit 1
    fi

    gunzip -c "${TMPDIR}/fyy.gz" > "${TMPDIR}/fyy"
    chmod +x "${TMPDIR}/fyy"

    echo "${BOLD}==>${RESET} Installing to ${INSTALL_DIR}/fyy..."
    mkdir -p "$INSTALL_DIR" 2>/dev/null || true

    if ! mv "${TMPDIR}/fyy" "${INSTALL_DIR}/fyy" 2>/dev/null; then
        INSTALL_DIR="${HOME}/.local/bin"
        echo "${YELLOW}Permission denied, installing to ${INSTALL_DIR}/fyy instead.${RESET}"
        echo "To install system-wide, re-run with: curl -fsSL https://fyy.dev/install.sh | sudo sh"
        mkdir -p "$INSTALL_DIR"
        mv "${TMPDIR}/fyy" "${INSTALL_DIR}/fyy"
    fi

    # Create fyyd symlink (fyy and fyyd are the same binary).
    ln -sf "${INSTALL_DIR}/fyy" "${INSTALL_DIR}/fyyd"

    # Add to PATH hint if needed.
    case ":$PATH:" in
        *:${INSTALL_DIR}:*) ;;
        *)
            echo ""
            echo "${YELLOW}Note:${RESET} ${INSTALL_DIR} is not in your PATH."
            echo "  Add this to your shell profile:"
            echo "    export PATH=\"${INSTALL_DIR}:\$PATH\""
            ;;
    esac
fi

# --- Step 5: Work out the API address for auto-provision ---
if [ -z "$FYY_API" ]; then
    # Derive from FYY_SERVER: ts.fyy.dev -> api.fyy.dev (replace 'ts' with 'api')
    FYY_API=$(echo "$FYY_SERVER" | sed 's|://ts\.|://api.|')
fi

# --- Step 6: Auto-provision AuthKey and join ---
if [ "$FYY_SKIP_JOIN" = "1" ]; then
    echo "${YELLOW}==>${RESET} Skipping network join (FYY_SKIP_JOIN=1)"
else
    echo "${BOLD}==>${RESET} Requesting auto-provisioned AuthKey from ${FYY_API}..."

    AUTH_RESPONSE=$(curl -fsSL -X POST "${FYY_API}/v1/auth/auto-provision-authkey" \
        -H "Content-Type: application/json" \
        -d '{}' 2>&1) || true

    AUTH_KEY=$(echo "$AUTH_RESPONSE" | sed -n 's/.*"auth_key"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p')

    if [ -z "$AUTH_KEY" ]; then
        echo "${YELLOW}Auto-provision unavailable (server may not support it or rate limited).${RESET}"
        echo ""
        echo "To join manually, obtain an AuthKey from your network administrator and run:"
        echo "  fyy join --auth-key=<key> --server=${FYY_SERVER}"
        echo ""
        echo "For CE (self-hosted) users:"
        echo "  See https://github.com/feiyueyun/fyy/blob/main/docs/quickstart.md#self-hosting"
    else
        echo "${GREEN}AuthKey obtained (valid for 5 minutes).${RESET}"

        echo "${BOLD}==>${RESET} Starting fyyd daemon..."

        if [ -n "$FYY_RUN_DIR" ]; then
            mkdir -p "$FYY_RUN_DIR"
            echo "${YELLOW}  Container environment detected — using ${FYY_RUN_DIR} for runtime files.${RESET}"
        fi

        FYY_RUN_DIR="$FYY_RUN_DIR" "${INSTALL_DIR}/fyyd" --foreground > /tmp/fyyd.log 2>&1 &
        DAEMON_PID=$!
        sleep 3

        echo "${BOLD}==>${RESET} Joining mesh network at ${FYY_SERVER}..."
        if ! FYY_RUN_DIR="$FYY_RUN_DIR" "${INSTALL_DIR}/fyy" join --auth-key="$AUTH_KEY" --server="$FYY_SERVER"; then
            kill "$DAEMON_PID" 2>/dev/null || true
            echo "${RED}Error:${RESET} Failed to join mesh network."
            echo "Try running manually: fyy join --auth-key=<key> --server=${FYY_SERVER}"
            exit 1
        fi

        if [ "$IS_CONTAINER" = "1" ]; then
            # In containers: keep daemon running for the lifetime of the container.
            echo "${GREEN}fyyd running in foreground mode (PID: ${DAEMON_PID}).${RESET}"
            SERVICE_INSTALLED=0
        else
            # On hosts: stop temp daemon, system service will manage it properly.
            kill "$DAEMON_PID" 2>/dev/null || true
        fi
    fi
fi

# --- Step 7: Install system service (host only) ---
SERVICE_INSTALLED="${SERVICE_INSTALLED:-0}"

if [ "$IS_CONTAINER" != "1" ] && [ "$FYY_SKIP_JOIN" != "1" ]; then
    echo "${BOLD}==>${RESET} Installing system service (auto-start on boot)..."

    case "$(uname -s)" in
        Linux)
            if "${INSTALL_DIR}/fyy" service install 2>/dev/null; then
                SERVICE_INSTALLED=1
            elif "${INSTALL_DIR}/fyy" service install --system 2>/dev/null; then
                SERVICE_INSTALLED=1
            fi
            ;;
        Darwin)
            if "${INSTALL_DIR}/fyy" service install 2>/dev/null; then
                SERVICE_INSTALLED=1
            fi
            ;;
    esac

    if [ "$SERVICE_INSTALLED" -eq 1 ]; then
        "${INSTALL_DIR}/fyy" service start 2>/dev/null || true
        echo "${GREEN}Service installed and started.${RESET}"
    else
        echo "${YELLOW}Note:${RESET} System service not installed (may need sudo for --system)."
        echo "Start the daemon manually: fyyd --foreground"
        echo "Set FYY_RUN_DIR for a custom socket/PID path if /var/run is not writable."
    fi
fi

# --- Step 8: Done ---
echo ""
echo "${GREEN}${BOLD}=== Installation Complete ===${RESET}"
echo ""
echo "  fyy binary:  ${INSTALL_DIR}/fyy"
echo "  fyyd daemon: ${INSTALL_DIR}/fyyd (symlink)"
echo ""

if [ "$IS_CONTAINER" = "1" ]; then
    echo "  Container setup notes:"
    echo "  - fyyd is running in background (PID: ${DAEMON_PID:-unknown})"
    echo "  - Runtime dir: ${FYY_RUN_DIR:-${HOME}/.fyy/run}"
    echo "  - Log file: /tmp/fyyd.log"
    echo ""
    echo "  To add to a container entrypoint for auto-start:"
    echo "    export FYY_RUN_DIR=${FYY_RUN_DIR:-${HOME}/.fyy/run}"
    echo "    mkdir -p \${FYY_RUN_DIR} || true"
    echo "    nohup \${INSTALL_DIR}/fyyd --foreground > /tmp/fyyd.log 2>&1 &"
    echo ""
    echo "  The daemon will keep the mesh connection alive. If the container"
    echo "  restarts, add the above lines to the entrypoint script."
else
    echo "Quick start:"
    echo "  fyy status              Check network connection"
    echo "  fyy help                List all commands"
    echo "  fyy skill list          Browse available skills"
fi

echo ""
echo "Documentation: https://github.com/feiyueyun/fyy"
echo "Website:       https://fyy.dev"