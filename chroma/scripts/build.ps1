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

$NDKPath = $env:ANDROID_NDK_HOME
if (Test-Path "$PSScriptRoot/ndkpath.txt") {
    $NDKPath = (Get-Content "$PSScriptRoot/ndkpath.txt" -Raw).Trim()
} elseif (Test-Path "$PSScriptRoot/../../ndkpath.txt") {
    $NDKPath = (Get-Content "$PSScriptRoot/../../ndkpath.txt" -Raw).Trim()
}
if (-not $NDKPath) {
    Write-Error "ANDROID_NDK_HOME not set and ndkpath.txt not found (chroma/scripts/ or repo root)."
    exit 1
}
$env:ANDROID_NDK_HOME = $NDKPath

if (($clean.IsPresent) -or (-not (Test-Path -Path "build")))
{
    $out = new-item -Path build -ItemType Directory
}


# Set build type based on release flag
$buildType = if ($release.IsPresent) { "RelWithDebInfo" } else { "Debug" }

& cmake -B build -G "Ninja" -DCMAKE_BUILD_TYPE="$buildType" .
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
& cmake --build ./build
exit $LASTEXITCODE