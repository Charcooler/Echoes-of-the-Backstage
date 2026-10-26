--!strict
-- Animates the entity's skeleton on each client: a long-legged walk with swinging arms, a hunched sprint while
-- hunting, and breathing plus sudden listening head-snaps while it stands still.
-- Reads the "Rigged", "State" and "Moving" attributes EntityService sets on the Entity model. Bones are driven
-- through Bone.Transform, which is local to each client, so the animation costs no network traffic.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage.Shared.Config)

local EntityAnimationController = {}

-- Rotations are written in the body mesh's own axes (+Z forward, +Y up, X sideways) and converted to each
-- bone's local axes, because the imported bones all point in different directions.
-- pitch > 0 tips the top of an upright bone forward (and swings the far end of a hanging limb backward).
local function meshRotation(pitch: number, yaw: number, roll: number): CFrame
	return CFrame.fromAxisAngle(Vector3.xAxis, math.rad(pitch))
		* CFrame.fromAxisAngle(Vector3.yAxis, math.rad(yaw))
		* CFrame.fromAxisAngle(Vector3.zAxis, math.rad(roll))
end

local function animate(model: Model, body: BasePart)
	local bones: { [string]: Bone } = {}
	local rest: { [string]: CFrame } = {} -- each bone's rotation relative to the body mesh, before any animation
	for _, descendant in body:GetDescendants() do
		if descendant:IsA("Bone") then
			bones[descendant.Name] = descendant
			rest[descendant.Name] = body.CFrame:ToObjectSpace(descendant.WorldCFrame).Rotation
		end
	end
	if not bones.Hips then
		return
	end

	local phase = 0
	local connection: RBXScriptConnection
	connection = RunService.RenderStepped:Connect(function(dt)
		if not model.Parent then
			connection:Disconnect()
			return
		end
		local now = os.clock()
		local hunting = model:GetAttribute("State") == "Hunt"
		local pose: { [string]: CFrame } = {}

		if model:GetAttribute("Moving") then
			local speed = if hunting then Config.ENTITY.HUNT_SPEED else Config.ENTITY.PATROL_SPEED
			phase += dt * (1.5 + speed * 0.18)
			local stride = math.sin(phase)
			local legSwing = if hunting then 38 else 26
			local armSwing = if hunting then 34 else 18
			local knee = if hunting then 55 else 35
			-- Limbs: negative pitch swings the foot/hand forward. Knees bend most while the leg comes forward.
			pose["UpperLeg.R"] = meshRotation(-stride * legSwing, 0, 0)
			pose["UpperLeg.L"] = meshRotation(stride * legSwing, 0, 0)
			pose["LowerLeg.R"] = meshRotation(math.max(0, math.cos(phase)) * knee, 0, 0)
			pose["LowerLeg.L"] = meshRotation(math.max(0, -math.cos(phase)) * knee, 0, 0)
			pose["UpperArm.R"] = meshRotation(stride * armSwing, 0, 0)
			pose["UpperArm.L"] = meshRotation(-stride * armSwing, 0, 0)
			-- Forearms lag behind the upper arms, so the long arms look loose and heavy.
			pose["LowerArm.R"] = meshRotation(math.sin(phase - 0.6) * armSwing * 0.6 - 10, 0, 0)
			pose["LowerArm.L"] = meshRotation(-math.sin(phase - 0.6) * armSwing * 0.6 - 10, 0, 0)
			pose["Hips"] = meshRotation(0, stride * 6, stride * 3)
			pose["Spine"] = meshRotation(if hunting then 22 else 6, -stride * 4, -stride * 3)
			pose["Chest"] = meshRotation(if hunting then 12 else 3, 0, 0)
			pose["Head"] = meshRotation((if hunting then -12 else 0) + math.abs(stride) * 5, 0, 0)
		else
			phase = 0
			local breath = math.sin(now * 1.6)
			pose["Spine"] = meshRotation(5, 0, 0)
			pose["Chest"] = meshRotation(4 + breath * 2, 0, 0)
			pose["UpperArm.R"] = meshRotation(-breath * 2, 0, 0)
			pose["UpperArm.L"] = meshRotation(-breath * 2, 0, 0)
			-- Now and then it snaps its horn to one side and holds it, as if listening for you.
			local listen = math.noise(now * 0.7, 3.1)
			local snap = if listen > 0.3 then 1 elseif listen < -0.3 then -1 else 0
			pose["Head"] = meshRotation(8, snap * 30, snap * 18)
		end

		for name, bone in bones do
			local rotation = pose[name]
			bone.Transform = if rotation then rest[name]:Inverse() * rotation * rest[name] else CFrame.identity
		end
	end)
end

local function onEntity(model: Model)
	-- Body and bones replicate after the model itself.
	local body = model:WaitForChild("Body", 10)
	if not (body and body:IsA("BasePart") and model:GetAttribute("Rigged")) then
		return -- primitive body: EntityService animates it as a whole
	end
	body:WaitForChild("Root", 10)
	animate(model, body)
end

function EntityAnimationController.init()
	workspace.ChildAdded:Connect(function(child)
		if child.Name == "Entity" and child:IsA("Model") then
			task.spawn(onEntity, child)
		end
	end)
	local existing = workspace:FindFirstChild("Entity")
	if existing and existing:IsA("Model") then
		task.spawn(onEntity, existing)
	end
end

return EntityAnimationController
