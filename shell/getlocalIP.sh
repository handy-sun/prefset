#/bin/bash
ifconfig | grep "inet " | awk '{ print $2 }' | sed 's/addr://g'

# (install mmnetwork) nmcli