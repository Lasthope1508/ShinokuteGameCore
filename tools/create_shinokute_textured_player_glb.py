import math
from pathlib import Path

import bpy

ROOT = Path(__file__).resolve().parents[1]
REF = ROOT / "assets" / "themes" / "candy_sky_islands" / "source" / "shinokute_player" / "shinokute_idle_sign_pose_clean_ref.png"
OUT = ROOT / "assets" / "themes" / "candy_sky_islands" / "source" / "model_candidates" / "character_shinokute_human.glb"

HEIGHT = 1.32
BOTTOM_Z = -0.40
DEPTH = 0.10
ALPHA_THRESHOLD = 0.18
CONTOUR_STEP = 8


def clear_scene():
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete()


def material_texture(name, image):
    mat = bpy.data.materials.new(name)
    mat.use_nodes = True
    mat.blend_method = "BLEND"
    mat.show_transparent_back = True
    bsdf = mat.node_tree.nodes.get("Principled BSDF")
    tex = mat.node_tree.nodes.new("ShaderNodeTexImage")
    tex.image = image
    tex.extension = "CLIP"
    mat.node_tree.links.new(tex.outputs["Color"], bsdf.inputs["Base Color"])
    mat.node_tree.links.new(tex.outputs["Alpha"], bsdf.inputs["Alpha"])
    bsdf.inputs["Roughness"].default_value = 0.76
    return mat


def material_color(name, color, roughness=0.72, alpha=1.0):
    mat = bpy.data.materials.new(name)
    mat.use_nodes = True
    bsdf = mat.node_tree.nodes.get("Principled BSDF")
    bsdf.inputs["Base Color"].default_value = color
    bsdf.inputs["Roughness"].default_value = roughness
    if alpha < 1.0 or color[3] < 1.0:
        mat.blend_method = "BLEND"
        bsdf.inputs["Alpha"].default_value = alpha if alpha < 1.0 else color[3]
    return mat


def add_textured_quad(name, x_half, mat, y):
    verts = [(-x_half, y, BOTTOM_Z), (x_half, y, BOTTOM_Z), (x_half, y, BOTTOM_Z + HEIGHT), (-x_half, y, BOTTOM_Z + HEIGHT)]
    faces = [(0, 1, 2, 3)] if y < 0 else [(3, 2, 1, 0)]
    mesh = bpy.data.meshes.new(f"{name}_mesh")
    mesh.from_pydata(verts, [], faces)
    mesh.update()
    uv = mesh.uv_layers.new(name="UVMap")
    coords = [(0, 0), (1, 0), (1, 1), (0, 1)] if y < 0 else [(0, 1), (1, 1), (1, 0), (0, 0)]
    for i, loop in enumerate(uv.data):
        loop.uv = coords[i]
    obj = bpy.data.objects.new(name, mesh)
    bpy.context.collection.objects.link(obj)
    obj.data.materials.append(mat)
    return obj


def alpha_at(pixels, width, x, y):
    return pixels[(y * width + x) * 4 + 3]


def contour_points(image):
    width, height = image.size
    pixels = list(image.pixels)
    rows = []
    for y in range(0, height, CONTOUR_STEP):
        xs = [x for x in range(width) if alpha_at(pixels, width, x, y) > ALPHA_THRESHOLD]
        if xs:
            rows.append((y, min(xs), max(xs)))
    if not rows:
        raise RuntimeError("No alpha contour found")

    width_world = HEIGHT * (width / height)

    def to_world(x, y):
        wx = (x / max(1, width - 1) - 0.5) * width_world
        wz = BOTTOM_Z + (y / max(1, height - 1)) * HEIGHT
        return wx, wz

    left = [to_world(xl, y) for y, xl, _ in rows]
    right = [to_world(xr, y) for y, _, xr in reversed(rows)]
    return left + right, width_world


def add_side_rim(points, mat):
    verts = []
    faces = []
    for x, z in points:
        verts.append((x, -DEPTH * 0.5, z))
        verts.append((x, DEPTH * 0.5, z))
    count = len(points)
    for i in range(count):
        j = (i + 1) % count
        faces.append((i * 2, j * 2, j * 2 + 1, i * 2 + 1))
    mesh = bpy.data.meshes.new("shinokute_alpha_rim_mesh")
    mesh.from_pydata(verts, [], faces)
    mesh.update()
    obj = bpy.data.objects.new("alpha_depth_rim", mesh)
    bpy.context.collection.objects.link(obj)
    obj.data.materials.append(mat)
    return obj


def add_aura(mat):
    bpy.ops.mesh.primitive_torus_add(
        major_radius=0.11,
        minor_radius=0.004,
        major_segments=64,
        minor_segments=8,
        location=(0, -DEPTH * 0.56, BOTTOM_Z + HEIGHT * 0.73),
    )
    ring = bpy.context.object
    ring.name = "idle_sign_aura_ring"
    ring.rotation_euler[0] = math.radians(90)
    ring.data.materials.append(mat)
    return ring


def parent_to(root, objects):
    for obj in objects:
        obj.parent = root


def export(path):
    path.parent.mkdir(parents=True, exist_ok=True)
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.export_scene.gltf(
        filepath=str(path),
        export_format="GLB",
        use_selection=True,
        use_visible=True,
        export_yup=True,
        export_animations=False,
        export_apply=True,
    )


def main():
    clear_scene()
    image = bpy.data.images.load(str(REF))
    points, width_world = contour_points(image)
    tex_mat = material_texture("Shinokute_Actual_Image_Texture", image)
    rim_mat = material_color("Shinokute_Alpha_Rim_Depth", (0.025, 0.026, 0.032, 1.0), 0.8)
    aura_mat = material_color("Shinokute_Idle_Aura", (0.22, 0.72, 1.0, 0.55), 0.35, 0.55)

    bpy.ops.object.empty_add(type="PLAIN_AXES", location=(0, 0, 0))
    root = bpy.context.object
    root.name = "root"

    front = add_textured_quad("front_actual_shinokute_image", width_world * 0.5, tex_mat, -DEPTH * 0.5)
    back = add_textured_quad("back_actual_shinokute_image", width_world * 0.5, tex_mat, DEPTH * 0.5)
    rim = add_side_rim(points, rim_mat)
    aura = add_aura(aura_mat)
    parent_to(root, [front, back, rim, aura])
    export(OUT)


if __name__ == "__main__":
    main()
