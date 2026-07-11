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


def make_mat(name: str, color: tuple[float, float, float, float]) -> bpy.types.Material:
    mat = bpy.data.materials.new(name)
    mat.diffuse_color = color
    mat.use_nodes = True
    bsdf = mat.node_tree.nodes.get("Principled BSDF")
    if bsdf:
        bsdf.inputs["Base Color"].default_value = color
        bsdf.inputs["Roughness"].default_value = 0.84
    return mat


def mesh_bounds(obj: bpy.types.Object) -> tuple[Vector, Vector]:
    coords = [obj.matrix_world @ Vector(corner) for corner in obj.bound_box]
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
    meshes = [obj for obj in bpy.context.scene.objects if obj.type == "MESH"]
    if not meshes:
        raise RuntimeError("No mesh in source GLB")

    mesh = meshes[0]
    mins, maxs = mesh_bounds(mesh)
    size = maxs - mins
    normal_matrix = mesh.matrix_world.to_3x3()

    base_count = len(mesh.data.materials)
    skin = make_mat("Shinokute_Anatomy_Skin_V3", (0.64, 0.48, 0.36, 1.0))
    sock = make_mat("Shinokute_Sock_Black_V3", (0.012, 0.013, 0.015, 1.0))
    mesh.data.materials.append(skin)
    skin_idx = base_count
    mesh.data.materials.append(sock)
    sock_idx = base_count + 1

    counts = {
        "face_cheek_skin": 0,
        "small_neck_skin": 0,
        "hand_skin": 0,
        "leg_skin": 0,
        "sock_black": 0,
    }

    for poly in mesh.data.polygons:
        center = mesh.matrix_world @ poly.center
        normal = (normal_matrix @ poly.normal).normalized()
        x = (center.x - mins.x) / max(0.001, size.x)
        y = (center.y - mins.y) / max(0.001, size.y)
        z = (center.z - mins.z) / max(0.001, size.z)

        front_most = y <= 0.285
        faces_front = normal.y < -0.16
        side_face = abs(normal.x) > 0.32 and y <= 0.36
        leg_col = (0.235 <= x <= 0.465) or (0.535 <= x <= 0.765)

        # Face/cheek: front-depth gated so hair/hood sharing x/z is untouched.
        face_cheek = 0.765 <= z <= 0.885 and 0.31 <= x <= 0.69 and front_most and (faces_front or side_face)
        # Neck only: tiny front-most window above hoodie collar. Wider/lower ranges
        # paint the hoodie chest as skin, so keep this deliberately narrow.
        small_neck = 0.705 <= z < 0.755 and 0.445 <= x <= 0.555 and y <= 0.205 and faces_front
        hand = 0.335 <= z <= 0.49 and ((0.09 <= x <= 0.235) or (0.765 <= x <= 0.91))
        exposed_leg = 0.172 <= z <= 0.342 and leg_col
        sock_band = 0.098 <= z < 0.172 and leg_col

        if face_cheek:
            poly.material_index = skin_idx
            counts["face_cheek_skin"] += 1
        elif small_neck:
            poly.material_index = skin_idx
            counts["small_neck_skin"] += 1
        elif hand:
            poly.material_index = skin_idx
            counts["hand_skin"] += 1
        elif exposed_leg:
            poly.material_index = skin_idx
            counts["leg_skin"] += 1
        elif sock_band:
            poly.material_index = sock_idx
            counts["sock_black"] += 1

    mesh["shinokute_cleanup_source"] = "anatomy skin v3: narrow neck, cheek, hand, leg bands"
    out.parent.mkdir(parents=True, exist_ok=True)
    bpy.ops.export_scene.gltf(filepath=str(out), export_format="GLB")

    if str(report):
        data = {
            "source": str(src),
            "output": str(out),
            "bounds_size": [round(size.x, 6), round(size.y, 6), round(size.z, 6)],
            "front_axis": "negative_y",
            "counts": counts,
            "status": "candidate_not_integrated",
        }
        report.parent.mkdir(parents=True, exist_ok=True)
        report.write_text(json.dumps(data, indent=2), encoding="utf-8")


if __name__ == "__main__":
    main()
