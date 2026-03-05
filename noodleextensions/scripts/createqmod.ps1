#!/usr/bin/env pwsh
# Creates NoodleExtensions.qmod from mod.json and build/libnoodleextensions.so. Run from noodleextensions/ directory.
$ErrorActionPreference = "Stop"
$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$projectRoot = Resolve-Path "$scriptRoot/.."

Push-Location $projectRoot
try {
    $qpm = Get-Command qpm-rust -ErrorAction SilentlyContinue
    if (-not $qpm) { $qpm = Get-Command qpm -ErrorAction SilentlyContinue }
    if ($qpm) {
        & $qpm.Name qmod manifest
        if ($LASTEXITCODE -ne 0) { Write-Warning "qmod manifest failed." }
    }

    $modJson = Join-Path $projectRoot "mod.json"
    $buildDir = Join-Path $projectRoot "build"
    $externLibs = Join-Path $projectRoot "extern/libs"
    if (-not (Test-Path $modJson)) {
        Write-Error "mod.json not found. Run 'qpm-rust restore' and 'qpm-rust qmod manifest' from noodleextensions/ first."
        exit 1
    }

    $qmodName = "NoodleExtensions.qmod"
    $qmodPath = Join-Path $projectRoot $qmodName
    $soFile = Join-Path $buildDir "libnoodleextensions.so"
    if (-not (Test-Path $soFile)) {
        Write-Error "Build output not found: $soFile. Run build from noodleextensions/ first."
        exit 1
    }

    $tempDir = Join-Path $projectRoot "qmod_temp"
    if (Test-Path $tempDir) { Remove-Item $tempDir -Recurse -Force }
    New-Item -ItemType Directory -Path $tempDir -Force | Out-Null
    Copy-Item $modJson $tempDir
    Copy-Item $soFile $tempDir
    if (Test-Path $externLibs) { Get-ChildItem $externLibs -Filter "*.so" | ForEach-Object { Copy-Item $_.FullName $tempDir } }
    if (Test-Path $qmodPath) { Remove-Item $qmodPath -Force }
    Compress-Archive -Path "$tempDir/*" -DestinationPath $qmodPath -CompressionLevel Optimal
    Remove-Item $tempDir -Recurse -Force
    Write-Host "Created: $qmodPath"
} finally { Pop-Location }
