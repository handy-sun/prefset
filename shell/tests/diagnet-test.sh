#!/usr/bin/env bash
## diagnet-test.sh — Test the read-only network diagnostics utility
# The sourced script consumes these globals indirectly through its functions.
# shellcheck disable=SC2034,SC2154
set -euo pipefail

TEST_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT="${TEST_DIR}/../diagnet.sh"

fail() {
    echo "FAIL: $*" >&2
    exit 1
}

[[ -f "${SCRIPT}" ]] || fail "diagnet.sh does not exist"
[[ -x "${SCRIPT}" ]] || fail "diagnet.sh is not executable"

# shellcheck source=../diagnet.sh
# shellcheck disable=SC1091
NETWORK_DIAG_SOURCE_ONLY=1 source "${SCRIPT}"

route='default via 192.168.77.1 dev enp0s31f6 proto dhcp src 192.168.49.196 metric 100'
[[ "$(route_device "${route}")" == "enp0s31f6" ]] || fail "route_device parsed the wrong interface"
[[ "$(route_gateway "${route}")" == "192.168.77.1" ]] || fail "route_gateway parsed the wrong gateway"
[[ "$(route_metric "${route}")" == "100" ]] || fail "route_metric parsed the wrong metric"
[[ "$(route_metric 'default dev eth0')" == "0" ]] || fail "route_metric did not default to zero"
[[ "$(carrier_label 1)" == "yes" ]] || fail "carrier state 1 was not described as yes"
[[ "$(carrier_label 0)" == "no" ]] || fail "carrier state 0 was not described as no"
[[ "$(speed_label '')" == "unknown" ]] || fail "an empty link speed was not described as unknown"

"${SCRIPT}" --help | grep -Fq 'Read-only network path diagnostics' || fail "help output is missing its description"
"${SCRIPT}" --help | grep -Fq 'diagnet.sh [OPTIONS]' || fail "help output uses the wrong script name"
"${SCRIPT}" --help | grep -Fq -- '--verbose' || fail "help output is missing --verbose"

legacy_name='diagnose-network''-path'
if grep -Fq "${legacy_name}" "${SCRIPT}" "${BASH_SOURCE[0]}"; then
    fail "the former script name is still referenced"
fi

if "${SCRIPT}" --timeout nope >/dev/null 2>&1; then
    fail "an invalid timeout was accepted"
fi

if "${SCRIPT}" --interface >/dev/null 2>&1; then
    fail "a missing interface value was accepted"
fi

if "${SCRIPT}" --interface lo --gateway nonsense >/dev/null 2>&1; then
    fail "an invalid IPv4 gateway was accepted"
fi

if "${SCRIPT}" --interface interface-that-does-not-exist >/dev/null 2>&1; then
    fail "a nonexistent interface was accepted"
fi

VERBOSE=false
[[ -z "$(verbose_printf 'hidden')" ]] || fail "verbose output appeared in concise mode"
VERBOSE=true
[[ "$(verbose_printf 'detail: %s' visible)" == 'detail: visible' ]] || fail "verbose output was not printed"

COLOR_ENABLED=true
[[ "$(status_label PASS)" == $'\033[32mPASS\033[0m' ]] || fail "PASS does not use normal green"
[[ "$(status_label FAIL)" == $'\033[31mFAIL\033[0m' ]] || fail "FAIL does not use normal red"
[[ "$(status_label WARN)" == $'\033[33mWARN\033[0m' ]] || fail "WARN does not use normal yellow"
[[ "$(important_value eth0)" == $'\033[34meth0\033[0m' ]] || fail "important values do not use normal blue"

COLOR_ENABLED=false
[[ "$(status_label PASS)" == 'PASS' ]] || fail "plain output contains color formatting"
[[ "$(important_value eth0)" == 'eth0' ]] || fail "plain values contain color formatting"

DEFAULT_ROUTES=('default via 192.168.77.1 dev eth0 metric 100')
INTERFACES=(eth0)
HTTPS_RESULTS[eth0]=pass
record_result PASS 'this probe result must not be repeated' >/dev/null
summary="$(print_summary)"
grep -Fq 'PASS:' <<<"${summary}" || fail "healthy summary is missing PASS"
if grep -Fq 'Diagnosis:' <<<"${summary}"; then
    fail "summary repeats its section title"
fi
if grep -Fq 'this probe result must not be repeated' <<<"${summary}"; then
    fail "summary repeats individual probe results"
fi

HTTPS_RESULTS[eth0]=fail
summary="$(print_summary)"
grep -Fq 'FAIL:' <<<"${summary}" || fail "failed HTTPS path is not diagnosed as FAIL"

# Called indirectly by inspect_sing_box.
# shellcheck disable=SC2329
pgrep() {
    return 1
}
[[ -z "$(inspect_sing_box)" ]] || fail "sing-box section appeared without a running process"
unset -f pgrep

TEST_ROOT="$(mktemp -d)"
MOCK_BIN="${TEST_ROOT}/bin"
CALLS="${TEST_ROOT}/calls"
trap 'rm -rf -- "${TEST_ROOT}"' EXIT
mkdir -p "${MOCK_BIN}"

