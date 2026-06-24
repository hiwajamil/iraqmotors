#!/usr/bin/env python3
"""Repair imports after feature-based lib/ restructure."""

from __future__ import annotations

import re
import shutil
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
LIB = ROOT / "lib"
PACKAGE = "iq_motors"

LEGACY_DIRS = ("data", "views", "models", "services", "providers", "widgets", "controllers")
LEGACY_CORE_SUBDIRS = frozenset({"config", "localization", "platform", "utils"})

PATH_REWRITES: list[tuple[str, str]] = [
    ("controllers/auth_controller.dart", "features/auth/presentation/controllers/auth_controller.dart"),
    ("core/post_auth_navigation.dart", "features/auth/presentation/navigation/post_auth_navigation.dart"),
    ("core/admin_audit_helper.dart", "features/admin/domain/admin_audit_helper.dart"),
    ("core/locale_config.dart", "core/localization/locale_config.dart"),
    ("core/l10n_extensions.dart", "core/localization/l10n_extensions.dart"),
    ("core/app_localization_delegates.dart", "core/localization/app_localization_delegates.dart"),
    ("core/auth_l10n.dart", "core/localization/auth_l10n.dart"),
    ("core/filter_l10n.dart", "core/localization/filter_l10n.dart"),
    ("core/iraq_location_l10n.dart", "core/localization/iraq_location_l10n.dart"),
    ("core/firebase_web_config.dart", "core/config/firebase_web_config.dart"),
    ("core/recaptcha_enterprise_config.dart", "core/config/recaptcha_enterprise_config.dart"),
    ("core/super_admin_config.dart", "core/config/super_admin_config.dart"),
    ("providers/locale_provider.dart", "app/providers/locale_provider.dart"),
    ("views/coming_soon_screen.dart", "app/screens/coming_soon_screen.dart"),
    ("views/startup_error_screen.dart", "app/screens/startup_error_screen.dart"),
    ("models/account_type.dart", "shared/models/account_type.dart"),
    ("models/car_brand.dart", "shared/models/car_brand.dart"),
    ("models/localized_car_model.dart", "shared/models/localized_car_model.dart"),
    ("data/", "shared/data/"),
    ("services/auth_service.dart", "features/auth/data/services/auth_service.dart"),
    ("providers/auth_providers.dart", "features/auth/presentation/providers/auth_providers.dart"),
    ("models/user_profile.dart", "features/auth/domain/models/user_profile.dart"),
    ("views/auth/auth_screen.dart", "features/auth/presentation/screens/auth_screen.dart"),
]

IMPORT_RE = re.compile(
    r"(?m)^(\s*(?:import|export)\s+)"
    r"['\"]([^'\"]+)['\"]"
    r"([^;]*;)"
)

CONDITIONAL_IMPORT_RE = re.compile(
    r"import\s+['\"]([^'\"]+\.dart)['\"]\s*"
    r"if\s*\([^)]+\)\s*['\"]([^'\"]+\.dart)['\"]"
)


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
    candidate = normalize(f"{importer_dir}/{raw}" if not raw.startswith("/") else raw.lstrip("/"))
    return candidate


def rewrite_canonical(lib_rel: str) -> str:
    for old, new in PATH_REWRITES:
        if lib_rel == old or lib_rel.startswith(old):
            return new + lib_rel[len(old) :]
    return lib_rel


def to_package(lib_rel: str) -> str:
    return f"package:{PACKAGE}/{rewrite_canonical(lib_rel)}"


def resolve_to_package(importer_rel: str, raw: str) -> str | None:
    if raw.startswith("package:") or raw.startswith("dart:"):
        if raw.startswith(f"package:{PACKAGE}/"):
            inner = raw[len(f"package:{PACKAGE}/") :]
            return f"package:{PACKAGE}/{rewrite_canonical(inner)}"
        return None
    resolved = resolve_lib_path(importer_rel, raw)
    if resolved is None:
        return None
    target_rel = rewrite_canonical(resolved)
    if not (LIB / target_rel).is_file():
        return None
    return to_package(resolved)


def remove_legacy() -> None:
    for name in LEGACY_DIRS:
        path = LIB / name
        if path.exists():
            shutil.rmtree(path)
            print(f"REMOVED {path.relative_to(ROOT)}")

    core = LIB / "core"
    if core.exists():
        for item in list(core.iterdir()):
            if item.is_file() and item.suffix == ".dart":
                item.unlink()
                print(f"REMOVED {item.relative_to(ROOT)}")
            elif item.is_dir() and item.name not in LEGACY_CORE_SUBDIRS:
                shutil.rmtree(item)
                print(f"REMOVED {item.relative_to(ROOT)}")


def fix_dart_file(path: Path) -> bool:
    if not path.is_relative_to(LIB):
        text = path.read_text(encoding="utf-8")
        updated = text.replace(
            "package:iq_motors/core/locale_config.dart",
            "package:iq_motors/core/localization/locale_config.dart",
        )
        if updated != text:
            path.write_text(updated, encoding="utf-8")
            print(f"FIXED {path.relative_to(ROOT)}")
            return True
        return False

    rel = path.relative_to(LIB).as_posix()
    text = path.read_text(encoding="utf-8")
    changed = False

    def repl(match: re.Match[str]) -> str:
        nonlocal changed
        prefix, raw, suffix = match.group(1), match.group(2), match.group(3)
        if " if " in suffix:
            return match.group(0)
        new_raw = resolve_to_package(rel, raw)
        if new_raw is None or new_raw == raw:
            return match.group(0)
        changed = True
        return f"{prefix}'{new_raw}'{suffix}"

    new_text = IMPORT_RE.sub(repl, text)

    def cond_repl(match: re.Match[str]) -> str:
        nonlocal changed
        first, second = match.group(1), match.group(2)
        nf = resolve_to_package(rel, first) or first
        ns = resolve_to_package(rel, second) or second
        if nf == first and ns == second:
            return match.group(0)
        changed = True
        return match.group(0).replace(f"'{first}'", f"'{nf}'", 1).replace(f"'{second}'", f"'{ns}'", 1)

    new_text = CONDITIONAL_IMPORT_RE.sub(cond_repl, new_text)

    if changed:
        path.write_text(new_text, encoding="utf-8")
        print(f"FIXED {rel}")
    return changed


def main() -> None:
    remove_legacy()
    count = sum(1 for dart in LIB.rglob("*.dart") if fix_dart_file(dart))
    test = ROOT / "test"
    if test.exists():
        count += sum(1 for dart in test.rglob("*.dart") if fix_dart_file(dart))
    print(f"Import repair complete ({count} files updated).")


if __name__ == "__main__":
    main()
