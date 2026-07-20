"""Fix invalid Dart const names (e.g. 9ff) and restore Mercedes mb_* ids."""

from __future__ import annotations

import re
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "scratch"))

from fill_missing_catalog_from_web import (  # noqa: E402
    parse_brands,
    parse_existing_models,
    write_models_file,
    write_catalog,
    to_const_name,
)

MODELS_DIR = ROOT / "lib" / "shared" / "data" / "car_models"
ITEM_RE = re.compile(
    r"LocalizedCarModel\(\s*"
    r"id:\s*'([^']+)',\s*"
    r"ku:\s*'((?:\\'|[^'])*)',\s*"
    r"en:\s*'((?:\\'|[^'])*)',\s*"
    r"ar:\s*'((?:\\'|[^'])*)'\s*\)",
    re.S,
)


def unescape(value: str) -> str:
    return value.replace(r"\'", "'")


def parse_models_from_text(text: str) -> list[dict]:
    models = []
    for im in ITEM_RE.finditer(text):
        models.append(
            {
                "id": im.group(1),
                "ku": unescape(im.group(2)),
                "en": unescape(im.group(3)),
                "ar": unescape(im.group(4)),
            }
        )
    return models


def main() -> None:
    brands = parse_brands()
    existing = parse_existing_models()

    # Reload 9ff from broken file (const name not parseable via catalog)
    nine = MODELS_DIR / "9ff_models.dart"
    if nine.exists():
        existing["9ff"] = parse_models_from_text(nine.read_text(encoding="utf-8"))
        print("9ff models:", len(existing["9ff"]), "const:", to_const_name("9ff"))

    # Restore Mercedes from git HEAD, keep extra models not in HEAD
    head = subprocess.check_output(
        ["git", "show", "HEAD:lib/shared/data/car_models/mercedes_benz_models.dart"],
        cwd=ROOT,
        text=True,
        encoding="utf-8",
    )
    restored = parse_models_from_text(head)
    current = existing.get("mercedes_benz", [])
    ens = {m["en"].lower() for m in restored}
    extras = 0
    for m in current:
        if m["en"].lower() in ens:
            continue
        restored.append(m)
        extras += 1
    existing["mercedes_benz"] = restored
    print(f"mercedes restored={len(parse_models_from_text(head))} extras={extras} total={len(restored)}")

    brand_ids = [b["id"] for b in brands if existing.get(b["id"])]
    for brand_id in brand_ids:
        write_models_file(brand_id, existing[brand_id])
    write_catalog(brand_ids)

    print("rewrote", len(brand_ids), "model files + catalog")
    print(nine.read_text(encoding="utf-8")[:180])
    # sanity: catalog must not contain bare 9ffModels
    cat = (MODELS_DIR / "catalog.dart").read_text(encoding="utf-8")
    assert "Brand9ffModels" in cat
    assert ": 9ffModels" not in cat
    print("catalog 9ff entry OK")


if __name__ == "__main__":
    main()
