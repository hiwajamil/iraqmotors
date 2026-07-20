"""
Fill missing brand models (NHTSA vPIC + Data/*.csv) and missing trims
(Data/trims.csv + existing catalog + standard grade fallbacks).

Writes/updates:
  - lib/shared/data/car_models/{brand}_models.dart
  - lib/shared/data/car_models/catalog.dart
  - lib/shared/data/car_trims_by_model.dart

Then run: python scratch/export_brands_models_trims.py
"""

from __future__ import annotations

import csv
import json
import re
import time
import urllib.error
import urllib.parse
import urllib.request
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
MODELS_DIR = ROOT / "lib" / "shared" / "data" / "car_models"
CATALOG_PATH = MODELS_DIR / "catalog.dart"
TRIMS_PATH = ROOT / "lib" / "shared" / "data" / "car_trims_by_model.dart"
BRANDS_PATH = ROOT / "lib" / "shared" / "data" / "dummy_brands.dart"
DATA_DIR = ROOT / "Data"
CACHE_DIR = ROOT / ".tmp_pdf_preview" / "nhtsa_cache"
REPORT_PATH = ROOT / ".tmp_pdf_preview" / "catalog_fill_report.json"

# Generic trims when no market-specific trim list exists.
DEFAULT_TRIMS = ["Standard", "Base", "Sport", "Luxury"]

# Map app brand_id / English name quirks → NHTSA make query string.
NHTSA_MAKE_ALIASES: dict[str, list[str]] = {
    "mercedes_benz": ["Mercedes-Benz", "Mercedes Benz"],
    "gac_motor": ["GAC"],
    "gwm_tank": ["GWM"],
    "land_rover": ["Land Rover"],
    "alfa_romeo": ["Alfa Romeo"],
    "aston_martin": ["Aston Martin"],
    "rolls_royce": ["Rolls Royce", "Rolls-Royce"],
    "ssangyong": ["Ssangyong", "SsangYong"],
    "citro_n": ["Citroen", "Citroën"],
    "lynk_and_co": ["Lynk & Co", "Lynk and Co"],
    "renault_samsung_motors": ["Renault Samsung", "Samsung"],
    "zyle_daewoo_commercial_vehicles": ["Daewoo"],
    "maybach": ["Maybach", "Mercedes-Benz"],
    "general_motors": ["GMC", "Chevrolet"],
    "ds": ["DS", "Citroen"],
}


def dart_string(value: str) -> str:
    escaped = (
        value.replace("\\", "\\\\")
        .replace("'", "\\'")
        .replace("$", "\\$")
    )
    return f"'{escaped}'"


def unescape(value: str) -> str:
    return value.replace(r"\'", "'")


def slugify(text: str) -> str:
    text = text.lower().strip()
    text = text.replace("&", " and ")
    text = re.sub(r"[^a-z0-9]+", "_", text)
    return re.sub(r"_+", "_", text).strip("_")


def to_const_name(brand_id: str) -> str:
    parts = brand_id.split("_")
    name = "".join(p.capitalize() for p in parts) + "Models"
    # Dart identifiers cannot start with a digit (e.g. brand id "9ff").
    if name and name[0].isdigit():
        name = f"Brand{name}"
    return name


def to_file_stem(brand_id: str) -> str:
    return f"{brand_id}_models"


def parse_brands() -> list[dict]:
    src = BRANDS_PATH.read_text(encoding="utf-8")
    brand_re = re.compile(
        r"CarBrand\(\s*"
        r"id:\s*'([^']+)',\s*"
        r"nameKurdish:\s*'((?:\\'|[^'])*)',\s*"
        r"nameEnglish:\s*'((?:\\'|[^'])*)',",
        re.S,
    )
    brands = []
    for m in brand_re.finditer(src):
        brands.append(
            {
                "id": m.group(1),
                "ku": unescape(m.group(2)),
                "en": unescape(m.group(3)),
            }
        )
    return brands


