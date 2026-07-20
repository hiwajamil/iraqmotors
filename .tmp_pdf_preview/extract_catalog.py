import re, json
from pathlib import Path

models_dir = Path(r"c:\project\iqmotors.net\lib\shared\data\car_models")
catalog = (models_dir / "catalog.dart").read_text(encoding="utf-8")

brand_to_var = {}
for m in re.finditer(r"'([^']+)'\s*:\s*(\w+Models)", catalog):
    brand_to_var[m.group(1)] = m.group(2)

var_to_models = {}
for f in models_dir.glob("*_models.dart"):
    text = f.read_text(encoding="utf-8")
    lm = re.search(r"const List<LocalizedCarModel>\s+(\w+)\s*=", text)
    if not lm:
        continue
    var = lm.group(1)
    entries = []
    for block in re.finditer(r"LocalizedCarModel\((.*?)\)\s*,", text, re.S):
        body = block.group(1)
        idm = re.search(r"id:\s*'([^']+)'", body)
        enm = re.search(r"en:\s*'([^']*)'", body)
        if idm and enm:
            entries.append({"id": idm.group(1), "en": enm.group(1)})
    var_to_models[var] = entries

brand_models = {
    brand: var_to_models.get(var, []) for brand, var in brand_to_var.items()
}

out = Path(r"c:\project\iqmotors.net\.tmp_pdf_preview\catalog_models.json")
out.write_text(json.dumps(brand_models, ensure_ascii=False, indent=2), encoding="utf-8")
print("brands", len(brand_models))
print("models", sum(len(v) for v in brand_models.values()))
