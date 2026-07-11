from pathlib import Path
import math

import bpy
from mathutils import Vector

ROOT = Path(__file__).resolve().parents[1]
REFERENCE = ROOT / "assets" / "themes" / "candy_sky_islands" / "cloud_large.png"
OUT_DIR = ROOT / "assets" / "themes" / "candy_sky_islands" / "models"

WHITE = (1.0, 1.0, 1.0, 1.0)
CREAM = (1.0, 0.949, 0.781, 1.0)
SKY = (0.866, 0.961, 1.0, 1.0)
MINT = (0.482, 0.878, 0.678, 1.0)


def clear_scene():
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete()


def material(name, color, roughness=0.86):
    mat = bpy.data.materials.new(name)
    mat.use_nodes = True
    bsdf = mat.node_tree.nodes.get("Principled BSDF")
    bsdf.inputs["Base Color"].default_value = color
    bsdf.inputs["Roughness"].default_value = roughness
    return mat


def load_alpha_mask(path):
    image = bpy.data.images.load(str(path), check_existing=False)
    width, height = image.size
    pixels = list(image.pixels)
    alpha = []
    for y in range(height):
        row = []
        for x in range(width):
            row.append(pixels[(y * width + x) * 4 + 3])
        alpha.append(row)
    return width, height, alpha


def alpha_bounds(alpha, threshold=0.08):
    height = len(alpha)
    width = len(alpha[0])
    xs = []
    ys = []
    for y in range(height):
        for x in range(width):
            if alpha[y][x] > threshold:
                xs.append(x)
                ys.append(y)
    if not xs:
        raise RuntimeError("reference alpha has no foreground")
    return min(xs), min(ys), max(xs), max(ys)


def column_bounds(alpha, x, y_min, y_max, threshold=0.08):
    hits = [y for y in range(y_min, y_max + 1) if alpha[y][x] > threshold]
    if hits:
        return min(hits), max(hits)
    return None


def sample_contour(width, height, alpha, bbox, samples=42):
    x_min, y_min, x_max, y_max = bbox
    top = []
    bottom = []
    last = None
    for index in range(samples):
        source_x = round(x_min + (x_max - x_min) * index / float(samples - 1))
        bounds = column_bounds(alpha, source_x, y_min, y_max)
        if bounds == None:
            bounds = last
        if bounds == None:
            continue
        last = bounds
        top_y, bottom_y = bounds
        top.append((source_x, top_y))
        bottom.append((source_x, bottom_y))
    if len(top) < 4:
        raise RuntimeError("reference contour too small")
    return top, bottom


def to_model_point(px, py, bbox, target_width=1.62, target_height=0.76):
    x_min, y_min, x_max, y_max = bbox
    nx = (px - x_min) / max(1.0, float(x_max - x_min))
    ny = (py - y_min) / max(1.0, float(y_max - y_min))
    x = (nx - 0.5) * target_width
    z = (1.0 - ny) * target_height
    return x, z


def make_silhouette_volume(top, bottom, bbox, mat):
    depth = 0.42
    contour = top + list(reversed(bottom))
    points = [to_model_point(x, y, bbox) for x, y in contour]
    center_x = sum(p[0] for p in points) / len(points)
    center_z = sum(p[1] for p in points) / len(points)

    verts = []
    for x, z in points:
        verts.append((x, -depth / 2.0, z))
    for x, z in points:
        verts.append((x, depth / 2.0, z))
    front_center = len(verts)
    verts.append((center_x, -depth / 2.0, center_z))
    back_center = len(verts)
    verts.append((center_x, depth / 2.0, center_z))

    faces = []
    count = len(points)
    for i in range(count):
        nxt = (i + 1) % count
        faces.append((front_center, i, nxt))
        faces.append((back_center, count + nxt, count + i))
        faces.append((i, count + i, count + nxt, nxt))

    mesh = bpy.data.meshes.new("CloudReferenceSilhouetteMesh")
    mesh.from_pydata(verts, [], faces)
    mesh.update(calc_edges=True)
    obj = bpy.data.objects.new("CloudReferenceSilhouetteVolume", mesh)
    bpy.context.collection.objects.link(obj)
    obj.data.materials.append(mat)
    bevel = obj.modifiers.new("soft_reference_edge", "BEVEL")
    bevel.width = 0.045
    bevel.segments = 7
    obj.modifiers.new("soft_cloud_normals", "WEIGHTED_NORMAL")
    return obj


