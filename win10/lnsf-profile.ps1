$repoRoot = git rev-parse --show-toplevel
$target = Join-Path $repoRoot "win10\Microsoft.PowerShell_profile.ps1"

New-Item -ItemType SymbolicLink `
  -Path $PROFILE.CurrentUserCurrentHost `
  -Target $target
