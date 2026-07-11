from pathlib import Path

import bpy


ROOT = Path(__file__).resolve().parents[1]
OUT_DIR = ROOT / "assets" / "themes" / "candy_sky_islands" / "models"

CORAL = (1.0, 0.435, 0.38, 1.0)
CREAM = (1.0, 0.949, 0.781, 1.0)
MINT = (0.482, 0.878, 0.678, 1.0)
WAFER = (1.0, 0.702, 0.549, 1.0)


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


def cube(name, loc, scale, mat):
    bpy.ops.mesh.primitive_cube_add(size=1, location=loc)
    obj = bpy.context.object
    obj.name = name
    obj.dimensions = scale
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    obj.data.materials.append(mat)
    bevel = obj.modifiers.new("soft_bevel", "BEVEL")
    bevel.width = min(scale) * 0.16
    bevel.segments = 5
    obj.modifiers.new("soft_normals", "WEIGHTED_NORMAL")
    return obj


def cyl(name, loc, radius, depth, mat, vertices=24):
    bpy.ops.mesh.primitive_cylinder_add(vertices=vertices, radius=radius, depth=depth, location=loc)
    obj = bpy.context.object
    obj.name = name
    obj.data.materials.append(mat)
    bevel = obj.modifiers.new("soft_bevel", "BEVEL")
    bevel.width = radius * 0.18
    bevel.segments = 4
    obj.modifiers.new("soft_normals", "WEIGHTED_NORMAL")
    return obj


def add_brick():
    wafer = material("Candy_Wafer_Body", WAFER)
    cream = material("Candy_Cream_Stripe", CREAM, 0.9)
    mint = material("Candy_Mint_Chip", MINT)

    cube("WaferBody", (0, 0, 0.38), (0.90, 0.82, 0.58), wafer)
    cube("CreamStripe", (0, 0, 0.53), (0.94, 0.86, 0.09), cream)
    cube("CreamStripeLower", (0, 0, 0.26), (0.88, 0.80, 0.07), cream)
    cube("MintChip", (-0.22, -0.16, 0.70), (0.18, 0.18, 0.08), mint)
    cube("MintChipSmall", (0.22, 0.18, 0.68), (0.14, 0.14, 0.07), mint)


def add_goal():
    coral = material("Candy_Coral_Pennant", CORAL)
    cream = material("Candy_Cream_Trim", CREAM, 0.9)
    mint = material("Candy_Mint_Pole", MINT)

    cyl("MintPole", (-0.28, 0.0, 0.78), 0.04, 1.55, mint)
    cube("Pennant", (0.16, 0.0, 1.18), (1.0, 0.08, 0.52), coral)
    cube("CreamTrim", (0.13, 0.0, 0.91), (0.92, 0.10, 0.08), cream)
    cube("CreamTopTrim", (0.13, 0.0, 1.45), (0.92, 0.10, 0.08), cream)
    cube("MintCap", (-0.28, 0.0, 1.58), (0.16, 0.16, 0.08), mint)


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
    outputs = [
        ("brick_candy_wafer.glb", add_brick),
        ("goal_candy_pennant.glb", add_goal),
    ]
    for filename, builder in outputs:
        clear_scene()
        builder()
        output = OUT_DIR / filename
        export(output)
        print("wrote", output)
