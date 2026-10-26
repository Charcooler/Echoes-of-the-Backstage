--!strict
-- Small debug HUD: shows the local player's stance and how loud one footstep is.
-- Reads the "Stance" attribute that MovementNoiseController sets on the local player.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)

local NoiseHudController = {}

function NoiseHudController.init()
	local player = Players.LocalPlayer

	local gui = Instance.new("ScreenGui")
	gui.Name = "NoiseHud"
	gui.ResetOnSpawn = false

	local label = Instance.new("TextLabel")
	label.AnchorPoint = Vector2.new(0, 1)
	label.Position = UDim2.new(0, 16, 1, -16)
	label.Size = UDim2.fromOffset(300, 56)
	label.BackgroundColor3 = Color3.new(0, 0, 0)
	label.BackgroundTransparency = 0.4
	label.TextColor3 = Color3.new(1, 1, 1)
	label.TextSize = 18
	label.Parent = gui

	local function update()
		local stance = player:GetAttribute("Stance")
		local settings = if typeof(stance) == "string" then Config.STANCES[stance] else nil
		label.Text = if settings then `{stance}  ·  noise {settings.NOISE}\n[C] crouch   [Shift] sprint` else ""
	end
	player:GetAttributeChangedSignal("Stance"):Connect(update)
	update()

	gui.Parent = player:WaitForChild("PlayerGui")
end

return NoiseHudController
