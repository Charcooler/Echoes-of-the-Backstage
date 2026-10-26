--!strict
-- When your round is over (escaped or caught) the camera follows a teammate who is still playing.
-- Switch between them with the Left/Right arrows, the gamepad D-pad or the on-screen buttons on touch.
-- The next round gives you a new character, and Roblox points the camera back at it.

local ContextActionService = game:GetService("ContextActionService")
local Players = game:GetService("Players")
local ReplicatedFirst = game:GetService("ReplicatedFirst")

local UiTheme = require(ReplicatedFirst:WaitForChild("First"):WaitForChild("UiTheme"))

local DEATH_PAUSE = 2 -- seconds you see what got you before the camera moves on

local SpectateController = {}

local function teammatesStillPlaying(): { Player }
	local mates = {}
	for _, other in Players:GetPlayers() do
		local character = other.Character
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		if other ~= Players.LocalPlayer and other:GetAttribute("Outcome") == nil and humanoid and humanoid.Health > 0 then
			table.insert(mates, other)
		end
	end
	return mates
end

function SpectateController.init()
	local player = Players.LocalPlayer
	local camera = workspace.CurrentCamera

	local gui = Instance.new("ScreenGui")
	gui.Name = "Spectate"
	gui.ResetOnSpawn = false
	gui.DisplayOrder = 6
	local label = UiTheme.label(gui, "", UiTheme.BODY_FONT, UiTheme.CREAM, UDim2.new(0.6, 0, 0, 26), UDim2.new(0.5, 0, 1, -70), 24)
	gui.Parent = player:WaitForChild("PlayerGui")

	local spectating = false
	local index = 1
	local watched: Player? = nil

	local function follow()
		local mates = teammatesStillPlaying()
		if #mates == 0 then
			watched = nil
			label.Text = ""
			return
		end
		index = (index - 1) % #mates + 1
		watched = mates[index]
		local humanoid = (watched :: Player).Character:FindFirstChildOfClass("Humanoid")
		camera.CameraSubject = humanoid
		label.Text = `Watching {(watched :: Player).DisplayName}      Left / Right to switch`
	end

	local function onSwitch(action: string, inputState: Enum.UserInputState, _: InputObject): Enum.ContextActionResult
		if inputState ~= Enum.UserInputState.Begin then
			return Enum.ContextActionResult.Pass
		end
		index += if action == "SpectateNext" then 1 else -1
		follow()
		return Enum.ContextActionResult.Sink
	end

	local function setSpectating(on: boolean)
		if on == spectating then
			return
		end
		spectating = on
		if on then
			ContextActionService:BindAction("SpectateNext", onSwitch, true, Enum.KeyCode.Right, Enum.KeyCode.DPadRight)
			ContextActionService:BindAction("SpectatePrevious", onSwitch, true, Enum.KeyCode.Left, Enum.KeyCode.DPadLeft)
			ContextActionService:SetTitle("SpectateNext", ">")
			ContextActionService:SetTitle("SpectatePrevious", "<")
			follow()
		else
			ContextActionService:UnbindAction("SpectateNext")
			ContextActionService:UnbindAction("SpectatePrevious")
			watched = nil
			label.Text = ""
		end
	end

	player:GetAttributeChangedSignal("Outcome"):Connect(function()
		if player:GetAttribute("Outcome") == nil then
			setSpectating(false)
		else
			task.delay(DEATH_PAUSE, function()
				if player:GetAttribute("Outcome") ~= nil then
					setSpectating(true)
				end
			end)
		end
	end)

	-- Move on when the teammate you watch escapes or gets caught.
	task.spawn(function()
		while true do
			task.wait(1)
			if spectating and (watched == nil or (watched :: Player):GetAttribute("Outcome") ~= nil) then
				follow()
			end
		end
	end)
end

return SpectateController
