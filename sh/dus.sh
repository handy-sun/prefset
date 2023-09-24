#!/bin/bash
if [ "$1" == "" ]; then 
    du -alh -d1 | sort -rh | head -n 11
else
    if [ -x $1 ] ; then
        du $1 -alh -d1 | sort -rh | head -n 11
    fi
fi