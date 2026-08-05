#!/usr/bin/env bash
## diagnose-network-path.sh — Compare default-route and interface-bound network paths
## Usage: ./diagnose-network-path.sh [--interface NAME]... [--gateway ADDRESS] [--timeout SECONDS]
set -euo pipefail

TIMEOUT=4
GATEWAY_OVERRIDE=""
INTERFACES=()
DEFAULT_ROUTES=()
SUMMARY_MESSAGES=()
declare -A HTTPS_RESULTS=()
declare -A INTERFACE_GATEWAYS=()
declare -A INTERFACE_NETWORKS=()

print_help() {
    cat <<'EOF'
Read-only network path diagnostics

Usage:
  diagnose-network-path.sh [OPTIONS]

Options:
  --interface NAME     Test only this interface. May be repeated.
  --gateway ADDRESS    Override the gateway for one selected interface.
  --timeout SECONDS    Per-probe timeout in seconds. Default: 4.
  -h, --help           Show this help.

The script does not disconnect interfaces, change routes, or restart services.
Network failures are reported as findings and do not change the exit status.
EOF
}

route_field() {
    local route="$1"
    local field="$2"

    awk -v field="${field}" '
        {
            for (i = 1; i <= NF; i++) {
                if ($i == field && i < NF) {
                    print $(i + 1)
                    exit
                }
            }
        }
    ' <<<"${route}"
}

route_device() {
    route_field "$1" dev
}

route_gateway() {
    route_field "$1" via
}

route_metric() {
    local metric

    metric="$(route_field "$1" metric)"
    printf '%s\n' "${metric:-0}"
}

carrier_label() {
    case "${1:-}" in
        1) printf 'yes\n' ;;
        0) printf 'no\n' ;;
        *) printf 'unknown\n' ;;
    esac
}

speed_label() {
    local speed="${1:-}"

    if [[ "${speed}" =~ ^[0-9]+$ ]]; then
        printf '%s Mbps\n' "${speed}"
    else
        printf 'unknown\n'
    fi
}

