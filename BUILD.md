# Building the mods for release

This document describes how to set up the environment and perform the **build steps for a new release** of Heck (Quest) — i.e. **Chroma** and **Noodle Extensions** for Beat Saber Quest 1.40.7. The release tag convention is **`bs_version-heck_version`**. There is no separate Heck.qmod; the release contains **Chroma.qmod** and **NoodleExtensions.qmod**.

---

## 1. Environment for release builds

Same toolchain as for development:

- **CMake** 3.21+, **Ninja**, **PowerShell**, **Android NDK** (compatible with Chroma/Noodle `qpm.json`), **qpm-rust**

See [SETUP.md](SETUP.md).

- **Test the CI workflow locally (before push):** Use [act](https://github.com/nektos/act) to run the "Build and Publish" pipeline on your machine: `act workflow_dispatch -j build` from the repo root (or `pwsh ./scripts/run-workflow-local.ps1`). Requires Docker. See [.github/TESTING_WORKFLOW_LOCALLY.md](.github/TESTING_WORKFLOW_LOCALLY.md).

- **Docker-only (minimal host install):** To avoid installing the toolchain on your machine, use the all-in-Docker flow: build the image once, then run the platform-specific script from the repo root — `./scripts/debian/docker-build.sh` (bash) or `pwsh ./scripts/windows/docker-build.ps1` (PowerShell). See [SETUP.md](SETUP.md) **Option C**.
- **On macOS with Apple Silicon (ARM):** Build the Docker image with `docker build --platform linux/amd64 -t heck-quest-build .` so the NDK (Linux x86_64 only) runs correctly. See [SETUP.md](SETUP.md) Option B (4.1) and Option C (5.1, 5.3).
- **Reproducible build with Docker (toolchain on host):** Use the Docker image from [SETUP.md](SETUP.md) Option B (restore on host; build inside container).

Restore dependencies **in each project** once (skip if using Docker-only, Option C):

```bash
cd chroma && qpm-rust restore && cd ..
cd noodleextensions && qpm-rust restore && cd ..
```

---

## 2. Build steps for a new release

### 2.1 Version alignment

- **Tag** will be **`bs_version-heck_version`** (e.g. `1.40.7-1.8.0`). **heck_version** = original [Heck](https://github.com/Aeroluna/Heck) version.
- In **`chroma/qpm.json`**: **`info.version`** = original [Chroma](https://github.com/Aeroluna/Chroma) version (e.g. `2.9.4`).
- In **`noodleextensions/qpm.json`**: **`info.version`** = original [Noodle Extensions](https://github.com/Aeroluna/NoodleExtensions) version (e.g. `1.0.0` or the current NE version).

### 2.2 Build in Release mode

From the **repo root**:

```powershell
pwsh ./scripts/build-all.ps1
```

This builds Chroma and then Noodle Extensions (each in its own folder). Output:

- `chroma/build/libchroma.so`
- `noodleextensions/build/libnoodleextensions.so`

### 2.3 Create the .qmod packages

From the **repo root**:

```powershell
pwsh ./scripts/createqmod-all.ps1
```

This creates:

- **`chroma/Chroma.qmod`**
- **`noodleextensions/NoodleExtensions.qmod`**

Install both on a Quest with Beat Saber 1.40.7 and test before publishing the release.

### 2.4 Populate release folders with .qmod (optional)

As pastas **`releases/1407/`** e **`releases/1408/`** devem conter apenas ficheiros **.qmod** (não .so). Depois do build e createqmod:

```powershell
pwsh ./scripts/copy-qmods-to-releases.ps1 1407   # ou 1408
```

Isto copia **Chroma.qmod** e **NoodleExtensions.qmod** para a pasta indicada e remove qualquer .so que lá esteja. Ver **`releases/README.md`** para mais pormenores.

---

## 3. Release tag convention: `bs_version-heck_version`

Tag format:

```text
<bs_version>-<heck_version>
```

- **bs_version** — Beat Saber version (e.g. `1.40.7`).
- **heck_version** — Original [Heck](https://github.com/Aeroluna/Heck) version (e.g. `1.8.0`).

**Examples:**

| Tag            | Meaning                                                    |
|----------------|------------------------------------------------------------|
| `1.40.7-1.8.0` | Heck (Chroma + Noodle) for BS 1.40.7, aligned to Heck 1.8.0 |

### 3.1 Creating the tag and pushing

1. Ensure **chroma** and **noodleextensions** `qpm.json` versions match the originals (Chroma / Noodle Extensions).
2. Commit any changes.
3. Create and push the tag:

```bash
git tag 1.40.7-1.8.0
git push origin 1.40.7-1.8.0
```

The GitHub Action runs on tags `*-*`, builds Chroma and Noodle Extensions, creates both .qmods, and creates a **GitHub Release** with:

- **Chroma.qmod**
- **NoodleExtensions.qmod**
- (optional) `libchroma.so`, `libnoodleextensions.so`, and debug libs

### 3.2 Release manually (without CI)

1. Run **build-all.ps1** and **createqmod-all.ps1** (sections 2.2 and 2.3).
2. Create the tag and push (e.g. `1.40.7-1.8.0`).
3. On GitHub, create a Release from that tag and upload **Chroma.qmod** and **NoodleExtensions.qmod** (and optionally the .so files).

---

## 4. One-liner (host): build + qmods

From the repo root, after restoring in both `chroma/` and `noodleextensions/`:

```powershell
pwsh ./scripts/build-all.ps1; if ($?) { pwsh ./scripts/createqmod-all.ps1 }
```

---

## 5. Release checklist

- [ ] Set **chroma/qpm.json** and **noodleextensions/qpm.json** **`info.version`** to the original Chroma and Noodle Extensions versions.
- [ ] Run **`pwsh ./scripts/build-all.ps1`** from repo root.
- [ ] Run **`pwsh ./scripts/createqmod-all.ps1`** and verify **Chroma.qmod** and **NoodleExtensions.qmod** are created.
- [ ] Test both .qmods on Beat Saber Quest **1.40.7**.
- [ ] Commit, then create and push the tag **`<bs_version>-<heck_version>`** (e.g. `1.40.7-1.8.0`).
- [ ] Let the GitHub Action create the Release and attach the artifacts, or create the Release manually and upload Chroma.qmod and NoodleExtensions.qmod.

---

## 6. Troubleshooting

### "Cannot upgrade NoodleExtensions to 1.0.0: mod MappingExtensions depends on renga ^1.5.4"

This can appear in QuestPatcher/BMBF when installing or upgrading NoodleExtensions. **MappingExtensions** (another mod) declares a dependency on **renga** ^1.5.4. NoodleExtensions' `mod.json` includes **renga** as a dependency so the installer can satisfy it. If the error persists:

1. Install **renga** (version 1.5.4 or compatible) first from your mod source, then install or upgrade NoodleExtensions.
2. Or install NoodleExtensions from the .qmod file directly (side-load) instead of through the mod list that triggers the upgrade check.

---

## 7. Building Tracks for Beat Saber 1.40.8

The **Tracks** mod (dependency of Chroma and Noodle Extensions) can be built for BS 1.40.8. The build uses Docker (Rust + CMake) and requires a **one-time restore on the host** (qpm-rust resolves from the network and needs a patched registry for CJD 0.24.3 + bs-cordl 4008). The output is **`local_deps/tracks/build/libtracks.so`**; for **releases/1408** use only .qmod (run build + createqmod for Chroma/NE 1.40.8 with that libtracks.so in extern, then **`pwsh ./scripts/copy-qmods-to-releases.ps1 1408`**).

### 7.1 One-time restore on the host

Ensure your QPM registry allows **custom-json-data 0.24.3** and **tracks 2.4.4** to use bs-cordl `>=4007.0.0, <4009.0.0` (see project notes on registry patching). Then:

```bash
cd local_deps/tracks
qpm-rust restore
cd ../..
```

This creates `local_deps/tracks/extern/`, `extern.cmake`, `qpm_defines.cmake`, and `qpm.lock`. The `extern/libs` symlinks point into your QPM cache (e.g. `~/Library/Application Support/QPM-RS` on macOS).

### 7.2 Docker build

From the **repo root**:

```bash
./scripts/docker-build-tracks.sh
```

This script builds the **heck-quest-tracks-build** image (Rust nightly + cargo-ndk) if needed, runs the Rust and CMake/Ninja build inside the container, mounts your QPM cache so `extern/libs` symlinks resolve, and writes **`libtracks.so`** to **`local_deps/tracks/build/`**. For 1.40.8 release packages use only .qmod in **releases/1408/** (see **releases/README.md**): copy that libtracks.so into chroma and noodleextensions extern/libs, build and createqmod, then run **`pwsh ./scripts/copy-qmods-to-releases.ps1 1408`**.
