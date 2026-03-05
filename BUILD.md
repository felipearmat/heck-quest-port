# Building the mods for release

This document describes how to set up the environment and perform the **build steps for a new release** of Heck (Quest) — i.e. **Chroma** and **Noodle Extensions** for Beat Saber Quest 1.40.7. The release tag convention is **`bs_version-heck_version`**. There is no separate Heck.qmod; the release contains **Chroma.qmod** and **NoodleExtensions.qmod**.

---

## 1. Environment for release builds

Same toolchain as for development:

- **CMake** 3.21+, **Ninja**, **PowerShell**, **Android NDK** (compatible with Chroma/Noodle `qpm.json`), **qpm-rust**

See [SETUP.md](SETUP.md).

- **Docker-only (minimal host install):** To avoid installing the toolchain on your machine, use the all-in-Docker flow: build the image once, then run `./scripts/docker-build.sh` (or `pwsh ./scripts/docker-build.ps1`) from the repo root. See [SETUP.md](SETUP.md) **Option C**.
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
