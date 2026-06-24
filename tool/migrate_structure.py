#!/usr/bin/env python3
"""One-shot lib/ restructure: move files + rewrite imports to package:iq_motors/..."""

from __future__ import annotations

import os
import re
import shutil
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
LIB = ROOT / "lib"
PACKAGE = "iq_motors"

# old path (relative to lib/, forward slashes) -> new path
MOVES: dict[str, str] = {}

def add(old: str, new: str) -> None:
    MOVES[old.replace("\\", "/")] = new.replace("\\", "/")


# --- app ---
add("providers/locale_provider.dart", "app/providers/locale_provider.dart")
add("views/coming_soon_screen.dart", "app/screens/coming_soon_screen.dart")
add("views/startup_error_screen.dart", "app/screens/startup_error_screen.dart")

# --- core ---
for name in [
    "activity_actions", "bid_display", "car_image_urls", "iraq_romanization",
    "phone_auth_email", "relative_time",
]:
    add(f"core/{name}.dart", f"core/utils/{name}.dart")

for name in [
    "app_localization_delegates", "auth_l10n", "filter_l10n", "iraq_location_l10n",
    "l10n_extensions", "locale_config",
]:
    add(f"core/{name}.dart", f"core/localization/{name}.dart")

for name in [
    "firebase_web_config", "recaptcha_enterprise_config", "super_admin_config",
]:
    add(f"core/{name}.dart", f"core/config/{name}.dart")

for name in [
    "image_upload_bytes", "picked_image_preview", "picked_web_file",
    "web_debug_log", "web_debug_log_stub", "web_debug_log_web",
    "web_file_picker", "web_file_picker_stub", "web_file_picker_web",
    "web_pick_upload", "web_pick_upload_result", "web_pick_upload_stub",
    "web_pick_upload_web",
]:
    add(f"core/{name}.dart", f"core/platform/{name}.dart")

add("core/post_auth_navigation.dart", "features/auth/presentation/navigation/post_auth_navigation.dart")
add("core/admin_audit_helper.dart", "features/admin/domain/admin_audit_helper.dart")

# --- shared data (entire data tree) ---
data_root = LIB / "data"
if data_root.exists():
    for path in data_root.rglob("*.dart"):
        rel = path.relative_to(LIB).as_posix()
        add(rel, f"shared/data/{path.relative_to(data_root).as_posix()}")

# --- shared models ---
add("models/account_type.dart", "shared/models/account_type.dart")
add("models/car_brand.dart", "shared/models/car_brand.dart")
add("models/localized_car_model.dart", "shared/models/localized_car_model.dart")

# --- auth feature ---
add("controllers/auth_controller.dart", "features/auth/presentation/controllers/auth_controller.dart")
add("services/auth_service.dart", "features/auth/data/services/auth_service.dart")
add("models/user_profile.dart", "features/auth/domain/models/user_profile.dart")
add("models/phone_verification_result.dart", "features/auth/domain/models/phone_verification_result.dart")
add("providers/auth_providers.dart", "features/auth/presentation/providers/auth_providers.dart")
add("views/auth/auth_screen.dart", "features/auth/presentation/screens/auth_screen.dart")

# --- marketplace feature ---
for name in [
    "car", "car_bid_record", "advanced_filter_state", "home_filter_state",
]:
    add(f"models/{name}.dart", f"features/marketplace/domain/models/{name}.dart")

for name in [
    "car_database_service", "car_filter_service", "car_bid_service",
]:
    add(f"services/{name}.dart", f"features/marketplace/data/services/{name}.dart")

add("providers/favorites_provider.dart", "features/marketplace/presentation/providers/favorites_provider.dart")
add("providers/filter_providers.dart", "features/marketplace/presentation/providers/filter_providers.dart")
add("views/home/home_screen.dart", "features/marketplace/presentation/screens/home_screen.dart")
add("views/listings/car_details_screen.dart", "features/marketplace/presentation/screens/car_details_screen.dart")
add("views/filters/advanced_filter_screen.dart", "features/marketplace/presentation/screens/advanced_filter_screen.dart")