def parse_existing_models() -> dict[str, list[dict]]:
    """brand_id → list of {id, ku, en, ar} from dart model files + catalog map."""
    catalog_src = CATALOG_PATH.read_text(encoding="utf-8")
    # 'toyota': toyotaModels,
    key_to_const: dict[str, str] = dict(
        re.findall(r"'([a-z0-9_]+)':\s*(\w+),", catalog_src)
    )
    const_to_models: dict[str, list[dict]] = {}
    item_re = re.compile(
        r"LocalizedCarModel\(\s*"
        r"id:\s*'([^']+)',\s*"
        r"ku:\s*'((?:\\'|[^'])*)',\s*"
        r"en:\s*'((?:\\'|[^'])*)',\s*"
        r"ar:\s*'((?:\\'|[^'])*)'\s*\)",
        re.S,
    )
    list_re = re.compile(
        r"const List<LocalizedCarModel> (\w+) = \[(.*?)\];",
        re.S,
    )
    for path in MODELS_DIR.glob("*_models.dart"):
        text = path.read_text(encoding="utf-8")
        for cm in list_re.finditer(text):
            const = cm.group(1)
            models = []
            for im in item_re.finditer(cm.group(2)):
                models.append(
                    {
                        "id": im.group(1),
                        "ku": unescape(im.group(2)),
                        "en": unescape(im.group(3)),
                        "ar": unescape(im.group(4)),
                    }
                )
            const_to_models[const] = models

    by_brand: dict[str, list[dict]] = {}
    for brand_id, const in key_to_const.items():
        by_brand[brand_id] = list(const_to_models.get(const, []))
    return by_brand


def parse_existing_trims() -> dict[str, list[str]]:
    src = TRIMS_PATH.read_text(encoding="utf-8")
    entry_re = re.compile(r"'([^']+)':\s*\[(.*?)\]", re.S)
    trim_map: dict[str, list[str]] = {}
    for match in entry_re.finditer(src):
        key = match.group(1)
        body = match.group(2)
        trims = [unescape(t) for t in re.findall(r"'((?:\\'|[^'])*)'", body)]
        if trims:
            trim_map[key] = trims
    return trim_map


def load_csv_data() -> tuple[dict[str, dict], dict[str, list[dict]], dict[str, list[str]]]:
    """
    Returns:
      brands_by_en_lower: en → {numeric_id, en, ar, ku}
      models_by_brand_en: brand_en → [{model_id, en, ar, ku}]
      trims_by_model_numeric: model_id → [trim_name]
    """
    brands_by_en: dict[str, dict] = {}
    with (DATA_DIR / "brands.csv").open(encoding="utf-8-sig") as f:
        for row in csv.DictReader(f):
            en = (row.get("brand_name_en") or "").strip()
            if not en:
                continue
            brands_by_en[en.lower()] = {
                "id": row.get("brand_id") or row.get("\ufeffbrand_id"),
                "en": en,
                "ar": (row.get("brand_name_ar") or en).strip(),
                "ku": (row.get("brand_name_ku") or en).strip(),
            }

    models_by_brand: dict[str, list[dict]] = {}
    model_meta: dict[str, dict] = {}  # numeric model_id → info
    with (DATA_DIR / "models.csv").open(encoding="utf-8-sig") as f:
        for row in csv.DictReader(f):
            if (row.get("deleted") or "").lower() == "true":
                continue
            brand_en = (row.get("brand_name_en") or "").strip()
            model_en = (row.get("model_name_en") or "").strip()
            if not brand_en or not model_en:
                continue
            mid = row.get("model_id")
            entry = {
                "numeric_id": mid,
                "en": model_en,
                "ar": (row.get("model_name_ar") or model_en).strip(),
                "ku": (row.get("model_name_ku") or model_en).strip(),
            }
            models_by_brand.setdefault(brand_en.lower(), []).append(entry)
            if mid:
                model_meta[mid] = {"brand_en": brand_en, "model_en": model_en}

    trims_by_model: dict[str, list[str]] = {}
    with (DATA_DIR / "trims.csv").open(encoding="utf-8-sig") as f:
        for row in csv.DictReader(f):
            if (row.get("deleted") or "").lower() == "true":
                continue
            mid = row.get("model_id")
            name = (row.get("trim_name") or "").strip()
            if not mid or not name:
                continue
            bucket = trims_by_model.setdefault(mid, [])
            if name not in bucket:
                bucket.append(name)

    # Also brands_models_trims.csv for extra trim rows
    bmt = DATA_DIR / "brands_models_trims.csv"
    if bmt.exists():
        with bmt.open(encoding="utf-8-sig") as f:
            for row in csv.DictReader(f):
                mid = row.get("model_id")
                name = (row.get("trim_name") or "").strip()
                if not mid or not name:
                    continue
                bucket = trims_by_model.setdefault(mid, [])
                if name not in bucket:
                    bucket.append(name)

    return brands_by_en, models_by_brand, trims_by_model, model_meta


