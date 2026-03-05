#!/usr/bin/env pwsh
# Build Noodle Extensions for Quest 1.40.7 from the noodleextensions/ subproject (code from bsq-ports, port of Aeroluna/NoodleExtensions).
$ErrorActionPreference = "Stop"
$root = Resolve-Path (Join-Path $PSScriptRoot "..")
$neDir = Join-Path $root "noodleextensions"
if (-not (Test-Path $neDir)) {
    Write-Error "noodleextensions/ not found. Ensure bsq-ports NoodleExtensions code is in heck-quest-port/noodleextensions/."
    exit 1
}
Push-Location $neDir
try {
    if (-not (Test-Path "extern") -or -not (Test-Path "qpm_defines.cmake")) {
        Write-Host "Restoring Noodle Extensions dependencies (qpm-rust restore)..."
        & qpm-rust restore
        if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
    }
    & pwsh ./scripts/build.ps1 -release
    $exit = $LASTEXITCODE
    if ($exit -eq 0) {
        Write-Host "Noodle Extensions build succeeded. Create NoodleExtensions.qmod with: pwsh ./scripts/createqmod.ps1 (from noodleextensions/)."
    }
    exit $exit
} finally {
    Pop-Location
}
