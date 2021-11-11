pipconf_dir="/home/$USER/.pip"
if [ ! -x "$pipconf_dir" ]; then
    mkdir -p "$pipconf_dir"
fi
cp pip.conf $pipconf_dir 
pip install --upgrade pip
