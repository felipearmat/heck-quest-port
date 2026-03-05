#!/usr/bin/env pwsh
# Create Chroma.qmod and NoodleExtensions.qmod. Run from repo root after build-all.ps1.
# Heck does not produce a .qmod; it is the umbrella (Chroma + NoodleExtensions).
$ErrorActionPreference = "Stop"
$root = Resolve-Path (Join-Path $PSScriptRoot "..")

Write-Host "=== Creating Chroma.qmod ==="
Push-Location (Join-Path $root "chroma")
try { & pwsh ./scripts/createqmod.ps1 } finally { Pop-Location }
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

Write-Host "`n=== Creating NoodleExtensions.qmod ==="
Push-Location (Join-Path $root "noodleextensions")
try { & pwsh ./scripts/createqmod.ps1 } finally { Pop-Location }
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

Write-Host "`nDone. Qmods:"
Write-Host "  $root/chroma/Chroma.qmod"
Write-Host "  $root/noodleextensions/NoodleExtensions.qmod"
