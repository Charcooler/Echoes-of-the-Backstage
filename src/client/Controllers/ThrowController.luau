--!strict
-- Throws the carried bottle where the camera looks: F on keyboard, R2 on gamepad, or an on-screen button on touch.
-- Only bound while the player holds a bottle (the HasBottle attribute set by ItemService).

local ContextActionService = game:GetService("ContextActionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remotes = require(ReplicatedStorage.Shared.Remotes)

local ACTION = "ThrowBottle"

local ThrowController = {}

function ThrowController.init()
	local player = Players.LocalPlayer
	-- Spawned so waiting for the remote does not block the other controllers from loading.
	task.spawn(function()
		local throwEvent = Remotes.getEvent("ThrowEvent") :: RemoteEvent
		local function onAction(_: string, inputState: Enum.UserInputState, _: InputObject): Enum.ContextActionResult
			if inputState ~= Enum.UserInputState.Begin then
				return Enum.ContextActionResult.Pass
			end
			throwEvent:FireServer(workspace.CurrentCamera.CFrame.LookVector)
			return Enum.ContextActionResult.Sink
		end
		local function update()
			if player:GetAttribute("HasBottle") then
				ContextActionService:BindAction(ACTION, onAction, true, Enum.KeyCode.F, Enum.KeyCode.ButtonR2)
				ContextActionService:SetTitle(ACTION, "Throw")
			else
				ContextActionService:UnbindAction(ACTION)
			end
		end
		player:GetAttributeChangedSignal("HasBottle"):Connect(update)
		update()
	end)
end

return ThrowController
