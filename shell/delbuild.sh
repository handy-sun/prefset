#!/bin/bash
function read_dir(){
    for ele in `ls -F $1`; do
        if [ "${ele:0-1}" == "/" ]; then
            # %/* 表示从右边开始，删除第一个 / 号及右边的字符
            child_dir="$1/${ele%/*}"
            result=$(echo $child_dir | grep "/build")
            if [ "$result" != "" ]; then
                echo "rm dir: $child_dir"
                rm -rf $child_dir
            else
                read_dir $child_dir
            fi            
            
        fi
    done
}

basepath=$(cd `dirname $0`; pwd)
if [ "$1" != "" ]; then
    basepath=$1
fi

read_dir $basepath
