from __future__ import annotations

import math
import sys
from pathlib import Path

import bpy
from mathutils import Vector


def _arg(name: str, default: str = "") -> str:
    argv = sys.argv
    if "--" not in argv:
        return default
    args = argv[argv.index("--") + 1 :]
    for i, item in enumerate(args):
        if item == name and i + 1 < len(args):
            return args[i + 1]
    return default


def _clear_scene() -> None:
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete()


def _mesh_bounds() -> tuple[Vector, Vector, Vector]:
    coords: list[Vector] = []
    for obj in bpy.context.scene.objects:
        if obj.type != "MESH":
            continue
        for corner in obj.bound_box:
            coords.append(obj.matrix_world @ Vector(corner))
    if not coords:
        return Vector((0, 0, 0)), Vector((1, 1, 1)), Vector((0, 0, 0))
    mins = Vector((min(v.x for v in coords), min(v.y for v in coords), min(v.z for v in coords)))
    maxs = Vector((max(v.x for v in coords), max(v.y for v in coords), max(v.z for v in coords)))
    center = (mins + maxs) * 0.5
    return mins, maxs, center


def _normalize_model() -> float:
    mins, maxs, center = _mesh_bounds()
    size = maxs - mins
    longest = max(size.x, size.y, size.z, 0.001)
    scale = 2.4 / longest
    for obj in bpy.context.scene.objects:
        if obj.type == "MESH":
            obj.location -= center
            obj.scale *= scale
    return longest


def _look_at(obj: bpy.types.Object, target: Vector) -> None:
    direction = target - obj.location
    obj.rotation_euler = direction.to_track_quat("-Z", "Y").to_euler()


def _setup_scene() -> None:
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


def _render_angles(out_dir: Path) -> None:
    out_dir.mkdir(parents=True, exist_ok=True)
    camera = bpy.context.scene.camera
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
        _look_at(camera, target)
        bpy.context.scene.render.filepath = str(out_dir / f"{name}.png")
        bpy.ops.render.render(write_still=True)


def main() -> None:
    glb = Path(_arg("--input"))
    out_dir = Path(_arg("--out-dir"))
    if not glb.exists():
        raise FileNotFoundError(glb)
    _clear_scene()
    bpy.ops.import_scene.gltf(filepath=str(glb))
    _normalize_model()
    _setup_scene()
    _render_angles(out_dir)


if __name__ == "__main__":
    main()
