#!/bin/bash
argu_list=($@)
argu_length=${#argu_list[*]}
((mod=$argu_length %2))
# echo argu_list=${argu_list[@]}, argu_length=$argu_length, mod=$mod
qmake_path=`which qmake`
if test -n "$qmake_path"; then
    if test -L "$qmake_path"; then
        nme=`readlink -nf "$qmake_path" 2>/dev/null`
        echo nme=$nme
    fi    
    echo qmake_path=$qmake_path
else
    echo err
fi