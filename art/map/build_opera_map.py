# Builds the opera house map in Blender, saves opera_house.blend and exports it for Roblox (export_map.py).
#
# Run from anywhere:
#   "D:\SteamLibrary\steamapps\common\Blender\blender.exe" -b --factory-startup --python build_opera_map.py
#
# After that, the .blend is the source of truth: open it in Blender, move or add objects, then run
#   blender opera_house.blend -b --python export_map.py
#
# Conventions (read by export_map.py):
#   obj["rbx"] = "part" | "marker" | "light"; parts carry rbx_class, rbx_shape, rbx_material, rbx_collide,
#   rbx_transparency, rbx_tag. The object color is the Roblox color. 1 Blender unit = 1 stud.
#   Blender axes: X east, Y north (towards backstage), Z up. Auditorium floor at Z = 0.
import bpy, bmesh, math, os, sys

HERE = os.path.dirname(os.path.abspath(__file__))

# name: (Roblox material, color)
MATERIALS = {
    "stage_wood": ("WoodPlanks", (0.33, 0.22, 0.14)),
    "dark_wood": ("Wood", (0.20, 0.13, 0.08)),
    "plaster": ("Plaster", (0.34, 0.29, 0.25)),
    "wall_red": ("Plaster", (0.30, 0.06, 0.07)),
    "brick": ("Brick", (0.30, 0.20, 0.17)),
    "concrete": ("Concrete", (0.26, 0.25, 0.24)),
    "carpet": ("Carpet", (0.32, 0.05, 0.07)),
    "velvet": ("Fabric", (0.42, 0.04, 0.07)),
    "black_cloth": ("Fabric", (0.05, 0.05, 0.06)),
    "costume_a": ("Fabric", (0.18, 0.10, 0.22)),
    "costume_b": ("Fabric", (0.35, 0.30, 0.22)),
    "gold": ("Metal", (0.62, 0.48, 0.22)),
    "marble": ("Marble", (0.52, 0.49, 0.45)),
    "metal": ("Metal", (0.24, 0.24, 0.26)),
    "plate": ("DiamondPlate", (0.30, 0.30, 0.32)),
    "rust": ("CorrodedMetal", (0.36, 0.22, 0.14)),
    "rope": ("Fabric", (0.50, 0.42, 0.30)),
    "glass": ("Glass", (0.75, 0.80, 0.85)),
    "water": ("Glass", (0.06, 0.20, 0.23)),
    "neon_red": ("Neon", (1.00, 0.20, 0.15)),
    "neon_orange": ("Neon", (1.00, 0.45, 0.10)),
    "bulb": ("Neon", (1.00, 0.86, 0.60)),
    "leather": ("Leather", (0.24, 0.14, 0.09)),
    "fuse": ("DiamondPlate", (0.22, 0.22, 0.24)),
    "marker": ("SmoothPlastic", (1.0, 1.0, 1.0)),
}

bpy.ops.wm.read_factory_settings(use_empty=True)
scene = bpy.context.scene


def unit_mesh(name, build):
    mesh = bpy.data.meshes.new(name)
    bm = bmesh.new()
    build(bm)
    bm.to_mesh(mesh)
    bm.free()
    return mesh


CUBE = unit_mesh("UnitCube", lambda bm: bmesh.ops.create_cube(bm, size=1))
CYL = unit_mesh("UnitCylinder", lambda bm: bmesh.ops.create_cone(bm, cap_ends=True, segments=16, radius1=0.5, radius2=0.5, depth=1))
BALL = unit_mesh("UnitBall", lambda bm: bmesh.ops.create_uvsphere(bm, u_segments=16, v_segments=8, radius=0.5))

COLLECTIONS = {}


def collection(name):
    if name not in COLLECTIONS:
        col = bpy.data.collections.new(name)
        scene.collection.children.link(col)
        COLLECTIONS[name] = col
    return COLLECTIONS[name]


AREA = ["Map"]  # current collection name, set per section


