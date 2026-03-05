#!/usr/bin/env pwsh
# Build Chroma and Noodle Extensions for Quest 1.40.7.
# Heck = Chroma + NoodleExtensions (same idea as Aeroluna/Heck); no separate Heck.qmod.
$ErrorActionPreference = "Stop"
$root = Resolve-Path (Join-Path $PSScriptRoot "..")

Write-Host "=== Building Chroma ==="
& $PSScriptRoot/build-chroma.ps1
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

Write-Host "`n=== Building Noodle Extensions ==="
& $PSScriptRoot/build-noodleextensions.ps1
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

Write-Host "`n=== All builds completed. ==="
Write-Host "Chroma.qmod:        run from chroma/:         pwsh ./scripts/createqmod.ps1"
Write-Host "NoodleExtensions:   run from noodleextensions/: pwsh ./scripts/createqmod.ps1"
Write-Host "Or from repo root:  pwsh ./scripts/createqmod-all.ps1"
