# Rigs the AI-generated Stagehand mesh for Roblox.
# Imports stagehand.gltf (exported from Studio), builds a skeleton, skins the mesh with automatic weights,
# renders a test pose to preview/ and exports stagehand_rigged.glb for Studio's 3D importer.
#
# Run (from this folder):
#   "D:\SteamLibrary\steamapps\common\Blender\blender.exe" -b --factory-startup --python rig_stagehand.py
#
# Blender axes: Z up, the monster faces +Y. Joint positions were measured from the mesh (feet centered on origin).
import bpy, os, math
from mathutils import Vector

HERE = os.path.dirname(os.path.abspath(__file__))
SRC = os.path.join(HERE, "stagehand.gltf")
OUT = os.path.join(HERE, "stagehand_rigged.glb")
PREVIEW = os.path.join(HERE, "preview")

# name: (head, tail, parent). Right side is +X (the monster's right when it faces +Y); left is mirrored.
BONES = {
    "Root": ((0, 0, 0), (0, 0, 1), None),
    "Hips": ((0, -0.1, 3.3), (0, -0.15, 4.4), "Root"),
    "Spine": ((0, -0.15, 4.4), (0, -0.2, 5.6), "Hips"),
    "Chest": ((0, -0.2, 5.6), (0, -0.05, 7.2), "Spine"),
    "Neck": ((0, -0.05, 7.2), (0, -0.1, 7.7), "Chest"),
    "Head": ((0, -0.1, 7.7), (0, 1.7, 7.85), "Neck"),
}
SIDED = {
    "UpperArm": ((1.0, -0.1, 6.35), (1.25, -0.53, 4.95), "Chest"),
    "LowerArm": ((1.25, -0.53, 4.95), (1.55, 0.08, 3.7), "UpperArm"),
    "Hand": ((1.55, 0.08, 3.7), (1.65, 0.3, 2.3), "LowerArm"),
    "UpperLeg": ((0.5, -0.14, 3.3), (0.68, 0.2, 1.85), "Hips"),
    "LowerLeg": ((0.68, 0.2, 1.85), (0.68, -0.16, 0.6), "UpperLeg"),
    "Foot": ((0.68, -0.16, 0.6), (0.7, 0.9, 0.15), "LowerLeg"),
}
for side, sign in (("R", 1), ("L", -1)):
    for name, (head, tail, parent) in SIDED.items():
        BONES[f"{name}.{side}"] = (
            (head[0] * sign, head[1], head[2]),
            (tail[0] * sign, tail[1], tail[2]),
            f"{parent}.{side}" if parent in SIDED else parent,
        )


BONE_DATA = {name: (Vector(h), Vector(t)) for name, (h, t, _) in BONES.items()}


def import_mesh():
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.import_scene.gltf(filepath=SRC)
    mesh = next(o for o in bpy.context.scene.objects if o.type == "MESH")
    # Bake the importer's parent transforms into the mesh and drop the empties.
    world = mesh.matrix_world.copy()
    mesh.parent = None
    mesh.matrix_world = world
    for o in list(bpy.context.scene.objects):
        if o is not mesh:
            bpy.data.objects.remove(o, do_unlink=True)
    bpy.context.view_layer.objects.active = mesh
    mesh.select_set(True)
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
    # Center the feet on the origin (measured: legs at y = -40.4).
    xs = [v.co.x for v in mesh.data.vertices]
    offset = Vector((-(min(xs) + max(xs)) / 2, 40.4, -min(v.co.z for v in mesh.data.vertices)))
    for v in mesh.data.vertices:
        v.co += offset
    mesh.name = "Stagehand"
    return mesh


def build_armature():
    data = bpy.data.armatures.new("StagehandRig")
    rig = bpy.data.objects.new("StagehandRig", data)
    bpy.context.scene.collection.objects.link(rig)
    bpy.context.view_layer.objects.active = rig
    bpy.ops.object.mode_set(mode="EDIT")
    for name, (head, tail, _) in BONES.items():
        bone = data.edit_bones.new(name)
        bone.head, bone.tail = Vector(head), Vector(tail)
    for name, (_, _, parent) in BONES.items():
        if parent:
            data.edit_bones[name].parent = data.edit_bones[parent]
    data.edit_bones["Root"].use_deform = False
    bpy.ops.object.mode_set(mode="OBJECT")
    return rig


def distance_to_bone(point, head, tail):
    segment = tail - head
    t = max(0.0, min(1.0, (point - head).dot(segment) / segment.length_squared))
    return (head + segment * t - point).length


def smoothstep(edge0, edge1, x):
    t = max(0.0, min(1.0, (x - edge0) / (edge1 - edge0)))
    return t * t * (3 - 2 * t)


# Torso bones by height, blended over BLEND around each boundary. The coat follows these, not the legs,
# so its thin shell does not tear when the legs swing.
TORSO = (("Hips", 4.4), ("Spine", 5.6), ("Chest", 7.2), ("Neck", 7.45), ("Head", None))
BLEND = 0.3
# Max distance from a limb bone for a vertex to belong to it (arms are thin, hands have spread fingers).
LIMB_RADIUS = {"UpperArm": 0.3, "LowerArm": 0.33, "Hand": 0.55, "UpperLeg": 0.35, "LowerLeg": 0.35}