def place(name, mesh, location, scale, mat, shape, cls="Part", tag="", collide=True, transparency=0.0, rotation=(0, 0, 0)):
    obj = bpy.data.objects.new(name, mesh)
    obj.location = location
    obj.scale = scale
    obj.rotation_euler = rotation
    material, color = MATERIALS[mat]
    obj.color = (*color, 1.0)
    obj["rbx"] = "part"
    obj["rbx_class"] = cls
    obj["rbx_shape"] = shape
    obj["rbx_material"] = material
    obj["rbx_collide"] = collide
    obj["rbx_transparency"] = 0.35 if mat == "water" else (0.5 if mat == "glass" else transparency)
    obj["rbx_tag"] = tag
    collection(AREA[0]).objects.link(obj)
    return obj


def box(name, x0, y0, z0, x1, y1, z1, mat, **kw):
    """Axis-aligned box between two corners."""
    return place(name, CUBE, ((x0 + x1) / 2, (y0 + y1) / 2, (z0 + z1) / 2), (abs(x1 - x0), abs(y1 - y0), abs(z1 - z0)), mat, "Block", **kw)


def cyl(name, x, y, z0, z1, radius, mat, axis="z", **kw):
    """Cylinder: along Z from z0 to z1 at (x, y), or along X/Y with z0..z1 as the span on that axis and z = radius height."""
    if axis == "z":
        return place(name, CYL, (x, y, (z0 + z1) / 2), (radius * 2, radius * 2, z1 - z0), mat, "Cylinder", **kw)
    raise ValueError("use hcyl for horizontal cylinders")


def hcyl(name, x0, x1, y0, y1, z, radius, mat, **kw):
    """Horizontal cylinder from (x0, y0) to (x1, y1) at height z."""
    length = math.hypot(x1 - x0, y1 - y0)
    angle = math.atan2(y1 - y0, x1 - x0)
    # The unit cylinder runs along local Z; tip it onto X, then turn it to the direction.
    return place(name, CYL, ((x0 + x1) / 2, (y0 + y1) / 2, z), (radius * 2, radius * 2, length), mat, "Cylinder",
                 rotation=(0, math.radians(90), angle), **kw)


def ball(name, x, y, z, diameter, mat, **kw):
    return place(name, BALL, (x, y, z), (diameter, diameter, diameter), mat, "Ball", **kw)


def marker(name, x0, y0, z0, x1, y1, z1, tag):
    obj = box(name, x0, y0, z0, x1, y1, z1, "marker", tag=tag, collide=False, transparency=1.0)
    obj["rbx"] = "marker"
    obj.display_type = "WIRE"
    return obj


def point(name, x, y, z, tag):
    """A 1-stud marker standing on the floor at height z."""
    return marker(name, x - 0.5, y - 0.5, z, x + 0.5, y + 0.5, z + 1, tag)


def light(name, x, y, z, color, rng, brightness, kind="PointLight", direction=(0, 0, -1), angle=60):
    data = bpy.data.lights.new(name, type="SPOT" if kind == "SpotLight" else "POINT")
    data.color = color
    obj = bpy.data.objects.new(name, data)
    obj.location = (x, y, z)
    if kind == "SpotLight":
        # Blender spots shine along local -Z; aim that axis at the direction.
        from mathutils import Vector
        obj.rotation_euler = Vector(direction).to_track_quat("-Z", "Y").to_euler()
        data.spot_size = math.radians(angle)
    obj["rbx"] = "light"
    obj["rbx_kind"] = kind
    obj["rbx_range"] = rng
    obj["rbx_brightness"] = brightness
    obj["rbx_angle"] = angle
    collection(AREA[0]).objects.link(obj)
    return obj


