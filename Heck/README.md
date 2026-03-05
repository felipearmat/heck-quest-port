# Heck (shared core — Quest)

In the [Aeroluna Heck](https://github.com/Aeroluna/Heck) repo, **Heck** is the shared core: it provides the patcher (HeckPatchManager), Track registration, Zenject installers, and other infrastructure that **Chroma** and **NoodleExtensions** both use. The solution has three projects: Heck, Chroma, NoodleExtensions (not submodules — one repo, three projects).

On Quest there is no separate “Heck” mod. The C++ ports of Chroma and Noodle Extensions (from [bsq-ports](https://github.com/bsq-ports)) each implement the needed logic in their own `.so`; there is no shared Heck library. So in **heck-quest-port**:

- **Heck** (this folder) = conceptual umbrella only. It does not produce a `Heck.qmod`. It can hold shared C++ utilities in the future if needed.
- **Chroma** = `../chroma/` — builds **Chroma.qmod** (port of [Aeroluna/Chroma](https://github.com/Aeroluna/Chroma), code from bsq-ports).
- **NoodleExtensions** = `../noodleextensions/` — builds **NoodleExtensions.qmod** (port of [Aeroluna/NoodleExtensions](https://github.com/Aeroluna/NoodleExtensions), code from bsq-ports).

Together, Chroma and Noodle Extensions represent “Heck” on Quest, same idea as the Aeroluna repo.
