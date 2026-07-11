from __future__ import annotations

import json
import sys
from pathlib import Path

import bpy
from mathutils import Vector


ROOT = Path(__file__).resolve().parents[1]
POOL = ROOT / "assets" / "themes" / "candy_sky_islands" / "source" / "shinokute_player" / "albedo_turnaround_pool_attempt2"
OUT = ROOT / "assets" / "themes" / "candy_sky_islands" / "models" / "character_shinokute_lentil_shell_candidate.glb"
REPORT = ROOT / "assets" / "themes" / "candy_sky_islands" / "source" / "shinokute_player" / "shinokute_lentil_shell_candidate_report.json"


def make_image_mat(name: str, image_path: Path, cull_backfaces: bool = False) -> bpy.types.Material:
    image = bpy.data.images.load(str(image_path))
    image.colorspace_settings.name = "sRGB"
    mat = bpy.data.materials.new(name)
    mat.use_nodes = True
    mat.blend_method = "CLIP"
    mat.alpha_threshold = 0.5
    mat.show_transparent_back = False
    mat.use_backface_culling = cull_backfaces
    mat.use_screen_refraction = False
    nodes = mat.node_tree.nodes
    bsdf = nodes.get("Principled BSDF")
    tex = nodes.new("ShaderNodeTexImage")
    tex.image = image
    tex.extension = "CLIP"
    if bsdf:
        mat.node_tree.links.new(tex.outputs["Color"], bsdf.inputs["Base Color"])
        mat.node_tree.links.new(tex.outputs["Alpha"], bsdf.inputs["Alpha"])
        bsdf.inputs["Roughness"].default_value = 0.82
    return mat

def alpha_profile(image_path: Path, samples: int = 64, threshold: float = 0.52) -> list[tuple[float, float]]:
    image = bpy.data.images.load(str(image_path), check_existing=True)
    width, height = image.size
    pixels = list(image.pixels)
    profile: list[tuple[float, float]] = []
    last = (0.42, 0.58)
    for i in range(samples + 1):
        v = i / samples
        row = min(height - 1, max(0, round(v * (height - 1))))
        xs = [
            x
            for x in range(width)
            if pixels[(row * width + x) * 4 + 3] >= threshold
        ]
        if xs:
            pad = max(1, round(width * 0.012))
            u_min = max(0.0, (min(xs) - pad) / max(1, width - 1))
            u_max = min(1.0, (max(xs) + pad) / max(1, width - 1))
            last = (u_min, u_max)
        profile.append(last)
    return profile

def profile_at(profile: list[tuple[float, float]], v: float) -> tuple[float, float]:
    idx = min(len(profile) - 1, max(0, round(v * (len(profile) - 1))))
    return profile[idx]


def make_solid_mat(name: str, color: tuple[float, float, float, float]) -> bpy.types.Material:
    mat = bpy.data.materials.new(name)
    mat.diffuse_color = color
    mat.use_nodes = True
    bsdf = mat.node_tree.nodes.get("Principled BSDF")
    if bsdf:
        bsdf.inputs["Base Color"].default_value = color
        bsdf.inputs["Roughness"].default_value = 0.88
    return mat


def add_textured_shell(
    name: str,
    mat: bpy.types.Material,
    y_offset: float,
    width: float,
    height: float,
    bulge: float,
    profile: list[tuple[float, float]],
    flip_u: bool = False,
    reverse_faces: bool = False,
) -> bpy.types.Object:
    cols = 18
    rows = 48
    verts: list[tuple[float, float, float]] = []
    uvs: list[tuple[float, float]] = []
    faces: list[tuple[int, int, int, int]] = []
    for r in range(rows + 1):
        v = r / rows
        z = (v - 0.5) * height
        u_min, u_max = profile_at(profile, v)
        for c in range(cols + 1):
            t = c / cols
            u = u_min + (u_max - u_min) * t
            x = (u - 0.5) * width
            oval = max(0.0, 1.0 - ((x / (width * 0.5)) ** 2) * 0.65 - ((z / (height * 0.5)) ** 2) * 0.18)
            y = y_offset + bulge * oval
            verts.append((x, y, z))
            uvs.append(((1.0 - u) if flip_u else u, v))
    for r in range(rows):
        for c in range(cols):
            a = r * (cols + 1) + c
            b = a + 1
            d = (r + 1) * (cols + 1) + c
            e = d + 1
            faces.append((a, d, e, b) if reverse_faces else (a, b, e, d))
    mesh = bpy.data.meshes.new(f"{name}_mesh")
    mesh.from_pydata(verts, [], faces)
    mesh.update()
    obj = bpy.data.objects.new(name, mesh)
    bpy.context.collection.objects.link(obj)
    mesh.materials.append(mat)
    uv_layer = mesh.uv_layers.new(name="SpriteUV")
    for poly in mesh.polygons:
        for loop_idx in poly.loop_indices:
            uv_layer.data[loop_idx].uv = uvs[mesh.loops[loop_idx].vertex_index]
    return obj


