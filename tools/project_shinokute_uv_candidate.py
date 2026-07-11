from __future__ import annotations

import json
import sys
from pathlib import Path

import bpy
from mathutils import Vector


ROOT = Path(__file__).resolve().parents[1]
SSOT_PATH = ROOT / "assets" / "themes" / "candy_sky_islands" / "source" / "shinokute_player" / "shinokute_character_3d_ssot.json"
ATLAS_META = ROOT / "assets" / "themes" / "candy_sky_islands" / "source" / "shinokute_player" / "projection" / "shinokute_projection_atlas_meta.json"


def _arg(name: str, default: str = "") -> str:
    argv = sys.argv
    if "--" not in argv:
        return default
    args = argv[argv.index("--") + 1 :]
    for i, item in enumerate(args):
        if item == name and i + 1 < len(args):
            return args[i + 1]
    return default


def _bounds(mesh_obj: bpy.types.Object) -> tuple[Vector, Vector]:
    coords = [mesh_obj.matrix_world @ Vector(corner) for corner in mesh_obj.bound_box]
    mins = Vector((min(v.x for v in coords), min(v.y for v in coords), min(v.z for v in coords)))
    maxs = Vector((max(v.x for v in coords), max(v.y for v in coords), max(v.z for v in coords)))
    return mins, maxs


def _clamp(value: float, lo: float = 0.0, hi: float = 1.0) -> float:
    return max(lo, min(hi, value))


def _rect_uv(rect: list[float], local_u: float, local_v: float) -> tuple[float, float]:
    u0, v0, w, h = rect
    margin_u = 0.015 * w
    margin_v = 0.015 * h
    return (
        u0 + margin_u + _clamp(local_u) * max(0.001, w - margin_u * 2.0),
        v0 + margin_v + _clamp(local_v) * max(0.001, h - margin_v * 2.0),
    )


def _view_for_normal(normal: Vector) -> str:
    # Current mesh convention: preview front is negative Y.
    if normal.y < -0.45:
        if normal.x > 0.25:
            return "front_left_3q"
        if normal.x < -0.25:
            return "front_right_3q"
        return "front"
    if normal.y > 0.45:
        if normal.x > 0.25:
            return "back_left_3q"
        if normal.x < -0.25:
            return "back_right_3q"
        return "back"
    if normal.x >= 0:
        return "left_side"
    return "right_side"


def _local_uv_for_view(view: str, point: Vector, mins: Vector, maxs: Vector) -> tuple[float, float]:
    size = maxs - mins
    x_norm = (point.x - mins.x) / max(0.001, size.x)
    y_norm = (point.y - mins.y) / max(0.001, size.y)
    z_norm = (point.z - mins.z) / max(0.001, size.z)

    if view == "front":
        return x_norm, z_norm
    if view == "back":
        return 1.0 - x_norm, z_norm
    if view == "left_side":
        return 1.0 - y_norm, z_norm
    if view == "right_side":
        return y_norm, z_norm
    if view == "front_left_3q":
        return (x_norm * 0.65 + (1.0 - y_norm) * 0.35), z_norm
    if view == "front_right_3q":
        return ((1.0 - x_norm) * 0.65 + (1.0 - y_norm) * 0.35), z_norm
    if view == "back_left_3q":
        return ((1.0 - x_norm) * 0.65 + y_norm * 0.35), z_norm
    if view == "back_right_3q":
        return (x_norm * 0.65 + y_norm * 0.35), z_norm
    return x_norm, z_norm


def _add_atlas_material(mesh_obj: bpy.types.Object, atlas_path: Path) -> None:
    image = bpy.data.images.load(str(atlas_path))
    image.colorspace_settings.name = "sRGB"
    material = bpy.data.materials.new("Shinokute_Project_From_Approved_Sprites")
    material.use_nodes = True
    material.diffuse_color = (1, 1, 1, 1)
    nodes = material.node_tree.nodes
    bsdf = nodes.get("Principled BSDF")
    tex = nodes.new("ShaderNodeTexImage")
    tex.image = image
    tex.extension = "CLIP"
    if bsdf:
        material.node_tree.links.new(tex.outputs["Color"], bsdf.inputs["Base Color"])
        bsdf.inputs["Roughness"].default_value = 0.78
    mesh_obj.data.materials.clear()
    mesh_obj.data.materials.append(material)
    for poly in mesh_obj.data.polygons:
        poly.material_index = 0


def _project_uv(mesh_obj: bpy.types.Object, meta: dict) -> None:
    mins, maxs = _bounds(mesh_obj)
    uv_layer = mesh_obj.data.uv_layers.get("ShinokuteSpriteProjection")
    if uv_layer is None:
        uv_layer = mesh_obj.data.uv_layers.new(name="ShinokuteSpriteProjection")

    normal_matrix = mesh_obj.matrix_world.to_3x3()
    for poly in mesh_obj.data.polygons:
        normal = (normal_matrix @ poly.normal).normalized()
        view = _view_for_normal(normal)
        rect = meta["views"][view]["uv_rect"]
        for loop_index in poly.loop_indices:
            loop = mesh_obj.data.loops[loop_index]
            point = mesh_obj.matrix_world @ mesh_obj.data.vertices[loop.vertex_index].co
            local_u, local_v = _local_uv_for_view(view, point, mins, maxs)
            uv_layer.data[loop_index].uv = _rect_uv(rect, local_u, local_v)


def main() -> None:
    src = Path(_arg("--input"))
    out = Path(_arg("--output"))
    if not src.exists():
        raise FileNotFoundError(src)
    ssot = json.loads(SSOT_PATH.read_text(encoding="utf-8"))
    meta = json.loads(ATLAS_META.read_text(encoding="utf-8"))
    atlas_path = Path(meta["atlas"])
    if not atlas_path.exists():
        raise FileNotFoundError(atlas_path)

    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete()
    bpy.ops.import_scene.gltf(filepath=str(src))
    mesh_objs = [obj for obj in bpy.context.scene.objects if obj.type == "MESH"]
    if not mesh_objs:
        raise RuntimeError("No mesh in source GLB")

    mesh = mesh_objs[0]
    mesh.name = "Shinokute_Hunyuan_SpriteProjected"
    _project_uv(mesh, meta)
    _add_atlas_material(mesh, atlas_path)
    mesh["shinokute_projection_ssot"] = str(SSOT_PATH)
    mesh["shinokute_projection_source"] = ssot["texture_pipeline"]["preferred"]

    out.parent.mkdir(parents=True, exist_ok=True)
    bpy.ops.export_scene.gltf(filepath=str(out), export_format="GLB")


if __name__ == "__main__":
    main()
