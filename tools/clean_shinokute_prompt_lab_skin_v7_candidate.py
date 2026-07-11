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
        bsdf.inputs["Roughness"].default_value = 0.86
        bsdf.inputs["Metallic"].default_value = 0.0
    return mat


def bounds(obj: bpy.types.Object) -> tuple[Vector, Vector]:
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
    mins, maxs = bounds(mesh)
    size = maxs - mins
    normal_matrix = mesh.matrix_world.to_3x3()

    base = len(mesh.data.materials)
    skin = make_mat("Shinokute_PromptLab_Skin_V7", (0.90, 0.68, 0.50, 1.0))
    sock = make_mat("Shinokute_PromptLab_Sock_Black_V7", (0.012, 0.013, 0.015, 1.0))
    mesh.data.materials.append(skin)
    skin_idx = base
    mesh.data.materials.append(sock)
    sock_idx = base + 1
    counts = {"face": 0, "neck": 0, "hands": 0, "legs": 0, "socks": 0}

    for poly in mesh.data.polygons:
        center = mesh.matrix_world @ poly.center
        normal = (normal_matrix @ poly.normal).normalized()
        x = (center.x - mins.x) / max(0.001, size.x)
        y = (center.y - mins.y) / max(0.001, size.y)
        z = (center.z - mins.z) / max(0.001, size.z)

        # V7 keeps the v5 spatial gates, but uses the cleaner prompt-lab mask skin color.
        # This avoids the v6 failure mode where wider neck/face gates painted hoodie/chest.
        front_most = y <= 0.285
        face = (
            0.765 <= z <= 0.885
            and 0.31 <= x <= 0.69
            and front_most
            and (normal.y < -0.16 or abs(normal.x) > 0.32)
        )
        neck = 0.705 <= z < 0.755 and 0.445 <= x <= 0.555 and y <= 0.205 and normal.y < -0.16
        hands = 0.335 <= z <= 0.49 and ((0.075 <= x <= 0.255) or (0.745 <= x <= 0.925))
        legs = 0.182 <= z <= 0.365
        socks = 0.100 <= z < 0.182

        if face:
            poly.material_index = skin_idx
            counts["face"] += 1
        elif neck:
            poly.material_index = skin_idx
            counts["neck"] += 1
        elif hands:
            poly.material_index = skin_idx
            counts["hands"] += 1
        elif legs:
            poly.material_index = skin_idx
            counts["legs"] += 1
        elif socks:
            poly.material_index = sock_idx
            counts["socks"] += 1

    mesh["shinokute_cleanup_source"] = "prompt lab skin v7: v5 gates with brighter material-mask skin"
    out.parent.mkdir(parents=True, exist_ok=True)
    bpy.ops.export_scene.gltf(filepath=str(out), export_format="GLB")

    if str(report):
        report.parent.mkdir(parents=True, exist_ok=True)
        report.write_text(
            json.dumps(
                {
                    "source": str(src),
                    "output": str(out),
                    "bounds_size": [round(size.x, 6), round(size.y, 6), round(size.z, 6)],
                    "front_axis": "negative_y",
                    "counts": counts,
                    "status": "candidate_not_integrated",
                },
                indent=2,
            ),
            encoding="utf-8",
        )


if __name__ == "__main__":
    main()
