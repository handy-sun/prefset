## define some func,alias,variable in zsh/bash shell script
# ----------------------- shell function ----------------------
# about git stash
shpo(){
    git stash pop stash@{${1}};
}
shap(){
    git stash apply stash@{${1}};
}
shsw(){
    git stash show -p stash@{${1}};
}
shdr(){
    git stash drop stash@{${1}};
}
# get pid of a process, avoid some Linux system cannot use 'pgrep' command
pgre(){
    ps -ef | grep "${1}" | grep -v grep | awk '{print$2;}'
}
# same to pgre(), and it also print parent pid
ppre(){
    ps -ef | grep "${1}" | grep -v grep | awk '{print$2, $3;}'
}
# final location of which command
fwhich(){
    local whi=`which ${1} 2>/dev/null`
    [ $? -eq 0 -a -x ${whi} 2>/dev/null ] && readlink -f ${whi} || echo "Error:${whi}"
}
# tar compress/uncompress with pigz
tcpzf(){
    which pigz >/dev/null 2>&1 || { echo "Not install pigz !"; return 1; }
    tar cf - ${2} | pigz --fast > ${1}
}
txpz(){
    which pigz >/dev/null 2>&1 || { echo "Not install pigz !"; return 1; }
    tar --no-same-owner -xf ${1} -I pigz
}
dus(){
	du $1 -alh -d1 | sort -rh | head -n 11
}
# ----------------------- alias ----------------------
# git
alias gta="git status"
alias gts="git status -s"
alias gtun="git status uno"

alias gcm="git commit"
alias gcma="git commit -a"
alias gcmn="git commit --amend"
alias gcman="git commit -a --amend"

alias gpl="git pull"
alias gplrb="git pull --rebase"

alias gsh="git stash"
alias gshl="git stash list"

alias grs="git reset"
alias grsh="git reset --hard"
alias grss="git reset --soft"
alias gstag="git restore --staged"

alias glg="git log --pretty=format:'%Cred%h%Creset -%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset %C(yellow)%d' --abbrev-commit --color"
alias glp="git log --pretty=format:'%Cred%h%Creset -%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset %C(yellow)%d' --abbrev-commit --color --graph"

alias gdf="git diff"
alias gdfh="git diff HEAD"
alias gdfc="git diff --cached"
alias gbr="git branch"
alias gbra="git branch -a"
alias gtl="git tag --list"
alias gck="git checkout"
alias grtv="git remote -v"
alias gblm="git blame -L"
alias gaprj="git apply --reject"
# tar
alias tarx="tar --no-same-owner -xf"
alias tarz="tar zcf"

# systemctl
alias syta="systemctl status"
alias syst="sudo systemctl start"
alias syrs="sudo systemctl restart"
alias systo="sudo systemctl stop"
alias syrld="sudo systemctl reload"
alias syen="sudo systemctl enable"
alias syenw="sudo systemctl enable --now"
alias sydis="sudo systemctl disable"
alias sydisw="sudo systemctl disable --now"

# cmake
export BUILD_DIR="./build"
alias cmkln="rm -rf ${BUILD_DIR}/CMakeCache.txt ${BUILD_DIR}/CMakeFiles/"
alias cmkr="cmake -B${BUILD_DIR} -G 'Ninja' -DCMAKE_BUILD_TYPE=Release"
alias cmkd="cmake -B${BUILD_DIR} -G 'Ninja' -DCMAKE_BUILD_TYPE=Debug"
alias cmba="cmake --build ${BUILD_DIR}"
alias cmb="cmake --build ${BUILD_DIR} -t"

# other shell
alias pingk="ping -c 4 -s 1024"
alias gdb="gdb -q"

alias ll="ls -AlF"
alias lh="ls -AlFh"
alias la="ls -alF"

which trash >/dev/null 2>&1 && alias rm="trash"
which xclip >/dev/null 2>&1 && alias pbcopy="xclip -selection clipboard" && alias pbpaste="xclip -selection clipboard -o"

alias grep >/dev/null 2>&1 || alias grep="grep --color=auto"

# only bash use this PS1.
echo $SHELL | grep -E '/bash$' >/dev/null 2>&1
if [ $? -eq 0 ]; then
    last_exit_code="\$(LEC=\$? ; [[ \$LEC -ne 0 ]] && printf \"\033[91m%d \033[0m\" \$LEC)"
    PS1="\[\e[0m\]\[\033[0;32m\]\A \[\033[00;36m\]\w\[\033[0;33m\]\[\e[0m\] ${last_exit_code}\\$ "
    unset last_exit_code
fi

# ----------------------- export some env var -------------------------
# history format only worked for bash; zsh can use 'history -i', see 'man zshoptions'
export HISTTIMEFORMAT='%F %T '
export HISTSIZE=5000
export SAVEHIST=5000

local_inc=$HOME/.local/include
if [ -d $local_inc ]; then
    [[ ! $C_INCLUDE_PATH =~ $local_inc ]] && export C_INCLUDE_PATH=$C_INCLUDE_PATH:$local_inc
    [[ ! $CPLUS_INCLUDE_PATH =~ $local_inc ]] && export CPLUS_INCLUDE_PATH=$CPLUS_INCLUDE_PATH:$local_inc
fi
unset local_inc

local_lib=$HOME/.local/lib
[[ -d $local_lib && ! $LD_LIBRARY_PATH =~ $local_lib ]] && export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$local_lib
unset local_lib
