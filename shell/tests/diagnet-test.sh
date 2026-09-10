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
"${SCRIPT}" --help | grep -Fq 'macOS: uname, ifconfig, netstat, dscacheutil' || fail "help output is missing macOS prerequisites"

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
map_set HTTPS_RESULT_NAMES HTTPS_RESULT_VALUES eth0 pass
record_result PASS 'this probe result must not be repeated' >/dev/null
summary="$(print_summary)"
grep -Fq 'PASS:' <<<"${summary}" || fail "healthy summary is missing PASS"
if grep -Fq 'Diagnosis:' <<<"${summary}"; then
    fail "summary repeats its section title"
fi
if grep -Fq 'this probe result must not be repeated' <<<"${summary}"; then
    fail "summary repeats individual probe results"
fi

map_set HTTPS_RESULT_NAMES HTTPS_RESULT_VALUES eth0 fail
summary="$(print_summary)"
grep -Fq 'FAIL:' <<<"${summary}" || fail "failed HTTPS path is not diagnosed as FAIL"

# Called indirectly by inspect_sing_box.
# shellcheck disable=SC2329
pgrep() {
    return 1
}
[[ -z "$(inspect_sing_box)" ]] || fail "sing-box section appeared without a running process"
# shellcheck disable=SC2329
pgrep() {
    return 1
}
[[ -z "$(inspect_dae)" ]] || fail "dae section appeared without a running process"
[[ -z "$(inspect_mihomo)" ]] || fail "mihomo section appeared without a running process"
unset -f pgrep

# The dae config path is discovered from the effective unit command line.
# shellcheck disable=SC2329
systemctl() {
    [[ "$1" == 'show' ]] || return 0
    echo '{ path=/usr/bin/dae ; argv[]=/usr/bin/dae run --disable-timestamp -c /var/lib/dae/config.dae ; ignore_errors=no ; start_time=[n/a] ; stop_time=[n/a] ; pid=0 ; code=(null) ; status=0/0 }'
}
[[ "$(service_config_path dae.service)" == '/var/lib/dae/config.dae' ]] || fail "service_config_path did not parse -c PATH from ExecStart"
# shellcheck disable=SC2329
systemctl() {
    [[ "$1" == 'show' ]] || return 0
    echo '{ path=/usr/bin/dae ; argv[]=/usr/bin/dae run --config /var/lib/dae/long.dae ; ignore_errors=no ; start_time=[n/a] ; stop_time=[n/a] ; pid=0 ; code=(null) ; status=0/0 }'
}
[[ "$(service_config_path dae.service)" == '/var/lib/dae/long.dae' ]] || fail "service_config_path did not parse --config PATH from ExecStart"
# shellcheck disable=SC2329
systemctl() {
    [[ "$1" == 'show' ]] || return 0
    echo '{ path=/usr/bin/dae ; argv[]=/usr/bin/dae run --config=/var/lib/dae/equals.dae ; ignore_errors=no ; start_time=[n/a] ; stop_time=[n/a] ; pid=0 ; code=(null) ; status=0/0 }'
}
[[ "$(service_config_path dae.service)" == '/var/lib/dae/equals.dae' ]] || fail "service_config_path did not parse --config=PATH from ExecStart"
# shellcheck disable=SC2329
systemctl() { return 0; }
if service_config_path dae.service; then
    fail "service_config_path accepted an ExecStart without a config flag"
fi
unset -f systemctl

# sing-box inbounds are parsed without jq, pretty or minified, and nested
# objects that reuse the tracked key names are ignored.
pretty_json='{
    "log": { "level": "info", "output": "/var/log/s{b}.log" },
    "inbounds": [
        {
            "type": "mixed",
            "tag": "mixed-in",
            "listen": "::",
            "listen_port": 2334,
            "sniff": { "enabled": true, "dest_port": [80, 443] }
        },
        { "type": "tun", "tag": "tun-in" }
    ],
    "outbounds": [ { "type": "direct", "tag": "direct", "listen": "1.2.3.4", "listen_port": 999 } ]
}'
expected_tsv="$(printf 'inbound\tmixed-in\tmixed\t::\t2334\ninbound\ttun-in\ttun\t-\t-')"
[[ "$(json_inbound_summary <<<"${pretty_json}")" == "${expected_tsv}" ]] ||
    fail "json_inbound_summary mis-parsed pretty-printed JSON"

