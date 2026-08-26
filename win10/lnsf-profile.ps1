$repoRoot = git rev-parse --show-toplevel
$target = Join-Path $repoRoot "win10\Microsoft.PowerShell_profile.ps1"
Remove-Item -Force $PROFILE.CurrentUserCurrentHost

New-Item -ItemType SymbolicLink `
  -Path $PROFILE.CurrentUserCurrentHost `
  -Target $target
