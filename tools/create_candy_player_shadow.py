from __future__ import annotations

import json
import math
from pathlib import Path

from PIL import Image


PROJECT = Path(__file__).resolve().parents[1]
OUT = PROJECT / "assets" / "themes" / "candy_sky_islands" / "player_shadow_soft.png"
QC = PROJECT / "assets" / "themes" / "candy_sky_islands" / "player_shadow_soft_qc.json"
SIZE = 256


def lerp(a: int, b: int, t: float) -> int:
    return round(a + (b - a) * t)


def edge_alpha_ratio(image: Image.Image, threshold: int = 8) -> float:
    width, height = image.size
    alpha = image.getchannel("A")
    edge_pixels = []
    for x in range(width):
        edge_pixels.append(alpha.getpixel((x, 0)))
        edge_pixels.append(alpha.getpixel((x, height - 1)))
    for y in range(height):
        edge_pixels.append(alpha.getpixel((0, y)))
        edge_pixels.append(alpha.getpixel((width - 1, y)))
    return sum(1 for value in edge_pixels if value > threshold) / len(edge_pixels)


def main() -> None:
    image = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    pixels = image.load()
    center_x = SIZE / 2
    center_y = 145
    radius_x = 95
    radius_y = 43
    inner = (39, 48, 67)
    outer = (121, 199, 242)

    for y in range(SIZE):
        for x in range(SIZE):
            dx = (x - center_x) / radius_x
            dy = (y - center_y) / radius_y
            distance = dx * dx + dy * dy
            if distance >= 1.75:
                continue
            falloff = math.exp(-distance * 2.15)
            alpha = max(0, min(224, round(224 * falloff)))
            if alpha <= 1:
                continue
            tint = min(1.0, distance / 1.45)
            r = lerp(inner[0], outer[0], tint)
            g = lerp(inner[1], outer[1], tint)
            b = lerp(inner[2], outer[2], tint)
            pixels[x, y] = (r, g, b, alpha)

    OUT.parent.mkdir(parents=True, exist_ok=True)
    image.save(OUT)

    alpha = image.getchannel("A")
    nonzero = sum(count for value, count in enumerate(alpha.histogram()) if value > 0)
    qc = {
        "asset": "player.shadow",
        "path": "res://assets/themes/candy_sky_islands/player_shadow_soft.png",
        "source": "local authored 2D alpha gradient, no AI generation, no sheet extraction",
        "mode": image.mode,
        "size": list(image.size),
        "alpha_extrema": list(alpha.getextrema()),
        "nonzero_alpha_pixels": nonzero,
        "edge_alpha_ratio_gt_8": edge_alpha_ratio(image),
        "runtime_contract": "objects/player.tscn Shadow Decal size Vector3(1, 2, 1)",
        "passes": image.mode == "RGBA"
        and image.size == (SIZE, SIZE)
        and alpha.getextrema()[0] == 0
        and alpha.getextrema()[1] >= 180
        and edge_alpha_ratio(image) == 0.0,
    }
    QC.write_text(json.dumps(qc, indent=2), encoding="utf-8")
    print(json.dumps(qc, indent=2))


if __name__ == "__main__":
    main()
