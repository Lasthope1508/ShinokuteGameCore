from __future__ import annotations

import json
import sys
from pathlib import Path

import bpy
from mathutils import Vector


def arg(name: str, default: str = "") -> str:
    if name not in sys.argv:
        return default
    index = sys.argv.index(name)
    if index + 1 >= len(sys.argv):
        return default
    return sys.argv[index + 1]


def make_material(name: str, color: tuple[float, float, float, float]) -> bpy.types.Material:
    mat = bpy.data.materials.new(name)
    mat.diffuse_color = color
    mat.use_nodes = True
    bsdf = mat.node_tree.nodes.get("Principled BSDF")
    if bsdf:
        bsdf.inputs["Base Color"].default_value = color
        bsdf.inputs["Roughness"].default_value = 0.84
    return mat


def mesh_bounds(mesh_obj: bpy.types.Object) -> tuple[Vector, Vector]:
    coords = [mesh_obj.matrix_world @ Vector(corner) for corner in mesh_obj.bound_box]
    mins = Vector((min(v.x for v in coords), min(v.y for v in coords), min(v.z for v in coords)))
    maxs = Vector((max(v.x for v in coords), max(v.y for v in coords), max(v.z for v in coords)))
    return mins, maxs


def main() -> None:
    src = Path(arg("--input"))
    out = Path(arg("--output"))
    report = Path(arg("--report", ""))
    if not src.exists():
        raise FileNotFoundError(src)

    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete()
    bpy.ops.import_scene.gltf(filepath=str(src))
    mesh_objs = [obj for obj in bpy.context.scene.objects if obj.type == "MESH"]
    if not mesh_objs:
        raise RuntimeError("No mesh in source GLB")

    mesh = mesh_objs[0]
    mins, maxs = mesh_bounds(mesh)
    size = maxs - mins
    normal_matrix = mesh.matrix_world.to_3x3()

    base_count = len(mesh.data.materials)
    skin_mat = make_material("Shinokute_Face_Depth_Gated_Skin", (0.68, 0.52, 0.42, 1.0))
    mesh.data.materials.append(skin_mat)
    skin_index = base_count

    changed = 0
    tested_face_band = 0
    for poly in mesh.data.polygons:
        center = mesh.matrix_world @ poly.center
        normal = (normal_matrix @ poly.normal).normalized()
        x_norm = (center.x - mins.x) / max(0.001, size.x)
        y_norm = (center.y - mins.y) / max(0.001, size.y)
        z_norm = (center.z - mins.z) / max(0.001, size.z)

        # Front is negative Y. A true face surface is close to the front-most
        # depth of the head; the hoodie hood sits around/behind it. This prevents
        # skin material from being painted onto the hood just because it shares
        # the same x/z rectangle.
        in_face_height = 0.755 <= z_norm <= 0.885
        in_face_width = 0.37 <= x_norm <= 0.63
        front_most = y_norm <= 0.28
        faces_forward = normal.y < -0.18
        if in_face_height and in_face_width:
            tested_face_band += 1
        if in_face_height and in_face_width and front_most and faces_forward:
            poly.material_index = skin_index
            changed += 1

    mesh["shinokute_cleanup_source"] = "face depth gated cleanup; hood remains projection texture"
    out.parent.mkdir(parents=True, exist_ok=True)
    bpy.ops.export_scene.gltf(filepath=str(out), export_format="GLB")

    if str(report):
        data = {
            "source": str(src),
            "output": str(out),
            "bounds": {
                "min": [round(mins.x, 6), round(mins.y, 6), round(mins.z, 6)],
                "max": [round(maxs.x, 6), round(maxs.y, 6), round(maxs.z, 6)],
                "size": [round(size.x, 6), round(size.y, 6), round(size.z, 6)],
            },
            "face_band_polygons": tested_face_band,
            "face_depth_gated_skin_polygons": changed,
            "front_axis": "negative_y",
            "status": "candidate_not_integrated",
        }
        report.parent.mkdir(parents=True, exist_ok=True)
        report.write_text(json.dumps(data, indent=2), encoding="utf-8")


if __name__ == "__main__":
    main()
