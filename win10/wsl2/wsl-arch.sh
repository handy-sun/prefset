#!/usr/bin/env bash
#
# Arch Linux WSL2 一键初始化脚本
# 基于优化后的顺序，在 WSL 实例内以 root 运行
#
# 用法:
#   1. 首次进入 Arch WSL（默认 root）
#   2. 将本脚本复制到实例内
#   3. chmod +x wsl-arch.sh && ./wsl-arch.sh
#   4. 脚本结束后，按提示在 Windows 端执行 wsl --terminate arch
#   5. 重新进入即完成
#
set -euo pipefail

# ============================================================
# 用户可自定义的变量（如需非交互设置密码，预置 PASS_ROOT / PASS_USER）
# ============================================================
USERNAME="${WSL_ARCH_USER:-qi}"
HOSTNAME="${WSL_ARCH_HOSTNAME:-archnix}"
MIRROR="${WSL_ARCH_MIRROR:-https://mirrors.tuna.tsinghua.edu.cn/archlinux/\$repo/os/\$arch}"

# ============================================================
# Step 1 — 配置 wsl.conf（不设 default，后续以 root 完成全部初始化）
# ============================================================
echo ">>> [1/8] 写入 /etc/wsl.conf ..."
cat > /etc/wsl.conf << EOF
[boot]
systemd=true

[interop]
enabled=false
appendWindowsPath=false

[network]
generateHosts=true
generateResolvConf=true
hostname=${HOSTNAME}
EOF

# ============================================================
# Step 2 — 创建用户和组
# ============================================================
echo ">>> [2/8] 创建用户 ${USERNAME} ..."
groupadd "${USERNAME}"
useradd -g "${USERNAME}" -m "${USERNAME}" -d "/home/${USERNAME}" -s /bin/bash

# ============================================================
# Step 3 — 配置 sudoers（通过 /etc/sudoers.d/ drop-in，不动主文件）
# ============================================================
echo ">>> [3/8] 配置 sudoers ..."

# sudoers.d 已被主文件 @includedir 引用，文件权限必须为 0440
# WSL 个人开发环境用 NOPASSWD 避免频繁输密码
cat > /etc/sudoers.d/wheel << EOF
%wheel ALL=(ALL:ALL) NOPASSWD: ALL
EOF
chmod 0440 /etc/sudoers.d/wheel

# 加入 wheel 组
usermod -aG wheel "${USERNAME}"

# ============================================================
# Step 4 — 设置密码
# ============================================================
echo ">>> [4/8] 设置密码 ..."

if [ -n "${PASS_ROOT:-}" ]; then
    echo "root:${PASS_ROOT}" | chpasswd
    echo "  root 密码已通过环境变量设置"
else
    echo "  === 设置 root 密码 ==="
    passwd
fi

if [ -n "${PASS_USER:-}" ]; then
    echo "${USERNAME}:${PASS_USER}" | chpasswd
    echo "  ${USERNAME} 密码已通过环境变量设置"
else
    echo "  === 设置 ${USERNAME} 密码 ==="
    passwd "${USERNAME}"
fi

# ============================================================
# Step 5 — 配置镜像源
# ============================================================
echo ">>> [5/8] 配置镜像源 ..."
cp /etc/pacman.d/mirrorlist{,.bak}
echo "Server = ${MIRROR}" > /etc/pacman.d/mirrorlist

# ============================================================
# Step 6 — 配置 locale（提前配置，避免包安装时 perl locale 警告）
# ============================================================
echo ">>> [6/8] 配置 locale ..."
sed -i 's/^#en_US.UTF-8/en_US.UTF-8/' /etc/locale.gen
locale-gen
echo 'LANG=en_US.UTF-8' > /etc/locale.conf

# ============================================================
# Step 7 — 更新 keyring → 全系统升级 + 安装基础包
# ============================================================
echo ">>> [7/8] 更新 keyring ..."
pacman -Sy --noconfirm archlinux-keyring

echo ">>> [7/8] 全系统升级 & 安装基础包 ..."
pacman -Syu --noconfirm vim git sudo wget which nano openssh libssh2

# ============================================================
# Step 8 — 设置默认用户
# ============================================================
echo ">>> [8/8] 设置默认用户为 ${USERNAME} ..."
cat >> /etc/wsl.conf << EOF

[user]
default=${USERNAME}
EOF

# ============================================================
echo ""
echo "=============================================="
echo "  初始化完成！"
echo ""
echo "  在 Windows 终端执行以下命令重启 WSL："
echo "    wsl --terminate arch"
echo ""
echo "  重新进入后将以 ${USERNAME} 用户登录。"
echo "=============================================="
