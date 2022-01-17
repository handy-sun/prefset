#!/bin/bash
target_app=$1
argu_list=($@)
argu_length=${#argu_list[*]}

if [ ! -x $target_app ]; then
    echo \'$target_app\' is not exist or cannot run.
    exit
fi
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

i=0
while [ $i -lt $argu_length ]; do
    echo i=$i ${argu_list[$i]}   
    next_one=${argu_list[$((i+1))]}
    # if [ "${argu_list[$i]}" == "-e" ]; then
    case "${argu_list[$i]}" in 
        "-e")        
            if [ -d "$next_one" ]; then
                abs_extra_dir=`cd "$next_one" ; pwd`
                extra_plugin_list=(`find $abs_extra_dir -name '*.so*'`)
            else
                j=$((i+1))
                while [ $j -lt $argu_length ]; do
                    if [[ ${argu_list[$j]} != -* ]]; then
                        p_argu+=(${argu_list[$j]})
                    else
                        break
                    fi
                    let ++j
                done
                # echo "p_argu=(${p_argu[@]})"
                split=","
                if [[ ${#p_argu[*]} -eq 1 && "${p_argu[@]}" =~ $split ]]; then
                    extra_plugin_list=(${next_one//$split/ })
                else
                    extra_plugin_list=(${p_argu[@]})
                fi
                i=$((j-1))
            fi
        ;;
        "-p")
            if [ -d "$next_one/plugins" ]; then
                qtplugin_path=`cd "$next_one/plugins" ; pwd`
                echo qtplugin_path=$qtplugin_path
            fi
        ;;
        "-N")
            dont_mkplugindir=1
        ;;
    esac
    let ++i
done

# echo argu_list=${argu_list[@]}, argu_length=$argu_length; exit

# get app's dependent .so list(we real need)
dep_list=(`ldd $target_app | awk '{if (match($3, "/") && match($1, "libQt|libicu")){printf("%s "), $3}}'`)
for var in ${dep_list[*]}; do
    if [[ "$var" =~ "libQt" ]]; then
        qtlib_path=$(cd `dirname "$var"` ; pwd)
        dep_list+=("$qtlib_path/libQt5XcbQpa.so.5" "$qtlib_path/libQt5DBus.so.5")
        break
    fi
done
var=""

for etp in ${extra_plugin_list[@]}; do
    extraplug_dep_list=(`ldd $etp 2>/dev/null | awk '{if (match($3, "/") && match($1, "libQt")){printf("%s "), $3}}'`)
    for ed in ${extraplug_dep_list[@]}; do
        if [[ ${dep_list[@]/${ed}/} == ${dep_list[@]} ]]; then
            dep_list+=("$ed")
        fi
    done
done 

notfound_list=(`ldd $target_app | awk '{if (match($3, "not")){printf("%s "), $1}}'`)
# echo "notfound_list:$notfound_list"
target_path=$(cd `dirname "$target_app"` ; pwd)
cd $target_path

# echo target_path=$target_path
# echo qtlib_path=$qtlib_path

echo "dep_list:( ${dep_list[@]} )" | sed 's/ /\n/g'

real_dep_list=()
plug_dlist=()

for var in ${dep_list[*]}; do
    if [ -L "$var" ]; then
        reallink=`readlink -nf "$var" 2>/dev/null`        
        real_dep_list+=("$reallink")
    fi
    if [[ "$var" =~ "Gui" ]]; then              
        plug_dlist+=("platforms/libqxcb.so" "platforminputcontexts/" "platformthemes/" "iconengines/" "imageformats/")
        if [ -d "styles" ]; then
            plug_dlist+=("styles/")
        fi
    elif [[ "$var" =~ "Network" ]]; then 
        plug_dlist+=("bearer/")
    elif [[ "$var" =~ "Multimedia" ]]; then 
        plug_dlist+=("mediaservice/" "audio/" "playlistformats/")
    elif [[ "$var" =~ "Sql" ]]; then 
        plug_dlist+=("sqldrivers/")
    elif [[ "$var" =~ "PrintSupport" ]]; then 
        plug_dlist+=("printsupport/")
    elif [[ "$var" =~ "Positioning" ]]; then 
        plug_dlist+=("position/")
    elif [[ "$var" =~ "OpenGL" || "$var" =~ "XcbQpa" ]]; then
        plug_dlist+=("xcbglintegrations/")
    fi
done

alldep_list=(${dep_list[@]} ${real_dep_list[@]})

echo "alldep_list.len:${#alldep_list[*]}"
# echo "${alldep_list[@]}" | sed 's/ /\n/g'

# change dir to qt.plugins..
# specified qtplugin_path
if [ -d "$qtplugin_path" ]; then
    cd "$qtplugin_path"
    echo "(specified qtplugin_path) cd `pwd`"
else
    if [ -d "$qtlib_path/../plugins" ]; then
        cd "$qtlib_path/../plugins"
        echo "cd `pwd`"
    elif [ -d "/usr/lib/qt/plugins/bearer" ]; then
        cd "/usr/lib/qt/plugins"
        echo "cd /usr/lib/qt/plugins"
    else
        echo "cannot find qt plugins directory!"
        exit -1
    fi
fi

# exit 0

dest="lib"
if [ ! -d "${target_path}/$dest" ]; then
    mkdir -p "${target_path}/$dest"
    echo mkdir "$target_path/$dest"
fi

if [ $dont_mkplugindir != "1" ]; then
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
else
    qtconf="${target_path}/qt.conf"
    if [ -x "$qtconf" ]; then
        rm -f $qtconf
    fi
fi

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