def profile_half_width(profile: list[tuple[float, float]], v: float, width: float) -> float:
    u_min, u_max = profile_at(profile, v)
    return max(0.025, ((u_max - u_min) * width) * 0.5)

def add_edge_rims(
    mat: bpy.types.Material,
    width: float,
    height: float,
    depth: float,
    profile: list[tuple[float, float]],
) -> list[bpy.types.Object]:
    cols = 6
    rows = 48
    objects: list[bpy.types.Object] = []
    for side_name, sign in [("Left", -1.0), ("Right", 1.0)]:
        verts: list[tuple[float, float, float]] = []
        faces: list[tuple[int, int, int, int]] = []
        for r in range(rows + 1):
            v = r / rows
            z = (v - 0.5) * height
            half_w = profile_half_width(profile, v, width)
            for c in range(cols + 1):
                t = c / cols
                y = (t - 0.5) * depth
                edge_bulge = 0.012 * (1.0 - abs(t - 0.5) * 2.0)
                x = sign * (half_w + edge_bulge)
                verts.append((x, y, z))
        for r in range(rows):
            for c in range(cols):
                a = r * (cols + 1) + c
                b = a + 1
                d = (r + 1) * (cols + 1) + c
                e = d + 1
                faces.append((a, b, e, d))
        mesh = bpy.data.meshes.new(f"shinokute_{side_name.lower()}_rim_mesh")
        mesh.from_pydata(verts, [], faces)
        mesh.update()
        obj = bpy.data.objects.new(f"Shinokute_{side_name}_Thin_Depth_Rim", mesh)
        bpy.context.collection.objects.link(obj)
        mesh.materials.append(mat)
        objects.append(obj)
    return objects

def add_side_shell(
    name: str,
    mat: bpy.types.Material,
    side_sign: float,
    width: float,
    height: float,
    depth: float,
    profile: list[tuple[float, float]],
    flip_u: bool = False,
) -> bpy.types.Object:
    cols = 10
    rows = 48
    verts: list[tuple[float, float, float]] = []
    uvs: list[tuple[float, float]] = []
    faces: list[tuple[int, int, int, int]] = []
    for r in range(rows + 1):
        v = r / rows
        z = (v - 0.5) * height
        u_min, u_max = profile_at(profile, v)
        row_depth = max(0.030, (u_max - u_min) * depth * 0.92)
        edge_x = profile_half_width(profile, v, width) * 0.92
        for c in range(cols + 1):
            t = c / cols
            u = u_min + (u_max - u_min) * t
            y = (t - 0.5) * row_depth
            side_round = 0.018 * max(0.0, 1.0 - ((t - 0.5) / 0.5) ** 2)
            x = side_sign * (edge_x - side_round)
            verts.append((x, y, z))
            uvs.append(((1.0 - u) if flip_u else u, v))
    for r in range(rows):
        for c in range(cols):
            a = r * (cols + 1) + c
            b = a + 1
            d = (r + 1) * (cols + 1) + c
            e = d + 1
            faces.append((a, b, e, d))
    mesh = bpy.data.meshes.new(f"{name}_mesh")
    mesh.from_pydata(verts, [], faces)
    mesh.update()
    obj = bpy.data.objects.new(name, mesh)
    bpy.context.collection.objects.link(obj)
    mesh.materials.append(mat)
    uv_layer = mesh.uv_layers.new(name="SideSpriteUV")
    for poly in mesh.polygons:
        for loop_idx in poly.loop_indices:
            uv_layer.data[loop_idx].uv = uvs[mesh.loops[loop_idx].vertex_index]
    return obj

