<#
.SYNOPSIS
Builds a Visual Studio solution without relying on machine-specific paths.

.DESCRIPTION
Configuration precedence is: command-line parameter, TY_* environment variable,
then automatic discovery. If SolutionPath is omitted, the script searches the
current Git repository (or the current directory) and requires exactly one .sln.

Supported environment variables:
  TY_SOLUTION_PATH, TY_PROJECT_ROOT, TY_VS_INSTALL_PATH, TY_MSBUILD_PATH,
  TY_BUILD_CONFIGURATION, TY_BUILD_PLATFORM, TY_VS_ARCH, TY_VS_HOST_ARCH,
  TY_MAX_CPU_COUNT
#>
[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [ValidateSet("Build", "Rebuild")]
    [string] $Target = "Build",

    [string] $SolutionPath = $env:TY_SOLUTION_PATH,
    [string] $ProjectRoot = $env:TY_PROJECT_ROOT,
    [string] $VsInstallPath = $env:TY_VS_INSTALL_PATH,
    [string] $MsBuildPath = $env:TY_MSBUILD_PATH,
    [string] $Configuration = $env:TY_BUILD_CONFIGURATION,
    [string] $Platform = $env:TY_BUILD_PLATFORM,
    [string] $Architecture = $env:TY_VS_ARCH,
    [string] $HostArchitecture = $env:TY_VS_HOST_ARCH,

    [ValidateRange(-1, 1024)]
    [int] $MaxCpuCount = -1,

    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]] $MsBuildArguments
)

$ErrorActionPreference = "Stop"

function Resolve-ExistingFile {
    param(
        [Parameter(Mandatory = $true)]
        [string] $Path,
        [Parameter(Mandatory = $true)]
        [string] $Description
    )

    $resolved = Resolve-Path -LiteralPath $Path -ErrorAction SilentlyContinue
    if (-not $resolved -or -not (Test-Path -LiteralPath $resolved.Path -PathType Leaf)) {
        throw "$Description not found: $Path"
    }

    return $resolved.Path
}

function Resolve-Solution {
    param(
        [string] $RequestedPath,
        [string] $RequestedRoot
    )

    if (-not [string]::IsNullOrWhiteSpace($RequestedPath)) {
        return Resolve-ExistingFile -Path $RequestedPath -Description "Solution"
    }

    if (-not [string]::IsNullOrWhiteSpace($RequestedRoot)) {
        $root = (Resolve-Path -LiteralPath $RequestedRoot).Path
    }
    else {
        $root = (Get-Location).Path
        $git = Get-Command git -ErrorAction SilentlyContinue
        if ($git) {
            $gitRoot = & $git.Source rev-parse --show-toplevel 2>$null
            if ($LASTEXITCODE -eq 0 -and $gitRoot) {
                $root = $gitRoot.Trim()
            }
        }
    }

    $solutions = @(Get-ChildItem -LiteralPath $root -Filter "*.sln" -File -Recurse -ErrorAction SilentlyContinue)
    if ($solutions.Count -eq 0) {
        throw "No .sln file found under '$root'. Pass -SolutionPath or set TY_SOLUTION_PATH."
    }
    if ($solutions.Count -gt 1) {
        $paths = ($solutions.FullName | ForEach-Object { "  $_" }) -join [Environment]::NewLine
        throw "Multiple .sln files found under '$root'. Pass -SolutionPath or set TY_SOLUTION_PATH:$([Environment]::NewLine)$paths"
    }

    return $solutions[0].FullName
}

function Find-VsInstallPath {
    $vsWhere = Get-Command vswhere.exe -ErrorAction SilentlyContinue
    if (-not $vsWhere) {
        $programFilesX86 = ${env:ProgramFiles(x86)}
        if ($programFilesX86) {
            $defaultVsWhere = Join-Path $programFilesX86 "Microsoft Visual Studio\Installer\vswhere.exe"
            if (Test-Path -LiteralPath $defaultVsWhere -PathType Leaf) {
                $vsWhere = Get-Item -LiteralPath $defaultVsWhere
            }
        }
    }

    if (-not $vsWhere) {
        throw "Visual Studio could not be discovered because vswhere.exe is unavailable. Set TY_VS_INSTALL_PATH."
    }

    $installPath = & $vsWhere.FullName -latest -products * `
        -requires Microsoft.Component.MSBuild Microsoft.VisualStudio.Component.VC.Tools.x86.x64 `
        -property installationPath
    if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($installPath)) {
        throw "No Visual Studio installation with MSBuild and the C++ toolchain was found. Set TY_VS_INSTALL_PATH."
    }

    return $installPath.Trim()
}

function Get-TargetArchitecture {
    param([string] $BuildPlatform)

    switch -Regex ($BuildPlatform) {
        "^(x86|Win32)$" { return "x86" }
        "^(x64|amd64)$" { return "x64" }
        "^arm64$" { return "arm64" }
        default { return $BuildPlatform }
    }
}

