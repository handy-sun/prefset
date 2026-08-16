#!/usr/bin/env bash
## diagnet.sh — Compare default-route and interface-bound network paths
## Usage: ./diagnet.sh [--interface NAME]... [--gateway ADDRESS] [--timeout SECONDS] [--verbose]
set -euo pipefail

TIMEOUT=4
GATEWAY_OVERRIDE=""
VERBOSE=false
COLOR_ENABLED=false
INTERFACES=()
DEFAULT_ROUTES=()
TEST_SITES=(baidu.com midjourney.com openai.com google.com)
declare -A HTTPS_RESULTS=()
declare -A INTERFACE_GATEWAYS=()
declare -A INTERFACE_NETWORKS=()

print_help() {
    cat <<'EOF'
Read-only network path diagnostics

Usage:
  diagnet.sh [OPTIONS]

Options:
  --interface NAME     Test only this interface. May be repeated.
  --gateway ADDRESS    Override the gateway for one selected interface.
  --timeout SECONDS    Per-probe timeout in seconds. Default: 4.
  --verbose            Show raw routes, adapter details, and probe timings.
  -h, --help           Show this help.

The script does not disconnect interfaces, change routes, or restart services.
Network failures are reported as findings and do not change the exit status.
EOF
}

init_output() {
    if [[ -t 1 && -z "${NO_COLOR+x}" ]]; then
        COLOR_ENABLED=true
    else
        COLOR_ENABLED=false
    fi
}

color_text() {
    local color_code="$1"
    shift

    if [[ "${COLOR_ENABLED}" == true ]]; then
        printf '\033[%sm%s\033[0m' "${color_code}" "$*"
    else
        printf '%s' "$*"
    fi
}

status_label() {
    case "$1" in
        PASS) color_text 32 PASS ;;
        FAIL) color_text 31 FAIL ;;
        WARN) color_text 33 WARN ;;
        *) printf '%s' "$1" ;;
    esac
}

important_value() {
    color_text 34 "$*"
}

verbose_printf() {
    [[ "${VERBOSE}" == true ]] || return 0
    # The callers provide constant format strings; this is a printf-compatible wrapper.
    # shellcheck disable=SC2059
    printf "$@"
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
            --verbose)
                VERBOSE=true
                shift
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

    for command_name in ip getent curl pgrep awk; do
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
    printf '\n%s\n' "$(color_text 36 "── $1 ──")"
}