minified_json='{"inbounds":[{"listen":"127.0.0.1","listen_port":1080,"tag":"s{ok}:1","type":"socks"}]}'
expected_tsv="$(printf 'inbound\ts{ok}:1\tsocks\t127.0.0.1\t1080')"
[[ "$(json_inbound_summary <<<"${minified_json}")" == "${expected_tsv}" ]] ||
    fail "json_inbound_summary mis-parsed minified JSON"

escaped_json='{"inbounds":[{"type":"mixed","tag":"quote\"tag","listen":"0.0.0.0","listen_port":1}]}'
expected_tsv="$(printf 'inbound\tquote"tag\tmixed\t0.0.0.0\t1')"
[[ "$(json_inbound_summary <<<"${escaped_json}")" == "${expected_tsv}" ]] ||
    fail "json_inbound_summary mis-parsed escaped quotes"

[[ -z "$(json_inbound_summary <<<'{"log":{"level":"warn"}}')" ]] ||
    fail "json_inbound_summary invented inbounds"


# The running state is green, and stays plain when color is disabled.
COLOR_ENABLED=true
# shellcheck disable=SC2329
systemctl() {
    printf '     Loaded: loaded (/etc/systemd/system/dae.service; enabled)\n     Active: active (running) since Wed 2026-09-02 15:43:49 CST; 1h 52min left\n'
}
status_output="$(print_service_status dae.service)"
grep -Fq $'\033[32mactive (running)\033[0m' <<<"${status_output}" || fail "active (running) is not highlighted green"
COLOR_ENABLED=false
status_output="$(print_service_status dae.service)"
grep -Fq 'Active: active (running)' <<<"${status_output}" || fail "plain service status lost the running state"
if grep -Fq $'\033[32m' <<<"${status_output}"; then
    fail "service status contains color while color is disabled"
fi
unset -f systemctl
# Proxy inbound values use the same blue highlighting as sing-box values.
COLOR_ENABLED=true
# shellcheck disable=SC2329
pgrep() { return 0; }
# shellcheck disable=SC2329
systemctl() {
    [[ "$1" == 'show' ]] || return 0
    case "$2" in
        sing-box.service)
            echo '{ path=/usr/bin/sing-box ; argv[]=/usr/bin/sing-box run -D /run/sing-box -c /run/sing-box/config.json ; ignore_errors=no ; start_time=[n/a] ; stop_time=[n/a] ; pid=0 ; code=(null) ; status=0/0 }'
            ;;
        *)
            echo '{ path=/usr/bin/dae ; argv[]=/usr/bin/dae run --disable-timestamp -c /run/dae/config.dae ; ignore_errors=no ; start_time=[n/a] ; stop_time=[n/a] ; pid=0 ; code=(null) ; status=0/0 }'
            ;;
    esac
}
# shellcheck disable=SC2329
read_config_file() {
    case "$1" in
        /run/sing-box/config.json)
            printf '{"log":{"level":"info"},"inbounds":[{"type":"mixed","tag":"mixed-in","listen":"::","listen_port":2334,"sniff":{"enabled":true}}],"outbounds":[{"type":"direct","tag":"direct"}]}'
            ;;
        /run/dae/config.dae)
            printf 'global {\n    tproxy_port: 12345\n}\n'
            ;;
        /run/mihomo/config.yaml)
            printf 'bind-address: "*"\nmixed-port: 7890\nexternal-controller: 0.0.0.0:9390\n'
            ;;
        *) return 1 ;;
    esac
}
sing_box_highlighted="$(inspect_sing_box)"
grep -Fq $'Inbound: tag \033[34mmixed-in\033[0m | type \033[34mmixed\033[0m | listen \033[34m::\033[0m | port \033[34m2334\033[0m' <<<"${sing_box_highlighted}" \
    || fail "sing-box inbound values were not highlighted"
dae_highlighted="$(inspect_dae)"
grep -Fq $'Inbound: tag \033[34mtproxy-port\033[0m | type \033[34mtproxy\033[0m | listen \033[34m0.0.0.0\033[0m | port \033[34m12345\033[0m' <<<"${dae_highlighted}" \
    || fail "dae inbound values were not highlighted"
