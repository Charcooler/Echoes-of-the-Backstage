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

local function addPatrolPoint(parent: Instance, position: Vector3)
	local point = addPart(parent, "PatrolPoint", Vector3.new(1, 1, 1), position, Color3.new(1, 1, 1), Enum.Material.SmoothPlastic)
	point.Transparency = 1
	point.CanCollide = false
	point.CanQuery = false
	point.CanTouch = false
	point:AddTag(Config.PATROL_POINT_TAG)
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
	addPart(room, "WallNorth", Vector3.new(84, WALL_HEIGHT, 2), Vector3.new(0, wallY, -111), wallColor, Enum.Material.Brick)
	addPart(room, "WallSouth", Vector3.new(84, WALL_HEIGHT, 2), Vector3.new(0, wallY, 11), wallColor, Enum.Material.Brick)
	addPart(room, "WallWest", Vector3.new(2, WALL_HEIGHT, 120), Vector3.new(-41, wallY, -50), wallColor, Enum.Material.Brick)
	addPart(room, "WallEast", Vector3.new(2, WALL_HEIGHT, 120), Vector3.new(41, wallY, -50), wallColor, Enum.Material.Brick)

	-- Stage with curtains at the far end.
	addPart(room, "Stage", Vector3.new(60, 3, 22), Vector3.new(0, 1.5, -98), WOOD, Enum.Material.WoodPlanks)
	local velvet = Color3.fromRGB(90, 10, 20)
	addPart(room, "CurtainLeft", Vector3.new(14, 18, 1), Vector3.new(-23, 12, -88), velvet, Enum.Material.Fabric)
	addPart(room, "CurtainRight", Vector3.new(14, 18, 1), Vector3.new(23, 12, -88), velvet, Enum.Material.Fabric)

	-- Prop crates to hide behind.
	local crateColor = Color3.fromRGB(100, 75, 45)
	for _, position in { Vector3.new(-25, 2.5, -20), Vector3.new(18, 2.5, -35), Vector3.new(-10, 2.5, -55), Vector3.new(28, 2.5, -65), Vector3.new(-30, 2.5, -70), Vector3.new(5, 2.5, -75) } do
		addPart(room, "Crate", Vector3.new(5, 5, 5), position, crateColor, Enum.Material.Wood)
	end

	for _, position in { Vector3.new(-39, 10, -20), Vector3.new(39, 10, -50), Vector3.new(-39, 10, -80), Vector3.new(0, 15, -109) } do
		addEmergencyLight(room, position)
	end

	-- Patrol points stay in the far two thirds so a new player does not spawn next to the entity.
	for _, position in { Vector3.new(-30, 1, -40), Vector3.new(30, 1, -45), Vector3.new(0, 1, -60), Vector3.new(-25, 1, -85), Vector3.new(25, 1, -82), Vector3.new(0, 1, -30) } do
		addPatrolPoint(room, position)
	end

	room.Parent = workspace
	setDarkLighting()
end

return DemoRoomService
