## Location: $PROFILE ($HOME\Documents\PowerShell\Microsoft.PowerShell_profile.ps1)

Import-Module PSReadLine
Import-Module posh-git

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
Set-Location "$HOME"

## ------------------------------- append into $env:path -------------------------------

# Current Date and Time (UTC - YYYY-MM-DD HH:MM:SS formatted): 2025-02-14 22:36:20 +8:00
function JudgeAndAddToPath {
    param (
        [string]$DirectoryPath
    )

    # 检查 DirectoryPath 是否为空
    if ([string]::IsNullOrEmpty($DirectoryPath)) {
        Write-Warning "DirectoryPath is null or empty.  No action taken."
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

JudgeAndAddToPath -DirectoryPath "$HOME\AppData\Local\Programs\Ollama"
JudgeAndAddToPath -DirectoryPath "C:\Program1\helix-dev"
## ---------------
$baseDirectory = "$HOME\.dotnet\tools"

$subdirectories = Get-ChildItem -Path $baseDirectory -Directory
foreach ($subdir in $subdirectories) {
    JudgeAndAddToPath -DirectoryPath $subdir
}

## Python 直接执行
# $env:PATHEXT += ";.py"
