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

if grep -Eq 'nmcli[[:space:]]+device[[:space:]]+(disconnect|delete)|ip[[:space:]]+route[[:space:]]+(add|del|replace)|systemctl[[:space:]]+(start|stop|restart)|sysctl[[:space:]]+-w' "${SCRIPT}"; then
    fail "a network-changing command was found"
fi

echo "PASS: all network diagnostics tests passed"
