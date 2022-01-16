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

argu_list=(${argu_list[@]})
argu_length=${#argu_list[*]}

for i in `seq 0 $(($argu_length-1))`; do
# for i in $(seq 0 ${#argu_list[@]}); do
    echo i=$i ${argu_list[$i]}
    ((mod=$i %2))
    if [ $mod == "0" ]; then
        :        
    fi
done

# echo argu_list=${argu_list[@]}, argu_length=$argu_length; exit

dependency_list=(`ldd $target_app | awk '{if (match($3, "/") && match($1, "libQt|libicu")){printf("%s "), $3}}'`)
notfound_list=(`ldd $target_app | awk '{if (match($3, "not")){printf("%s "), $1}}'`)
# echo "notfound_list:$notfound_list"
target_path=$(cd `dirname "$target_app"`;pwd)
cd $target_path

dest="lib"
if [ ! -d "${target_path}/$dest" ]; then
    mkdir -p "${target_path}/$dest"
    echo mkdir "$target_path/$dest"
fi

for v in ${dependency_list[*]}; do
    if [[ "$v" =~ "libQt" ]]; then
        qtlib_path=$(cd `dirname "$v"`;pwd)
        dependency_list+=("$qtlib_path/libQt5XcbQpa.so.5" "$qtlib_path/libQt5DBus.so.5")
        break
    fi
done

echo target_path=$target_path
echo qtlib_path=$qtlib_path
# echo "dependency_list:(${dependency_list[@]})"

real_dependency_list=()
plug_dlist=()

for v in ${dependency_list[*]}; do
    if [ -L "$v" ]; then
        reallink=`readlink -nf "$v" 2>/dev/null`        
        real_dependency_list+=("$reallink")
    fi
    if [[ "$v" =~ "Gui" ]]; then              
        plug_dlist+=("platforms/libqxcb.so" "platforminputcontexts/" "platformthemes/" "iconengines/" "imageformats/")
        if [ -d "styles" ]; then
            plug_dlist+=("styles/")
        fi
    elif [[ "$v" =~ "Network" ]]; then 
        plug_dlist+=("bearer/")
    elif [[ "$v" =~ "Multimedia" ]]; then 
        plug_dlist+=("mediaservice/" "audio/" "playlistformats/")
    elif [[ "$v" =~ "Sql" ]]; then 
        plug_dlist+=("sqldrivers/")
    elif [[ "$v" =~ "PrintSupport" ]]; then 
        plug_dlist+=("printsupport/")
    elif [[ "$v" =~ "Positioning" ]]; then 
        plug_dlist+=("position/")
    elif [[ "$v" =~ "OpenGL" || "$v" =~ "XcbQpa" ]]; then
        plug_dlist+=("xcbglintegrations/")
    fi
done

alldep_list=(${dependency_list[@]} ${real_dependency_list[@]})

echo "real_len:${#real_dependency_list[*]}"
# echo "${alldep_list[@]}" | sed 's/ /\n/g'

# deploqy plugins
cd "$qtlib_path/../"
if [ -d "plugins" ]; then
    cd "plugins"
fi

plugin_lib="plugins"
if [ ! -d "${target_path}/$plugin_lib" ]; then
    mkdir -p "${target_path}/$plugin_lib"
fi

# create qt.conf
qtconf="${target_path}/qt.conf"
touch $qtconf
> $qtconf
echo "[Paths]" >> $qtconf
echo "Prefix = ./" >> $qtconf
echo "Plugins = $plugin_lib" >> $qtconf

# create xxx.sh
base_name=`basename $target_app`
runshell="${target_path}/${base_name}.sh"
touch $runshell
> $runshell
echo "#!/bin/bash" >> $runshell
echo 'bin_dir=`dirname "$0"`' >> $runshell
echo 'bin_dir=`cd "$bin_dir";pwd`' >> $runshell
echo 'cd $bin_dir' >> $runshell
echo 'export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$bin_dir/'"${dest}" >> $runshell
echo 'exec "$bin_dir/'"${base_name}\"" >> $runshell

# echo -e --${plug_dlist[@]}

sudo cp -a "${alldep_list[@]}" "${target_path}/${dest}"
sudo cp -dr --parents "${plug_dlist[@]}" "${target_path}/${plugin_lib}"
sudo chown -R ${USER}:${USER} "${target_path}"
sudo chmod 755 -R "${target_path}"

# qmake_path=`which qmake`
# if [ -n "$qmake_path" ]; then
#     if [ -L "$qmake_path" ]; then
#         qmake_path=`readlink -nf "$qmake_path" 2>/dev/null`
#     fi
# else
#     echo 'not in path'
# fi
