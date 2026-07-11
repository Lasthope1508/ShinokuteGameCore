from __future__ import annotations

import json
import time
from pathlib import Path

import torch
import trimesh
from PIL import Image

from hy3dgen.texgen import Hunyuan3DPaintPipeline


ROOT = Path(__file__).resolve().parents[1]
POOL = ROOT / "assets" / "themes" / "candy_sky_islands" / "source" / "shinokute_player" / "standing_multiview_pool"
MESH_IN = ROOT / "assets" / "themes" / "candy_sky_islands" / "models" / "character_shinokute_hunyuan_mv_candidate.glb"
MESH_OUT = ROOT / "assets" / "themes" / "candy_sky_islands" / "models" / "character_shinokute_hunyuan_mv_textured_candidate.glb"
REPORT = ROOT / "assets" / "themes" / "candy_sky_islands" / "source" / "shinokute_player" / "shinokute_hunyuan_mv_textured_candidate_report.json"


def _load_rgba(path: Path) -> Image.Image:
    return Image.open(path).convert("RGBA")


def main() -> int:
    inputs = [
        POOL / "shinokute_standing_front.png",
        POOL / "shinokute_standing_left_side.png",
        POOL / "shinokute_standing_back.png",
        POOL / "shinokute_standing_front_right_3q.png",
    ]
    missing = [str(path) for path in [MESH_IN, *inputs] if not path.exists()]
    if missing:
        raise FileNotFoundError(missing)

    images = [_load_rgba(path) for path in inputs]
    mesh = trimesh.load(str(MESH_IN), force="mesh")

    start = time.time()
    pipeline = Hunyuan3DPaintPipeline.from_pretrained(
        "tencent/Hunyuan3D-2",
        subfolder="hunyuan3d-paint-v2-0-turbo",
    )
    if hasattr(pipeline, "enable_model_cpu_offload"):
        try:
            pipeline.enable_model_cpu_offload()
        except Exception as exc:
            print(f"enable_model_cpu_offload skipped: {exc}")

    # Keep first pass lighter for RTX 3050-class VRAM. This candidate is for QA,
    # not final texture resolution.
    pipeline.config.render_size = 1024
    pipeline.config.texture_size = 1024
    if hasattr(pipeline.render, "set_default_texture_resolution"):
        pipeline.render.set_default_texture_resolution(1024)

    textured_mesh = pipeline(mesh, image=images)
    MESH_OUT.parent.mkdir(parents=True, exist_ok=True)
    textured_mesh.export(str(MESH_OUT))

    report = {
        "output": str(MESH_OUT),
        "input_mesh": str(MESH_IN),
        "inputs": [str(path) for path in inputs],
        "seconds": round(time.time() - start, 2),
        "pipeline": "Hunyuan3D-2/hunyuan3d-paint-v2-0-turbo",
        "render_size": pipeline.config.render_size,
        "texture_size": pipeline.config.texture_size,
        "owner_exception": "front_right_3q mirrored texture accepted by owner on 2026-07-08 despite reversed hoodie text.",
        "status": "candidate_not_integrated",
    }
    REPORT.write_text(json.dumps(report, indent=2), encoding="utf-8")
    print(json.dumps(report, indent=2))
    if torch.cuda.is_available():
        torch.cuda.empty_cache()
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
