#!/usr/bin/env pwsh
# Build Chroma for Quest 1.40.7 from the chroma/ subproject (code from bsq-ports, port of Aeroluna/Chroma).
$ErrorActionPreference = "Stop"
$root = Resolve-Path (Join-Path $PSScriptRoot "..")
$chromaDir = Join-Path $root "chroma"
if (-not (Test-Path $chromaDir)) {
    Write-Error "chroma/ not found. Ensure bsq-ports Chroma code is in heck-quest-port/chroma/."
    exit 1
}
Push-Location $chromaDir
try {
    if (-not (Test-Path "extern") -or -not (Test-Path "qpm_defines.cmake")) {
        Write-Host "Restoring Chroma dependencies (qpm-rust restore)..."
        & qpm-rust restore
        if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
    }
    & pwsh ./scripts/build.ps1 -release
    $exit = $LASTEXITCODE
    if ($exit -eq 0) {
        Write-Host "Chroma build succeeded. Create Chroma.qmod with: pwsh ./scripts/createqmod.ps1 (from chroma/)."
    }
    exit $exit
} finally {
    Pop-Location
}