def add_silhouette_side_wall(
    name: str,
    mats: dict[str, bpy.types.Material],
    side_sign: float,
    width: float,
    height: float,
    depth: float,
    profile: list[tuple[float, float]],
) -> bpy.types.Object:
    cols = 8
    rows = 48
    verts: list[tuple[float, float, float]] = []
    faces: list[tuple[int, int, int, int]] = []
    for r in range(rows + 1):
        v = r / rows
        z = (v - 0.5) * height
        edge_x = profile_half_width(profile, v, width) * 0.88
        u_min, u_max = profile_at(profile, v)
        row_depth = max(0.025, (u_max - u_min) * depth * 0.78)
        for c in range(cols + 1):
            t = c / cols
            y = (t - 0.5) * row_depth
            side_round = 0.020 * max(0.0, 1.0 - ((t - 0.5) / 0.5) ** 2)
            x = side_sign * (edge_x - side_round)
            verts.append((x, y, z))
    for r in range(rows):
        for c in range(cols):
            a = r * (cols + 1) + c
            b = a + 1
            d = (r + 1) * (cols + 1) + c
            e = d + 1
            faces.append((a, b, e, d))
    mesh = bpy.data.meshes.new(f"{name}_mesh")
    mesh.from_pydata(verts, [], faces)
    mesh.update()
    obj = bpy.data.objects.new(name, mesh)
    bpy.context.collection.objects.link(obj)
    material_order = ["fabric", "skin", "shoe"]
    for key in material_order:
        mesh.materials.append(mats[key])
    for poly in mesh.polygons:
        row = poly.index // cols
        v = (row + 0.5) / rows
        if 0.15 <= v <= 0.34 or 0.72 <= v <= 0.80:
            poly.material_index = material_order.index("skin")
        elif v < 0.09:
            poly.material_index = material_order.index("shoe")
        else:
            poly.material_index = material_order.index("fabric")
    return obj


def main() -> None:
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete()

    front = POOL / "shinokute_albedo_attempt2_front.png"
    back = POOL / "shinokute_albedo_attempt2_back.png"
    left = POOL / "shinokute_albedo_attempt2_left_side.png"
    right = POOL / "shinokute_albedo_attempt2_right_side.png"
    for path in [front, back, left, right]:
        if not path.exists():
            raise FileNotFoundError(path)

    front_mat = make_image_mat("Shinokute_Front_Image_Source", front, True)
    back_mat = make_image_mat("Shinokute_Back_Image_Source", back, True)
    side_mat = make_solid_mat("Shinokute_Side_Black_Fabric_And_Shadow", (0.018, 0.020, 0.023, 1.0))
    side_skin_mat = make_solid_mat("Shinokute_Side_Skin_Zone", (0.76, 0.55, 0.39, 1.0))
    side_shoe_mat = make_solid_mat("Shinokute_Side_Shoe_Red_Black_Zone", (0.58, 0.035, 0.025, 1.0))
    side_zone_mats = {"fabric": side_mat, "skin": side_skin_mat, "shoe": side_shoe_mat}
    front_profile = alpha_profile(front)
    back_profile = alpha_profile(back)
    left_profile = alpha_profile(left)
    right_profile = alpha_profile(right)

    width = 0.62
    height = 1.34
    depth = 0.34
    add_textured_shell("Shinokute_Front_Lentil_Shell", front_mat, -depth * 0.48, width, height, -0.050, front_profile, False, False)
    add_textured_shell("Shinokute_Back_Lentil_Shell", back_mat, depth * 0.48, width, height, 0.050, back_profile, True, True)
    add_silhouette_side_wall("Shinokute_Left_Silhouette_Depth_Wall", side_zone_mats, -1.0, width, height, depth, left_profile)
    add_silhouette_side_wall("Shinokute_Right_Silhouette_Depth_Wall", side_zone_mats, 1.0, width, height, depth, right_profile)

    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.shade_smooth()

    OUT.parent.mkdir(parents=True, exist_ok=True)
    bpy.ops.export_scene.gltf(filepath=str(OUT), export_format="GLB")

    REPORT.parent.mkdir(parents=True, exist_ok=True)
    REPORT.write_text(
        json.dumps(
            {
                "output": str(OUT),
                "sources": {
                    "front": str(front),
                    "back": str(back),
                    "left": str(left),
                    "right": str(right),
                },
                "method": "image-derived lentil shell: accepted albedo sprites on front/back curved shells plus left/right alpha-silhouette depth walls with SSOT material bands; no atlas UV projection and no primitive dummy body",
                "status": "candidate_not_integrated",
                "dimensions_target": [width, height, depth],
            },
            indent=2,
        ),
        encoding="utf-8",
    )


if __name__ == "__main__":
    main()
