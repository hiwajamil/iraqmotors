"""
Bulk-replace common hardcoded Apple/IQ palette colors with ColorScheme roles.
Skips paint-swatch / domain color files. Strips invalid `const` after injection.
"""

from __future__ import annotations

import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1] / "lib"

SKIP_PARTS = {
    "add_car_form_options.dart",
    "car_models",
    "car_trims_by_model.dart",
    "dummy_brands.dart",
}

# Exact hex → ColorScheme accessor (requires `context` in scope)
HEX_MAP = {
    "0xFF1D1D1F": "Theme.of(context).colorScheme.onSurface",
    "0xFF000000": "Theme.of(context).colorScheme.onSurface",
    "0xFF86868B": "Theme.of(context).colorScheme.onSurfaceVariant",
    "0xFF3C3C43": "Theme.of(context).colorScheme.onSurfaceVariant",
    "0xFFF5F5F7": "Theme.of(context).colorScheme.surface",
    "0xFFF2F2F7": "Theme.of(context).colorScheme.surfaceContainerHighest",
    "0xFFFAFAFA": "Theme.of(context).colorScheme.surfaceContainerHighest",
    "0xFFFFFFFF": "Theme.of(context).colorScheme.surfaceContainerLowest",
    "0xFF007AFF": "Theme.of(context).colorScheme.primary",
    "0xFF34C759": "Theme.of(context).colorScheme.tertiary",
    "0xFFFF3B30": "Theme.of(context).colorScheme.error",
    "0xFFFF9500": "Theme.of(context).colorScheme.tertiary",
    "0xFFE5E5EA": "Theme.of(context).colorScheme.outlineVariant",
    "0xFFD1D1D6": "Theme.of(context).colorScheme.outlineVariant",
    "0xFF8E8E93": "Theme.of(context).colorScheme.onSurfaceVariant",
    "0xFF636366": "Theme.of(context).colorScheme.onSurfaceVariant",
    "0xFFAEAEB2": "Theme.of(context).colorScheme.outline",
    "0xFFC7C7CC": "Theme.of(context).colorScheme.outlineVariant",
}


def should_skip(path: Path) -> bool:
    parts = set(path.parts)
    name = path.name
    if name in SKIP_PARTS:
        return True
    if "car_models" in parts:
        return True
    return False


def transform(text: str) -> str:
    out = text
    for hex_code, expr in HEX_MAP.items():
        # Color(0xFF....) and const Color(0xFF....)
        out = re.sub(
            rf"(?:const\s+)?Color\({hex_code}\)",
            expr,
            out,
            flags=re.IGNORECASE,
        )

    # Common static field initializers that are now invalid:
    # static const Color _x = Theme.of(context)...
    # Convert to getters is too hard; instead leave and fix by removing const Color fields
    # that reference Theme.of — convert `static const Color _foo = Theme.of...` 
    # into removal and replace _foo usages... too risky.
    #
    # Instead: rewrite `static const Color _name = Theme.of(context).colorScheme.X;`
    # back is wrong. Better convert those lines to comments and map field usages.

    # Fix: static const Color _textPrimary = Theme.of(context).colorScheme.onSurface;
    # → delete the field line; replace _textPrimary with Theme.of(context).colorScheme.onSurface
    field_assign = re.compile(
        r"^\s*static\s+const\s+Color\s+(_\w+)\s*=\s*(Theme\.of\(context\)\.colorScheme\.\w+)\s*;\s*$",
        re.M,
    )
    fields = list(field_assign.finditer(out))
    for m in reversed(fields):
        name, expr = m.group(1), m.group(2)
        # remove declaration
        out = out[: m.start()] + out[m.end() :]
        # replace usages of the field (word boundary)
        out = re.sub(rf"\b{name}\b", expr, out)

    # Also: `static const Color _x = Color(...)` already replaced color so may be Theme.of
    # Handle non-static final fields too
    field_assign2 = re.compile(
        r"^\s*(?:static\s+)?(?:const\s+)?Color\s+(_\w+)\s*=\s*(Theme\.of\(context\)\.colorScheme\.\w+)\s*;\s*$",
        re.M,
    )
    for m in reversed(list(field_assign2.finditer(out))):
        name, expr = m.group(1), m.group(2)
        out = out[: m.start()] + out[m.end() :]
        out = re.sub(rf"\b{name}\b", expr, out)

    # Strip const from constructors that now contain Theme.of(context)
    def strip_const(match: re.Match[str]) -> str:
        body = match.group(0)
        if "Theme.of(context)" in body:
            return re.sub(r"\bconst\s+", "", body, count=1)
        return body

    out = re.sub(
        r"const\s+[A-Z][A-Za-z0-9_]*\([^;]{0,1200}?\)",
        strip_const,
        out,
        flags=re.S,
    )
    # const TextStyle(...)
    out = re.sub(
        r"const\s+TextStyle\([^;]{0,400}?\)",
        strip_const,
        out,
        flags=re.S,
    )
    out = re.sub(
        r"const\s+BorderSide\([^;]{0,200}?\)",
        strip_const,
        out,
        flags=re.S,
    )
    out = re.sub(
        r"const\s+BoxDecoration\([^;]{0,600}?\)",
        strip_const,
        out,
        flags=re.S,
    )
    out = re.sub(
        r"const\s+Divider\([^;]{0,200}?\)",
        strip_const,
        out,
        flags=re.S,
    )

    return out


def main() -> None:
    changed = 0
    for path in ROOT.rglob("*.dart"):
        if should_skip(path):
            continue
        raw = path.read_text(encoding="utf-8")
        if "Color(0x" not in raw and "Color(0X" not in raw:
            continue
        updated = transform(raw)
        if updated != raw:
            path.write_text(updated, encoding="utf-8")
            changed += 1
            print(path.relative_to(ROOT.parent))
    print("files changed:", changed)


if __name__ == "__main__":
    main()
