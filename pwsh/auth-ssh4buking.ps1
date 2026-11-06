$key = 'ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMizFfVaUfb6gY10IXqG7dguFa3P5Z8OwLiU8n4Q+SvG qi@buking'

# 先看 cheer 是不是管理员（大概率是，Win11 首个账号默认在 Administrators）
whoami /groups | Select-String 'S-1-5-32-544'

if (whoami /groups | Select-String 'S-1-5-32-544') {
    # 管理员账号：必须写这个全局文件，用户目录里那个会被 Match 块忽略
    $p = "$env:ProgramData\ssh\administrators_authorized_keys"
    if (!(Test-Path $p)) { New-Item -ItemType File -Path $p -Force | Out-Null }
    Set-Content -Path $p -Value $key -Encoding ascii
    icacls $p /inheritance:r /grant "Administrators:F" /grant "SYSTEM:F"
} else {
    # 普通账号：写用户目录
    New-Item -ItemType Directory -Force "$env:USERPROFILE\.ssh" | Out-Null
    $p = "$env:USERPROFILE\.ssh\authorized_keys"
    Set-Content -Path $p -Value $key -Encoding ascii
    icacls $p /inheritance:r /grant "$env:USERNAME:F" /grant "SYSTEM:F"
}

# 确认 sshd 配置没关掉公钥认证
Select-String -Path "$env:ProgramData\ssh\sshd_config" `
    -Pattern 'PubkeyAuthentication|AuthorizedKeysFile|Match Group|administrators_authorized_keys'

Restart-Service sshd
Get-Service sshd
