#!/bin/sh
# fyy — Uninstall script
# Usage: curl -fsSL https://fyy.dev/uninstall.sh | sh
#        curl -fsSL https://fyy.dev/uninstall.sh | sh -s -- --purge
#
# Resolution order for paths:
#   1. $HOME/.fyy/manifest.json (written by install.sh — most precise)
#   2. Environment variables (FYY_RUN_DIR, FYY_STATE_DIR, INSTALL_DIR)
#   3. Standard path probes (fallback)
#
# What this removes:
#   - fyyd daemon process (if running)
#   - Binaries: fyy, fyyd
#   - Runtime dir: socket, PID
#   - System service: systemd (Linux) or launchd (macOS)
#   - Config files: ~/.fyy/config.yaml
#
# With --purge, also removes all state data:
#   - ~/.fyy/state/ (identity tokens, skill cache, local DB)
#   - ~/.fyy/ (manifest, config)

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

PURGE="${FYY_PURGE:-0}"
if [ "${1:-}" = "--purge" ]; then
    PURGE=1
fi
SKIP_LEAVE="${FYY_SKIP_LEAVE:-0}"
KEPT_SOMETHING=0

echo "${BOLD}==>${RESET} fyy uninstall"

# ---------------------------------------------------------------------------
# Step 0: Load install manifest (written by install.sh at $HOME/.fyy/manifest.json)
# ---------------------------------------------------------------------------
MANIFEST="${HOME}/.fyy/manifest.json"
IS_CONTAINER=0
INSTALL_DIR=""
FYY_RUN_DIR=""
FYY_STATE_DIR=""

if [ -f "$MANIFEST" ]; then
    echo "${BOLD}==>${RESET} Reading install manifest: ${MANIFEST}"

    IS_CONTAINER=$(sed -n 's/.*"container":[[:space:]]*\(true\|false\).*/\1/p' "$MANIFEST")
    IS_CONTAINER=$([ "$IS_CONTAINER" = "true" ] && echo 1 || echo 0)

    INSTALL_DIR=$(sed -n 's/.*"install_dir":[[:space:]]*"\([^"]*\)".*/\1/p' "$MANIFEST")
    FYY_RUN_DIR=$(sed -n 's/.*"run_dir":[[:space:]]*"\([^"]*\)".*/\1/p' "$MANIFEST")
    FYY_STATE_DIR=$(sed -n 's/.*"state_dir":[[:space:]]*"\([^"]*\)".*/\1/p' "$MANIFEST")

    echo "  Loaded from manifest:"
    echo "    install_dir: ${INSTALL_DIR:-N/A}"
    echo "    run_dir: ${FYY_RUN_DIR:-N/A}"
    echo "    state_dir: ${FYY_STATE_DIR:-N/A}"
    echo "    container: $([ "$IS_CONTAINER" = "1" ] && echo 'yes' || echo 'no')"
else
    echo "${YELLOW}  No manifest found, probing paths...${RESET}"

    IS_CONTAINER=0
    if [ -f /.dockerenv ] 2>/dev/null || grep -qE 'docker|containerd|kubepods' /proc/1/cgroup 2>/dev/null; then
        IS_CONTAINER=1
    fi

    if [ -z "${FYY_RUN_DIR:-}" ]; then
        for d in /tmp/fyy-run "${HOME}/.fyy/run"; do
            if [ -S "${d}/fyyd.sock" ] || [ -f "${d}/fyyd.pid" ]; then
                FYY_RUN_DIR="$d"
                break
            fi
        done
    fi
    INSTALL_DIR="${INSTALL_DIR:-/usr/local/bin}"
fi

# ---------------------------------------------------------------------------
# Step 1: Stop daemon
# ---------------------------------------------------------------------------
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

PIDS=$(pgrep -x fyyd 2>/dev/null || true)
if [ -n "$PIDS" ]; then
    kill $PIDS 2>/dev/null || true
fi

# ---------------------------------------------------------------------------
# Step 2: Remove system service (host only)
# ---------------------------------------------------------------------------
if [ "$IS_CONTAINER" != "1" ] && [ -n "$INSTALL_DIR" ] && [ -x "${INSTALL_DIR}/fyy" ]; then
    echo "${BOLD}==>${RESET} Removing system service..."
    "${INSTALL_DIR}/fyy" service stop 2>/dev/null || true
    "${INSTALL_DIR}/fyy" service uninstall 2>/dev/null || true
fi

# ---------------------------------------------------------------------------
# Step 3: Remove binaries
# ---------------------------------------------------------------------------
echo "${BOLD}==>${RESET} Removing binaries..."
for dir in "${INSTALL_DIR}" "${HOME}/.local/bin"; do
    [ -n "$dir" ] || continue
    for bin in "${dir}/fyy" "${dir}/fyyd"; do
        if [ -f "$bin" ] || [ -L "$bin" ]; then
            rm -f "$bin"
            echo "  Removed: ${bin}"
        fi
    done
done

# ---------------------------------------------------------------------------
# Step 4: Remove runtime dir
# ---------------------------------------------------------------------------
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

# ---------------------------------------------------------------------------
# Step 5: Remove config + state
# ---------------------------------------------------------------------------
# Config file lives at ~/.fyy/config.yaml (not in state dir)
rm -f "${HOME}/.fyy/config.yaml" "${HOME}/.fyy/config.json" 2>/dev/null || true

STATE_DIR="${FYY_STATE_DIR:-${HOME}/.fyy/state}"
if [ -d "$STATE_DIR" ]; then
    if [ "$PURGE" = "1" ]; then
        echo "${BOLD}==>${RESET} Purging all fyy state data..."
        rm -rf "$STATE_DIR"
        echo "  Removed: ${STATE_DIR}"
        if [ -d "${HOME}/.fyy" ]; then
            rm -rf "${HOME}/.fyy" 2>/dev/null || true
            echo "  Removed: ${HOME}/.fyy (manifest)"
        fi
    else
        REMAINING=$(find "$STATE_DIR" -mindepth 1 2>/dev/null | head -5 || echo "")
        if [ -n "$REMAINING" ]; then
            KEPT_SOMETHING=1
        fi
    fi
else
    if [ "$PURGE" = "1" ] && [ -d "${HOME}/.fyy" ]; then
        rm -rf "${HOME}/.fyy" 2>/dev/null || true
    fi
fi

# ---------------------------------------------------------------------------
# Done
# ---------------------------------------------------------------------------
echo ""
echo "${GREEN}${BOLD}=== Uninstall Complete ===${RESET}"
echo ""

if [ "$DAEMON_KILLED" = "1" ]; then
    echo "  Daemon: stopped"
else
    echo "  Daemon: not running"
fi
echo "  Binaries: removed"
echo "  Runtime: cleaned"

if [ "$PURGE" = "1" ]; then
    echo "  State data: purged"
else
    if [ "$KEPT_SOMETHING" = "1" ]; then
        echo "  State data: kept at ${STATE_DIR}"
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
