#/bin/bash
# get ipv4
ip a | grep 'inet ' | grep -v ' lo' | awk '{print$2}' | cut -d/ -f1

# (install mmnetwork) nmcli
