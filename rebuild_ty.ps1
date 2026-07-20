$buildScript = Join-Path $PSScriptRoot "build_ty.ps1"

if (-not (Test-Path -LiteralPath $buildScript -PathType Leaf)) {
    throw "Build script not found: $buildScript"
}

& $buildScript -Target Rebuild @args
exit $LASTEXITCODE
