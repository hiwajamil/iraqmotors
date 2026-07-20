"""
Second pass: fill remaining empty brands from vehiclesdb (CC-BY 4.0)
plus curated known model lists and extra NHTSA aliases.

Re-runs model file + catalog + trim default assignment for newly filled brands.
"""

from __future__ import annotations

import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "scratch"))

from fill_missing_catalog_from_web import (  # noqa: E402
    DEFAULT_TRIMS,
    parse_brands,
    parse_existing_models,
    parse_existing_trims,
    merge_model,
    write_models_file,
    write_catalog,
    preserve_trims_api,
    slugify,
    fetch_nhtsa_models,
)

VDB_PATH = ROOT / ".tmp_pdf_preview" / "external_car_data" / "vdb.json"
REPORT_PATH = ROOT / ".tmp_pdf_preview" / "catalog_fill_pass2_report.json"

# Extra make aliases for empty brands → NHTSA / vehiclesdb name keys
EXTRA_ALIASES: dict[str, list[str]] = {
    "vauxhall": ["Vauxhall"],
    "abarth": ["Abarth", "Fiat"],
    "dacia": ["Dacia", "Renault"],
    "alpina": ["Alpina", "BMW"],
    "brabus": ["Brabus", "Mercedes-Benz"],
    "jetta": ["Jetta", "Volkswagen"],
    "saic_motor": ["SAIC", "MG", "Roewe"],
    "faraday_future": ["Faraday Future", "FF"],
    "de_tomaso": ["De Tomaso", "DeTomaso"],
    "perodua": ["Perodua"],
    "tvr": ["TVR"],
    "zenvo": ["Zenvo"],
    "arcfox": ["Arcfox", "BAIC"],
    "li_auto": ["Li Auto", "Li", "Lixiang"],
    "weltmeister": ["Weltmeister"],
    "nevs": ["NEVS", "Saab"],
    "geometry": ["Geometry", "Geely"],
    "aixam": ["Aixam"],
    "baojun": ["Baojun", "Wuling"],
    "caterham": ["Caterham"],
    "hsv": ["HSV", "Holden"],
    "kamaz": ["Kamaz"],
    "ligier": ["Ligier"],
    "luxgen": ["Luxgen"],
    "qoros": ["Qoros"],
    "w_motors": ["W Motors"],
    "sinotruk_cnhtc": ["Sinotruk", "CNHTC"],
    "shacman": ["Shacman", "Shaanxi"],
    "hongyan": ["Hongyan"],
    "beiben": ["BeiBen", "Beiben"],
    "hennessey": ["Hennessey"],
    "eicher": ["Eicher"],
    "paccar": ["Peterbilt", "Kenworth"],
    "bharatbenz": ["BharatBenz", "Mercedes-Benz"],
    "hindustan_motors": ["Hindustan"],
    "man": ["MAN"],
    "scania": ["Scania"],
    "irizar": ["Irizar"],
}

