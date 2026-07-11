import math
from pathlib import Path

import bpy
from mathutils import Vector


ROOT = Path(__file__).resolve().parents[1]
OUT_DIR = ROOT / "assets" / "themes" / "candy_sky_islands" / "models"

CORAL = (1.0, 0.435, 0.38, 1.0)
CREAM = (1.0, 0.949, 0.781, 1.0)
MINT = (0.482, 0.878, 0.678, 1.0)


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


def star_points(outer, inner, count=5):
    points = []
    start = math.radians(90)
    for i in range(count * 2):
        radius = outer if i % 2 == 0 else inner
        angle = start + i * math.pi / count
        points.append((math.cos(angle) * radius, math.sin(angle) * radius))
    return points


def star_prism(name, outer, inner, thickness, mat):
    pts = star_points(outer, inner)
    verts = []
    for x, z in pts:
        verts.append((x, -thickness / 2, z))
    for x, z in pts:
        verts.append((x, thickness / 2, z))
    front_center = len(verts)
    verts.append((0, -thickness / 2, 0))
    back_center = len(verts)
    verts.append((0, thickness / 2, 0))

    faces = []
    count = len(pts)
    for i in range(count):
        nxt = (i + 1) % count
        faces.append((front_center, i, nxt))
        faces.append((back_center, count + nxt, count + i))
        faces.append((i, count + i, count + nxt, nxt))

    mesh = bpy.data.meshes.new(name + "Mesh")
    mesh.from_pydata(verts, [], faces)
    mesh.update(calc_edges=True)
    obj = bpy.data.objects.new(name, mesh)
    bpy.context.collection.objects.link(obj)
    obj.data.materials.append(mat)
    return obj


def sprinkle(name, loc, scale, mat):
    bpy.ops.mesh.primitive_cube_add(size=1, location=loc)
    obj = bpy.context.object
    obj.name = name
    obj.dimensions = scale
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    obj.data.materials.append(mat)
    bevel = obj.modifiers.new("soft_bevel", "BEVEL")
    bevel.width = min(scale) * 0.25
    bevel.segments = 4
    obj.modifiers.new("soft_normals", "WEIGHTED_NORMAL")
    return obj


def add_collectible():
    coral = material("Candy_Coral_Star", CORAL)
    cream = material("Candy_Cream_Inner", CREAM)
    mint = material("Candy_Mint_Rim", MINT)

    rim = star_prism("MintStarRim", 0.32, 0.15, 0.12, mint)
    body = star_prism("CoralStarBody", 0.26, 0.12, 0.16, coral)
    body.location = Vector((0, -0.01, 0))
    inner = star_prism("CreamStarInset", 0.11, 0.052, 0.18, cream)
    inner.location = Vector((0, -0.03, 0))

    for index, (x, z, angle) in enumerate(((-0.08, 0.08, 18), (0.08, 0.04, -24), (0.02, -0.08, 42))):
        obj = sprinkle("CreamSprinkle%d" % index, (x, -0.12, z), (0.055, 0.018, 0.018), cream)
        obj.rotation_euler[1] = math.radians(angle)


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
    add_collectible()
    output = OUT_DIR / "star_candy_collectible.glb"
    export(output)
    print("wrote", output)
