#!/bin/bash
sudo apt update
sudo apt upgrade 

sudo apt install -y cmake build-essential clang clang-format lldb ninja-build net-tools git-man python-is-python3 tree p7zip-full pigz rar screenfetch trash-cli unzip rar unrar xclip ccache patchelf
# install java11
sudo apt install openjdk-11-jdk-headless openjdk-11-jre-headless

sudo apt install daemonize
sudo daemonize /usr/bin/unshare --fork --pid --mount-proc /lib/systemd/systemd --system-unit=basic.target
exec sudo nsenter -t $(pidof systemd) -a su - $LOGNAME

git config --global user.name sooncheer
git config --global user.email handy-sun@foxmail.com
git config --global core.editor "vim"
git config --global core.autocrlf "input"
git config --global core.safecrlf "true"


sqlite3_path=`strings /etc/ld.so.cache | grep /libsqlite3.so.*` # /lib/x86_64-linux-gnu/libsqlite3.so.0
sqlite3_dir=`dirname sqlite3_path`

sudo ln -sf libsqlite3.so.0 ${sqlite3_dir}/libsqlite3.so