def torso_weights(co):
    # The horn sticks out in front of the collar, so everything up there belongs to the head.
    if co.z > 7.45 or (co.y > 0.55 and co.z > 6.6):
        return {"Head": 1.0}
    weights = {}
    lower = 0.0
    for i, (name, top) in enumerate(TORSO):
        rise = 1.0 if i == 0 else smoothstep(lower - BLEND, lower + BLEND, co.z)
        fall = 1.0 if top is None else 1 - smoothstep(top - BLEND, top + BLEND, co.z)
        w = rise * fall
        if w > 0.001:
            weights[name] = w
        lower = top if top is not None else lower
    return weights


def limb_weights(co, bones, side):
    names = [f"{b}.{side}" for b in bones]
    dists = {}
    for base, name in zip(bones, names):
        bone = BONE_DATA[name]
        d = distance_to_bone(co, bone[0], bone[1])
        if d <= LIMB_RADIUS[base]:
            dists[name] = d
    if not dists:
        return None
    raw = {n: 1 / (d + 0.05) ** 4 for n, d in dists.items()}
    total = sum(raw.values())
    return {n: w / total for n, w in raw.items()}


def vertex_weights(co):
    side = "R" if co.x > 0 else "L"
    if co.z < 0.75:  # shoes and ankles
        foot = smoothstep(0.75, 0.5, co.z)
        return {f"Foot.{side}": foot, f"LowerLeg.{side}": 1 - foot} if foot < 1 else {f"Foot.{side}": 1.0}
    if co.z < 3.5:
        legs = limb_weights(co, ("UpperLeg", "LowerLeg"), side)
        if legs:
            return legs
    arms = limb_weights(co, ("UpperArm", "LowerArm", "Hand"), side)
    if arms:
        # Blend into the chest near the shoulder so the joint does not crease.
        shoulder = Vector(BONE_DATA[f"UpperArm.{side}"][0])
        t = smoothstep(0.15, 0.55, (co - shoulder).length)
        if t < 1:
            arms = {n: w * t for n, w in arms.items()}
            arms["Chest"] = arms.get("Chest", 0) + (1 - t)
        return arms
    return torso_weights(co)


def skin(mesh, rig):
    mesh.data.validate()
    bpy.ops.object.select_all(action="DESELECT")
    mesh.select_set(True)
    rig.select_set(True)
    bpy.context.view_layer.objects.active = rig
    bpy.ops.object.parent_set(type="ARMATURE_NAME")  # empty groups; weights are set below

    groups = {name: mesh.vertex_groups[name] for name in BONES if name in mesh.vertex_groups}
    for v in mesh.data.vertices:
        for name, w in vertex_weights(v.co).items():
            groups[name].add([v.index], w, "REPLACE")

    bpy.ops.object.select_all(action="DESELECT")
    mesh.select_set(True)
    bpy.context.view_layer.objects.active = mesh
    bpy.ops.object.mode_set(mode="WEIGHT_PAINT")  # the smoothing operator only runs in weight paint mode
    bpy.ops.object.vertex_group_smooth(group_select_mode="ALL", factor=0.5, repeat=2)
    bpy.ops.object.vertex_group_normalize_all(lock_active=False)
    bpy.ops.object.mode_set(mode="OBJECT")
    print(f"RIG: {len(mesh.data.vertices)} vertices weighted")


def render_previews(mesh, rig, label):
    os.makedirs(PREVIEW, exist_ok=True)
    scene = bpy.context.scene
    scene.render.engine = "BLENDER_WORKBENCH"
    scene.display.shading.color_type = "TEXTURE"
    scene.render.resolution_x, scene.render.resolution_y = 500, 750
    cam = scene.camera
    if cam is None:
        cam = bpy.data.objects.new("cam", bpy.data.cameras.new("cam"))
        cam.data.type = "ORTHO"
        cam.data.ortho_scale = 10.5
        scene.collection.objects.link(cam)
        scene.camera = cam
    center = Vector((0, 0.5, 4.6))
    for name, offset, rot in (
        ("front", Vector((0, 20, 0)), (math.radians(90), 0, math.radians(180))),
        ("side", Vector((20, 0, 0)), (math.radians(90), 0, math.radians(90))),
    ):
        cam.location = center + offset
        cam.rotation_euler = rot
        scene.render.filepath = os.path.join(PREVIEW, f"{label}_{name}.png")
        bpy.ops.render.render(write_still=True)


def pose_walk(rig, amount):
    pose = rig.pose.bones
    for b in pose:
        b.rotation_mode = "XYZ"
        b.rotation_euler = (0, 0, 0)
    pose["UpperLeg.R"].rotation_euler.x = math.radians(35 * amount)
    pose["UpperLeg.L"].rotation_euler.x = math.radians(-35 * amount)
    pose["LowerLeg.L"].rotation_euler.x = math.radians(-40 * amount)
    pose["UpperArm.R"].rotation_euler.x = math.radians(-30 * amount)
    pose["UpperArm.L"].rotation_euler.x = math.radians(30 * amount)
    pose["Spine"].rotation_euler.x = math.radians(15 * amount)
    pose["Head"].rotation_euler.z = math.radians(25 * amount)


mesh = import_mesh()
rig = build_armature()
skin(mesh, rig)
render_previews(mesh, rig, "rest")
pose_walk(rig, 1)
render_previews(mesh, rig, "walk")
pose_walk(rig, 0)

bpy.ops.object.select_all(action="DESELECT")
mesh.select_set(True)
rig.select_set(True)
bpy.ops.export_scene.gltf(filepath=OUT, export_format="GLB", use_selection=True, export_skins=True, export_animations=False)
print(f"RIG_DONE {OUT}")
