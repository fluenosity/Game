--!strict
--[[
    EnvironmentTimeControllerPlugin.lua
    Roblox Studio Plugin: World Time, Day & Atmosphere Controller
    for "Don't Let the Fire Die" (Fluenosity Studio).

    Features:
    - Instant 1-click Presets: Dawn (06:00), Noon (12:00), Afternoon (14:00 Dev), Dusk (17:30), Night (20:00), Midnight (00:00).
    - Smooth Real-time Scrubber: Drag the slider to scrub sun/moon arc across the sky in real-time.
    - Day Progression Selector: Days 0 to 5 (escalating darkness, cloud oppression & survival fog).
    - Instant Cloud & Weather Presets: Alpine Clear, Fluffy Midday, Overcast, Stormy, Milky Way Night.
    - Studio Time Simulation (Play/Pause with 1x, 10x, 60x, 360x speeds) to preview full cycles.
    - Glassmorphic Obsidian / Ember UI aesthetic with ChangeHistoryService undo support.
]]

local ChangeHistoryService = game:GetService("ChangeHistoryService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local UserInputService = game:GetService("UserInputService")

-- -----------------------------------------------------------------------------
-- Helper: Safe Require of Shared Systems
-- -----------------------------------------------------------------------------

local function getSharedFolder(): Folder?
	return ReplicatedStorage:FindFirstChild("FluenosityShared") :: Folder?
end

local function getTimeVisuals(): any?
	local sharedFolder = getSharedFolder()
	if sharedFolder and sharedFolder:FindFirstChild("TimeVisuals") then
		local ok, mod = pcall(function()
			return require(sharedFolder:FindFirstChild("TimeVisuals"))
		end)
		if ok then return mod end
	end
	return nil
end

local function getEnvironmentManager(): any?
	local sharedFolder = getSharedFolder()
	if sharedFolder and sharedFolder:FindFirstChild("Environment") then
		local envFolder = sharedFolder:FindFirstChild("Environment")
		if envFolder and envFolder:FindFirstChild("EnvironmentManager") then
			local ok, mod = pcall(function()
				return require(envFolder:FindFirstChild("EnvironmentManager"))
			end)
			if ok then return mod end
		end
	end
	return nil
end

-- -----------------------------------------------------------------------------
-- State
-- -----------------------------------------------------------------------------

local currentHour: number = 14.0
local currentDay: number = 0
local isSimulating: boolean = false
local simSpeed: number = 60.0 -- 60x = 1 game minute per real second

-- -----------------------------------------------------------------------------
-- Core Time Application Logic
-- -----------------------------------------------------------------------------

local function applyTime(hour: number, day: number, recordWaypoint: boolean?)
	currentHour = math.clamp(hour % 24, 0, 24)
	currentDay = math.clamp(math.floor(day), 0, 5)

	-- 1. Apply through TimeVisuals & EnvironmentManager
	local TimeVisuals = getTimeVisuals()
	if TimeVisuals and typeof(TimeVisuals.Apply) == "function" then
		pcall(function()
			TimeVisuals.Apply(currentHour, currentDay)
		end)
	else
		-- Direct fallback if module unavailable
		Lighting.ClockTime = currentHour
	end

	-- Also set StudioTimeOverride on Lighting for instant client reflection
	Lighting:SetAttribute("StudioTimeOverride", currentHour)
	Lighting.ClockTime = currentHour

	-- 2. Synchronize ReplicatedStorage TimeState (if present in Play/Test mode)
	local sharedFolder = getSharedFolder()
	if sharedFolder then
		local timeState = sharedFolder:FindFirstChild("TimeState")
		if timeState then
			timeState:SetAttribute("CurrentHour", currentHour)
			timeState:SetAttribute("FreezeHour", currentHour)
			timeState:SetAttribute("CurrentDay", currentDay)
		end
	end

	-- 3. Register Undo Waypoint if requested
	if recordWaypoint then
		pcall(function()
			ChangeHistoryService:SetWaypoint(string.format("Set Environment Time (%.1f:00, Day %d)", currentHour, currentDay))
		end)
	end
end

local function formatTimeDisplay(hour: number): (string, string)
	local totalMins = math.floor(hour * 60)
	local h = math.floor(totalMins / 60)
	local m = totalMins % 60
	local ampm = h >= 12 and "PM" or "AM"
	local h12 = h % 12
	if h12 == 0 then h12 = 12 end

	local timeStr = string.format("%02d:%02d (%d:%02d %s)", h, m, h12, m, ampm)

	local phase = "DAY"
	if hour >= 5.0 and hour < 7.0 then
		phase = "DAWN"
	elseif hour >= 7.0 and hour < 17.0 then
		phase = "DAY"
	elseif hour >= 17.0 and hour < 19.0 then
		phase = "DUSK"
	else
		phase = "NIGHT"
	end

	return timeStr, phase
end

-- -----------------------------------------------------------------------------
-- Toolbar & Quick Action Buttons
-- -----------------------------------------------------------------------------

local toolbar = plugin:CreateToolbar("🌅 Environment & Time")
local btnTogglePanel = toolbar:CreateButton("Open Time Panel", "Open the Environment & World Time Control Panel", "rbxassetid://16898613044")
local btnQuickNoon = toolbar:CreateButton("☀️ Noon (14:00)", "Set to clear midday dev lighting (14:00)", "rbxassetid://6281397916")
local btnQuickDusk = toolbar:CreateButton("🌇 Dusk (17:30)", "Set to sunset golden hour (17:30)", "rbxassetid://16898613613")
local btnQuickMidnight = toolbar:CreateButton("🌌 Midnight (00:00)", "Set to deep starry galaxy night (00:00)", "rbxassetid://2626744426")

btnQuickNoon.Click:Connect(function()
	applyTime(14.0, currentDay, true)
end)

btnQuickDusk.Click:Connect(function()
	applyTime(17.5, currentDay, true)
end)

btnQuickMidnight.Click:Connect(function()
	applyTime(0.0, currentDay, true)
end)

-- -----------------------------------------------------------------------------
-- Dockable Widget Window
-- -----------------------------------------------------------------------------

local widgetInfo = DockWidgetPluginGuiInfo.new(
	Enum.InitialDockState.Right,
	false,
	false,
	320,
	560,
	280,
	420
)
local widget = plugin:CreateDockWidgetPluginGui("EnvironmentTimeWidget", widgetInfo)
widget.Title = "🌅 World Time & Atmosphere"

btnTogglePanel.Click:Connect(function()
	widget.Enabled = not widget.Enabled
end)

-- Main Background Container
local rootScroll = Instance.new("ScrollingFrame")
rootScroll.Size = UDim2.fromScale(1, 1)
rootScroll.BackgroundColor3 = Color3.fromRGB(18, 18, 22)
rootScroll.BorderSizePixel = 0
rootScroll.ScrollBarThickness = 4
rootScroll.ScrollBarImageColor3 = Color3.fromRGB(255, 140, 50)
rootScroll.CanvasSize = UDim2.new(0, 0, 0, 680)
rootScroll.Parent = widget

local rootPad = Instance.new("UIPadding")
rootPad.PaddingTop = UDim.new(0, 14)
rootPad.PaddingBottom = UDim.new(0, 14)
rootPad.PaddingLeft = UDim.new(0, 12)
rootPad.PaddingRight = UDim.new(0, 12)
rootPad.Parent = rootScroll

local rootList = Instance.new("UIListLayout")
rootList.Padding = UDim.new(0, 10)
rootList.SortOrder = Enum.SortOrder.LayoutOrder
rootList.Parent = rootScroll

-- -----------------------------------------------------------------------------
-- UI Component Builders (Glassmorphic Luxury Aesthetic)
-- -----------------------------------------------------------------------------

local function createCard(layoutOrder: number, height: number): Frame
	local card = Instance.new("Frame")
	card.Size = UDim2.new(1, 0, 0, height)
	card.BackgroundColor3 = Color3.fromRGB(26, 27, 33)
	card.BorderSizePixel = 0
	card.LayoutOrder = layoutOrder
	card.Parent = rootScroll

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = card

	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(48, 50, 62)
	stroke.Thickness = 1
	stroke.Parent = card

	local pad = Instance.new("UIPadding")
	pad.PaddingTop = UDim.new(0, 10)
	pad.PaddingBottom = UDim.new(0, 10)
	pad.PaddingLeft = UDim.new(0, 10)
	pad.PaddingRight = UDim.new(0, 10)
	pad.Parent = card

	return card
end

local function createSectionTitle(parent: Instance, text: string)
	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, 0, 0, 18)
	label.BackgroundTransparency = 1
	label.Text = text:upper()
	label.TextColor3 = Color3.fromRGB(255, 165, 65)
	label.Font = Enum.Font.GothamBold
	label.TextSize = 11
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Parent = parent
	return label
