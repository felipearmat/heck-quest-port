#!/usr/bin/env python3
"""
Patch QPM registry so tracks 2.4.4 + custom-json-data 0.24.3 can resolve with bs-cordl 4008.*.
Use in Docker before `qpm-rust restore` when building for BS 1.40.8.
"""
import json
import os
import sys

WIDE_BS_CORDL = ">=4007.0.0, <4009.0.0"
REGISTRY_PATH = os.path.expanduser("~/.local/share/QPM-RS/qpm.repository.json")
if "QPM_RS_DIR" in os.environ:
    REGISTRY_PATH = os.path.join(os.environ["QPM_RS_DIR"], "qpm.repository.json")


def patch_artifact(data: dict, pkg_id: str, version: str) -> bool:
    changed = False
    try:
        pkg = data["artifacts"][pkg_id]
        if version not in pkg:
            return False
        ver_data = pkg[version]
        config = ver_data.get("config", ver_data)
        deps = config.get("dependencies", [])
        for d in deps:
            if d.get("id") == "bs-cordl":
                old = d.get("versionRange", "")
                if old != WIDE_BS_CORDL:
                    d["versionRange"] = WIDE_BS_CORDL
                    changed = True
                break
    except (KeyError, TypeError):
        pass
    return changed


def main():
    if not os.path.isfile(REGISTRY_PATH):
        print("Registry not found:", REGISTRY_PATH, file=sys.stderr)
        sys.exit(1)
    with open(REGISTRY_PATH, "r", encoding="utf-8") as f:
        data = json.load(f)
    c1 = patch_artifact(data, "custom-json-data", "0.24.3")
    c2 = patch_artifact(data, "tracks", "2.4.4")
    if c1 or c2:
        with open(REGISTRY_PATH, "w", encoding="utf-8") as f:
            json.dump(data, f, indent=2)
        print("Patched qpm.repository.json: bs-cordl ->", WIDE_BS_CORDL)
    else:
        print("Registry already patched or entries not found.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
