# Build Chroma and Noodle Extensions for Quest 1.40.7 entirely inside Docker.
# Requires only Docker on the host (no qpm-rust, CMake, Ninja, or NDK install).
# On macOS Apple Silicon: build the image with --platform linux/amd64 (see SETUP.md).
$ErrorActionPreference = "Stop"
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$root = Resolve-Path (Join-Path $scriptDir ".." "..")
$imageName = if ($env:HECK_QUEST_IMAGE) { $env:HECK_QUEST_IMAGE } else { "heck-quest-build" }

Write-Host "=== Heck Quest Docker build (Chroma + NoodleExtensions) ==="
Write-Host "Repo root: $root"
Write-Host "Image: $imageName"
Write-Host ""

# Single-line command for bash -c (avoids quoting issues on Windows)
$bashCmd = 'set -e; echo "=== Restore + Build Chroma ==="; cd /src/chroma && qpm-rust restore && pwsh -NoProfile -Command "./scripts/build.ps1 -release" && pwsh -NoProfile -Command "./scripts/createqmod.ps1" && echo "" && echo "=== Restore + Build Noodle Extensions ===" && cd /src/noodleextensions && qpm-rust restore && pwsh -NoProfile -Command "./scripts/build.ps1 -release" && pwsh -NoProfile -Command "./scripts/createqmod.ps1" && echo "" && echo "Done. Chroma.qmod and NoodleExtensions.qmod in chroma/ and noodleextensions/."'

docker run --rm `
  -v "${root}:/src" `
  -w /src `
  -e ANDROID_NDK_HOME=/opt/android-ndk `
  $imageName `
  bash -c $bashCmd

Write-Host ""
Write-Host "Artifacts on host:"
Write-Host "  $root/chroma/Chroma.qmod"
Write-Host "  $root/noodleextensions/NoodleExtensions.qmod"