for name in [
    "advanced_filter_widget", "bid_input_dialog", "brand_horizontal_row",
    "brand_search_sheet", "car_bid_history_sheet", "home_filter_section",
    "premium_car_card",
]:
    add(f"widgets/{name}.dart", f"features/marketplace/presentation/widgets/{name}.dart")

home_widgets = LIB / "widgets" / "home"
if home_widgets.exists():
    for path in home_widgets.glob("*.dart"):
        name = path.name
        add(f"widgets/home/{name}", f"features/marketplace/presentation/widgets/home/{name}")

# --- listings feature (add car) ---
add("models/add_car_draft.dart", "features/listings/domain/models/add_car_draft.dart")
add("services/car_vision_service.dart", "features/listings/data/services/car_vision_service.dart")
add("widgets/add_car_chip_selector.dart", "features/listings/presentation/widgets/add_car_chip_selector.dart")

listings_root = LIB / "views" / "add_car"
if listings_root.exists():
    for path in listings_root.rglob("*.dart"):
        rel = path.relative_to(LIB).as_posix()
        suffix = path.relative_to(listings_root).as_posix()
        add(rel, f"features/listings/presentation/{suffix}")

# --- dashboard feature ---
add("views/dashboard/user_dashboard_screen.dart", "features/dashboard/presentation/screens/user_dashboard_screen.dart")
add("views/dashboard/showroom_dashboard_screen.dart", "features/dashboard/presentation/screens/showroom_dashboard_screen.dart")
add("widgets/wishlist_car_card.dart", "features/dashboard/presentation/widgets/wishlist_car_card.dart")
add("widgets/showroom_car_list_item.dart", "features/dashboard/presentation/widgets/showroom_car_list_item.dart")

# --- admin feature ---
for name in [
    "activity_log", "admin_dashboard_analytics", "admin_system_config",
    "flagged_ad_report", "showroom_listing_status", "support_ticket",
]:
    add(f"models/{name}.dart", f"features/admin/domain/models/{name}.dart")

for name in [
    "activity_log_service", "admin_database_service", "flagged_ads_service",
    "support_ticket_service", "user_usage_service",
]:
    add(f"services/{name}.dart", f"features/admin/data/services/{name}.dart")

add("providers/admin_settings_provider.dart", "features/admin/presentation/providers/admin_settings_provider.dart")

admin_root = LIB / "views" / "admin"
if admin_root.exists():
    for path in admin_root.glob("*.dart"):
        name = path.name
        add(f"views/admin/{name}", f"features/admin/presentation/screens/{name}")

# --- storage feature ---
add("models/r2_config.dart", "features/storage/domain/models/r2_config.dart")
for name in [
    "r2_storage_service", "cloudflare_upload_service", "cloudflare_upload_http",
    "cloudflare_upload_http_web", "storage_service",
]:
    add(f"services/{name}.dart", f"features/storage/data/services/{name}.dart")

add("providers/r2_storage_provider.dart", "features/storage/presentation/providers/r2_storage_provider.dart")
add("providers/storage_providers.dart", "features/storage/presentation/providers/storage_providers.dart")

# --- shared widgets ---
for name in [
    "car_network_image", "car_network_image_stub", "car_network_image_web",
    "filter_option_picker_dialog", "iraq_location_dropdowns", "language_switcher",
    "location_picker_sheet", "moderation_error_dialog",
]:
    add(f"widgets/{name}.dart", f"shared/widgets/{name}.dart")

IMPORT_RE = re.compile(
    r"import\s+['\"]([^'\"]+)['\"]\s*;",
)


