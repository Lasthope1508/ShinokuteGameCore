import math
from pathlib import Path

import bpy

ROOT = Path(__file__).resolve().parents[1]
OUT_DIR = ROOT / "assets" / "themes" / "candy_sky_islands" / "models"

CORAL = (1.0, 0.435, 0.38, 1.0)
CREAM = (1.0, 0.949, 0.781, 1.0)
MINT = (0.482, 0.878, 0.678, 1.0)
TEXT = (0.153, 0.188, 0.263, 1.0)
WHITE = (1.0, 1.0, 0.925, 1.0)


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


def shade(obj):
    bpy.context.view_layer.objects.active = obj
    obj.select_set(True)
    try:
        bpy.ops.object.shade_smooth()
    finally:
        obj.select_set(False)


def ellipsoid(name, loc, scale, mat, segments=32, rings=16):
    bpy.ops.mesh.primitive_uv_sphere_add(
        segments=segments,
        ring_count=rings,
        radius=1.0,
        location=loc,
    )
    obj = bpy.context.object
    obj.name = name
    obj.scale = scale
    obj.data.materials.append(mat)
    shade(obj)
    return obj


def cube(name, loc, scale, mat):
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=loc)
    obj = bpy.context.object
    obj.name = name
    obj.dimensions = scale
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    obj.data.materials.append(mat)
    bevel = obj.modifiers.new("soft_bevel", "BEVEL")
    bevel.width = min(scale) * 0.25
    bevel.segments = 5
    obj.modifiers.new("soft_normals", "WEIGHTED_NORMAL")
    return obj


def cyl(name, loc, radius, depth, mat, vertices=32):
    bpy.ops.mesh.primitive_cylinder_add(
        vertices=vertices,
        radius=radius,
        depth=depth,
        location=loc,
    )
    obj = bpy.context.object
    obj.name = name
    obj.data.materials.append(mat)
    bevel = obj.modifiers.new("soft_edge", "BEVEL")
    bevel.width = radius * 0.12
    bevel.segments = 4
    obj.modifiers.new("soft_normals", "WEIGHTED_NORMAL")
    shade(obj)
    return obj


def parent_to(root, objects):
    for obj in objects:
        obj.parent = root


def add_key(obj, frame, loc=None, rot=None, scale=None):
    bpy.context.scene.frame_set(frame)
    if loc is not None:
        obj.location = loc
        obj.keyframe_insert(data_path="location", frame=frame)
    if rot is not None:
        obj.rotation_euler = rot
        obj.keyframe_insert(data_path="rotation_euler", frame=frame)
    if scale is not None:
        obj.scale = scale
        obj.keyframe_insert(data_path="scale", frame=frame)


def stash_action(obj, name):
    if not obj.animation_data or not obj.animation_data.action:
        return
    action = obj.animation_data.action
    action.name = "%s_%s" % (name, obj.name)
    track = obj.animation_data.nla_tracks.new()
    track.name = name
    strip = track.strips.new(name, int(action.frame_range[0]), action)
    strip.name = name
    obj.animation_data.action = None


def animate_loop(name, root, left_leg, right_leg, left_arm, right_arm, body, frame_a, frame_b):
    add_key(root, frame_a, loc=(0, 0, 0))
    add_key(root, frame_b, loc=(0, 0, 0.035 if name == "idle" else 0.02))
    add_key(root, frame_b * 2 - frame_a, loc=(0, 0, 0))
    stash_action(root, name)

    swing = math.radians(18 if name == "walk" else 4)
    add_key(left_leg, frame_a, rot=(swing, 0, 0))
    add_key(left_leg, frame_b, rot=(-swing, 0, 0))
    add_key(left_leg, frame_b * 2 - frame_a, rot=(swing, 0, 0))
    stash_action(left_leg, name)

    add_key(right_leg, frame_a, rot=(-swing, 0, 0))
    add_key(right_leg, frame_b, rot=(swing, 0, 0))
    add_key(right_leg, frame_b * 2 - frame_a, rot=(-swing, 0, 0))
    stash_action(right_leg, name)

    arm_swing = -swing * 0.8
    add_key(left_arm, frame_a, rot=(0, 0, arm_swing))
    add_key(left_arm, frame_b, rot=(0, 0, -arm_swing))
    add_key(left_arm, frame_b * 2 - frame_a, rot=(0, 0, arm_swing))
    stash_action(left_arm, name)

    add_key(right_arm, frame_a, rot=(0, 0, -arm_swing))
    add_key(right_arm, frame_b, rot=(0, 0, arm_swing))
    add_key(right_arm, frame_b * 2 - frame_a, rot=(0, 0, -arm_swing))
    stash_action(right_arm, name)

    squash = (1.02, 0.98, 1.02) if name == "idle" else (1.0, 1.0, 1.0)
    add_key(body, frame_a, scale=(1, 1, 1))
    add_key(body, frame_b, scale=squash)
    add_key(body, frame_b * 2 - frame_a, scale=(1, 1, 1))
    stash_action(body, name)


