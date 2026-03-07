#!/usr/bin/env pwsh
# Copy Chroma.qmod and NoodleExtensions.qmod to releases/<version>/ and keep only .qmod in that folder.
# Run from repo root after build-all.ps1 and createqmod-all.ps1.
# Usage: pwsh ./scripts/copy-qmods-to-releases.ps1 [1407|1408]
$ErrorActionPreference = "Stop"
$root = Resolve-Path (Join-Path $PSScriptRoot "..")

$version = $args[0]
if (-not $version -or $version -notmatch '^140[78]$') {
    Write-Host "Usage: pwsh ./scripts/copy-qmods-to-releases.ps1 1407|1408"
    Write-Host "  Copies Chroma.qmod and NoodleExtensions.qmod to releases/<version>/ and removes .so from that folder."
    exit 1
}

$releaseDir = Join-Path $root "releases" $version
$chromaQmod = Join-Path $root "chroma" "Chroma.qmod"
$noodleQmod = Join-Path $root "noodleextensions" "NoodleExtensions.qmod"

if (-not (Test-Path $chromaQmod)) {
    Write-Error "Chroma.qmod not found. Run build and createqmod from chroma/ first (e.g. pwsh ./scripts/build-all.ps1; pwsh ./scripts/createqmod-all.ps1)."
    exit 1
}
if (-not (Test-Path $noodleQmod)) {
    Write-Error "NoodleExtensions.qmod not found. Run build and createqmod from noodleextensions/ first."
    exit 1
}

if (-not (Test-Path $releaseDir)) {
    New-Item -ItemType Directory -Path $releaseDir -Force | Out-Null
}

# Remove any .so from the release folder so it contains only .qmod
Get-ChildItem -Path $releaseDir -Filter "*.so" -ErrorAction SilentlyContinue | Remove-Item -Force
Copy-Item -Path $chromaQmod -Destination $releaseDir -Force
Copy-Item -Path $noodleQmod -Destination $releaseDir -Force

Write-Host "Copied to $releaseDir :"
Write-Host "  Chroma.qmod"
Write-Host "  NoodleExtensions.qmod"
Get-ChildItem $releaseDir | ForEach-Object { Write-Host "  $($_.Name)" }
