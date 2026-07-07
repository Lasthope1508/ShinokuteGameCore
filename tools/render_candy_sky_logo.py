#!/usr/bin/env python3
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter, ImageFont

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "assets" / "themes" / "candy_sky_islands" / "branding" / "logo_candy_sky_islands.png"
FONT = ROOT / "fonts" / "lilita_one_regular.ttf"
TEXT = "Candy Sky Islands"


def main() -> int:
	font = ImageFont.truetype(str(FONT), 132)
	padding_x, padding_y = 56, 42
	dummy = Image.new("RGBA", (1, 1), (0, 0, 0, 0))
	draw = ImageDraw.Draw(dummy)
	box = draw.textbbox((0, 0), TEXT, font=font, stroke_width=10)
	width = box[2] - box[0] + padding_x * 2
	height = box[3] - box[1] + padding_y * 2
	image = Image.new("RGBA", (width, height), (0, 0, 0, 0))
	shadow = Image.new("RGBA", image.size, (0, 0, 0, 0))
	shadow_draw = ImageDraw.Draw(shadow)
	position = (padding_x, padding_y - box[1])
	shadow_draw.text(position, TEXT, font=font, fill=(39, 48, 67, 180), stroke_width=14, stroke_fill=(39, 48, 67, 180))
	shadow = shadow.filter(ImageFilter.GaussianBlur(2.0))
	image.alpha_composite(shadow)
	draw = ImageDraw.Draw(image)
	draw.text(position, TEXT, font=font, fill=(255, 242, 199, 255), stroke_width=10, stroke_fill=(39, 48, 67, 255))
	draw.text((position[0], position[1] - 8), TEXT, font=font, fill=(255, 111, 97, 90), stroke_width=0)
	draw.line((padding_x + 18, height - 34, width - padding_x - 18, height - 34), fill=(123, 224, 173, 255), width=10)
	OUT.parent.mkdir(parents=True, exist_ok=True)
	image.save(OUT)
	print(OUT)
	return 0


if __name__ == "__main__":
	raise SystemExit(main())
