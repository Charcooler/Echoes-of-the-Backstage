--!strict
-- Round HUD in the game's Art Deco style: the objective at the top, a hint while carrying a bottle, and the
-- result screen (escaped / caught, countdown to the next round).
-- Reads the workspace attributes RoundState, NextRoundAt, FusesFixed, FusesTotal and ExitOpen and the player
-- attributes Outcome and HasBottle.

local Players = game:GetService("Players")
local ReplicatedFirst = game:GetService("ReplicatedFirst")

local UiTheme = require(ReplicatedFirst:WaitForChild("First"):WaitForChild("UiTheme"))

local RoundHudController = {}

function RoundHudController.init()
	local player = Players.LocalPlayer

	local gui = Instance.new("ScreenGui")
	gui.Name = "RoundHud"
	gui.ResetOnSpawn = false
	gui.DisplayOrder = 5

	local objective = UiTheme.label(gui, "", UiTheme.TITLE_FONT, UiTheme.GOLD, UDim2.new(0.7, 0, 0, 30), UDim2.new(0.5, 0, 0, 28), 28)
	local hint = UiTheme.label(gui, "", UiTheme.BODY_FONT, UiTheme.CREAM, UDim2.new(0.7, 0, 0, 24), UDim2.new(0.5, 0, 1, -110), 22)

	local result = Instance.new("Frame")
	result.Size = UDim2.fromScale(1, 1)
	result.BackgroundColor3 = UiTheme.BLACK
	result.BackgroundTransparency = 0.25
	result.Visible = false
	result.Parent = gui
	UiTheme.decoFrame(result, 24)
	local title = UiTheme.label(result, "", UiTheme.TITLE_FONT, UiTheme.GOLD, UDim2.fromScale(0.7, 0.12), UDim2.fromScale(0.5, 0.42), 90)
	local subtitle = UiTheme.label(result, "", UiTheme.BODY_FONT, UiTheme.CREAM, UDim2.fromScale(0.6, 0.05), UDim2.fromScale(0.5, 0.55), 28)

	gui.Parent = player:WaitForChild("PlayerGui")

	-- A light poll keeps this simple: a handful of attributes, read five times a second.
	task.spawn(function()
		while true do
			local fixed = workspace:GetAttribute("FusesFixed") or 0
			local total = workspace:GetAttribute("FusesTotal") or 0
			local outcome = player:GetAttribute("Outcome")
			local ended = workspace:GetAttribute("RoundState") == "Ended"
			-- Out of the round but others still play: a line on top, so the spectator view stays clear.
			objective.Text = if outcome == "Escaped"
				then "You escaped. Watch the others try to make it out."
				elseif outcome == "Caught" then "It heard you. Watch the others..."
				elseif workspace:GetAttribute("ExitOpen") then "The power is back. Escape through the door behind the stage!"
				else `Repair the fuse boxes   {fixed} / {total}`
			hint.Text = if player:GetAttribute("HasBottle") then "Bottle in hand: press F to throw it and lure the monster away" else ""
			result.Visible = ended
			title.Text = if outcome == "Escaped" then "YOU ESCAPED" elseif outcome == "Caught" then "IT HEARD YOU" else "ROUND OVER"
			local nextRoundAt = workspace:GetAttribute("NextRoundAt")
			subtitle.Text = if typeof(nextRoundAt) == "number"
				then `Next round in {math.max(0, math.ceil(nextRoundAt - workspace:GetServerTimeNow()))}`
				else ""
			task.wait(0.2)
		end
	end)
end

return RoundHudController
