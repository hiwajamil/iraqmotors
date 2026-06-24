#!/usr/bin/env python3
"""Remove legacy lib/ folders superseded by features/, shared/, and core/ subdirs."""

from pathlib import Path
import shutil

ROOT = Path(__file__).resolve().parent.parent
LIB = ROOT / "lib"

LEGACY_DIRS = [
    "data",
    "views",
    "models",
    "services",
    "providers",
    "widgets",
    "controllers",
]

LEGACY_CORE_SUBDIRS = {"config", "localization", "platform", "utils"}


def main() -> None:
    for name in LEGACY_DIRS:
        path = LIB / name
        if path.exists():
            shutil.rmtree(path)
            print(f"REMOVED dir {path.relative_to(ROOT)}")

    core = LIB / "core"
    if core.exists():
        for item in core.iterdir():
            if item.is_file() and item.suffix == ".dart":
                item.unlink()
                print(f"REMOVED file {item.relative_to(ROOT)}")
            elif item.is_dir() and item.name not in LEGACY_CORE_SUBDIRS:
                shutil.rmtree(item)
                print(f"REMOVED dir {item.relative_to(ROOT)}")

    print("Legacy cleanup done.")


if __name__ == "__main__":
    main()