def http_get_json(url: str, timeout: float = 30.0) -> dict:
    req = urllib.request.Request(
        url,
        headers={"User-Agent": "iqmotors-catalog-filler/1.0"},
    )
    with urllib.request.urlopen(req, timeout=timeout) as resp:
        return json.loads(resp.read().decode("utf-8"))


def fetch_nhtsa_models(make: str) -> list[str]:
    CACHE_DIR.mkdir(parents=True, exist_ok=True)
    cache_key = slugify(make) or "unknown"
    cache_file = CACHE_DIR / f"{cache_key}.json"
    if cache_file.exists():
        data = json.loads(cache_file.read_text(encoding="utf-8"))
        return data.get("models", [])

    encoded = urllib.parse.quote(make)
    url = (
        "https://vpic.nhtsa.dot.gov/api/vehicles/"
        f"GetModelsForMake/{encoded}?format=json"
    )
    try:
        payload = http_get_json(url)
    except (urllib.error.URLError, TimeoutError, json.JSONDecodeError) as exc:
        print(f"  NHTSA fail [{make}]: {exc}")
        cache_file.write_text(
            json.dumps({"make": make, "models": [], "error": str(exc)}),
            encoding="utf-8",
        )
        return []

    names: list[str] = []
    seen: set[str] = set()
    for row in payload.get("Results") or []:
        name = (row.get("Model_Name") or "").strip()
        if not name:
            continue
        key = name.lower()
        if key in seen:
            continue
        seen.add(key)
        names.append(name)

    cache_file.write_text(
        json.dumps({"make": make, "models": names}, ensure_ascii=False, indent=2),
        encoding="utf-8",
    )
    time.sleep(0.12)  # be polite to NHTSA
    return names


def nhtsa_queries_for_brand(brand: dict) -> list[str]:
    brand_id = brand["id"]
    en = brand["en"]
    queries: list[str] = []
    for q in NHTSA_MAKE_ALIASES.get(brand_id, []):
        if q not in queries:
            queries.append(q)
    if en not in queries:
        queries.append(en)
    # Drop parenthetical suffixes: "GAC Motor" → also try "GAC"
    simple = re.sub(r"\s*\(.*?\)\s*", " ", en).strip()
    if simple and simple not in queries:
        queries.append(simple)
    first = en.split()[0] if en else ""
    if first and len(first) > 2 and first not in queries:
        queries.append(first)
    return queries


def match_csv_brand_key(brand: dict, brands_by_en: dict[str, dict]) -> str | None:
    candidates = [
        brand["en"].lower(),
        brand["en"].lower().replace("-", " "),
        brand["en"].lower().replace(" motor", ""),
        brand["id"].replace("_", " "),
    ]
    for c in candidates:
        c = c.strip()
        if c in brands_by_en:
            return c
    # fuzzy: startswith / contained
    en = brand["en"].lower()
    for key in brands_by_en:
        if key == en or key.startswith(en) or en.startswith(key):
            return key
    return None


def merge_model(
    brand_id: str,
    models: list[dict],
    en: str,
    ku: str | None = None,
    ar: str | None = None,
) -> bool:
    """Append model if not present (by en/id). Returns True if added."""
    en = en.strip()
    if not en:
        return False
    model_id = f"{brand_id}_{slugify(en)}"
    existing_ids = {m["id"] for m in models}
    existing_ens = {m["en"].lower() for m in models}
    if model_id in existing_ids or en.lower() in existing_ens:
        return False
    models.append(
        {
            "id": model_id,
            "en": en,
            "ku": (ku or en).strip() or en,
            "ar": (ar or en).strip() or en,
        }
    )
    return True


def write_models_file(brand_id: str, models: list[dict]) -> Path:
    const = to_const_name(brand_id)
    path = MODELS_DIR / f"{to_file_stem(brand_id)}.dart"
    lines = [
        "import 'package:iq_motors/shared/models/localized_car_model.dart';",
        "",
        f"const List<LocalizedCarModel> {const} = [",
    ]
    # Stable sort by English name
    for m in sorted(models, key=lambda x: x["en"].lower()):
        lines.append(
            "  LocalizedCarModel("
            f"id: {dart_string(m['id'])}, "
            f"ku: {dart_string(m['ku'])}, "
            f"en: {dart_string(m['en'])}, "
            f"ar: {dart_string(m['ar'])}),"
        )
    lines.append("];")
    lines.append("")
    path.write_text("\n".join(lines), encoding="utf-8")
    return path


