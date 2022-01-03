#!/bin/bash
target_app=$1
argu_list=($@)
argu_length=${#argu_list[*]}
if test 0 -lt $argu_length; then
    unset argu_list[0]
fi
argu_length=${#argu_list[*]}

echo argu_list=${argu_list[@]}, argu_length=$argu_length
for i in $(seq 0 ${#argu_list[@]}); do
    ((mod=$i %2))
    if [ $mod == "0" ]; then
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
    echo 'not in path'
fi