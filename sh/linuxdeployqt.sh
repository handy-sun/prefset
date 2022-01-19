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
app_name=`basename $target_app`

i=0
while [ $i -lt $argu_length ]; do
    # echo i=$i ${argu_list[$i]}
    next_one=${argu_list[$((i+1))]}
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
            fi
        ;;
        "-N")
            dont_mkplugindir=1
        ;;
        "-D")
            if [ -n "$next_one" ] && [[ "$next_one" != -* ]]; then
                gen_appimage_desktop=$next_one
            else
                gen_appimage_desktop=$app_name
            fi

            if [[ "$gen_appimage_desktop" != *.desktop ]]; then
                gen_appimage_desktop="${gen_appimage_desktop}_appimage.desktop"
            fi
            echo gen_appimage_desktop=$gen_appimage_desktop
        ;;
        "-i")
            if [ -e "$next_one" ]; then
                if [[ "$next_one" = *.png || "$next_one" = *.svg || "$next_one" = *.xpm ]]; then
                    icon_file=$next_one
                    echo icon_file=$icon_file
                fi
            fi
        ;;
    esac
    let ++i
done

if [ -n "$gen_appimage_desktop" -a ! -n "$icon_file" ]; then
    echo "'-D' is ok but '-i' can't work ."
    exit -1
fi

if [ ! -n "$gen_appimage_desktop" -a -n "$icon_file" ]; then
    echo "'-i' is ok but '-D' can't work ."
    exit -1
fi

exclude_list=(
    "ld-linux.so.2"
    "ld-linux-x86-64.so.2"
    "libanl.so.1"
    "libasound.so.2"
    "libBrokenLocale.so.1"
    "libcidn.so.1"
    "libcom_err.so.2"
    "libc.so.6"
    "libdl.so.2"
    "libdrm.so.2"
    "libEGL.so.1"
    "libexpat.so.1"
    "libfontconfig.so.1"
    "libfreetype.so.6"
    "libfribidi.so.0"
    "libgbm.so.1"
    "libgcc_s.so.1"
    "libgdk_pixbuf-2.0.so.0"
    "libgio-2.0.so.0"
    "libglapi.so.0"
    "libGLdispatch.so.0"
    "libglib-2.0.so.0"
    "libGL.so.1"
    "libGLX.so.0"
    "libgobject-2.0.so.0"
    "libgpg-error.so.0"
    "libharfbuzz.so.0"
    "libICE.so.6"
    "libjack.so.0"
    "libm.so.6"
    "libmvec.so.1"
    "libnss_compat.so.2"
    "libnss_db.so.2"
    "libnss_dns.so.2"
    "libnss_files.so.2"
    "libnss_hesiod.so.2"
    "libnss_nisplus.so.2"
    "libnss_nis.so.2"
    "libp11-kit.so.0"
    "libpango-1.0.so.0"
    "libpangocairo-1.0.so.0"
    "libpangoft2-1.0.so.0"
    "libpthread.so.0"
    "libresolv.so.2"
    "librt.so.1"
    "libSM.so.6"
    "libstdc\\+\\+.so.6"
    "libthai.so.0"
    "libthread_db.so.1"
    "libusb-1.0.so.0"
    "libutil.so.1"
    "libuuid.so.1"
    "libX11.so.6"
    "libxcb-dri2.so.0"
    "libxcb-dri3.so.0"
    "libxcb.so.1"
    "libz.so.1"
    "ld-linux-aarch64.so.1"
    # "libgthread-2.0.so.0"
    # "libpcre.so.3"
    # "libXau.so.6"
    # "libXdmcp.so.6"
    # "libbsd.so.0"
)
exclude_str=`echo ${exclude_list[@]} | sed 's/ /|/g'`

# get app's dependent .so list(real need)
# dep_list=(`ldd $target_app | awk '{if (match($3, "/") && match($1, "libQt|libicu")){printf("%s "), $3}}'`)
dep_list=(`ldd $target_app | awk '{ if (match($3, "/")){ printf("%s %s\n"), $1, $3 } }' | egrep -v $exclude_str | awk '{ printf("%s\n"), $2}'`)