cat >"${MOCK_BIN}/ip" <<'EOF'
#!/usr/bin/env bash
if [[ "$*" == '-4 route show default' ]]; then
    echo 'default via 127.0.0.1 dev lo metric 100'
elif [[ "$*" == '-o -4 address show dev lo scope global' ]]; then
    echo '1: lo inet 127.0.0.1/8 scope global lo'
fi
EOF

cat >"${MOCK_BIN}/getent" <<'EOF'
#!/usr/bin/env bash
echo "getent $*" >>"${DIAG_TEST_CALLS}"
echo '192.0.2.1 STREAM test.example'
EOF

cat >"${MOCK_BIN}/curl" <<'EOF'
#!/usr/bin/env bash
echo "curl $*" >>"${DIAG_TEST_CALLS}"
printf 'HTTP 200, local 127.0.0.1, connect 0.01s, TLS 0.02s'
EOF

cat >"${MOCK_BIN}/pgrep" <<'EOF'
#!/usr/bin/env bash
echo "pgrep $*" >>"${DIAG_TEST_CALLS}"
if [[ "$*" == '-x sing-box' ]]; then
    echo 4242
    exit 0
fi
exit 1
EOF

cat >"${MOCK_BIN}/systemctl" <<'EOF'
#!/usr/bin/env bash
echo "systemctl $*" >>"${DIAG_TEST_CALLS}"
echo 'sing-box.service is active'
EOF

cat >"${MOCK_BIN}/sudo" <<'EOF'
#!/usr/bin/env bash
if [[ "$*" == '-n true' ]]; then
    echo 'sudo -n true' >>"${DIAG_TEST_CALLS}"
    exit 0
fi
if [[ "$1" == '-n' && "$2" == 'jq' ]]; then
    echo 'sudo -n jq config' >>"${DIAG_TEST_CALLS}"
    printf 'inbound\tmixed-in\tmixed\t::\t2334\n'
    exit 0
fi
exit 1
EOF

chmod +x "${MOCK_BIN}"/*

DIAG_TEST_CALLS="${CALLS}" PATH="${MOCK_BIN}:${PATH}" \
    "${SCRIPT}" --interface lo --timeout 1 >"${TEST_ROOT}/output"

expected_calls=$(cat <<'EOF'
getent ahostsv4 baidu.com
getent ahostsv4 archlinux.org
getent ahostsv4 linux.do
getent ahostsv4 google.com
curl --noproxy * --ipv4 --interface lo --silent --show-error --output /dev/null --connect-timeout 1 --max-time 4 --write-out HTTP %{http_code}, local %{local_ip}, connect %{time_connect}s, TLS %{time_appconnect}s https://baidu.com/
curl --noproxy * --ipv4 --interface lo --silent --show-error --output /dev/null --connect-timeout 1 --max-time 4 --write-out HTTP %{http_code}, local %{local_ip}, connect %{time_connect}s, TLS %{time_appconnect}s https://archlinux.org/
curl --noproxy * --ipv4 --interface lo --silent --show-error --output /dev/null --connect-timeout 1 --max-time 4 --write-out HTTP %{http_code}, local %{local_ip}, connect %{time_connect}s, TLS %{time_appconnect}s https://linux.do/
curl --noproxy * --ipv4 --interface lo --silent --show-error --output /dev/null --connect-timeout 1 --max-time 4 --write-out HTTP %{http_code}, local %{local_ip}, connect %{time_connect}s, TLS %{time_appconnect}s https://google.com/
pgrep -x sing-box
systemctl status --no-pager --full --lines=0 sing-box.service
sudo -n true
sudo -n jq config
EOF
)

[[ "$(<"${CALLS}")" == "${expected_calls}" ]] || {
    diff -u <(printf '%s\n' "${expected_calls}") "${CALLS}" >&2 || true
    fail "network probes or proxy diagnostics ran in the wrong order"
}

grep -Fq 'DNS baidu.com' "${TEST_ROOT}/output" || fail "DNS result for baidu.com was not printed"
grep -Fq 'DNS google.com' "${TEST_ROOT}/output" || fail "DNS result for google.com was not printed"
grep -Fq 'sing-box.service is active' "${TEST_ROOT}/output" || fail "sing-box status was not printed"
grep -Fq 'Inbound: tag mixed-in | type mixed | listen :: | port 2334' "${TEST_ROOT}/output" || fail "sing-box inbound port was not printed"
if grep -Eq 'Process:|Recent logs:|Auto-detect default interface:' "${TEST_ROOT}/output"; then
    fail "sing-box output contains a removed process, log, or route field"
fi

if grep -Eq 'probe_ping|ping[[:space:]]+-4|inspect_proxy_process[[:space:]]+dae|pgrep[[:space:]]+-x[[:space:]]+dae' "${SCRIPT}"; then
    fail "removed ping or dae diagnostics are still present"
fi

if grep -Eq 'nmcli[[:space:]]+device[[:space:]]+(disconnect|delete)|ip[[:space:]]+route[[:space:]]+(add|del|replace)|systemctl[[:space:]]+(start|stop|restart)|sysctl[[:space:]]+-w' "${SCRIPT}"; then
    fail "a network-changing command was found"
fi

echo "PASS: all network diagnostics tests passed"
