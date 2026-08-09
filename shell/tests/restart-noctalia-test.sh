#!/usr/bin/env bash
## restart-noctalia-test.sh — Test safe Noctalia restart behavior.
set -euo pipefail

TEST_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT="${TEST_DIR}/../restart-noctalia.sh"

fail() {
    echo "FAIL: $*" >&2
    exit 1
}

[[ -f "${SCRIPT}" ]] || fail "restart-noctalia.sh does not exist"
[[ -x "${SCRIPT}" ]] || fail "restart-noctalia.sh is not executable"

TEST_ROOT="$(mktemp -d)"
trap 'rm -rf -- "${TEST_ROOT}"' EXIT

MOCK_BIN="${TEST_ROOT}/bin"
STATE_DIR="${TEST_ROOT}/state"
RUNTIME_DIR="${TEST_ROOT}/runtime"
SYSTEM_PATH="${PATH}"
mkdir -p -- "${MOCK_BIN}" "${STATE_DIR}" "${RUNTIME_DIR}"

cat >"${MOCK_BIN}/systemctl" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

[[ "${1:-}" == "--user" && "${2:-}" == "show-environment" ]] || exit 2
printf 'XDG_RUNTIME_DIR=%s\n' "${TEST_RUNTIME_DIR}"
printf 'DBUS_SESSION_BUS_ADDRESS=unix:path=%s/bus\n' "${TEST_RUNTIME_DIR}"
printf 'DISPLAY=:99\n'
if [[ "${OMIT_WAYLAND_ENV:-0}" != 1 ]]; then
    printf 'WAYLAND_DISPLAY=wayland-test\n'
    printf 'NIRI_SOCKET=%s/niri.sock\n' "${TEST_RUNTIME_DIR}"
fi
EOF

cat >"${MOCK_BIN}/noctalia-shell" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

case "${1:-}" in
    list)
        if [[ -e "${TEST_STATE_DIR}/running" ]]; then
            echo "Instance test-instance:"
        else
            echo 'No running instances'
        fi
        ;;
    kill)
        echo kill >>"${TEST_STATE_DIR}/calls"
        rm -f -- "${TEST_STATE_DIR}/running"
        ;;
    -d)
        echo daemon >>"${TEST_STATE_DIR}/calls"
        if [[ "${FAIL_START:-0}" == 1 ]]; then
            echo 'mock startup failure' >&2
            exit 1
        fi
        {
            printf 'WAYLAND_DISPLAY=%s\n' "${WAYLAND_DISPLAY:-}"
            printf 'NIRI_SOCKET=%s\n' "${NIRI_SOCKET:-}"
            printf 'DISPLAY=%s\n' "${DISPLAY:-}"
            printf 'XDG_RUNTIME_DIR=%s\n' "${XDG_RUNTIME_DIR:-}"
            printf 'DBUS_SESSION_BUS_ADDRESS=%s\n' "${DBUS_SESSION_BUS_ADDRESS:-}"
        } >"${TEST_STATE_DIR}/launch-environment"
        touch "${TEST_STATE_DIR}/running"
        ;;
    *)
        exit 2
        ;;
esac
EOF

cat >"${MOCK_BIN}/pgrep" <<'EOF'
#!/usr/bin/env bash
[[ -e "${TEST_STATE_DIR}/running" ]]
EOF

cat >"${MOCK_BIN}/pkill" <<'EOF'
#!/usr/bin/env bash
rm -f -- "${TEST_STATE_DIR}/running"
EOF

cat >"${MOCK_BIN}/setsid" <<'EOF'
#!/usr/bin/env bash
exec "$@"
EOF

chmod +x \
    "${MOCK_BIN}/systemctl" \
    "${MOCK_BIN}/noctalia-shell" \
    "${MOCK_BIN}/pgrep" \
    "${MOCK_BIN}/pkill" \
    "${MOCK_BIN}/setsid"

run_script() {
    env \
        -u WAYLAND_DISPLAY \
        -u NIRI_SOCKET \
        PATH="${MOCK_BIN}:${SYSTEM_PATH}" \
        TEST_RUNTIME_DIR="${RUNTIME_DIR}" \
        TEST_STATE_DIR="${STATE_DIR}" \
        "$@" \
        "${SCRIPT}"
}

touch "${STATE_DIR}/running"
output="$(run_script)" || fail "restart failed with a valid user-manager environment"
grep -Fxq 'WAYLAND_DISPLAY=wayland-test' "${STATE_DIR}/launch-environment" || fail "WAYLAND_DISPLAY was not imported"
grep -Fxq "NIRI_SOCKET=${RUNTIME_DIR}/niri.sock" "${STATE_DIR}/launch-environment" || fail "NIRI_SOCKET was not imported"
grep -Fxq 'DISPLAY=:99' "${STATE_DIR}/launch-environment" || fail "DISPLAY was not imported"
grep -Fxq '>>> noctalia-shell restarted' <<<"${output}" || fail "successful restart was not reported"
[[ "$(sed -n '1p' "${STATE_DIR}/calls")" == kill ]] || fail "the old instance was not stopped first"
[[ "$(sed -n '2p' "${STATE_DIR}/calls")" == daemon ]] || fail "the new instance was not daemonized"

rm -f -- "${STATE_DIR}/calls" "${STATE_DIR}/launch-environment"
touch "${STATE_DIR}/running"
if run_script OMIT_WAYLAND_ENV=1 >"${TEST_ROOT}/missing-env.out" 2>"${TEST_ROOT}/missing-env.err"; then
    fail "missing Wayland environment was accepted"
fi
[[ -e "${STATE_DIR}/running" ]] || fail "the running instance was stopped before environment validation"
[[ ! -e "${STATE_DIR}/calls" ]] || fail "Noctalia was called with an invalid environment"
grep -Fq 'Error:' "${TEST_ROOT}/missing-env.err" || fail "missing environment error was not reported"

rm -f -- "${STATE_DIR}/running" "${STATE_DIR}/calls"
if run_script FAIL_START=1 >"${TEST_ROOT}/failed-start.out" 2>"${TEST_ROOT}/failed-start.err"; then
    fail "a failed Noctalia launch returned success"
fi
if grep -Fq '>>> noctalia-shell restarted' "${TEST_ROOT}/failed-start.out"; then
    fail "a failed Noctalia launch reported success"
fi
grep -Fq 'mock startup failure' "${TEST_ROOT}/failed-start.err" || fail "startup diagnostics were discarded"

echo "PASS: all Noctalia restart tests passed"
