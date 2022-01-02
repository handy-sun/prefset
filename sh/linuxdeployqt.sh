#!/bin/bash
target_app=$1
argu_list=($@)
argu_length=${#argu_list[*]}
((mod=$argu_length %2))
# echo argu_list=${argu_list[@]}, argu_length=$argu_length, mod=$mod
for i in $(seq 0 ${#argu_list[@]}); do
    if [ $i == "1" ]; then
        echo ${argu_list[$i]}
    fi
done
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