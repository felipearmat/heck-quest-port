# Thin wrapper to keep backward compatibility with the previous location.
# Delegates to the Windows-specific script under scripts/windows/.
$ErrorActionPreference = "Stop"
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
& (Join-Path $scriptDir "windows/docker-build.ps1") @args
