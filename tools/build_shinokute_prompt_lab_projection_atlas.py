from __future__ import annotations

import json
import sys
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[1]

VIEWS = [
    "front",
    "back",
    "left_side",
    "front_left_3q",
    "front_right_3q",
    "right_side",
    "back_left_3q",
    "back_right_3q",
]


def alpha_bbox(image: Image.Image) -> tuple[int, int, int, int]:
    bbox = image.getchannel("A").getbbox()
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
    background = Image.new("RGBA", rgba.size, (8, 8, 10, 255))
    background.alpha_composite(rgba)
    return background


def main() -> int:
    if len(sys.argv) != 5:
        print("usage: build_shinokute_prompt_lab_projection_atlas.py <pool_dir> <prefix> <atlas_png> <meta_json>")
        return 2
    pool = Path(sys.argv[1])
    prefix = sys.argv[2]
    atlas_path = Path(sys.argv[3])
    meta_path = Path(sys.argv[4])
    atlas_path.parent.mkdir(parents=True, exist_ok=True)

    cell = 768
    columns = 4
    rows = 2
    atlas = Image.new("RGBA", (cell * columns, cell * rows), (8, 8, 10, 255))
    meta = {
        "atlas": str(atlas_path),
        "cell_size": cell,
        "columns": columns,
        "rows": rows,
        "views": {},
        "source": "9Router prompt lab albedo sheet, Photoroom full sheet first, high-alpha component polygon extracted pool",
        "source_mode": "prompt_lab_albedo",
    }

    for index, name in enumerate(VIEWS):
        path = pool / f"{prefix}_{name}.png"
        source = Image.open(path).convert("RGBA")
        crop = composite_for_texture(crop_with_padding(source, 12))
        scale = min((cell - 80) / crop.width, (cell - 80) / crop.height)
        resized = crop.resize(
            (max(1, int(crop.width * scale)), max(1, int(crop.height * scale))),
            Image.Resampling.LANCZOS,
        )
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

    atlas.save(atlas_path)
    meta_path.write_text(json.dumps(meta, indent=2), encoding="utf-8")
    print(json.dumps({"atlas": str(atlas_path), "meta": str(meta_path)}, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