def animate_jump(root, left_leg, right_leg, left_arm, right_arm):
    add_key(root, 1, loc=(0, 0, 0))
    add_key(root, 12, loc=(0, 0, 0.12))
    add_key(root, 24, loc=(0, 0, 0))
    stash_action(root, "jump")

    leg_rot = math.radians(-18)
    arm_rot = math.radians(28)
    for obj in (left_leg, right_leg):
        add_key(obj, 1, rot=(0, 0, 0))
        add_key(obj, 12, rot=(leg_rot, 0, 0))
        add_key(obj, 24, rot=(0, 0, 0))
        stash_action(obj, "jump")
    add_key(left_arm, 1, rot=(0, 0, 0))
    add_key(left_arm, 12, rot=(0, 0, arm_rot))
    add_key(left_arm, 24, rot=(0, 0, 0))
    stash_action(left_arm, "jump")
    add_key(right_arm, 1, rot=(0, 0, 0))
    add_key(right_arm, 12, rot=(0, 0, -arm_rot))
    add_key(right_arm, 24, rot=(0, 0, 0))
    stash_action(right_arm, "jump")


def build_player():
    cream = material("Candy_Player_Marshmallow", CREAM)
    whipped = material("Candy_Player_Whipped_Cream", WHITE)
    coral = material("Candy_Player_Coral", CORAL)
    mint = material("Candy_Player_Mint", MINT)
    face = material("Candy_Player_Face", TEXT)

    bpy.ops.object.empty_add(type="PLAIN_AXES", location=(0, 0, 0))
    root = bpy.context.object
    root.name = "root"

    body = ellipsoid("marshmallow_body", (0, 0, 0.58), (0.34, 0.26, 0.42), cream)
    head = ellipsoid("cream_head", (0, 0, 1.02), (0.27, 0.23, 0.26), whipped)
    cap = ellipsoid("cream_cap", (0, -0.01, 1.22), (0.22, 0.19, 0.10), whipped)
    face_badge = cube("face_badge", (0, -0.235, 1.03), (0.25, 0.035, 0.15), face)
    left_eye = ellipsoid("left_eye", (-0.065, -0.265, 1.055), (0.024, 0.012, 0.035), face, 16, 8)
    right_eye = ellipsoid("right_eye", (0.065, -0.265, 1.055), (0.024, 0.012, 0.035), face, 16, 8)
    smile = cube("smile", (0, -0.275, 0.99), (0.11, 0.018, 0.025), face)

    left_arm = cyl("arm_left_mint", (-0.34, -0.01, 0.74), 0.055, 0.42, mint)
    left_arm.rotation_euler[1] = math.radians(72)
    right_arm = cyl("arm_right_coral", (0.34, -0.01, 0.74), 0.055, 0.42, coral)
    right_arm.rotation_euler[1] = math.radians(-72)
    left_hand = ellipsoid("hand_left_mint", (-0.49, -0.01, 0.58), (0.075, 0.065, 0.075), mint, 16, 8)
    right_hand = ellipsoid("hand_right_coral", (0.49, -0.01, 0.58), (0.075, 0.065, 0.075), coral, 16, 8)

    left_leg = cyl("leg_left_coral", (-0.14, 0, 0.22), 0.06, 0.36, coral)
    left_leg.rotation_euler[0] = math.radians(4)
    right_leg = cyl("leg_right_mint", (0.14, 0, 0.22), 0.06, 0.36, mint)
    right_leg.rotation_euler[0] = math.radians(-4)
    left_foot = cube("foot_left_coral", (-0.16, -0.03, 0.035), (0.16, 0.23, 0.07), coral)
    right_foot = cube("foot_right_mint", (0.16, -0.03, 0.035), (0.16, 0.23, 0.07), mint)

    sprinkle_a = cube("sprinkle_coral", (-0.09, -0.25, 1.20), (0.09, 0.025, 0.025), coral)
    sprinkle_a.rotation_euler[2] = math.radians(18)
    sprinkle_b = cube("sprinkle_mint", (0.09, -0.25, 1.19), (0.09, 0.025, 0.025), mint)
    sprinkle_b.rotation_euler[2] = math.radians(-20)

    objects = [
        body,
        head,
        cap,
        face_badge,
        left_eye,
        right_eye,
        smile,
        left_arm,
        right_arm,
        left_hand,
        right_hand,
        left_leg,
        right_leg,
        left_foot,
        right_foot,
        sprinkle_a,
        sprinkle_b,
    ]
    parent_to(root, objects)

def export(path):
    path.parent.mkdir(parents=True, exist_ok=True)
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.export_scene.gltf(
        filepath=str(path),
        export_format="GLB",
        use_selection=True,
        use_visible=True,
        export_apply=True,
        export_yup=True,
        export_animations=False,
    )


if __name__ == "__main__":
    clear_scene()
    build_player()
    output = OUT_DIR / "character_candy_marshmallow.glb"
    export(output)
    print("wrote", output)