def wall_x(name, x0, x1, y0, y1, z0, z1, mat, doors=()):
    """Wall along X from x0 to x1 (thickness y0..y1), with door openings (xa, xb, top) starting at z0."""
    x = x0
    for xa, xb, top in sorted(doors):
        if xa > x:
            box(name, x, y0, z0, xa, y1, z1, mat)
        if top < z1:
            box(name + "Lintel", xa, y0, top, xb, y1, z1, mat)
        x = xb
    if x < x1:
        box(name, x, y0, z0, x1, y1, z1, mat)


def wall_y(name, y0, y1, x0, x1, z0, z1, mat, doors=()):
    """Wall along Y from y0 to y1 (thickness x0..x1), with door openings (ya, yb, top) starting at z0."""
    y = y0
    for ya, yb, top in sorted(doors):
        if ya > y:
            box(name, x0, y, z0, x1, ya, z1, mat)
        if top < z1:
            box(name + "Lintel", x0, ya, top, x1, yb, z1, mat)
        y = yb
    if y < y1:
        box(name, x0, y, z0, x1, y1, z1, mat)


# ---------------------------------------------------------------- Auditorium (Z = 0)
AREA[0] = "Auditorium"
box("AudFloor", -36, -64, -1, 36, -22, 0, "carpet")
box("AudFloorWest", -36, -22, -1, -24, -16, 0, "carpet")
box("AudFloorEast", 28, -22, -1, 36, -16, 0, "carpet")
box("AudWallS", -38, -66, -1, 38, -64, 31, "wall_red")
box("AudWallW", -38, -64, -1, -36, -16, 31, "wall_red")
box("AudWallE", 36, -64, -1, 38, -16, 31, "wall_red")
box("AudCeiling", -38, -66, 30, 38, -16, 31, "plaster")
for i in range(10):
    y = -56 + i * 2.8
    for side, (xa, xb) in (("W", (-32, -5)), ("E", (5, 32))):
        box(f"SeatRow{side}{i}", xa, y, 0, xb, y + 1.6, 1.3, "velvet")
        box(f"SeatBack{side}{i}", xa, y - 0.4, 0, xb, y, 3.0, "velvet")
for tier, z in (("Low", 11), ("High", 19)):
    for side, sign in (("W", -1), ("E", 1)):
        xa, xb = sorted((sign * 36, sign * 30))
        box(f"Balcony{tier}{side}", xa, -60, z, xb, -26, z + 1, "dark_wood")
        rail_x = sign * 30
        box(f"BalconyRail{tier}{side}", min(rail_x, rail_x - sign * 0.6), -60, z + 1, max(rail_x, rail_x - sign * 0.6), -26, z + 3, "gold")
cyl("ChandelierChain", 0, -42, 24.5, 30, 0.15, "metal")
cyl("Chandelier", 0, -42, 23.5, 25, 3, "gold")
ball("ChandelierGlass", 0, -42, 22.6, 3.4, "glass", collide=False)
light("ChandelierLight", 0, -42, 22, (1.0, 0.75, 0.5), 32, 0.5)
light("AudEmergencyW", -35.5, -40, 10, (1.0, 0.3, 0.2), 20, 0.8)
light("AudEmergencyE", 35.5, -30, 10, (1.0, 0.3, 0.2), 20, 0.8)
box("AudEmergencyLampW", -36, -40.5, 9.5, -35.6, -39.5, 10.5, "neon_red", collide=False)
box("AudEmergencyLampE", 35.6, -30.5, 9.5, 36, -29.5, 10.5, "neon_red", collide=False)
point("PatrolAisleBack", 0, -50, 0, "EntityPatrolPoint")
point("PatrolAisleFront", 0, -28, 0, "EntityPatrolPoint")
point("BottleSeats", -20, -44, 1.3, "BottleSpawn")

# ---------------------------------------------------------------- Orchestra pit (Z = -4)
AREA[0] = "OrchestraPit"
box("PitFloor", -24, -22, -5, 25, -16, -4, "dark_wood")
box("PitRail", -24, -22, -4, 24, -21.4, 1, "dark_wood")
box("PitWallW", -24.6, -22, -5, -24, -16, 0, "dark_wood")
for k in range(1, 5):  # steps down from the auditorium on the east side
    box(f"PitStep{k}", 28 - k, -22, -5, 29 - k, -16, -k, "dark_wood")
