import json
from pathlib import Path

catalog = json.loads(Path("final_iqmotors_catalog.json").read_text(encoding="utf-8"))
src = Path("lib/shared/data/car_trims_by_model.dart").read_text(encoding="utf-8")

missing = []
for brand in catalog["brands"]:
    for model in brand["models"]:
        trims = model.get("trims") or []
        if not trims:
            continue
        key = model.get("trimLookupKey") or model["id"]
        needle = f"'{key}':"
        if needle not in src:
            missing.append((brand["id"], model["id"], key))

print("missing keys:", len(missing))
print("sample:", missing[:10])
print("has toyota_camry:", "'toyota_camry':" in src)
print("has kia_k900:", "'kia_k900':" in src)
print("has kia_kia_k900:", "'kia_kia_k900':" in src)
