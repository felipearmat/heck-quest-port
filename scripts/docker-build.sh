#!/usr/bin/env bash
# Build Chroma and Noodle Extensions for Quest 1.40.7 entirely inside Docker.
# Requires only Docker on the host (no qpm-rust, CMake, Ninja, or NDK install).
# On macOS Apple Silicon: build the image with --platform linux/amd64 (see SETUP.md).
set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
IMAGE_NAME="${HECK_QUEST_IMAGE:-heck-quest-build}"

echo "=== Heck Quest Docker build (Chroma + NoodleExtensions) ==="
echo "Repo root: $ROOT"
echo "Image: $IMAGE_NAME"
echo ""

docker run --rm \
  -v "$ROOT:/src" \
  -w /src \
  -e ANDROID_NDK_HOME=/opt/android-ndk \
  "$IMAGE_NAME" \
  bash -c '
    set -e
    echo "=== Restore + Build Chroma ==="
    cd /src/chroma
    qpm-rust restore
    pwsh -NoProfile -Command "./scripts/build.ps1 -release"
    pwsh -NoProfile -Command "./scripts/createqmod.ps1"

    echo ""
    echo "=== Restore + Build Noodle Extensions ==="
    cd /src/noodleextensions
    qpm-rust restore
    pwsh -NoProfile -Command "./scripts/build.ps1 -release"
    pwsh -NoProfile -Command "./scripts/createqmod.ps1"

    echo ""
    echo "=== Done ==="
    echo "Chroma.qmod:        /src/chroma/Chroma.qmod"
    echo "NoodleExtensions:   /src/noodleextensions/NoodleExtensions.qmod"
  '

echo ""
echo "Artifacts on host:"
echo "  $ROOT/chroma/Chroma.qmod"
echo "  $ROOT/noodleextensions/NoodleExtensions.qmod"
