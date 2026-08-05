#!/usr/bin/env bash
## diagnose-network-path-test.sh — Test the read-only network diagnostics utility
set -euo pipefail

TEST_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT="${TEST_DIR}/../diagnose-network-path.sh"

fail() {
    echo "FAIL: $*" >&2
    exit 1
}

[[ -f "${SCRIPT}" ]] || fail "diagnose-network-path.sh does not exist"
[[ -x "${SCRIPT}" ]] || fail "diagnose-network-path.sh is not executable"

# shellcheck source=../diagnose-network-path.sh
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

grep -Fq 'Default route winner' "${SCRIPT}" || fail "default-route explanation is missing"
grep -Fq 'Plain-English summary' "${SCRIPT}" || fail "plain-English summary is missing"
grep -Fq 'All tested interfaces completed the bound HTTPS check' "${SCRIPT}" || fail "healthy-path summary is missing"

if grep -Eq 'nmcli[[:space:]]+device[[:space:]]+(disconnect|delete)|ip[[:space:]]+route[[:space:]]+(add|del|replace)|systemctl[[:space:]]+(start|stop|restart)|sysctl[[:space:]]+-w' "${SCRIPT}"; then
    fail "a network-changing command was found"
fi

echo "PASS: all network diagnostics tests passed"
