--!strict
-- The invisible entity. Patrols between tagged points, investigates noise it hears and hunts loud noise.
-- Players only notice it through its 3D footsteps. Touching it (CATCH_RANGE) kills the player.

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage.Shared.Config)
local NoiseService = require(script.Parent.NoiseService)

local SETTINGS = Config.ENTITY
local FOOTSTEP_SOUND = "rbxasset://sounds/action_footsteps_plastic.mp3" -- ships with Roblox, no upload needed
-- shortcut: fixed height and straight-line movement through props, switch to PathfindingService once the map has walls between rooms or several floors.
local HEIGHT = 3

type State = "Patrol" | "Investigate" | "Hunt"

local EntityService = {}

local body: Part
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

	local offset = Vector3.new(goal.X, HEIGHT, goal.Z) - body.Position
	local distance = offset.Magnitude
	if distance < 0.5 then
		-- Arrived: stand still and listen, longer after a noise than between patrol points.
		target = nil
		lingerUntil = os.clock() + (if state == "Patrol" then 1 else SETTINGS.LINGER_TIME)
		return
	end

	local direction = offset.Unit
	local position = body.Position + direction * math.min(speedFor(state) * dt, distance)
	body.CFrame = CFrame.lookAt(position, position + direction)
	footsteps.PlaybackSpeed = if state == "Hunt" then 1.3 elseif state == "Investigate" then 1 else 0.7
	footsteps.Playing = true
end

local function onNoise(_player: Player, level: number, position: Vector3)
	if not body.Parent or level <= 0 or (position - body.Position).Magnitude > level then
		return
	end
	-- A hunt follows the newest sound instead of calming down to Investigate.
	local newState: State = if level >= SETTINGS.HUNT_NOISE or state == "Hunt" then "Hunt" else "Investigate"
	setState(newState, position)
end

local function createBody(): Part
	local part = Instance.new("Part")
	part.Name = "Entity"
	part.Size = Vector3.new(3, 6, 2)
	part.Color = Color3.fromRGB(255, 40, 40)
	part.Transparency = if SETTINGS.DEBUG_VISIBLE then 0.75 else 1
	part.Anchored = true
	part.CanCollide = false
	part.CanTouch = false
	part.CanQuery = false
	part.CastShadow = false

	footsteps = Instance.new("Sound")
	footsteps.Name = "Footsteps"
	footsteps.SoundId = FOOTSTEP_SOUND
	footsteps.Looped = true
	footsteps.RollOffMinDistance = 8
	footsteps.RollOffMaxDistance = 90
	footsteps.Parent = part
	return part
end

function EntityService.init()
	body = createBody()
	NoiseService.onNoise(onNoise)

	-- The map may be built by another service after this one, so wait for patrol points before spawning.
	task.spawn(function()
		local spawnAt = pickPatrolTarget()
		while not spawnAt do
			task.wait(0.5)
			spawnAt = pickPatrolTarget()
		end
		-- shortcut: the part's position replicates, so exploiters can see where it is; hide it server-side if that matters.
		body.Position = Vector3.new(spawnAt.X, HEIGHT, spawnAt.Z)
		body.Parent = workspace
		RunService.Heartbeat:Connect(step)
	end)
end

return EntityService
