#!/bin/bash
LANG=C pacman -Qi | sed -n '/^Name[^:]*: \(.*\)/{s//\1 /;x};/^Installed[^:]*: \(.*\)/{s//\1/;H;x;s/\n//;p}' | column -t | sort -rnk2 > ~/pacsize.list
# 使用 yay -Ps 查看最大的10个包