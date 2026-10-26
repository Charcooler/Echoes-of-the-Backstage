--!strict
-- Builds the entity's body: «The Stagehand», a tall, hunched stagehand with arms that reach the floor,
-- ropes and a sandbag hanging off it, and a tarnished gramophone horn for a head (sound is all it is).
-- Every part is welded to an anchored Root, so moving Root.CFrame moves the whole body.

local EntityModel = {}

-- Root sits this high above the floor; the feet touch Y = 0.
EntityModel.ROOT_HEIGHT = 4.5

local SOOT = Color3.fromRGB(24, 21, 21)
local CLOTH = Color3.fromRGB(46, 41, 36)
local LEATHER = Color3.fromRGB(70, 52, 36)
local SKIN = Color3.fromRGB(112, 106, 96)
local BRASS = Color3.fromRGB(138, 104, 44)
local ROPE = Color3.fromRGB(122, 101, 70)
local THROAT = Color3.fromRGB(150, 0, 10)

local function lean(degrees: number): CFrame
	-- Negative degrees tip the top of a part forward (towards -Z, where the entity faces).
	return CFrame.Angles(math.rad(degrees), 0, 0)
end

function EntityModel.build(): (Model, Part)
	local model = Instance.new("Model")
	model.Name = "Entity"

	local root = Instance.new("Part")
	root.Name = "Root"
	root.Size = Vector3.new(2, 2, 2)
	root.CFrame = CFrame.new(0, EntityModel.ROOT_HEIGHT, 0)
	root.Transparency = 1
	root.Anchored = true
	root.CanCollide = false
	root.CanTouch = false
	root.CanQuery = false
	root.Parent = model
	model.PrimaryPart = root

	local function add(name: string, size: Vector3, cframe: CFrame, color: Color3, material: Enum.Material, shape: Enum.PartType?)
		local part = Instance.new("Part")
		part.Name = name
		part.Size = size
		part.CFrame = cframe
		part.Color = color
		part.Material = material
		part.Shape = shape or Enum.PartType.Block
		part.CanCollide = false
		part.CanTouch = false
		part.CanQuery = false
		local weld = Instance.new("WeldConstraint")
		weld.Part0 = root
		weld.Part1 = part
		weld.Parent = part
		part.Parent = model
	end

	-- Legs and boots.
	for _, x in { -0.6, 0.6 } do
		add("Leg", Vector3.new(0.7, 4.2, 0.7), CFrame.new(x, 2.3, 0), CLOTH, Enum.Material.Fabric)
		add("Boot", Vector3.new(0.9, 0.5, 1.3), CFrame.new(x, 0.25, -0.2), SOOT, Enum.Material.Leather)
	end

	-- Hunched torso, hump, leather apron and shoulders.
	add("Torso", Vector3.new(2.2, 3, 1.2), CFrame.new(0, 5.6, -0.3) * lean(-20), CLOTH, Enum.Material.Fabric)
	add("Hump", Vector3.new(1.7, 1.7, 1.7), CFrame.new(0, 6.6, 0.3), CLOTH, Enum.Material.Fabric, Enum.PartType.Ball)
	add("Apron", Vector3.new(1.8, 2.6, 0.1), CFrame.new(0, 4.6, -0.95) * lean(-10), LEATHER, Enum.Material.Leather)
	add("Shoulders", Vector3.new(3, 0.6, 1), CFrame.new(0, 6.9, -0.7), SOOT, Enum.Material.Fabric)

	-- Arms long enough to drag the fingers along the floor.
	for _, x in { -1.7, 1.7 } do
		add("UpperArm", Vector3.new(0.5, 3, 0.5), CFrame.new(x, 5.5, -0.9) * lean(-15), CLOTH, Enum.Material.Fabric)
		add("Forearm", Vector3.new(0.45, 3, 0.45), CFrame.new(x * 1.05, 2.8, -1.4) * lean(-10), SKIN, Enum.Material.SmoothPlastic)
		add("Hand", Vector3.new(0.6, 1.3, 0.3), CFrame.new(x * 1.05, 0.9, -1.6), SKIN, Enum.Material.SmoothPlastic)
	end

	-- Stage rigging tangled on its back: two ropes and a sandbag.
	add("Rope", Vector3.new(0.15, 3.6, 0.15), CFrame.new(0.9, 5.4, 0.65) * CFrame.Angles(0, 0, math.rad(8)), ROPE, Enum.Material.Fabric)
	add("Rope", Vector3.new(0.15, 4.2, 0.15), CFrame.new(-0.5, 5.0, 0.7) * CFrame.Angles(0, 0, math.rad(-5)), ROPE, Enum.Material.Fabric)
	add("Sandbag", Vector3.new(0.8, 1, 0.6), CFrame.new(1.05, 3.4, 0.65), Color3.fromRGB(105, 90, 62), Enum.Material.Fabric)

	-- Neck and gramophone horn head, flaring forward and slightly down.
	add("Neck", Vector3.new(0.4, 1, 0.4), CFrame.new(0, 7.5, -1) * lean(-30), SKIN, Enum.Material.SmoothPlastic)
	local horn = CFrame.new(0, 8, -1.2) * lean(-15)
	local alongHorn = CFrame.Angles(0, math.rad(90), 0) -- a cylinder's length runs along its X axis
	for _, segment in { { 0.3, 0.6, 0.5 }, { 0.75, 0.4, 1 }, { 1.1, 0.35, 1.6 }, { 1.4, 0.3, 2.4 }, { 1.6, 0.2, 3.2 } } do
		local distance, length, diameter = segment[1], segment[2], segment[3]
		add("Horn", Vector3.new(length, diameter, diameter), horn * CFrame.new(0, 0, -distance) * alongHorn, BRASS, Enum.Material.Metal, Enum.PartType.Cylinder)
	end
	add("HornMouth", Vector3.new(0.05, 2.8, 2.8), horn * CFrame.new(0, 0, -1.72) * alongHorn, SOOT, Enum.Material.SmoothPlastic, Enum.PartType.Cylinder)
	add("Throat", Vector3.new(0.06, 0.45, 0.45), horn * CFrame.new(0, 0, -1.76) * alongHorn, THROAT, Enum.Material.Neon, Enum.PartType.Cylinder)

	return model, root
end

-- Shows or hides every part except the always-invisible Root.
function EntityModel.setVisible(model: Model, visible: boolean)
	for _, part in model:GetDescendants() do
		if part:IsA("BasePart") and part ~= model.PrimaryPart then
			part.Transparency = if visible then 0 else 1
		end
	end
end

return EntityModel
