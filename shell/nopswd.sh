#!/bin/bash

uname=`whoami`
uid=`id -u`
filepath=/etc/sudoers.d/${uid}-pass
if [ -e ${filepath} ]; then
    echo "${filepath} exist, do nothing."
    exit 1
fi

if [[ "$1" = "-d" ]]; then # dry-run
    echo "tee ${filepath} <<< \"${uname} ALL=(ALL) NOPASSWD:ALL\""
    echo chmod 440 ${filepath}
else
    tee ${filepath} <<< "${uname} ALL=(ALL) NOPASSWD:ALL"
    chmod 440 ${filepath}
fi