function Get-HostArchitecture {
    switch -Regex ($env:PROCESSOR_ARCHITECTURE) {
        "^(AMD64|x64)$" { return "x64" }
        "^(x86|X86)$" { return "x86" }
        "^ARM64$" { return "arm64" }
        default { return "x64" }
    }
}

if ([string]::IsNullOrWhiteSpace($Configuration)) {
    $Configuration = "Release"
}
if ([string]::IsNullOrWhiteSpace($Platform)) {
    $Platform = "x86"
}
if ([string]::IsNullOrWhiteSpace($Architecture)) {
    $Architecture = Get-TargetArchitecture -BuildPlatform $Platform
}
if ([string]::IsNullOrWhiteSpace($HostArchitecture)) {
    $HostArchitecture = Get-HostArchitecture
}
if ($MaxCpuCount -eq -1) {
    if (-not [string]::IsNullOrWhiteSpace($env:TY_MAX_CPU_COUNT)) {
        $parsedCpuCount = 0
        if (-not [int]::TryParse($env:TY_MAX_CPU_COUNT, [ref] $parsedCpuCount) -or $parsedCpuCount -lt 0) {
            throw "TY_MAX_CPU_COUNT must be a non-negative integer."
        }
        $MaxCpuCount = $parsedCpuCount
    }
    elseif ($Target -eq "Rebuild") {
        $MaxCpuCount = 1
    }
    else {
        $MaxCpuCount = 0
    }
}

$solution = Resolve-Solution -RequestedPath $SolutionPath -RequestedRoot $ProjectRoot

$msBuildCommand = Get-Command msbuild.exe -ErrorAction SilentlyContinue
$clCommand = Get-Command cl.exe -ErrorAction SilentlyContinue
$needsDevShell = -not $msBuildCommand -or -not $clCommand

if (-not [string]::IsNullOrWhiteSpace($VsInstallPath)) {
    $VsInstallPath = (Resolve-Path -LiteralPath $VsInstallPath).Path
    $needsDevShell = $true
}
elseif ($needsDevShell) {
    if (-not [string]::IsNullOrWhiteSpace($env:VSINSTALLDIR)) {
        $VsInstallPath = $env:VSINSTALLDIR
    }
    else {
        $VsInstallPath = Find-VsInstallPath
    }
}

if ($needsDevShell) {
    $devShellModule = Join-Path $VsInstallPath "Common7\Tools\Microsoft.VisualStudio.DevShell.dll"
    if (-not (Test-Path -LiteralPath $devShellModule -PathType Leaf)) {
        throw "Visual Studio developer shell module not found: $devShellModule"
    }

    Import-Module $devShellModule
    $requestedWhatIf = $WhatIfPreference
    try {
        $WhatIfPreference = $false
        Enter-VsDevShell -VsInstallPath $VsInstallPath -SkipAutomaticLocation `
            -DevCmdArguments "-arch=$Architecture -host_arch=$HostArchitecture"
    }
    finally {
        $WhatIfPreference = $requestedWhatIf
    }
}

if (-not [string]::IsNullOrWhiteSpace($MsBuildPath)) {
    $msbuild = Resolve-ExistingFile -Path $MsBuildPath -Description "MSBuild"
}
else {
    $msBuildCommand = Get-Command msbuild.exe -ErrorAction SilentlyContinue
    if (-not $msBuildCommand) {
        throw "MSBuild is unavailable after initializing the Visual Studio environment. Set TY_MSBUILD_PATH."
    }
    $msbuild = $msBuildCommand.Source
}

if (-not (Get-Command cl.exe -ErrorAction SilentlyContinue)) {
    throw "The Visual C++ compiler is unavailable after initializing the Visual Studio environment."
}

$arguments = @(
    $solution
    "/t:$Target"
    "/p:Configuration=$Configuration"
    "/p:Platform=$Platform"
    "/nr:false"
)
if ($MaxCpuCount -eq 0) {
    $arguments += "/m"
}
else {
    $arguments += "/m:$MaxCpuCount"
}
if ($MsBuildArguments) {
    $arguments += $MsBuildArguments
}

Write-Host "Solution:      $solution"
Write-Host "Visual Studio: $VsInstallPath"
Write-Host "MSBuild:       $msbuild"
Write-Host "Build:         $Target | $Configuration | $Platform | max CPU: $MaxCpuCount"

if (-not $PSCmdlet.ShouldProcess($solution, "$Target with MSBuild")) {
    exit 0
}

$previousNodeReuse = $env:MSBUILDDISABLENODEREUSE
try {
    $env:MSBUILDDISABLENODEREUSE = "1"
    & $msbuild @arguments
    $buildExitCode = $LASTEXITCODE
}
finally {
    if ($null -eq $previousNodeReuse) {
        Remove-Item Env:MSBUILDDISABLENODEREUSE -ErrorAction SilentlyContinue
    }
    else {
        $env:MSBUILDDISABLENODEREUSE = $previousNodeReuse
    }
}

exit $buildExitCode
