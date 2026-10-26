--!strict
-- Stance-based movement: C toggles crouch, holding LeftShift sprints.
-- While moving on the ground it reports a footstep to the server, which decides how loud it was.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local Config = require(ReplicatedStorage.Shared.Config)
local Remotes = require(ReplicatedStorage.Shared.Remotes)

local CROUCH_KEY = Enum.KeyCode.C
local SPRINT_KEY = Enum.KeyCode.LeftShift

local MovementNoiseController = {}

local player = Players.LocalPlayer
local crouching = false
local sprinting = false

local function currentStance(): string
	if sprinting then
		return "Sprint"
	end
	return if crouching then "Crouch" else "Walk"
end

local function getHumanoid(): Humanoid?
	local character = player.Character
	return character and character:FindFirstChildOfClass("Humanoid")
end

local function applyWalkSpeed()
	-- Local only (client attributes do not replicate); read by NoiseHudController, never by the server.
	player:SetAttribute("Stance", currentStance())
	local humanoid = getHumanoid()
	if humanoid then
		humanoid.WalkSpeed = Config.STANCES[currentStance()].WALK_SPEED
	end
end

local function onInput(input: InputObject, gameProcessed: boolean, isDown: boolean)
	if input.KeyCode == SPRINT_KEY then
		sprinting = isDown
	elseif input.KeyCode == CROUCH_KEY and isDown and not gameProcessed then
		crouching = not crouching
	else
		return
	end
	print(`[MovementNoiseController] stance={currentStance()}`)
	applyWalkSpeed()
end

local function footstepLoop()
	local noiseEvent = Remotes.getEvent("NoiseEvent") :: RemoteEvent
	while true do
		local stance = currentStance()
		local humanoid = getHumanoid()
		if humanoid and humanoid.MoveDirection.Magnitude > 0 and humanoid.FloorMaterial ~= Enum.Material.Air then
			noiseEvent:FireServer("Footstep", stance)
		end
		task.wait(Config.STANCES[stance].STEP_INTERVAL)
	end
end

function MovementNoiseController.init()
	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		onInput(input, gameProcessed, true)
	end)
	UserInputService.InputEnded:Connect(function(input, gameProcessed)
		onInput(input, gameProcessed, false)
	end)
	player.CharacterAdded:Connect(function(character)
		character:WaitForChild("Humanoid")
		applyWalkSpeed()
	end)
	applyWalkSpeed()
	-- Spawned so waiting for the remote does not block the other controllers from loading.
	task.spawn(footstepLoop)
end

return MovementNoiseController