box("Piano", -19, -21, -2.2, -12, -17, -1.2, "black_cloth")
for i, (px, py) in enumerate(((-18.5, -20.5), (-12.5, -20.5), (-15.5, -17.5))):
    cyl(f"PianoLeg{i}", px, py, -4, -2.2, 0.25, "black_cloth")
for i in range(6):
    box(f"MusicStand{i}", -6 + i * 4, -19.5, -4, -5.6 + i * 4, -19.1, -1.5, "metal")
    box(f"PitChair{i}", -6.5 + i * 4, -18.5, -4, -5 + i * 4, -17, -3, "dark_wood")
box("FuseBoxPit", -24, -20, -3, -23.4, -18, 0, "fuse", tag="FuseBox")
point("PatrolPit", 0, -19, -4, "EntityPatrolPoint")
point("BottlePiano", -15.5, -19, -1.2, "BottleSpawn")

# ---------------------------------------------------------------- Proscenium wall (y -16..-14) with steps up to the side doors
AREA[0] = "Proscenium"
for side, sign in (("W", -1), ("E", 1)):
    def sx(a, b):
        return sorted((sign * a, sign * b))
    xa, xb = sx(50, 34)
    box(f"Prosc{side}Outer", xa, -16, -18, xb, -14, 35, "wall_red")
    xa, xb = sx(34, 28)
    box(f"Prosc{side}DoorLintel", xa, -16, 13, xb, -14, 35, "wall_red")
    box(f"Prosc{side}DoorSill", xa, -16, -18, xb, -14, 4, "wall_red")
    xa, xb = sx(28, 22)
    box(f"Prosc{side}Inner", xa, -16, -18, xb, -14, 35, "wall_red")
    xa, xb = sx(23, 22)
    box(f"ProscFrame{side}", xa, -16.6, 4, xb, -16, 26, "gold")
    for k in range(1, 5):
        xa, xb = sx(34, 28)
        box(f"ProscStep{side}{k}", xa, -22 + (k - 1) * 1.5, -1, xb, -16, k, "dark_wood")
box("ProscTop", -22, -16, 26, 22, -14, 35, "wall_red")
box("ProscFrameTop", -23, -16.6, 26, 23, -16, 27, "gold")
box("StageFront", -22, -16, -18, 22, -14, 4, "dark_wood")
box("CurtainW", -22, -13.6, 4, -12, -13, 26, "velvet")
box("CurtainE", 12, -13.6, 4, 22, -13, 26, "velvet")
box("Valance", -22, -13.6, 22, 22, -13, 26, "velvet")

# ---------------------------------------------------------------- Stage, wings and fly loft (Z = 4)
AREA[0] = "Stage"
box("StageFloor", -30, -14, 3, 30, 18, 4, "stage_wood")
box("WingFloorW", -48, -14, 3, -30, 18, 4, "dark_wood")
box("WingFloorE", 30, -14, 3, 48, 18, 4, "dark_wood")
box("Trapdoor", -3, 2, 4, 3, 8, 4.05, "dark_wood")
box("StageRoof", -50, -16, 35, 50, 20, 36, "plaster")
box("StageNorthSill", -48, 18, 3, 48, 20, 4, "dark_wood")
wall_x("StageNorthWall", -48, 48, 18, 20, 4, 35, "brick", doors=((-42, -36, 15), (-4, 4, 15), (36, 42, 15)))
# Outer east and west walls run the full building, basement to roof. The west one has the stage door.
box("OuterWallE", 48, -16, -18, 50, 48, 36, "brick")
box("OuterWallW_South", -50, -16, -18, -48, 21, 36, "brick")
box("OuterWallW_DoorSill", -50, 21, -18, -48, 27, 4, "brick")
box("OuterWallW_DoorLintel", -50, 21, 15, -48, 27, 36, "brick")
box("OuterWallW_North", -50, 27, -18, -48, 48, 36, "brick")
# Masking legs (black curtains) at the sides of the stage: good places to hide.
for side, sign in (("W", -1), ("E", 1)):
    for i, y in enumerate((-6, 2, 10)):
        xa, xb = sorted((sign * 22, sign * 30))
        box(f"Leg{side}{i}", xa, y, 4, xb, y + 0.6, 26, "black_cloth")
