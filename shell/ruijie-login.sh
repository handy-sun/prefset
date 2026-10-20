#!/bin/sh
# Ruijie AC Web Portal (ac_portal) auto-login for OpenWrt / small systems.
#
# Protocol (reverse-engineered from 1.1.1.3xuw-ias.har portal JS logic_new.js):
#   POST http://<portal>/ac_portal/login.php   (form-urlencoded, no cookies)
#     opr=pwdLogin&userName=<user>&pwd=<rc4hex(pass, auth_tag)>&auth_tag=<tag>&rememberPwd=on
#   pwd = RC4(password, key=auth_tag) hex-encoded; auth_tag = client-chosen
#   ms-timestamp string. RC4 verified byte-exact against captured /terminal_info.
#   Optional fingerprint: POST /terminal_info tag=<ts> userAgent/platform RC4(ts).
#   Logout: POST login.php with opr=logout. Heartbeat /out.htm not required.
#
# Config via env or /etc/config-style plain vars below.

PORTAL="${PORTAL:-http://1.1.1.3}"
USERNAME="${USERNAME:?set USERNAME e.g. 22330000@dy}"
PASSWORD="${PASSWORD:?set PASSWORD}"
# probe URL: portal hijacks any HTTP pre-auth, so check exact body, not status
PROBE_URL="${PROBE_URL:-http://www.msftconnecttest.com/connecttest.txt}"
PROBE_BODY="${PROBE_BODY:-Microsoft Connect Test}"
REFERER="$PORTAL/ac_portal/default/pc.html?template=default&tabs=pwd&vlanid=0&url=http%3A%2F%2Fwww.msftconnecttest.com%2Fconnecttest.txt"

rc4hex() { # $1=plaintext  $2=key -> lowercase hex on stdout
    LC_ALL=C awk -v src="$1" -v key="$2" 'BEGIN{
        # byte->value map for all 1..255 (NUL cannot occur in shell strings)
        for (n = 1; n < 256; n++) ordtab[sprintf("%c", n)] = n
        # JS portal code does src.trim() before encrypting
        sub(/^[ \t\r\n]+/, "", src); sub(/[ \t\r\n]+$/, "", src)
        plen = length(key)
        for (i = 0; i < 256; i++) {
            c = substr(key, (i % plen) + 1, 1)
            k[i] = (c in ordtab) ? ordtab[c] : 0
            S[i] = i
        }
        j = 0
        for (i = 0; i < 256; i++) {
            j = (j + S[i] + k[i]) % 256
            t = S[i]; S[i] = S[j]; S[j] = t
        }
        a = b = 0
        n = length(src)
        for (i = 1; i <= n; i++) {
            a = (a + 1) % 256
            b = (b + S[a]) % 256
            t = S[a]; S[a] = S[b]; S[b] = t
            c = (S[a] + S[b]) % 256
            c1 = substr(src, i, 1)
            x = (c1 in ordtab) ? ordtab[c1] : 0
            y = S[c]
            # portable 8-bit XOR on copies (busybox awk-safe)
            r = 0; bit = 1
            for (q = 0; q < 8; q++) {
                if ((x % 2) != (y % 2)) r += bit
                x = int(x / 2); y = int(y / 2); bit *= 2
            }
            printf "%02x", r
        }
    }'
}

online() {
    curl -s -m 8 "$PROBE_URL" 2>/dev/null | grep -qF "$PROBE_BODY"
}

login() {
    tag="$(date +%s)$((100 + $$ % 900))"          # ~ms timestamp, client-chosen key
    pwd="$(rc4hex "$PASSWORD" "$tag")"
    ua="$(rc4hex "$USERAGENT" "$tag")"
    pf="$(rc4hex "Linux x86_64" "$tag")"
    # mimic browser: optional terminal fingerprint (audit; harmless if skipped)
    curl -s -m 8 -X POST "$PORTAL/terminal_info" \
         --data-urlencode "tag=$tag" --data-urlencode "userAgent=$ua" \
         --data-urlencode "platform=$pf" >/dev/null 2>&1
    resp=$(curl -s -m 10 -X POST "$PORTAL/ac_portal/login.php" \
         -H "Referer: $REFERER" -A "$USERAGENT" \
         --data-urlencode "opr=pwdLogin" \
         --data-urlencode "userName=$USERNAME" \
         --data-urlencode "pwd=$pwd" \
         --data-urlencode "auth_tag=$tag" \
         --data-urlencode "rememberPwd=on")
    case "$resp" in
        *'"success":true'*|*'"success": true'*)
            sleep 2
            online && { echo "[$(date '+%F %T')] login ok: $USERNAME"; exit 0; }
            echo "[$(date '+%F %T')] login accepted but probe failed: $resp"; exit 1 ;;
        *) echo "[$(date '+%F %T')] login failed: $resp"; exit 1 ;;
    esac
}

USERAGENT="Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/125.0.0.0 Safari/537.36"

if online; then
    echo "[$(date '+%F %T')] already online"
    exit 0
fi
login
