"""Export app brand / model / trim catalogs to a single JSON file."""

from __future__ import annotations

import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
OUT_PATH = ROOT / "brands_models_trims.json"
LOGO_CDN = (
    "https://cdn.jsdelivr.net/gh/filippofilip95/"
    "car-logos-dataset@master/logos/optimized"
)


def unescape(value: str) -> str:
    return value.replace(r"\'", "'")


def parse_brands(src: str) -> list[dict]:
    brand_re = re.compile(
        r"CarBrand\(\s*"
        r"id:\s*'([^']+)',\s*"
        r"nameKurdish:\s*'((?:\\'|[^'])*)',\s*"
        r"nameEnglish:\s*'((?:\\'|[^'])*)',\s*"
        r"logoUrl:\s*'((?:\\'|[^'])*)',?\s*\)",
        re.S,
    )
    brands = []
    for match in brand_re.finditer(src):
        logo = unescape(match.group(4)).replace("$_logoCdn", LOGO_CDN)
        brands.append(
            {
                "id": match.group(1),
                "nameKurdish": unescape(match.group(2)),
                "nameEnglish": unescape(match.group(3)),
                "logoUrl": logo,
            }
        )
    return brands


def parse_trims(src: str) -> dict[str, list[str]]:
    entry_re = re.compile(r"'([^']+)':\s*\[(.*?)\]", re.S)
    trim_map: dict[str, list[str]] = {}
    for match in entry_re.finditer(src):
        key = match.group(1)
        body = match.group(2)
        trims = [unescape(t) for t in re.findall(r"'((?:\\'|[^'])*)'", body)]
        trim_map[key] = trims
    return trim_map


def resolve_trims(
    brand_id: str, model_id: str, trim_map: dict[str, list[str]]
) -> tuple[list[str], str | None]:
    candidates = [f"{brand_id}_{model_id}"]
    prefix = f"{brand_id}_"
    remaining = model_id
    while remaining.startswith(prefix):
        remaining = remaining[len(prefix) :]
        if not remaining:
            break
        candidates.append(f"{brand_id}_{remaining}")
    if model_id in trim_map:
        candidates.append(model_id)

    seen: set[str] = set()
    for key in candidates:
        if key in seen:
            continue
        seen.add(key)
        if key in trim_map:
            return trim_map[key], key
    return [], None


def parse_model_consts(models_dir: Path) -> dict[str, list[dict]]:
    model_file_re = re.compile(
        r"const List<LocalizedCarModel> (\w+) = \[(.*?)\];", re.S
    )
    model_item_re = re.compile(
        r"LocalizedCarModel\(\s*"
        r"id:\s*'([^']+)',\s*"
        r"ku:\s*'((?:\\'|[^'])*)',\s*"
        r"en:\s*'((?:\\'|[^'])*)',\s*"
        r"ar:\s*'((?:\\'|[^'])*)',?\s*\)",
        re.S,
    )
    const_models: dict[str, list[dict]] = {}
    for path in models_dir.glob("*_models.dart"):
        text = path.read_text(encoding="utf-8")
        for cm in model_file_re.finditer(text):
            const_name = cm.group(1)
            body = cm.group(2)
            items = []
            for im in model_item_re.finditer(body):
                items.append(
                    {
                        "id": im.group(1),
                        "ku": unescape(im.group(2)),
                        "en": unescape(im.group(3)),
                        "ar": unescape(im.group(4)),
                    }
                )
            const_models[const_name] = items
    return const_models


def parse_catalog(src: str) -> dict[str, str]:
    catalog_map: dict[str, str] = {}
    for match in re.finditer(r"'([^']+)':\s*(\w+),", src):
        brand_id, const_name = match.group(1), match.group(2)
        if const_name.endswith("Models"):
            catalog_map[brand_id] = const_name
    return catalog_map


def main() -> None:
    brands_src = (ROOT / "lib/shared/data/dummy_brands.dart").read_text(
        encoding="utf-8"
    )
    trims_src = (ROOT / "lib/shared/data/car_trims_by_model.dart").read_text(
        encoding="utf-8"
    )
    catalog_src = (ROOT / "lib/shared/data/car_models/catalog.dart").read_text(
        encoding="utf-8"
    )
    models_dir = ROOT / "lib/shared/data/car_models"

    brands = parse_brands(brands_src)
    trim_map = parse_trims(trims_src)
    const_models = parse_model_consts(models_dir)
    catalog_map = parse_catalog(catalog_src)

    brand_by_id = {b["id"]: b for b in brands}
    result_brands: list[dict] = []
    stats = {
        "brands": 0,
        "brandsWithModels": 0,
        "models": 0,
        "modelsWithTrims": 0,
        "trimEntries": 0,
        "uniqueTrimCatalogKeys": len(trim_map),
    }

    def build_models(brand_id: str) -> list[dict]:
        const_name = catalog_map.get(brand_id, "")
        models_raw = const_models.get(const_name, [])
        models_out = []
        for model in models_raw:
            trims, matched_key = resolve_trims(brand_id, model["id"], trim_map)
            models_out.append(
                {
                    "id": model["id"],
                    "name": {
                        "ku": model["ku"],
                        "en": model["en"],
                        "ar": model["ar"],
                    },
                    "trims": trims,
                    "trimLookupKey": matched_key,
                }
            )
            stats["models"] += 1
            if trims:
                stats["modelsWithTrims"] += 1
                stats["trimEntries"] += len(trims)
        return models_out

    for brand in brands:
        bid = brand["id"]
        models_out = build_models(bid)
        result_brands.append(
            {
                "id": bid,
                "name": {
                    "ku": brand["nameKurdish"],
                    "en": brand["nameEnglish"],
                },
                "logoUrl": brand["logoUrl"],
                "models": models_out,
            }
        )
        stats["brands"] += 1
        if models_out:
            stats["brandsWithModels"] += 1

    for bid in catalog_map:
        if bid in brand_by_id:
            continue
        models_out = build_models(bid)
        result_brands.append(
            {
                "id": bid,
                "name": {"ku": bid, "en": bid},
                "logoUrl": None,
                "models": models_out,
            }
        )
        stats["brands"] += 1
        if models_out:
            stats["brandsWithModels"] += 1

    payload = {
        "generatedFrom": "iqmotors.net app catalogs",
        "sourceFiles": [
            "lib/shared/data/dummy_brands.dart",
            "lib/shared/data/car_models/",
            "lib/shared/data/car_trims_by_model.dart",
        ],
        "stats": stats,
        "brands": result_brands,
    }

    OUT_PATH.write_text(
        json.dumps(payload, ensure_ascii=False, indent=2), encoding="utf-8"
    )
    print(json.dumps(stats, indent=2))
    print(f"Wrote {OUT_PATH}")
    print(f"Size MB: {round(OUT_PATH.stat().st_size / 1024 / 1024, 2)}")


if __name__ == "__main__":
    main()