is_ipv4_address() {
    local address="$1"
    local octet
    local -a octets=()

    IFS=. read -r -a octets <<<"${address}"
    ((${#octets[@]} == 4)) || return 1
    for octet in "${octets[@]}"; do
        [[ "${octet}" =~ ^[0-9]{1,3}$ ]] || return 1
        ((10#${octet} <= 255)) || return 1
    done
}

add_interface() {
    local candidate="$1"
    local existing

    [[ -n "${candidate}" ]] || return 0
    for existing in "${INTERFACES[@]}"; do
        [[ "${existing}" != "${candidate}" ]] || return 0
    done
    INTERFACES+=("${candidate}")
}

parse_args() {
    while (($# > 0)); do
        case "$1" in
            --interface)
                (($# >= 2)) || {
                    echo "Error: --interface requires a device name." >&2
                    return 2
                }
                add_interface "$2"
                shift 2
                ;;
            --gateway)
                (($# >= 2)) || {
                    echo "Error: --gateway requires an IPv4 address." >&2
                    return 2
                }
                is_ipv4_address "$2" || {
                    echo "Error: --gateway must be a valid IPv4 address." >&2
                    return 2
                }
                GATEWAY_OVERRIDE="$2"
                shift 2
                ;;
            --timeout)
                (($# >= 2)) || {
                    echo "Error: --timeout requires a positive number." >&2
                    return 2
                }
                [[ "$2" =~ ^[1-9][0-9]*$ ]] || {
                    echo "Error: --timeout must be a positive whole number." >&2
                    return 2
                }
                TIMEOUT="$2"
                shift 2
                ;;
            -h | --help)
                print_help
                exit 0
                ;;
            *)
                echo "Error: unknown option: $1" >&2
                echo "Run with --help to see valid options." >&2
                return 2
                ;;
        esac
    done
}

require_commands() {
    local command_name
    local missing=()

    for command_name in ip ping curl awk; do
        command -v "${command_name}" >/dev/null 2>&1 || missing+=("${command_name}")
    done

    if ((${#missing[@]} > 0)); then
        echo "Error: missing required commands: ${missing[*]}" >&2
        return 2
    fi
}

have_command() {
    command -v "$1" >/dev/null 2>&1
}

print_section() {
    printf '\n=== %s ===\n' "$1"
}

record_result() {
    local level="$1"
    shift
    local message="$*"

    printf '%s: %s\n' "${level}" "${message}"
    SUMMARY_MESSAGES+=("${level}: ${message}")
}

collect_default_routes() {
    mapfile -t DEFAULT_ROUTES < <(ip -4 route show default 2>/dev/null || true)
}

discover_interfaces() {
    local route
    local interface_name

    if ((${#INTERFACES[@]} == 0)); then
        for route in "${DEFAULT_ROUTES[@]}"; do
            add_interface "$(route_device "${route}")"
        done
    fi

    if ((${#INTERFACES[@]} == 0)); then
        while IFS= read -r interface_name; do
            [[ "${interface_name}" != "lo" ]] || continue
            add_interface "${interface_name}"
        done < <(ip -o -4 address show up scope global | awk '{print $2}' | sort -u)
    fi

    if ((${#INTERFACES[@]} == 0)); then
        echo "Error: no active IPv4 interfaces were found." >&2
        return 2
    fi

    for interface_name in "${INTERFACES[@]}"; do
        if [[ ! -d "/sys/class/net/${interface_name}" ]]; then
            echo "Error: interface does not exist: ${interface_name}" >&2
            return 2
        fi
    done

    if [[ -n "${GATEWAY_OVERRIDE}" && ${#INTERFACES[@]} -ne 1 ]]; then
        echo "Error: --gateway can only be used with exactly one --interface." >&2
        return 2
    fi
}

find_interface_route() {
    local wanted_interface="$1"
    local route

    for route in "${DEFAULT_ROUTES[@]}"; do
        if [[ "$(route_device "${route}")" == "${wanted_interface}" ]]; then
            printf '%s\n' "${route}"
            return 0
        fi
    done
    return 1
}

find_winning_route() {
    local route
    local winner=""
    local winner_metric=2147483647
    local metric

    for route in "${DEFAULT_ROUTES[@]}"; do
        metric="$(route_metric "${route}")"
        if ((metric < winner_metric)); then
            winner="${route}"
            winner_metric="${metric}"
        fi
    done

    [[ -n "${winner}" ]] && printf '%s\n' "${winner}"
}

print_default_routes() {
    local route
    local winner
    local winner_interface
    local winner_metric

    print_section "Default routes"
    if ((${#DEFAULT_ROUTES[@]} == 0)); then
        record_result FAIL "No IPv4 default route is installed. Internet destinations have no general path."
        return 0
    fi

    for route in "${DEFAULT_ROUTES[@]}"; do
        printf 'Route: %s\n' "${route}"
    done

    winner="$(find_winning_route)"
    winner_interface="$(route_device "${winner}")"
    winner_metric="$(route_metric "${winner}")"
    printf 'Default route winner: %s (metric %s)\n' "${winner_interface}" "${winner_metric}"
    printf 'Meaning: traffic without a more specific route normally uses %s because it has the lowest metric.\n' "${winner_interface}"
}

interface_ipv4_cidr() {
    ip -o -4 address show dev "$1" scope global 2>/dev/null | awk 'NR == 1 {print $4}'
}

ipv4_network() {
    local cidr="$1"
    local address="${cidr%/*}"
    local prefix="${cidr#*/}"
    local a b c d
    local value mask network

    [[ "${address}" != "${prefix}" && "${prefix}" =~ ^[0-9]+$ ]] || return 1
    ((prefix >= 0 && prefix <= 32)) || return 1
    IFS=. read -r a b c d <<<"${address}"
    [[ -n "${a:-}" && -n "${b:-}" && -n "${c:-}" && -n "${d:-}" ]] || return 1

    value=$(((a << 24) | (b << 16) | (c << 8) | d))
    if ((prefix == 0)); then
        mask=0
    else
        mask=$(((0xFFFFFFFF << (32 - prefix)) & 0xFFFFFFFF))
    fi
    network=$((value & mask))

    printf '%d.%d.%d.%d/%d\n' \
        $(((network >> 24) & 255)) \
        $(((network >> 16) & 255)) \
        $(((network >> 8) & 255)) \
        $((network & 255)) \
        "${prefix}"
}

interface_gateway() {
    local interface_name="$1"
    local route=""

    if [[ -n "${GATEWAY_OVERRIDE}" ]]; then
        printf '%s\n' "${GATEWAY_OVERRIDE}"
        return 0
    fi

    route="$(find_interface_route "${interface_name}" || true)"
    route_gateway "${route}"
}

print_interface_details() {
    local interface_name="$1"
    local cidr
    local gateway
    local route
    local carrier_raw=""
    local speed_raw=""

    cidr="$(interface_ipv4_cidr "${interface_name}")"
    gateway="$(interface_gateway "${interface_name}")"
    route="$(find_interface_route "${interface_name}" || true)"
    INTERFACE_GATEWAYS["${interface_name}"]="${gateway}"

    if [[ -n "${cidr}" ]]; then
        INTERFACE_NETWORKS["${interface_name}"]="$(ipv4_network "${cidr}" || true)"
    fi
    [[ -r "/sys/class/net/${interface_name}/carrier" ]] && carrier_raw="$(<"/sys/class/net/${interface_name}/carrier")"
    [[ -r "/sys/class/net/${interface_name}/speed" ]] && speed_raw="$(<"/sys/class/net/${interface_name}/speed")"

    printf 'Interface: %s\n' "${interface_name}"
    printf '  IPv4 address: %s\n' "${cidr:-none}"
    printf '  Carrier: %s\n' "$(carrier_label "${carrier_raw}")"
    printf '  Link speed: %s\n' "$(speed_label "${speed_raw}")"
    printf '  Gateway: %s\n' "${gateway:-none}"
    if [[ -n "${route}" ]]; then
        printf '  Default-route metric: %s\n' "$(route_metric "${route}")"
    else
        printf '  Default-route metric: none\n'
    fi

    if have_command nmcli; then
        local nm_state
        local nm_connection
        nm_state="$(nmcli -g GENERAL.STATE device show "${interface_name}" 2>/dev/null || true)"
        nm_connection="$(nmcli -g GENERAL.CONNECTION device show "${interface_name}" 2>/dev/null || true)"
        printf '  NetworkManager state: %s\n' "${nm_state:-unknown}"
        printf '  NetworkManager connection: %s\n' "${nm_connection:---}"
    fi

    if have_command ethtool; then
        local detected
        detected="$(ethtool "${interface_name}" 2>/dev/null | awk -F': ' '/Link detected:/ {print $2; exit}')"
        [[ -z "${detected}" ]] || printf '  Link detected by driver: %s\n' "${detected}"
    fi
}

probe_ping() {
    local interface_name="$1"
    local target="$2"
    local label="$3"

    if ping -4 -I "${interface_name}" -c 2 -W "${TIMEOUT}" "${target}" >/dev/null 2>&1; then
        record_result PASS "${interface_name} can reach ${label} ${target}."
        return 0
    fi

    record_result WARN "${interface_name} received no ping reply from ${label} ${target}. ICMP may be blocked, so HTTPS is tested next."
    return 1
}

probe_https() {
    local interface_name="$1"
    local output
    local max_time=$((TIMEOUT + 3))

    if output="$(curl \
        --noproxy '*' \
        --ipv4 \
        --interface "${interface_name}" \
        --silent \
        --show-error \
        --output /dev/null \
        --resolve 'dns.alidns.com:443:223.5.5.5' \
        --connect-timeout "${TIMEOUT}" \
        --max-time "${max_time}" \
        --write-out 'HTTP %{http_code}, local %{local_ip}, connect %{time_connect}s, TLS %{time_appconnect}s' \
        'https://dns.alidns.com/dns-query' 2>&1)"; then
        HTTPS_RESULTS["${interface_name}"]=pass
        record_result PASS "${interface_name} completed an interface-bound HTTPS handshake (${output})."
        return 0
    fi

    HTTPS_RESULTS["${interface_name}"]=fail
    output="${output//$'\n'/ }"
    record_result FAIL "${interface_name} could not complete an interface-bound HTTPS handshake (${output})."
    return 1
}

probe_unbound_baseline() {
    local output
    local max_time=$((TIMEOUT + 3))

    print_section "Unbound baseline"
    if output="$(curl \
        --noproxy '*' \
        --ipv4 \
        --silent \
        --show-error \
        --output /dev/null \
        --resolve 'dns.alidns.com:443:223.5.5.5' \
        --connect-timeout "${TIMEOUT}" \
        --max-time "${max_time}" \
        --write-out 'HTTP %{http_code}, local %{local_ip}, connect %{time_connect}s, TLS %{time_appconnect}s' \
        'https://dns.alidns.com/dns-query' 2>&1)"; then
        record_result PASS "An unbound HTTPS request succeeded (${output})."
    else
        output="${output//$'\n'/ }"
        record_result FAIL "The unbound HTTPS baseline failed (${output})."
    fi
}

check_shared_networks() {
    local left right

    print_section "Multi-interface checks"
    if ((${#INTERFACES[@]} < 2)); then
        printf 'Only one interface is being tested. No overlap comparison is needed.\n'
        return 0
    fi

    local found_overlap=false
    for ((left = 0; left < ${#INTERFACES[@]}; left++)); do
        for ((right = left + 1; right < ${#INTERFACES[@]}; right++)); do
            local left_name="${INTERFACES[left]}"
            local right_name="${INTERFACES[right]}"
            local left_gateway="${INTERFACE_GATEWAYS[${left_name}]:-}"
            local right_gateway="${INTERFACE_GATEWAYS[${right_name}]:-}"
            local left_network="${INTERFACE_NETWORKS[${left_name}]:-}"
            local right_network="${INTERFACE_NETWORKS[${right_name}]:-}"

            if [[ -n "${left_gateway}" && "${left_gateway}" == "${right_gateway}" ]]; then
                record_result WARN "${left_name} and ${right_name} use the same gateway ${left_gateway}. The lower default-route metric normally wins."
                found_overlap=true
            fi
            if [[ -n "${left_network}" && "${left_network}" == "${right_network}" ]]; then
                record_result WARN "${left_name} and ${right_name} are both on ${left_network}. Binding an application to the wrong interface can expose a broken path."
                found_overlap=true
            fi
        done
    done

    if [[ "${found_overlap}" == false ]]; then
        record_result PASS "No duplicate gateway or connected IPv4 network was found among the tested interfaces."
    fi
}

inspect_sing_box() {
    local config_path="/run/sing-box/config.json"
    local auto_detect=""
    local socket_interfaces=""

    print_section "sing-box integration"
    if ! have_command systemctl || ! systemctl is-active --quiet sing-box.service 2>/dev/null; then
        printf 'sing-box is not active, so there is no automatic interface selection to inspect.\n'
        return 0
    fi

    printf 'sing-box service: active\n'
    if have_command jq; then
        if [[ -r "${config_path}" ]]; then
            auto_detect="$(jq -r '.route.auto_detect_interface // false' "${config_path}" 2>/dev/null || true)"
        elif have_command sudo && sudo -n true 2>/dev/null; then
            auto_detect="$(sudo -n jq -r '.route.auto_detect_interface // false' "${config_path}" 2>/dev/null || true)"
        fi
    fi

    if [[ -n "${auto_detect}" ]]; then
        printf 'sing-box auto-detects the default interface: %s\n' "${auto_detect}"
    else
        printf 'The generated sing-box route setting could not be read without prompting for privileges.\n'
    fi

    if have_command ss; then
        if have_command sudo && sudo -n true 2>/dev/null; then
            socket_interfaces="$(sudo -n ss -Htnpe state syn-sent 2>/dev/null \
                | awk '/sing-box/ && match($4, /%[^: ]+/) {print substr($4, RSTART + 1, RLENGTH - 1)}' \
                | sort -u \
                | paste -sd, -)"
        fi
        [[ -z "${socket_interfaces}" ]] || printf 'Interfaces on pending sing-box TCP sockets: %s\n' "${socket_interfaces}"
    fi
}

print_summary() {
    local message
    local winner
    local winner_interface=""
    local alternative
    local interface_name
    local tested_count=0
    local passed_count=0

    print_section "Plain-English summary"
    for message in "${SUMMARY_MESSAGES[@]}"; do
        printf '%s\n' "${message}"
    done

    winner="$(find_winning_route || true)"
    [[ -z "${winner}" ]] || winner_interface="$(route_device "${winner}")"
    if [[ -n "${winner_interface}" && "${HTTPS_RESULTS[${winner_interface}]:-}" == fail ]]; then
        for alternative in "${INTERFACES[@]}"; do
            if [[ "${HTTPS_RESULTS[${alternative}]:-}" == pass ]]; then
                printf '\nDiagnosis: %s wins the default route but fails when traffic is bound to it. %s has a working bound path.\n' \
                    "${winner_interface}" "${alternative}"
                printf 'Likely impact: software that auto-detects and binds the default interface can lose connectivity even while other applications still work.\n'
                printf 'Suggested next check: inspect the cable, switch port, VLAN, DHCP lease, or gateway policy for %s.\n' "${winner_interface}"
                return 0
            fi
        done
    fi

    for interface_name in "${INTERFACES[@]}"; do
        if [[ -n "${HTTPS_RESULTS[${interface_name}]:-}" ]]; then
            ((tested_count += 1))
        fi
        if [[ "${HTTPS_RESULTS[${interface_name}]:-}" == pass ]]; then
            ((passed_count += 1))
        fi
    done
    if ((tested_count > 0 && tested_count == passed_count)); then
        printf '\nDiagnosis: All tested interfaces completed the bound HTTPS check. The earlier path failure is not currently reproduced.\n'
        printf 'The route warnings still matter: software using automatic interface selection will prefer the lowest metric.\n'
        return 0
    fi

    printf '\nDiagnosis: review the FAIL and WARN lines above; no network settings were changed.\n'
}

main() {
    local interface_name
    local gateway

    parse_args "$@"
    require_commands
    collect_default_routes
    discover_interfaces

    printf 'Network path diagnostics started. No settings will be changed.\n'
    print_default_routes
    probe_unbound_baseline

    for interface_name in "${INTERFACES[@]}"; do
        print_section "Interface ${interface_name}"
        print_interface_details "${interface_name}"
        gateway="${INTERFACE_GATEWAYS[${interface_name}]:-}"
        if [[ -n "${gateway}" ]]; then
            probe_ping "${interface_name}" "${gateway}" gateway || true
        else
            record_result WARN "${interface_name} has no discovered gateway, so the gateway ping was skipped."
        fi
        probe_ping "${interface_name}" 223.5.5.5 "public IP" || true
        probe_https "${interface_name}" || true
    done

    check_shared_networks
    inspect_sing_box
    print_summary

    printf '\nNetwork path diagnostics completed.\n'
}

if [[ "${NETWORK_DIAG_SOURCE_ONLY:-0}" != 1 ]]; then
    main "$@"
fi
