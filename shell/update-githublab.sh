#!/bin/bash

# set -x

Red="\033[31m"
Green="\033[32m"
Yellow="\033[33m"
Blue="\033[34m"
Color_Reset="\033[0m"

pull_hub_or_lab() {
  for child_dir in $(ls $1); do
    dir_or_file="$1/$child_dir"

    if [ -d "$dir_or_file/.git" ]; then
      cd $dir_or_file
      is_github_url=$(git remote -v | grep -E '[//|@]github.com|[//|@]gitlab.com|[//|@]codeberg.org')
      if [ $? -ne 0 ]; then
        echo -e "${Red}$child_dir is not a github or gitlab respo, skipped.\n${Color_Reset}"
        continue
      fi

      modify_cnt=$(git status -s | grep -E '^ M|^A' | wc -l)
      if [ $modify_cnt -gt 0 ]; then
        while true; do
          echo -e "Stash your changes before pull repo:<${Green}$child_dir${Color_Reset}>? (y/n/s)"
          echo "-- y: yes (stash it then pull and shash pop)"
          echo "-- n: no (discard all changes then pull)"
          echo "-- s: skip (do nothing)"
          read -p "Input the word:" choice
          case $choice in
            [Yy]* ) 
              echo -e "${Yellow}git stash <$child_dir>${Color_Reset}"
              [ $2 -eq 1 ] && git stash

              echo -e "${Yellow}git pull <$child_dir>${Color_Reset}"
              if [ $2 -eq 1 ]; then
                git pull

                if [ $? -eq 0 ]; then
                  if git stash pop; then
                    echo -e "${Green}stash pop success${Color_Reset}"
                  else
                    echo -e "${Red}stash pop failed, has some conflicts${Color_Reset}"
                  fi
                else
                  echo -e "${Red}pull failed${Color_Reset}"
                fi

              fi
              break;;
            [Nn]* )
              echo -e "${Green}git checkout . <$child_dir>${Color_Reset}"
              [ $2 -eq 1 ] && git checkout .
              echo -e "${Green}git pull <$child_dir>${Color_Reset}"
              [ $2 -eq 1 ] && git pull
              break;;
            [Ss]* )
              echo -e "${Blue}Skip for <$child_dir>${Color_Reset}";
              break;;
            * )
              echo "Input error!Please answer y, n or s!";
          esac
        done
      else
        echo -e "${Blue}git pull <$child_dir>${Color_Reset}"
        [ $2 -eq 1 ] && git pull
      fi
    else
      echo -e "${Red}$child_dir donnot have '.git' directory${Color_Reset}"
    fi
  done
}

# param1: define project root dir, if param2 is not empty, must specify param1
if [ "$1" == "" ]; then
  root_dir=`cd $(dirname "$0");pwd`
else
  if [ ! -d "$1" ]; then
    echo "$1 not exist"
    exit 1
  fi
  root_dir=`cd $(dirname "$1");pwd`
fi

echo -e root_dir = "$root_dir\n"
# param2: dry-run mode
if [ "$2" == "-d" ]; then
  pull_hub_or_lab $root_dir 0
else
  pull_hub_or_lab $root_dir 1
fi

