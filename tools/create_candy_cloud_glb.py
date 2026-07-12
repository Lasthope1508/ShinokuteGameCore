import math
from pathlib import Path

import bpy


ROOT = Path(__file__).resolve().parents[1]
OUT_DIR = ROOT / "assets" / "themes" / "candy_sky_islands" / "models"

CREAM = (1.0, 0.949, 0.781, 1.0)
MINT = (0.482, 0.878, 0.678, 1.0)
SKY = (0.475, 0.78, 0.949, 1.0)
WHITE = (1.0, 1.0, 1.0, 1.0)


def clear_scene():
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete()


def material(name, color, roughness=0.84):
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


def sphere(name, loc, scale, mat):
    bpy.ops.mesh.primitive_uv_sphere_add(segments=32, ring_count=16, radius=1, location=loc)
    obj = bpy.context.object
    obj.name = name
    obj.scale = scale
    obj.data.materials.append(mat)
    shade(obj)
    return obj


def cube(name, loc, scale, mat):
    bpy.ops.mesh.primitive_cube_add(size=1, location=loc)
    obj = bpy.context.object
    obj.name = name
    obj.dimensions = scale
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    obj.data.materials.append(mat)
    bevel = obj.modifiers.new("soft_bevel", "BEVEL")
    bevel.width = min(scale) * 0.18
    bevel.segments = 5
    obj.modifiers.new("soft_normals", "WEIGHTED_NORMAL")
    return obj


def add_cloud():
    mats = {
        "white": material("Candy_Cloud_White", WHITE),
        "cream": material("Candy_Cloud_Cream", CREAM),
        "mint": material("Candy_Mint_Spark", MINT),
        "sky": material("Candy_Sky_Shadow", SKY),
    }

    sphere("CandyCloudPuffCenter", (0.0, 0.0, 0.52), (0.62, 0.36, 0.42), mats["white"])
    sphere("CandyCloudPuffLeft", (-0.47, 0.04, 0.42), (0.42, 0.31, 0.34), mats["white"])
    sphere("CandyCloudPuffRight", (0.48, -0.03, 0.40), (0.44, 0.30, 0.33), mats["cream"])
    sphere("CandyCloudPuffBack", (0.08, -0.30, 0.36), (0.52, 0.24, 0.27), mats["sky"])
    cube("CandyCloudSoftBase", (0.0, 0.02, 0.24), (1.46, 0.56, 0.24), mats["white"])

    for i, (x, y, z, angle) in enumerate(((-0.25, 0.32, 0.72, 45), (0.34, 0.26, 0.66, -30))):
        spark = cube("MintSpark" if i == 0 else "MintSparkSmall", (x, y, z), (0.18, 0.06, 0.18), mats["mint"])
        spark.rotation_euler[2] = math.radians(angle)


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


if __name__ == "__main__":
    clear_scene()
    add_cloud()
    output = ROOT / "assets" / "themes" / "candy_sky_islands" / "source" / "model_candidates" / "cloud_candy.glb"
    export(output)
    print("wrote", output)
