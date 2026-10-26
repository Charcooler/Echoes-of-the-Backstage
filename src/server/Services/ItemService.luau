--!strict
-- Throwable bottles: pick one up at a bottle spawn, throw it with ThrowEvent, and it shatters loudly where it lands,
-- pulling the entity away from you. The client only sends the direction it aims; the server checks that the player
-- holds a bottle, simulates the throw from the player's head and decides where it lands.
-- The player attribute HasBottle tells the clients who carries one. RoundService calls reset() each round.

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage.Shared.Config)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local NoiseService = require(script.Parent.NoiseService)

local SETTINGS = Config.THROW
-- shortcut: built-in thud that ships with Roblox; swap for a real glass-break sound asset.
local SHATTER_SOUND = "rbxasset://sounds/action_jump_land.mp3"

local ItemService = {}

local lastThrow: { [Player]: number } = {}
local worldBottles: { Instance } = {}

local function makeBottle(): Part
	local bottle = Instance.new("Part")
	bottle.Name = "Bottle"
	bottle.Shape = Enum.PartType.Cylinder
	bottle.Size = Vector3.new(1.1, 0.45, 0.45)
	bottle.Color = Color3.fromRGB(40, 110, 60)
	bottle.Material = Enum.Material.Glass
	bottle.Transparency = 0.2
	bottle.Anchored = true
	bottle.CanCollide = false
	bottle.CanQuery = false
	return bottle
end

local function aliveCharacter(player: Player): (Model?, BasePart?)
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local head = character and character:FindFirstChild("Head")
	if humanoid and humanoid.Health > 0 and head and head:IsA("BasePart") then
		return character, head
	end
	return nil, nil
end

local function spawnBottle(spawnPoint: BasePart)
	local bottle = makeBottle()
	bottle.CFrame = CFrame.new(spawnPoint.Position) * CFrame.Angles(0, 0, math.rad(90)) -- standing upright
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Pick up"
	prompt.ObjectText = "Bottle"
	prompt.MaxActivationDistance = 7
	prompt.RequiresLineOfSight = false
	prompt.Parent = bottle
	prompt.Triggered:Connect(function(player)
		local _, head = aliveCharacter(player)
		if not bottle.Parent or player:GetAttribute("HasBottle") or not head then
			return
		end
		if (head.Position - bottle.Position).Magnitude > prompt.MaxActivationDistance + 3 then
			return
		end
		player:SetAttribute("HasBottle", true)
		bottle:Destroy()
	end)
	bottle.Parent = workspace
	table.insert(worldBottles, bottle)
end

local function shatter(bottle: Part)
	local sound = Instance.new("Sound")
	sound.SoundId = SHATTER_SOUND
	sound.Volume = 2
	sound.PlaybackSpeed = 1.6 -- higher pitch reads more like glass
	sound.RollOffMaxDistance = 120
	sound.PlayOnRemove = true -- plays at the bottle's position as it is destroyed
	sound.Parent = bottle
	NoiseService.emit(bottle.Position, SETTINGS.NOISE, "Bottle")
	bottle:Destroy()
end

-- Flies a bottle along an arc from `from` to `to`, then shatters it.
local function fly(from: Vector3, to: Vector3)
	local bottle = makeBottle()
	bottle.CFrame = CFrame.new(from)
	bottle.Parent = workspace
	local distance = (to - from).Magnitude
	local duration = math.clamp(distance / 45, 0.25, 1)
	local height = math.min(distance * 0.25, 8)
	local start = os.clock()
	local connection: RBXScriptConnection
	connection = RunService.Heartbeat:Connect(function()
		local t = math.min((os.clock() - start) / duration, 1)
		local position = from:Lerp(to, t) + Vector3.new(0, height * 4 * t * (1 - t), 0)
		bottle.CFrame = CFrame.new(position) * CFrame.Angles(t * 12, 0, t * 7)
		if t >= 1 then
			connection:Disconnect()
			shatter(bottle)
		end
	end)
end

local function onThrow(player: Player, direction: unknown)
	-- A finite, roughly unit-length Vector3 (NaN fails every comparison, so it is rejected here too).
	if typeof(direction) ~= "Vector3" or not (direction.Magnitude > 0.5 and direction.Magnitude < 1.5) then
		return
	end
	if not player:GetAttribute("HasBottle") then
		return
	end
	local now = os.clock()
	if now - (lastThrow[player] or 0) < SETTINGS.COOLDOWN then
		return
	end
	local character, head = aliveCharacter(player)
	if not (character and head) then
		return
	end
	lastThrow[player] = now
	player:SetAttribute("HasBottle", false)

	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { character }
	local aim = direction.Unit * SETTINGS.RANGE
	local hit = workspace:Raycast(head.Position, aim, params)
	local landing = if hit then hit.Position else head.Position + aim
	if not hit then
		local ground = workspace:Raycast(landing, Vector3.new(0, -60, 0), params)
		if ground then
			landing = ground.Position
		end
	end
	fly(head.Position, landing)
end

function ItemService.reset()
	for _, bottle in worldBottles do
		bottle:Destroy()
	end
	table.clear(worldBottles)
	for _, player in Players:GetPlayers() do
		player:SetAttribute("HasBottle", false)
	end
	for _, spawnPoint in CollectionService:GetTagged(Config.BOTTLE_SPAWN_TAG) do
		if spawnPoint:IsA("BasePart") then
			spawnBottle(spawnPoint)
		end
	end
end

function ItemService.init()
	local throwEvent = Remotes.getEvent("ThrowEvent") :: RemoteEvent
	throwEvent.OnServerEvent:Connect(onThrow)
	Players.PlayerRemoving:Connect(function(player)
		lastThrow[player] = nil
	end)
end

return ItemService