# The ghost light: one bare bulb left burning on an empty stage.
cyl("GhostLightBase", 0, 4, 4, 4.3, 0.8, "metal")
cyl("GhostLightStand", 0, 4, 4.3, 9, 0.12, "metal")
ball("GhostLightBulb", 0, 4, 9.3, 0.7, "bulb", collide=False)
light("GhostLight", 0, 4, 9.3, (1.0, 0.82, 0.55), 24, 1.2)
# Scenery: a throne on a platform, a painted flat and crates.
box("ThronePlatform", 8, 6, 4, 18, 12, 5, "dark_wood")
box("ThroneSeat", 12, 9, 5, 14.5, 11, 6.5, "velvet")
box("ThroneBack", 12, 11, 5, 14.5, 11.6, 10, "gold")
box("PaintedFlat", -18, 12, 4, -6, 12.5, 14, "plaster")
box("FlatBrace", -12.5, 12.5, 4, -11.5, 15, 10, "dark_wood")
for i, (bx, by) in enumerate(((-40, -8), (-36, 8), (38, -4), (42, 10))):
    box(f"WingCrate{i}", bx - 2, by - 2, 4, bx + 2, by + 2, 8, "dark_wood")
# Fly rail: ropes and sandbags in the east wing.
for i in range(9):
    cyl(f"FlyRope{i}", 47, -8 + i * 2, 4.5, 34, 0.12, "rope", collide=False)
for i in range(3):
    box(f"Sandbag{i}", 46.2, -7 + i * 6, 4, 47.8, -5.5 + i * 6, 5.5, "rope")
# Battens with stage lamps hanging over the stage.
for i, y in enumerate((-8, 0, 8)):
    box(f"Batten{i}", -26, y, 28, 26, y + 0.4, 28.4, "metal")
    for j, x in enumerate((-12, 12)):
        cyl(f"StageLamp{i}{j}", x, y + 0.2, 26.8, 28, 0.5, "metal")
light("StageSpot", 0, 0, 27, (1.0, 0.85, 0.65), 34, 1.5, kind="SpotLight", direction=(0, 0.1, -1), angle=45)
# Catwalks in the fly loft (Z = 22), reached by ladders in the wings.
box("CatwalkE", 40, -12, 21, 46, 16, 22, "plate")
box("CatwalkW", -46, -12, 21, -40, 16, 22, "plate")
box("CatwalkBridge", -40, 14, 21, 40, 17.4, 22, "plate")
box("CatwalkRailE", 40, -12, 22, 40.3, 14, 25, "metal")
box("CatwalkRailW", -40.3, -12, 22, -40, 14, 25, "metal")
box("CatwalkRailBridge", -40, 14, 22, 40, 14.3, 25, "metal")
box("LadderE", 46, -12, 4, 48, -10, 22, "metal", cls="TrussPart")
box("LadderW", -48, -12, 4, -46, -10, 22, "metal", cls="TrussPart")
box("FuseBoxFlyLoft", -1, 17.4, 22.5, 1, 18, 25.5, "fuse", tag="FuseBox")
light("CatwalkWork", 0, 16, 26, (0.9, 0.9, 1.0), 14, 0.5)
light("WingEmergencyW", -47.5, 0, 12, (1.0, 0.3, 0.2), 22, 0.8)
light("WingEmergencyE", 47.5, 4, 12, (1.0, 0.3, 0.2), 22, 0.8)
box("WingEmergencyLampW", -48, -0.5, 11.5, -47.6, 0.5, 12.5, "neon_red", collide=False)
box("WingEmergencyLampE", 47.6, 3.5, 11.5, 48, 4.5, 12.5, "neon_red", collide=False)
point("PatrolStage", 0, -6, 4, "EntityPatrolPoint")
point("PatrolStageBack", -4, 12, 4, "EntityPatrolPoint")
point("PatrolWingW", -40, 2, 4, "EntityPatrolPoint")
point("PatrolWingE", 39, 4, 4, "EntityPatrolPoint")
point("BottleThrone", 9.5, 7.5, 5, "BottleSpawn")
point("BottleWingCrate", -40, -8, 8, "BottleSpawn")

