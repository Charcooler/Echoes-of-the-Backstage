--!strict
-- Replaces Roblox's default loading screen (ReplicatedFirst runs before anything else replicates).
-- Stays until the game has loaded and MIN_SHOW_TIME has passed, then fades out over the start screen.

local Players = game:GetService("Players")
local ReplicatedFirst = game:GetService("ReplicatedFirst")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local UiTheme = require(script.Parent:WaitForChild("UiTheme"))

local MIN_SHOW_TIME = 3
local TIPS = {
	"It cannot see you. It can hear you.",
	"Press C to crouch. Crouching makes no sound.",
	"Sprinting is loud. It will come running.",
	"Being hunted? Stop running, crouch and stay still.",
}

ReplicatedFirst:RemoveDefaultLoadingScreen()
local startTime = os.clock()

local gui = Instance.new("ScreenGui")
gui.Name = "LoadingScreen"
gui.IgnoreGuiInset = true
gui.DisplayOrder = 100
gui.ResetOnSpawn = false

local root = Instance.new("CanvasGroup")
root.Size = UDim2.fromScale(1, 1)
root.BackgroundColor3 = UiTheme.BLACK
root.BorderSizePixel = 0
root.Parent = gui

local rays = UiTheme.sunburst(root, UDim2.fromScale(0.5, 0.42), 18)
UiTheme.decoFrame(root, 24)
UiTheme.label(root, UiTheme.TITLE, UiTheme.TITLE_FONT, UiTheme.GOLD, UDim2.fromScale(0.7, 0.16), UDim2.fromScale(0.5, 0.38), 120)
UiTheme.label(root, UiTheme.SUBTITLE, UiTheme.TITLE_FONT, UiTheme.CREAM, UDim2.fromScale(0.6, 0.06), UDim2.fromScale(0.5, 0.49), 40)
local bars = UiTheme.soundBars(root, UDim2.fromScale(0.5, 0.64), 15)
local tip = UiTheme.label(root, TIPS[math.random(#TIPS)], UiTheme.BODY_FONT, UiTheme.CREAM, UDim2.fromScale(0.8, 0.04), UDim2.fromScale(0.5, 0.86), 26)
tip.TextTransparency = 0.25

gui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")

local animation = RunService.RenderStepped:Connect(function()
	local time = os.clock() - startTime
	UiTheme.animateSoundBars(bars, time, 30)
	UiTheme.turnSunburst(rays, time * 2)
end)

if not game:IsLoaded() then
	game.Loaded:Wait()
end
task.wait(math.max(0, MIN_SHOW_TIME - (os.clock() - startTime)))

local fade = TweenService:Create(root, TweenInfo.new(1.2), { GroupTransparency = 1 })
fade:Play()
fade.Completed:Wait()
animation:Disconnect()
gui:Destroy()
