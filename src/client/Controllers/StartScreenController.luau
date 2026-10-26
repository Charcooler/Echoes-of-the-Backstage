--!strict
-- Title screen shown under the loading screen: the camera looks at the stage between velvet curtains.
-- ENTER opens the curtains and hands the camera, controls and Roblox UI back to the player.

local GuiService = game:GetService("GuiService")
local Players = game:GetService("Players")
local ReplicatedFirst = game:GetService("ReplicatedFirst")
local RunService = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local UiTheme = require(ReplicatedFirst:WaitForChild("First"):WaitForChild("UiTheme"))

-- shortcut: framing fits DemoRoomService's stage; use a tagged camera part once the real map exists.
local MENU_CAMERA = CFrame.lookAt(Vector3.new(0, 9, -48), Vector3.new(0, 8, -98))
local OPEN_TIME = 1.4

local StartScreenController = {}

local function velvet(frame: GuiObject, folds: number)
	frame.BackgroundColor3 = Color3.new(1, 1, 1)
	frame.BorderSizePixel = 0
	local keypoints = {}
	for i = 0, folds do
		table.insert(keypoints, ColorSequenceKeypoint.new(i / folds, if i % 2 == 0 then UiTheme.VELVET else UiTheme.VELVET_DARK))
	end
	local gradient = Instance.new("UIGradient")
	gradient.Color = ColorSequence.new(keypoints)
	gradient.Parent = frame
end

-- side 0 = left curtain, 1 = right curtain.
local function makeCurtain(parent: Instance, side: number): Frame
	local curtain = Instance.new("Frame")
	curtain.AnchorPoint = Vector2.new(side, 0)
	curtain.Position = UDim2.fromScale(side, 0)
	curtain.Size = UDim2.fromScale(0.22, 1)
	velvet(curtain, 10)

	local fringe = Instance.new("Frame")
	fringe.AnchorPoint = Vector2.new(1 - side, 0)
	fringe.Position = UDim2.fromScale(1 - side, 0)
	fringe.Size = UDim2.new(0, 4, 1, 0)
	fringe.BackgroundColor3 = UiTheme.GOLD
	fringe.BorderSizePixel = 0
	fringe.Parent = curtain

	curtain.Parent = parent
	return curtain
end

local function makeValance(parent: Instance): Frame
	local valance = Instance.new("Frame")
	valance.Size = UDim2.fromScale(1, 0.09)
	velvet(valance, 18)
	local trim = Instance.new("Frame")
	trim.AnchorPoint = Vector2.new(0, 1)
	trim.Position = UDim2.fromScale(0, 1)
	trim.Size = UDim2.new(1, 0, 0, 4)
	trim.BackgroundColor3 = UiTheme.GOLD
	trim.BorderSizePixel = 0
	trim.Parent = valance
	valance.Parent = parent
	return valance
end

-- Darkens the top and bottom of the screen so the stage in the middle stands out.
local function makeShade(parent: Instance): Frame
	local shade = Instance.new("Frame")
	shade.Size = UDim2.fromScale(1, 1)
	shade.BackgroundColor3 = UiTheme.BLACK
	shade.BorderSizePixel = 0
	local gradient = Instance.new("UIGradient")
	gradient.Rotation = 90
	gradient.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.1),
		NumberSequenceKeypoint.new(0.35, 0.6),
		NumberSequenceKeypoint.new(0.65, 0.6),
		NumberSequenceKeypoint.new(1, 0.1),
	})
	gradient.Parent = shade
	shade.Parent = parent
	return shade
end

local function makeEnterButton(parent: Instance): TextButton
	local button = Instance.new("TextButton")
	button.AnchorPoint = Vector2.new(0.5, 0.5)
	button.Position = UDim2.fromScale(0.5, 0.66)
	button.Size = UDim2.fromOffset(220, 56)
	button.BackgroundColor3 = UiTheme.GOLD
	button.BackgroundTransparency = 1
	button.AutoButtonColor = false
	button.FontFace = UiTheme.TITLE_FONT
	button.Text = "ENTER"
	button.TextColor3 = UiTheme.GOLD
	button.TextSize = 30
	local stroke = Instance.new("UIStroke")
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Color = UiTheme.GOLD
	stroke.Thickness = 2
	stroke.Parent = button
	button.MouseEnter:Connect(function()
		button.BackgroundTransparency = 0.8
	end)
	button.MouseLeave:Connect(function()
		button.BackgroundTransparency = 1
	end)
	button.Parent = parent
	return button
