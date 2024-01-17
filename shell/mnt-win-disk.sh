#!/bin/bash
win_device_arr=($(LANG=C fdisk -l 2>/dev/null | grep 'Microsoft basic data' | awk '{print$1}'))
mounted_device_arr=($(LANG=C df -h | grep -E '^/dev/*' | awk '{print$1}'))

device_count=${#win_device_arr[*]}

# 0x63=99 is ascii value of 'c'
ch_hex=63

i=0
while [ $i -lt ${device_count} ]; do
    one=${win_device_arr[$i]}
    isIn=0
    for var in ${mounted_device_arr[*]}; do
        if [ $var == $one ]; then
            isIn=1
            break
        fi
    done
    tar_dir=/mnt/$(echo -ne "\x$((ch_hex + i))")
    isHasFile=`ls $tar_dir 2>/dev/null | wc -l`
    if [[ $isIn -eq 0 && isHasFile -eq 0 ]]; then
        if [ ! -d "$tar_dir" ]; then
            mkdir -p $tar_dir
        fi
        mount $one $tar_dir
        echo "mount $one $tar_dir"
    else
        echo "$one has been mounted or \"$tar_dir\" is not empty dir"
    fi
    let ++i
done

