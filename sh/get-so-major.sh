#!/bin/bash
str="$1"
if [ ! -n "$str" ]; then
    exit -1
fi
dn=`dirname $str`
str=`basename $str`
idx=`expr index "$str" .so`
idx=$(($idx+2))
# echo idx=$idx
left=${str:0:$idx}
right=${str:$idx}
echo right=$right, left=$left
# echo "$right" | grep -o "\." | wc -l
# expr "$str" : ".*\(\(.[0-9]\{1,3\}\)\{2\}\)"
onedot=`expr "$right" : "\(\(.[0-9]\{1,3\}\)\{1\}\)"`
if [ -n "$dn" ]; then
    echo "${dn}/$left$onedot"
else
    echo $left$onedot
fi
