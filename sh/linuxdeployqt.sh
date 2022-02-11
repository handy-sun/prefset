#!/bin/bash
show_opts()
{
    if [[ $LANG = zh_CN* ]]; then
        echo "linuxdeployqt.sh 是一个在Linux用来打包qt依赖库的脚本程序."
        echo "版本: $script_version"
        echo "用法: linuxdeployqt 打包的程序 [选项] <参数> [选项] <参数> ... "
        echo "选项:"
        echo "  -p,   指定一个路径，其子目录必须包含名为'plugins'的qt插件目录，"
        echo "        若环境变量中已包含此路径可不指定此选项；找不到正确的插件目录将终止脚本"
        echo "  -e,   打包一组额外的库的依赖，后边可跟: 1、这些库所在的文件夹；2、通配符组成的库列表；"
        echo "        3、每个库的路径，以','分隔开"
        echo "  -N,   所有插件将放在和打包的程序同一级目录下（默认放在打包程序目录下的plugins文件夹下）"
        echo "  -D,   指定用于appimagetool打包所用的desktop文件的名称（无需扩展名），若不指定名称则自动生成"
        echo "        注意：若指定此选项，那 -i 也必须指定"
        echo "  -i,   指定desktop文件所需的图标文件（后缀名为: .png，.svg，.xpm）"
        echo "  -h,   查看帮助信息"
        echo " "
    else
        echo "linuxdeployqt.sh is a shell script for deploy qt libraries on linux."
        echo "Version: $script_version"
        echo "Usage: linuxdeployqt deploy_filename [OPTION] <ARGU> [OPTION] <ARGU> ... "
        echo "Options:"
        echo "  -p,   specify the directory which contains a 'plugins' child directory of qt,"
        echo "        it's not necessary to specify it if PATH contains;"
        echo "        script will terminate if the directory is wrong."
        echo "  -e,   package some extra files' depends, behind argu maybe: 1, the directory libs locate；"
        echo "        2, the lib's list with wild card character； 3，every lib's path split with ','"
        echo "  -N,   all plugins lib and deploy_file under the same directory(all plugins lib locate at a folder"
        echo "        named plugins under deploy_file's path default)"
        echo "  -D,   specify the desktop-file's name (donnot need extension name) which appimagetool used，"
        echo "        if don't specify the name, a default desktop file generate automatical"
        echo "        Note：if specify this option，then options '-i' must be specified."
        echo "  -i,   specify the icon-file's name which desktop-file needed(extension name: .png，.svg，.xpm) "
        echo "  -h,   show helps"
        echo " "
    fi
}

get_dependent_list()
{
    _arr=(`ldd $1 2>/dev/null | awk '(match($3, "/")) { printf("%s %s\n"), $1, $3 }' | egrep -v $exclude_str | awk '{ printf("%s\n"), $2}'`)
    echo ${_arr[@]}
}
script_version="1.0.1"
target_app=$1
argu_list=($@)
argu_length=${#argu_list[*]}

if [ "$target_app" == "-h" -o $argu_length -eq 0 ]; then
    show_opts
    exit
fi

if [ ! -x $target_app ]; then
    echo \'$target_app\' is not exist or cannot run.
    exit
fi

if [ $argu_length -gt 0 ]; then
    unset argu_list[0]
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
                extra_plugin_list=(`find $abs_extra_dir -maxdepth 1 -name '*.so*'`)
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
                gen_appimage_desktop="${gen_appimage_desktop}-appimage.desktop"
            fi
            echo gen_appimage_desktop=$gen_appimage_desktop
        ;;
        "-i")
            if [ -e "$next_one" ]; then
                if [[ "$next_one" = *.png || "$next_one" = *.svg || "$next_one" = *.xpm ]]; then
                    icon_file=$next_one
                    icon_name=`basename "$icon_file"`
                    icon_file="$(cd `dirname "$icon_file"` ; pwd)/$icon_name"
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

# if [ ! -n "$gen_appimage_desktop" -a -n "$icon_file" ]; then
#     echo "'-i' is ok but '-D' can't work ."
#     exit -1
# fi

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
# dep_list=(`ldd $target_app | awk '{ if (match($3, "/")){ printf("%s %s\n"), $1, $3 } }' | egrep -v $exclude_str | awk '{ printf("%s\n"), $2}'`)
dep_list=(`get_dependent_list $target_app`)

for var in ${dep_list[*]}; do
    if [[ "$var" =~ "libQt5Core" ]]; then
        qtlib_path=$(cd `dirname "$var"` ; pwd)
        dep_list+=("$qtlib_path/libQt5XcbQpa.so.5" "$qtlib_path/libQt5DBus.so.5")
    elif [[ "$var" =~ "libQt5Gui" ]]; then
        qtlib_path=$(cd `dirname "$var"` ; pwd)
        dep_list+=("$qtlib_path/libQt5Svg.so.5")
    fi
