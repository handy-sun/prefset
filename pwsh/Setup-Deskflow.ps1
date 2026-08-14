$path = "$env:ProgramData\Deskflow"

New-Item -ItemType Directory -Path "$path\tls" -Force

icacls $path /inheritance:r
icacls $path /grant:r `
  '*S-1-5-18:(OI)(CI)F' `
  '*S-1-5-32-544:(OI)(CI)F' `
  "$($env:USERDOMAIN)\$($env:USERNAME):(OI)(CI)M"

Restart-Service Deskflow
## WARN: Modify this installed path as u need
Start-Process 'D:\Software\Deskflow\deskflow.exe'

