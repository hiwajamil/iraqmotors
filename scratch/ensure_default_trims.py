"""Ensure every catalogued model id has at least default trims."""

from __future__ import annotations

import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "scratch"))

from fill_missing_catalog_from_web import (  # noqa: E402
    DEFAULT_TRIMS,
    parse_brands,
    parse_existing_models,
    parse_existing_trims,
    preserve_trims_api,
)

def main() -> None:
    brands = parse_brands()
    models = parse_existing_models()
    trims = parse_existing_trims()
    added = 0
    for brand in brands:
        for model in models.get(brand["id"], []):
            mid = model["id"]
            if not trims.get(mid):
                trims[mid] = list(DEFAULT_TRIMS)
                added += 1
    preserve_trims_api(trims)
    print(f"default trims added for {added} models; total keys {len(trims)}")


if __name__ == "__main__":
    main()