# ---------------------------------------------------------------- Corridor and rooms (Z = 4)
AREA[0] = "Backstage"
box("CorridorFloor", -48, 20, 3, 48, 30, 4, "dark_wood")
box("RoomsFloor", -48, 30, 3, 32, 46, 4, "dark_wood")
box("BackstageCeiling", -48, 20, 16, 48, 46, 17, "plaster")
box("OuterWallN", -50, 46, -18, 50, 48, 17, "brick")
wall_x("CorridorNorthWall", -48, 48, 28, 30, 4, 16, "plaster",
       doors=((-44, -38, 14), (-30, -24, 14), (-9, -3, 14), (18, 24, 14), (33, 39, 14)))
for name, x in (("WallDressing", -34), ("WallWardrobe", -20), ("WallProps", 10), ("WallStairs", 32)):
    box(name, x - 0.5, 30, 4, x + 0.5, 46, 16, "plaster")
# Stage door (the exit), its sign and the alley outside.
box("StageDoor", -50, 21, 4, -48, 27, 15, "dark_wood", tag="ExitDoor")
box("ExitSign", -48, 22.5, 15.1, -47.7, 25.5, 15.9, "neon_red", collide=False)
light("ExitSignLight", -47.4, 24, 15.5, (1.0, 0.3, 0.2), 16, 1.2)
box("Alley", -60, 19, 3, -50, 29, 4, "concrete")
marker("ExitZone", -60, 19, 2, -51, 29, 16, "ExitZone")
for i, x in enumerate((-30, 0, 30)):
    box(f"CorridorLamp{i}", x - 0.5, 27.6, 12.5, x + 0.5, 28, 13.5, "neon_red", collide=False)
    light(f"CorridorEmergency{i}", x, 27.4, 13, (1.0, 0.3, 0.2), 18, 0.7)
point("PatrolCorridorW", -12, 24, 4, "EntityPatrolPoint")
point("PatrolCorridorE", 26, 24, 4, "EntityPatrolPoint")
# Dressing rooms: mirrors ringed with bulbs, tables, a costume dummy. Players spawn in the first one.
for i, (xa, xb) in enumerate(((-48, -34.5), (-33.5, -20.5))):
    cx = (xa + xb) / 2
    box(f"DressingTable{i}", cx - 5, 43.5, 4, cx + 5, 46, 7, "dark_wood")
    box(f"Mirror{i}", cx - 4.5, 45.6, 8, cx + 4.5, 46, 12, "glass")
    for j in range(5):
        ball(f"MirrorBulb{i}{j}", cx - 4 + j * 2, 45.5, 12.5, 0.5, "bulb", collide=False)
    light(f"MirrorLight{i}", cx, 44.5, 11, (1.0, 0.8, 0.55), 16, 0.6)
    box(f"DressingChair{i}", cx - 1, 41, 4, cx + 1, 42.5, 6, "leather")
    cyl(f"DummyBody{i}", cx + 4, 34, 4, 9.5, 0.7, "costume_b")
    ball(f"DummyHead{i}", cx + 4, 34, 10.2, 1.2, "plaster")
    point(f"BottleDressing{i}", cx - 3, 44.5, 7, "BottleSpawn")
