import argparse
import hashlib
import importlib.util
import json
import os
import sys
import time
import urllib.error
import urllib.request
from collections import deque
from pathlib import Path

from PIL import Image, ImageDraw


PROJECT = Path(__file__).resolve().parents[1]
MODEL_ID = "cx/gpt-5.5-image"
PUBLIC_PREFIX = "images/glyph-arrows-cyber-ui-production"
MANIFEST_PATH = PROJECT / "docs" / "ui_cyber_component_generation_manifest.json"
FULL_REFS_PATH = PROJECT / "docs" / "ui_cyber_reference_pack_r2.json"
COMPONENT_REFS_PATH = PROJECT / "docs" / "ui_cyber_dark_light_component_refs_r2.json"
UPLOADER_PATH = Path(r"C:\Users\Admin\Desktop\Game\reskin_dashboard\upload_server.py")


COMPONENTS = {
    "modal_frame": {
        "size": "1792x1024",
        "anchor": "modal.center_frame",
        "content_padding": "28px transparent crop padding; Godot renders title, rows, icons, and close icon separately",
        "safe_overdraw": "contained bevel glow inside cropped alpha bounds",
        "scale_policy": "fit_inside_canonical_modal_rect_preserve_aspect_centered_use_9slice_if_needed",
        "background_removal": "connected_edge_chroma_key_magenta",
        "component_refs": ["top_tray", "stats_capsule", "full_demo"],
        "production_refs": ["top_tray_layer", "stats_capsule", "logo_socket"],
        "base_prompt": (
            "Create one isolated production mobile game UI asset object, not poster art and not a full screen mockup.\n"
            "Asset: modal_frame.\n"
            "Object: empty cyber settings/leaderboard modal shell, wide rounded sci-fi beveled frame, hollow readable inner content area, small corner close slot only.\n"
            "Keep the corner close slot as an empty circular or hex socket in the upper right corner; do not draw an X icon.\n"
            "No full-row close button. No title. No settings labels. No leaderboard rows. No text. No icons. No logo. No character. No gameplay pipes. No board screenshot.\n"
            "Use reference images only for material language, bevel depth, glow color, fake3D cockpit proportion, and premium mobile game readability.\n"
            "Centered object, fully visible, clean alpha-friendly edge, generous #ff00ff removable background margin.\n"
        ),
    },
    "board_backplate": {
        "size": "1024x1024",
        "anchor": "board.backplate",
        "content_padding": "28px transparent crop padding; board grid and pipe tiles are rendered by Godot above this support frame",
        "safe_overdraw": "contained outer shadow and cyan edge glow inside cropped alpha bounds",
        "scale_policy": "fit_under_canonical_square_board_rect_preserve_aspect_centered",
        "background_removal": "connected_edge_chroma_key_magenta",
        "component_refs": ["board_region", "full_demo", "background_depth"],
        "production_refs": ["top_tray_layer", "bottom_reserve_layer"],
        "base_prompt": (
            "Create one isolated production mobile game UI asset object, not poster art and not a full screen mockup.\n"
            "Asset: board_backplate.\n"
            "Object: square fake3D cyber board support backplate/frame behind a puzzle grid, empty center support plate, readable low-noise surface.\n"
            "No actual cells. No grid tiles. No pipes. No solved path markings. No text. No icons. No logo. No character. No gameplay screenshot.\n"
            "Must improve contrast behind existing black-green cyber cells and cyan-green energy VFX.\n"
            "Use reference images only for material language, bevel depth, glow color, fake3D cockpit proportion, and premium mobile game readability.\n"
            "Centered object, fully visible, clean alpha-friendly edge, generous #ff00ff removable background margin.\n"
        ),
    },
}


MODE_PROMPTS = {
    "dark": (
        "Mode: dark cyber. Black and deep green gameplay tone, cyan electric accent, glossy beveled sci-fi material, high contrast, not purple-dominant."
    ),
    "light": (
        "Mode: bright cyber light. Pale graphite and white-lit material, cyan electric accent, same bevel language as dark mode, readable on bright background, not beige."
    ),
}


def load_json(path: Path) -> dict:
    return json.loads(path.read_text(encoding="utf-8"))


