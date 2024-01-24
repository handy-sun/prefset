#!/bin/bash

argu_list=($@)
argu_length=${#argu_list[*]}

i=0
while [ $i -lt $argu_length ]; do
    case "${argu_list[$i]}" in
        "-f")
            out_file=${argu_list[$((i+1))]}
        ;;
    esac
    case "${argu_list[$i]}" in
        "-p")
            process=${argu_list[$((i+1))]}
        ;;
    esac
    let ++i
done

if [[ "" == "${out_file}" ]]; then
    out_file=/tmp/loop.log
    echo "use default log file: ${out_file}"
fi

if [[ "" == "${process}" ]]; then
    process=main.app
fi

echo "observe process: ${process}" | tee -a ${out_file}

for i in {1..28800}; do
    pid=`ps aux | grep ${process} | grep -v grep | grep -v observe_fd | awk '{print$2}' | head -1`
    if [[ "" != "${pid}" ]]; then
        date 2>&1 | tee -a ${out_file}
        ls -l /proc/${pid}/fd 2>&1 | tee -a ${out_file}
    else
        echo "\"${process}\" not running!"
        exit 1
    fi

    sleep 2
done