end

-- Holds the character still while the menu is open. Anchoring locally works because the client owns its
-- character's physics, and it does not depend on Roblox's control scripts (not always a PlayerModule there).
local function setCharacterFrozen(character: Model?, frozen: boolean)
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if root and root:IsA("BasePart") then
		root.Anchored = frozen
	end
end

function StartScreenController.init()
	local player = Players.LocalPlayer
	local camera = workspace.CurrentCamera
	setCharacterFrozen(player.Character, true)
	local freezeOnSpawn = player.CharacterAdded:Connect(function(character)
		character:WaitForChild("HumanoidRootPart")
		setCharacterFrozen(character, true)
	end)
	StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.All, false)

	local gui = Instance.new("ScreenGui")
	gui.Name = "StartScreen"
	gui.IgnoreGuiInset = true
	gui.DisplayOrder = 50
	gui.ResetOnSpawn = false

	local shade = makeShade(gui)
	local leftCurtain = makeCurtain(gui, 0)
	local rightCurtain = makeCurtain(gui, 1)
	local valance = makeValance(gui)

	local content = Instance.new("CanvasGroup")
	content.Size = UDim2.fromScale(1, 1)
	content.BackgroundTransparency = 1
	content.Parent = gui

	local rays = UiTheme.sunburst(content, UDim2.fromScale(0.5, 0.33), 12)
	local title = UiTheme.label(content, UiTheme.TITLE, UiTheme.TITLE_FONT, UiTheme.GOLD, UDim2.fromScale(0.6, 0.15), UDim2.fromScale(0.5, 0.3), 130)
	UiTheme.label(content, UiTheme.SUBTITLE, UiTheme.TITLE_FONT, UiTheme.CREAM, UDim2.fromScale(0.45, 0.055), UDim2.fromScale(0.5, 0.41), 42)
	local bars = UiTheme.soundBars(content, UDim2.fromScale(0.5, 0.48), 11)
	UiTheme.label(content, UiTheme.TAGLINE, UiTheme.BODY_FONT, UiTheme.CREAM, UDim2.fromScale(0.5, 0.04), UDim2.fromScale(0.5, 0.55), 28)
	local button = makeEnterButton(content)
	local hint = UiTheme.label(content, "WASD  move     C  crouch     Shift  sprint", UiTheme.BODY_FONT, UiTheme.CREAM, UDim2.fromScale(0.6, 0.03), UDim2.fromScale(0.5, 0.9), 22)
	hint.TextTransparency = 0.35

	gui.Parent = player:WaitForChild("PlayerGui")
	if UserInputService.GamepadEnabled then
		GuiService.SelectedObject = button
	end

	local startTime = os.clock()
	-- The camera is forced every frame because the default camera scripts may reset it while the character spawns.
	local animation = RunService.RenderStepped:Connect(function()
		local time = os.clock() - startTime
		camera.CameraType = Enum.CameraType.Scriptable
		camera.CFrame = MENU_CAMERA
		UiTheme.turnSunburst(rays, time * 1.5)
		UiTheme.animateSoundBars(bars, time, 14)
		-- A rare flicker, like a failing stage light.
		title.TextTransparency = if math.noise(time * 2.5) > 0.32 then 0.65 else 0
	end)

	button.Activated:Once(function()
		button.Active = false
		local info = TweenInfo.new(OPEN_TIME, Enum.EasingStyle.Quint, Enum.EasingDirection.InOut)
		TweenService:Create(leftCurtain, info, { Position = UDim2.fromScale(-0.25, 0) }):Play()
		TweenService:Create(rightCurtain, info, { Position = UDim2.fromScale(1.25, 0) }):Play()
		TweenService:Create(valance, info, { Position = UDim2.fromScale(0, -0.12) }):Play()
		TweenService:Create(shade, info, { BackgroundTransparency = 1 }):Play()
		TweenService:Create(content, TweenInfo.new(OPEN_TIME * 0.5), { GroupTransparency = 1 }):Play()
		task.wait(OPEN_TIME)

		animation:Disconnect()
		camera.CameraType = Enum.CameraType.Custom
		freezeOnSpawn:Disconnect()
		setCharacterFrozen(player.Character, false)
		StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.All, true)
		GuiService.SelectedObject = nil
		gui:Destroy()
	end)
end

return StartScreenController
