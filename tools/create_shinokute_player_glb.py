import math
from pathlib import Path

import bpy

ROOT = Path(__file__).resolve().parents[1]
OUT_DIR = ROOT / "assets" / "themes" / "candy_sky_islands" / "models"
MODEL_SCALE = 0.68


BLACK = (0.015, 0.016, 0.018, 1.0)
BLACK_SOFT = (0.035, 0.038, 0.044, 1.0)
BLACK_EDGE = (0.09, 0.095, 0.105, 1.0)
SKIN = (0.92, 0.68, 0.50, 1.0)
SKIN_SHADE = (0.72, 0.45, 0.31, 1.0)
WHITE = (0.94, 0.94, 0.90, 1.0)
RED = (0.78, 0.04, 0.03, 1.0)
SOLE = (0.98, 0.96, 0.91, 1.0)
EYE = (0.04, 0.045, 0.055, 1.0)
SIGN_BLUE = (0.24, 0.72, 1.0, 0.62)


def clear_scene():
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete()


def material(name, color, roughness=0.78, alpha=1.0):
    mat = bpy.data.materials.new(name)
    mat.use_nodes = True
    bsdf = mat.node_tree.nodes.get("Principled BSDF")
    bsdf.inputs["Base Color"].default_value = color
    bsdf.inputs["Roughness"].default_value = roughness
    if alpha < 1.0 or color[3] < 1.0:
        mat.blend_method = "BLEND"
        mat.use_screen_refraction = True
        bsdf.inputs["Alpha"].default_value = alpha if alpha < 1.0 else color[3]
    return mat


def shade(obj):
    bpy.context.view_layer.objects.active = obj
    obj.select_set(True)
    try:
        bpy.ops.object.shade_smooth()
    finally:
        obj.select_set(False)


def add_bevel(obj, width, segments=3):
    bevel = obj.modifiers.new("soft_bevel", "BEVEL")
    bevel.width = width
    bevel.segments = segments
    obj.modifiers.new("weighted_normals", "WEIGHTED_NORMAL")
    return obj


def ellipsoid(name, loc, scale, mat, segments=32, rings=16):
    bpy.ops.mesh.primitive_uv_sphere_add(segments=segments, ring_count=rings, radius=1.0, location=loc)
    obj = bpy.context.object
    obj.name = name
    obj.scale = scale
    obj.data.materials.append(mat)
    shade(obj)
    return obj


def cube(name, loc, scale, mat, bevel_width=0.02):
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=loc)
    obj = bpy.context.object
    obj.name = name
    obj.dimensions = scale
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    obj.data.materials.append(mat)
    add_bevel(obj, bevel_width, 4)
    return obj


def cyl(name, loc, radius, depth, mat, vertices=28, bevel=True):
    bpy.ops.mesh.primitive_cylinder_add(vertices=vertices, radius=radius, depth=depth, location=loc)
    obj = bpy.context.object
    obj.name = name
    obj.data.materials.append(mat)
    if bevel:
        add_bevel(obj, radius * 0.12, 3)
    shade(obj)
    return obj


def cone(name, loc, radius1, radius2, depth, mat, vertices=5):
    bpy.ops.mesh.primitive_cone_add(vertices=vertices, radius1=radius1, radius2=radius2, depth=depth, location=loc)
    obj = bpy.context.object
    obj.name = name
    obj.data.materials.append(mat)
    shade(obj)
    return obj


def text_obj(name, text, loc, scale, mat, rot=(math.radians(90), 0, 0)):
    curve = bpy.data.curves.new(name, "FONT")
    curve.body = text
    curve.align_x = "CENTER"
    curve.align_y = "CENTER"
    curve.size = 0.16
    curve.extrude = 0.004
    obj = bpy.data.objects.new(name, curve)
    bpy.context.collection.objects.link(obj)
    obj.location = loc
    obj.rotation_euler = rot
    obj.scale = scale
    obj.data.materials.append(mat)
    return obj


def parent_to(root, objects):
    for obj in objects:
        obj.parent = root


def scale_model(root, factor):
    for obj in root.children:
        obj.location.x *= factor
        obj.location.y *= factor
        obj.location.z *= factor
        obj.scale.x *= factor
        obj.scale.y *= factor
        obj.scale.z *= factor


