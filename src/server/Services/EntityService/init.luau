--!strict
-- The invisible entity. Patrols between tagged points, investigates noise it hears and hunts loud noise.
-- Players only notice it through its 3D footsteps, and glimpse its body (EntityModel) when it catches them.
-- Touching it (CATCH_RANGE) kills the player.

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage.Shared.Config)
local NoiseService = require(script.Parent.NoiseService)
local EntityModel = require(script.EntityModel)

local SETTINGS = Config.ENTITY
-- shortcut: fixed height and straight-line movement through props, switch to PathfindingService once the map has walls between rooms or several floors.
local HEIGHT = EntityModel.ROOT_HEIGHT
local GLIMPSE_TIME = 1.5 -- seconds the body shows after a catch

type State = "Patrol" | "Investigate" | "Hunt"

local EntityService = {}

local model: Model
local body: Part -- the model's anchored Root; moving it moves the whole body
local groundPosition = Vector3.zero -- where the entity really is; body adds the animation pose on top
local facing = Vector3.new(0, 0, -1)
local footsteps: Sound
local state: State = "Patrol"
local target: Vector3? = nil
local lingerUntil = 0

local function setState(newState: State, newTarget: Vector3?)
	if newState ~= state then
		print(`[EntityService] {state} -> {newState}`)
	end
	state = newState
	target = newTarget
	lingerUntil = 0
end

local function pickPatrolTarget(): Vector3?
	local points = CollectionService:GetTagged(Config.PATROL_POINT_TAG)
	if #points == 0 then
		return nil
	end
	local point = points[math.random(#points)]
	return if point:IsA("BasePart") then point.Position else nil
end

local function speedFor(s: State): number
	if s == "Hunt" then
		return SETTINGS.HUNT_SPEED
	end
	return if s == "Investigate" then SETTINGS.INVESTIGATE_SPEED else SETTINGS.PATROL_SPEED
end

local function catchNearbyPlayers()
	for _, player in Players:GetPlayers() do
		local character = player.Character
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		local root = character and character:FindFirstChild("HumanoidRootPart")
		if humanoid and humanoid.Health > 0 and root and root:IsA("BasePart") then
			if (root.Position - body.Position).Magnitude <= SETTINGS.CATCH_RANGE then
				print(`[EntityService] caught {player.Name}`)
				humanoid.Health = 0
				if not SETTINGS.DEBUG_VISIBLE then
					EntityModel.setVisible(model, true)
					task.delay(GLIMPSE_TIME, EntityModel.setVisible, model, false)
				end
				setState("Patrol", nil)
				lingerUntil = os.clock() + SETTINGS.LINGER_TIME
			end
		end
	end
end

-- Rotation around the feet instead of the body's center, so leaning tips the top and keeps the feet planted.
local function aroundFeet(rotation: CFrame): CFrame
	return CFrame.new(0, -HEIGHT, 0) * rotation * CFrame.new(0, HEIGHT, 0)
end

-- shortcut: the generated mesh has no rig, so the whole body is animated (gait, lean, breathing, twitches);
-- rig it (Blender or Studio's auto-rig) for real limb animation.
local function pose(moving: boolean, speed: number): CFrame
	if model:GetAttribute("Rigged") then
		return CFrame.identity -- the clients animate the skeleton (EntityAnimationController)
	end
	local now = os.clock()
	if moving then
		local gait = now * speed * 0.6
		local lean = math.rad(if state == "Hunt" then -16 else -4)
		return CFrame.new(0, math.abs(math.sin(gait)) * 0.4, 0) * aroundFeet(CFrame.Angles(lean, 0, math.sin(gait) * 0.08))
	end
	local breath = math.sin(now * 1.6) * 0.06
	-- Now and then it snaps its head to one side and holds it, as if listening for you.
	local twitch = if math.noise(now * 0.7, 3.1) > 0.3 then math.rad(12) else 0
	return CFrame.new(0, breath, 0) * aroundFeet(CFrame.Angles(math.rad(-6), twitch, twitch * 0.5))
end

local function step(dt: number)
	catchNearbyPlayers()

	local moving = false
	local goal = target
	if goal then
		local offset = Vector3.new(goal.X, HEIGHT, goal.Z) - groundPosition
		local distance = offset.Magnitude
		if distance < 0.5 then
			-- Arrived: stand still and listen, longer after a noise than between patrol points.
			target = nil
			lingerUntil = os.clock() + (if state == "Patrol" then 1 else SETTINGS.LINGER_TIME)
		else
			facing = offset.Unit
			groundPosition += facing * math.min(speedFor(state) * dt, distance)
			moving = true
		end
	elseif os.clock() >= lingerUntil then
		setState("Patrol", pickPatrolTarget())
	end

	body.CFrame = CFrame.lookAt(groundPosition, groundPosition + facing) * pose(moving, speedFor(state))
	-- Attributes only replicate when they change, so setting them every frame is cheap.
	model:SetAttribute("State", state)
	model:SetAttribute("Moving", moving)
	footsteps.PlaybackSpeed = if state == "Hunt" then 1.3 elseif state == "Investigate" then 1 else 0.7
	footsteps.Playing = moving
end

local function onNoise(level: number, position: Vector3, _source: string)
	if not (model and model.Parent) or level <= 0 or (position - groundPosition).Magnitude > level then
		return
	end
	-- A hunt follows the newest sound instead of calming down to Investigate.
	local newState: State = if level >= SETTINGS.HUNT_NOISE or state == "Hunt" then "Hunt" else "Investigate"
	setState(newState, position)
end

-- New round: back to a random patrol point, calm. Before the body has spawned there is nothing to reset.
function EntityService.reset()
	local point = pickPatrolTarget()
	if model and point then
		groundPosition = Vector3.new(point.X, HEIGHT, point.Z)
	end
	setState("Patrol", nil)
	lingerUntil = os.clock() + 2
end

function EntityService.init()
	NoiseService.onNoise(onNoise)

	-- Spawned because loading the mesh yields, and the map may be built by another service after this one.
	task.spawn(function()
		model, body = EntityModel.build()
		EntityModel.setVisible(model, SETTINGS.DEBUG_VISIBLE)

		footsteps = Instance.new("Sound")
		footsteps.Name = "Footsteps"
		footsteps.SoundId = Config.SOUNDS.ENTITY_STEPS
		footsteps.Looped = true
		footsteps.Volume = 1.5
		footsteps.RollOffMinDistance = 8
		footsteps.RollOffMaxDistance = 90
		footsteps.Parent = body

		-- Always breathing, but only audible up close: the warning that it is right next to you.
		local breath = Instance.new("Sound")
		breath.Name = "Breath"
		breath.SoundId = Config.SOUNDS.ENTITY_BREATH
		breath.Looped = true
		breath.Volume = 1.2
		breath.RollOffMinDistance = 4
		breath.RollOffMaxDistance = 30
		breath.Parent = body
		breath:Play()

		local spawnAt = pickPatrolTarget()
		while not spawnAt do
			task.wait(0.5)
			spawnAt = pickPatrolTarget()
		end
		-- shortcut: the body's position replicates, so exploiters can see where it is; hide it server-side if that matters.
		groundPosition = Vector3.new(spawnAt.X, HEIGHT, spawnAt.Z)
		model:PivotTo(CFrame.new(groundPosition))
		model.Parent = workspace
		RunService.Heartbeat:Connect(step)
	end)
end

return EntityService
