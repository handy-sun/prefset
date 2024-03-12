if (!(Test-Path -Path $PROFILE)) {
    New-Item -ItemType File -Path $PROFILE -Force
}

Install-Module -Name PSReadLine -AllowPrerelease -Scope AllUsers -Force -SkipPublisherCheck -Verbose 

Install-Module -Name posh-git -Scope AllUsers -Force -SkipPublisherCheck -Verbose

# install/update
Set-ExecutionPolicy Bypass -Scope Process -Force; Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://ohmyposh.dev/install.ps1'))

# oh-my-posh font install
