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

# echo argu_list=${argu_list[@]}, argu_length=$argu_length
for i in $(seq 0 ${#argu_list[@]}); do
    ((mod=$i %2))
    if [ $mod == "0" ]; then
        :
        # echo ${argu_list[$i]}
    fi
done

dependency_list=(`ldd $target_app | awk '{if (match($3, "/") && match($1, "libQt5|libicu")){printf("%s "), $3}}'`)
notfound_list=(`ldd $target_app | awk '{if (match($3, "not")){printf("%s "), $1}}'`)
# echo "notfound_list:$notfound_list"
target_path=`dirname $target_app`
cd $target_path
des="lib"
if [ ! -d "$des" ]; then
    # mkdir "$des"
    # echo mkdir "$target_path/$des"
    :
fi

for v in ${dependency_list[*]}; do
    if [[ "$v" =~ "libQt" ]]; then
        qtlib_path=`dirname $v`
        # dependency_list=("${dependency_list[@]}" "$qtlib_path/libQt5XcbQpa.so.5" "$qtlib_path/libQt5DBus.so.5")
        dependency_list+=("$qtlib_path/libQt5XcbQpa.so.5" "$qtlib_path/libQt5DBus.so.5")
        break
    fi
done

# echo "dependency_list:(${dependency_list[@]})"

real_dependency_list=()
plu_str="{"

for v in ${dependency_list[*]}; do
    if [ -L "$v" ]; then
        reallink=`readlink -nf "$v" 2>/dev/null`        
        real_dependency_list+=("$reallink")
    fi
    if [[ "$v" =~ "libQt5Gui" ]]; then                
        plu_str="${plu_str}platforms/libqxcb.so,platforminputcontexts/,platformthemes/,styles/,iconengines/,imageformats/,"
    elif [[ "$v" =~ "libQt5Network" ]]; then 
        plu_str="${plu_str}bearer/,"
    elif [[ "$v" =~ "libQt5PrintSupport" ]]; then 
        plu_str="${plu_str}printsupport/libcupsprintersupport.so,"
    elif [[ "$v" =~ "libQt5OpenGL" || "$v" =~ "libQt5XcbQpa" ]]; then
        plu_str="${plu_str}xcbglintegrations/,"
    fi
done

plu_str=${plu_str%,*}
plu_str="${plu_str}}"

echo "real_len:${#real_dependency_list[*]}"
# echo "real_list:${real_dependency_list[@]}"


plugin_lib="plugins"
if [ ! -d "$plugin_lib" ]; then
    mkdir "$plugin_lib"
fi
cd "/usr/lib/qt/plugins"
sudo cp -drP "${plu_str}" "${target_path}/${plugin_lib}"

echo "plu_str="${plu_str}
echo dest="$target_path/$plugin_lib"

qmake_path=`which qmake`
if [ -n "$qmake_path" ]; then
    if [ -L "$qmake_path" ]; then
        qmake_path=`readlink -nf "$qmake_path" 2>/dev/null`
    fi    
else
    echo 'not in path'
fi