end

-- -----------------------------------------------------------------------------
-- Card 1: Time & Phase Display Header
-- -----------------------------------------------------------------------------

local headerCard = createCard(1, 80)
local timeLabel = Instance.new("TextLabel")
timeLabel.Size = UDim2.new(1, 0, 0, 32)
timeLabel.BackgroundTransparency = 1
timeLabel.Text = "14:00 (2:00 PM)"
timeLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
timeLabel.Font = Enum.Font.GothamBold
timeLabel.TextSize = 22
timeLabel.TextXAlignment = Enum.TextXAlignment.Center
timeLabel.Parent = headerCard

local phasePill = Instance.new("TextLabel")
phasePill.Size = UDim2.new(0, 120, 0, 22)
phasePill.Position = UDim2.new(0.5, -60, 0, 36)
phasePill.BackgroundColor3 = Color3.fromRGB(40, 75, 110)
phasePill.TextColor3 = Color3.fromRGB(200, 230, 255)
phasePill.Font = Enum.Font.GothamBold
phasePill.TextSize = 11
phasePill.Text = "☀️ DAY PHASE"
phasePill.Parent = headerCard

local phaseCorner = Instance.new("UICorner")
phaseCorner.CornerRadius = UDim.new(0, 11)
phaseCorner.Parent = phasePill

