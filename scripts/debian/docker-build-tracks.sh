#!/usr/bin/env bash
# Build libtracks.so for BS 1.40.8 entirely inside Docker.
# Requires only Docker on the host (no Rust, QPM, CMake, Ninja, NDK install needed).
#
# On macOS Apple Silicon: images must be linux/amd64 (NDK x86_64 toolchain only).
# The script handles --platform automatically.
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
BASE_IMAGE="${HECK_QUEST_IMAGE:-heck-quest-build}"
TRACKS_IMAGE="${HECK_QUEST_TRACKS_IMAGE:-heck-quest-tracks-build}"
PLATFORM="linux/amd64"

echo "=== Heck Quest Tracks Docker build (BS 1.40.8) ==="
echo "Repo root:    $ROOT"
echo "Base image:   $BASE_IMAGE"
echo "Tracks image: $TRACKS_IMAGE"
echo ""

# ── 1. Ensure base image (heck-quest-build) exists ──────────────────────────
if ! docker image inspect "$BASE_IMAGE" &>/dev/null; then
    echo ">>> Base image '$BASE_IMAGE' not found — building it first..."
    docker build --platform "$PLATFORM" -t "$BASE_IMAGE" -f "$ROOT/Dockerfile" "$ROOT"
fi

# ── 2. Build the Rust-enabled tracks image ───────────────────────────────────
echo ">>> Building '$TRACKS_IMAGE' (Rust nightly + cargo-ndk)..."
docker build --platform "$PLATFORM" -t "$TRACKS_IMAGE" -f "$ROOT/Dockerfile.tracks" "$ROOT"

# ── 3. QPM cache mount: extern/libs has symlinks into host QPM cache; mount it at same path ──
if [ -d "${HOME}/Library/Application Support/QPM-RS" ]; then
  HOST_QPM="${HOME}/Library/Application Support/QPM-RS"
elif [ -d "${HOME}/.local/share/QPM-RS" ]; then
  HOST_QPM="${HOME}/.local/share/QPM-RS"
else
  HOST_QPM=""
fi
if [ -z "$HOST_QPM" ]; then
  echo ">>> No QPM cache found at ~/Library/Application Support/QPM-RS or ~/.local/share/QPM-RS."
  echo "    Restore creates symlinks there; Docker needs it mounted so they resolve."
  exit 1
fi

# ── 4. Run the full tracks build ──────────────────────────────────────────────
echo ""
echo ">>> Running tracks build inside container..."
# ── 4. Run the full tracks build ──────────────────────────────────────────────
# Tracks restore must be run on the host first (qpm-rust uses qpackages.com and requires
# a patched registry for CJD 0.24.3 + bs-cordl 4008). Docker only runs Rust + CMake.
if [ ! -f "$ROOT/local_deps/tracks/extern.cmake" ] && [ ! -f "$ROOT/local_deps/tracks/qpm.lock" ]; then
  echo ">>> Tracks restore not done. Run on the host (with patched QPM registry for 1.40.8):"
  echo "    cd $ROOT/local_deps/tracks && qpm-rust restore"
  echo ""
  echo "Then run this script again."
  exit 1
fi

echo ""
echo ">>> Running tracks build (Rust + CMake) inside container..."
docker run --rm \
  --platform "$PLATFORM" \
  -v "$ROOT:/src" \
  -v "$HOST_QPM:$HOST_QPM" \
  -w /src/local_deps/tracks \
  -e ANDROID_NDK_HOME=/opt/android-ndk \
  "$TRACKS_IMAGE" \
  bash -c '
    set -e

    echo "--- Build tracks_rs_link (Rust nightly → aarch64-linux-android staticlib) ---"
    cd tracks_rs_link
    cargo ndk -t arm64-v8a build --release
    cd ..

    echo ""
    echo "--- CMake configure ---"
    cmake -B ./build -G "Ninja" -DCMAKE_BUILD_TYPE="RelWithDebInfo" .

    echo ""
    echo "--- Ninja build ---"
    cmake --build ./build

    echo ""
    echo "--- Artifact (for Chroma/NE 1.40.8 builds: copy to chroma/extern/libs and noodleextensions/extern/libs before createqmod) ---"
    echo "  /src/local_deps/tracks/build/libtracks.so"
    ls -lh /src/local_deps/tracks/build/libtracks.so
  '

echo ""
echo "Build complete. libtracks.so: $ROOT/local_deps/tracks/build/libtracks.so"
echo "For 1.40.8 release: copy that .so to chroma/extern/libs and noodleextensions/extern/libs, then build and run copy-qmods-to-releases.ps1 1408."
