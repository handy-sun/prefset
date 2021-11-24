if [ "$1" != "" ]; then
    input_dir=$1
    if [ ! -x "$input_dir" ]; then
        echo -e "\033[31m[Error]\033[0m folder \"${input_dir}\" not exits."
        exit
    fi
fi

suf="*\.exe|*\.json"
if [ "${input_dir:0-1}" != "/" ]; then
    input_dir="${input_dir}/"
fi
find ${input_dir} | egrep $suf | sed 's#'$input_dir'##g'