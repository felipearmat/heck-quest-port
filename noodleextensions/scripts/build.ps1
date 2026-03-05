#!/usr/bin/env pwsh

Param(
    [Parameter(Mandatory=$false)]
    [Switch]$clean,
    [Parameter(Mandatory=$false)]
    [Switch]$release
)

# if user specified clean, remove all build files
if ($clean.IsPresent)
{
    if (Test-Path -Path "build")
    {
        remove-item build -R
    }
}

if (Test-Path "$PSScriptRoot/ndkpath.txt") {
    $NDKPath = (Get-Content "$PSScriptRoot/ndkpath.txt" -Raw).Trim()
} elseif (Test-Path "$PSScriptRoot/../../ndkpath.txt") {
    $NDKPath = (Get-Content "$PSScriptRoot/../../ndkpath.txt" -Raw).Trim()
} else {
    $NDKPath = $env:ANDROID_NDK_HOME
}
if (-not $NDKPath) {
    Write-Error "ANDROID_NDK_HOME not set and ndkpath.txt not found (noodleextensions/scripts/ or repo root)."
    exit 1
}
$env:ANDROID_NDK_HOME = $NDKPath
Write-Host "Using NDK Path: $NDKPath"

if (($clean.IsPresent) -or (-not (Test-Path -Path "build")))
{
    $out = new-item -Path build -ItemType Directory
}


# Set build type based on release flag
$buildType = if ($release.IsPresent) { "RelWithDebInfo" } else { "Debug" }

& cmake -B build -G "Ninja" -DCMAKE_BUILD_TYPE="$buildType" .
& cmake --build ./build 
exit $LASTEXITCODE