done
# make array's item unique
dep_list=($(awk -v RS=' ' '!a[$1]++' <<< ${dep_list[@]}))
# echo "dep_list=( ${dep_list[@]} )" | sed 's/ /\n/g'

var=""

for etp in ${extra_plugin_list[@]}; do
    extraplug_dep_list=(`get_dependent_list $etp`)
    for ed in ${extraplug_dep_list[@]}; do
        if [[ ${dep_list[@]/${ed}/} == ${dep_list[@]} ]]; then
            dep_list+=("$ed")
        fi
    done
done

notfound_list=(`ldd $target_app | awk '(match($3, "^not$")) { printf("%s "), $1 }'`)
if [ ${#notfound_list[*]} -gt 0 ]; then
    echo "Some libraries don't found, check it and try again."
    echo "Notfound_list:( ${notfound_list[@]} )" | sed 's/ /\n/g'
    exit -1
fi

target_path=$(cd `dirname "$target_app"` ; pwd)
# cd $target_path

echo Qt5lib_path = $qtlib_path

# change dir to qt.plugins..
# specified qtplugin_path
if [ -d "$qtplugin_path" ]; then
    cd "$qtplugin_path"
    echo "Specified qtplugin's path: `pwd`"
# donnot specified qtplugin_path
else
    if [ -d "$qtlib_path/../plugins/bearer" ]; then
        cd "$qtlib_path/../plugins"
        echo "Change dir to `pwd`"
    elif [ -d "/usr/lib/qt/plugins/bearer" ]; then
        cd "/usr/lib/qt/plugins"
        echo "Change dir to /usr/lib/qt/plugins"
    else
        echo "Cannot find qt plugins directory!"
        exit -1
    fi
fi

real_dep_list=()
plug_dlist=()

for var in ${dep_list[*]}; do
    if [ -L "$var" ]; then
        reallink=`readlink -nf "$var" 2>/dev/null`
        real_dep_list+=("$reallink")
    fi
    if [[ "$var" =~ "Gui" ]]; then
        gui_temp_list=("platforms/libqxcb.so" "platforminputcontexts/" "platformthemes/" "iconengines/" "imageformats/" "styles/")
        for _vartemp in ${gui_temp_list[*]}; do
            if [ -e "$_vartemp" ]; then
                plug_dlist+=($_vartemp)
            fi
        done 
    elif [[ "$var" =~ "Network" ]]; then
        plug_dlist+=("bearer/")
    elif [[ "$var" =~ "Multimedia" ]]; then
        media_temp_list=("mediaservice/" "audio/" "playlistformats/")
        for _vartemp in ${media_temp_list[*]}; do
            if [ -d "$_vartemp" ]; then
                plug_dlist+=($_vartemp)
            fi
        done 
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
# echo "${plug_dlist[@]}" 
# echo "all dependent shared library count(contain symbollink): ${#alldep_list[*]}"
# echo "${alldep_list[@]}" | sed 's/ /\n/g'

dest="lib"
if [ ! -d "${target_path}/$dest" ]; then
    mkdir -p "${target_path}/$dest"
    echo Mkdir "$target_path/$dest"
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
sh_name="${app_name}.sh"
cat > "${target_path}/$sh_name" << "EOF"
#!/bin/bash
real_link=`readlink -nf "$0"`
bin_dir=`dirname "$real_link"`
bin_dir=`cd "$bin_dir" ; pwd`
cd $bin_dir
EOF
cat >> "${target_path}/$sh_name" << EOF
export LD_LIBRARY_PATH=\$LD_LIBRARY_PATH:\$bin_dir/${dest}
exec "\$bin_dir/${app_name}"
EOF

# echo -e --${plug_dlist[@]}

sudo cp -a "${alldep_list[@]}" "${target_path}/${dest}"
sudo cp -dr --parents "${plug_dlist[@]}" "${target_path}/${plugin_lib}"
sudo chown -R ${USER}:${USER} "${target_path}"
sudo chmod 755 -R "${target_path}"

echo "All dependent shared library copy to: ${target_path}/${dest}"
echo "All dependent qt plugins copy to: ${target_path}/${plugin_lib}"

# create *.desktop
if [ ! -n "$gen_appimage_desktop" -a ! -n "$icon_file" ]; then
    echo "Finished."
    exit 0
fi

sudo cp ${icon_file} ${target_path} 
ln -sf "$sh_name" "$target_path/AppRun"

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
echo "Finished."
