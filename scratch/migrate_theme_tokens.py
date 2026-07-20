"""
Mechanically update AddCarTheme / HomeScreenColors call sites for M3 context APIs.

Patterns:
  AddCarTheme.scaffoldBg  -> AddCarTheme.scaffoldBg(context)
  AddCarTheme.cardDecoration() -> AddCarTheme.cardDecoration(context)
  AddCarTheme.cardDecoration(color: x) -> AddCarTheme.cardDecoration(context, color: x)
  AddCarTheme.textFieldDecoration(...) -> AddCarTheme.textFieldDecoration(context, ...)
  AddCarTheme.focusBlue -> AddCarTheme.focus(context)
  AddCarTheme.primaryBlack -> AddCarTheme.primary(context)
  AddCarTheme.successGreen -> AddCarTheme.success(context)
  HomeScreenColors.background -> HomeScreenColors.background(context)
"""

from __future__ import annotations

import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1] / "lib"

RENAMES = {
    "focusBlue": "focus",
    "primaryBlack": "primary",
    "successGreen": "success",
}

COLOR_PROPS = [
    "scaffoldBg",
    "cardBg",
    "inputFill",
    "focus",
    "primary",
    "textPrimary",
    "textSecondary",
    "border",
    "success",
    "stepTitle",
    "stepSubtitle",
    "sectionTitle",
    "sectionLabel",
]

HOME_PROPS = ["background", "textPrimary", "textSecondary"]


def transform(src: str) -> str:
    out = src
    for old, new in RENAMES.items():
        out = out.replace(f"AddCarTheme.{old}", f"AddCarTheme.{new}")

    def ensure_context_call(name: str, text: str) -> str:
        # Skip if already has (context
        return re.sub(
            rf"AddCarTheme\.{name}(?!\s*\(\s*context)",
            f"AddCarTheme.{name}(context",
            text,
        )

    # Methods with optional named args — insert context as first arg once
    for method in ("cardDecoration", "inputDecorationBox", "textFieldDecoration"):
        # empty call
        out = re.sub(
            rf"AddCarTheme\.{method}\(\s*\)",
            f"AddCarTheme.{method}(context)",
            out,
        )
        # already has context
        out = re.sub(
            rf"AddCarTheme\.{method}\(\s*context\s*,\s*context\s*",
            f"AddCarTheme.{method}(context",
            out,
        )
        # has other args but not context
        out = re.sub(
            rf"AddCarTheme\.{method}\((?!\s*context)",
            f"AddCarTheme.{method}(context, ",
            out,
        )

    for prop in COLOR_PROPS:
        out = re.sub(
            rf"AddCarTheme\.{prop}(?!\s*\()",
            f"AddCarTheme.{prop}(context)",
            out,
        )
        out = re.sub(
            rf"AddCarTheme\.{prop}\(context\)\(context\)",
            f"AddCarTheme.{prop}(context)",
            out,
        )

    for prop in HOME_PROPS:
        out = re.sub(
            rf"HomeScreenColors\.{prop}(?!\s*\()",
            f"HomeScreenColors.{prop}(context)",
            out,
        )
        out = re.sub(
            rf"HomeScreenColors\.{prop}\(context\)\(context\)",
            f"HomeScreenColors.{prop}(context)",
            out,
        )

    return out


def main() -> None:
    changed = 0
    for path in ROOT.rglob("*.dart"):
        text = path.read_text(encoding="utf-8")
        if "AddCarTheme." not in text and "HomeScreenColors." not in text:
            continue
        updated = transform(text)
        if updated != text:
            path.write_text(updated, encoding="utf-8")
            changed += 1
            print("updated", path.relative_to(ROOT))
    print(f"files changed: {changed}")


if __name__ == "__main__":
    main()