def build_model():
    black = material("Shinokute_Hoodie_Black", BLACK)
    black_soft = material("Shinokute_Hoodie_Fold_Black", BLACK_SOFT)
    black_edge = material("Shinokute_Outline_Black", BLACK_EDGE)
    skin = material("Shinokute_Skin", SKIN)
    skin_shade = material("Shinokute_Skin_Shade", SKIN_SHADE)
    white = material("Shinokute_White_Print", WHITE)
    red = material("Shinokute_Shoe_Red", RED)
    sole = material("Shinokute_Shoe_White", SOLE)
    eye = material("Shinokute_Eye_Hair", EYE)
    aura_mat = material("Shinokute_Sign_Aura", SIGN_BLUE, 0.38, 0.56)

    bpy.ops.object.empty_add(type="PLAIN_AXES", location=(0, 0, 0))
    root = bpy.context.object
    root.name = "root"

    torso = ellipsoid("torso_hoodie", (0, -0.005, 0.78), (0.31, 0.22, 0.36), black)
    torso.rotation_euler[0] = math.radians(1)
    waist = cube("hoodie_waist_band", (0, -0.01, 0.45), (0.55, 0.19, 0.08), black_edge, 0.025)
    pocket = cube("front_hoodie_pocket", (0, -0.205, 0.69), (0.34, 0.035, 0.105), black_soft, 0.018)
    hood_back = ellipsoid("raised_hood", (0, 0.035, 1.05), (0.32, 0.17, 0.17), black_soft, 32, 12)
    hood_l = cyl("hood_lace_left", (-0.07, -0.225, 0.97), 0.009, 0.23, black_edge, 12)
    hood_l.rotation_euler[0] = math.radians(8)
    hood_r = cyl("hood_lace_right", (0.07, -0.225, 0.97), 0.009, 0.23, black_edge, 12)
    hood_r.rotation_euler[0] = math.radians(-8)
    logo = text_obj("hoodie_text_SHINOKUTE", "SHINOKUTE", (0, -0.235, 0.92), (0.72, 0.72, 0.72), white)

    neck = cyl("neck", (0, -0.005, 1.08), 0.055, 0.12, skin, 20)
    neck.rotation_euler[0] = math.radians(90)
    head = ellipsoid("head", (0, -0.015, 1.23), (0.18, 0.15, 0.21), skin, 32, 16)
    chin = ellipsoid("chin_shadow", (0, -0.14, 1.15), (0.08, 0.018, 0.025), skin_shade, 16, 8)
    eye_l = ellipsoid("eye_left", (-0.065, -0.155, 1.255), (0.025, 0.011, 0.035), eye, 16, 8)
    eye_r = ellipsoid("eye_right", (0.065, -0.155, 1.255), (0.025, 0.011, 0.035), eye, 16, 8)
    brow_l = cube("brow_left", (-0.066, -0.163, 1.305), (0.055, 0.01, 0.012), eye, 0.004)
    brow_l.rotation_euler[2] = math.radians(-8)
    brow_r = cube("brow_right", (0.066, -0.163, 1.305), (0.055, 0.01, 0.012), eye, 0.004)
    brow_r.rotation_euler[2] = math.radians(8)
    mouth = cube("mouth_focused", (0, -0.168, 1.19), (0.055, 0.008, 0.01), eye, 0.003)

    hair_parts = []
    for idx, (x, z, rz, length) in enumerate([
        (-0.16, 1.38, 22, 0.19),
        (-0.10, 1.42, 8, 0.22),
        (-0.03, 1.45, -3, 0.24),
        (0.05, 1.43, -13, 0.23),
        (0.13, 1.39, -25, 0.20),
        (-0.19, 1.28, 50, 0.15),
        (0.19, 1.28, -50, 0.15),
    ]):
        spike = cone(f"hair_spike_{idx}", (x, -0.02, z), 0.055, 0.0, length, eye, 5)
        spike.rotation_euler = (math.radians(74), 0, math.radians(rz))
        hair_parts.append(spike)
    hair_cap = ellipsoid("hair_cap", (0, -0.015, 1.36), (0.19, 0.15, 0.09), eye, 32, 8)

    shorts = cube("black_shorts", (0, -0.005, 0.31), (0.46, 0.18, 0.20), black, 0.025)
    short_l = cube("short_leg_left", (-0.12, -0.005, 0.22), (0.20, 0.17, 0.18), black, 0.022)
    short_r = cube("short_leg_right", (0.12, -0.005, 0.22), (0.20, 0.17, 0.18), black, 0.022)

    leg_l = cyl("leg_left", (-0.13, -0.005, -0.02), 0.045, 0.42, skin, 24)
    leg_l.rotation_euler[0] = math.radians(2)
    leg_r = cyl("leg_right", (0.13, -0.005, -0.02), 0.045, 0.42, skin, 24)
    leg_r.rotation_euler[0] = math.radians(-2)
    sock_l = cyl("sock_left", (-0.13, -0.005, -0.25), 0.047, 0.14, black_edge, 24)
    sock_r = cyl("sock_right", (0.13, -0.005, -0.25), 0.047, 0.14, black_edge, 24)
    shoe_l = cube("shoe_left_red_black", (-0.14, -0.055, -0.36), (0.18, 0.30, 0.08), red, 0.025)
    shoe_r = cube("shoe_right_red_black", (0.14, -0.055, -0.36), (0.18, 0.30, 0.08), red, 0.025)
    sole_l = cube("shoe_left_white_sole", (-0.14, -0.06, -0.405), (0.20, 0.32, 0.035), sole, 0.018)
    sole_r = cube("shoe_right_white_sole", (0.14, -0.06, -0.405), (0.20, 0.32, 0.035), sole, 0.018)
    toe_l = cube("shoe_left_black_toe", (-0.14, -0.19, -0.36), (0.17, 0.08, 0.07), black_edge, 0.02)
    toe_r = cube("shoe_right_black_toe", (0.14, -0.19, -0.36), (0.17, 0.08, 0.07), black_edge, 0.02)

    upper_l = cyl("upper_arm_left", (-0.28, -0.02, 0.84), 0.055, 0.33, black, 24)
    upper_l.rotation_euler = (math.radians(25), math.radians(62), math.radians(-12))
    upper_r = cyl("upper_arm_right", (0.28, -0.02, 0.84), 0.055, 0.33, black, 24)
    upper_r.rotation_euler = (math.radians(25), math.radians(-62), math.radians(12))
    fore_l = cyl("forearm_left", (-0.12, -0.12, 0.76), 0.046, 0.30, black, 24)
    fore_l.rotation_euler = (math.radians(72), math.radians(12), math.radians(-38))
    fore_r = cyl("forearm_right", (0.12, -0.12, 0.76), 0.046, 0.30, black, 24)
    fore_r.rotation_euler = (math.radians(72), math.radians(-12), math.radians(38))
    cuff_l = cyl("cuff_left", (-0.045, -0.19, 0.83), 0.05, 0.055, black_edge, 20)
    cuff_l.rotation_euler = (math.radians(76), 0, math.radians(-25))
    cuff_r = cyl("cuff_right", (0.045, -0.19, 0.83), 0.05, 0.055, black_edge, 20)
    cuff_r.rotation_euler = (math.radians(76), 0, math.radians(25))
    hand_l = ellipsoid("hand_left_sign", (-0.038, -0.225, 0.91), (0.045, 0.023, 0.060), skin, 20, 10)
    hand_r = ellipsoid("hand_right_sign", (0.040, -0.225, 0.82), (0.048, 0.023, 0.055), skin, 20, 10)
    finger_up = cyl("raised_sign_finger", (-0.008, -0.236, 1.01), 0.015, 0.19, skin, 16)
    finger_up.rotation_euler[0] = math.radians(4)
    finger_support = cyl("support_sign_finger", (0.035, -0.239, 0.93), 0.013, 0.14, skin, 16)
    finger_support.rotation_euler = (math.radians(88), 0, math.radians(-8))

    bpy.ops.mesh.primitive_torus_add(major_radius=0.17, minor_radius=0.004, major_segments=64, minor_segments=8, location=(0, -0.245, 0.93))
    aura_ring = bpy.context.object
    aura_ring.name = "idle_sign_aura_ring"
    aura_ring.rotation_euler[0] = math.radians(90)
    aura_ring.data.materials.append(aura_mat)
    bpy.ops.mesh.primitive_torus_add(major_radius=0.10, minor_radius=0.003, major_segments=48, minor_segments=8, location=(0, -0.248, 0.93))
    aura_inner = bpy.context.object
    aura_inner.name = "idle_sign_aura_inner"
    aura_inner.rotation_euler[0] = math.radians(90)
    aura_inner.data.materials.append(aura_mat)

    all_objs = [
        torso, waist, pocket, hood_back, hood_l, hood_r, logo, neck, head, chin, eye_l, eye_r, brow_l, brow_r, mouth,
        hair_cap, shorts, short_l, short_r, leg_l, leg_r, sock_l, sock_r, shoe_l, shoe_r, sole_l, sole_r, toe_l, toe_r,
        upper_l, upper_r, fore_l, fore_r, cuff_l, cuff_r, hand_l, hand_r, finger_up, finger_support, aura_ring, aura_inner,
    ] + hair_parts
    parent_to(root, all_objs)
    scale_model(root, MODEL_SCALE)
    return root


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
    build_model()
    export(OUT_DIR / "character_shinokute_human.glb")


if __name__ == "__main__":
    main()
