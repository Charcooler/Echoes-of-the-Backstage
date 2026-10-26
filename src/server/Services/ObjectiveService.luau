--!strict
-- Fuse boxes the players repair to get the power back. Repairing is a long hold on a ProximityPrompt that makes
-- noise the entity can hear; when every box is fixed, the exit door opens.
-- Publishes FusesFixed, FusesTotal and ExitOpen as workspace attributes. RoundService calls reset() each round.

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local NoiseService = require(script.Parent.NoiseService)

local SETTINGS = Config.ROUND
local BROKEN_COLOR = Color3.fromRGB(255, 50, 30)
local FIXED_COLOR = Color3.fromRGB(80, 255, 120)

local ObjectiveService = {}

local fixed: { [BasePart]: boolean } = {}
local repairing: { [BasePart]: { [Player]: boolean } } = {}

local function fuseBoxes(): { BasePart }
	local boxes = {}
	for _, box in CollectionService:GetTagged(Config.FUSE_BOX_TAG) do
		if box:IsA("BasePart") then
			table.insert(boxes, box)
		end
	end
	return boxes
end

local function isNear(player: Player, position: Vector3, range: number): boolean
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	return root ~= nil and root:IsA("BasePart") and (root.Position - position).Magnitude <= range
end

local function setExitOpen(open: boolean)
	workspace:SetAttribute("ExitOpen", open)
	for _, door in CollectionService:GetTagged(Config.EXIT_DOOR_TAG) do
		if door:IsA("BasePart") then
			door.CanCollide = not open
			door.Transparency = if open then 1 else 0
		end
	end
end

local function updateProgress()
	local boxes = fuseBoxes()
	local done = 0
	for _, box in boxes do
		if fixed[box] then
			done += 1
		end
	end
	workspace:SetAttribute("FusesFixed", done)
	workspace:SetAttribute("FusesTotal", #boxes)
	if #boxes > 0 and done == #boxes and not workspace:GetAttribute("ExitOpen") then
		print("[ObjectiveService] all fuse boxes fixed, exit open")
		setExitOpen(true)
	end
end

local function getSound(box: BasePart, name: string, soundId: string, looped: boolean): Sound
	local existing = box:FindFirstChild(name)
	if existing and existing:IsA("Sound") then
		return existing
	end
	local sound = Instance.new("Sound")
	sound.Name = name
	sound.SoundId = soundId
	sound.Looped = looped
	sound.RollOffMaxDistance = 40
	sound.Parent = box
	return sound
end

local function setup(box: BasePart)
	local light = box:FindFirstChildOfClass("PointLight") or Instance.new("PointLight")
	light.Range = 10
	light.Brightness = 2
	light.Parent = box
	local repairSound = getSound(box, "RepairSound", Config.SOUNDS.REPAIR_LOOP, true)
	local fixedSound = getSound(box, "FixedSound", Config.SOUNDS.FUSE_FIXED, false)
	repairSound:Stop()

	-- The arcing sound plays while at least one player is working on the box.
	local function updateRepairSound()
		repairSound.Playing = next(repairing[box]) ~= nil
	end

	local prompt = box:FindFirstChildOfClass("ProximityPrompt")
	if not prompt then
		local newPrompt = Instance.new("ProximityPrompt")
		newPrompt.ActionText = "Repair"
		newPrompt.ObjectText = "Fuse box"
		newPrompt.HoldDuration = SETTINGS.REPAIR_TIME
		newPrompt.MaxActivationDistance = 8
		newPrompt.RequiresLineOfSight = false
		newPrompt.Parent = box
		newPrompt.PromptButtonHoldBegan:Connect(function(player)
			repairing[box][player] = true
			updateRepairSound()
		end)
		newPrompt.PromptButtonHoldEnded:Connect(function(player)
			repairing[box][player] = nil
			updateRepairSound()
		end)
		newPrompt.Triggered:Connect(function(player)
			repairing[box][player] = nil
			updateRepairSound()
			-- The engine checks the distance too, but the server never trusts the client.
			if fixed[box] or workspace:GetAttribute("RoundState") ~= "Playing" then
				return
			end
			if not isNear(player, box.Position, newPrompt.MaxActivationDistance + 2) then
				return
			end
			fixed[box] = true
			newPrompt.Enabled = false
			light.Color = FIXED_COLOR
			fixedSound:Play()
			print(`[ObjectiveService] {player.Name} fixed a fuse box`)
			updateProgress()
		end)
		prompt = newPrompt
	end
	(prompt :: ProximityPrompt).Enabled = true
	light.Color = BROKEN_COLOR
	repairing[box] = {}
end

function ObjectiveService.reset()
	table.clear(fixed)
	for _, box in fuseBoxes() do
		setup(box)
	end
	setExitOpen(false)
	updateProgress()
end

function ObjectiveService.init()
	-- Repairing is loud: every interval, each box someone is working on makes noise.
	task.spawn(function()
		while true do
			task.wait(SETTINGS.REPAIR_NOISE_INTERVAL)
			for box, players in repairing do
				if next(players) and box.Parent then
					NoiseService.emit(box.Position, SETTINGS.REPAIR_NOISE, "Repair")
				end
			end
		end
	end)
end

return ObjectiveService
