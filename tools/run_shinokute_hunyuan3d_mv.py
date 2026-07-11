from __future__ import annotations

import json
import time
from pathlib import Path

import torch
from PIL import Image

from hy3dgen.shapegen import Hunyuan3DDiTFlowMatchingPipeline


ROOT = Path(__file__).resolve().parents[1]
POOL = ROOT / "assets" / "themes" / "candy_sky_islands" / "source" / "shinokute_player" / "standing_multiview_pool"
OUT = ROOT / "assets" / "themes" / "candy_sky_islands" / "models" / "character_shinokute_hunyuan_mv_candidate.glb"
REPORT = ROOT / "assets" / "themes" / "candy_sky_islands" / "source" / "shinokute_player" / "shinokute_hunyuan_mv_candidate_report.json"


def load_rgba(path: Path) -> Image.Image:
    return Image.open(path).convert("RGBA")


def main() -> int:
    inputs = {
        "front": POOL / "shinokute_standing_front.png",
        "left": POOL / "shinokute_standing_left_side.png",
        "back": POOL / "shinokute_standing_back.png",
    }
    missing = [str(path) for path in inputs.values() if not path.exists()]
    if missing:
        raise FileNotFoundError(missing)

    images = {key: load_rgba(path) for key, path in inputs.items()}
    start = time.time()
    pipeline = Hunyuan3DDiTFlowMatchingPipeline.from_pretrained(
        "tencent/Hunyuan3D-2mv",
        subfolder="hunyuan3d-dit-v2-mv-turbo",
        variant="fp16",
    )
    if hasattr(pipeline, "enable_flashvdm"):
        try:
            pipeline.enable_flashvdm()
        except Exception as exc:
            print(f"enable_flashvdm skipped: {exc}")

    mesh = pipeline(
        image=images,
        num_inference_steps=5,
        octree_resolution=256,
        num_chunks=16000,
        generator=torch.manual_seed(12345),
        output_type="trimesh",
    )[0]
    OUT.parent.mkdir(parents=True, exist_ok=True)
    mesh.export(OUT)
    report = {
        "output": str(OUT),
        "inputs": {key: str(path) for key, path in inputs.items()},
        "seconds": round(time.time() - start, 2),
        "vertices": int(len(mesh.vertices)) if hasattr(mesh, "vertices") else None,
        "faces": int(len(mesh.faces)) if hasattr(mesh, "faces") else None,
        "pipeline": "Hunyuan3D-2mv/hunyuan3d-dit-v2-mv-turbo",
        "steps": 5,
        "octree_resolution": 256,
        "num_chunks": 16000,
    }
    REPORT.write_text(json.dumps(report, indent=2), encoding="utf-8")
    print(json.dumps(report, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
