#!/usr/bin/env bash
set -e

# 自动检测，确保有 sing-box 和 openssl 工具用于生成凭据
if ! command -v sing-box &> /dev/null || ! command -v openssl &> /dev/null; then
    echo "🌟正在通过 nix shell 自动加载依赖..."
    exec nix shell nixpkgs#sing-box nixpkgs#openssl --command bash "$0" "$@"
fi

echo "================================================="
echo " 📦 sing-box 终极配置生成器 (服务端 + 客户端 JSON)"
echo "================================================="

read -p "0. 输入你的服务器公网 IP (默认: 127.0.0.1): " SERVER_IP
SERVER_IP=${SERVER_IP:-127.0.0.1}

read -p "1. 输入 Shadowsocks 端口 (默认: 20085): " SS_PORT
SS_PORT=${SS_PORT:-20085}

read -p "2. 输入 VMess 端口 (默认: 20086): " VMESS_PORT
VMESS_PORT=${VMESS_PORT:-20086}

read -p "3. 输入 Trojan 端口 (默认: 443): " TROJAN_PORT
TROJAN_PORT=${TROJAN_PORT:-443}

read -p "4. 输入 Trojan 绑定的域名 (默认: yourdomain.com): " TROJAN_DOMAIN
TROJAN_DOMAIN=${TROJAN_DOMAIN:-yourdomain.com}

# 创建带时间戳的输出目录
DIR_NAME="gen-sing-box-$(date +%m%dT%H%M%S)"
mkdir -p "$DIR_NAME"

echo ""
echo "🔮 正在生成高强度密码与强加密凭据..."
SS_PASS=$(openssl rand -base64 32)
TROJAN_PASS=$(openssl rand -base64 16)
VMESS_UUID=$(sing-box generate uuid)

# --- 计算标准协议分享链接 ---
# 1. Shadowsocks 2022
SS_USER_INFO=$(echo -n "2022-blake3-aes-256-gcm:${SS_PASS}" | openssl base64 | tr -d '\n' | tr -d '\r')
SS_LINK="ss://${SS_USER_INFO}@${SERVER_IP}:${SS_PORT}#SS_2022"

# 2. Trojan
TROJAN_LINK="trojan://${TROJAN_PASS}@${SERVER_IP}:${TROJAN_PORT}?security=tls&sni=${TROJAN_DOMAIN}#Trojan"

# 3. VMess
VMESS_JSON=$(cat <<EOF
{
  "v": "2", "ps": "VMess", "add": "${SERVER_IP}", "port": "${VMESS_PORT}", "id": "${VMESS_UUID}", "aid": "0", "scy": "auto", "net": "tcp", "type": "none", "tls": ""
}
EOF
)
VMESS_LINK="vmess://$(echo -n "$VMESS_JSON" | openssl base64 | tr -d '\n' | tr -d '\r')"


# 📄 文件 1：写入纯净版 NixOS 服务端配置文件
cat << EOF > "${DIR_NAME}/sing-box-server.nix"
{ config, pkgs, ... }:
{
  services.sing-box = {
    enable = true;
    settings = {
      log = {
        level = "info";
        timestamp = true;
        output = "/tmp/box-access.log";
      };
      inbounds = [
        {
          type = "shadowsocks";
          tag = "ss-in";
          listen = "::";
          listen_port = ${SS_PORT};
          method = "2022-blake3-aes-256-gcm";
          password = "${SS_PASS}";
        }
        {
          type = "trojan";
          tag = "trojan-in";
          listen = "::";
          listen_port = ${TROJAN_PORT};
          users = [ { password = "${TROJAN_PASS}"; } ];
          tls = {
            enabled = true;
            server_name = "${TROJAN_DOMAIN}";
            certificate_path = "/var/lib/sing-box/cert.pem";
            key_path = "/var/lib/sing-box/priv.key";
          };
        }
        {
          type = "vmess";
          tag = "vmess-in";
          listen = "::";
          listen_port = ${VMESS_PORT};
          users = [
            {
              uuid = "${VMESS_UUID}";
            }
          ];
        }
      ];
      outbounds = [
        {
          type = "direct";
          tag = "direct";
        }
      ];
    };
  };
}
EOF


# 📄 文件 2：写入标准服务端 server-config.json 配置文件
cat << EOF > "${DIR_NAME}/server-config.json"
{
  "log": { "level": "info", "timestamp": true, output = "/tmp/box-access.log" },
  "inbounds": [
    { "type": "shadowsocks", "tag": "ss-in", "listen": "::", "listen_port": ${SS_PORT}, "method": "2022-blake3-aes-256-gcm", "password": "${SS_PASS}" },
    {
      "type": "trojan", "tag": "trojan-in", "listen": "::", "listen_port": ${TROJAN_PORT},
      "users": [ { "password": "${TROJAN_PASS}" } ],
      "tls": { "enabled": true, "server_name": "${TROJAN_DOMAIN}", "certificate_path": "/var/lib/sing-box/cert.pem", "key_path": "/var/lib/sing-box/priv.key" }
    },
    { "type": "vmess", "tag": "vmess-in", "listen": "::", "listen_port": ${VMESS_PORT}, "users": [ { "uuid": "${VMESS_UUID}" } ] }
  ],
  "outbounds": [ { "type": "direct", "tag": "direct" } ]
}
EOF


# 📄 文件 3：写入完整的客户端 client-config.json
cat << EOF > "${DIR_NAME}/client-config.json"
{
  "log": {
    "level": "info",
    "timestamp": true
  },
  "outbounds": [
    {
      "type": "selector",
      "tag": "proxy",
      "outbounds": [
        "Shadowsocks_2022",
        "Trojan_TLS",
        "VMess_TCP",
        "direct"
      ]
    },
    {
      "type": "shadowsocks",
      "tag": "Shadowsocks_2022",
      "server": "${SERVER_IP}",
      "server_port": ${SS_PORT},
      "method": "2022-blake3-aes-256-gcm",
      "password": "${SS_PASS}"
    },
    {
      "type": "trojan",
      "tag": "Trojan_TLS",
      "server": "${SERVER_IP}",
      "server_port": ${TROJAN_PORT},
      "password": "${TROJAN_PASS}",
      "tls": {
        "enabled": true,
        "server_name": "${TROJAN_DOMAIN}"
      }
    },
    {
      "type": "vmess",
      "tag": "VMess_TCP",
      "server": "${SERVER_IP}",
      "server_port": ${VMESS_PORT},
      "uuid": "${VMESS_UUID}",
      "security": "auto"
    },
    {
      "type": "direct",
      "tag": "direct"
    }
  ]
}
EOF

echo ""
echo "=================================================="
echo "📂 所有纯净配置文件已输出至目录 👉 ./${DIR_NAME}/"
echo "=================================================="
echo "📄 1. 服务端 NixOS 模块 👉 ./${DIR_NAME}/sing-box-server.nix"
echo "📄 2. 服务端通用 JSON   👉 ./${DIR_NAME}/server-config.json"
echo "📄 3. 客户端通用 JSON   👉 ./${DIR_NAME}/client-config.json"
echo ""
echo "🔗 客户端标准分享链接 (务必复制保存好):"
echo "--------------------------------------------------"
echo -e "[SS 2022]:\n${SS_LINK}\n"
echo -e "[Trojan]:\n${TROJAN_LINK}\n"
echo -e "[VMess]:\n${VMESS_LINK}"

