pipconf_dir="$HOME/.pip"
if [ ! -x "$pipconf_dir" ]; then
    mkdir -p "$pipconf_dir"
fi
sh_dir=$(cd `dirname $0`; pwd)

echo "cp $sh_dir/pip.conf $pipconf_dir"
cp $sh_dir/pip.conf $pipconf_dir

pip_cmd=""
cmd_list=("pip" "pip3" "pip2")
for v in ${cmd_list[@]}; do
    absolute=`which "$v"`
    value=$?
    if [ $value -eq 0 ]; then
        pip_cmd=$absolute
        echo $pip_cmd 'chedeng'
        break
    fi
done

if [ -x "$pip_cmd" ]; then
    "$pip_cmd" install --upgrade pip
    echo "Finished upgrade"
else
    echo "Donnot find suitable 'pip' commond"
    exit -1
fi
