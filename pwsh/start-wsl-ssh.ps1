$ErrorActionPreference = 'Stop'
$wsl = Join-Path $env:WINDIR 'System32\wsl.exe'
$netsh = Join-Path $env:WINDIR 'System32\netsh.exe'
& $wsl -d ubt22 --exec /bin/true | Out-Null
Start-Sleep -Seconds 2
$ip = ((& $wsl -d ubt22 -- hostname -I) -split '\s+' | Where-Object { $_ -match '^\d+\.\d+\.\d+\.\d+$' } | Select-Object -First 1)
if (-not $ip) { throw 'Unable to determine ubt22 IPv4 address.' }
& $netsh interface portproxy delete v4tov4 listenport=2222 listenaddress=0.0.0.0 | Out-Null
& $netsh interface portproxy add v4tov4 listenport=2222 listenaddress=0.0.0.0 connectport=22 connectaddress=$ip | Out-Null
