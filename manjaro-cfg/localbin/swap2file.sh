#!/bin/bash
# filename: swap2file.sh
# Usage: swap2file.sh file1 file2
# 交换两个文件的内容。
# 如果文件不存在返回1，如果两个文件相同返回2。

if [[ ! -f "$1" || ! -f "$2" ]]; then
  echo "$1 or $2 is not existed." >&2
  exit 1
fi

if [[ "$1" -ef "$2" ]]; then
  echo "$1 and $2 is same file" >&2
  exit 2
fi

tempfile=$(mktemp ./swap2file.$$.XXXXXXXXXX)
mv "$1" $tempfile
mv "$2" "$1"
mv $tempfile "$2"
