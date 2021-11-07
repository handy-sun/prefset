#!/bin/bash
if [ "$1" == "" ]; then 
    du -alh --max-depth=1 | sort -rh | head -n 11
else
    if [ -x $1 ] ; then
        cd $1	
        du -alh --max-depth=1 | sort -rh | head -n 11
    fi
fi