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
local FOOTSTEP_SOUND = "rbxasset://sounds/action_footsteps_plastic.mp3" -- ships with Roblox, no upload needed
-- shortcut: fixed height and straight-line movement through props, switch to PathfindingService once the map has walls between rooms or several floors.
local HEIGHT = EntityModel.ROOT_HEIGHT
local GLIMPSE_TIME = 1.5 -- seconds the body shows after a catch

type State = "Patrol" | "Investigate" | "Hunt"

local EntityService = {}

local model: Model
local body: Part -- the model's anchored Root; moving it moves the whole body
local groundPosition = Vector3.zero -- where the entity really is; body adds the lurching gait on top
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

local function step(dt: number)
	catchNearbyPlayers()

	local goal = target
	if not goal then
		footsteps.Playing = false
		if os.clock() < lingerUntil then
			return
		end
		setState("Patrol", pickPatrolTarget())
		return
	end

	local offset = Vector3.new(goal.X, HEIGHT, goal.Z) - groundPosition
	local distance = offset.Magnitude
	if distance < 0.5 then
		-- Arrived: stand still and listen, longer after a noise than between patrol points.
		target = nil
		lingerUntil = os.clock() + (if state == "Patrol" then 1 else SETTINGS.LINGER_TIME)
		return
	end

	local direction = offset.Unit
	local speed = speedFor(state)
	groundPosition += direction * math.min(speed * dt, distance)
	-- Lurching gait: bob and sway in step with the speed, on top of the smooth ground path.
	local gait = os.clock() * speed * 0.6
	body.CFrame = CFrame.lookAt(groundPosition, groundPosition + direction)
		* CFrame.new(0, math.abs(math.sin(gait)) * 0.4, 0)
		* CFrame.Angles(0, 0, math.sin(gait) * 0.08)
	footsteps.PlaybackSpeed = if state == "Hunt" then 1.3 elseif state == "Investigate" then 1 else 0.7
	footsteps.Playing = true
end

local function onNoise(_player: Player, level: number, position: Vector3)
	if not model.Parent or level <= 0 or (position - groundPosition).Magnitude > level then
		return
	end
	-- A hunt follows the newest sound instead of calming down to Investigate.
	local newState: State = if level >= SETTINGS.HUNT_NOISE or state == "Hunt" then "Hunt" else "Investigate"
	setState(newState, position)
end

function EntityService.init()
	model, body = EntityModel.build()
	EntityModel.setVisible(model, SETTINGS.DEBUG_VISIBLE)

	footsteps = Instance.new("Sound")
	footsteps.Name = "Footsteps"
	footsteps.SoundId = FOOTSTEP_SOUND
	footsteps.Looped = true
	footsteps.RollOffMinDistance = 8
	footsteps.RollOffMaxDistance = 90
	footsteps.Parent = body

	NoiseService.onNoise(onNoise)

	-- The map may be built by another service after this one, so wait for patrol points before spawning.
	task.spawn(function()
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