-- -----------------------------------------------------------------------------
-- Card 2: Preset Time Buttons
-- -----------------------------------------------------------------------------

local presetsCard = createCard(2, 115)
createSectionTitle(presetsCard, "⚡ QUICK TIME PRESETS")

local presetsGrid = Instance.new("Frame")
presetsGrid.Size = UDim2.new(1, 0, 0, 70)
presetsGrid.Position = UDim2.new(0, 0, 0, 24)
presetsGrid.BackgroundTransparency = 1
presetsGrid.Parent = presetsCard

local gridLayout = Instance.new("UIGridLayout")
gridLayout.CellSize = UDim2.new(0.31, 0, 0, 32)
gridLayout.CellPadding = UDim2.new(0.035, 0, 0, 6)
gridLayout.SortOrder = Enum.SortOrder.LayoutOrder
gridLayout.Parent = presetsGrid

local TIME_PRESETS = {
	{ Name = "🌅 Dawn", Hour = 6.0, Color = Color3.fromRGB(180, 100, 60) },
	{ Name = "☀️ Noon", Hour = 12.0, Color = Color3.fromRGB(60, 130, 180) },
	{ Name = "🌤️ Midday", Hour = 14.0, Color = Color3.fromRGB(45, 120, 160) },
	{ Name = "🌇 Dusk", Hour = 17.5, Color = Color3.fromRGB(190, 95, 40) },
	{ Name = "🌙 Night", Hour = 20.0, Color = Color3.fromRGB(70, 60, 120) },
	{ Name = "🌌 Midnight", Hour = 0.0, Color = Color3.fromRGB(35, 30, 70) },
}

local function updateUIElements()
	local timeStr, phase = formatTimeDisplay(currentHour)
	timeLabel.Text = timeStr

	if phase == "DAWN" then
		phasePill.Text = "🌅 DAWN"
		phasePill.BackgroundColor3 = Color3.fromRGB(140, 80, 50)
		phasePill.TextColor3 = Color3.fromRGB(255, 220, 190)
	elseif phase == "DAY" then
		phasePill.Text = "☀️ DAY PHASE"
		phasePill.BackgroundColor3 = Color3.fromRGB(40, 90, 130)
		phasePill.TextColor3 = Color3.fromRGB(210, 240, 255)
	elseif phase == "DUSK" then
		phasePill.Text = "🌇 DUSK / GOLDEN"
		phasePill.BackgroundColor3 = Color3.fromRGB(160, 80, 35)
		phasePill.TextColor3 = Color3.fromRGB(255, 215, 175)
	else
		phasePill.Text = "🌌 NIGHT / GALAXY"
		phasePill.BackgroundColor3 = Color3.fromRGB(45, 40, 85)
		phasePill.TextColor3 = Color3.fromRGB(215, 205, 255)
	end