def write_catalog(brand_ids: list[str]) -> None:
    imports: list[str] = [
        "import 'package:iq_motors/shared/models/localized_car_model.dart';",
    ]
    for brand_id in sorted(brand_ids):
        stem = to_file_stem(brand_id)
        imports.append(
            f"import 'package:iq_motors/shared/data/car_models/{stem}.dart';"
        )

    lines = imports + [
        "",
        "/// Brand id ([CarBrand.id]) → localized model catalog.",
        "const Map<String, List<LocalizedCarModel>> carModelsCatalog = {",
    ]
    for brand_id in sorted(brand_ids):
        lines.append(f"  '{brand_id}': {to_const_name(brand_id)},")
    lines.append("};")
    lines.append("")
    CATALOG_PATH.write_text("\n".join(lines), encoding="utf-8")


def write_trims(trim_map: dict[str, list[str]]) -> None:
    lines = [
        "/// Trim / variant options keyed by catalog model id.",
        "///",
        "/// Regenerated by scratch/fill_missing_catalog_from_web.py",
        "/// Empty trim sets are omitted only when unknown — this file prefers",
        "/// Data/trims.csv, prior catalog entries, then Standard/Base/Sport/Luxury.",
        "abstract final class CarTrimsByModel {",
        "  static const Map<String, List<String>> _trimsByModelId = {",
    ]
    for model_id in sorted(trim_map.keys()):
        trims = trim_map[model_id]
        if not trims:
            continue
        lines.append(f"    {dart_string(model_id)}: [")
        for t in trims:
            lines.append(f"      {dart_string(t)},")
        lines.append("    ],")
    lines += [
        "  };",
        "",
        "  static List<String> trimsFor(String brandId, String modelId) {",
        "    final direct = _trimsByModelId[modelId];",
        "    if (direct != null && direct.isNotEmpty) return List<String>.from(direct);",
        "",
        "    final prefixed = '${brandId}_$modelId';",
        "    final viaPrefix = _trimsByModelId[prefixed];",
        "    if (viaPrefix != null && viaPrefix.isNotEmpty) {",
        "      return List<String>.from(viaPrefix);",
        "    }",
        "",
        "    // Strip duplicated brand prefix from model id.",
        "    var remaining = modelId;",
        "    final prefix = '${brandId}_';",
        "    while (remaining.startsWith(prefix)) {",
        "      remaining = remaining.substring(prefix.length);",
        "    }",
        "    if (remaining != modelId) {",
        "      final alt = _trimsByModelId['${brandId}_$remaining'];",
        "      if (alt != null && alt.isNotEmpty) return List<String>.from(alt);",
        "      final bare = _trimsByModelId[remaining];",
        "      if (bare != null && bare.isNotEmpty) return List<String>.from(bare);",
        "    }",
        "    return const [];",
        "  }",
        "}",
        "",
    ]
    # Preserve existing helper API if present — read old file for extra methods
    old = TRIMS_PATH.read_text(encoding="utf-8")
    # If old file had different public API, keep a simple compatible surface.
    # Many call sites use CarTrimsByModel.trimsFor — verify below.
    TRIMS_PATH.write_text("\n".join(lines), encoding="utf-8")
    # Restore any additional static methods from old file if we overwrote API
    if "static List<String> trimsFor" not in old and "trimsFor" in old:
        pass


def preserve_trims_api(trim_map: dict[str, list[str]]) -> None:
    """Write trims map but keep the original public API from the existing file."""
    old = TRIMS_PATH.read_text(encoding="utf-8")
    # Extract everything after the closing of _trimsByModelId map
    # Prefer: keep methods after the map by regex-replacing only the map body.
    map_match = re.search(
        r"static const Map<String, List<String>> _trimsByModelId = \{(.*?)\n  \};",
        old,
        re.S,
    )
    if not map_match:
        write_trims(trim_map)
        return

    body_lines = []
    for model_id in sorted(trim_map.keys()):
        trims = trim_map[model_id]
        if not trims:
            continue
        body_lines.append(f"    {dart_string(model_id)}: [")
        for t in trims:
            body_lines.append(f"      {dart_string(t)},")
        body_lines.append("    ],")
    new_map = (
        "static const Map<String, List<String>> _trimsByModelId = {\n"
        + "\n".join(body_lines)
        + "\n  };"
    )
    updated = old[: map_match.start()] + new_map + old[map_match.end() :]
    # Update header comment
    updated = re.sub(
        r"^///.*?(?=abstract final class CarTrimsByModel)",
        "/// Trim / variant options keyed by catalog model id.\n"
        "///\n"
        "/// Regenerated by scratch/fill_missing_catalog_from_web.py\n"
        "/// Sources: prior catalog, Data/trims.csv, default Standard/Base/Sport/Luxury.\n"
        "///\n",
        updated,
        count=1,
        flags=re.S | re.M,
    )
    TRIMS_PATH.write_text(updated, encoding="utf-8")


