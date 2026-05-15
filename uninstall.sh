#!/bin/sh
# fyy — Uninstall script
# Usage: curl -fsSL https://fyy.dev/uninstall.sh | sh
#        curl -fsSL https://fyy.dev/uninstall.sh | sh -s -- --purge
#
# What this removes:
#   - fyyd daemon process (if running)
#   - fyyd-watchdog process + script (if deployed)
#   - Binaries: /usr/local/bin/fyy, /usr/local/bin/fyyd (or INSTALL_DIR)
#   - Runtime dir: /tmp/fyy-run (socket + PID), or FYY_RUN_DIR
#   - System service: systemd (Linux) or launchd (macOS)
#   - Config file: ~/.feiyueyun/config.*
#
# With --purge, also removes state data:
#   - ~/.feiyueyun/ (identity tokens, skill cache, local DB)
#
# Environment variables:
#   INSTALL_DIR   Binary directory (default: /usr/local/bin)
#   FYY_RUN_DIR   Runtime dir override (probed if not set)

set -eu

# --- Colors ---
if [ -t 1 ]; then
    BOLD="\033[1m"
    GREEN="\033[32m"
    YELLOW="\033[33m"
    RED="\033[31m"
    RESET="\033[0m"
else
    BOLD=""; GREEN=""; YELLOW=""; RED=""; RESET=""
fi

INSTALL_DIR="${INSTALL_DIR:-/usr/local/bin}"
PURGE="${FYY_PURGE:-0}"
if [ "${1:-}" = "--purge" ]; then
    PURGE=1
fi
SKIP_LEAVE="${FYY_SKIP_LEAVE:-0}"
KEPT_SOMETHING=0

echo "${BOLD}==>${RESET} fyy uninstall"

# --- Step 1: Detect container ---
IS_CONTAINER=0
if [ -f /.dockerenv ] 2>/dev/null || grep -qE 'docker|containerd|kubepods' /proc/1/cgroup 2>/dev/null; then
    IS_CONTAINER=1
fi

# --- Step 2: Probe FYY_RUN_DIR ---
if [ -z "${FYY_RUN_DIR:-}" ]; then
    for d in /tmp/fyy-run "${HOME}/.fyy/run"; do
        if [ -S "${d}/fyyd.sock" ] || [ -f "${d}/fyyd.pid" ]; then
            FYY_RUN_DIR="$d"
            break
        fi
    done
fi

# --- Step 3: Stop daemon ---
DAEMON_KILLED=0
if [ -n "${FYY_RUN_DIR:-}" ] && [ -f "${FYY_RUN_DIR}/fyyd.pid" ]; then
    DAEMON_PID=$(cat "${FYY_RUN_DIR}/fyyd.pid" 2>/dev/null || echo "")
    if [ -n "$DAEMON_PID" ] && kill -0 "$DAEMON_PID" 2>/dev/null; then
        echo "${BOLD}==>${RESET} Stopping fyyd daemon (PID: ${DAEMON_PID})..."

        if [ "$SKIP_LEAVE" != "1" ] && command -v "${INSTALL_DIR}/fyy" >/dev/null 2>&1; then
            "${INSTALL_DIR}/fyy" leave 2>/dev/null || true
        fi

        kill "$DAEMON_PID" 2>/dev/null || true
        sleep 1
        kill -9 "$DAEMON_PID" 2>/dev/null || true
        DAEMON_KILLED=1
        echo "${GREEN}  Daemon stopped.${RESET}"
    fi
    rm -f "${FYY_RUN_DIR}/fyyd.pid" 2>/dev/null || true
fi

# Kill any remaining fyyd processes
FYAD_PIDS=$(pgrep -x fyyd 2>/dev/null || true)
if [ -n "$FYAD_PIDS" ]; then
    echo "${BOLD}==>${RESET} Stopping remaining fyyd processes..."
    kill $FYAD_PIDS 2>/dev/null || true
    sleep 1
    kill -9 $FYAD_PIDS 2>/dev/null || true
fi