end

for idx, p in ipairs(TIME_PRESETS) do
	local b = Instance.new("TextButton")
	b.Name = p.Name
	b.BackgroundColor3 = p.Color
	b.TextColor3 = Color3.fromRGB(255, 255, 255)
	b.Font = Enum.Font.GothamBold
	b.TextSize = 11
	b.Text = p.Name
	b.BorderSizePixel = 0
	b.LayoutOrder = idx
	b.Parent = presetsGrid

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 6)
	corner.Parent = b

	b.Activated:Connect(function()
		applyTime(p.Hour, currentDay, true)
		updateUIElements()
	end)
end

-- -----------------------------------------------------------------------------
-- Card 3: Continuous Time Slider (Real-time Scrubbing)
-- -----------------------------------------------------------------------------

local sliderCard = createCard(3, 85)
createSectionTitle(sliderCard, "🎛️ SCRUB TIME (0.0 - 24.0)")

local sliderTrack = Instance.new("TextButton")
sliderTrack.Size = UDim2.new(1, 0, 0, 18)
sliderTrack.Position = UDim2.new(0, 0, 0, 32)
sliderTrack.BackgroundColor3 = Color3.fromRGB(15, 16, 20)
sliderTrack.BorderSizePixel = 0
sliderTrack.Text = ""
sliderTrack.AutoButtonColor = false
sliderTrack.Parent = sliderCard

local trackCorner = Instance.new("UICorner")
trackCorner.CornerRadius = UDim.new(0, 9)
trackCorner.Parent = sliderTrack

local sliderFill = Instance.new("Frame")
sliderFill.Size = UDim2.new(currentHour / 24, 0, 1, 0)
sliderFill.BackgroundColor3 = Color3.fromRGB(255, 150, 50)
sliderFill.BorderSizePixel = 0
sliderFill.Parent = sliderTrack

local fillCorner = Instance.new("UICorner")
fillCorner.CornerRadius = UDim.new(0, 9)
fillCorner.Parent = sliderFill

local fillGrad = Instance.new("UIGradient")
fillGrad.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromRGB(120, 60, 200)),
	ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 160, 60)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(70, 160, 255)),
})
fillGrad.Parent = sliderFill

local knob = Instance.new("Frame")
knob.Size = UDim2.new(0, 24, 0, 24)
knob.AnchorPoint = Vector2.new(0.5, 0.5)
knob.Position = UDim2.new(currentHour / 24, 0, 0.5, 0)
knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
knob.BorderSizePixel = 0
knob.Parent = sliderTrack

local knobCorner = Instance.new("UICorner")
knobCorner.CornerRadius = UDim.new(1, 0)
knobCorner.Parent = knob

local knobStroke = Instance.new("UIStroke")
knobStroke.Color = Color3.fromRGB(255, 140, 40)
knobStroke.Thickness = 2
knobStroke.Parent = knob

local isDraggingSlider = false

local function updateSliderVisual(hour: number)
	local alpha = math.clamp(hour / 24, 0, 1)
	sliderFill.Size = UDim2.new(alpha, 0, 1, 0)
	knob.Position = UDim2.new(alpha, 0, 0.5, 0)
end

local function handleSliderInput(inputPos: Vector2)
	local trackAbsPos = sliderTrack.AbsolutePosition
	local trackAbsSize = sliderTrack.AbsoluteSize
	local alpha = math.clamp((inputPos.X - trackAbsPos.X) / trackAbsSize.X, 0, 1)
	local targetHourVal = alpha * 24.0
	applyTime(targetHourVal, currentDay, false)
	updateSliderVisual(targetHourVal)
	updateUIElements()
end

sliderTrack.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		isDraggingSlider = true
		handleSliderInput(Vector2.new(input.Position.X, input.Position.Y))
	end
end)

UserInputService.InputChanged:Connect(function(input)
	if isDraggingSlider and input.UserInputType == Enum.UserInputType.MouseMovement then
		handleSliderInput(Vector2.new(input.Position.X, input.Position.Y))
	end
end)

UserInputService.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 and isDraggingSlider then
		isDraggingSlider = false
		pcall(function()
			ChangeHistoryService:SetWaypoint(string.format("Scrub Time to %.1f", currentHour))
		end)
	end
end)