mihomo_highlighted="$(inspect_mihomo)"
grep -Fq $'Inbound: tag \033[34mmixed-port\033[0m | type \033[34mmixed\033[0m | listen \033[34m*\033[0m | port \033[34m7890\033[0m' <<<"${mihomo_highlighted}" \
    || fail "mihomo inbound values were not highlighted"
grep -Fq $'Controller: listen \033[34m0.0.0.0\033[0m | port \033[34m9390\033[0m' <<<"${mihomo_highlighted}" \
    || fail "mihomo controller values were not highlighted"
unset -f pgrep read_config_file systemctl
COLOR_ENABLED=false

# When no sing-box config is readable, the first candidate path is reported.
# shellcheck disable=SC2329
pgrep() { return 0; }
# shellcheck disable=SC2329
systemctl() { return 1; }
# shellcheck disable=SC2329
read_config_file() { return 1; }
sing_box_unreadable="$(inspect_sing_box)"
grep -Fq 'Inbound: unavailable (/run/sing-box/config.json is not readable).' <<<"${sing_box_unreadable}" ||
    fail "an unreadable sing-box config was not reported with its path"
unset -f pgrep systemctl read_config_file

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
if [[ "$*" == '-x sing-box' || "$*" == '-x dae' || "$*" == '-x mihomo' ]]; then
    echo 4242
    exit 0
fi
exit 1
EOF

cat >"${MOCK_BIN}/systemctl" <<'EOF'
#!/usr/bin/env bash
echo "systemctl $*" >>"${DIAG_TEST_CALLS}"
if [[ "$1" == 'show' ]]; then
    if [[ "$2" == 'sing-box.service' ]]; then
        echo '{ path=/usr/bin/sing-box ; argv[]=/usr/bin/sing-box run -D /run/sing-box -c /run/sing-box/config.json ; ignore_errors=no ; start_time=[n/a] ; stop_time=[n/a] ; pid=0 ; code=(null) ; status=0/0 }'
    else
        echo '{ path=/usr/bin/dae ; argv[]=/usr/bin/dae run --disable-timestamp -c /run/dae/config.dae ; ignore_errors=no ; start_time=[n/a] ; stop_time=[n/a] ; pid=0 ; code=(null) ; status=0/0 }'
    fi
else
    echo 'Active: active (running)'
fi
EOF

cat >"${MOCK_BIN}/sudo" <<'EOF'
#!/usr/bin/env bash
if [[ "$*" == '-n true' ]]; then
    echo 'sudo -n true' >>"${DIAG_TEST_CALLS}"
    exit 0
fi
if [[ "$1" == '-n' && "$2" == 'cat' && "$3" == '/run/sing-box/config.json' ]]; then
    echo 'sudo -n cat /run/sing-box/config.json' >>"${DIAG_TEST_CALLS}"
    printf '{"log":{"level":"info"},"inbounds":[{"type":"mixed","tag":"mixed-in","listen":"::","listen_port":2334,"sniff":{"enabled":true}}],"outbounds":[{"type":"direct","tag":"direct"}]}'
    exit 0
fi
if [[ "$1" == '-n' && "$2" == 'cat' && "$3" == '/run/dae/config.dae' ]]; then
    echo 'sudo -n cat /run/dae/config.dae' >>"${DIAG_TEST_CALLS}"
    printf 'global {\n    tproxy_port: 12345\n}\n'
    exit 0
fi
if [[ "$1" == '-n' && "$2" == 'cat' && "$3" == '/run/mihomo/config.yaml' ]]; then
    echo 'sudo -n cat /run/mihomo/config.yaml' >>"${DIAG_TEST_CALLS}"
    printf 'bind-address: "*"\nmixed-port: 7890\nredir-port: 7891\ntproxy-port: 7892\nexternal-controller: 0.0.0.0:9390\n'
    exit 0
fi
exit 1
EOF

