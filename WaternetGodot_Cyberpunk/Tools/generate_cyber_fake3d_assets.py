from __future__ import annotations

import math
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter


ROOT = Path(__file__).resolve().parents[1]
ASSET_ROOT = ROOT / "Assets" / "Themes" / "cyberpunk_theme"
SIZE = 512


def radial_alpha(size: int, center: tuple[float, float], radius: float, strength: int) -> Image.Image:
    image = Image.new("L", (size, size), 0)
    pixels = image.load()
    cx, cy = center
    for y in range(size):
        for x in range(size):
            distance = math.hypot(x - cx, y - cy)
            t = max(0.0, 1.0 - distance / radius)
            pixels[x, y] = int((t * t) * strength)
    return image


def draw_cell_bg() -> Image.Image:
    image = Image.new("RGBA", (SIZE, SIZE), (4, 6, 8, 255))
    draw = ImageDraw.Draw(image, "RGBA")

    draw.rectangle((0, 0, SIZE - 1, SIZE - 1), fill=(3, 4, 5, 255))
    draw.rounded_rectangle((14, 14, SIZE - 15, SIZE - 15), radius=28, fill=(14, 17, 18, 255))
    draw.rounded_rectangle((30, 30, SIZE - 31, SIZE - 31), radius=20, fill=(24, 27, 27, 255))

    for i in range(30, 90, 12):
        alpha = 80 - i // 2
        draw.line((i, 32, SIZE - 34, 32), fill=(95, 255, 185, alpha), width=2)
        draw.line((32, i, 32, SIZE - 34), fill=(95, 255, 185, alpha), width=2)

    draw.line((34, SIZE - 34, SIZE - 34, SIZE - 34), fill=(0, 0, 0, 150), width=12)
    draw.line((SIZE - 34, 34, SIZE - 34, SIZE - 34), fill=(0, 0, 0, 140), width=12)
    draw.rounded_rectangle((26, 26, SIZE - 27, SIZE - 27), radius=24, outline=(42, 255, 135, 22), width=1)
    draw.rounded_rectangle((40, 40, SIZE - 41, SIZE - 41), radius=18, outline=(0, 0, 0, 115), width=5)

    noise = Image.effect_noise((SIZE, SIZE), 14).convert("L")
    texture = Image.new("RGBA", (SIZE, SIZE), (255, 255, 255, 0))
    texture.putalpha(noise.point(lambda p: 18 if p > 136 else 0))
    image = Image.alpha_composite(image, texture)
    return image


def enhance_terminal(path: Path, output: Path, glow: bool = False) -> None:
    base = Image.open(path).convert("RGBA")
    alpha = base.getchannel("A")

    shadow = Image.new("RGBA", base.size, (0, 0, 0, 0))
    shadow_alpha = alpha.filter(ImageFilter.GaussianBlur(14)).point(lambda p: int(p * 0.42))
    shadow.putalpha(shadow_alpha)

    canvas = Image.new("RGBA", base.size, (0, 0, 0, 0))
    canvas.alpha_composite(shadow, (12, 16))

    highlight = Image.new("RGBA", base.size, (0, 0, 0, 0))
    highlight_alpha = alpha.filter(ImageFilter.GaussianBlur(3)).point(lambda p: int(p * 0.22))
    highlight.putalpha(highlight_alpha)
    highlight_color = Image.new("RGBA", base.size, (120, 255, 200, 0))
    highlight_color.putalpha(highlight_alpha)
    canvas.alpha_composite(highlight_color, (-5, -7))

    if glow:
        glow_layer = Image.new("RGBA", base.size, (70, 255, 140, 0))
        glow_layer.putalpha(radial_alpha(SIZE, (SIZE * 0.5, SIZE * 0.52), SIZE * 0.38, 120))
        canvas = Image.alpha_composite(canvas, glow_layer)

    canvas = Image.alpha_composite(canvas, base)
    output.parent.mkdir(parents=True, exist_ok=True)
    canvas.save(output)


def main() -> None:
    draw_cell_bg().save(ASSET_ROOT / "cell_bg.png")
    enhance_terminal(ASSET_ROOT / "source.png", ASSET_ROOT / "source.png", glow=True)
    enhance_terminal(ASSET_ROOT / "target.png", ASSET_ROOT / "target.png", glow=False)
    enhance_terminal(ASSET_ROOT / "target.png", ASSET_ROOT / "target_slices" / "target_slice_1.png", glow=True)
    print("generated cyber fake3D assets")


if __name__ == "__main__":
    main()
