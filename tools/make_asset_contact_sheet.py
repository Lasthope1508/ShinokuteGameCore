#!/usr/bin/env python3
import json
import math
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont


ROOT = Path(__file__).resolve().parents[1]
THEME_DIR = ROOT / "assets" / "themes" / "candy_sky_islands"
QC_PATH = THEME_DIR / "asset_family_extraction_qc.json"
OUT_PATH = ROOT / "docs" / "screenshots" / "candy_sky_islands_corrected_asset_contact_sheet.png"


def main() -> int:
    qc = json.loads(QC_PATH.read_text(encoding="utf-8"))
    keys = list(qc["assets"].keys())
    cell_w, cell_h = 320, 300
    cols = 3
    rows = math.ceil(len(keys) / cols)
    margin = 24
    image = Image.new("RGB", (cols * cell_w + margin * 2, rows * cell_h + margin * 2), (18, 24, 30))
    draw = ImageDraw.Draw(image)
    font = ImageFont.load_default()

    for index, key in enumerate(keys):
        col = index % cols
        row = index // cols
        x = margin + col * cell_w
        y = margin + row * cell_h
        draw.rounded_rectangle(
            [x + 8, y + 8, x + cell_w - 8, y + cell_h - 8],
            radius=8,
            fill=(35, 42, 48),
            outline=(255, 216, 77),
        )

        tile = 16
        for yy in range(y + 22, y + cell_h - 54, tile):
            for xx in range(x + 22, x + cell_w - 22, tile):
                color = (205, 214, 220) if ((xx // tile + yy // tile) % 2 == 0) else (116, 128, 138)
                draw.rectangle([xx, yy, xx + tile - 1, yy + tile - 1], fill=color)

        asset = Image.open(THEME_DIR / f"{key}.png").convert("RGBA")
        max_w, max_h = cell_w - 58, cell_h - 96
        scale = min(max_w / asset.width, max_h / asset.height, 1.0)
        size = (max(1, int(asset.width * scale)), max(1, int(asset.height * scale)))
        asset = asset.resize(size, Image.LANCZOS)
        px = x + (cell_w - size[0]) // 2
        py = y + 28 + (max_h - size[1]) // 2
        image.paste(asset, (px, py), asset)

        output_size = qc["assets"][key]["output_size"]
        label = f"{key}  {output_size[0]}x{output_size[1]}"
        draw.text((x + 18, y + cell_h - 42), label, fill=(233, 251, 255), font=font)

    OUT_PATH.parent.mkdir(parents=True, exist_ok=True)
    image.save(OUT_PATH)
    print(str(OUT_PATH))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