# Curated models when datasets miss the brand entirely (Iraq-relevant / well-known).
CURATED: dict[str, list[str]] = {
    "dacia": ["Sandero", "Duster", "Logan", "Jogger", "Spring", "Lodgy", "Dokker", "Lodgy Stepway"],
    "abarth": ["500", "595", "695", "124 Spider", "Punto", "Grande Punto"],
    "alpina": ["B3", "B4", "B5", "B6", "B7", "B8", "D3", "D4", "D5", "XB7", "XD3", "XD4"],
    "li_auto": ["L6", "L7", "L8", "L9", "MEGA", "One"],
    "baojun": ["510", "530", "730", "E300", "RS-3", "RS-5", "RC-5", "KiWi EV"],
    "perodua": ["Myvi", "Axia", "Bezza", "Alza", "Ativa", "Aruz"],
    "luxgen": ["U6", "U7", "S3", "S5", "M7", "U5"],
    "qoros": ["3", "5", "7"],
    "geometry": ["A", "C", "E", "G6", "M6"],
    "arcfox": ["Alpha S", "Alpha T", "Kaola"],
    "weltmeister": ["EX5", "EX6", "W6", "Maven"],
    "nevs": ["9-3", "Emily GT"],
    "vauxhall": ["Corsa", "Astra", "Insignia", "Mokka", "Crossland", "Grandland", "Combo", "Vivaro", "Movano"],
    "caterham": ["Seven", "Twenty One", "CSR"],
    "tvr": ["Griffith", "Chimaera", "Cerbera", "Tuscan", "Sagaris", "Tamora"],
    "zenvo": ["ST1", "TS1", "TSR-S", "Aurora"],
    "w_motors": ["Lykan Hypersport", "Fenyr SuperSport"],
    "brabus": ["G-Class", "S-Class", "E-Class", "C-Class", "GLS", "GT"],
    "jetta": ["VS5", "VS7", "VA3", "VA7"],
    "hennessey": ["Venom F5", "Venom GT", "Mammoth", "VelociRaptor"],
    "aixam": ["City", "Coupe", "Crossline", "Crossover", "e-City"],
    "ligier": ["JS50", "JS60", "Myli", "Pulse"],
    "hsv": ["Clubsport", "GTS", "Maloo", "Senator", "Grange"],
    "kamaz": ["43118", "53212", "5490", "65115", "6520"],
    "shacman": ["F3000", "X3000", "H3000", "L3000"],
    "sinotruk_cnhtc": ["Howo", "Sitrak", "Steyr"],
    "hongyan": ["Genlyon", "Jieshi", "Jingang"],
    "beiben": ["V3", "NG80", "North Benz"],
    "eicher": ["Pro 1049", "Pro 2049", "Pro 3015", "Pro 6028"],
    "bharatbenz": ["1217C", "1617R", "2823C", "3123R", "4828R"],
    "faraday_future": ["FF 91", "FF 91 2.0"],
    "de_tomaso": ["Pantera", "Mangusta", "P72", "Guarà"],
    "paccar": ["Peterbilt 579", "Kenworth T680", "DAF XF"],
    "saic_motor": ["MG4", "MG5", "MG ZS", "Roewe RX5", "Maxus G10"],
    "mansory": ["Carbonado", "Cyrus", "Le Mansory", "G63"],
    "techart": ["GTstreet", "Magnum", "Carrera"],
    "carlsson": ["C25", "CK63", "Aigner"],
    "arrival": ["Van", "Bus", "Car"],
    "rezvani": ["Tank", "Beast", "Vengeance", "Hercules"],
    "gumpert": ["Apollo", "Explosion"],
    "artega": ["GT", "Scalo"],
    "trion": ["Nemesis"],
    "arrinera": ["Hussarya"],
    "mazzanti": ["Evantra"],
    "keating": ["Bolt", "Berucci"],
    "caparo": ["T1"],
    "ginetta": ["G40", "G55", "Akula"],
    "melkus": ["RS 1000", "RS2000"],
    "praga": ["Bohema", "R1", "V4S"],
    "prodrive": ["P25", "Hunter"],
    "osca": ["MT4", "2000 S"],
    "oltcit": ["Club", "Special"],
    "microcar": ["M.Go", "Virgo", "Due"],
    "autobics": ["Garaiya"],
    "autobacs": ["Garaiya"],
    "edsel": ["Citation", "Corsair", "Pacer", "Ranger", "Villager"],
    "stutz": ["Bearcat", "Blackhawk", "DV-32"],
    "tucker": ["48"],
    "tatra": ["T613", "T700", "T815", "Phoenix"],
    "troller": ["T4"],
    "sisu": ["Polar", "Kontio", "Rock"],
    "lagonda": ["Taraf", "Rapide", "Vision Concept"],
    "ascari": ["A10", "KZ1", "Ecosse"],
    "spania_gta": ["Spano"],
    "tramontana": ["R", "XTR"],
    "arash": ["AF10", "AF8", "Fachion"],
    "vencer": ["Sarthe"],
    "vlf": ["Force 1", "Rocket"],
    "elemental": ["RP1"],
    "suffolk": ["GTO", "SS100"],
    "rossion": ["Q1"],
    "laraki": ["Fulgura", "Epitome"],
    "duesenberg": ["Model J", "Model A", "SJ"],
    "zarooq_motors": ["Sandracer"],
    "zenos": ["E10"],
    "yulon": ["Feeling", "Arex"],
    "singulato": ["iS6", "iC3"],
    "grinnall": ["Scorpion", "Rocket"],
    "9ff": ["GT9", "GTurbo"],
    "hindustan_motors": ["Ambassador", "Contessa", "Trekker"],
    "packard": ["One Twenty", "Caribbean", "Clipper", "Twelve"],
}