for var in ${dep_list[*]}; do
    if [[ "$var" =~ "libQt" ]]; then
        qtlib_path=$(cd `dirname "$var"` ; pwd)
        dep_list+=("$qtlib_path/libQt5XcbQpa.so.5" "$qtlib_path/libQt5DBus.so.5")
        break
    fi
done
var=""
# echo "dep_list=( ${dep_list[@]} )" | sed 's/ /\n/g'

for etp in ${extra_plugin_list[@]}; do
    extraplug_dep_list=(`ldd $etp 2>/dev/null | awk '{ if (match($3, "/")){ printf("%s %s\n"), $1, $3 } }' | egrep -v $exclude_str | awk '{ printf("%s\n"), $2}'`)
    for ed in ${extraplug_dep_list[@]}; do
        if [[ ${dep_list[@]/${ed}/} == ${dep_list[@]} ]]; then
            dep_list+=("$ed")
        fi
    done
done

notfound_list=(`ldd $target_app | awk '{if (match($3, "not")){printf("%s "), $1}}'`)
if [ ${#notfound_list[*]} -gt 0 ]; then
    echo "some libraries don't found, check it and try again:( ${notfound_list[@]} )" | sed 's/ /\n/g'
    exit -1
fi

target_path=$(cd `dirname "$target_app"` ; pwd)
cd $target_path

echo qtlib_path=$qtlib_path

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

# echo "all dependent shared library count(contain symbollink): ${#alldep_list[*]}"
# echo "${alldep_list[@]}" | sed 's/ /\n/g'

# change dir to qt.plugins..
# specified qtplugin_path
if [ -d "$qtplugin_path" ]; then
    cd "$qtplugin_path"
    echo "specified qtplugin's path: `pwd`"
# donnot specified qtplugin_path
else
    if [ -d "$qtlib_path/../plugins/bearer" ]; then
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
else
    rm -rf "${target_path}/$dest/*"
fi

if [ "$dont_mkplugindir" != "1" ]; then
    plugin_lib="plugins"
    if [ ! -d "${target_path}/$plugin_lib" ]; then
        mkdir -p "${target_path}/$plugin_lib"
    fi
    # create qt.conf
    qtconf="${target_path}/qt.conf"
  cat > $qtconf << EOF
[Paths]
Prefix = ./
Plugins = $plugin_lib
EOF
:
else
    # remove qt.conf beacause don't need it
    qtconf="${target_path}/qt.conf"
    if [ -x "$qtconf" ]; then
        rm -f $qtconf
        echo remove file:$qtconf
    fi
fi

# create $app_name.sh
run_shell="${target_path}/${app_name}.sh"
cat > "$run_shell" << "EOF"
#!/bin/bash
bin_dir=`dirname "$0"`
bin_dir=`cd "$bin_dir" ; pwd`
cd $bin_dir
EOF
cat >> "$run_shell" << EOF
export LD_LIBRARY_PATH=\$LD_LIBRARY_PATH:\$bin_dir/${dest}
exec "\$bin_dir/${app_name}"
EOF

# echo -e --${plug_dlist[@]}

sudo cp -a "${alldep_list[@]}" "${target_path}/${dest}"
sudo cp -dr --parents "${plug_dlist[@]}" "${target_path}/${plugin_lib}"
sudo chown -R ${USER}:${USER} "${target_path}"
sudo chmod 755 -R "${target_path}"

echo "all dependent shared library copy to: ${target_path}/${dest}"
echo "all qt plugins copy to: ${target_path}/${plugin_lib}"

# create *.desktop
if [ ! -n "$gen_appimage_desktop" -a ! -n "$icon_file" ]; then
    echo "finished."
    exit 0
fi

sudo cp ${icon_file} ${target_path} 2>/dev/null
ln -sf "$run_shell" "$target_path/AppRun"

icon_name=`basename ${icon_file}`
icon_name=${icon_name%.*}

cat > "$target_path/$gen_appimage_desktop" << EOF
[Desktop Entry]
Name=${app_name}
Terminal=false
Type=Application
Categories=Development;
Exec=AppRun
Icon=${icon_name}
EOF
echo create "$target_path/$gen_appimage_desktop"
echo "finished."
