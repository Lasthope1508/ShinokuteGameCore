from __future__ import annotations

import sys
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont


def arg(name: str, default: str = "") -> str:
    if name not in sys.argv:
        return default
    index = sys.argv.index(name)
    if index + 1 >= len(sys.argv):
        return default
    return sys.argv[index + 1]


def main() -> int:
    in_dir = Path(arg("--in-dir")).resolve()
    out_path = Path(arg("--out")).resolve()
    names = ["front", "front_right_3q", "right", "back", "left", "front_left_3q"]
    images = []
    for name in names:
        path = in_dir / f"{name}.png"
        if not path.exists():
            raise FileNotFoundError(path)
        images.append((name, Image.open(path).convert("RGB")))

    cell_w, cell_h = 360, 440
    margin = 28
    label_h = 36
    canvas = Image.new("RGB", (margin * 2 + cell_w * 3, margin * 2 + (cell_h + label_h) * 2), (18, 24, 30))
    draw = ImageDraw.Draw(canvas)
    try:
        font = ImageFont.truetype("arial.ttf", 22)
    except OSError:
        font = ImageFont.load_default()

    for index, (name, image) in enumerate(images):
        col = index % 3
        row = index // 3
        x = margin + col * cell_w
        y = margin + row * (cell_h + label_h)
        thumb = image.copy()
        thumb.thumbnail((cell_w, cell_h), Image.Resampling.LANCZOS)
        tx = x + (cell_w - thumb.width) // 2
        ty = y + (cell_h - thumb.height) // 2
        canvas.paste(thumb, (tx, ty))
        draw.text((x + 8, y + cell_h + 6), name, fill=(235, 239, 245), font=font)

    out_path.parent.mkdir(parents=True, exist_ok=True)
    canvas.save(out_path)
    print(out_path)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
