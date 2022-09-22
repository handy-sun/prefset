# custom
alias ll="ls -lAF"
alias rm="rm -f"
alias gdb="gdb -q"

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
# alias grsH="git reset HEAD"

alias glg="git log"
alias glgo="git log --oneline"
alias glgp="git log --graph"

alias gdf="git diff"
alias gdfh="git diff HEAD"
alias gbr="git branch"
alias gck="git checkout"
alias gme="git merge"
alias grm="git rm"


# last_exit_code="\$(LEC=\$? ; if [[ \$LEC -ne 0 ]]; then echo -n '\[\e[0;91m\]'; else echo -n '\[\e[0m\]'; fi ; printf \"%3d\" \$LEC)"
PS1="[\[\033[0;32m\]\A \[\033[0;31m\]\u\[\033[0;34m\] \[\033[00;36m\]\W\[\033[0;33m\]\[\e[0m\]] "

export HISTTIMEFORMAT='%F %T '
