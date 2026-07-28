## Location: $PROFILE ($HOME\Documents\PowerShell\Microsoft.PowerShell_profile.ps1)
## To apply profile's change, use command:. $PROFILE

# Fix external command (git etc.) UTF-8 output garbled in PowerShell pipeline
[Console]::OutputEncoding = [Text.Encoding]::UTF8
[Console]::InputEncoding = [Text.Encoding]::UTF8

Import-Module PSReadLine
## Donnot need to import it
# Import-Module posh-git

## use theme powerlevel10k_lean, donnot use command: Import-Module oh-my-posh
oh-my-posh init pwsh --config "$env:POSH_THEMES_PATH/powerlevel10k_lean.omp.json" | Invoke-Expression

## ------------------------------- Set Hot-keys BEGIN -------------------------------
# 设置预测文本来源为历史记录
Set-PSReadLineOption -PredictionSource History
# 设置预测文本的颜色
Set-PSReadLineOption -Colors @{
    InlinePrediction = '87afaf'
}
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
# Set-Location "$HOME"
Set-PSReadLineOption -AddToHistoryHandler {
    param($line)
    # 如果命令以空格开头，则不记录到历史
    if ($line.StartsWith(' ')) {
        return $false
    }
    return $true
}

## ------------------------------- append into $env:path -------------------------------

# Current Date and Time (UTC - YYYY-MM-DD HH:MM:SS formatted): 2025-02-14 22:36:20 +8:00
function JudgeAndAddToPath {
    param (
        [string]$DirectoryPath
    )

    # 检查 DirectoryPath 是否为空
    if ([string]::IsNullOrEmpty($DirectoryPath)) {
        Write-Warning "DirectoryPath is null or empty. No action taken."
        return
    }

    # 确保目录存在
    if (!(Test-Path -Path $DirectoryPath -PathType Container)) {
        Write-Warning "Directory '$DirectoryPath' does not exist. No action taken."
        return
    }

    # 检查 DirectoryPath 是否已在 Path 中
    $pathEntries = $env:Path -split ";"
    if (!($pathEntries -contains $DirectoryPath)) {
        $env:Path = "$($env:Path);$DirectoryPath"
        # Write-Host "Added '$DirectoryPath' to the Path environment variable."
    }
    # else {
    #     Write-Host "Directory '$DirectoryPath' is already in the Path environment variable."
    # }
}

JudgeAndAddToPath -DirectoryPath "$HOME\.local\bin"

## ---------------
# $baseDirectory = "$HOME\.dotnet\tools"

# $subdirectories = Get-ChildItem -Path $baseDirectory -Directory
# foreach ($subdir in $subdirectories) {
#     JudgeAndAddToPath -DirectoryPath $subdir
# }

Invoke-Expression (& { (zoxide init powershell | Out-String) })
## Python 直接执行
# $env:PATHEXT += ";.py"

# Generated from common.sh.in git/fd/rg aliases for PowerShell.
# Written for PowerShell 7, with syntax kept compatible with Windows PowerShell 1.0 where practical.

function gta { & git status @args }
function gtun { & git status uno @args }

function gad { & git add -v @args }
function gcm { & git commit @args }
function gcmm { & git commit -m @args }
function gcma { & git commit -a @args }
function gcmam { & git commit -a -m @args }
function gcmn { & git commit --amend @args }
function gcman { & git commit -a --amend @args }

function gpl { & git pull @args }
function gplrb { & git pull --rebase @args }

function gsh { & git stash @args }
function gshl { & git stash list @args }
function gshp { & git stash pop @args }

function grs { & git reset @args }
function grsh { & git reset --hard @args }
function grss { & git reset --soft @args }
function gro { & git restore @args }
function grg { & git restore --staged @args }

function glg {
    & git log "--pretty=format:%Cred%h%Creset %Cgreen(%ad) %Creset%s %C(bold blue)<%an>%Creset%C(yellow)%d" "--date=format:%Y-%m-%d %H:%M" --abbrev-commit --color @args
}
function glp { glg --graph @args }
function glh { glp @args | Select-Object -First 30 }
function glsa {
    & git log "--pretty=format:%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset" "--date=format:%Y-%m-%d %H:%M" --abbrev-commit --graph --all @args
}

function gdf { & git diff @args }
function gdfh { & git diff HEAD @args }
function gdfc { & git diff --cached @args }
function gbr { & git branch @args }
function gba { & git branch -a -v @args }
function gtl { & git tag --list @args }
function gck { & git checkout @args }
function gblm { & git blame -L @args }
function gaprj { & git apply --reject @args }
function gchp { & git cherry-pick @args }
function gklrj { & git clone --recursive --jobs 8 @args }
function gcln { & git clean -n @args }
function gclfd { & git clean -fd @args }

