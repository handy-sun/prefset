# shell function
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
# final location of a command
finloc(){
    readlink -f `which ${1}`
}
# git
alias gta="git status"

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
alias sybeg="sudo systemctl start"
alias syrs="sudo systemctl restart"
alias systo="sudo systemctl stop"
alias syrld="sudo systemctl reload"
alias syen="sudo systemctl enable"
alias sydis="sudo systemctl disable"

# cmake
export BUILD_DIR="./build"
alias cmkln="rm -rf ${BUILD_DIR}/CMakeCache.txt ${BUILD_DIR}/CMakeFiles/"
alias cmkg="cmake -B${BUILD_DIR} -G 'Ninja'"
alias cmba="cmake --build ${BUILD_DIR}"
alias cmb="cmake --build ${BUILD_DIR} -t"

# other shell
alias pingx="ping -c 4 -s 1024 -t 10"
alias gdb="gdb -q"

alias ll="ls -AlF"
alias lh="ls -AlFh"
alias la="ls -alF"

_trash=`which trash 2>/dev/null`
if [ $? -eq 0 ]; then
    alias rm="trash"
fi

# TODO: nvim

_is_bash=`echo $SHELL | grep bash`
# only bash use this PS1.
if [ $? -eq 0 ]; then
    PS1="[\[\033[0;32m\]\A \[\033[0;31m\]\u\[\033[0;34m\] \[\033[00;36m\]\W\[\033[0;33m\]\[\e[0m\]] "
fi

unset _trash
unset _is_bash
# some env var
# history format only worked for bash; zsh can use 'history -i', see 'man zshoptions'
export HISTTIMEFORMAT='%F %T '

if [ -d $HOME/.local/include ]; then
    export C_INCLUDE_PATH=$C_INCLUDE_PATH:$HOME/.local/include
    export CPLUS_INCLUDE_PATH=$CPLUS_INCLUDE_PATH:$HOME/.local/include
fi

if [ -d $HOME/.local/lib ]; then
    export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$HOME/.local/lib
fi