# --- Step 3b: Stop watchdog (if running) ---
WATCHDOG_KILLED=0
if [ -n "${FYY_RUN_DIR:-}" ] && [ -f "${FYY_RUN_DIR}/watchdog.pid" ]; then
    WD_PID=$(cat "${FYY_RUN_DIR}/watchdog.pid" 2>/dev/null || echo "")
    if [ -n "$WD_PID" ] && kill -0 "$WD_PID" 2>/dev/null; then
        kill "$WD_PID" 2>/dev/null || true
        WATCHDOG_KILLED=1
    fi
    rm -f "${FYY_RUN_DIR}/watchdog.pid" 2>/dev/null || true
fi

# Also kill any watchdog by process name
WD_PIDS=$(pgrep -x fyyd-watchdog 2>/dev/null || true)
if [ -n "$WD_PIDS" ]; then
    kill $WD_PIDS 2>/dev/null || true
fi

# --- Step 4: Remove system service (host only) ---
if [ "$IS_CONTAINER" != "1" ] && command -v "${INSTALL_DIR}/fyy" >/dev/null 2>&1; then
    echo "${BOLD}==>${RESET} Removing system service..."
    "${INSTALL_DIR}/fyy" service stop 2>/dev/null || true
    "${INSTALL_DIR}/fyy" service uninstall 2>/dev/null || true
fi

# --- Step 5: Remove binaries ---
echo "${BOLD}==>${RESET} Removing binaries..."
for bin in "${INSTALL_DIR}/fyy" "${INSTALL_DIR}/fyyd" "${INSTALL_DIR}/fyyd-watchdog"; do
    if [ -f "$bin" ] || [ -L "$bin" ]; then
        rm -f "$bin"
        echo "  Removed: $bin"
    fi
done

# Also check ~/.local/bin for user-local installs
for dir in "${HOME}/.local/bin"; do
    for bin in "${dir}/fyy" "${dir}/fyyd" "${dir}/fyyd-watchdog"; do
        if [ -f "$bin" ] || [ -L "$bin" ]; then
            rm -f "$bin"
            echo "  Removed: $bin"
        fi
    done
done

# --- Step 6: Remove runtime dir ---
if [ -n "${FYY_RUN_DIR:-}" ] && [ -d "$FYY_RUN_DIR" ]; then
    echo "${BOLD}==>${RESET} Removing runtime directory..."
    rm -rf "$FYY_RUN_DIR"
    echo "  Removed: ${FYY_RUN_DIR}"
fi

for d in /tmp/fyy-run "${HOME}/.fyy/run"; do
    if [ -d "$d" ]; then
        rm -rf "$d" 2>/dev/null || true
    fi
done

# --- Step 7: Remove config ---
CONFIG_DIR="${HOME}/.feiyueyun"
if [ -d "$CONFIG_DIR" ]; then
    rm -f "${CONFIG_DIR}/config.yaml" "${CONFIG_DIR}/config.json" 2>/dev/null || true
    echo "${BOLD}==>${RESET} Removed config files."
fi

# --- Step 8: Purge state data (optional) ---
if [ "$PURGE" = "1" ]; then
    if [ -d "$CONFIG_DIR" ]; then
        echo "${BOLD}==>${RESET} Purging all fyy state data..."
        rm -rf "$CONFIG_DIR"
        echo "  Removed: ${CONFIG_DIR}"
    fi
    if [ -d "${HOME}/.fyy" ]; then
        rm -rf "${HOME}/.fyy" 2>/dev/null || true
    fi
else
    if [ -d "$CONFIG_DIR" ]; then
        KEPT_SOMETHING=1
    fi
fi

# --- Done ---
echo ""
echo "${GREEN}${BOLD}=== Uninstall Complete ===${RESET}"
echo ""

if [ "$DAEMON_KILLED" = "1" ]; then
    echo "  Daemon: stopped"
else
    echo "  Daemon: not running"
fi
if [ "$WATCHDOG_KILLED" = "1" ]; then
    echo "  Watchdog: stopped"
fi
echo "  Binaries: removed"
echo "  Runtime: cleaned"

if [ "$PURGE" = "1" ]; then
    echo "  State data: purged"
else
    if [ "$KEPT_SOMETHING" = "1" ]; then
        echo "  State data: kept at ${CONFIG_DIR}"
        echo "    (re-run with --purge to remove)"
    fi
fi

echo ""
echo "fyy has been removed from this system."

if [ "$IS_CONTAINER" = "1" ]; then
    echo ""
    echo "${YELLOW}Container note:${RESET} The container itself still exists."
    echo "Remove the container if you no longer need it: docker rm <container>"
fi
