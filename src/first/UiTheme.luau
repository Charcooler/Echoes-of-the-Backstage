--!strict
-- Visual identity shared by the loading screen and the start screen:
-- 1920s Art Deco (gold on black, sunbursts, double frames), opera-red velvet and a sound meter motif.
-- Lives in ReplicatedFirst so the loading screen can use it before anything else has replicated.

local UiTheme = {}

UiTheme.BLACK = Color3.fromRGB(8, 7, 9)
UiTheme.GOLD = Color3.fromRGB(201, 162, 74)
UiTheme.CREAM = Color3.fromRGB(232, 222, 200)
UiTheme.VELVET = Color3.fromRGB(110, 12, 24)
UiTheme.VELVET_DARK = Color3.fromRGB(45, 4, 10)

UiTheme.TITLE_FONT = Font.fromEnum(Enum.Font.Bodoni)
UiTheme.BODY_FONT = Font.fromEnum(Enum.Font.Garamond)

-- Letter-spaced on purpose: Bodoni would otherwise join "OE" into the ligature "Œ".
UiTheme.TITLE = "E C H O E S"
UiTheme.SUBTITLE = "OF THE BACKSTAGE"
UiTheme.TAGLINE = "Silence is your only armor."

function UiTheme.label(parent: Instance, text: string, font: Font, color: Color3, size: UDim2, position: UDim2, maxTextSize: number): TextLabel
	local label = Instance.new("TextLabel")
	label.AnchorPoint = Vector2.new(0.5, 0.5)
	label.BackgroundTransparency = 1
	label.Size = size
	label.Position = position
	label.FontFace = font
	label.TextColor3 = color
	label.Text = text
	label.TextScaled = true
	local constraint = Instance.new("UITextSizeConstraint")
	constraint.MaxTextSize = maxTextSize
	constraint.Parent = label
	label.Parent = parent
	return label
end

local function rayAngle(index: number, count: number, turn: number): number
	-- A centered ray points both ways, so 180 degrees covers the full circle.
	return index / count * 180 + turn
end

-- Thin gold rays fanning out from `center`, faded in the middle and at the ends.
function UiTheme.sunburst(parent: Instance, center: UDim2, rayCount: number): { Frame }
	local rays = {}
	for i = 1, rayCount do
		local ray = Instance.new("Frame")
		ray.AnchorPoint = Vector2.new(0.5, 0.5)
		ray.Position = center
		ray.Size = UDim2.fromOffset(2, 1400)
		ray.Rotation = rayAngle(i, rayCount, 0)
		ray.BackgroundColor3 = UiTheme.GOLD
		ray.BorderSizePixel = 0
		local gradient = Instance.new("UIGradient")
		gradient.Rotation = 90
		gradient.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 1),
			NumberSequenceKeypoint.new(0.32, 0.8),
			NumberSequenceKeypoint.new(0.5, 1),
			NumberSequenceKeypoint.new(0.68, 0.8),
			NumberSequenceKeypoint.new(1, 1),
		})
		gradient.Parent = ray
		ray.Parent = parent
		table.insert(rays, ray)
	end
	return rays
end

function UiTheme.turnSunburst(rays: { Frame }, turn: number)
	for i, ray in rays do
		ray.Rotation = rayAngle(i, #rays, turn)
	end
end

-- Art Deco double gold border inset from the edges of `parent`.
function UiTheme.decoFrame(parent: Instance, inset: number)
	for i, offset in { inset, inset + 8 } do
		local border = Instance.new("Frame")
		border.AnchorPoint = Vector2.new(0.5, 0.5)
		border.Position = UDim2.fromScale(0.5, 0.5)
		border.Size = UDim2.new(1, -offset * 2, 1, -offset * 2)
		border.BackgroundTransparency = 1
		local stroke = Instance.new("UIStroke")
		stroke.Color = UiTheme.GOLD
		stroke.Thickness = if i == 1 then 2 else 1
		stroke.Transparency = 0.3
		stroke.Parent = border
		border.Parent = parent
	end
end

-- A row of gold bars animated like a sound meter, the game's core motif.
function UiTheme.soundBars(parent: Instance, position: UDim2, count: number): { Frame }
	local row = Instance.new("Frame")
	row.AnchorPoint = Vector2.new(0.5, 0.5)
	row.Position = position
	row.Size = UDim2.fromOffset(count * 10, 40)
	row.BackgroundTransparency = 1
	local layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Horizontal
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	layout.VerticalAlignment = Enum.VerticalAlignment.Center
	layout.Padding = UDim.new(0, 4)
	layout.Parent = row

	local bars = {}
	for _ = 1, count do
		local bar = Instance.new("Frame")
		bar.Size = UDim2.fromOffset(6, 4)
		bar.BackgroundColor3 = UiTheme.GOLD
		bar.BorderSizePixel = 0
		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, 3)
		corner.Parent = bar
		bar.Parent = row
		table.insert(bars, bar)
	end
	row.Parent = parent
	return bars
end

-- `loudness` is the extra bar height in pixels; two sine waves make it look like real audio.
function UiTheme.animateSoundBars(bars: { Frame }, time: number, loudness: number)
	for i, bar in bars do
		local wave = (0.5 + 0.5 * math.sin(time * 6 + i * 0.9)) * (0.5 + 0.5 * math.sin(time * 2.3 + i * 1.7))
		bar.Size = UDim2.fromOffset(6, 4 + loudness * wave)
	end
end

return UiTheme
