--!strict
-- Runs the round: everyone spawns, repairs the fuse boxes and escapes through the exit while the entity hunts.
-- A player's round is over when they escape or get caught (no respawn); when everyone is done, the result shows
-- for RESULT_TIME seconds and a new round starts.
-- Publishes RoundState ("Playing"/"Ended") and NextRoundAt as workspace attributes, and Outcome
-- ("Escaped"/"Caught") as a player attribute.

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local EntityService = require(script.Parent.EntityService)
local ItemService = require(script.Parent.ItemService)
local ObjectiveService = require(script.Parent.ObjectiveService)

local RoundService = {}

local function isInside(zone: BasePart, position: Vector3): boolean
	local offset = zone.CFrame:PointToObjectSpace(position)
	local half = zone.Size / 2
	return math.abs(offset.X) <= half.X and math.abs(offset.Y) <= half.Y and math.abs(offset.Z) <= half.Z
end

local function spawnPlayer(player: Player)
	player:SetAttribute("Outcome", nil)
	player:LoadCharacter()
end

local function setupPlayer(player: Player)
	player.CharacterAdded:Connect(function(character)
		local humanoid = character:WaitForChild("Humanoid") :: Humanoid
		humanoid.Died:Connect(function()
			if player:GetAttribute("Outcome") == nil then
				player:SetAttribute("Outcome", "Caught")
				print(`[RoundService] {player.Name} was caught`)
			end
		end)
	end)
	-- Late joiners play the current round; during the result screen they wait for the next one.
	if workspace:GetAttribute("RoundState") == "Playing" then
		spawnPlayer(player)
	end
end

local function checkEscapes()
	if not workspace:GetAttribute("ExitOpen") then
		return
	end
	local zones = CollectionService:GetTagged(Config.EXIT_ZONE_TAG)
	for _, player in Players:GetPlayers() do
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		if character and root and root:IsA("BasePart") and player:GetAttribute("Outcome") == nil then
			for _, zone in zones do
				if zone:IsA("BasePart") and isInside(zone, root.Position) then
					player:SetAttribute("Outcome", "Escaped")
					print(`[RoundService] {player.Name} escaped`)
					character:Destroy() -- out of the entity's reach; their camera stays at the exit
					break
				end
			end
		end
	end
end

local function everyoneDone(): boolean
	local players = Players:GetPlayers()
	if #players == 0 then
		return false
	end
	for _, player in players do
		if player:GetAttribute("Outcome") == nil then
			return false
		end
	end
	return true
end

local function startRound()
	ObjectiveService.reset()
	ItemService.reset()
	EntityService.reset()
	workspace:SetAttribute("RoundState", "Playing")
	for _, player in Players:GetPlayers() do
		task.spawn(spawnPlayer, player)
	end
	print("[RoundService] round started")
end

local function roundLoop()
	while true do
		startRound()
		repeat
			task.wait(0.25)
			checkEscapes()
		until everyoneDone()
		workspace:SetAttribute("RoundState", "Ended")
		workspace:SetAttribute("NextRoundAt", workspace:GetServerTimeNow() + Config.ROUND.RESULT_TIME)
		print("[RoundService] round over")
		task.wait(Config.ROUND.RESULT_TIME)
	end
end

function RoundService.init()
	Players.CharacterAutoLoads = false -- caught players stay out until the next round
	Players.PlayerAdded:Connect(setupPlayer)
	for _, player in Players:GetPlayers() do
		setupPlayer(player)
	end
	-- Deferred so every service (and the map) has finished init before the first round.
	task.defer(roundLoop)
end

return RoundService
