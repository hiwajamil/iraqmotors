"""
Sync trims into car_trims_by_model.dart keyed by the APP's real model ids.

final_iqmotors_catalog.json often uses different ids than LocalizedCarModel.id
(e.g. mercedes mb_c_class vs mercedes_benz_c_class, bmw series_3 vs bmw_3_series).
We match catalog entries onto app models, then store trims under keys that
CarTrimsByModel.trimsFor(brandId, modelId) will find.
"""

from __future__ import annotations

import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
CATALOG = ROOT / "final_iqmotors_catalog.json"
OUT = ROOT / "lib" / "shared" / "data" / "car_trims_by_model.dart"
MODELS_DIR = ROOT / "lib" / "shared" / "data" / "car_models"


def dart_string(value: str) -> str:
    escaped = (
        value.replace("\\", "\\\\")
        .replace("'", "\\'")
        .replace("$", "\\$")
    )
    return f"'{escaped}'"


def norm(text: str) -> str:
    text = text.lower().strip()
    text = text.replace("&", " and ")
    text = re.sub(r"[^a-z0-9]+", "_", text)
    return re.sub(r"_+", "_", text).strip("_")


def strip_brand_prefix(brand_id: str, model_id: str) -> str:
    prefix = f"{brand_id}_"
    remaining = model_id
    while remaining.startswith(prefix):
        remaining = remaining[len(prefix) :]
    # Mercedes models in app use mb_ prefix
    if brand_id == "mercedes_benz" and remaining.startswith("mb_"):
        remaining = remaining[3:]
    return remaining


def parse_app_models() -> dict[str, list[dict]]:
    catalog_src = (ROOT / "lib/shared/data/car_models/catalog.dart").read_text(
        encoding="utf-8"
    )
    const_models: dict[str, list[dict]] = {}
    model_file_re = re.compile(
        r"const List<LocalizedCarModel> (\w+) = \[(.*?)\];", re.S
    )
    item_re = re.compile(
        r"LocalizedCarModel\(\s*"
        r"id:\s*'([^']+)',\s*"
        r"ku:\s*'((?:\\'|[^'])*)',\s*"
        r"en:\s*'((?:\\'|[^'])*)',\s*"
        r"ar:\s*'((?:\\'|[^'])*)',?\s*\)",
        re.S,
    )
    for path in MODELS_DIR.glob("*_models.dart"):
        text = path.read_text(encoding="utf-8")
        for cm in model_file_re.finditer(text):
            items = []
            for im in item_re.finditer(cm.group(2)):
                items.append(
                    {
                        "id": im.group(1),
                        "en": im.group(3).replace(r"\'", "'"),
                    }
                )
            const_models[cm.group(1)] = items

    result: dict[str, list[dict]] = {}
    for match in re.finditer(r"'([^']+)':\s*(\w+),", catalog_src):
        brand_id, const_name = match.group(1), match.group(2)
        if const_name.endswith("Models"):
            result[brand_id] = const_models.get(const_name, [])
    return result


def catalog_index(data: dict) -> dict[str, list[dict]]:
    by_brand: dict[str, list[dict]] = {}
    for brand in data.get("brands", []):
        brand_id = brand["id"]
        models = []
        for model in brand.get("models", []):
            trims = [str(t).strip() for t in (model.get("trims") or []) if str(t).strip()]
            models.append(
                {
                    "id": model["id"],
                    "trimLookupKey": model.get("trimLookupKey") or model["id"],
                    "en": (model.get("name") or {}).get("en") or "",
                    "trims": trims,
                }
            )
        by_brand[brand_id] = models
    return by_brand


def score_match(brand_id: str, app_model: dict, cat_model: dict) -> int:
    app_id = app_model["id"]
    cat_id = cat_model["id"]
    cat_key = cat_model["trimLookupKey"]
    app_suffix = strip_brand_prefix(brand_id, app_id)
    cat_suffix = strip_brand_prefix(brand_id, cat_id)
    cat_key_suffix = strip_brand_prefix(brand_id, cat_key)

    app_en = norm(app_model["en"])
    cat_en = norm(cat_model["en"])

    if app_id == cat_id or app_id == cat_key:
        return 100
    if f"{brand_id}_{app_id}" == cat_key or f"{brand_id}_{app_id}" == cat_id:
        return 95
    if app_suffix and app_suffix in {cat_suffix, cat_key_suffix}:
        return 90
    if app_en and app_en == cat_en:
        return 85

    # series_3 <-> 3_series, series_5 <-> 5_series
    m1 = re.fullmatch(r"series_(\d+)", app_suffix)
    m2 = re.fullmatch(r"(\d+)_series", cat_suffix) or re.fullmatch(
        r"(\d+)_series", cat_key_suffix
    )
    if m1 and m2 and m1.group(1) == m2.group(1):
        return 80

    # chr <-> ch_r, land_cruiser_prado etc soft normalize
    if app_suffix.replace("_", "") == cat_suffix.replace("_", ""):
        return 75
    if app_suffix.replace("_", "") == cat_key_suffix.replace("_", ""):
        return 75
    if app_en and cat_en and (
        app_en.replace("_", "") == cat_en.replace("_", "")
    ):
        return 70

    # contains mutual for longer names
    if app_en and cat_en and len(app_en) >= 4:
        if app_en in cat_en or cat_en in app_en:
            return 40

    return 0


