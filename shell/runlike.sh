#!/usr/bin/env bash
## runlike.sh — Reconstruct the docker run command from a running container
## Usage: ./runlike.sh [OPTIONS] CONTAINER...
set -euo pipefail

ENGINE=""
ALL=false
TARGETS=()

print_help() {
    cat <<'EOF'
Reconstruct the "docker run" command line of existing containers

Usage:
  runlike.sh [OPTIONS] CONTAINER...
  runlike.sh [OPTIONS] --all

Options:
  --engine BIN   Container CLI to use. Default: docker, or podman if docker is missing.
  -a, --all      Process every container, running and stopped.
  -h, --help     Show this help.

Only container settings that differ from the image defaults are emitted, so the
output stays close to what was originally typed on the command line. Options the
engine cannot report back (such as --rm or build-time only flags) are lost.

Required programs: docker (or podman), jq
EOF
}

## The container inspect output alone cannot tell which settings were explicit:
## env, labels, volumes, entrypoint and cmd are merged with the image defaults.
## So both objects are passed in and every value equal to the image default is dropped.
JQ_PROGRAM=$(cat <<'EOF'
def shq:
  tostring
  | if test("^[A-Za-z0-9_@%+=:,./-]+$") and length > 0
    then .
    else "'" + gsub("'"; "'\\''") + "'"
    end;

$container as $c
| $image as $i
| ($i.Config.Env    // []) as $ienv
| ($i.Config.Labels // {}) as $ilbl
| ($i.Config.Volumes // {}) as $ivol

| [ "docker run -d" ]

## Name
+ [ "--name " + ($c.Name | ltrimstr("/") | shq) ]

## Restart policy
+ ( $c.HostConfig.RestartPolicy as $r
    | if (($r.Name // "") == "") or (($r.Name // "") == "no") then []
      elif $r.Name == "on-failure" and (($r.MaximumRetryCount // 0) > 0)
        then ["--restart=on-failure:" + ($r.MaximumRetryCount|tostring)]
      else ["--restart=" + $r.Name] end )

## Network / hostname / user / working directory
+ ( if ($c.HostConfig.NetworkMode // "default") == "default" then []
    else ["--network=" + ($c.HostConfig.NetworkMode | shq)] end )
+ ( if (($c.Config.Hostname // "") == "")
       or ($c.HostConfig.NetworkMode == "host")
       or (($c.Id // "") | startswith($c.Config.Hostname // "@@"))
    then [] else ["--hostname " + ($c.Config.Hostname | shq)] end )
+ ( if ($c.Config.User // "") == "" then [] else ["--user " + ($c.Config.User|shq)] end )
+ ( if (($c.Config.WorkingDir // "") == "") or ($c.Config.WorkingDir == ($i.Config.WorkingDir // ""))
    then [] else ["--workdir " + ($c.Config.WorkingDir|shq)] end )

## Privileges and capabilities
+ ( if $c.HostConfig.Privileged then ["--privileged"] else [] end )
+ ( ($c.HostConfig.CapAdd  // []) | map("--cap-add "  + shq) )
+ ( ($c.HostConfig.CapDrop // []) | map("--cap-drop " + shq) )
+ ( ($c.HostConfig.SecurityOpt // []) | map("--security-opt " + shq) )
+ ( ($c.HostConfig.Devices // []) | map("--device " +
      ((.PathOnHost + ":" + .PathInContainer +
        (if (.CgroupPermissions // "rwm") != "rwm" then ":" + .CgroupPermissions else "" end)) | shq)) )

## Mounts
+ ( ($c.HostConfig.Binds // []) | map("-v " + shq) )
+ ( ($c.Config.Volumes // {}) | keys_unsorted
    | map(select(. as $k | ($ivol | has($k)) | not)) | map("-v " + shq) )
+ ( ($c.HostConfig.VolumesFrom // []) | map("--volumes-from " + shq) )
+ ( ($c.HostConfig.Tmpfs // {}) | to_entries
    | map("--tmpfs " + ((.key + (if .value == "" then "" else ":" + .value end)) | shq)) )

## Ports
+ ( if $c.HostConfig.PublishAllPorts then ["-P"] else [] end )
+ ( ($c.HostConfig.PortBindings // {}) | to_entries
    | map( .key as $cport | (.value // [])
         | map("-p " + (((if (.HostIp // "") == "" then "" else .HostIp + ":" end)
                        + (.HostPort // "") + ":" + $cport) | shq)) )
    | flatten )

## Environment variables, minus the ones inherited from the image
+ ( ($c.Config.Env // []) | map(select(. as $e | ($ienv | index($e)) | not))
    | map("-e " + shq) )

## Labels, minus the ones inherited from the image
+ ( ($c.Config.Labels // {}) | to_entries
    | map(select(. as $l | (($ilbl[$l.key]) // null) != $l.value))
    | map("--label " + ((.key + "=" + .value) | shq)) )

## Other common settings
+ ( ($c.HostConfig.Sysctls // {}) | to_entries | map("--sysctl " + ((.key+"="+.value)|shq)) )
+ ( ($c.HostConfig.Dns // []) | map("--dns " + shq) )
+ ( ($c.HostConfig.ExtraHosts // []) | map("--add-host " + shq) )
+ ( ($c.HostConfig.Links // []) | map("--link " + shq) )
+ ( if ($c.HostConfig.Memory // 0) > 0 then ["--memory " + ($c.HostConfig.Memory|tostring)] else [] end )
+ ( if ($c.HostConfig.NanoCpus // 0) > 0
    then ["--cpus " + ((($c.HostConfig.NanoCpus/1000000000)*1000|round)/1000|tostring)] else [] end )
+ ( ($c.HostConfig.LogConfig.Type // "") as $lt
    | if ($lt == "") or ($lt == "json-file") then [] else ["--log-driver " + ($lt|shq)] end )
+ ( if ($c.HostConfig.Runtime // "runc") == "runc" then [] else ["--runtime " + ($c.HostConfig.Runtime|shq)] end )
+ ( if ($c.Config.Tty // false) then ["-t"] else [] end )
+ ( if ($c.Config.OpenStdin // false) then ["-i"] else [] end )

## Entrypoint: only explicit when it differs from the image
+ ( if ($c.Config.Entrypoint // null) != ($i.Config.Entrypoint // null)
    then ["--entrypoint " + (($c.Config.Entrypoint // []) | join(" ") | shq)] else [] end )

## Image
+ [ ($c.Config.Image | shq) ]

## Cmd: only explicit when it differs from the image
+ ( if ($c.Config.Cmd // null) != ($i.Config.Cmd // null)
    then (($c.Config.Cmd // []) | map(shq)) else [] end )

| join(" \\\n  ")
EOF
)

parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --engine)
                [[ $# -gt 1 ]] || { echo "Error: --engine needs a value"; exit 1; }
                ENGINE="$2"
                shift 2
                ;;
            --engine=*)
                ENGINE="${1#*=}"
                shift
                ;;
            -a|--all)
                ALL=true
                shift
                ;;
            -h|--help)
                print_help
                exit 0
                ;;
            --)
                shift
                TARGETS+=("$@")
                break
                ;;
            -*)
                echo "Error: unknown option $1"
                echo "Run runlike.sh --help for usage."
                exit 1
                ;;
            *)
                TARGETS+=("$1")
                shift
                ;;
        esac
    done
}

resolve_engine() {
    if [[ -n "${ENGINE}" ]]; then
        command -v "${ENGINE}" >/dev/null 2>&1 || { echo "Error: ${ENGINE} not found in PATH"; exit 1; }
        return
    fi
    if command -v docker >/dev/null 2>&1; then
        ENGINE=docker
    elif command -v podman >/dev/null 2>&1; then
        ENGINE=podman
    else
        echo "Error: neither docker nor podman found in PATH"
        exit 1
    fi
}

list_all_containers() {
    "${ENGINE}" ps -a --format '{{.Names}}'
}

## Emits the run command for one container, or returns non-zero with a message
render_container() {
    local target="$1"
    local container_json image_ref image_json

    if ! container_json=$("${ENGINE}" inspect --type container --format '{{json .}}' "${target}" 2>/dev/null); then
        echo "Error: no such container: ${target}" >&2
        return 1
    fi

    ## Prefer the image ID over Config.Image: the tag may have been reused since
    image_ref=$(jq -r '.Image // .Config.Image // ""' <<<"${container_json}")
    image_json='{}'
    if [[ -n "${image_ref}" ]]; then
        if ! image_json=$("${ENGINE}" inspect --type image --format '{{json .}}' "${image_ref}" 2>/dev/null); then
            echo "Warning: image ${image_ref} is gone, image defaults cannot be subtracted" >&2
            image_json='{}'
        fi
    fi

    jq -nr \
        --argjson container "${container_json}" \
        --argjson image "${image_json}" \
        "${JQ_PROGRAM}"
}

main() {
    parse_args "$@"
    command -v jq >/dev/null 2>&1 || { echo "Error: jq not found in PATH"; exit 1; }
    resolve_engine

    if [[ "${ALL}" == true ]]; then
        local name
        while IFS= read -r name; do
            [[ -n "${name}" ]] && TARGETS+=("${name}")
        done < <(list_all_containers)
    fi

    if [[ ${#TARGETS[@]} -eq 0 ]]; then
        echo "Error: no container given"
        echo "Run runlike.sh --help for usage."
        exit 1
    fi

    local status=0 first=true target
    for target in "${TARGETS[@]}"; do
        if [[ ${#TARGETS[@]} -gt 1 ]]; then
            [[ "${first}" == true ]] || echo ""
            echo "# ${target}"
        fi
        first=false
        render_container "${target}" || status=1
    done
    return "${status}"
}

main "$@"
