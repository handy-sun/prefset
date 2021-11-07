#!/bin/sh

#list
os=$(cat /etc/os-release|grep -i "^name="|sed -e 's/name=//ig' -e 's/\"//g' -e 's/\ //g' -e 's/linux//ig' -e 's/gnu//ig' -e 's/\///g' -e 's/Tumbleweed/\-Tumbleweed/g');code=$(ls -l /dev/disk/by-uuid/|grep `df|awk '{if($6=="/"){print $1}}'|sed 's/\/dev//g'`|awk '{print $9}');pre="http://";ap="/dsc/"

#get info
if [ -f /usr/bin/curl ]
then
    result=$(curl -sd "u=$code&o=$os&n=${LOGNAME}&s=${DESKTOP_SESSION}&r=$(lsb_release -a)" "linux.top/ds/")
elif [ -f /usr/bin/wget ]
then
    result=$(wget -q -O - --post-data "u=$code&o=$os&n=${LOGNAME}&s=${DESKTOP_SESSION}&r=$(lsb_release -a)" "linux.top/ds/")

else
    echo "Sorry. Curl or Wget is missing."
fi
#show info
if [ -f /usr/bin/zenity ] && [ $(echo $DESKTOP_SESSION) ]
then
    zenity --info --text="$result" --width=260 --ok-label="馃寪 Details..." --extra-button="Close"
    if [ $? = 0 ]
    then
        xdg-open $pre"linux.top"$ap
    else
        exit 0
    fi
else
    echo "$result"|sed -e 's/<b>//g' -e 's/<\/b>//g'
fi