#!/bin/sh
# fyyd-watchdog — Self-healing daemon monitor for container environments.
# Auto-installed by fyy install.sh. No entrypoint modification needed.
#
# Checks fyyd health every 60 seconds and restarts on failure.
# Uses the same FYY_RUN_DIR and INSTALL_DIR that were configured during install.
#
# Logs to /tmp/fyyd-watchdog.log by default.
# Override: export FYY_WATCHDOG_LOG=/custom/path

set -eu

# --- Configuration (set by install.sh, can be overridden) ---
FYY_RUN_DIR="${FYY_RUN_DIR:-/tmp/fyy-run}"
INSTALL_DIR="${INSTALL_DIR:-/usr/local/bin}"
FYY_WATCHDOG_LOG="${FYY_WATCHDOG_LOG:-/tmp/fyyd-watchdog.log}"
CHECK_INTERVAL="${FYY_WATCHDOG_INTERVAL:-60}"

# --- Write our PID so uninstall.sh can find us ---
echo "$$" > "${FYY_RUN_DIR}/watchdog.pid" 2>/dev/null || true

log() {
    echo "[$(date -u '+%Y-%m-%dT%H:%M:%SZ')] $*" >> "$FYY_WATCHDOG_LOG"
}

log "fyyd-watchdog started (PID: $$, check interval: ${CHECK_INTERVAL}s)"

while true; do
    if ! FYY_RUN_DIR="$FYY_RUN_DIR" "${INSTALL_DIR}/fyy" status >/dev/null 2>&1; then
        log "fyyd not responding, restarting..."

        # Kill any stale fyyd process
        FYAD_PID=$(cat "${FYY_RUN_DIR}/fyyd.pid" 2>/dev/null || echo "")
        if [ -n "$FYAD_PID" ]; then
            kill "$FYAD_PID" 2>/dev/null || true
            sleep 1
        fi

        # Clean up stale socket
        rm -f "${FYY_RUN_DIR}/fyyd.sock" "${FYY_RUN_DIR}/fyyd.pid" 2>/dev/null || true

        # Restart daemon
        FYY_RUN_DIR="$FYY_RUN_DIR" nohup "${INSTALL_DIR}/fyyd" --foreground > /tmp/fyyd.log 2>&1 &
        NEW_PID=$!
        echo "$NEW_PID" > "${FYY_RUN_DIR}/fyyd.pid" 2>/dev/null || true

        log "fyyd restarted (PID: ${NEW_PID})"
        sleep 5
    fi

    sleep "$CHECK_INTERVAL"
done
