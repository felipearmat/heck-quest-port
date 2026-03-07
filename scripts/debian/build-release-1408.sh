#!/usr/bin/env bash
# Full release build for Beat Saber 1.40.8: Tracks + Chroma + NoodleExtensions → releases/1408/*.qmod
# Prereqs:
#   - Branch upgrade/1.40.8-2.0.0 (or qpm.json with bs-cordl 4008).
#   - On host: cd local_deps/tracks && qpm-rust restore
#   - On host: cd chroma && qpm-rust restore; cd ../noodleextensions && qpm-rust restore
#     (with patched QPM registry for CJD 0.24.3 + tracks 2.4.4 for 1.40.8)
# Requires: Docker, host QPM cache mounted so extern/libs symlinks resolve.
set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
PLATFORM="linux/amd64"

if [ -d "${HOME}/Library/Application Support/QPM-RS" ]; then
  HOST_QPM="${HOME}/Library/Application Support/QPM-RS"
elif [ -d "${HOME}/.local/share/QPM-RS" ]; then
  HOST_QPM="${HOME}/.local/share/QPM-RS"
else
  echo "No QPM cache found. Need ~/Library/Application Support/QPM-RS or ~/.local/share/QPM-RS"
  exit 1
fi

echo "=== Release 1.40.8 build ==="
echo "Repo root: $ROOT"
echo ""

# ── 1. Build Tracks (Docker) ─────────────────────────────────────────────────
if [ ! -f "$ROOT/local_deps/tracks/extern.cmake" ]; then
  echo "Run first: cd $ROOT/local_deps/tracks && qpm-rust restore"
  exit 1
fi
echo ">>> Step 1: Build libtracks.so (Docker)..."
"$SCRIPT_DIR/docker-build-tracks.sh"
TRACKS_SO="$ROOT/local_deps/tracks/build/libtracks.so"
if [ ! -f "$TRACKS_SO" ]; then
  echo "Tracks build did not produce $TRACKS_SO"
  exit 1
fi

# ── 2. Copy libtracks.so into chroma and noodleextensions extern ─────────────
echo ""
echo ">>> Step 2: Copy libtracks.so to chroma and noodleextensions extern/libs..."
mkdir -p "$ROOT/chroma/extern/libs" "$ROOT/noodleextensions/extern/libs"
cp "$TRACKS_SO" "$ROOT/chroma/extern/libs/libtracks.so"
cp "$TRACKS_SO" "$ROOT/noodleextensions/extern/libs/libtracks.so"

# Require chroma/NE already restored on host (so extern has 1.40.8 deps and symlinks)
if [ ! -f "$ROOT/chroma/extern.cmake" ] || [ ! -f "$ROOT/noodleextensions/extern.cmake" ]; then
  echo "Run on host (with patched registry for 1.40.8):"
  echo "  cd $ROOT/chroma && qpm-rust restore"
  echo "  cd $ROOT/noodleextensions && qpm-rust restore"
  exit 1
fi

# Clean CMake build dirs so the container generates cache for /src (not host path)
echo ">>> Cleaning chroma/build and noodleextensions/build for Docker..."
rm -rf "$ROOT/chroma/build" "$ROOT/noodleextensions/build"

# ── 3. Build Chroma and NoodleExtensions in Docker (no restore; mount host QPM) ──
echo ""
echo ">>> Step 3: Build Chroma & NoodleExtensions + createqmod (Docker)..."
BASE_IMAGE="${HECK_QUEST_IMAGE:-heck-quest-build}"
if ! docker image inspect "$BASE_IMAGE" &>/dev/null; then
  echo "Building base image $BASE_IMAGE..."
  docker build --platform "$PLATFORM" -t "$BASE_IMAGE" -f "$ROOT/Dockerfile" "$ROOT"
fi

docker run --rm \
  --platform "$PLATFORM" \
  -v "$ROOT:/src" \
  -v "$HOST_QPM:$HOST_QPM" \
  -w /src \
  -e ANDROID_NDK_HOME=/opt/android-ndk \
  "$BASE_IMAGE" \
  bash -c '
    set -e
    echo "--- Use container NDK (/opt/android-ndk) ---"
    echo "/opt/android-ndk" > /src/chroma/ndkpath.txt
    echo "/opt/android-ndk" > /src/noodleextensions/ndkpath.txt
    echo "--- Overwrite extern/libs/libtracks.so with 1.40.8 build ---"
    cp /src/local_deps/tracks/build/libtracks.so /src/chroma/extern/libs/libtracks.so
    cp /src/local_deps/tracks/build/libtracks.so /src/noodleextensions/extern/libs/libtracks.so
    echo "--- Build Chroma ---"
    cd /src/chroma && pwsh -NoProfile -Command "./scripts/build.ps1 -release"
    echo "--- Build NoodleExtensions ---"
    cd /src/noodleextensions && pwsh -NoProfile -Command "./scripts/build.ps1 -release"
    echo "--- Create Chroma.qmod ---"
    cd /src/chroma && pwsh -NoProfile -Command "./scripts/createqmod.ps1"
    echo "--- Create NoodleExtensions.qmod ---"
    cd /src/noodleextensions && pwsh -NoProfile -Command "./scripts/createqmod.ps1"
    echo "--- Copy to releases/1408 ---"
    mkdir -p /src/releases/1408
    rm -f /src/releases/1408/*.so
    cp /src/chroma/Chroma.qmod /src/noodleextensions/NoodleExtensions.qmod /src/releases/1408/
    echo "Done. releases/1408: Chroma.qmod, NoodleExtensions.qmod"
  '

echo ""
echo "Release 1.40.8 build complete."
echo "  $ROOT/releases/1408/Chroma.qmod"
echo "  $ROOT/releases/1408/NoodleExtensions.qmod"
echo ""
echo "Note: If step 3 ran in Docker, chroma/ndkpath.txt and noodleextensions/ndkpath.txt"
echo "were set to /opt/android-ndk. For host builds, restore your NDK path in those files."
ls -la "$ROOT/releases/1408/"