def main() -> None:
    brands = parse_brands()
    existing = parse_existing_models()
    existing_trims = parse_existing_trims()
    brands_by_en, csv_models, csv_trims, model_meta = load_csv_data()

    report = {
        "brandsTotal": len(brands),
        "brandsStartedWithModels": sum(1 for b in brands if existing.get(b["id"])),
        "modelsAdded": 0,
        "brandsFilledFromNhtsa": [],
        "brandsFilledFromCsv": [],
        "brandsStillEmpty": [],
        "trimsAssigned": 0,
        "trimsFromCsv": 0,
        "trimsDefaulted": 0,
    }

    # --- Fill models ---
    for brand in brands:
        brand_id = brand["id"]
        models = list(existing.get(brand_id, []))
        before = len(models)

        # 1) Data CSV models (localized)
        csv_key = match_csv_brand_key(brand, brands_by_en)
        if csv_key:
            for entry in csv_models.get(csv_key, []):
                if merge_model(
                    brand_id,
                    models,
                    entry["en"],
                    ku=entry.get("ku"),
                    ar=entry.get("ar"),
                ):
                    report["modelsAdded"] += 1
            if len(models) > before:
                report["brandsFilledFromCsv"].append(brand_id)

        # 2) NHTSA models (English only → use EN for ku/ar if missing)
        before_nhtsa = len(models)
        for query in nhtsa_queries_for_brand(brand):
            for name in fetch_nhtsa_models(query):
                # Skip junk / overly long VIN-ish rows
                if len(name) > 60:
                    continue
                if merge_model(brand_id, models, name):
                    report["modelsAdded"] += 1
        if len(models) > before_nhtsa:
            report["brandsFilledFromNhtsa"].append(brand_id)

        existing[brand_id] = models
        if not models:
            report["brandsStillEmpty"].append(
                {"id": brand_id, "en": brand["en"]}
            )

    # Write all model files + catalog for brands that have ≥1 model
    brands_with_models = [b["id"] for b in brands if existing.get(b["id"])]
    for brand_id in brands_with_models:
        write_models_file(brand_id, existing[brand_id])
    write_catalog(brands_with_models)

    # --- Fill trims ---
    # Build lookup: (brand_en_lower, model_en_lower) → numeric model ids
    numeric_by_brand_model: dict[tuple[str, str], str] = {}
    for brand_en, entries in csv_models.items():
        for entry in entries:
            key = (brand_en, entry["en"].lower())
            if entry.get("numeric_id"):
                numeric_by_brand_model[key] = entry["numeric_id"]

    trim_map: dict[str, list[str]] = dict(existing_trims)

    for brand in brands:
        brand_id = brand["id"]
        csv_key = match_csv_brand_key(brand, brands_by_en)
        for model in existing.get(brand_id, []):
            model_id = model["id"]
            # Keep existing trims
            if trim_map.get(model_id):
                continue

            # CSV trims via numeric model id
            found: list[str] = []
            if csv_key:
                mid = numeric_by_brand_model.get((csv_key, model["en"].lower()))
                if mid and csv_trims.get(mid):
                    found = list(csv_trims[mid])
                    report["trimsFromCsv"] += 1

            if found:
                trim_map[model_id] = found
                report["trimsAssigned"] += 1
            else:
                trim_map[model_id] = list(DEFAULT_TRIMS)
                report["trimsDefaulted"] += 1
                report["trimsAssigned"] += 1

    preserve_trims_api(trim_map)

    REPORT_PATH.parent.mkdir(parents=True, exist_ok=True)
    REPORT_PATH.write_text(
        json.dumps(report, ensure_ascii=False, indent=2),
        encoding="utf-8",
    )

    print("=== Catalog fill complete ===")
    print(f"brands: {report['brandsTotal']}")
    print(f"started with models: {report['brandsStartedWithModels']}")
    print(f"models added: {report['modelsAdded']}")
    print(f"brands with models now: {len(brands_with_models)}")
    print(f"still empty: {len(report['brandsStillEmpty'])}")
    print(f"trims assigned: {report['trimsAssigned']} "
          f"(csv={report['trimsFromCsv']}, default={report['trimsDefaulted']})")
    print(f"report: {REPORT_PATH}")


if __name__ == "__main__":
    main()
