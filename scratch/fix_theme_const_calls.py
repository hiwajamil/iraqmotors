"""Remove invalid const around theme-token calls; fix leftover AddCarTheme APIs."""

from __future__ import annotations

import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1] / "lib"


def fix(text: str) -> str:
    # Leftover renames / removed APIs
    text = text.replace("AddCarTheme.focusBlue", "AddCarTheme.focus(context)")
    text = text.replace("AddCarTheme.primaryBlack", "AddCarTheme.primary(context)")
    text = text.replace("AddCarTheme.successGreen", "AddCarTheme.success(context)")
    text = text.replace("AddCarTheme.cardShadow", "const <BoxShadow>[]")

    # Double-wrapping like focus(context)(context)
    text = re.sub(
        r"AddCarTheme\.(focus|primary|success)\(context\)\(context\)",
        r"AddCarTheme.\1(context)",
        text,
    )

    # const TextStyle( ... ThemeToken(context) ...) -> TextStyle(
    def strip_const_textstyle(match: re.Match[str]) -> str:
        body = match.group(0)
        if "(context)" in body:
            return body.replace("const TextStyle", "TextStyle", 1)
        return body

    text = re.sub(
        r"const TextStyle\([^;]*?\)",
        strip_const_textstyle,
        text,
        flags=re.S,
    )

    # const OutlineInputBorder / BorderSide with context
    def strip_const_if_context(match: re.Match[str]) -> str:
        body = match.group(0)
        if "(context)" in body:
            return re.sub(r"\bconst\s+", "", body, count=1)
        return body

    text = re.sub(
        r"const\s+(OutlineInputBorder|BorderSide|BoxDecoration|TextStyle|Icon|ColoredBox|Container)\([^;]*?\)",
        strip_const_if_context,
        text,
        flags=re.S,
    )

    # const BorderSide(color: AddCarTheme...
    text = re.sub(
        r"const BorderSide\(color: AddCarTheme\.",
        "BorderSide(color: AddCarTheme.",
        text,
    )

    # HomeScreenColors still missing (context) — shouldn't happen; belt & suspenders
    for prop in ("background", "textPrimary", "textSecondary"):
        text = re.sub(
            rf"HomeScreenColors\.{prop}(?!\s*\()",
            f"HomeScreenColors.{prop}(context)",
            text,
        )

    return text


def main() -> None:
    n = 0
    for path in ROOT.rglob("*.dart"):
        raw = path.read_text(encoding="utf-8")
        if "AddCarTheme." not in raw and "HomeScreenColors." not in raw:
            continue
        updated = fix(raw)
        if updated != raw:
            path.write_text(updated, encoding="utf-8")
            n += 1
            print(path.relative_to(ROOT))
    print("fixed", n)


if __name__ == "__main__":
    main()
