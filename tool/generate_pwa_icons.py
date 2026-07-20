"""Generate branded PWA icons from the IQ Motors wordmark."""

from __future__ import annotations

from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
LOGO_PATH = ROOT / "assets" / "images" / "IQ11.png"
ICONS_DIR = ROOT / "web" / "icons"
BG = (10, 10, 12, 255)  # AppTheme dark surface #0A0A0C


def _trim_logo(logo: Image.Image) -> Image.Image:
    alpha = logo.split()[-1]
    bbox = alpha.getbbox()
    w, h = logo.size
    if bbox and (bbox[2] - bbox[0]) < w * 0.98:
        return logo.crop(bbox)

    pixels = logo.load()
    min_x, min_y, max_x, max_y = w, h, 0, 0
    for y in range(h):
        for x in range(w):
            r, g, b, a = pixels[x, y]
            if a > 20 and (r > 30 or g > 30 or b > 30):
                min_x = min(min_x, x)
                min_y = min(min_y, y)
                max_x = max(max_x, x)
                max_y = max(max_y, y)
    if max_x > min_x:
        return logo.crop((min_x, min_y, max_x + 1, max_y + 1))
    return logo


def make_icon(logo: Image.Image, size: int, *, maskable: bool) -> Image.Image:
    canvas = Image.new("RGBA", (size, size), BG)
    pad_ratio = 0.22 if maskable else 0.12
    max_w = int(size * (1 - 2 * pad_ratio))
    max_h = int(size * (1 - 2 * pad_ratio))
    lw, lh = logo.size
    scale = min(max_w / lw, max_h / lh)
    nw, nh = max(1, int(lw * scale)), max(1, int(lh * scale))
    resized = logo.resize((nw, nh), Image.Resampling.LANCZOS)
    x = (size - nw) // 2
    y = (size - nh) // 2
    canvas.paste(resized, (x, y), resized)
    return canvas


def main() -> None:
    logo = _trim_logo(Image.open(LOGO_PATH).convert("RGBA"))
    print(f"cropped logo {logo.size}")

    ICONS_DIR.mkdir(parents=True, exist_ok=True)
    for size in (192, 512):
        make_icon(logo, size, maskable=False).save(
            ICONS_DIR / f"Icon-{size}.png", optimize=True
        )
        make_icon(logo, size, maskable=True).save(
            ICONS_DIR / f"Icon-maskable-{size}.png", optimize=True
        )

    make_icon(logo, 48, maskable=False).save(ROOT / "web" / "favicon.png", optimize=True)
    make_icon(logo, 180, maskable=False).save(
        ICONS_DIR / "apple-touch-icon.png", optimize=True
    )
    print("wrote branded PWA icons")


if __name__ == "__main__":
    main()
