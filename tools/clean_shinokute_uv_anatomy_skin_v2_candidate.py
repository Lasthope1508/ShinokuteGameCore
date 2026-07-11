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


def material(name: str, color: tuple[float, float, float, float]) -> bpy.types.Material:
    mat = bpy.data.materials.new(name)
    mat.diffuse_color = color
    mat.use_nodes = True
    bsdf = mat.node_tree.nodes.get("Principled BSDF")
    if bsdf:
        bsdf.inputs["Base Color"].default_value = color
        bsdf.inputs["Roughness"].default_value = 0.84
    return mat


def bounds(mesh_obj: bpy.types.Object) -> tuple[Vector, Vector]:
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
    meshes = [obj for obj in bpy.context.scene.objects if obj.type == "MESH"]
    if not meshes:
        raise RuntimeError("No mesh in source GLB")

    mesh = meshes[0]
    mins, maxs = bounds(mesh)
    size = maxs - mins
    normal_matrix = mesh.matrix_world.to_3x3()

    base_count = len(mesh.data.materials)
    skin = material("Shinokute_Anatomy_Skin_V2", (0.66, 0.49, 0.36, 1.0))
    fabric = material("Shinokute_Anatomy_Fabric_Black_V2", (0.012, 0.013, 0.015, 1.0))
    mesh.data.materials.append(skin)
    skin_index = base_count
    mesh.data.materials.append(fabric)
    fabric_index = base_count + 1

    counts = {
        "face_cheek_skin": 0,
        "neck_skin": 0,
        "hand_skin": 0,
        "leg_skin": 0,
        "sock_fabric": 0,
        "hood_or_collar_fabric": 0,
    }

    for poly in mesh.data.polygons:
        center = mesh.matrix_world @ poly.center
        normal = (normal_matrix @ poly.normal).normalized()
        x = (center.x - mins.x) / max(0.001, size.x)
        y = (center.y - mins.y) / max(0.001, size.y)
        z = (center.z - mins.z) / max(0.001, size.z)

        front_half = y <= 0.48
        front_most = y <= 0.31
        faces_forward = normal.y < -0.12
        side_surface = abs(normal.x) > 0.25
        leg_column = (0.23 <= x <= 0.47) or (0.53 <= x <= 0.77)

        # Keep hood/collar black before skin passes. This prevents the hoodie
        # rim from being painted as neck/cheek skin when it overlaps face x/z.
        hood_or_collar = 0.63 <= z <= 0.79 and 0.22 <= x <= 0.78 and (not front_most or normal.y > -0.35)
        if hood_or_collar:
            poly.material_index = fabric_index
            counts["hood_or_collar_fabric"] += 1
            continue

        face_cheek = 0.755 <= z <= 0.89 and 0.29 <= x <= 0.71 and front_most and (faces_forward or side_surface)
        neck = 0.655 <= z < 0.755 and 0.39 <= x <= 0.61 and front_most and normal.y < -0.08
        hands = 0.33 <= z <= 0.49 and ((0.08 <= x <= 0.24) or (0.76 <= x <= 0.92))

        # Shorts end above this band; socks/shoes start below it. Use a narrow
        # leg column so the black shorts and center shadow stay intact.
        exposed_leg = 0.165 <= z <= 0.345 and leg_column
        sock = 0.095 <= z < 0.165 and leg_column

        if face_cheek:
            poly.material_index = skin_index
            counts["face_cheek_skin"] += 1
        elif neck:
            poly.material_index = skin_index
            counts["neck_skin"] += 1
        elif hands:
            poly.material_index = skin_index
            counts["hand_skin"] += 1
        elif exposed_leg:
            poly.material_index = skin_index
            counts["leg_skin"] += 1
        elif sock:
            poly.material_index = fabric_index
            counts["sock_fabric"] += 1

    mesh["shinokute_cleanup_source"] = "anatomy skin v2: depth-gated face/neck plus leg skin bands"
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
            "front_axis": "negative_y",
            "counts": counts,
            "status": "candidate_not_integrated",
        }
        report.parent.mkdir(parents=True, exist_ok=True)
        report.write_text(json.dumps(data, indent=2), encoding="utf-8")


if __name__ == "__main__":
    main()
