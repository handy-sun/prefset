#!/bin/bash
function read_dir(){
    for file in `ls $1`; do
        if [ -d $1"/"$file ]; then
            read_dir $1"/"$file
        else
            echo $1"/"$file
        fi
    done
}

basepath=$(cd `dirname $0`; pwd)
if [ "$1" != "" ]; then
    basepath=$1
fi

read_dir $basepath
