#!/usr/bin/env bash
## restart-noctalia.sh — Restart noctalia-shell.
## Import the active graphical-session environment, then restart and verify it.
set -euo pipefail

import_graphical_environment() {
    local manager_environment name value

    if ! manager_environment="$(systemctl --user show-environment)"; then
        echo "Error: failed to read the systemd user environment" >&2
        return 1
    fi

    while IFS='=' read -r name value; do
        case "${name}" in
            DBUS_SESSION_BUS_ADDRESS | DISPLAY | NIRI_SOCKET | WAYLAND_DISPLAY | XDG_RUNTIME_DIR)
                export "${name}=${value}"
                ;;
        esac
    done <<<"${manager_environment}"

    if [[ -z "${WAYLAND_DISPLAY:-}" ]]; then
        echo "Error: WAYLAND_DISPLAY is missing from the systemd user environment" >&2
        return 1
    fi

    if [[ -z "${NIRI_SOCKET:-}" ]]; then
        echo "Error: NIRI_SOCKET is missing from the systemd user environment" >&2
        return 1
    fi

    if [[ -z "${XDG_RUNTIME_DIR:-}" ]]; then
        echo "Error: XDG_RUNTIME_DIR is missing from the systemd user environment" >&2
        return 1
    fi
}

instance_running() {
    noctalia-shell list 2>/dev/null | grep -q '^Instance '
}

wait_until_stopped() {
    local attempt

    for ((attempt = 0; attempt < 10; attempt++)); do
        if ! instance_running; then
            return 0
        fi
        sleep 1
    done

    return 1
}

wait_until_started() {
    local attempt

    for ((attempt = 0; attempt < 10; attempt++)); do
        if instance_running; then
            return 0
        fi
        sleep 1
    done

    return 1
}

import_graphical_environment

if instance_running; then
    echo ">>> stopping noctalia-shell..."
    noctalia-shell kill
    if ! wait_until_stopped; then
        echo "Error: noctalia-shell did not stop within 10 seconds" >&2
        exit 1
    fi
fi

echo ">>> starting noctalia-shell..."
log_file="${XDG_RUNTIME_DIR}/restart-noctalia.log"
if ! noctalia-shell -d >"${log_file}" 2>&1; then
    echo "Error: noctalia-shell failed to launch; startup output follows" >&2
    cat "${log_file}" >&2
    exit 1
fi

if ! wait_until_started; then
    echo "Error: noctalia-shell did not start within 10 seconds; see ${log_file}" >&2
    cat "${log_file}" >&2
    exit 1
fi

echo ">>> noctalia-shell restarted"
