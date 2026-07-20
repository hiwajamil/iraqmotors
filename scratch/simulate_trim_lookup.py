"""Simulate CarTrimsByModel.trimsFor against the live model catalog."""

from __future__ import annotations

import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def parse_trim_map(src: str) -> dict[str, list[str]]:
    entry_re = re.compile(r"'([^']+)':\s*\[(.*?)\]", re.S)
    trim_map: dict[str, list[str]] = {}
    for match in entry_re.finditer(src):
        key = match.group(1)
        body = match.group(2)
        trims = re.findall(r"'((?:\\'|[^'])*)'", body)
        trim_map[key] = trims
    return trim_map


def trims_for(brand_id: str, model_key: str, trim_map: dict[str, list[str]]) -> list[str]:
    candidates = [f"{brand_id}_{model_key}"]
    prefix = f"{brand_id}_"
    remaining = model_key
    while remaining.startswith(prefix):
        remaining = remaining[len(prefix) :]
        if not remaining:
            break
        candidates.append(f"{brand_id}_{remaining}")
    for key in candidates:
        if key in trim_map:
            return trim_map[key]
    return []


def parse_models() -> dict[str, list[str]]:
    catalog_src = (ROOT / "lib/shared/data/car_models/catalog.dart").read_text(
        encoding="utf-8"
    )
    models_dir = ROOT / "lib/shared/data/car_models"
    const_models: dict[str, list[str]] = {}
    model_file_re = re.compile(
        r"const List<LocalizedCarModel> (\w+) = \[(.*?)\];", re.S
    )
    id_re = re.compile(r"id:\s*'([^']+)'")
    for path in models_dir.glob("*_models.dart"):
        text = path.read_text(encoding="utf-8")
        for cm in model_file_re.finditer(text):
            const_models[cm.group(1)] = id_re.findall(cm.group(2))

    catalog: dict[str, list[str]] = {}
    for match in re.finditer(r"'([^']+)':\s*(\w+),", catalog_src):
        brand_id, const_name = match.group(1), match.group(2)
        if const_name.endswith("Models"):
            catalog[brand_id] = const_models.get(const_name, [])
    return catalog


def main() -> None:
    trim_src = (ROOT / "lib/shared/data/car_trims_by_model.dart").read_text(
        encoding="utf-8"
    )
    trim_map = parse_trim_map(trim_src)
    models = parse_models()

    hit = 0
    miss = 0
    miss_samples = []
    for brand_id, model_ids in models.items():
        for model_id in model_ids:
            found = trims_for(brand_id, model_id, trim_map)
            if found:
                hit += 1
            else:
                miss += 1
                if len(miss_samples) < 25:
                    miss_samples.append((brand_id, model_id))

    print(f"trim keys: {len(trim_map)}")
    print(f"models hit: {hit}")
    print(f"models miss: {miss}")
    print("miss samples:")
    for s in miss_samples:
        print(" ", s)

    # popular checks
    for brand, model in [
        ("toyota", "toyota_camry"),
        ("toyota", "toyota_corolla"),
        ("kia", "kia_sportage"),
        ("audi", "a3"),
        ("hyundai", "hyundai_tucson"),
        ("mercedes_benz", "mercedes_benz_mb_c_class"),
    ]:
        print(brand, model, "->", trims_for(brand, model, trim_map)[:5])


if __name__ == "__main__":
    main()
