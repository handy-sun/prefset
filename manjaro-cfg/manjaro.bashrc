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
alias syen="sudo systemctl enable"
alias sydis="sudo systemctl disable"

# cmake
export BUILD_DIR="./build"
alias cmkln="rm -rf ${BUILD_DIR}/CMakeCache.txt ${BUILD_DIR}/CMakeFiles/"
alias cmgn="cmake -B${BUILD_DIR} -G 'Ninja'"
alias cmball="cmake --build ${BUILD_DIR}"
alias cmb="cmake --build ${BUILD_DIR} --target"

# other shell
alias ping4="ping -c 4 -s 1024"
alias gdb="gdb -q"

alias ll="ls -AlF"
alias lh="ls -AlFh"
alias la="ls -alF"

has_trash=`which trash | grep -E '^/*'`
if [[ "${has_trash}" != "" ]]; then
    alias rm="trash"
fi

# TODO: nvim

shell_is_bash=`echo $SHELL | grep bash`
if [[ "${shell_is_bash}" != "" ]]; then
    # only worked for bash
    PS1="[\[\033[0;32m\]\A \[\033[0;31m\]\u\[\033[0;34m\] \[\033[00;36m\]\W\[\033[0;33m\]\[\e[0m\]] "
fi

# some env var
# history format only worked for bash; zsh can use 'history -i', see 'man zshoptions'
export HISTTIMEFORMAT='%F %T '

export C_INCLUDE_PATH=$C_INCLUDE_PATH:$HOME/.local/include
export CPLUS_INCLUDE_PATH=$CPLUS_INCLUDE_PATH:$HOME/.local/include