-- -----------------------------------------------------------------------------
-- Card 4: Day Tension Selector (Days 0 to 5)
-- -----------------------------------------------------------------------------

local dayCard = createCard(4, 95)
createSectionTitle(dayCard, "📅 SURVIVAL DAY (DARKNESS & FOG OPPRESSION)")

local dayGrid = Instance.new("Frame")
dayGrid.Size = UDim2.new(1, 0, 0, 42)
dayGrid.Position = UDim2.new(0, 0, 0, 26)
dayGrid.BackgroundTransparency = 1
dayGrid.Parent = dayCard

local dayLayout = Instance.new("UIGridLayout")
dayLayout.CellSize = UDim2.new(0.145, 0, 0, 36)
dayLayout.CellPadding = UDim2.new(0.026, 0, 0, 0)
dayLayout.SortOrder = Enum.SortOrder.LayoutOrder
dayLayout.Parent = dayGrid

local dayButtons: { [number]: TextButton } = {}

local function updateDayButtonsVisual()
	for d, b in pairs(dayButtons) do
		if d == currentDay then
			b.BackgroundColor3 = Color3.fromRGB(255, 140, 40)
			b.TextColor3 = Color3.fromRGB(20, 20, 24)
		else
			b.BackgroundColor3 = Color3.fromRGB(38, 40, 50)
			b.TextColor3 = Color3.fromRGB(200, 205, 215)
		end
	end
end

for d = 0, 5 do
	local b = Instance.new("TextButton")
	b.Name = "Day" .. tostring(d)
	b.BackgroundColor3 = (d == currentDay) and Color3.fromRGB(255, 140, 40) or Color3.fromRGB(38, 40, 50)
	b.TextColor3 = (d == currentDay) and Color3.fromRGB(20, 20, 24) or Color3.fromRGB(200, 205, 215)
	b.Font = Enum.Font.GothamBold
	b.TextSize = 12
	b.Text = "D" .. tostring(d)
	b.BorderSizePixel = 0
	b.LayoutOrder = d
	b.Parent = dayGrid

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 6)
	corner.Parent = b

	dayButtons[d] = b

	b.Activated:Connect(function()
		currentDay = d
		applyTime(currentHour, currentDay, true)
		updateDayButtonsVisual()
		updateUIElements()
	end)
end

-- -----------------------------------------------------------------------------
-- Card 5: Volumetric Cloud & Weather Presets
-- -----------------------------------------------------------------------------

local weatherCard = createCard(5, 120)
createSectionTitle(weatherCard, "☁️ VOLUMETRIC CLOUDS & WEATHER")

local weatherGrid = Instance.new("Frame")
weatherGrid.Size = UDim2.new(1, 0, 0, 72)
weatherGrid.Position = UDim2.new(0, 0, 0, 24)
weatherGrid.BackgroundTransparency = 1
weatherGrid.Parent = weatherCard

local wLayout = Instance.new("UIGridLayout")
wLayout.CellSize = UDim2.new(0.48, 0, 0, 30)
wLayout.CellPadding = UDim2.new(0.04, 0, 0, 6)
wLayout.SortOrder = Enum.SortOrder.LayoutOrder
wLayout.Parent = weatherGrid

local CLOUD_PRESETS = {
	{ Name = "Alpine Clear", Preset = "AlpineClear" },
	{ Name = "Fluffy Midday", Preset = "FluffyMidday" },
	{ Name = "Overcast Brood", Preset = "OvercastBrooding" },
	{ Name = "Stormy Tension", Preset = "StormyTension" },
	{ Name = "Milky Way Galaxy", Preset = "MilkyWayNight" },
}

for idx, cp in ipairs(CLOUD_PRESETS) do
	local b = Instance.new("TextButton")
	b.Name = cp.Preset
	b.BackgroundColor3 = Color3.fromRGB(42, 46, 58)
	b.TextColor3 = Color3.fromRGB(230, 235, 245)
	b.Font = Enum.Font.GothamSemibold
	b.TextSize = 11
	b.Text = cp.Name
	b.BorderSizePixel = 0
	b.LayoutOrder = idx
	b.Parent = weatherGrid

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 6)
	corner.Parent = b

	b.Activated:Connect(function()
		local env = getEnvironmentManager()
		if env and env.Clouds then
			env.Clouds.SetPreset(cp.Preset, 1.5)
			print(string.format("[EnvironmentPlugin] Set cloud preset: %s", cp.Preset))
		end
	end)
