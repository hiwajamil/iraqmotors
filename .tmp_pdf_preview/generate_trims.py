import ast
import json
import re
from collections import defaultdict
from difflib import SequenceMatcher
from pathlib import Path

ROOT = Path(r"c:\project\iqmotors.net")
SOURCE = Path(
    r"c:\Users\HEWA\.gemini\antigravity\brain"
    r"\87ac9e9e-dd7e-4d96-a872-ccceef381cbe"
    r"\iqmotors_all_brands_models_trims.json"
)
CATALOG = ROOT / ".tmp_pdf_preview" / "catalog_models.json"
PDF_TRIMS = ROOT / ".tmp_pdf_preview" / "toyota_kia_specs_from_pdfs.json"
CURRENT = ROOT / "lib" / "shared" / "data" / "car_trims_by_model.dart"
OUTPUT = CURRENT
REPORT = ROOT / ".tmp_pdf_preview" / "trim_import_report.json"


def normalized(value: str) -> str:
    return re.sub(r"[^a-z0-9]+", "", value.casefold())


def dart_strings(value: str) -> list[str]:
    return [
        ast.literal_eval(match.group(0))
        for match in re.finditer(r"'(?:\\.|[^'\\])*'", value)
    ]


def existing_trims() -> dict[str, list[str]]:
    text = CURRENT.read_text(encoding="utf-8")
    constants: dict[str, list[str]] = {}
    for match in re.finditer(
        r"static const List<String>\s+(\w+)\s*=\s*\[(.*?)\];", text, re.S
    ):
        constants[match.group(1)] = dart_strings(match.group(2))

    body = re.search(
        r"_trimsByModelId\s*=\s*\{(.*?)\n\s*\};", text, re.S
    ).group(1)
    result: dict[str, list[str]] = {}
    for match in re.finditer(
        r"'([^']+)'\s*:\s*(\[[^\]]*\]|\w+)\s*,", body, re.S
    ):
        key, raw_value = match.groups()
        values = (
            dart_strings(raw_value)
            if raw_value.startswith("[")
            else constants.get(raw_value, [])
        )
        # Ignore malformed values from an interrupted earlier import attempt.
        result[key] = [value for value in values if not value.startswith("{'TrimName':")]
    return result


def app_brand_names() -> dict[str, str]:
    text = (
        ROOT / "lib" / "shared" / "data" / "dummy_brands.dart"
    ).read_text(encoding="utf-8")
    result: dict[str, str] = {}
    for block in re.finditer(r"CarBrand\((.*?)\),", text, re.S):
        body = block.group(1)
        brand_id = re.search(r"id:\s*'([^']+)'", body)
        name = re.search(r"nameEnglish:\s*'([^']+)'", body)
        if brand_id and name:
            result[brand_id.group(1)] = name.group(1)
    return result


BRAND_ALIASES = {
    "citroen": "citro_n",
    "gac": "gac_motor",
    "gwm": "great_wall",
    "iran khodro": "ikco",
    "mhero": "m_hero",
    "tank": "gwm_tank",
}

MODEL_ALIASES = {
    ("kia", "quoris"): "kia_koris",
    ("kia", "besta"): "kia_bestas",
    ("kia", "forte koup"): "kia_forte_coupe",
    ("toyota", "ch-r"): "toyota_chr",
    ("chevrolet", "silverado ev"): "silverado_ev",
    ("haval", "h6 gt"): "haval_gt_h6",
    ("bmw", "1-series"): "series_1",
    ("bmw", "2-series"): "series_2",
    ("bmw", "3-series"): "series_3",
    ("bmw", "4-series"): "series_4",
    ("bmw", "5-series"): "series_5",
    ("bmw", "6-series"): "series_6",
    ("bmw", "7-series"): "series_7",
    ("bmw", "8-series"): "series_8",
}


def resolve_brand(
    source_name: str,
    app_names: dict[str, str],
    catalog: dict[str, list[dict]],
) -> str | None:
    alias = BRAND_ALIASES.get(source_name.casefold())
    if alias:
        return alias
    needle = normalized(source_name)
    exact = [
        brand_id
        for brand_id, name in app_names.items()
        if normalized(name) == needle and brand_id in catalog
    ]
    return exact[0] if len(exact) == 1 else None


def resolve_model(
    brand_id: str, source_name: str, models: list[dict]
) -> tuple[str | None, str]:
    alias = MODEL_ALIASES.get((brand_id, source_name.casefold()))
    if alias:
        return alias, "alias"

    needle = normalized(source_name)
    exact = [model["id"] for model in models if normalized(model["en"]) == needle]
    if len(exact) == 1:
        return exact[0], "exact"

    scored = sorted(
        (
            SequenceMatcher(None, needle, normalized(model["en"])).ratio(),
            model["id"],
        )
        for model in models
    )
    if scored and scored[-1][0] >= 0.94:
        return scored[-1][1], "fuzzy"
    return None, "unmatched"


def storage_key(brand_id: str, model_id: str) -> str:
    return model_id if model_id.startswith(f"{brand_id}_") else f"{brand_id}_{model_id}"


