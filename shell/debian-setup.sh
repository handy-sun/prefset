#!/usr/bin/env bash
set -euo pipefail

_pkginsy() {
    sudo apt install -y "$@"
}

if [ `id -u` -ne 0 ]; then
    echo "current user must be root!"
    return 1
fi

reposrc=/etc/apt/sources.list
if ! grep -iq testing-updates $reposrc ; then
    cp -v $reposrc "${reposrc}_$(date +%Y%m%d-%H%M).bak"
    cat > $reposrc << EOF
deb http://deb.debian.org/debian/ testing main contrib non-free
deb-src http://deb.debian.org/debian/ testing main contrib non-free

deb http://deb.debian.org/debian testing-updates main contrib non-free non-free-firmware
deb-src http://deb.debian.org/debian testing-updates main contrib non-free non-free-firmware
EOF
fi

apt update && apt upgrade
apt autoremove

_pkginsy busybox curl lsof fastfetch strace iproute2

_pkginsy git git-man vim xclip tmux coreutils net-tools p7zip-full pigz unzip unrar iptables-persistent bind9-dnsutils

_pkginsy zsh rsync nginx-full trash-cli jq htop btop multitail gnupg tree aria2 acme.sh

_pkginsy duf fzf xxd du-dust

_pkginsy make build-essential

# ## debian12 Testing (trixie)
_pkginsy docker-cli docker.io docker-compose
_pkginsy fd-find ripgrep zoxide eza bat procs sd git-delta hyperfine


if [ ! -e /usr/bin/fd ]; then
    ln -sfv fdfind /usr/bin/fd
fi

if [ ! -e /usr/bin/bat ]; then
    ln -sfv batcat /usr/bin/bat
fi

## create default `python` symbol link
if [ ! -e /bin/python ]; then
    if [ ! -e /bin/python3 ]; then
        ln -sfv python3 /bin/python
    elif [ ! -e /bin/python2 ]; then
        ln -sfv python2 /bin/python
    else
        echo "not install python"
    fi
fi

## create libsqlite3.so symbollink
# sqlite3_path=`strings /etc/ld.so.cache | grep /libsqlite3.so.*`
# echo $sqlite3_path | grep -E '/libsqlite3.so$'
# if [ $? -ne 0 ]; then
#     local sqlite3_dir=`dirname sqlite3_path`
#     ln -sfv libsqlite3.so.0 ${sqlite3_dir}/libsqlite3.so
#     ldconfig
# fi
# unset sqlite3_path

## c,cpp tools
# _pkginsy clang clang-format lldb cmake ninja-build
## jdk8 jre8
# _pkginsy openjdk-8-jdk openjdk-8-jre