function gpar {
    $branch = if ($args.Length -gt 0) { $args[0] } else { $null }
    git remote | ForEach-Object {
        if ($branch) {
            & git push $_ $branch
        }
        else {
            & git push $_
        }
    }
}

function gts {
    $dir = if ($args.Length -gt 0 -and $args[0]) { $args[0] } else { "." }
    & git -C $dir status -s
}

function grt {
    $workDir = if ($args.Length -gt 0 -and $args[0]) { $args[0] } else { "." }
    & git -C $workDir remote -v
}

function gbc {
    if ($args.Length -lt 1 -or -not $args[0]) {
        Write-Error "Usage: gbc <branch>"
        return
    }

    & git branch $args[0]
    if ($LASTEXITCODE -eq 0) {
        & git checkout $args[0]
    }
}

function Get-GitRootDir {
    $rootDir = & git rev-parse --show-toplevel 2>$null
    if ($LASTEXITCODE -ne 0) {
        Write-Error 'fatal: not a git repository (or any of the parent directories): .git'
        return
    }

    return $rootDir
}

function gaa {
    if ($args.Count -gt 0) {
        Write-Error 'gaa does not accept any arguments.'
        return
    }

    $rootDir = Get-GitRootDir
    if (-not $rootDir) {
        return
    }

    & git -C $rootDir add . -v
}

function groa {
    $rootDir = Get-GitRootDir
    if (-not $rootDir) {
        return
    }

    & git -C $rootDir restore . @args
}

function grga {
    $rootDir = Get-GitRootDir
    if (-not $rootDir) {
        return
    }

    & git -C $rootDir restore --staged . @args
}

function prenv {
    if ($args.Length -eq 0) {
        Write-Output "Show All EnvironmentVariable:"
        Get-ChildItem Env:
        return
    }

    $varName = $args[0]
    $envVar = Get-ChildItem Env:$varName -ErrorAction SilentlyContinue

    if ($envVar) {
        $envVar
    } else {
        Write-Warning "EnvironmentVariable '$varName' not exists."
    }
}


function pathl {
    $env:PATH -replace ';', "`n"
}

function Update-SessionPath {
    $machinePath = [Environment]::GetEnvironmentVariable('PATH', 'Machine')
    $userPath = [Environment]::GetEnvironmentVariable('PATH', 'User')

    if ([string]::IsNullOrEmpty($machinePath)) {
        $env:PATH = $userPath
    }
    elseif ([string]::IsNullOrEmpty($userPath)) {
        $env:PATH = $machinePath
    }
    else {
        $env:PATH = $machinePath + ';' + $userPath
    }
}

function getproxy {
    Get-itemPropertyValue -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings" -Name ProxyEnable,ProxyServer
}

function set_proxy {
    set-itemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings" -Name ProxyEnable -Value 1
}
function unset_proxy {
    set-itemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings" -Name ProxyEnable -Value 0
}

function rlip4 {
    if (Get-Command Get-NetIPAddress -ErrorAction SilentlyContinue) {
        Get-NetIPAddress -AddressFamily IPv4 | Select-Object -ExpandProperty IPAddress
    }
    else {
        Get-WmiObject Win32_NetworkAdapterConfiguration | Where-Object { $_.IPEnabled } | ForEach-Object { $_.IPAddress } | Where-Object { $_ -match '^[0-9]+\.' }
    }
}

function rrm {
    if ($args.Length -eq 0) {
        Write-Error "Usage: rrm <path> [<path>...]"
        return
    }

    foreach ($path in $args) {
        if (-not (Test-Path -LiteralPath $path)) {
            Write-Error "Path not found: $path"
            continue
        }

        Remove-Item -LiteralPath $path -Recurse -Force
    }
}

function ll {
    & eza --group-directories-first -A -blg --git @args
}

function sha256sum {
    Get-FileHash @args -Algorithm SHA256
}

function md5sum {
    Get-FileHash @args -Algorithm MD5
}

$sbSubs = "http://fngo.local:3001/c53248f264d9997/download/collection/main?target=URI"
$sbPolicy = "@🌐Proxy@⚡UrlTest-~^(?!.*(kooya)).*$@💬AI$@🚀LowLatency"

function genWinTunSb {
    node D:\handy\sbtpl\node\base.js -s $sbSubs -p $sbPolicy --tun --icmp --windows -o ~\.config\sbroot\config.json
}

function genWinSb {
    node D:\handy\sbtpl\node\base.js -s $sbSubs -p $sbPolicy --icmp --windows -o ~\.config\sbroot\config.json
}
# try { $null = gcm pshazz -ea stop; pshazz init 'default' } catch { }
