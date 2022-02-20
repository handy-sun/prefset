#!/bin/bash
if [ -d "$1" ]; then
    cd "$1"
fi

real=(`ls | egrep '*.so(.[0-9]+){2,3}$' | sort`)
softlink=(`ls | egrep '*.so.[0-9]+$' | sort`)
len_real=${#real[*]}
len_softlink=${#softlink[*]}
if [ $len_real -ne $len_softlink ]; then
    echo "two list's length don\'t equal to each other."
fi

i=0
while [ $i -lt $len_real ]; do
    # ln -sf ${real[$i]} ${softlink[$i]}
    echo ${real[$i]} | grep -Eeo '*.so.[0-9]+$'
    # echo "${real[$i]} ${softlink[$i]}"
    let ++i
done