record_result() {
    local level="$1"
    shift
    local message="$*"

    printf '%s: %s\n' "$(status_label "${level}")" "${message}"
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
    local winner_gateway
    local winner_metric

    print_section "Routing"
    if ((${#DEFAULT_ROUTES[@]} == 0)); then
        record_result FAIL "No IPv4 default route."
        return 0
    fi

    for route in "${DEFAULT_ROUTES[@]}"; do
        verbose_printf 'Raw route: %s\n' "${route}"
    done

    winner="$(find_winning_route)"
    winner_interface="$(route_device "${winner}")"
    winner_gateway="$(route_gateway "${winner}")"
    winner_metric="$(route_metric "${winner}")"
    printf 'Default: %s via %s (metric %s)\n' \
        "$(important_value "${winner_interface}")" \
        "$(important_value "${winner_gateway:-direct}")" \
        "$(important_value "${winner_metric}")"
    verbose_printf 'Selection: lowest default-route metric wins.\n'
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

    printf '%s  IPv4 %s | gateway %s | carrier %s | speed %s | metric %s\n' \
        "$(important_value "${interface_name}")" \
        "$(important_value "${cidr:-none}")" \
        "$(important_value "${gateway:-none}")" \
        "$(carrier_label "${carrier_raw}")" \
        "$(speed_label "${speed_raw}")" \
        "$([[ -n "${route}" ]] && route_metric "${route}" || printf 'none')"

    if [[ "${VERBOSE}" == true ]] && have_command nmcli; then
        local nm_state
        local nm_connection
        nm_state="$(nmcli -g GENERAL.STATE device show "${interface_name}" 2>/dev/null || true)"
        nm_connection="$(nmcli -g GENERAL.CONNECTION device show "${interface_name}" 2>/dev/null || true)"
        printf '  NetworkManager state: %s\n' "${nm_state:-unknown}"
        printf '  NetworkManager connection: %s\n' "${nm_connection:---}"
    fi

    if [[ "${VERBOSE}" == true ]] && have_command ethtool; then
        local detected
        detected="$(ethtool "${interface_name}" 2>/dev/null | awk -F': ' '/Link detected:/ {print $2; exit}')"
        [[ -z "${detected}" ]] || printf '  Link detected by driver: %s\n' "${detected}"
    fi
}

probe_dns() {
    local target="$1"
    local output
    local addresses

    if output="$(getent ahostsv4 "${target}" 2>&1)"; then
        addresses="$(awk '{print $1}' <<<"${output}" | sort -u | paste -sd, -)"
        record_result PASS "DNS ${target}: ${addresses}."
        verbose_printf '  DNS detail:\n%s\n' "${output}"
        return 0
    fi

    output="${output//$'\n'/ }"
    record_result FAIL "DNS ${target}: ${output:-no IPv4 address returned}."
    return 1
}

probe_https() {
    local interface_name="$1"
    local target="$2"
    local output
    local max_time=$((TIMEOUT + 3))

    if output="$(curl \
        --noproxy '*' \
        --ipv4 \
        --interface "${interface_name}" \
        --silent \
        --show-error \
        --output /dev/null \
        --connect-timeout "${TIMEOUT}" \
        --max-time "${max_time}" \
        --write-out 'HTTP %{http_code}, local %{local_ip}, connect %{time_connect}s, TLS %{time_appconnect}s' \
        "https://${target}/" 2>&1)"; then
        if [[ "${HTTPS_RESULTS[${interface_name}]:-}" != fail ]]; then
            HTTPS_RESULTS["${interface_name}"]=pass
        fi
        record_result PASS "$(important_value "${interface_name}") HTTPS ${target}: ${output}."
        verbose_printf '  HTTPS detail: %s\n' "${output}"
        return 0
    fi

    HTTPS_RESULTS["${interface_name}"]=fail
    output="${output//$'\n'/ }"
    record_result FAIL "$(important_value "${interface_name}") HTTPS ${target}: ${output}"
    return 1
}

check_shared_networks() {
    local left right

    if ((${#INTERFACES[@]} < 2)); then
        if [[ "${VERBOSE}" == true ]]; then
            print_section "Interface overlap"
            printf 'Only one interface; overlap check skipped.\n'
        fi
        return 0
    fi

    print_section "Interface overlap"

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
                record_result WARN "$(important_value "${left_name}") and $(important_value "${right_name}") share gateway ${left_gateway}; the lower route metric wins."
                found_overlap=true
            fi
            if [[ -n "${left_network}" && "${left_network}" == "${right_network}" ]]; then
                record_result WARN "$(important_value "${left_name}") and $(important_value "${right_name}") share ${left_network}; bound traffic may use the wrong path."
                found_overlap=true
            fi
        done
    done

    if [[ "${found_overlap}" == false ]]; then
        record_result PASS "No shared gateway or IPv4 network."
    fi
}

inspect_sing_box() {
    local unit_name="sing-box.service"
    local config_path="/run/sing-box/config.json"
    local config_summary=""
    local jq_filter
    local kind field1 field2 field3 field4
    local inbound_count=0

    if ! pgrep -x sing-box >/dev/null 2>&1; then
        return 0
    fi

    print_section "sing-box"
    if have_command systemctl; then
        printf 'Service status:\n'
        systemctl status --no-pager --full --lines=0 "${unit_name}" 2>&1 | grep -E 'Loaded:|Active:'|| true
    else
        printf 'Service status: unavailable (systemctl is not installed).\n'
    fi

    if ! have_command jq; then
        printf 'Inbound: unavailable (jq is not installed).\n'
        return 0
    fi

    jq_filter='.inbounds[]? | ([
            "inbound",
            (.tag // "-"),
            (.type // "-"),
            (.listen // "-"),
            ((.listen_port // "-") | tostring)
        ] | @tsv)'

    if [[ -r "${config_path}" ]]; then
        config_summary="$(jq -r "${jq_filter}" "${config_path}" 2>/dev/null || true)"
    elif have_command sudo && sudo -n true 2>/dev/null; then
        config_summary="$(sudo -n jq -r "${jq_filter}" "${config_path}" 2>/dev/null || true)"
    else
        printf 'Inbound: unavailable (%s is not readable).\n' "${config_path}"
        return 0
    fi

    if [[ -z "${config_summary}" ]]; then
        printf 'Inbound: none configured or configuration could not be read.\n'
        return 0
    fi

    while IFS=$'\t' read -r kind field1 field2 field3 field4; do
        case "${kind}" in
            inbound)
                printf 'Inbound: tag %s | type %s | listen %s | port %s\n' \
                    "$(important_value "${field1}")" \
                    "$(important_value "${field2}")" \
                    "$(important_value "${field3}")" \
                    "$(important_value "${field4}")"
                ((inbound_count += 1))
                ;;
        esac
    done <<<"${config_summary}"

    if ((inbound_count == 0)); then
        printf 'Inbound: none configured.\n'
    fi
}

print_summary() {
    local winner
    local winner_interface=""
    local alternative
    local interface_name
    local tested_count=0
    local passed_count=0
    local failed_count=0

    print_section "Diagnosis"

    winner="$(find_winning_route || true)"
    [[ -z "${winner}" ]] || winner_interface="$(route_device "${winner}")"
    if [[ -n "${winner_interface}" && "${HTTPS_RESULTS[${winner_interface}]:-}" == fail ]]; then
        for alternative in "${INTERFACES[@]}"; do
            if [[ "${HTTPS_RESULTS[${alternative}]:-}" == pass ]]; then
                printf '%s: Default route %s fails; %s works.\n' \
                    "$(status_label FAIL)" \
                    "$(important_value "${winner_interface}")" \
                    "$(important_value "${alternative}")"
                printf 'Next: check cable, switch port, VLAN, DHCP, or gateway policy for %s.\n' \
                    "$(important_value "${winner_interface}")"
                verbose_printf 'Impact: software bound to the auto-detected default interface can lose connectivity.\n'
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
        elif [[ "${HTTPS_RESULTS[${interface_name}]:-}" == fail ]]; then
            ((failed_count += 1))
        fi
    done
    if ((tested_count > 0 && tested_count == passed_count)); then
        printf '%s: All %s tested interface path(s) work.\n' \
            "$(status_label PASS)" "${tested_count}"
        verbose_printf 'Automatic interface selection still follows the lowest route metric.\n'
        return 0
    fi

    if ((failed_count > 0)); then
        printf '%s: One or more interface paths failed; review the lines above.\n' "$(status_label FAIL)"
    else
        printf '%s: Review the WARN lines above.\n' "$(status_label WARN)"
    fi
}

main() {
    local interface_name
    local target

    init_output
    parse_args "$@"
    require_commands
    collect_default_routes
    discover_interfaces

    verbose_printf 'Network diagnostics started (read-only).\n'
    print_default_routes

    for interface_name in "${INTERFACES[@]}"; do
        print_section "Interface ${interface_name}"
        print_interface_details "${interface_name}"
    done

    print_section "DNS resolution"
    for target in "${TEST_SITES[@]}"; do
        probe_dns "${target}" || true
    done

    for interface_name in "${INTERFACES[@]}"; do
        print_section "HTTPS via ${interface_name}"
        for target in "${TEST_SITES[@]}"; do
            probe_https "${interface_name}" "${target}" || true
        done
    done

    check_shared_networks
    inspect_sing_box
    print_summary

    verbose_printf '\nNetwork diagnostics completed.\n'
}

if [[ "${NETWORK_DIAG_SOURCE_ONLY:-0}" != 1 ]]; then
    main "$@"
fi
