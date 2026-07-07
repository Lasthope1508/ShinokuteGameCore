#!/usr/bin/env python3
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[1]
BRANDING = ROOT / "assets" / "themes" / "candy_sky_islands" / "branding"
OUT = ROOT / "docs" / "screenshots" / "candy_sky_islands_branding_contact_sheet.png"

ITEMS = [
	("App icon", BRANDING / "app_icon_source.png", (360, 360)),
	("Splash", BRANDING / "splash_candy_sky_islands.png", (720, 405)),
	("Logo", BRANDING / "logo_candy_sky_islands.png", (720, 180)),
]


def _fit(image: Image.Image, max_size: tuple[int, int]) -> Image.Image:
	image = image.convert("RGBA")
	scale = min(max_size[0] / image.width, max_size[1] / image.height, 1.0)
	size = (max(1, int(image.width * scale)), max(1, int(image.height * scale)))
	return image.resize(size, Image.LANCZOS)


def main() -> int:
	font = ImageFont.load_default()
	canvas = Image.new("RGB", (820, 1080), (24, 30, 38))
	draw = ImageDraw.Draw(canvas)
	y = 28
	for label, path, box in ITEMS:
		draw.text((32, y), label, fill=(233, 251, 255), font=font)
		y += 24
		draw.rectangle((32, y, 32 + box[0], y + box[1]), fill=(55, 64, 74), outline=(255, 242, 199))
		if path.exists():
			image = _fit(Image.open(path), box)
			x = 32 + (box[0] - image.width) // 2
			py = y + (box[1] - image.height) // 2
			if image.mode == "RGBA":
				canvas.paste(image, (x, py), image)
			else:
				canvas.paste(image, (x, py))
		else:
			draw.text((48, y + 24), f"Missing: {path.name}", fill=(255, 111, 97), font=font)
		y += box[1] + 42
	OUT.parent.mkdir(parents=True, exist_ok=True)
	canvas.save(OUT)
	print(OUT)
	return 0


if __name__ == "__main__":
	raise SystemExit(main())
