# Heck (Quest) — Beat Saber 1.40.7

Quest port of **[Aeroluna/Heck](https://github.com/Aeroluna/Heck)**. In the original repo, **Heck** is the umbrella that joins **Chroma** and **Noodle Extensions** in one solution (three projects, not submodules). There is no separate “Heck” mod — Heck is the shared core (patcher, Track, installers) used by Chroma and NoodleExtensions on PC.

On Quest this repo follows the same idea:

- **Heck** = the project name; it does **not** produce a `Heck.qmod`. See [Heck/README.md](Heck/README.md).
- **Chroma** = subfolder `Chroma/` — builds **Chroma.qmod** (port of [Aeroluna/Chroma](https://github.com/Aeroluna/Chroma), C++ code from [bsq-ports/Chroma](https://github.com/bsq-ports/Chroma)).
- **NoodleExtensions** = subfolder `noodleextensions/` — builds **NoodleExtensions.qmod** (port of [Aeroluna/NoodleExtensions](https://github.com/Aeroluna/NoodleExtensions), C++ code from [bsq-ports/NoodleExtensions](https://github.com/bsq-ports/NoodleExtensions)).

Together, Chroma and Noodle Extensions are “Heck” on Quest. You get **two mods**: Chroma.qmod and NoodleExtensions.qmod, both for **Beat Saber Quest 1.40.7**.

- **Target:** Beat Saber Quest **1.40.7** (package version `1.40.7_7060`)
- **Toolchain:** C++20, CMake, Ninja, qpm-rust, bs-cordl 4007.\*
- **Release tags:** **`bs_version-heck_version`** (e.g. `1.40.7-1.8.0`). **heck_version** = original [Heck](https://github.com/Aeroluna/Heck) version. Chroma and Noodle versions in their `qpm.json` follow the original Chroma/Noodle versions. See [BUILD.md](BUILD.md).

## Repository structure (like Aeroluna)

| Folder            | Role                                                                 | Build output           |
|-------------------|----------------------------------------------------------------------|------------------------|
| **Heck/**         | Umbrella / shared core (no .qmod on Quest)                          | —                      |
| **Chroma/**       | Chroma mod (C++ from bsq-ports, port of Aeroluna Chroma)            | Chroma.qmod            |
| **noodleextensions/** | Noodle Extensions mod (C++ from bsq-ports, port of Aeroluna NE) | NoodleExtensions.qmod  |

## How to build

- **Docker-only (minimal install):** Install only Docker, then build the image and run the platform-specific script:
  - Linux/macOS (bash): `./scripts/debian/docker-build.sh`
  - Windows (PowerShell): `pwsh ./scripts/windows/docker-build.ps1`  
  On **macOS Apple Silicon**, build the image with `docker build --platform linux/amd64 -t heck-quest-build .`. See [SETUP.md](SETUP.md) Option C.
- **Host toolchain:** [SETUP.md](SETUP.md): NDK, qpm-rust, CMake, Ninja, ADB. On macOS you can also use `./scripts/mac/build.sh` to install the required tools and build both mods.
2. **Restore** (once per project):
   - `cd chroma && qpm-rust restore && cd ..`
   - `cd noodleextensions && qpm-rust restore && cd ..`
3. **Build both mods:** from repo root: `pwsh ./scripts/build-all.ps1`
4. **Create .qmod files:** from repo root: `pwsh ./scripts/createqmod-all.ps1`

Output: `chroma/Chroma.qmod`, `noodleextensions/NoodleExtensions.qmod`.

## How to contribute

1. **Setup** — [SETUP.md](SETUP.md).
2. **Build for release** — [BUILD.md](BUILD.md): tag format `bs_version-heck_version`, attach Chroma.qmod and NoodleExtensions.qmod to the release.
3. **Code** — Edit under `Chroma/` or `noodleextensions/`; follow [port-guide-1.40.7](https://github.com/felipearmat/porting-guide/blob/main/port-guide-1.40.7.md) and bsq-ports patterns.
4. **PRs** — Target `main`; ensure `build-all.ps1` and `createqmod-all.ps1` succeed.

## References

- [Aeroluna/Heck](https://github.com/Aeroluna/Heck) — Original (Heck + Chroma + NoodleExtensions)
- [Beat Saber Quest porting guide (1.40.7)](https://github.com/felipearmat/porting-guide/blob/main/port-guide-1.40.7.md)
- [bsq-ports/Chroma](https://github.com/bsq-ports/Chroma), [bsq-ports/NoodleExtensions](https://github.com/bsq-ports/NoodleExtensions) — C++ ports used in this repo
- [QuestPackageManager](https://github.com/QuestPackageManager) — Quest modding toolchain

## Notes

- **ndkpath.txt** — Optional. Place in repo root (or in `chroma/scripts/` or `noodleextensions/scripts/`) with the NDK path if `ANDROID_NDK_HOME` is not set.

## License

Same as the original Heck project where applicable. See [LICENSE](LICENSE).
