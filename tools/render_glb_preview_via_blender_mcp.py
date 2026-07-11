from __future__ import annotations

import json
import socket
import sys
from pathlib import Path


def arg(name: str, default: str = "") -> str:
    if name not in sys.argv:
        return default
    index = sys.argv.index(name)
    if index + 1 >= len(sys.argv):
        return default
    return sys.argv[index + 1]


def send_execute_code(code: str, host: str = "127.0.0.1", port: int = 9876) -> dict:
    payload = json.dumps({"type": "execute_code", "params": {"code": code}}).encode("utf-8")
    with socket.create_connection((host, port), timeout=20) as client:
        client.settimeout(None)
        client.sendall(payload)
        chunks: list[bytes] = []
        while True:
            chunk = client.recv(65536)
            if not chunk:
                break
            chunks.append(chunk)
            try:
                return json.loads(b"".join(chunks).decode("utf-8"))
            except json.JSONDecodeError:
                continue
    raise RuntimeError("Blender MCP closed without JSON response")


def blender_render_code(glb: Path, out_dir: Path) -> str:
    glb_s = str(glb).replace("\\", "\\\\")
    out_s = str(out_dir).replace("\\", "\\\\")
    return f"""
import math
from pathlib import Path
import bpy
from mathutils import Vector

glb = Path(r"{glb_s}")
out_dir = Path(r"{out_s}")
if not glb.exists():
    raise FileNotFoundError(str(glb))
out_dir.mkdir(parents=True, exist_ok=True)

bpy.ops.object.select_all(action="SELECT")
bpy.ops.object.delete()
bpy.ops.import_scene.gltf(filepath=str(glb))

coords = []
for obj in bpy.context.scene.objects:
    if obj.type == "MESH":
        for corner in obj.bound_box:
            coords.append(obj.matrix_world @ Vector(corner))
if not coords:
    raise RuntimeError("No mesh objects imported")

mins = Vector((min(v.x for v in coords), min(v.y for v in coords), min(v.z for v in coords)))
maxs = Vector((max(v.x for v in coords), max(v.y for v in coords), max(v.z for v in coords)))
center = (mins + maxs) * 0.5
size = maxs - mins
longest = max(size.x, size.y, size.z, 0.001)
scale = 2.4 / longest
for obj in bpy.context.scene.objects:
    if obj.type == "MESH":
        obj.location -= center
        obj.scale *= scale

scene = bpy.context.scene
scene.render.engine = "BLENDER_EEVEE_NEXT"
scene.eevee.taa_render_samples = 64
scene.render.resolution_x = 900
scene.render.resolution_y = 1100
scene.view_settings.view_transform = "Filmic"
scene.view_settings.look = "Medium High Contrast"
scene.world = bpy.data.worlds.new("PreviewWorld") if scene.world is None else scene.world
scene.world.color = (0.78, 0.86, 0.95)

bpy.ops.object.light_add(type="AREA", location=(0, -4, 5))
key = bpy.context.object
key.name = "PreviewKeyLight"
key.data.energy = 450
key.data.size = 5

bpy.ops.object.light_add(type="POINT", location=(-3, 3, 3))
fill = bpy.context.object
fill.name = "PreviewFillLight"
fill.data.energy = 80

bpy.ops.object.camera_add(location=(0, -5.5, 1.8))
camera = bpy.context.object
camera.name = "PreviewCamera"
camera.data.lens = 70
camera.data.dof.use_dof = False
scene.camera = camera

def look_at(obj, target):
    direction = target - obj.location
    obj.rotation_euler = direction.to_track_quat("-Z", "Y").to_euler()

target = Vector((0, 0, 0.25))
distance = 5.2
height = 1.25
angles = [
    ("front", 180),
    ("front_left_3q", 135),
    ("left", 90),
    ("back", 0),
    ("right", 270),
    ("front_right_3q", 225),
]
for name, degrees in angles:
    rad = math.radians(degrees)
    camera.location = Vector((math.sin(rad) * distance, math.cos(rad) * distance, height))
    look_at(camera, target)
    scene.render.filepath = str(out_dir / f"{{name}}.png")
    bpy.ops.render.render(write_still=True)

print("rendered", str(glb), "to", str(out_dir))
"""


def main() -> int:
    glb = Path(arg("--input")).resolve()
    out_dir = Path(arg("--out-dir")).resolve()
    response = send_execute_code(blender_render_code(glb, out_dir))
    print(json.dumps(response, indent=2))
    if response.get("status") != "success":
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