def write_json(path: Path, data: dict) -> None:
    path.write_text(json.dumps(data, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")


def gateway() -> tuple[str, str, str]:
    base = os.environ.get("NINEROUTER_IMAGE_URL") or "https://img.teelab247.com"
    key = os.environ.get("NINEROUTER_IMAGE_KEY") or os.environ.get("NINEROUTER_KEY")
    key_source = "NINEROUTER_IMAGE_KEY" if os.environ.get("NINEROUTER_IMAGE_KEY") else "NINEROUTER_KEY"
    if not key:
        raise RuntimeError("No approved 9Router key found in NINEROUTER_IMAGE_KEY or NINEROUTER_KEY")
    return base.rstrip("/"), key, key_source


def request_json(url: str, key: str) -> dict:
    req = urllib.request.Request(url, headers={"Authorization": f"Bearer {key}"})
    with urllib.request.urlopen(req, timeout=30) as resp:
        return json.loads(resp.read().decode("utf-8"))


def verify_model(base: str, key: str) -> None:
    health = json.loads(urllib.request.urlopen(f"{base}/api/health", timeout=20).read().decode("utf-8"))
    models = request_json(f"{base}/v1/models/image", key)
    ids = [item.get("id") for item in models.get("data", [])]
    if not health.get("ok"):
        raise RuntimeError("9Router health check failed")
    if MODEL_ID not in ids:
        raise RuntimeError(f"{MODEL_ID} missing. Stop; no fallback allowed.")


def ref_urls(mode: str, component_key: str) -> list[str]:
    component = COMPONENTS[component_key]
    full_refs = load_json(FULL_REFS_PATH)["items"]
    component_refs = load_json(COMPONENT_REFS_PATH)["items"]
    urls: list[str] = []

    for item in component_refs:
        if item.get("mode") == mode and item.get("component") in component["component_refs"]:
            urls.append(item["url"])

    manifest = load_json(MANIFEST_PATH)
    for item in manifest.get("items", []):
        if item.get("mode") == mode and item.get("component_key") in component["production_refs"]:
            urls.append(item["r2_url"])

    for item in full_refs:
        if item.get("name") in ("gameplay_board_reference.png", "cyber_pipe_assets_reference.png", "cyber_energy_reference.png"):
            urls.append(item["url"])

    deduped: list[str] = []
    for url in urls:
        if url not in deduped:
            deduped.append(url)
    return deduped


def build_prompt(mode: str, component_key: str, urls: list[str]) -> str:
    component = COMPONENTS[component_key]
    return "\n".join(
        [
            component["base_prompt"],
            MODE_PROMPTS[mode],
            "Style anchor: cyber puzzle, fake3D cockpit layer, black/green gameplay tone, cyan electric accent, beveled glossy depth, mobile game readability.",
            "Output: PNG object on flat pure #ff00ff background for clean chroma key. Do not use gradients in the background. Object only.",
            "Reference image URLs for style synchronization:",
            "\n".join(urls),
        ]
    )


def generate_image(base: str, key: str, prompt: str, urls: list[str], size: str, out_path: Path, retries: int = 2) -> None:
    body = {
        "model": MODEL_ID,
        "prompt": prompt,
        "size": size,
        "output_format": "png",
        "image_detail": "high",
        "images": urls,
    }
    payload = json.dumps(body).encode("utf-8")
    last_error = None
    for attempt in range(retries + 1):
        req = urllib.request.Request(
            f"{base}/v1/images/generations?response_format=binary",
            data=payload,
            method="POST",
            headers={
                "Authorization": f"Bearer {key}",
                "Content-Type": "application/json",
            },
        )
        try:
            with urllib.request.urlopen(req, timeout=240) as resp:
                out_path.write_bytes(resp.read())
            return
        except urllib.error.HTTPError as exc:
            detail = exc.read().decode("utf-8", errors="replace")
            last_error = f"HTTP {exc.code}: {detail}"
            if exc.code not in (408, 429, 500, 502, 503, 504) or attempt == retries:
                break
            time.sleep(4 + attempt * 4)
        except Exception as exc:
            last_error = str(exc)
            if attempt == retries:
                break
            time.sleep(4 + attempt * 4)
    raise RuntimeError(last_error or "Image generation failed")


def is_magenta(r: int, g: int, b: int, _a: int) -> bool:
    return r >= 190 and b >= 170 and g <= 95 and (r - g) >= 110 and (b - g) >= 95


def clean_magenta_to_alpha(raw_path: Path, alpha_path: Path, padding: int = 28) -> tuple[int, int]:
    image = Image.open(raw_path).convert("RGBA")
    pixels = image.load()
    width, height = image.size
    visited = [[False] * height for _ in range(width)]
    queue: deque[tuple[int, int]] = deque()

    def add_if_bg(x: int, y: int) -> None:
        if visited[x][y]:
            return
        visited[x][y] = True
        if is_magenta(*pixels[x, y]):
            queue.append((x, y))

    for x in range(width):
        add_if_bg(x, 0)
        add_if_bg(x, height - 1)
    for y in range(height):
        add_if_bg(0, y)
        add_if_bg(width - 1, y)

    while queue:
        x, y = queue.popleft()
        pixels[x, y] = (255, 0, 255, 0)
        for nx, ny in ((x - 1, y), (x + 1, y), (x, y - 1), (x, y + 1)):
            if 0 <= nx < width and 0 <= ny < height and not visited[nx][ny]:
                visited[nx][ny] = True
                if is_magenta(*pixels[nx, ny]):
                    queue.append((nx, ny))

    bbox = image.getbbox()
    if not bbox:
        raise RuntimeError(f"alpha cleanup produced blank image: {raw_path}")

    left = max(0, bbox[0] - padding)
    top = max(0, bbox[1] - padding)
    right = min(width, bbox[2] + padding)
    bottom = min(height, bbox[3] + padding)
    cropped = image.crop((left, top, right, bottom))
    cropped.save(alpha_path)
    return cropped.size


def create_preview(project: Path, component_key: str, paths: dict[str, Path]) -> Path:
    images = {mode: Image.open(path).convert("RGBA") for mode, path in paths.items()}
    cell_w = max(image.width for image in images.values()) + 80
    cell_h = max(image.height for image in images.values()) + 120
    preview = Image.new("RGBA", (cell_w * len(images), cell_h), (21, 24, 28, 255))
    draw = ImageDraw.Draw(preview)
    for idx, (mode, image) in enumerate(images.items()):
        x0 = idx * cell_w
        checker = Image.new("RGBA", (cell_w, cell_h), (32, 36, 42, 255))
        cdraw = ImageDraw.Draw(checker)
        for y in range(0, cell_h, 32):
            for x in range(0, cell_w, 32):
                if (x // 32 + y // 32) % 2 == 0:
                    cdraw.rectangle((x, y, x + 31, y + 31), fill=(48, 54, 62, 255))
        preview.alpha_composite(checker, (x0, 0))
        px = x0 + (cell_w - image.width) // 2
        py = 64 + (cell_h - 96 - image.height) // 2
        preview.alpha_composite(image, (px, py))
        draw.text((x0 + 24, 24), f"{mode} {component_key}", fill=(230, 245, 250, 255))
    out = project / "debug" / f"{component_key}_dark_light_alpha_preview.png"
    out.parent.mkdir(parents=True, exist_ok=True)
    preview.save(out)
    return out


def sha256(path: Path) -> str:
    h = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            h.update(chunk)
    return h.hexdigest().upper()


def upload(path: Path, key: str) -> str:
    spec = importlib.util.spec_from_file_location("old_upload_server", UPLOADER_PATH)
    if spec is None or spec.loader is None:
        raise RuntimeError(f"Cannot import uploader: {UPLOADER_PATH}")
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module.upload_to_r2(path.read_bytes(), key, "image/png")


def existing_component_record(mode: str, component_key: str, alpha_path: Path) -> dict | None:
    manifest = load_json(MANIFEST_PATH)
    for item in manifest.get("items", []):
        if item.get("mode") == mode and item.get("component_key") == component_key:
            return item
    raw_path = alpha_path.with_name(f"{component_key}_raw.png")
    if not alpha_path.exists() or not raw_path.exists():
        return None
    r2_key = f"{PUBLIC_PREFIX}/{mode}/{component_key}_alpha.png"
    r2_url = upload(alpha_path, r2_key)
    image = Image.open(alpha_path).convert("RGBA")
    return record_component(
        mode,
        component_key,
        raw_path,
        alpha_path,
        r2_url,
        r2_key,
        image.size,
        "Recovered from existing generated alpha candidate after interrupted generation run.",
        [],
    )


def upsert_manifest_item(manifest: dict, item: dict) -> None:
    items = manifest.setdefault("items", [])
    for index, existing in enumerate(items):
        if existing.get("mode") == item.get("mode") and existing.get("component_key") == item.get("component_key"):
            items[index] = item
            return
    items.append(item)


def record_component(mode: str, component_key: str, raw_path: Path, alpha_path: Path, r2_url: str, r2_key: str, pixel_size: tuple[int, int], prompt: str, refs: list[str]) -> dict:
    component = COMPONENTS[component_key]
    return {
        "mode": mode,
        "component_key": component_key,
        "local_path": str(alpha_path),
        "raw_local_path": str(raw_path),
        "r2_key": r2_key,
        "r2_url": r2_url,
        "content_type": "image/png",
        "bytes": alpha_path.stat().st_size,
        "sha256": sha256(alpha_path),
        "pixel_size": list(pixel_size),
        "asset_stage": "alpha_candidate",
        "background_removal": component["background_removal"],
        "anchor": component["anchor"],
        "draw_rect": f"SSOT pending after owner approval; shared canonical {component_key} rect",
        "content_padding": component["content_padding"],
        "safe_overdraw": component["safe_overdraw"],
        "scale_policy": component["scale_policy"],
        "source_refs": [
            "docs/ui_cyber_reference_pack_r2.json",
            "docs/ui_cyber_dark_light_component_refs_r2.json",
            "docs/ui_cyber_9router_component_call_queue.md",
        ],
        "reference_urls": refs,
        "prompt": prompt,
        "acceptance_status": "pending_owner_visual_approval",
    }


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("component", choices=sorted(COMPONENTS))
    parser.add_argument("--modes", nargs="+", default=["dark", "light"], choices=["dark", "light"])
    args = parser.parse_args()

    base, key, key_source = gateway()
    verify_model(base, key)
    print(json.dumps({"base": base, "key_source": key_source, "model": MODEL_ID, "component": args.component}, ensure_ascii=False))

    manifest = load_json(MANIFEST_PATH)
    generated: dict[str, Path] = {}
    records: list[dict] = []
    for mode in args.modes:
        out_dir = PROJECT / "Assets" / "UI" / "cyberpunk_theme" / "generated" / "production" / mode
        out_dir.mkdir(parents=True, exist_ok=True)
        raw_path = out_dir / f"{args.component}_raw.png"
        alpha_path = out_dir / f"{args.component}_alpha.png"
        refs = ref_urls(mode, args.component)
        prompt = build_prompt(mode, args.component, refs)
        generate_image(base, key, prompt, refs, COMPONENTS[args.component]["size"], raw_path)
        pixel_size = clean_magenta_to_alpha(raw_path, alpha_path)
        r2_key = f"{PUBLIC_PREFIX}/{mode}/{args.component}_alpha.png"
        r2_url = upload(alpha_path, r2_key)
        record = record_component(mode, args.component, raw_path, alpha_path, r2_url, r2_key, pixel_size, prompt, refs)
        upsert_manifest_item(manifest, record)
        generated[mode] = alpha_path
        records.append(record)
        write_json(MANIFEST_PATH, manifest)
        print(json.dumps({"mode": mode, "raw": str(raw_path), "alpha": str(alpha_path), "pixel_size": pixel_size, "r2_url": r2_url}, ensure_ascii=False))

    for mode in ("dark", "light"):
        if mode in generated:
            continue
        candidate = PROJECT / "Assets" / "UI" / "cyberpunk_theme" / "generated" / "production" / mode / f"{args.component}_alpha.png"
        recovered = existing_component_record(mode, args.component, candidate)
        if recovered:
            upsert_manifest_item(manifest, recovered)
            generated[mode] = candidate

    preview_path = create_preview(PROJECT, args.component, generated)
    preview_key = f"{PUBLIC_PREFIX}/debug/{preview_path.name}"
    preview_url = upload(preview_path, preview_key)
    preview_record = {
        "mode": "debug",
        "component_key": f"{args.component}_dark_light_alpha_preview",
        "local_path": str(preview_path),
        "r2_key": preview_key,
        "r2_url": preview_url,
        "content_type": "image/png",
        "bytes": preview_path.stat().st_size,
        "sha256": sha256(preview_path),
        "asset_stage": "preview",
        "background_removal": COMPONENTS[args.component]["background_removal"],
        "acceptance_status": "debug_preview",
    }
    upsert_manifest_item(manifest, preview_record)
    manifest["updated_at"] = "2026-07-01"
    write_json(MANIFEST_PATH, manifest)
    print(json.dumps({"preview": str(preview_path), "preview_url": preview_url, "records": len(records)}, ensure_ascii=False))
    return 0


if __name__ == "__main__":
    sys.exit(main())
