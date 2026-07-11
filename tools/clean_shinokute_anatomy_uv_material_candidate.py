from __future__ import annotations

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


def material(name: str, color: tuple[float, float, float, float]) -> bpy.types.Material:
    mat = bpy.data.materials.new(name)
    mat.diffuse_color = color
    mat.use_nodes = True
    bsdf = mat.node_tree.nodes.get("Principled BSDF")
    if bsdf:
        bsdf.inputs["Base Color"].default_value = color
        bsdf.inputs["Roughness"].default_value = 0.82
    return mat


def bounds(mesh_obj: bpy.types.Object) -> tuple[Vector, Vector]:
    coords = [mesh_obj.matrix_world @ Vector(corner) for corner in mesh_obj.bound_box]
    mins = Vector((min(v.x for v in coords), min(v.y for v in coords), min(v.z for v in coords)))
    maxs = Vector((max(v.x for v in coords), max(v.y for v in coords), max(v.z for v in coords)))
    return mins, maxs


def main() -> None:
    src = Path(arg("--input"))
    out = Path(arg("--output"))
    if not src.exists():
        raise FileNotFoundError(src)

    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete()
    bpy.ops.import_scene.gltf(filepath=str(src))

    mesh_objs = [obj for obj in bpy.context.scene.objects if obj.type == "MESH"]
    if not mesh_objs:
        raise RuntimeError("No mesh in source GLB")
    mesh = mesh_objs[0]
    mins, maxs = bounds(mesh)
    size = maxs - mins

    base_count = len(mesh.data.materials)
    skin_mat = material("Shinokute_Skin_Cleanup_From_SSOT", (0.72, 0.50, 0.36, 1.0))
    black_mat = material("Shinokute_Black_Fabric_Cleanup_From_SSOT", (0.015, 0.016, 0.018, 1.0))
    mesh.data.materials.append(skin_mat)
    skin_index = base_count
    mesh.data.materials.append(black_mat)
    black_index = base_count + 1

    for poly in mesh.data.polygons:
        center = mesh.matrix_world @ poly.center
        z_norm = (center.z - mins.z) / max(0.001, size.z)
        x_norm = (center.x - mins.x) / max(0.001, size.x)
        y_norm = (center.y - mins.y) / max(0.001, size.y)
        normal = (mesh.matrix_world.to_3x3() @ poly.normal).normalized()

        # Only clean zones where projection tearing was visible; keep hoodie/shoe
        # projected texture because those details read well in the candidate.
        front_face = normal.y < -0.35 and 0.74 <= z_norm <= 0.89 and 0.32 <= x_norm <= 0.68
        exposed_legs = 0.14 <= z_norm <= 0.33 and 0.26 <= x_norm <= 0.74 and 0.20 <= y_norm <= 0.84
        hands = 0.34 <= z_norm <= 0.49 and (x_norm < 0.22 or x_norm > 0.78)
        sock_band = 0.09 <= z_norm < 0.15 and 0.28 <= x_norm <= 0.72

        if front_face or exposed_legs or hands:
            poly.material_index = skin_index
        elif sock_band:
            poly.material_index = black_index

    mesh["shinokute_cleanup_source"] = "projection candidate with SSOT-zone skin cleanup"
    out.parent.mkdir(parents=True, exist_ok=True)
    bpy.ops.export_scene.gltf(filepath=str(out), export_format="GLB")


if __name__ == "__main__":
    main()
