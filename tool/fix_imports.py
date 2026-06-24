#!/usr/bin/env python3
"""Fix remaining broken relative imports after structure migration."""

import re
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent

IMPORT_RE = re.compile(
    r"import\s+['\"]([^'\"]+)['\"]\s*;",
)

REPLACEMENTS = {
    # l10n — any relative path ending in l10n/app_localizations.dart
    re.compile(r"^(?:\.\./)+l10n/app_localizations\.dart$"): "package:iq_motors/l10n/app_localizations.dart",
    re.compile(r"^l10n/app_localizations\.dart$"): "package:iq_motors/l10n/app_localizations.dart",
    # firebase_options
    re.compile(r"^(?:\.\./)+firebase_options\.dart$"): "package:iq_motors/firebase_options.dart",
    # locale_config old path in tests
    re.compile(r"^package:iq_motors/core/locale_config\.dart$"): "package:iq_motors/core/localization/locale_config.dart",
}


def fix_file(path: Path) -> bool:
    text = path.read_text(encoding="utf-8")
    changed = False

    def repl(match: re.Match[str]) -> str:
        nonlocal changed
        raw = match.group(1)
        for pattern, replacement in REPLACEMENTS.items():
            if pattern.match(raw):
                if raw != replacement:
                    changed = True
                    return f"import '{replacement}';"
                return match.group(0)
        return match.group(0)

    new_text = IMPORT_RE.sub(repl, text)
    if changed:
        path.write_text(new_text, encoding="utf-8")
        print(f"FIXED {path.relative_to(ROOT)}")
    return changed


def main() -> None:
    count = 0
    for folder in (ROOT / "lib", ROOT / "test"):
        if not folder.exists():
            continue
        for dart in folder.rglob("*.dart"):
            if fix_file(dart):
                count += 1
    print(f"Fixed {count} files.")


if __name__ == "__main__":
    main()