marker("PlayerSpawn", -44, 33, 4, -38, 39, 5, "PlayerSpawn")
# Wardrobe: racks of hanging costumes (cloth does not collide, so you can hide among them).
for r, y in enumerate((34, 38, 42)):
    for side, (xa, xb) in enumerate(((-18, -6), (-3, 8))):
        hcyl(f"RackBar{r}{side}", xa, xb, y, y, 12.6, 0.15, "metal", collide=False)
        cyl(f"RackPost{r}{side}a", xa, y, 4, 12.6, 0.15, "metal")
        cyl(f"RackPost{r}{side}b", xb, y, 4, 12.6, 0.15, "metal")
        for c in range(5):
            x = xa + 1.2 + c * (xb - xa - 2.4) / 4
            box(f"Costume{r}{side}{c}", x - 0.8, y - 0.25, 6.5, x + 0.8, y + 0.25, 12.4,
                "costume_a" if (c + r) % 2 else "velvet", collide=False)
box("Trunk", -17, 30.5, 4, -13, 32.5, 6, "leather")
point("BottleTrunk", -15, 31.5, 6, "BottleSpawn")
point("PatrolWardrobe", -5, 36, 4, "EntityPatrolPoint")
light("WardrobeLight", -5, 40, 14, (0.8, 0.75, 0.9), 18, 0.35)
# Prop store: shelves, masks and crates.
box("ShelfN", 12, 44.5, 4, 30, 46, 7, "dark_wood")
box("ShelfW", 10.5, 32, 4, 12, 44, 9, "dark_wood")
for i in range(6):
    ball(f"Mask{i}", 13 + i * 3, 45.2, 7.6, 1.1, "plaster")
for i, (bx, by) in enumerate(((18, 35), (26, 38), (22, 41))):
    box(f"PropCrate{i}", bx - 2, by - 2, 4, bx + 2, by + 2, 7, "dark_wood")
point("BottleShelf", 20, 45.2, 7, "BottleSpawn")
point("PatrolProps", 20, 32, 4, "EntityPatrolPoint")
light("PropsLight", 21, 38, 14, (1.0, 0.6, 0.4), 16, 0.35)

# ---------------------------------------------------------------- Stairwell down to the basement
AREA[0] = "Stairwell"
RUN = 1.3
for i in range(1, 10):  # first flight: Z 4 -> -5 going north
    box(f"StairA{i}", 32, 30 + (i - 1) * RUN, -14, 40, 30 + i * RUN, 4 - i, "concrete")
landing_y = 30 + 9 * RUN
box("StairLanding", 32, landing_y, -14, 48, 46, -5, "concrete")
for j in range(1, 9):  # second flight: Z -5 -> -13 going south
    box(f"StairB{j}", 40, landing_y - j * RUN, -14, 48, landing_y - (j - 1) * RUN, -5 - j, "concrete")
light("StairLight", 44, 38, 2, (1.0, 0.3, 0.2), 20, 0.6)

# ---------------------------------------------------------------- Basement (Z = -14): trap room, machine vault, cistern
AREA[0] = "Basement"
box("TrapFloor", -32, -14, -15, 32, 18, -14, "concrete")  # reaches under the doorways in the side walls
box("VaultFloor", 32, -14, -15, 48, 46, -14, "concrete")
box("StageNorthLow", -48, 18, -18, 32, 20, 3, "brick")
box("VaultWallW", 30, 20, -14, 32, 46, 3, "brick")
wall_y("TrapWallE", -14, 18, 30, 32, -14, 3, "brick", doors=((-6, 2, -3),))
wall_y("TrapWallW", -14, 18, -32, -30, -14, 3, "brick", doors=((0, 8, -3),))
box("TrapWallWDeep", -32, -14, -18, -30, 18, -14, "brick")
for i, x in enumerate((-20, -10, 10, 20)):
    for j, y in enumerate((-6, 2, 10)):
        cyl(f"StageColumn{i}{j}", x, y, -14, 3, 0.8, "dark_wood")
