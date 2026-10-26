--!strict
-- Receives noise events from clients and turns them into a noise level and a world position.
-- The client only reports the noise type and its stance; level and position are decided here.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Remotes = require(ReplicatedStorage.Shared.Remotes)

local NoiseService = {}

export type NoiseListener = (level: number, position: Vector3, source: string) -> ()

local lastEventTime: { [Player]: number } = {}
local listeners: { NoiseListener } = {}

-- Lets other services (e.g. EntityService) react to noise without NoiseService knowing about them.
function NoiseService.onNoise(listener: NoiseListener)
	table.insert(listeners, listener)
end

-- Noise made on the server (footsteps after validation, repairs, shattered bottles).
function NoiseService.emit(position: Vector3, level: number, source: string)
	for _, listener in listeners do
		task.spawn(listener, level, position, source)
	end
end

-- A client can claim to crouch while running, so the speed the server sees sets a minimum stance.
local function resolveStance(claimed: string, speed: number): string
	local stances = Config.STANCES
	local tolerance = Config.NOISE_SPEED_TOLERANCE
	local implied = if speed > stances.Walk.WALK_SPEED + tolerance
		then "Sprint"
		elseif speed > stances.Crouch.WALK_SPEED + tolerance then "Walk"
		else "Crouch"
	return if stances[implied].NOISE > stances[claimed].NOISE then implied else claimed
end

local function onNoiseEvent(player: Player, noiseType: unknown, stance: unknown)
	if typeof(noiseType) ~= "string" or not Config.NOISE_TYPES[noiseType] then
		return
	end
	if typeof(stance) ~= "string" or not Config.STANCES[stance] then
		return
	end

	local now = os.clock()
	if now - (lastEventTime[player] or 0) < Config.NOISE_EVENT_MIN_INTERVAL then
		return
	end
	lastEventTime[player] = now

	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not (root and root:IsA("BasePart") and humanoid and humanoid.Health > 0) then
		return
	end

	local velocity = root.AssemblyLinearVelocity
	local speed = Vector3.new(velocity.X, 0, velocity.Z).Magnitude
	local finalStance = resolveStance(stance, speed)
	local level = Config.STANCES[finalStance].NOISE
	local pos = root.Position

	print(
		`[NoiseService] {player.Name} {noiseType} stance={finalStance} (claimed {stance}) level={level} `
			.. `pos=({math.round(pos.X)}, {math.round(pos.Y)}, {math.round(pos.Z)}) speed={math.round(speed)}`
	)
	NoiseService.emit(pos, level, `{player.Name} {noiseType}`)
end

function NoiseService.init()
	local noiseEvent = Remotes.getEvent("NoiseEvent") :: RemoteEvent
	noiseEvent.OnServerEvent:Connect(onNoiseEvent)
	Players.PlayerRemoving:Connect(function(player)
		lastEventTime[player] = nil
	end)
end

return NoiseService
