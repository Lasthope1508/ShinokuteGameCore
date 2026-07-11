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
        bsdf.inputs["Roughness"].default_value = 0.88
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
    mats = {
        "skin": make_mat("Shinokute_V9_Skin_From_Mask", (0.92, 0.69, 0.50, 1.0)),
        "hair": make_mat("Shinokute_V9_Hair_Black", (0.008, 0.009, 0.010, 1.0)),
        "hoodie": make_mat("Shinokute_V9_Hoodie_Black", (0.020, 0.023, 0.026, 1.0)),
        "shorts": make_mat("Shinokute_V9_Shorts_Black", (0.012, 0.013, 0.015, 1.0)),
        "socks": make_mat("Shinokute_V9_Socks_Black", (0.006, 0.007, 0.008, 1.0)),
    }
    mat_index = {}
    for name, mat in mats.items():
        mat_index[name] = base + len(mat_index)
        mesh.data.materials.append(mat)

    counts = {name: 0 for name in [*mats.keys(), "projected"]}

    for poly in mesh.data.polygons:
        center = mesh.matrix_world @ poly.center
        normal = (normal_matrix @ poly.normal).normalized()
        x = (center.x - mins.x) / max(0.001, size.x)
        y = (center.y - mins.y) / max(0.001, size.y)
        z = (center.z - mins.z) / max(0.001, size.z)

        front_depth = y <= 0.290
        face = 0.800 <= z <= 0.900 and 0.330 <= x <= 0.670 and front_depth and (normal.y < -0.10 or abs(normal.x) > 0.34)
        neck = 0.765 <= z < 0.800 and 0.485 <= x <= 0.515 and y <= 0.110 and normal.y < -0.22
        hands = 0.320 <= z <= 0.505 and ((0.055 <= x <= 0.280) or (0.720 <= x <= 0.945))
        exposed_legs = 0.182 <= z <= 0.370
        socks = 0.098 <= z < 0.182
        shoes_or_sole = z < 0.098
        shorts = 0.300 <= z < 0.500
        hoodie = 0.390 <= z < 0.775
        hood_or_hair = z >= 0.755

        assigned = ""
        if face or neck or hands or exposed_legs:
            assigned = "skin"
        elif socks:
            assigned = "socks"
        elif shoes_or_sole:
            assigned = ""
        elif shorts:
            assigned = "shorts"
        elif hoodie:
            assigned = "hoodie"
        elif hood_or_hair:
            # Keep face/neck protected above, then darken the remaining high head/hood silhouette.
            assigned = "hair" if z >= 0.820 else "hoodie"

        if assigned:
            poly.material_index = mat_index[assigned]
            counts[assigned] += 1
        else:
            counts["projected"] += 1

    mesh["shinokute_cleanup_source"] = "prompt lab material zone V10: narrow face/neck plus material-ID/SSOT solid zones"
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
                    "method": "prompt-lab albedo projection plus material-ID/SSOT solid cleanup zones; v10 narrow face/neck gate",
                },
                indent=2,
            ),
            encoding="utf-8",
        )


if __name__ == "__main__":
    main()
