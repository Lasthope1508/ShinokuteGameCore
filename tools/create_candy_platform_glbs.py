import math
import os
from pathlib import Path

import bpy


ROOT = Path(__file__).resolve().parents[1]
OUT_DIR = ROOT / "assets" / "themes" / "candy_sky_islands" / "models"

CORAL = (1.0, 0.435, 0.38, 1.0)
CREAM = (1.0, 0.949, 0.781, 1.0)
MINT = (0.482, 0.878, 0.678, 1.0)
SKY = (0.475, 0.78, 0.949, 1.0)
SHADOW = (0.45, 0.57, 0.74, 1.0)


def clear_scene():
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete()


def material(name, color, roughness=0.82):
    mat = bpy.data.materials.new(name)
    mat.use_nodes = True
    bsdf = mat.node_tree.nodes.get("Principled BSDF")
    bsdf.inputs["Base Color"].default_value = color
    bsdf.inputs["Roughness"].default_value = roughness
    return mat


def shade(obj):
    bpy.context.view_layer.objects.active = obj
    obj.select_set(True)
    try:
        bpy.ops.object.shade_smooth()
    finally:
        obj.select_set(False)


def cube(name, loc, scale, mat):
    bpy.ops.mesh.primitive_cube_add(size=1, location=loc)
    obj = bpy.context.object
    obj.name = name
    obj.dimensions = scale
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    obj.data.materials.append(mat)
    bevel = obj.modifiers.new("soft_bevel", "BEVEL")
    bevel.width = min(scale) * 0.18
    bevel.segments = 6
    obj.modifiers.new("soft_normals", "WEIGHTED_NORMAL")
    return obj


def cyl(name, loc, radius, depth, mat, vertices=48):
    bpy.ops.mesh.primitive_cylinder_add(vertices=vertices, radius=radius, depth=depth, location=loc)
    obj = bpy.context.object
    obj.name = name
    obj.data.materials.append(mat)
    bevel = obj.modifiers.new("round_edge", "BEVEL")
    bevel.width = depth * 0.16
    bevel.segments = 5
    obj.modifiers.new("soft_normals", "WEIGHTED_NORMAL")
    return obj


def sphere(name, loc, scale, mat):
    bpy.ops.mesh.primitive_uv_sphere_add(segments=24, ring_count=12, radius=1, location=loc)
    obj = bpy.context.object
    obj.name = name
    obj.scale = scale
    obj.data.materials.append(mat)
    shade(obj)
    return obj


def export(path):
    path.parent.mkdir(parents=True, exist_ok=True)
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.export_scene.gltf(
        filepath=str(path),
        export_format="GLB",
        use_selection=True,
        export_apply=True,
        export_yup=True,
    )


def add_rect_platform(width, depth, height, falling=False):
    mats = {
        "coral": material("Candy_Coral_Cake", CORAL),
        "cream": material("Candy_Cream_Rim", CREAM),
        "mint": material("Candy_Mint_Accent", MINT),
        "sky": material("Candy_Sky_Cloud", SKY),
        "shadow": material("Candy_Shadow_Side", SHADOW),
    }
    body_h = height * 0.58
    cream_h = height * 0.28
    top_h = height * 0.18
    cube("CloudCakeBase", (0, 0, body_h / 2), (width, depth, body_h), mats["sky"])
    cube("CreamRimFront", (0, depth / 2 - 0.06, body_h + cream_h / 2), (width * 0.96, 0.12, cream_h), mats["cream"])
    cube("CreamRimBack", (0, -depth / 2 + 0.06, body_h + cream_h / 2), (width * 0.96, 0.12, cream_h), mats["cream"])
    cube("CreamRimLeft", (-width / 2 + 0.06, 0, body_h + cream_h / 2), (0.12, depth * 0.92, cream_h), mats["cream"])
    cube("CreamRimRight", (width / 2 - 0.06, 0, body_h + cream_h / 2), (0.12, depth * 0.92, cream_h), mats["cream"])
    cube("CoralCakeTop", (0, 0, height - top_h / 2), (width * 0.84, depth * 0.78, top_h), mats["coral"])
    cube("MintCandyChip", (-width * 0.22, -depth * 0.18, height + 0.035), (width * 0.14, depth * 0.10, 0.07), mats["mint"])
    cube("MintCandyChip2", (width * 0.24, depth * 0.15, height + 0.03), (width * 0.10, depth * 0.12, 0.06), mats["mint"])
    if falling:
        for x in (-width * 0.32, 0, width * 0.32):
            cube("BreakScore", (x, 0, height + 0.055), (0.035, depth * 0.62, 0.035), mats["shadow"])
    for x in (-width * 0.38, width * 0.38):
        sphere("CloudPuff", (x, -depth * 0.37, body_h * 0.5), (width * 0.12, depth * 0.10, body_h * 0.42), mats["sky"])


def add_round_platform(radius, height):
    mats = {
        "coral": material("Candy_Coral_RoundCake", CORAL),
        "cream": material("Candy_Cream_RoundRim", CREAM),
        "mint": material("Candy_Mint_Grass", MINT),
        "sky": material("Candy_Sky_RoundBase", SKY),
    }
    cyl("CloudRoundBase", (0, 0, height * 0.26), radius, height * 0.52, mats["sky"], 64)
    cyl("CreamRoundRim", (0, 0, height * 0.63), radius * 0.93, height * 0.24, mats["cream"], 64)
    cyl("CoralRoundCakeTop", (0, 0, height * 0.88), radius * 0.84, height * 0.16, mats["coral"], 64)
    for i, angle in enumerate((30, 150, 265)):
        rad = math.radians(angle)
        x = math.cos(rad) * radius * 0.42
        y = math.sin(rad) * radius * 0.42
        sphere("MintGrassTuft%d" % i, (x, y, height + 0.07), (0.22, 0.12, 0.20), mats["mint"])


def add_grass(name, small=False):
    mint = material("Candy_Mint_Grass", MINT)
    cream = material("Candy_Cream_Base", CREAM)
    h = 0.26 if small else 0.32
    w = 0.10 if small else 0.16
    cube("%s_CreamBase" % name, (0, 0, 0.035), (w * 1.8, w * 1.2, 0.07), cream)
    for i, x in enumerate((-w, 0, w)):
        blade = cube("%s_Blade%d" % (name, i), (x, 0, 0.08 + h / 2), (w * 0.55, w * 0.28, h), mint)
        blade.rotation_euler[1] = math.radians((i - 1) * 10)


def build_all():
    outputs = [
        ("platform_candy_small.glb", lambda: add_rect_platform(2.0, 2.0, 0.56)),
        ("platform_candy_medium.glb", lambda: add_rect_platform(3.0, 3.0, 0.56)),
        ("platform_candy_falling.glb", lambda: add_rect_platform(2.2, 2.2, 0.52, True)),
        ("platform_candy_round_large.glb", lambda: add_round_platform(2.5, 0.52)),
        ("grass_candy.glb", lambda: add_grass("CandyGrass", False)),
        ("grass_candy_small.glb", lambda: add_grass("CandyGrassSmall", True)),
    ]
    for filename, builder in outputs:
        clear_scene()
        builder()
        export(OUT_DIR / filename)
        print("wrote", OUT_DIR / filename)


if __name__ == "__main__":
    build_all()