def shade(obj):
    bpy.context.view_layer.objects.active = obj
    obj.select_set(True)
    try:
        bpy.ops.object.shade_smooth()
    finally:
        obj.select_set(False)


def add_reference_puff(name, loc, scale, mat):
    bpy.ops.mesh.primitive_uv_sphere_add(segments=32, ring_count=16, radius=1, location=loc)
    obj = bpy.context.object
    obj.name = name
    obj.scale = scale
    obj.data.materials.append(mat)
    shade(obj)
    return obj


def add_reference_puffs(alpha, bbox, mats):
    x_min, y_min, x_max, y_max = bbox
    anchors = [
        (0.16, "LeftReferencePuff", mats["white"], -0.02),
        (0.35, "UpperReferencePuff", mats["white"], 0.08),
        (0.56, "CenterReferencePuff", mats["cream"], 0.05),
        (0.76, "RightReferencePuff", mats["white"], -0.03),
    ]
    for fraction, name, mat, depth_offset in anchors:
        source_x = round(x_min + (x_max - x_min) * fraction)
        bounds = column_bounds(alpha, source_x, y_min, y_max)
        if bounds == None:
            continue
        top_y, bottom_y = bounds
        x, top_z = to_model_point(source_x, top_y, bbox)
        _, bottom_z = to_model_point(source_x, bottom_y, bbox)
        height = max(0.18, top_z - bottom_z)
        z = bottom_z + height * 0.52
        width_scale = max(0.24, height * 0.72)
        depth_scale = max(0.22, height * 0.42)
        add_reference_puff(name, (x, depth_offset, z), (width_scale, depth_scale, height * 0.52), mat)


def add_alpha_ridge(top, bbox, mat):
    every = max(1, len(top) // 7)
    for index, (px, py) in enumerate(top[::every][:7]):
        x, z = to_model_point(px, py, bbox)
        bpy.ops.mesh.primitive_cube_add(size=1, location=(x, -0.24, z - 0.03))
        ridge = bpy.context.object
        ridge.name = "ReferenceTopHighlight%d" % index
        ridge.dimensions = (0.13, 0.035, 0.025)
        bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
        ridge.rotation_euler[1] = math.radians(7 if index % 2 == 0 else -7)
        ridge.data.materials.append(mat)
        bevel = ridge.modifiers.new("soft_highlight", "BEVEL")
        bevel.width = 0.012
        bevel.segments = 3
        ridge.modifiers.new("highlight_normals", "WEIGHTED_NORMAL")


def add_mint_spark(mat):
    for index, (x, y, z, size, angle) in enumerate(((-0.31, -0.28, 0.65, 0.09, 45), (0.39, -0.27, 0.58, 0.065, -35))):
        bpy.ops.mesh.primitive_cube_add(size=1, location=(x, y, z))
        spark = bpy.context.object
        spark.name = "MintSpark" if index == 0 else "MintSparkSmall"
        spark.dimensions = (size, 0.028, size)
        bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
        spark.rotation_euler[2] = math.radians(angle)
        spark.data.materials.append(mat)
        bevel = spark.modifiers.new("soft_spark", "BEVEL")
        bevel.width = size * 0.18
        bevel.segments = 3
        spark.modifiers.new("spark_normals", "WEIGHTED_NORMAL")


def add_cloud():
    if not REFERENCE.exists():
        raise FileNotFoundError(REFERENCE)
    width, height, alpha = load_alpha_mask(REFERENCE)
    bbox = alpha_bounds(alpha)
    top, bottom = sample_contour(width, height, alpha, bbox)
    mats = {
        "white": material("Candy_Cloud_Reference_White", WHITE),
        "cream": material("Candy_Cloud_Reference_Cream", CREAM),
        "sky": material("Candy_Cloud_Sky_Depth", SKY),
        "mint": material("Candy_Mint_Spark", MINT),
    }
    make_silhouette_volume(top, bottom, bbox, mats["sky"])
    add_reference_puffs(alpha, bbox, mats)
    add_alpha_ridge(top, bbox, mats["cream"])
    add_mint_spark(mats["mint"])


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
    output = OUT_DIR / "cloud_candy_volume.glb"
    export(output)
    print("wrote", output)
