# Development environment setup

This document describes how to set up the environment and tools needed to **develop** the Chroma and Noodle Extensions Quest mods and **test them during development** (build, push to device, run Beat Saber, view logs). Heck is the umbrella project (Chroma + NoodleExtensions); there is no separate Heck.qmod to build.

---

## 1. Tools required for development

| Tool | Purpose |
|------|--------|
| **CMake** 3.21+ | Configure the C++ projects |
| **Ninja** | Build system |
| **PowerShell** (Core 7+ recommended) | Run `build-all.ps1`, `createqmod-all.ps1`, and per-project scripts |
| **Android NDK** (r27, compatible with each project’s `qpm.json`) | Cross-compile for Quest (arm64-v8a) |
| **qpm-rust** | Restore dependencies and generate build files per project |
| **ADB** | Push built `.so` to the Quest and capture logcat (for testing) |
| **Docker** (optional) | Full build inside container — **minimal host install**; see Option B and Option C below |

---

## 2. Option A — Host setup (Windows / Linux / macOS)

### 2.1 Install CMake and Ninja

- **Windows:** Install [CMake](https://cmake.org/download/) and [Ninja](https://github.com/ninja-build/ninja/releases); add both to `PATH`.
- **Linux (Debian/Ubuntu):** `sudo apt install cmake ninja-build`
- **macOS:** `brew install cmake ninja`

### 2.2 Install Android NDK

- Download the NDK from [Android NDK](https://developer.android.com/ndk/downloads) (e.g. NDK 27.x, as required by Chroma/Noodle `qpm.json`).
- Extract to a permanent path.
- Either set **`ANDROID_NDK_HOME`** to that path, or create **`ndkpath.txt`** in the **repo root** with that path (one line). Chroma and Noodle build scripts will use the repo root `ndkpath.txt` if present.

### 2.3 Install qpm-rust

- **Prebuilt:** [QuestPackageManager-Rust](https://github.com/RedBrumbler/QuestPackageManager-Rust/releases), add to `PATH` as `qpm-rust`.
- **From source:** `cargo install qpm-rust`.

### 2.4 Install ADB (for testing on device)

- Install [Android SDK Platform-Tools](https://developer.android.com/studio/releases/platform-tools) or standalone ADB; add to `PATH`.
- Enable developer mode and USB debugging on the Quest; connect and run `adb devices`.

### 2.5 Restore project dependencies

Restore **each project** from the repo root:

```bash
cd chroma && qpm-rust restore && cd ..
cd noodleextensions && qpm-rust restore && cd ..
```

If you see cache errors:

```bash
qpm-rust cache legacy-fix
# then restore again in each project
```

### 2.6 Verify the development build

From the **repo root**:

```powershell
pwsh ./scripts/build-all.ps1
```

Or build one mod at a time:

```powershell
cd chroma && pwsh ./scripts/build.ps1 && cd ..
cd noodleextensions && pwsh ./scripts/build.ps1 && cd ..
```

Use `-release` for an optimized build. If both build successfully, the environment is ready.

---

## 3. Testing the mods during development

Build Chroma and/or Noodle (see 2.6), then push the desired `.so` to the Quest with ADB. Each project’s `build/` folder contains e.g. `libchroma.so` or `libnoodleextensions.so`. Copy them to the Beat Saber mod folder on the device (e.g. `Modloader/mods/`) and restart the game. Use `adb logcat` to inspect logs (filter by `Chroma`, `Noodle`, or the mod ID).

If a project provides a `copy.ps1` (or similar) in its `scripts/` folder, you can use that to build and push in one step from that project directory.

---

## 4. Option B — Docker setup for development

Use Docker for a reproducible build environment. Restore dependencies on the host (see 2.5); build inside the container.

### 4.1 Build the image

From the repo root (if a `Dockerfile` exists):

```bash
docker build -t heck-quest-build .
```

**On macOS with Apple Silicon (M1/M2/M3):** The Android NDK is only distributed for Linux x86_64. To run the NDK inside the container, build the image for the amd64 platform (emulation; slower but works):

```bash
docker build --platform linux/amd64 -t heck-quest-build .
```

### 4.2 Build inside the container

Mount the repo and run the build for each project. The image sets `ANDROID_NDK_HOME=/opt/android-ndk`:

```bash
docker run --rm -v "$(pwd):/src" -w /src/chroma -e ANDROID_NDK_HOME=/opt/android-ndk heck-quest-build \
  sh -c "qpm-rust restore && qpm-rust s build"
```

Repeat for `noodleextensions`. The built `.so` files will appear in `chroma/build/` and `noodleextensions/build/` on the host. Then use ADB on the host to push and test (see section 3).

---

## 5. Option C — Docker-only build (minimal host install)

If you want to **avoid installing** qpm-rust, CMake, Ninja, and the NDK on your machine, use the **all-in-Docker** flow. The Docker image includes qpm-rust, CMake, Ninja, NDK, and PowerShell.

**Host requirement:** Only **Docker** (and Git to clone the repo).

### 5.1 Build the image once

From the repo root:

```bash
docker build -t heck-quest-build .
```

**On macOS with Apple Silicon (ARM):** The NDK is Linux x86_64 only. Build the image for amd64 so the NDK runs correctly inside the container (Docker will use emulation):

```bash
docker build --platform linux/amd64 -t heck-quest-build .
```

### 5.2 Run the full build and create .qmods

From the repo root, run **one** of:

```bash
./scripts/docker-build.sh
```

or (PowerShell, e.g. on Windows):

```powershell
pwsh ./scripts/docker-build.ps1
```

This restores dependencies, builds Chroma and Noodle Extensions in release mode, and creates `Chroma.qmod` and `NoodleExtensions.qmod` inside the container. The artifacts are written to the mounted repo, so you get:

- `chroma/Chroma.qmod`
- `noodleextensions/NoodleExtensions.qmod`

on your host. No local qpm-rust, CMake, Ninja, or NDK needed.

### 5.3 macOS Apple Silicon (ARM) — summary

| Step | Command |
|------|--------|
| Build image | `docker build --platform linux/amd64 -t heck-quest-build .` |
| Run build | `./scripts/docker-build.sh` (or `pwsh ./scripts/docker-build.ps1`) |

The scripts do **not** auto-detect macOS ARM; you must build the image with `--platform linux/amd64` yourself. Running the container uses the same image, so no extra flags are needed when calling `docker-build.sh` / `docker-build.ps1`. Builds may be slower due to emulation.

---

## 6. Troubleshooting

- **`qpm_defines.cmake` or `extern.cmake` not found**  
  Run `qpm-rust restore` inside the project directory (`chroma/` or `noodleextensions/`).

- **NDK not found**  
  Set `ANDROID_NDK_HOME` or create `ndkpath.txt` in the **repo root** (or in the project’s `scripts/` folder) with the NDK path on a single line.

- **Link or compile errors**  
  Use bs-cordl 4007.\* for Beat Saber 1.40.7. Run `qpm-rust cache legacy-fix` and restore again in the project.

- **Mod not loading on Quest**  
  Confirm Beat Saber 1.40.7, modloader (e.g. Scotland2) installed, and the correct `.so` in the mod folder. Check logcat for errors.

For **release** builds and creating a new release, see [BUILD.md](BUILD.md).
