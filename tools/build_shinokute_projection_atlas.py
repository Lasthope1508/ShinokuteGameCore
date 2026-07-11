from __future__ import annotations

import json
from pathlib import Path

from PIL import Image


ROOT = Path(__file__).resolve().parents[1]
SOURCE_MODE = "anatomy"
POOL = ROOT / "assets" / "themes" / "candy_sky_islands" / "source" / "shinokute_player" / "anatomy_turnaround_pool"
OUT_DIR = ROOT / "assets" / "themes" / "candy_sky_islands" / "source" / "shinokute_player" / "projection"
ATLAS = OUT_DIR / "shinokute_projection_atlas.png"
META = OUT_DIR / "shinokute_projection_atlas_meta.json"

VIEWS = {
    "front": POOL / "shinokute_anatomy_front.png",
    "back": POOL / "shinokute_anatomy_back.png",
    "left_side": POOL / "shinokute_anatomy_left_side.png",
    "front_left_3q": POOL / "shinokute_anatomy_front_left_3q.png",
    "front_right_3q": POOL / "shinokute_anatomy_front_right_3q.png",
    "right_side": POOL / "shinokute_anatomy_right_side.png",
    "back_left_3q": POOL / "shinokute_anatomy_back_left_3q.png",
    "back_right_3q": POOL / "shinokute_anatomy_back_right_3q.png",
}


def alpha_bbox(image: Image.Image) -> tuple[int, int, int, int]:
    alpha = image.getchannel("A")
    bbox = alpha.getbbox()
    if bbox is None:
        raise ValueError("image has no alpha foreground")
    return bbox


def crop_with_padding(image: Image.Image, padding: int) -> Image.Image:
    x0, y0, x1, y1 = alpha_bbox(image)
    x0 = max(0, x0 - padding)
    y0 = max(0, y0 - padding)
    x1 = min(image.width, x1 + padding)
    y1 = min(image.height, y1 + padding)
    return image.crop((x0, y0, x1, y1))


def composite_for_texture(image: Image.Image) -> Image.Image:
    rgba = image.convert("RGBA")
    # Keep alpha in source, but fill transparent RGB with nearby-neutral black so
    # mip/filter bleed does not create white halos on black Shinokute clothing.
    background = Image.new("RGBA", rgba.size, (8, 8, 10, 255))
    background.alpha_composite(rgba)
    return background


def main() -> int:
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    cell = 768
    columns = 4
    rows = 2
    atlas = Image.new("RGBA", (cell * columns, cell * rows), (8, 8, 10, 255))
    meta = {
        "atlas": str(ATLAS),
        "cell_size": cell,
        "columns": columns,
        "rows": rows,
        "views": {},
        "source": "9Router Hunyuan-anatomy corrected sheet, Photoroom full sheet first, component polygon extracted pool",
        "source_mode": SOURCE_MODE,
    }

    for index, (name, path) in enumerate(VIEWS.items()):
        source = Image.open(path).convert("RGBA")
        crop = composite_for_texture(crop_with_padding(source, 12))
        scale = min((cell - 80) / crop.width, (cell - 80) / crop.height)
        resized = crop.resize((max(1, int(crop.width * scale)), max(1, int(crop.height * scale))), Image.Resampling.LANCZOS)
        col = index % columns
        row = index // columns
        x = col * cell + (cell - resized.width) // 2
        y = row * cell + (cell - resized.height) // 2
        atlas.alpha_composite(resized, (x, y))
        meta["views"][name] = {
            "source": str(path),
            "cell": [col, row],
            "atlas_rect_px": [x, y, resized.width, resized.height],
            "uv_rect": [
                x / atlas.width,
                1.0 - (y + resized.height) / atlas.height,
                resized.width / atlas.width,
                resized.height / atlas.height,
            ],
        }

    atlas.save(ATLAS)
    META.write_text(json.dumps(meta, indent=2), encoding="utf-8")
    print(json.dumps({"atlas": str(ATLAS), "meta": str(META)}, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
