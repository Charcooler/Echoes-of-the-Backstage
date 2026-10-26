--!strict
-- Builds a small dark backstage room around the SpawnLocation for testing.
-- shortcut: map made in code so both of us get it through git; replace with a real map built in Studio later.

local CollectionService = game:GetService("CollectionService")
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)

-- Room spans X -40..40 and Z 10..-110; the spawn sits near the Z = 10 wall, the stage at the far end.
local WALL_HEIGHT = 22
local WOOD = Color3.fromRGB(70, 50, 35)

local DemoRoomService = {}

local function addPart(parent: Instance, name: string, size: Vector3, position: Vector3, color: Color3, material: Enum.Material): Part
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.Position = position
	part.Color = color
	part.Material = material
	part.Anchored = true
	part.Parent = parent
	return part
end

local function addEmergencyLight(parent: Instance, position: Vector3)
	local lamp = addPart(parent, "EmergencyLight", Vector3.new(1, 1, 1), position, Color3.fromRGB(255, 60, 40), Enum.Material.Neon)
	lamp.CanCollide = false
	local light = Instance.new("PointLight")
	light.Color = Color3.fromRGB(255, 80, 60)
	light.Range = 24
	light.Brightness = 1.5
	light.Parent = lamp
end

-- Invisible tagged part that only marks a place or an area for a service.
local function addMarker(parent: Instance, name: string, size: Vector3, position: Vector3, tag: string)
	local marker = addPart(parent, name, size, position, Color3.new(1, 1, 1), Enum.Material.SmoothPlastic)
	marker.Transparency = 1
	marker.CanCollide = false
	marker.CanQuery = false
	marker.CanTouch = false
	marker:AddTag(tag)
end

local function addFuseBox(parent: Instance, size: Vector3, position: Vector3)
	local box = addPart(parent, "FuseBox", size, position, Color3.fromRGB(55, 55, 60), Enum.Material.DiamondPlate)
	box:AddTag(Config.FUSE_BOX_TAG)
end

-- Exit door in the back wall of the stage, with a glowing EXIT sign above it and the escape zone behind it.
local function addExit(parent: Instance, wallColor: Color3)
	local wallY = WALL_HEIGHT / 2
	-- The back wall is split around a door gap at X -4..4, Y 3..15 (the stage top is Y = 3).
	addPart(parent, "WallNorthLeft", Vector3.new(38, WALL_HEIGHT, 2), Vector3.new(-23, wallY, -111), wallColor, Enum.Material.Brick)
	addPart(parent, "WallNorthRight", Vector3.new(38, WALL_HEIGHT, 2), Vector3.new(23, wallY, -111), wallColor, Enum.Material.Brick)
	addPart(parent, "WallNorthTop", Vector3.new(8, 7, 2), Vector3.new(0, 18.5, -111), wallColor, Enum.Material.Brick)
	addPart(parent, "WallNorthBottom", Vector3.new(8, 3, 2), Vector3.new(0, 1.5, -111), wallColor, Enum.Material.Brick)

	local door = addPart(parent, "ExitDoor", Vector3.new(8, 12, 1.6), Vector3.new(0, 9, -111), Color3.fromRGB(60, 35, 25), Enum.Material.Wood)
	door:AddTag(Config.EXIT_DOOR_TAG)
	addMarker(parent, "ExitZone", Vector3.new(10, 14, 6), Vector3.new(0, 7, -116), Config.EXIT_ZONE_TAG)

	local sign = addPart(parent, "ExitSign", Vector3.new(4, 1.4, 0.3), Vector3.new(0, 16.5, -109.9), Color3.fromRGB(255, 40, 30), Enum.Material.Neon)
	sign.CanCollide = false
	local gui = Instance.new("SurfaceGui")
	gui.Face = Enum.NormalId.Back -- the side facing into the room (+Z)
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Text = "EXIT"
	label.TextScaled = true
	label.FontFace = Font.fromEnum(Enum.Font.Bodoni)
	label.TextColor3 = Color3.new(1, 1, 1)
	label.Parent = gui
	gui.Parent = sign
	local light = Instance.new("PointLight")
	light.Color = Color3.fromRGB(255, 80, 60)
	light.Range = 18
	light.Brightness = 1.5
	light.Parent = sign
end

local function setDarkLighting()
	Lighting.ClockTime = 0
	Lighting.Brightness = 0
	Lighting.Ambient = Color3.fromRGB(25, 25, 32)
	Lighting.OutdoorAmbient = Color3.fromRGB(25, 25, 32)
	Lighting.EnvironmentDiffuseScale = 0
	Lighting.EnvironmentSpecularScale = 0
