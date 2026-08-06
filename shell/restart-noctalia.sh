#!/usr/bin/env bash
## restart-noctalia.sh — Restart noctalia-shell.
## Stop it, poll once per second until the process is gone, then start it again.
set -euo pipefail

## The real process is "quickshell -p <store path>/noctalia-shell".
## The pattern must not match this script itself.
pattern='quickshell -p .*noctalia-shell'

if pgrep -f "${pattern}" >/dev/null; then
  echo ">>> stopping noctalia-shell..."
  pkill -f "${pattern}"
  while pgrep -f "${pattern}" >/dev/null; do
    sleep 1
  done
fi

echo ">>> starting noctalia-shell..."
setsid noctalia-shell >/dev/null 2>&1 &
echo ">>> noctalia-shell restarted"
