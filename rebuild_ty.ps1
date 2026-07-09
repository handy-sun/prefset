$ErrorActionPreference = "Stop"

Import-Module "C:\Program Files (x86)\Microsoft Visual Studio\2019\Community\Common7\Tools\Microsoft.VisualStudio.DevShell.dll"
Enter-VsDevShell -VsInstallPath "C:\Program Files (x86)\Microsoft Visual Studio\2019\Community" -SkipAutomaticLocation -DevCmdArguments "-arch=x86 -host_arch=x64"

where.exe cl

$env:MSBUILDDISABLENODEREUSE = "1"
$msbuild = "C:\Program Files (x86)\Microsoft Visual Studio\2019\Community\MSBuild\Current\Bin\MSBuild.exe"
& $msbuild "D:\tzw\vpn-client-qt\VPNClient_NEW\VPNClient_NEW.sln" /t:Rebuild /p:Configuration=Release /p:Platform=x86 /m:1 /nr:false
exit $LASTEXITCODE
