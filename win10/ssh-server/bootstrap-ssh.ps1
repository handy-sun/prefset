## register serivce
$OpenSSH = scoop prefix openssh
Set-ExecutionPolicy -Scope Process Bypass -Force
& "$OpenSSH\install-sshd.ps1"

## start at power on
Set-Service sshd -StartupType Automatic
Start-Service sshd

## 放行 TCP 22，允许公用，专用和域网络
if (-not (Get-NetFirewallRule -Name "OpenSSH-Server-In-TCP-Scoop" -ErrorAction SilentlyContinue)) {
    New-NetFirewallRule `
    -Name "OpenSSH-Server-In-TCP-Scoop" `
    -DisplayName "OpenSSH Server (Scoop)" `
    -Direction Inbound `
    -Protocol TCP `
    -LocalPort 22 `
    -Action Allow `
    -Profile Public,Private,Domain
}