def find_trims(brand_id: str, app_model: dict, cat_models: list[dict]) -> list[str]:
    best = None
    best_score = 0
    for cat_model in cat_models:
        if not cat_model["trims"]:
            continue
        score = score_match(brand_id, app_model, cat_model)
        if score > best_score:
            best_score = score
            best = cat_model
    if best is None or best_score < 70:
        return []
    # unique preserve order
    seen: set[str] = set()
    out: list[str] = []
    for t in best["trims"]:
        if t not in seen:
            seen.add(t)
            out.append(t)
    return out


def lookup_keys(brand_id: str, model_id: str) -> list[str]:
    """Keys that trimsFor(brandId, modelId) may request."""
    keys = [f"{brand_id}_{model_id}"]
    prefix = f"{brand_id}_"
    remaining = model_id
    while remaining.startswith(prefix):
        remaining = remaining[len(prefix) :]
        if not remaining:
            break
        keys.append(f"{brand_id}_{remaining}")
    # Also store bare model id when it already embeds brand (helps debugging)
    if model_id.startswith(prefix):
        keys.append(model_id)
    # Deduplicate preserving order
    seen: set[str] = set()
    ordered = []
    for k in keys:
        if k not in seen:
            seen.add(k)
            ordered.append(k)
    return ordered


def main() -> None:
    data = json.loads(CATALOG.read_text(encoding="utf-8"))
    app_models = parse_app_models()
    cat_by_brand = catalog_index(data)

    entries: dict[str, list[str]] = {}
    matched = 0
    unmatched_with_catalog_trims = 0

    for brand_id, models in app_models.items():
        cat_models = cat_by_brand.get(brand_id, [])
        for app_model in models:
            trims = find_trims(brand_id, app_model, cat_models)
            if not trims:
                continue
            matched += 1
            for key in lookup_keys(brand_id, app_model["id"]):
                existing = entries.get(key)
                if existing is None or len(trims) >= len(existing):
                    entries[key] = trims

    # Report catalog models with trims that never matched an app model
    for brand_id, cat_models in cat_by_brand.items():
        app_list = app_models.get(brand_id, [])
        for cat_model in cat_models:
            if not cat_model["trims"]:
                continue
            if not any(score_match(brand_id, a, cat_model) >= 70 for a in app_list):
                unmatched_with_catalog_trims += 1

    lines: list[str] = []
    lines.append("/// Trim / variant options keyed by catalog model id.")
    lines.append("///")
    lines.append(
        "/// Source of truth: final_iqmotors_catalog.json matched onto app model ids."
    )
    lines.append("/// Regenerated automatically. DO NOT edit by hand.")
    lines.append("/// Run: python scratch/sync_trims_from_final_catalog.py")
    lines.append("///")
    lines.append(
        "/// Empty trim sets are omitted — models without catalogued trims "
        "fall back to free text / generic options."
    )
    lines.append("abstract final class CarTrimsByModel {")
    lines.append("  static const Map<String, List<String>> _trimsByModelId = {")

    for key in sorted(entries.keys()):
        trims = entries[key]
        lines.append(f"    {dart_string(key)}: [")
        for trim in trims:
            lines.append(f"      {dart_string(trim)},")
        lines.append("    ],")

    lines.append("  };")
    lines.append("")
    lines.append(
        "  /// Returns the trim list for the given [brandId] + [modelKey] combination."
    )
    lines.append("  ///")
    lines.append("  /// NOTE:")
    lines.append(
        "  /// The model catalogs in this app sometimes store model ids already prefixed"
    )
    lines.append(
        "  /// with the brand id (e.g. `toyota_corolla`), while trim keys may also be"
    )
    lines.append(
        "  /// stored as `brand_model`. We try both forms, and also `modelKey` itself."
    )
    lines.append(
        "  static List<String> trimsFor(String? brandId, String? modelKey) {"
    )
    lines.append(
        "    if (brandId == null || modelKey == null) return const [];"
    )
    lines.append("    final candidates = <String>[")
    lines.append("      '${brandId}_$modelKey',")
    lines.append("      modelKey,")
    lines.append("    ];")
    lines.append("")
    lines.append("    final prefix = '${brandId}_';")
    lines.append("    var remaining = modelKey;")
    lines.append("    while (remaining.startsWith(prefix)) {")
    lines.append(
        "      remaining = remaining.substring(prefix.length);"
    )
    lines.append("      if (remaining.isEmpty) break;")
    lines.append("      candidates.add('${brandId}_$remaining');")
    lines.append("    }")
    lines.append("")
    lines.append(
        "    // Mercedes app model ids use an `mb_` prefix "
        "(e.g. mb_c_class)."
    )
    lines.append(
        "    if (brandId == 'mercedes_benz' && modelKey.startsWith('mb_')) {"
    )
    lines.append(
        "      candidates.add('mercedes_benz_${modelKey.substring(3)}');"
    )
    lines.append("    }")
    lines.append("")
    lines.append("    for (final key in candidates) {")
    lines.append("      final trims = _trimsByModelId[key];")
    lines.append("      if (trims != null && trims.isNotEmpty) return trims;")
    lines.append("    }")
    lines.append("    return const [];")
    lines.append("  }")
    lines.append("")
    lines.append("  /// Returns true if the model has a catalogued trim list.")
    lines.append(
        "  static bool hasTrims(String? brandId, String? modelKey) =>"
    )
    lines.append("      trimsFor(brandId, modelKey).isNotEmpty;")
    lines.append("}")
    lines.append("")

    OUT.write_text("\n".join(lines), encoding="utf-8")
    print(f"Wrote {OUT}")
    print(f"Unique map keys: {len(entries)}")
    print(f"App models matched with trims: {matched}")
    print(f"Catalog trim models unmatched to app: {unmatched_with_catalog_trims}")


if __name__ == "__main__":
    main()
