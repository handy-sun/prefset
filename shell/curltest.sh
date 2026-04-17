#!/usr/bin/env bash
set -e

sh_c(){
  # echo "$@"
  sh -c '$@'
}
access_https(){
  timeout 3s curl --proto '=https' --tlsv1.2 -I -sfSL https://"$1" && echo -e "\033[32mtrue\033[0m" || echo -e "\033[31mfalse\033[0m"
  echo
}

echo ============= www.baidu.com
$sh_c access_https www.baidu.com
echo ============= archlinux.org
$sh_c access_https archlinux.org
echo ============= www.yandex.com
$sh_c access_https www.yandex.com
echo ============= www.youtube.com
$sh_c access_https www.youtube.com
echo ============= www.github.com
$sh_c access_https www.github.com
echo ============= www.v2ex.com
$sh_c access_https www.v2ex.com
echo ============= www.google.com
$sh_c access_https www.google.com