end

function DemoRoomService.init()
	local room = Instance.new("Model")
	room.Name = "DemoRoom"

	addPart(room, "Floor", Vector3.new(80, 0.2, 120), Vector3.new(0, 0.1, -50), WOOD, Enum.Material.WoodPlanks)
	local wallColor = Color3.fromRGB(45, 40, 40)
	local wallY = WALL_HEIGHT / 2
	addExit(room, wallColor)
	addPart(room, "WallSouth", Vector3.new(84, WALL_HEIGHT, 2), Vector3.new(0, wallY, 11), wallColor, Enum.Material.Brick)
	addPart(room, "WallWest", Vector3.new(2, WALL_HEIGHT, 120), Vector3.new(-41, wallY, -50), wallColor, Enum.Material.Brick)
	addPart(room, "WallEast", Vector3.new(2, WALL_HEIGHT, 120), Vector3.new(41, wallY, -50), wallColor, Enum.Material.Brick)

	-- Stage with curtains at the far end.
	addPart(room, "Stage", Vector3.new(60, 3, 22), Vector3.new(0, 1.5, -98), WOOD, Enum.Material.WoodPlanks)
	local velvet = Color3.fromRGB(90, 10, 20)
	addPart(room, "CurtainLeft", Vector3.new(14, 18, 1), Vector3.new(-23, 12, -88), velvet, Enum.Material.Fabric)
	addPart(room, "CurtainRight", Vector3.new(14, 18, 1), Vector3.new(23, 12, -88), velvet, Enum.Material.Fabric)

	-- Warm stage spotlight, also what the start screen camera looks at.
	local spotLamp = addPart(room, "StageSpotlight", Vector3.new(1, 1, 1), Vector3.new(0, 20, -94), Color3.new(0, 0, 0), Enum.Material.SmoothPlastic)
	spotLamp.Transparency = 1
	spotLamp.CanCollide = false
	local spotlight = Instance.new("SpotLight")
	spotlight.Face = Enum.NormalId.Bottom
	spotlight.Angle = 50
	spotlight.Range = 30
	spotlight.Brightness = 3
	spotlight.Color = Color3.fromRGB(255, 214, 160)
	spotlight.Parent = spotLamp

	-- Prop crates to hide behind.
	local crateColor = Color3.fromRGB(100, 75, 45)
	for _, position in { Vector3.new(-25, 2.5, -20), Vector3.new(18, 2.5, -35), Vector3.new(-10, 2.5, -55), Vector3.new(28, 2.5, -65), Vector3.new(-30, 2.5, -70), Vector3.new(5, 2.5, -75) } do
		addPart(room, "Crate", Vector3.new(5, 5, 5), position, crateColor, Enum.Material.Wood)
	end

	-- A bottle on top of some of the crates.
	for _, position in { Vector3.new(-25, 5.6, -20), Vector3.new(18, 5.6, -35), Vector3.new(-10, 5.6, -55), Vector3.new(5, 5.6, -75) } do
		addMarker(room, "BottleSpawn", Vector3.new(1, 1, 1), position, Config.BOTTLE_SPAWN_TAG)
	end

	-- Three fuse boxes spread out: west wall, east wall and on the stage next to the exit.
	addFuseBox(room, Vector3.new(0.6, 3, 2), Vector3.new(-39.7, 5, -50))
	addFuseBox(room, Vector3.new(0.6, 3, 2), Vector3.new(39.7, 5, -25))
	addFuseBox(room, Vector3.new(2, 3, 0.6), Vector3.new(-26, 7, -109.7))

	for _, position in { Vector3.new(-39, 10, -20), Vector3.new(39, 10, -50), Vector3.new(-39, 10, -80) } do
		addEmergencyLight(room, position)
	end

	-- Patrol points stay in the far two thirds so a new player does not spawn next to the entity.
	for _, position in { Vector3.new(-30, 1, -40), Vector3.new(30, 1, -45), Vector3.new(0, 1, -60), Vector3.new(-25, 1, -85), Vector3.new(25, 1, -82), Vector3.new(0, 1, -30) } do
		addMarker(room, "PatrolPoint", Vector3.new(1, 1, 1), position, Config.PATROL_POINT_TAG)
	end

	room.Parent = workspace
	setDarkLighting()
end

return DemoRoomService
