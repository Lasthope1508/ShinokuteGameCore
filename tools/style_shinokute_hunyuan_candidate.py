from __future__ import annotations

import math
import sys
import json
from pathlib import Path

import bpy
from mathutils import Vector


ROOT = Path(__file__).resolve().parents[1]
SSOT_PATH = ROOT / "assets" / "themes" / "candy_sky_islands" / "source" / "shinokute_player" / "shinokute_character_3d_ssot.json"


def _arg(name: str, default: str = "") -> str:
    argv = sys.argv
    if "--" not in argv:
        return default
    args = argv[argv.index("--") + 1 :]
    for i, item in enumerate(args):
        if item == name and i + 1 < len(args):
            return args[i + 1]
    return default


def _mat(name: str, color: tuple[float, float, float, float], roughness: float = 0.72) -> bpy.types.Material:
    mat = bpy.data.materials.new(name)
    mat.use_nodes = True
    bsdf = mat.node_tree.nodes.get("Principled BSDF")
    if bsdf:
        bsdf.inputs["Base Color"].default_value = color
        bsdf.inputs["Roughness"].default_value = roughness
    return mat


def _bounds(mesh_obj: bpy.types.Object) -> tuple[Vector, Vector]:
    coords = [mesh_obj.matrix_world @ Vector(corner) for corner in mesh_obj.bound_box]
    mins = Vector((min(v.x for v in coords), min(v.y for v in coords), min(v.z for v in coords)))
    maxs = Vector((max(v.x for v in coords), max(v.y for v in coords), max(v.z for v in coords)))
    return mins, maxs


def _assign_materials(mesh_obj: bpy.types.Object) -> None:
    ssot = json.loads(SSOT_PATH.read_text(encoding="utf-8"))
    zones = ssot["zones"]
    mats = {
        "hoodie": _mat("Shinokute_Hoodie_Black", (0.006, 0.007, 0.009, 1.0)),
        "shorts": _mat("Shinokute_Shorts_Black", (0.01, 0.011, 0.013, 1.0)),
        "hair": _mat("Shinokute_Hair_Black", (0.002, 0.002, 0.003, 1.0)),
        "skin": _mat("Shinokute_Skin", (0.98, 0.70, 0.52, 1.0)),
        "shoe_black": _mat("Shinokute_Shoe_Black", (0.005, 0.005, 0.006, 1.0)),
        "shoe_red": _mat("Shinokute_Shoe_Red", (0.86, 0.05, 0.05, 1.0)),
        "sole": _mat("Shinokute_Sole_White", (0.93, 0.93, 0.90, 1.0)),
    }
    order = ["hoodie", "shorts", "hair", "skin", "shoe_black", "shoe_red", "sole"]
    for key in order:
        mesh_obj.data.materials.append(mats[key])

    mins, maxs = _bounds(mesh_obj)
    height = maxs.z - mins.z

    def nz(z: float) -> float:
        return (z - mins.z) / max(height, 0.001)

    for poly in mesh_obj.data.polygons:
        center = mesh_obj.matrix_world @ poly.center
        zn = nz(center.z)
        ax = abs(center.x)
        front = center.y < 0

        material_key = "hoodie"
        face = zones["face"]
        hair = zones["hair"]
        hoodie = zones["hoodie_body"]
        shorts = zones["shorts"]
        legs = zones["legs"]
        socks = zones["socks"]
        shoes = zones["shoes"]

        if (
            front
            and face["z_norm_min"] <= zn <= face["z_norm_max"]
            and ax <= face["abs_x_max"]
            and center.y < -0.11
        ):
            material_key = "skin"
        elif zn >= hair["z_norm_min"]:
            material_key = "hair"
        elif 0.24 < zn < 0.40 and ax > 0.20 and center.z < -0.20:
            material_key = "skin"
        elif legs["z_norm_min"] <= zn < legs["z_norm_max"] and ax < 0.17:
            material_key = "skin"
        elif shorts["z_norm_min"] <= zn < shorts["z_norm_max"]:
            material_key = "shorts"
        elif zn < shoes["z_norm_max"]:
            material_key = "shoe_red" if front else "shoe_black"
        elif zn < socks["z_norm_max"]:
            material_key = "shoe_black"
        elif socks["z_norm_max"] <= zn < shorts["z_norm_min"]:
            material_key = "skin"
        elif hoodie["z_norm_min"] <= zn < hoodie["z_norm_max"]:
            material_key = "hoodie"
        elif zn >= 0.74:
            material_key = "hair"

        poly.material_index = order.index(material_key)

    mesh_obj.select_set(True)
    bpy.context.view_layer.objects.active = mesh_obj
    bpy.ops.object.shade_smooth()


def _add_hoodie_text(mesh_obj: bpy.types.Object) -> None:
    ssot = json.loads(SSOT_PATH.read_text(encoding="utf-8"))
    text_zone = ssot["zones"]["hoodie_text"]
    mins, maxs = _bounds(mesh_obj)
    y_front = mins.y - 0.012
    z = mins.z + (maxs.z - mins.z) * float(text_zone["z_norm"])
    bpy.ops.object.text_add(location=(0, y_front, z), rotation=(math.radians(90), 0, 0))
    text = bpy.context.object
    text.name = "Shinokute_Hoodie_Text_Decal"
    text.data.body = "SHINOKUTE"
    text.data.align_x = "CENTER"
    text.data.align_y = "CENTER"
    text.data.size = 0.052
    text.data.extrude = 0.0015
    white = _mat("Shinokute_Text_White", (0.96, 0.96, 0.90, 1.0))
    text.data.materials.append(white)


def main() -> None:
    src = Path(_arg("--input"))
    out = Path(_arg("--output"))
    if not src.exists():
        raise FileNotFoundError(src)
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete()
    bpy.ops.import_scene.gltf(filepath=str(src))
    mesh_objs = [obj for obj in bpy.context.scene.objects if obj.type == "MESH"]
    if not mesh_objs:
        raise RuntimeError("No mesh in source GLB")
    mesh = mesh_objs[0]
    mesh.name = "Shinokute_Hunyuan_Styled_Geometry"
    _assign_materials(mesh)
    _add_hoodie_text(mesh)
    out.parent.mkdir(parents=True, exist_ok=True)
    bpy.ops.export_scene.gltf(filepath=str(out), export_format="GLB")


if __name__ == "__main__":
    main()
