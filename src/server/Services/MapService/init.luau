--!strict
-- Builds the opera house from MapLayout, which art/map/export_map.py generates from art/map/opera_house.blend:
-- parts (with their CollectionService tags), lights, the player spawn and the start screen camera.
-- To change the map, edit the .blend in Blender and re-export; do not edit MapLayout by hand.

local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local MapLayout = require(script.MapLayout)

local MapService = {}

local function buildPart(data: { any }): BasePart
	local part = Instance.new(data[2]) :: BasePart
	part.Name = data[1]
	if part:IsA("Part") then
		part.Shape = (Enum.PartType :: any)[data[3]]
	end
	part.Material = (Enum.Material :: any)[data[4]]
	part.Color = Color3.new(data[5], data[6], data[7])
	part.Transparency = data[8]
	part.CanCollide = data[9]
	part.Size = Vector3.new(data[10], data[11], data[12])
	part.CFrame = CFrame.new(data[13], data[14], data[15], data[16], data[17], data[18], data[19], data[20], data[21], data[22], data[23], data[24])
	part.Anchored = true
	if not part.CanCollide then
		-- Cloth, glass, markers: nothing to stand on or bump into, and raycasts (thrown bottles) pass through.
		part.CanQuery = false
		part.CanTouch = false
		part.CastShadow = part.Transparency < 1
	end
	local tag = data[25]
	if tag ~= "" then
		part:AddTag(tag)
	end
	return part
end

local function buildLight(data: { any }, parent: Instance)
	-- Lights live in a tiny invisible part facing the light's direction, so spotlights shine out of its Front.
	local position = Vector3.new(data[2], data[3], data[4])
	local direction = Vector3.new(data[5], data[6], data[7])
	local holder = Instance.new("Part")
	holder.Name = "Light"
	holder.Size = Vector3.new(0.2, 0.2, 0.2)
	holder.Transparency = 1
	holder.Anchored = true
	holder.CanCollide = false
	holder.CanQuery = false
	holder.CanTouch = false
	holder.CFrame = CFrame.lookAt(position, position + direction)
	local light = Instance.new(data[1]) :: Light
	light.Color = Color3.new(data[8], data[9], data[10])
	light.Brightness = data[12]
	light.Shadows = true
	if light:IsA("PointLight") then
		light.Range = data[11]
	elseif light:IsA("SpotLight") then
		light.Range = data[11]
		light.Angle = data[13]
		light.Face = Enum.NormalId.Front
	end
	light.Parent = holder
	holder.Parent = parent
end

local function addExitSign(sign: BasePart)
	for _, face in { Enum.NormalId.Front, Enum.NormalId.Back, Enum.NormalId.Left, Enum.NormalId.Right } do
		local gui = Instance.new("SurfaceGui")
		gui.Face = face
		local label = Instance.new("TextLabel")
		label.Size = UDim2.fromScale(1, 1)
		label.BackgroundTransparency = 1
		label.Text = "EXIT"
		label.TextScaled = true
		label.FontFace = Font.fromEnum(Enum.Font.Bodoni)
		label.TextColor3 = Color3.new(1, 1, 1)
		label.Parent = gui
		gui.Parent = sign
	end
end

-- Players spawn on the marker tagged PlayerSpawn; any spawn the place itself has is switched off.
local function setupSpawn(marker: BasePart)
	for _, existing in workspace:GetDescendants() do
		if existing:IsA("SpawnLocation") then
			existing.Enabled = false
		end
	end
	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "PlayerSpawn"
	spawn.Size = marker.Size
	spawn.CFrame = marker.CFrame
	spawn.Transparency = 1
	spawn.Anchored = true
	spawn.Neutral = true
	spawn.Duration = 0 -- no force field: the entity is the point of the game
	spawn.Parent = marker.Parent
end

local function setDarkLighting()
	Lighting.ClockTime = 0
	Lighting.Brightness = 0
	Lighting.Ambient = Color3.fromRGB(18, 18, 24)
	Lighting.OutdoorAmbient = Color3.fromRGB(18, 18, 24)
	Lighting.EnvironmentDiffuseScale = 0
	Lighting.EnvironmentSpecularScale = 0
end

function MapService.init()
	local map = Instance.new("Model")
	map.Name = "Map"
	local spawnMarker: BasePart? = nil
	for _, data in MapLayout.parts do
		local part = buildPart(data)
		part.Parent = map
		if part.Name == "ExitSign" then
			addExitSign(part)
		elseif data[25] == Config.PLAYER_SPAWN_TAG then
			spawnMarker = part
		end
	end
	for _, data in MapLayout.lights do
		buildLight(data, map)
	end
	map.Parent = workspace

	if spawnMarker then
		setupSpawn(spawnMarker)
	end
	local camera = MapLayout.menuCamera
	if camera then
		workspace:SetAttribute("MenuCamera", CFrame.lookAt(Vector3.new(camera[1], camera[2], camera[3]), Vector3.new(camera[4], camera[5], camera[6])))
	end
	setDarkLighting()
end

return MapService
