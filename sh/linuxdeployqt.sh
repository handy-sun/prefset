#!/bin/bash
target_app=$1
argu_list=($@)
argu_length=${#argu_list[*]}
if [ $argu_length -eq 0 ]; then
    target_app="-h"
elif [ $argu_length -gt 0 ]; then
    unset argu_list[0]
fi

if [ $target_app == "-h" ]; then
    echo "show usage help"
    exit
fi

argu_length=${#argu_list[*]}

echo argu_list=${argu_list[@]}, argu_length=$argu_length
for i in $(seq 0 ${#argu_list[@]}); do
    ((mod=$i %2))
    if [ $mod == "0" ]; then
        echo 
        # ${argu_list[$i]}
    fi
done

dependency_list=$(ldd $target_app | awk '{if (match($3, "/") && match($1, "libQt5|libicu")){printf("%s "), $3}}')
target_path=`dirname $target_app`
cd $target_path
des="lib"
if [ ! -x "$des" ]; then
    # mkdir "$des"
    echo mkdir "$target_path/$des"
fi

for i in $dependency_list; do
    result=`echo $i | grep "Core"`
    if [ "$result" != "" ]; then
        qtlib_path=`dirname $i`
        dependency_list=("${dependency_list[@]}" "$qtlib_path/libQt5XcbQpa.so.5" "$qtlib_path/libQt5DBus.so.5")
        break
    fi
done

qmake_path=`which qmake`
if [ -n "$qmake_path" ]; then
    if [ -L "$qmake_path" ]; then
        nme=`readlink -nf "$qmake_path" 2>/dev/null`
        echo nme=$nme
    fi    
    echo qmake_path=$qmake_path
else
    echo 'not in path'
fi