end

-- -----------------------------------------------------------------------------
-- Card 6: Time Flow Simulation (Play/Pause & Speeds)
-- -----------------------------------------------------------------------------

local simCard = createCard(6, 90)
createSectionTitle(simCard, "⏱️ PREVIEW TIME FLOW")

local simRow = Instance.new("Frame")
simRow.Size = UDim2.new(1, 0, 0, 36)
simRow.Position = UDim2.new(0, 0, 0, 26)
simRow.BackgroundTransparency = 1
simRow.Parent = simCard

local simRowLayout = Instance.new("UIListLayout")
simRowLayout.FillDirection = Enum.FillDirection.Horizontal
simRowLayout.Padding = UDim.new(0, 6)
simRowLayout.SortOrder = Enum.SortOrder.LayoutOrder
simRowLayout.Parent = simRow

local btnPlayPause = Instance.new("TextButton")
btnPlayPause.Size = UDim2.new(0, 110, 1, 0)
btnPlayPause.BackgroundColor3 = Color3.fromRGB(45, 140, 80)
btnPlayPause.TextColor3 = Color3.fromRGB(255, 255, 255)
btnPlayPause.Font = Enum.Font.GothamBold
btnPlayPause.TextSize = 12
btnPlayPause.Text = "▶ PLAY TIME"
btnPlayPause.BorderSizePixel = 0
btnPlayPause.Parent = simRow

local playCorner = Instance.new("UICorner")
playCorner.CornerRadius = UDim.new(0, 6)
playCorner.Parent = btnPlayPause

btnPlayPause.Activated:Connect(function()
	isSimulating = not isSimulating
	if isSimulating then
		btnPlayPause.Text = "⏸ PAUSE"
		btnPlayPause.BackgroundColor3 = Color3.fromRGB(180, 60, 50)
	else
		btnPlayPause.Text = "▶ PLAY TIME"
		btnPlayPause.BackgroundColor3 = Color3.fromRGB(45, 140, 80)
	end
end)

local speeds = {
	{ Label = "1x", Val = 1.0 },
	{ Label = "10x", Val = 10.0 },
	{ Label = "60x", Val = 60.0 },
	{ Label = "360x", Val = 360.0 },
}

local speedButtons: { [number]: TextButton } = {}

for _, spd in ipairs(speeds) do
	local b = Instance.new("TextButton")
	b.Size = UDim2.new(0, 42, 1, 0)
	b.BackgroundColor3 = (spd.Val == simSpeed) and Color3.fromRGB(255, 150, 50) or Color3.fromRGB(40, 42, 52)
	b.TextColor3 = (spd.Val == simSpeed) and Color3.fromRGB(20, 20, 24) or Color3.fromRGB(210, 215, 225)
	b.Font = Enum.Font.GothamBold
	b.TextSize = 11
	b.Text = spd.Label
	b.BorderSizePixel = 0
	b.Parent = simRow

	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, 6)
	c.Parent = b

	speedButtons[spd.Val] = b

	b.Activated:Connect(function()
		simSpeed = spd.Val
		for val, btn in pairs(speedButtons) do
			if val == simSpeed then
				btn.BackgroundColor3 = Color3.fromRGB(255, 150, 50)
				btn.TextColor3 = Color3.fromRGB(20, 20, 24)
			else
				btn.BackgroundColor3 = Color3.fromRGB(40, 42, 52)
				btn.TextColor3 = Color3.fromRGB(210, 215, 225)
			end
		end
	end)
end

-- -----------------------------------------------------------------------------
-- RunService Step for Time Simulation & Dynamic Refresh
-- -----------------------------------------------------------------------------

RunService.Heartbeat:Connect(function(dt: number)
	if isSimulating then
		local advanceHours = (dt * simSpeed) / 3600 -- simSpeed real seconds = 1 hour
		local newHour = (currentHour + advanceHours) % 24
		applyTime(newHour, currentDay, false)
		updateSliderVisual(newHour)
		updateUIElements()
	end
end)

-- Initial Sync
applyTime(14.0, 0, false)
updateSliderVisual(14.0)
updateDayButtonsVisual()
updateUIElements()

print("[EnvironmentPlugin] World Time & Atmosphere Controller Plugin Loaded!")