chmod +x "${MOCK_BIN}"/*

DIAG_TEST_CALLS="${CALLS}" PATH="${MOCK_BIN}:${PATH}" \
    "${SCRIPT}" --interface lo --timeout 1 >"${TEST_ROOT}/output"

expected_calls=$(cat <<'EOF'
getent ahostsv4 www.baidu.com
getent ahostsv4 www.youtube.com
getent ahostsv4 grok.com
getent ahostsv4 www.google.com
curl --noproxy * --ipv4 --interface lo --silent --show-error --output /dev/null --connect-timeout 1 --max-time 4 --write-out HTTP %{http_code}, local %{local_ip}, connect %{time_connect}s, TLS %{time_appconnect}s https://www.baidu.com/
curl --noproxy * --ipv4 --interface lo --silent --show-error --output /dev/null --connect-timeout 1 --max-time 4 --write-out HTTP %{http_code}, local %{local_ip}, connect %{time_connect}s, TLS %{time_appconnect}s https://www.youtube.com/
curl --noproxy * --ipv4 --interface lo --silent --show-error --output /dev/null --connect-timeout 1 --max-time 4 --write-out HTTP %{http_code}, local %{local_ip}, connect %{time_connect}s, TLS %{time_appconnect}s https://grok.com/
curl --noproxy * --ipv4 --interface lo --silent --show-error --output /dev/null --connect-timeout 1 --max-time 4 --write-out HTTP %{http_code}, local %{local_ip}, connect %{time_connect}s, TLS %{time_appconnect}s https://www.google.com/
pgrep -x sing-box
systemctl status --no-pager --full --lines=0 sing-box.service
systemctl show sing-box.service --property=ExecStart --value
sudo -n true
sudo -n cat /run/sing-box/config.json
pgrep -x dae
systemctl status --no-pager --full --lines=0 dae.service
systemctl show dae.service --property=ExecStart --value
sudo -n true
sudo -n cat /run/dae/config.dae
pgrep -x mihomo
systemctl status --no-pager --full --lines=0 mihomo.service
sudo -n true
sudo -n cat /run/mihomo/config.yaml
EOF
)

[[ "$(<"${CALLS}")" == "${expected_calls}" ]] || {
    diff -u <(printf '%s\n' "${expected_calls}") "${CALLS}" >&2 || true
    fail "network probes or proxy diagnostics ran in the wrong order"
}

grep -Fq 'DNS www.baidu.com' "${TEST_ROOT}/output" || fail "DNS result for www.baidu.com was not printed"
grep -Fq 'DNS www.google.com' "${TEST_ROOT}/output" || fail "DNS result for www.google.com was not printed"
grep -Fq 'Active: active (running)' "${TEST_ROOT}/output" || fail "sing-box status was not printed"
grep -Fq 'Inbound: tag mixed-in | type mixed | listen :: | port 2334' "${TEST_ROOT}/output" || fail "sing-box inbound port was not printed"
grep -Fq '── dae ──' "${TEST_ROOT}/output" || fail "dae status section was not printed"
grep -Fq 'Inbound: tag tproxy-port | type tproxy | listen 0.0.0.0 | port 12345' "${TEST_ROOT}/output" || fail "dae inbound port was not printed"
grep -Fq '── mihomo ──' "${TEST_ROOT}/output" || fail "mihomo status section was not printed"
grep -Fq 'Inbound: tag mixed-port | type mixed | listen * | port 7890' "${TEST_ROOT}/output" || fail "mihomo mixed port was not printed"
grep -Fq 'Inbound: tag redir-port | type redir | listen * | port 7891' "${TEST_ROOT}/output" || fail "mihomo redir port was not printed"
grep -Fq 'Inbound: tag tproxy-port | type tproxy | listen * | port 7892' "${TEST_ROOT}/output" || fail "mihomo tproxy port was not printed"
grep -Fq 'Controller: listen 0.0.0.0 | port 9390' "${TEST_ROOT}/output" || fail "mihomo controller was not printed"
if grep -Eq 'Process:|Recent logs:|Auto-detect default interface:' "${TEST_ROOT}/output"; then
    fail "sing-box output contains a removed process, log, or route field"
fi

if grep -Eq 'probe_ping|ping[[:space:]]+-4|inspect_proxy_process' "${SCRIPT}"; then
    fail "removed ping diagnostics are still present"
fi

if grep -Fq '/run/secrets/dae-config.dae' "${SCRIPT}"; then
    fail "the stale dae secret-store config path is still referenced"
fi

if grep -Fq 'jq' "${SCRIPT}"; then
    fail "jq is still referenced by the script"
fi

if grep -Eq 'nmcli[[:space:]]+device[[:space:]]+(disconnect|delete)|ip[[:space:]]+route[[:space:]]+(add|del|replace)|systemctl[[:space:]]+(start|stop|restart)|sysctl[[:space:]]+-w' "${SCRIPT}"; then
    fail "a network-changing command was found"
fi

MAC_TEST_ROOT="${TEST_ROOT}/mac"
MAC_MOCK_BIN="${MAC_TEST_ROOT}/bin"
MAC_CALLS="${MAC_TEST_ROOT}/calls"
mkdir -p "${MAC_MOCK_BIN}"

cat >"${MAC_MOCK_BIN}/uname" <<'EOF'
#!/usr/bin/env bash
[[ "$1" == '-s' ]] && echo Darwin
EOF

cat >"${MAC_MOCK_BIN}/netstat" <<'EOF'
#!/usr/bin/env bash
if [[ "$*" == '-rn -f inet' ]]; then
    cat <<'ROUTES'
Routing tables
Internet:
Destination        Gateway            Flags        Netif Expire
default            192.0.2.1          UGScg        en0
ROUTES
fi
EOF

cat >"${MAC_MOCK_BIN}/ifconfig" <<'EOF'
#!/usr/bin/env bash
if [[ "$1" == '-l' ]]; then
    echo 'lo0 en0'
    exit 0
fi
if [[ "$1" == 'en0' ]]; then
    cat <<'IFCONFIG'
en0: flags=8863<UP,BROADCAST,SMART,RUNNING,SIMPLEX,MULTICAST>
    inet 192.0.2.10 netmask 0xffffff00 broadcast 192.0.2.255
    status: active
    media: autoselect (1000baseT <full-duplex>)
IFCONFIG
    exit 0
fi
exit 1
EOF

cat >"${MAC_MOCK_BIN}/dscacheutil" <<'EOF'
#!/usr/bin/env bash
echo "dscacheutil $*" >>"${DIAG_TEST_CALLS}"
cat <<'DNS'
name: example.test
ip_address: 192.0.2.53
DNS
EOF

cat >"${MAC_MOCK_BIN}/curl" <<'EOF'
#!/usr/bin/env bash
echo "curl $*" >>"${DIAG_TEST_CALLS}"
printf 'HTTP 200, local 192.0.2.10, connect 0.01s, TLS 0.02s'
EOF

cat >"${MAC_MOCK_BIN}/pgrep" <<'EOF'
#!/usr/bin/env bash
echo "pgrep $*" >>"${DIAG_TEST_CALLS}"
exit 1
EOF

chmod +x "${MAC_MOCK_BIN}"/*

DIAG_TEST_CALLS="${MAC_CALLS}" PATH="${MAC_MOCK_BIN}:${PATH}" \
    "${SCRIPT}" --timeout 1 >"${MAC_TEST_ROOT}/output"

grep -Fq 'Default: en0 via 192.0.2.1' "${MAC_TEST_ROOT}/output" || fail "macOS default route was not diagnosed"
grep -Fq 'en0  IPv4 192.0.2.10/24 | gateway 192.0.2.1 | carrier yes | speed 1000 Mbps' "${MAC_TEST_ROOT}/output" || { sed -n '1,80p' "${MAC_TEST_ROOT}/output" >&2; fail "macOS interface details were not diagnosed"; }
grep -Fq 'DNS www.baidu.com: 192.0.2.53.' "${MAC_TEST_ROOT}/output" || fail "macOS DNS resolution was not diagnosed"
grep -Fq 'en0 HTTPS www.baidu.com: HTTP 200' "${MAC_TEST_ROOT}/output" || fail "macOS HTTPS probing was not diagnosed"
if grep -Eq 'missing required commands|/sys/class/net|ip -4 route|getent ahostsv4' "${MAC_TEST_ROOT}/output"; then
    fail "macOS diagnostics reported Linux-only prerequisites"
fi

if DIAG_TEST_CALLS="${MAC_CALLS}" PATH="${MAC_MOCK_BIN}:${PATH}" \
    "${SCRIPT}" --interface interface-that-does-not-exist >/dev/null 2>&1; then
    fail "a nonexistent macOS interface was accepted"
fi

echo "PASS: all network diagnostics tests passed"