def normalize_name(name: str) -> str:
    return re.sub(r"[^a-z0-9]+", "", name.lower())


def build_vdb_index(path: Path) -> dict[str, list[str]]:
    data = json.loads(path.read_text(encoding="utf-8"))
    index: dict[str, list[str]] = {}
    for make in data.get("makes") or []:
        name = make.get("name") or ""
        slug = make.get("slug") or ""
        models = []
        for m in make.get("models") or []:
            # prefer car/van/truck/bus; vehiclesdb uses singular "kind"
            kind = m.get("kind")
            make_kinds = set(make.get("kinds") or [])
            if kind:
                if kind not in {"car", "van", "truck", "bus"}:
                    continue
            elif make_kinds and not make_kinds.intersection(
                {"car", "van", "truck", "bus"}
            ):
                continue
            mn = m.get("name") or ""
            if mn:
                models.append(mn)
        if not models:
            continue
        for key in {normalize_name(name), normalize_name(slug), name.lower(), slug.lower()}:
            if key:
                index.setdefault(key, [])
                # merge unique
                seen = {x.lower() for x in index[key]}
                for mn in models:
                    if mn.lower() not in seen:
                        index[key].append(mn)
                        seen.add(mn.lower())
    return index


def main() -> None:
    brands = parse_brands()
    existing = parse_existing_models()
    existing_trims = parse_existing_trims()
    vdb = build_vdb_index(VDB_PATH) if VDB_PATH.exists() else {}

    report = {
        "filled": [],
        "stillEmpty": [],
        "modelsAdded": 0,
        "sources": {},
    }

    for brand in brands:
        brand_id = brand["id"]
        models = list(existing.get(brand_id, []))
        if models:
            existing[brand_id] = models
            continue

        added_from: list[str] = []

        # Curated
        for name in CURATED.get(brand_id, []):
            if merge_model(brand_id, models, name):
                report["modelsAdded"] += 1
                added_from.append("curated")

        # vehiclesdb
        keys = [
            normalize_name(brand["en"]),
            normalize_name(brand_id),
            brand["en"].lower(),
            brand_id.replace("_", " ").lower(),
        ]
        for alias in EXTRA_ALIASES.get(brand_id, []):
            keys.append(normalize_name(alias))
            keys.append(alias.lower())
        for key in keys:
            for name in vdb.get(key, []):
                if merge_model(brand_id, models, name):
                    report["modelsAdded"] += 1
                    added_from.append("vehiclesdb")

        # Extra NHTSA aliases
        for alias in EXTRA_ALIASES.get(brand_id, []):
            for name in fetch_nhtsa_models(alias):
                if len(name) > 60:
                    continue
                if merge_model(brand_id, models, name):
                    report["modelsAdded"] += 1
                    added_from.append("nhtsa")

        existing[brand_id] = models
        if models:
            report["filled"].append(brand_id)
            report["sources"][brand_id] = sorted(set(added_from))
        else:
            report["stillEmpty"].append({"id": brand_id, "en": brand["en"]})

    brands_with_models = [b["id"] for b in brands if existing.get(b["id"])]
    for brand_id in brands_with_models:
        # Only rewrite newly filled + ensure all exist
        write_models_file(brand_id, existing[brand_id])
    write_catalog(brands_with_models)

    # Assign default trims for any model still missing trims
    trim_map = dict(existing_trims)
    for brand in brands:
        brand_id = brand["id"]
        for model in existing.get(brand_id, []):
            mid = model["id"]
            if not trim_map.get(mid):
                trim_map[mid] = list(DEFAULT_TRIMS)
    preserve_trims_api(trim_map)

    REPORT_PATH.write_text(json.dumps(report, ensure_ascii=False, indent=2), encoding="utf-8")
    print("=== Pass 2 complete ===")
    print(f"models added: {report['modelsAdded']}")
    print(f"brands newly filled: {len(report['filled'])}")
    print(f"brands with models: {len(brands_with_models)} / {len(brands)}")
    print(f"still empty: {len(report['stillEmpty'])}")
    if report["stillEmpty"]:
        print("remaining:", [x["en"] for x in report["stillEmpty"][:40]])
    print(f"report: {REPORT_PATH}")


if __name__ == "__main__":
    main()
