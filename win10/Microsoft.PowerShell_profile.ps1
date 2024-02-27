## Location: $PROFILE
## is equal to:
## $HOME\Documents\PowerShell\Microsoft.PowerShell_profile.ps1

## Install-Module -Name PSReadLine -AllowPrerelease -Scope AllUsers -Force -SkipPublisherCheck
Import-Module PSReadLine

## Install-Module -Name posh-git -Scope AllUsers -Force -SkipPublisherCheck -Verbose
Import-Module posh-git

# Set-ExecutionPolicy Bypass -Scope Process -Force; Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://ohmyposh.dev/install.ps1'))
# oh-my-posh font install
## donnot use: Import-Module oh-my-posh
## use theme powerlevel10k_lean
oh-my-posh init pwsh --config "$env:POSH_THEMES_PATH/powerlevel10k_lean.omp.json" | Invoke-Expression

## ------------------------------- Set Hot-keys BEGIN -------------------------------
# 设置预测文本来源为历史记录
Set-PSReadLineOption -PredictionSource History
# 每次回溯输入历史，光标定位于输入内容末尾
Set-PSReadLineOption -HistorySearchCursorMovesToEnd
# 设置 Tab 为菜单补全和 Intellisense
Set-PSReadLineKeyHandler -Key "Tab" -Function MenuComplete
# 设置 Ctrl+d 为退出 PowerShell
Set-PSReadlineKeyHandler -Key "Ctrl+d" -Function ViExit
# 设置 Ctrl+z 为撤销
Set-PSReadLineKeyHandler -Key "Ctrl+z" -Function Undo
# 设置向上键为后向搜索历史记录
Set-PSReadLineKeyHandler -Key UpArrow -Function HistorySearchBackward
# 设置向下键为前向搜索历史纪录
Set-PSReadLineKeyHandler -Key DownArrow -Function HistorySearchForward
## ------------------------------- Set Hot-keys END -------------------------------

# powershell start path
Set-Location "$HOME"

## ------------------------------- append into $env:path -------------------------------
# $env:Path = "$env:PATH;C:\Intel\"
# $env:Path += ";$HOME\AppData\Local\Programs\oh-my-posh\bin"

## Python 直接执行
# $env:PATHEXT += ";.py"

