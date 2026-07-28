#!/usr/bin/env bash
set -euo pipefail

_pkginsy() {
    sudo apt install -y "$@"
}

if [ `id -u` -ne 0 ]; then
    echo "current user must be root!"
    return 1
fi


cp /etc/apt/sources.list /etc/apt/sources.list.bak.$(date +%Y%m%d%H%M%S)

# 判断架构,arm64 用 ports.ubuntu.com,amd64/x86_64 用主仓库
ARCH=$(dpkg --print-architecture)
if [[ "$ARCH" == "amd64" ]]; then
  BASE="https://mirrors.tuna.tsinghua.edu.cn/ubuntu"
else
  BASE="https://mirrors.tuna.tsinghua.edu.cn/ubuntu-ports"
fi

tee /etc/apt/sources.list > /dev/null <<EOF
deb ${BASE} jammy main restricted universe multiverse
deb ${BASE} jammy-updates main restricted universe multiverse
deb ${BASE} jammy-backports main restricted universe multiverse
deb ${BASE} jammy-security main restricted universe multiverse
EOF

apt update && apt upgrade || exit 1
apt autoremove

# busybox
_pkginsy curl lsof strace iproute2

_pkginsy git git-man vim xclip tmux coreutils net-tools p7zip-full pigz unzip unrar bind9-dnsutils

_pkginsy zsh rsync trash-cli jq htop btop multitail gnupg tree

_pkginsy duf fzf make

_pkginsy build-essential

# _pkginsy docker-cli docker.io docker-compose
_pkginsy fd-find ripgrep zoxide bat
# sd git-delta hyperfine

## ubuntu22 内软链接到 ../lib/cargo/bin/fd
# if [ ! -e /usr/local/bin/fd ]; then
#     ln -sfv /usr/bin/fdfind /usr/local/bin/fd
# fi

if [ ! -e /usr/local/bin/bat ]; then
    ln -sfv /usr/bin/batcat /usr/local/bin/bat
fi

## create default `python` symbol link
if [ ! -e /bin/python ]; then
    if [ -e /bin/python3 ]; then
        ln -sfv python3 /bin/python
    elif [ -e /bin/python2 ]; then
        ln -sfv python2 /bin/python
    else
        echo "not install python"
    fi
fi
