#!/bin/bash
sudo apt update
sudo apt upgrade 

sudo apt install -y cmake build-essential clang clang-format lldb ninja-build net-tools git-man python-is-python3 tree p7zip-full pigz rar screenfetch trash-cli unzip rar unrar xclip ccache patchelf

sudo apt install -y openjdk-8-jdk openjdk-8-jre

sudo apt install daemonize
sudo daemonize /usr/bin/unshare --fork --pid --mount-proc /lib/systemd/systemd --system-unit=basic.target
exec sudo nsenter -t $(pidof systemd) -a su - $LOGNAME


sqlite3_path=`strings /etc/ld.so.cache | grep /libsqlite3.so.*` # /lib/x86_64-linux-gnu/libsqlite3.so.0
sqlite3_dir=`dirname sqlite3_path`

sudo ln -sf libsqlite3.so.0 ${sqlite3_dir}/libsqlite3.so

