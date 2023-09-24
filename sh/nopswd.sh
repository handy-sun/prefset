#!/bin/bash
# description: root add a user who sudo without passwd!
if [[ "$1" = "" || "$1" = root ]]; then 
    echo "Input a valid and real user(but not root)!"
    exit 1
fi

is_real_user=`cat /etc/shadow | grep $1 | cut -d: -f2 | grep -v '!\*' | wc -l`
if [ ${is_real_user} -ne 1 ]; then 
    echo "Not a real user!"
    exit 1
fi

uname=$1
filepath=/etc/sudoers.d/${uname}-pass
if [ -e ${filepath} ]; then
    echo "${filepath} exist, do nothing."
    exit 1
fi

tee ${filepath} <<< "${uname} ALL=(ALL) NOPASSWD:ALL"
chmod 440 ${filepath}
