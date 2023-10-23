#!/bin/bash
CHK_PORT=$1
if ! [[ "$CHK_PORT" =~ ^[1-9][0-9]{0,4}$ && "$CHK_PORT" -le 65535 ]]; then
    echo "Error, the port input must between 1 and 65535."
    exit 1
fi

n=1
while true; do
    CONTENT=`sudo netstat -antp | grep ":$CHK_PORT"`
    if [ $? -eq 0 ]; then
        echo "port is in used!"
        break
    else
        echo "check port: $CHK_PORT repeat $n."
    fi

    if [ $n -ge 3 ]; then
        echo "port is not in use"
        exit 1
    fi
    n=$(($n+1))
    sleep 2
done