def resolve_import(importer: str, import_path: str) -> str | None:
    """Return lib-relative path of target, or None for non-lib imports."""
    if import_path.startswith("package:"):
        if import_path.startswith(f"package:{PACKAGE}/"):
            return import_path[len(f"package:{PACKAGE}/") :]
        return None  # external package — unchanged
    if import_path.startswith("dart:"):
        return None

    importer_dir = str(Path(importer).parent).replace("\\", "/")

    if import_path.startswith("/"):
        candidate = import_path.lstrip("/")
    else:
        candidate = str(Path(importer_dir) / import_path)
        # normalize ..
        parts: list[str] = []
        for part in candidate.replace("\\", "/").split("/"):
            if part == "..":
                if parts:
                    parts.pop()
            elif part == "." or part == "":
                continue
            else:
                parts.append(part)
        candidate = "/".join(parts)

    return candidate


def to_package(path: str) -> str:
    return f"package:{PACKAGE}/{path}"


def move_files() -> None:
    # Sort by depth descending so we move leaves before parents when needed
    items = sorted(MOVES.items(), key=lambda x: x[0].count("/"), reverse=True)
    for old, new in items:
        src = LIB / old
        dst = LIB / new
        if not src.exists():
            if dst.exists():
                continue  # already moved
            raise FileNotFoundError(f"Missing source: {src}")
        dst.parent.mkdir(parents=True, exist_ok=True)
        if dst.exists():
            raise FileExistsError(f"Destination exists: {dst}")
        shutil.move(str(src), str(dst))
        print(f"MOVED {old} -> {new}")

    # Remove empty legacy directories
    for dirpath, dirnames, filenames in os.walk(LIB, topdown=False):
        p = Path(dirpath)
        if p == LIB:
            continue
        rel = p.relative_to(LIB)
        # keep l10n, main.dart locations
        if rel.parts == ("l10n",) or rel == Path("."):
            continue
        try:
            if not any(p.rglob("*")):
                p.rmdir()
        except OSError:
            pass


def rewrite_imports() -> None:
  # Build lookup: any historical path -> canonical new path
    canonical: dict[str, str] = {}
    for old, new in MOVES.items():
        canonical[old] = new
        canonical[new] = new

    dart_files = list(LIB.rglob("*.dart"))
    for dart_file in dart_files:
        rel = dart_file.relative_to(LIB).as_posix()
        text = dart_file.read_text(encoding="utf-8")
        changed = False

        def repl(match: re.Match[str]) -> str:
            nonlocal changed
            raw = match.group(1)
            if raw.startswith("package:") and not raw.startswith(f"package:{PACKAGE}/"):
                return match.group(0)
            if raw.startswith("dart:"):
                return match.group(0)

            resolved = resolve_import(rel, raw)
            if resolved is None:
                return match.group(0)

            # l10n stays at lib/l10n
            if resolved.startswith("l10n/"):
                new_import = to_package(resolved)
            elif resolved in canonical:
                new_import = to_package(canonical[resolved])
            elif resolved == "firebase_options.dart":
                new_import = to_package(resolved)
            elif resolved == "main.dart":
                new_import = to_package(resolved)
            else:
                # try without leading path issues — file may already be at new location
                if (LIB / resolved).exists():
                    new_import = to_package(resolved)
                else:
                    # fallback: search by basename in MOVES values
                    base = Path(resolved).name
                    matches = [v for v in MOVES.values() if Path(v).name == base]
                    if len(matches) == 1:
                        new_import = to_package(matches[0])
                    else:
                        print(f"WARN {rel}: unresolved import {raw!r} -> {resolved}")
                        return match.group(0)

            if new_import != f"package:{PACKAGE}/{raw}" and match.group(0) != f"import '{new_import}';":
                changed = True
                return f"import '{new_import}';"
            return match.group(0)

        new_text = IMPORT_RE.sub(repl, text)
        if changed:
            dart_file.write_text(new_text, encoding="utf-8")
            print(f"UPDATED imports in {rel}")


def main() -> None:
    print(f"Migrating {len(MOVES)} files under {LIB}")
    move_files()
    rewrite_imports()
    print("Done.")


if __name__ == "__main__":
    main()
