#!/bin/sh
# fyyd-watchdog — Self-healing daemon monitor for container environments.
# Auto-installed by fyy install.sh.
#
# Two modes:
#   fyyd-watchdog           — Continuous loop (background process mode)
#   fyyd-watchdog --once    — Single check, exit (cron mode)
#
# Override: FYY_RUN_DIR, INSTALL_DIR, FYY_WATCHDOG_LOG, FYY_WATCHDOG_INTERVAL

set -eu

FYY_RUN_DIR="${FYY_RUN_DIR:-/tmp/fyy-run}"
INSTALL_DIR="${INSTALL_DIR:-/usr/local/bin}"
FYY_WATCHDOG_LOG="${FYY_WATCHDOG_LOG:-/tmp/fyyd-watchdog.log}"
CHECK_INTERVAL="${FYY_WATCHDOG_INTERVAL:-60}"

echo "$$" > "${FYY_RUN_DIR}/watchdog.pid" 2>/dev/null || true

log() {
    echo "[$(date -u '+%Y-%m-%dT%H:%M:%SZ')] $*" >> "$FYY_WATCHDOG_LOG"
}

check_and_restart() {
    if ! FYY_RUN_DIR="$FYY_RUN_DIR" "${INSTALL_DIR}/fyy" status >/dev/null 2>&1; then
        log "fyyd not responding, restarting..."
        FP=$(cat "${FYY_RUN_DIR}/fyyd.pid" 2>/dev/null || echo "")
        [ -n "$FP" ] && kill "$FP" 2>/dev/null || true
        sleep 1
        rm -f "${FYY_RUN_DIR}/fyyd.sock" "${FYY_RUN_DIR}/fyyd.pid" 2>/dev/null || true
        FYY_RUN_DIR="$FYY_RUN_DIR" nohup "${INSTALL_DIR}/fyyd" --foreground > /tmp/fyyd.log 2>&1 &
        NP=$!
        echo "$NP" > "${FYY_RUN_DIR}/fyyd.pid" 2>/dev/null || true
        log "fyyd restarted (PID: ${NP})"
        sleep 5
    fi
}

case "${1:-}" in
    --once|-1)
        check_and_restart
        ;;
    *)
        log "fyyd-watchdog started (PID: $$, interval: ${CHECK_INTERVAL}s)"
        while true; do
            check_and_restart
            sleep "$CHECK_INTERVAL"
        done
        ;;
esac