def add_unique(target: list[str], values: list[str]) -> None:
    seen = {value.casefold() for value in target}
    for value in values:
        clean = value.strip()
        if clean and clean.casefold() not in seen:
            target.append(clean)
            seen.add(clean.casefold())


def trim_names(raw_trims: list) -> list[str]:
    return [
        str(trim.get("TrimName", "") if isinstance(trim, dict) else trim)
        for trim in raw_trims
    ]


def main() -> None:
    source = json.loads(SOURCE.read_text(encoding="utf-8"))
    catalog: dict[str, list[dict]] = json.loads(
        CATALOG.read_text(encoding="utf-8")
    )
    app_names = app_brand_names()

    merged: dict[str, list[str]] = defaultdict(list)
    for key, values in existing_trims().items():
        add_unique(merged[key], values)

    report = {
        "source_summary": source["summary"],
        "matched_brands": {},
        "unmatched_brands": [],
        "unmatched_models_with_trims": [],
        "fuzzy_matches": [],
        "imported_source_models": 0,
        "imported_pdf_models": 0,
    }

    source_lookup: dict[tuple[str, str], str] = {}
    for brand in source["brands"]:
        source_brand = brand["BrandNameen"]
        brand_id = resolve_brand(source_brand, app_names, catalog)
        if not brand_id:
            if any(model["Trims"] for model in brand["Models"]):
                report["unmatched_brands"].append(source_brand)
            continue
        report["matched_brands"][source_brand] = brand_id

        for model in brand["Models"]:
            model_id, match_type = resolve_model(
                brand_id, model["ModelNameen"], catalog.get(brand_id, [])
            )
            if model_id:
                source_lookup[(brand_id, normalized(model["ModelNameen"]))] = model_id
            if not model["Trims"]:
                continue
            if not model_id:
                report["unmatched_models_with_trims"].append(
                    {
                        "brand": source_brand,
                        "model": model["ModelNameen"],
                        "trims": model["Trims"],
                    }
                )
                continue
            if match_type == "fuzzy":
                report["fuzzy_matches"].append(
                    {
                        "brand": source_brand,
                        "source": model["ModelNameen"],
                        "model_id": model_id,
                    }
                )
            add_unique(
                merged[storage_key(brand_id, model_id)],
                trim_names(model["Trims"]),
            )
            report["imported_source_models"] += 1

    if PDF_TRIMS.exists():
        pdf = json.loads(PDF_TRIMS.read_text(encoding="utf-8"))
        for brand_id in ("toyota", "kia"):
            for model_name, trims in pdf.get(brand_id, {}).items():
                model_id, _ = resolve_model(
                    brand_id, model_name, catalog.get(brand_id, [])
                )
                if not model_id:
                    continue
                add_unique(merged[storage_key(brand_id, model_id)], trims)
                report["imported_pdf_models"] += 1

    merged = {
        key: values
        for key, values in sorted(merged.items())
        if values
    }
    valid_keys = {
        storage_key(brand_id, model["id"])
        for brand_id, models in catalog.items()
        for model in models
    }
    report["invalid_generated_keys"] = sorted(set(merged) - valid_keys)
    lines = [
        "/// Trim / variant options keyed by catalog model id.",
        "///",
        "/// Imported from the exhaustive iQ Cars trim export and supplemented by",
        "/// the verified Toyota/Kia PDF extraction. Empty trim sets are",
        "/// intentionally omitted so single-trim models keep free-text fallback.",
        "abstract final class CarTrimsByModel {",
        "  static const Map<String, List<String>> _trimsByModelId = {",
    ]
    for key, trims in merged.items():
        rendered = ", ".join(
            "'" + trim.replace("\\", "\\\\").replace("'", "\\'") + "'"
            for trim in trims
        )
        lines.append(f"    '{key}': [{rendered}],")
    lines.extend(
        [
            "  };",
            "",
            "  /// Trims for the selected brand + model, or empty when none are catalogued.",
            "  static List<String> trimsFor(String? brandId, String? modelKey) {",
            "    if (modelKey == null || modelKey.isEmpty) return const [];",
            "",
            "    final direct = _trimsByModelId[modelKey];",
            "    if (direct != null) return direct;",
            "",
            "    if (brandId != null && brandId.isNotEmpty) {",
            "      final prefixed = _trimsByModelId['${brandId}_$modelKey'];",
            "      if (prefixed != null) return prefixed;",
            "    }",
            "",
            "    return const [];",
            "  }",
            "",
            "  static bool hasTrims(String? brandId, String? modelKey) =>",
            "      trimsFor(brandId, modelKey).isNotEmpty;",
            "}",
            "",
        ]
    )
    OUTPUT.write_text("\n".join(lines), encoding="utf-8")

    report["generated_entries"] = len(merged)
    report["generated_unique_trims"] = len(
        {trim.casefold() for trims in merged.values() for trim in trims}
    )
    REPORT.write_text(
        json.dumps(report, ensure_ascii=False, indent=2), encoding="utf-8"
    )
    print(json.dumps(report, ensure_ascii=False, indent=2))


if __name__ == "__main__":
    main()
