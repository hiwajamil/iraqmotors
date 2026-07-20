"""Pass 3: curated models for remaining niche / historic brands."""

from __future__ import annotations

import json
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
)

CURATED: dict[str, list[str]] = {
    "camc": ["Hanma", "H7", "H9", "M3", "S3"],
    "zinoro": ["1E", "60H", "C1"],
    "hiphi": ["X", "Z", "Y", "A"],
    "atalanta": ["Sports", "AM"],
    "bowler": ["Wildcat", "Nemesis", "CSP 575", "Bulldog"],
    "bufori": ["Geneva", "La Joya", "BMS V8", "MKII"],
    "changfeng": ["Liebao", "CS6", "CS7", "Flying"],
    "dartz": ["Prombron", "Kombat"],
    "edag": ["Light Cocoon", "Genesis", "No.8"],
    "eterniti": ["Hetiara", "Artes"],
    "facel_vega": ["HK500", "Facel II", "Excellence", "Facellia"],
    "fpv": ["GT", "F6", "Pursuit", "Super Pursuit", "GS"],
    "landwind": ["X5", "X6", "X7", "Xiaoyao", "Xiaoshuai"],
    "lobini": ["H1", "T1"],
    "spirra": ["S", "Wraith"],
    "venucia": ["D60", "T60", "T70", "T90", "VX6", "V-Online", "Star"],
    "wiesmann": ["MF3", "MF4", "MF5", "GT MF4", "GT MF5"],
    "abadal": ["Buick", "Y-Series"],
    "abbott_detroit": ["Model 34", "Limousine"],
    "askam": ["AS 250", "AS 950", "AS 1200"],
    "autobianchi": ["A112", "Y10", "Primula", "Bianchina"],
    "berliet": ["GR", "GBC", "T100", "Stradair"],
    "bizzarrini": ["5300 GT", "P538", "Giotto"],
    "brooke": ["Double Six", "Austin"],
    "cisitalia": ["202", "204", "360"],
    "cizeta": ["V16T", "Moroder"],
    "diatto": ["Tipo 20", "Tipo 30"],
    "dkw": ["F102", "Junior", "3=6", "Sonderklasse"],
    "elva": ["Courier", "Mk VII", "GT160"],
    "englon": ["SC5-RV", "SX7", "SC6", "SC7"],
    "fioravanti": ["F100", "Hidra", "Thalia"],
    "foden": ["Alpha", "C Series", "S21"],
    "gilbern": ["GT", "Genie", "Invader"],
    "gillet": ["Vertigo", "Arena"],
    "gonow": ["Troy", "GX6", "Aoosed", "Xinglang"],
    "hispano_suiza": ["Carmen", "J12", "H6", "Alfonso"],
    "hommell": ["Barchetta", "Berlinette", "RS"],
    "horch": ["830", "853", "930", "850"],
    "innocenti": ["Mini", "Elba", "950", "Spyder"],
    "intermeccanica": ["Italia", "Indra", "Apollo", "Murena"],
    "isdera": ["Imperator 108i", "Commendatore 112i", "Spyder"],
    "marcos": ["Mantara", "Mantis", "LM500", "GT"],
    "mastretta": ["MXT"],
    "pegaso": ["Z-102", "Z-103", "Thrill"],
    "pgo": ["Celebra", "Speedster II", "Hemera", "Cévennes"],
    "pierce_arrow": ["Model 66", "Silver Arrow", "Model 1240"],
    "rinspeed": ["sQuba", "Oasis", "Budii", "Etos"],
    "ronart": ["Lightning", "W152"],
    "vandenbrink": ["Carver", "XCR"],
    "venturi": ["Atlantis", "400 GT", "Fetish", "America"],
    "wanderer": ["W24", "W25", "W51"],
    "willys_overland": ["Jeep MB", "CJ-2A", "CJ-3A", "Wagon", "Aero"],
}


def main() -> None:
    brands = parse_brands()
    existing = parse_existing_models()
    existing_trims = parse_existing_trims()

    added = 0
    filled = []
    for brand in brands:
        brand_id = brand["id"]
        models = list(existing.get(brand_id, []))
        if models:
            existing[brand_id] = models
            continue
        for name in CURATED.get(brand_id, []):
            if merge_model(brand_id, models, name):
                added += 1
        existing[brand_id] = models
        if models:
            filled.append(brand_id)

    brands_with = [b["id"] for b in brands if existing.get(b["id"])]
    still = [b for b in brands if not existing.get(b["id"])]

    for brand_id in brands_with:
        write_models_file(brand_id, existing[brand_id])
    write_catalog(brands_with)

    trim_map = dict(existing_trims)
    for brand in brands:
        for model in existing.get(brand["id"], []):
            if not trim_map.get(model["id"]):
                trim_map[model["id"]] = list(DEFAULT_TRIMS)
    preserve_trims_api(trim_map)

    print(f"models added: {added}")
    print(f"newly filled: {len(filled)}")
    print(f"brands with models: {len(brands_with)} / {len(brands)}")
    print(f"still empty: {len(still)}")
    if still:
        print([b["en"] for b in still])


if __name__ == "__main__":
    main()