box("StageLift", -3, 2, -14, 3, 8, -12, "metal")
for i, (px, py) in enumerate(((-3, 2), (3, 2), (-3, 8), (3, 8))):
    cyl(f"LiftRail{i}", px, py, -12, 3, 0.2, "metal")
for i, (bx, by) in enumerate(((-24, -10), (22, 14), (-14, 14))):
    box(f"TrapCrate{i}", bx - 2, by - 2, -14, bx + 2, by + 2, -10, "dark_wood")
box("BrokenFlat", 12, -10, -14, 22, -9.5, -6, "plaster", rotation=(0, 0, 0))
light("TrapLight", 0, 5, -2, (0.7, 0.75, 0.9), 26, 0.35)
point("PatrolTrapW", -15, -6, -14, "EntityPatrolPoint")
point("PatrolTrapE", 15, 6, -14, "EntityPatrolPoint")
# Machine vault: boilers glowing, pipes along the wall, the main fuse panel.
for i, y in enumerate((-4, 8)):
    cyl(f"Boiler{i}", 40, y, -14, -5, 2.5, "rust")
    box(f"FurnaceGlow{i}", 38.6, y - 2.6, -13, 41.4, y - 2.4, -11.5, "neon_orange", collide=False)
    light(f"FurnaceLight{i}", 40, y - 3.5, -12, (1.0, 0.45, 0.15), 18, 1.0)
for i, z in enumerate((-4, -2)):
    hcyl(f"Pipe{i}", 47, 47, -12, 28, z, 0.4, "rust")  # stops before the stairwell so it is not at head height there
box("FuseBoxVault", 47.4, 18, -12, 48, 20, -9, "fuse", tag="FuseBox")
box("VaultCrate", 34, 18, -14, 38, 22, -10, "dark_wood")
point("BottleVault", 36, 20, -10, "BottleSpawn")
point("PatrolVaultS", 40, -10, -14, "EntityPatrolPoint")
point("PatrolVaultN", 42, 24, -14, "EntityPatrolPoint")
# The cistern: black water under the stage, a narrow bridge and a ledge (after the lake under the Palais Garnier).
box("CisternFloor", -48, -14, -19, -32, 18, -18, "concrete")
box("CisternWater", -48, -14, -15.4, -32, 18, -15.2, "water", collide=False)
box("CisternBridge", -44, 2, -15, -32, 6, -14, "dark_wood")
box("CisternLedge", -48, -12, -15, -44, 16, -14, "concrete")
for k in range(1, 5):  # steps out of the water, rising west onto the ledge
    x1 = -38.8 - (k - 1) * 1.3
    box(f"CisternStep{k}", x1 - 1.3, 12, -19, x1, 16, -18 + k, "concrete")
box("CisternNorthDeep", -48, 18, -18, -32, 20, -14, "brick")
box("Boat", -40, -8, -16.5, -36, -1, -15.2, "dark_wood")
light("CisternLight", -40, 2, -10, (0.3, 0.7, 0.8), 26, 0.6)
point("BottleLedge", -46, -6, -14, "BottleSpawn")
point("PatrolLedge", -46, 8, -14, "EntityPatrolPoint")

# ---------------------------------------------------------------- Start screen camera: from the stalls towards the ghost light
AREA[0] = "Map"
cam_data = bpy.data.cameras.new("MenuCamera")
cam = bpy.data.objects.new("MenuCamera", cam_data)
cam.location = (0, -54, 9)
from mathutils import Vector
cam.rotation_euler = (Vector((0, 4, 7)) - cam.location).to_track_quat("-Z", "Y").to_euler()
cam["rbx"] = "camera"
collection("Map").objects.link(cam)
scene.camera = cam

bpy.ops.wm.save_as_mainfile(filepath=os.path.join(HERE, "opera_house.blend"))
print("BUILD_DONE")

sys.path.insert(0, HERE)
import export_map  # noqa: E402

export_map.run()
