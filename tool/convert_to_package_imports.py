#!/usr/bin/env python3
"""Convert all lib-relative imports to package:iq_motors/... paths."""

from __future__ import annotations

import re
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
LIB = ROOT / "lib"
PACKAGE = "iq_motors"

IMPORT_RE = re.compile(r"import\s+['\"]([^'\"]+)['\"]\s*;")


def normalize(path: str) -> str:
    parts: list[str] = []
    for part in path.replace("\\", "/").split("/"):
        if part == "..":
            if parts:
                parts.pop()
        elif part in (".", ""):
            continue
        else:
            parts.append(part)
    return "/".join(parts)


def resolve_lib_path(importer: str, raw: str) -> str | None:
    if raw.startswith("package:") or raw.startswith("dart:"):
        return None
    importer_dir = str(Path(importer).parent).replace("\\", "/")
    if raw.startswith("/"):
        candidate = raw.lstrip("/")
    else:
        candidate = f"{importer_dir}/{raw}"
    return normalize(candidate)


def fix_file(path: Path, base: Path) -> bool:
    rel = path.relative_to(base).as_posix()
    text = path.read_text(encoding="utf-8")
    changed = False

    def repl(match: re.Match[str]) -> str:
        nonlocal changed
        raw = match.group(1)
        if raw.startswith("package:") or raw.startswith("dart:"):
            return match.group(0)

        resolved = resolve_lib_path(rel, raw)
        if resolved is None:
            return match.group(0)

        target = LIB / resolved  # lib targets only
        if not target.is_file():
            print(f"WARN {rel}: missing target for {raw!r} -> {resolved}")
            return match.group(0)

        package_import = f"package:{PACKAGE}/{resolved}"
        if raw != package_import:
            changed = True
            return f"import '{package_import}';"
        return match.group(0)

    new_text = IMPORT_RE.sub(repl, text)
    if changed:
        path.write_text(new_text, encoding="utf-8")
        print(f"FIXED {rel}")
    return changed


def main() -> None:
    count = 0
    if LIB.exists():
        for dart in LIB.rglob("*.dart"):
            if fix_file(dart, LIB):
                count += 1
  # test/ files already use package: imports; fix known stale paths only
    test = ROOT / "test"
    if test.exists():
        stale = {
            "package:iq_motors/core/locale_config.dart": "package:iq_motors/core/localization/locale_config.dart",
        }
        for dart in test.rglob("*.dart"):
            text = dart.read_text(encoding="utf-8")
            updated = text
            for old, new in stale.items():
                updated = updated.replace(old, new)
            if updated != text:
                dart.write_text(updated, encoding="utf-8")
                print(f"FIXED {dart.relative_to(ROOT)}")
                count += 1
    print(f"Updated {count} files.")


if __name__ == "__main__":
    main()
