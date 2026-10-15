--!strict
--[[
    SurvivorWardrobe.lua
    Luxury First-Class Survivor Selection Interface for "Don't Let the Fire Die".
    Developed for Fluenosity Studio.

    Features:
    - 4 Curated Survivor Characters: Sophie (Female), Jody (Female), Bryce (Male), Remy (Male)
    - Anti-Zombie Dynamic 3D Viewport: Real-time Mixamo animation playback in ViewportFrame
    - Production-Grade Loading Veil: Animated Ember Spinner prevents raw T-pose and texture pop-in
    - Idle Animation Switcher: Seamlessly toggle between Main Idle, Relaxed Tilt, and Check Nails
    - Interactive 360° Turntable: Click & drag to rotate survivor with smooth inertial damping
    - Luxury Obsidian / Ember Glassmorphism with Lucide vector iconography
    - Live Dossier with Specialization Bio & Calibrated Stat Bars (Agility, Combat, Endurance, Crafting)
    - Fully Responsive (Desktop & Mobile viewport scaling)
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ContentProvider = game:GetService("ContentProvider")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local sharedFolder = ReplicatedStorage:WaitForChild("FluenosityShared")
local Config = require(sharedFolder:WaitForChild("SurvivorWardrobeConfig"))
local Applier = require(sharedFolder:WaitForChild("SurvivorWardrobeApplier"))
local SurvivorRigConfig = require(sharedFolder:WaitForChild("SurvivorRigConfig"))
local roster = sharedFolder:WaitForChild("SurvivorRoster")

local Wardrobe = {}

local IDLE_ANIMATIONS: { [string]: string } = {
	["Relaxed Tilt"] = "rbxassetid://89629385542634",
	["Main Idle"] = "rbxassetid://79030538201747",
	["Check Nails"] = "rbxassetid://81640445815841",
}

local function makeText(
	parent: Instance,
	text: string,
	size: number,
	color: Color3,
	font: Enum.Font,
	z: number,
	xAlign: Enum.TextXAlignment?
): TextLabel
	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Text = text
	label.TextColor3 = color
	label.TextSize = size
	label.Font = font
	label.TextXAlignment = xAlign or Enum.TextXAlignment.Left
	label.TextYAlignment = Enum.TextYAlignment.Center
	label.TextWrapped = true
	label.ZIndex = z
	label.Parent = parent
	return label
end

local function makeButton(
	parent: Instance,
	text: string,
	size: UDim2,
	z: number,
	UI: any,
	onClick: () -> ()
): TextButton
	local button = Instance.new("TextButton")
	button.Size = size
	button.AutoButtonColor = false
	button.Text = text
	button.TextColor3 = UI.Theme.Colors.TextPrimary
	button.TextSize = 12
	button.Font = UI.Theme.Fonts.Heading
	button.BackgroundColor3 = UI.Theme.Colors.GlassSurface
	button.BackgroundTransparency = 0.28
	button.BorderSizePixel = 0
	button.ZIndex = z
	button.Parent = parent

	UI.Theme.ApplyGlass(button, {
		CornerRadius = 8,
		StrokeColor = UI.Theme.Colors.BorderSubtle,
		StrokeThickness = 1,
	})

	button.Activated:Connect(function()
		UI.Theme.PlayClick()
		onClick()
	end)

	button.MouseEnter:Connect(function()
		button.BackgroundTransparency = 0.12
	end)

	button.MouseLeave:Connect(function()
		button.BackgroundTransparency = 0.28
	end)

	return button
end

function Wardrobe.Create(screenGui: ScreenGui, UI: any, theme: any)
	local state = {
		SelectedCharacterId = "Sophie",
		SelectedFilter = "ALL", -- "ALL" | "FEMALE" | "MALE"
		CurrentIdleName = "Relaxed Tilt",
		RotationY = math.rad(15),
		TargetRotationY = math.rad(15),
		IsDragging = false,
		DragStartX = 0,
		DragStartRot = 0,
		OnBack = nil :: (() -> ())?,
		OnConfirm = nil :: ((any) -> ())?,
		IsOpen = false,
	}

	-- Background Asset Preloading (All 4 characters, all textures and all idles cached upfront)
	task.spawn(function()
		local toPreload: { Instance } = {}
		for _, charId in ipairs(Config.CharacterOrder) do
			local m = roster:FindFirstChild(charId)
			if m then
				table.insert(toPreload, m)
				for _, d in ipairs(m:GetDescendants()) do
					table.insert(toPreload, d)
				end
			end
		end
		for _, animId in pairs(IDLE_ANIMATIONS) do
			local a = Instance.new("Animation")
			a.AnimationId = animId
			table.insert(toPreload, a)
		end
		pcall(function()
			ContentProvider:PreloadAsync(toPreload)
		end)
	end)

	-- Root Fullscreen Overlay
	local overlay = Instance.new("Frame")
	overlay.Name = "SurvivorWardrobe"
	overlay.Size = UDim2.fromScale(1, 1)
	overlay.BackgroundColor3 = UI.Theme.Colors.GlassBackdrop
	overlay.BackgroundTransparency = 0.16
	overlay.BorderSizePixel = 0
	overlay.Visible = false
	overlay.ZIndex = 70
	overlay.Parent = screenGui

	-- Main Central Luxury Glass Panel
	local panel = Instance.new("Frame")
	panel.Name = "WardrobePanel"
	panel.Size = UDim2.fromScale(0.94, 0.90)
	panel.Position = UDim2.fromScale(0.5, 0.5)
	panel.AnchorPoint = Vector2.new(0.5, 0.5)
	panel.BackgroundColor3 = UI.Theme.Colors.GlassModal
	panel.BackgroundTransparency = 0.08
	panel.BorderSizePixel = 0
	panel.ZIndex = 71
	panel.Parent = overlay

	UI.Theme.ApplyGlass(panel, {
		CornerRadius = 16,
		StrokeColor = UI.Theme.Colors.BorderGlow,
		StrokeThickness = 1.4,
	})

	local sizeConstraint = Instance.new("UISizeConstraint")
	sizeConstraint.MinSize = Vector2.new(340, 420)
	sizeConstraint.MaxSize = Vector2.new(1220, 800)
	sizeConstraint.Parent = panel

	-- Header Tag & Title
	local headerTag = makeText(panel, "[ SURVIVOR PREPARATION ]", 10, UI.Theme.Colors.EmberHot, UI.Theme.Fonts.Heading, 72)
	headerTag.Position = UDim2.new(0.035, 0, 0.022, 0)
	headerTag.Size = UDim2.new(0.8, 0, 0, 14)

	local header = makeText(panel, "CHOOSE YOUR SURVIVOR", 22, UI.Theme.Colors.TextPrimary, UI.Theme.Fonts.Title, 72)
	header.Position = UDim2.new(0.035, 0, 0.048, 0)
	header.Size = UDim2.new(0.8, 0, 0, 28)

	-- Hairline Divider
	local headerDiv = Instance.new("Frame")
	headerDiv.Name = "HeaderDivider"
	headerDiv.Size = UDim2.new(0.93, 0, 0, 1)
	headerDiv.Position = UDim2.new(0.035, 0, 0.095, 0)
	headerDiv.BackgroundColor3 = UI.Theme.Colors.BorderSubtle
	headerDiv.BackgroundTransparency = 0.5
	headerDiv.BorderSizePixel = 0
	headerDiv.ZIndex = 72
	headerDiv.Parent = panel

	----------------------------------------------------------------------------
	-- LEFT SIDE: 3D CHARACTER PREVIEW PANEL
	----------------------------------------------------------------------------
	local previewPanel = Instance.new("Frame")
	previewPanel.Name = "PreviewPanel"
	previewPanel.Position = UDim2.new(0.035, 0, 0.115, 0)
	previewPanel.Size = UDim2.new(0.41, 0, 0.85, 0)
	previewPanel.BackgroundColor3 = UI.Theme.Colors.GlassSurface
	previewPanel.BackgroundTransparency = 0.38
	previewPanel.BorderSizePixel = 0
	previewPanel.ZIndex = 72
	previewPanel.ClipsDescendants = true
	previewPanel.Parent = panel

	UI.Theme.ApplyGlass(previewPanel, {
		CornerRadius = 14,
		StrokeColor = UI.Theme.Colors.BorderSubtle,
		StrokeThickness = 1.2,
	})

	local viewport = Instance.new("ViewportFrame")
	viewport.Name = "CharacterViewport"
	viewport.Size = UDim2.fromScale(1, 1)
	viewport.BackgroundTransparency = 1
	viewport.Ambient = Color3.fromRGB(185, 190, 205)
	viewport.LightColor = Color3.fromRGB(255, 175, 110)
	viewport.LightDirection = Vector3.new(-1, -1.8, -1.2)
	viewport.ZIndex = 73
	viewport.Parent = previewPanel

	local worldModel = Instance.new("WorldModel")
	worldModel.Parent = viewport

	local previewCamera = Instance.new("Camera")
	previewCamera.FieldOfView = 30
	previewCamera.Parent = viewport
	viewport.CurrentCamera = previewCamera

	-- Subtle Rim Background Glow in Preview
	local rimGlow = Instance.new("ImageLabel")
	rimGlow.Name = "RimGlow"
	rimGlow.Size = UDim2.fromScale(1.2, 1.2)
	rimGlow.Position = UDim2.fromScale(0.5, 0.6)
	rimGlow.AnchorPoint = Vector2.new(0.5, 0.5)
	rimGlow.BackgroundTransparency = 1
	rimGlow.Image = "rbxasset://textures/particles/sparkles_main.dds"
	rimGlow.ImageColor3 = UI.Theme.Colors.EmberHot
	rimGlow.ImageTransparency = 0.88
	rimGlow.ZIndex = 72
	rimGlow.Parent = previewPanel

	-- Character Name & Tag overlay inside preview
	local previewInfoBox = Instance.new("Frame")
	previewInfoBox.Name = "PreviewInfoBox"
	previewInfoBox.Size = UDim2.new(0.90, 0, 0, 60)
	previewInfoBox.Position = UDim2.new(0.05, 0, 0.03, 0)
	previewInfoBox.BackgroundTransparency = 1
	previewInfoBox.ZIndex = 75
	previewInfoBox.Parent = previewPanel

	local characterName = makeText(previewInfoBox, "SOPHIE", 22, UI.Theme.Colors.TextPrimary, UI.Theme.Fonts.Title, 75)
	characterName.Size = UDim2.new(1, 0, 0, 28)

	local characterRole = makeText(previewInfoBox, "THE AGILE SCOUT", 11, UI.Theme.Colors.EmberHot, UI.Theme.Fonts.Heading, 75)
	characterRole.Position = UDim2.new(0, 0, 0, 28)
	characterRole.Size = UDim2.new(1, 0, 0, 18)

	-- Turntable drag hint
	local dragHint = makeText(previewPanel, "DRAG TO ROTATE 360°", 9, UI.Theme.Colors.TextMuted, UI.Theme.Fonts.Heading, 75, Enum.TextXAlignment.Center)
	dragHint.Position = UDim2.new(0, 0, 0.84, 0)
	dragHint.Size = UDim2.new(1, 0, 0, 14)

	-- Idle Pose Emote Switcher Bar at bottom of preview
	local poseBar = Instance.new("Frame")
	poseBar.Name = "PoseSwitcherBar"
	poseBar.Position = UDim2.new(0.04, 0, 0.89, 0)
	poseBar.Size = UDim2.new(0.92, 0, 0, 36)
	poseBar.BackgroundColor3 = UI.Theme.Colors.GlassElevated
	poseBar.BackgroundTransparency = 0.45
	poseBar.BorderSizePixel = 0
	poseBar.ZIndex = 75
	poseBar.Parent = previewPanel

	UI.Theme.ApplyGlass(poseBar, {
		CornerRadius = 8,
		StrokeColor = UI.Theme.Colors.BorderGlass,
		StrokeThickness = 1,
	})

	local poseBarLayout = Instance.new("UIListLayout")
	poseBarLayout.FillDirection = Enum.FillDirection.Horizontal
	poseBarLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	poseBarLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	poseBarLayout.Padding = UDim.new(0, 6)
	poseBarLayout.Parent = poseBar

	-- Luxury Loading Veil (Anti-T-Pose & Zero Texture Pop-In)
	local previewVeil = Instance.new("Frame")
	previewVeil.Name = "PreviewLoadingVeil"
	previewVeil.Size = UDim2.fromScale(1, 1)
	previewVeil.Position = UDim2.fromScale(0, 0)
	previewVeil.BackgroundColor3 = Color3.fromRGB(10, 11, 14)
	previewVeil.BackgroundTransparency = 0
	previewVeil.BorderSizePixel = 0
	previewVeil.ZIndex = 82
	previewVeil.Visible = false
	previewVeil.Parent = previewPanel

	local veilCorner = Instance.new("UICorner")
	veilCorner.CornerRadius = UDim.new(0, 14)
	veilCorner.Parent = previewVeil

	local veilStroke = Instance.new("UIStroke")
	veilStroke.Color = UI.Theme.Colors.BorderSubtle
	veilStroke.Thickness = 1.2
	veilStroke.Parent = previewVeil

	local spinnerCenter = Instance.new("Frame")
	spinnerCenter.Name = "SpinnerCenter"
	spinnerCenter.Size = UDim2.fromOffset(240, 110)
	spinnerCenter.Position = UDim2.fromScale(0.5, 0.5)
	spinnerCenter.AnchorPoint = Vector2.new(0.5, 0.5)
	spinnerCenter.BackgroundTransparency = 1
	spinnerCenter.ZIndex = 83
	spinnerCenter.Parent = previewVeil

	local spinnerRing = Instance.new("Frame")
	spinnerRing.Name = "SpinnerRing"
	spinnerRing.Size = UDim2.fromOffset(36, 36)
	spinnerRing.Position = UDim2.new(0.5, 0, 0, 18)
	spinnerRing.AnchorPoint = Vector2.new(0.5, 0.5)
	spinnerRing.BackgroundTransparency = 1
	spinnerRing.ZIndex = 84
	spinnerRing.Parent = spinnerCenter

	local srCorner = Instance.new("UICorner")
	srCorner.CornerRadius = UDim.new(1, 0)
	srCorner.Parent = spinnerRing

	local srStroke = Instance.new("UIStroke")
	srStroke.Thickness = 2.8
	srStroke.Color = UI.Theme.Colors.EmberHot
	srStroke.Parent = spinnerRing

	local srGrad = Instance.new("UIGradient")
	srGrad.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0),
		NumberSequenceKeypoint.new(0.4, 0.2),
		NumberSequenceKeypoint.new(0.8, 0.85),
		NumberSequenceKeypoint.new(1, 1),
	})
	srGrad.Parent = srStroke

	local centerDot = Instance.new("Frame")
	centerDot.Name = "CenterEmber"
	centerDot.Size = UDim2.fromOffset(8, 8)
	centerDot.Position = UDim2.fromScale(0.5, 0.5)
	centerDot.AnchorPoint = Vector2.new(0.5, 0.5)
	centerDot.BackgroundColor3 = UI.Theme.Colors.EmberGold
	centerDot.BorderSizePixel = 0
	centerDot.ZIndex = 85
	centerDot.Parent = spinnerRing

	local cdCorner = Instance.new("UICorner")
	cdCorner.CornerRadius = UDim.new(1, 0)
	cdCorner.Parent = centerDot

	local veilTitle = makeText(spinnerCenter, "LOADING SURVIVOR...", 12, UI.Theme.Colors.EmberGold, UI.Theme.Fonts.Heading, 84, Enum.TextXAlignment.Center)
	veilTitle.Position = UDim2.new(0, 0, 0, 48)
	veilTitle.Size = UDim2.new(1, 0, 0, 18)

	local veilSub = makeText(spinnerCenter, "Syncing high-fidelity textures & posture...", 9, UI.Theme.Colors.TextMuted, UI.Theme.Fonts.Body, 84, Enum.TextXAlignment.Center)
	veilSub.Position = UDim2.new(0, 0, 0, 70)
	veilSub.Size = UDim2.new(1, 0, 0, 16)

	----------------------------------------------------------------------------
	-- RIGHT SIDE: SURVIVOR SELECTOR & DOSSIER CONTROLS
	----------------------------------------------------------------------------
	local controls = Instance.new("Frame")
	controls.Name = "WardrobeControls"
	controls.Position = UDim2.new(0.47, 0, 0.115, 0)
	controls.Size = UDim2.new(0.495, 0, 0.85, 0)
	controls.BackgroundTransparency = 1
	controls.ZIndex = 72
	controls.Parent = panel

	-- Filter Row: ALL (4) | FEMALE (2) | MALE (2)
	local filterRow = Instance.new("Frame")
	filterRow.Name = "FilterTabs"
	filterRow.Size = UDim2.new(1, 0, 0, 36)
	filterRow.BackgroundTransparency = 1
	filterRow.ZIndex = 73
	filterRow.Parent = controls

	local filterButtons: { [string]: TextButton } = {}

	-- Survivor Selection Cards Container (4 Cards Grid)
	local cardsContainer = Instance.new("Frame")
	cardsContainer.Name = "SurvivorCards"
	cardsContainer.Position = UDim2.new(0, 0, 0, 44)
	cardsContainer.Size = UDim2.new(1, 0, 0, 168)
	cardsContainer.BackgroundTransparency = 1
	cardsContainer.ZIndex = 73
	cardsContainer.Parent = controls

	local cardsLayout = Instance.new("UIGridLayout")
	cardsLayout.CellSize = UDim2.new(0.488, 0, 0, 76)
	cardsLayout.CellPadding = UDim2.new(0.024, 0, 0, 10)
	cardsLayout.SortOrder = Enum.SortOrder.LayoutOrder
	cardsLayout.Parent = cardsContainer

	-- Survivor Dossier Card (Specialization & Stat Meters)
	local dossierCard = Instance.new("Frame")
	dossierCard.Name = "DossierCard"
	dossierCard.Position = UDim2.new(0, 0, 0, 222)
	dossierCard.Size = UDim2.new(1, 0, 0, 180)
	dossierCard.BackgroundColor3 = UI.Theme.Colors.GlassSurface
	dossierCard.BackgroundTransparency = 0.35
	dossierCard.BorderSizePixel = 0
	dossierCard.ZIndex = 73
	dossierCard.Parent = controls

	UI.Theme.ApplyGlass(dossierCard, {
		CornerRadius = 12,
		StrokeColor = UI.Theme.Colors.BorderSubtle,
		StrokeThickness = 1,
	})

	local dossierPadding = Instance.new("UIPadding")
	dossierPadding.PaddingLeft = UDim.new(0, 16)
	dossierPadding.PaddingRight = UDim.new(0, 16)
	dossierPadding.PaddingTop = UDim.new(0, 12)
	dossierPadding.PaddingBottom = UDim.new(0, 12)
	dossierPadding.Parent = dossierCard

	local dossierTag = makeText(dossierCard, "[ SPECIALIZATION & ATTRIBUTES ]", 10, UI.Theme.Colors.EmberHot, UI.Theme.Fonts.Heading, 74)
	dossierTag.Size = UDim2.new(1, 0, 0, 14)

	local dossierTagline = makeText(dossierCard, "Quick on her feet, alert to the whispering winds.", 11, UI.Theme.Colors.TextPrimary, UI.Theme.Fonts.Heading, 74)
	dossierTagline.Position = UDim2.new(0, 0, 0, 18)
	dossierTagline.Size = UDim2.new(1, 0, 0, 18)

	local dossierDesc = makeText(dossierCard, "Exceptional speed and wilderness awareness. Excels in foraging, reconnaissance, and evading forest threats before they strike.", 10, UI.Theme.Colors.TextMuted, UI.Theme.Fonts.Body, 74)
	dossierDesc.Position = UDim2.new(0, 0, 0, 38)
	dossierDesc.Size = UDim2.new(1, 0, 0, 34)

	local statsContainer = Instance.new("Frame")
	statsContainer.Name = "StatsContainer"
	statsContainer.Position = UDim2.new(0, 0, 0, 78)
	statsContainer.Size = UDim2.new(1, 0, 0, 80)
	statsContainer.BackgroundTransparency = 1
	statsContainer.ZIndex = 74
	statsContainer.Parent = dossierCard

	local statsLayout = Instance.new("UIGridLayout")
	statsLayout.CellSize = UDim2.new(0.485, 0, 0, 34)
	statsLayout.CellPadding = UDim2.new(0.03, 0, 0, 8)
	statsLayout.Parent = statsContainer

	type StatItem = {
		BarFill: Frame,
		ValueLabel: TextLabel,
	}
	local statWidgets: { [string]: StatItem } = {}

	local function createStatBar(statName: string, labelText: string): StatItem
		local row = Instance.new("Frame")
		row.Name = "Stat_" .. statName
		row.BackgroundTransparency = 1
		row.ZIndex = 74
		row.Parent = statsContainer

		local lbl = makeText(row, labelText, 9, UI.Theme.Colors.TextMuted, UI.Theme.Fonts.Heading, 75)
		lbl.Size = UDim2.new(0.7, 0, 0, 12)

		local valLbl = makeText(row, "85%", 9, UI.Theme.Colors.EmberGold, UI.Theme.Fonts.Heading, 75, Enum.TextXAlignment.Right)
		valLbl.Position = UDim2.new(0.7, 0, 0, 0)
		valLbl.Size = UDim2.new(0.3, 0, 0, 12)

		local barBg = Instance.new("Frame")
		barBg.Name = "BarBg"
		barBg.Position = UDim2.new(0, 0, 0, 16)
		barBg.Size = UDim2.new(1, 0, 0, 7)
		barBg.BackgroundColor3 = UI.Theme.Colors.GlassElevated
		barBg.BackgroundTransparency = 0.4
		barBg.BorderSizePixel = 0
		barBg.ZIndex = 75
		barBg.Parent = row

		local bgCorner = Instance.new("UICorner")
		bgCorner.CornerRadius = UDim.new(0, 3)
		bgCorner.Parent = barBg

		local barFill = Instance.new("Frame")
		barFill.Name = "BarFill"
		barFill.Size = UDim2.new(0.5, 0, 1, 0)
		barFill.BackgroundColor3 = UI.Theme.Colors.EmberHot
		barFill.BorderSizePixel = 0
		barFill.ZIndex = 76
		barFill.Parent = barBg

		local fillCorner = Instance.new("UICorner")
		fillCorner.CornerRadius = UDim.new(0, 3)
		fillCorner.Parent = barFill

		return {
			BarFill = barFill,
			ValueLabel = valLbl,
		}
	end

	statWidgets.Agility = createStatBar("Agility", "AGILITY / MOBILITY")
	statWidgets.Combat = createStatBar("Combat", "COMBAT / RESILIENCE")
	statWidgets.Endurance = createStatBar("Endurance", "SURVIVAL ENDURANCE")
	statWidgets.Crafting = createStatBar("Crafting", "CRAFT & REPAIR")

	-- Bottom Navigation Buttons
	local bottomRow = Instance.new("Frame")
	bottomRow.Name = "BottomActionRow"
	bottomRow.Position = UDim2.new(0, 0, 1, -48)
	bottomRow.Size = UDim2.new(1, 0, 0, 46)
	bottomRow.BackgroundTransparency = 1
	bottomRow.ZIndex = 74
	bottomRow.Parent = controls

	local backButton = makeButton(bottomRow, "BACK", UDim2.new(0.32, -6, 1, 0), 75, UI, function()
		Wardrobe.Close()
		if state.OnBack then state.OnBack() end
	end)
	backButton.Name = "BackButton"
	backButton.Position = UDim2.new(0, 0, 0, 0)

	local enterButton = makeButton(bottomRow, "CONFIRM & ENTER WILDERNESS", UDim2.new(0.68, 0, 1, 0), 75, UI, function()
		local validated = Config.ValidateSelection({ CharacterId = state.SelectedCharacterId })
		if not validated then return end
		Wardrobe.Close()
		if state.OnConfirm then state.OnConfirm(validated) end
	end)
	enterButton.Name = "EnterButton"
	enterButton.Position = UDim2.new(0.32, 6, 0, 0)
	enterButton.BackgroundColor3 = UI.Theme.Colors.EmberCrimson
	enterButton.TextColor3 = Color3.fromRGB(255, 245, 235)

	----------------------------------------------------------------------------
	-- INTERACTIVE 360° DRAG ROTATION
	----------------------------------------------------------------------------
	local inputBeganConn: RBXScriptConnection? = nil
	local inputChangedConn: RBXScriptConnection? = nil
	local inputEndedConn: RBXScriptConnection? = nil

	inputBeganConn = previewPanel.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			state.IsDragging = true
			state.DragStartX = input.Position.X
			state.DragStartRot = state.TargetRotationY
		end
	end)

	inputChangedConn = previewPanel.InputChanged:Connect(function(input)
		if state.IsDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			local deltaX = input.Position.X - state.DragStartX
			state.TargetRotationY = state.DragStartRot - (deltaX * 0.015)
		end
	end)

	inputEndedConn = UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			state.IsDragging = false
		end
	end)

	----------------------------------------------------------------------------
	-- LIVE 3D PREVIEW PIPELINE & ANTI-ZOMBIE ENGINE
	----------------------------------------------------------------------------
	type BoneSyncPair = { Source: Bone, Target: Bone }
	local currentSyncPairs: { BoneSyncPair } = {}

	local previewClone: Model? = nil
	local previewAnimator: Animator? = nil
	local previewTrack: AnimationTrack? = nil
	local previewGeneration = 0
	local refreshPreview: () -> ()
	local refreshUI: () -> ()
	local poseButtons: { [string]: TextButton } = {}

	local function showLoadingVeil(titleText: string?)
		if veilTitle then veilTitle.Text = titleText or "LOADING SURVIVOR..." end
		previewVeil.Visible = true
		previewVeil.BackgroundTransparency = 0
	end

	local function hideLoadingVeil()
		if not previewVeil.Visible then return end
		local fade = TweenService:Create(previewVeil, TweenInfo.new(0.24, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			BackgroundTransparency = 1,
		})
		fade:Play()
		fade.Completed:Connect(function()
			if previewVeil.BackgroundTransparency >= 0.98 then
				previewVeil.Visible = false
			end
		end)
	end

	local function applyAntiZombiePose(clone: Model, profile: any)
		-- Safety fallback: Holds relaxed arms and natural stance on bones every frame so it NEVER shows a stiff zombie T-pose
		pcall(function()
			local lArm = clone:FindFirstChild("mixamorig:LeftArm", true)
			local rArm = clone:FindFirstChild("mixamorig:RightArm", true)
			local head = clone:FindFirstChild("mixamorig:Head", true)

			local lArm6 = clone:FindFirstChild("mixamorig6:LeftArm", true)
			local rArm6 = clone:FindFirstChild("mixamorig6:RightArm", true)
			local head6 = clone:FindFirstChild("mixamorig6:Head", true)

			-- Lower arms along torso with natural bend
			if lArm and lArm:IsA("Bone") then
				lArm.Transform = CFrame.Angles(math.rad(10), 0, math.rad(-55))
			end
			if rArm and rArm:IsA("Bone") then
				rArm.Transform = CFrame.Angles(math.rad(10), 0, math.rad(55))
			end
			if head and head:IsA("Bone") and profile and profile.Facial then
				head.Transform = CFrame.Angles(0, 0, math.rad(profile.Facial.HeadRestTiltDeg or 1.5))
			end

			if lArm6 and lArm6:IsA("Bone") and lArm then
				lArm6.Transform = lArm.Transform
			end
			if rArm6 and rArm6:IsA("Bone") and rArm then
				rArm6.Transform = rArm.Transform
			end
			if head6 and head6:IsA("Bone") and head then
				head6.Transform = head.Transform
			end
		end)
	end

	refreshPreview = function()
		previewGeneration += 1
		local generation = previewGeneration

		showLoadingVeil("PREPARING " .. string.upper(state.SelectedCharacterId) .. "...")

		local charDef = Config.Characters[state.SelectedCharacterId]
		if not charDef then
			hideLoadingVeil()
			return
		end

		characterName.Text = string.upper(charDef.DisplayName)
		characterRole.Text = charDef.Role

		task.spawn(function()
			local source = roster:FindFirstChild(charDef.DisplayName) or roster:FindFirstChild(state.SelectedCharacterId)
			if not source or not source:IsA("Model") then
				characterName.Text = "SURVIVOR UNAVAILABLE"
				hideLoadingVeil()
				return
			end

			-- 1. Preload character textures, meshes and materials completely before mounting
			local toPreload: { Instance } = { source }
			for _, d in ipairs(source:GetDescendants()) do
				table.insert(toPreload, d)
			end
			pcall(function()
				ContentProvider:PreloadAsync(toPreload)
			end)
			if generation ~= previewGeneration then return end

			-- Safely clean up previous preview
			if previewTrack then
				previewTrack:Stop(0)
				previewTrack:Destroy()
				previewTrack = nil
			end
			if previewClone then
				previewClone:Destroy()
				previewClone = nil
			end
			previewAnimator = nil
			table.clear(currentSyncPairs)

			local clone = source:Clone()
			clone.Name = "WardrobePreview"

			-- Discover secondary deformer bones (e.g. mixamorig6 for Jody)
			for _, d in ipairs(clone:GetDescendants()) do
				if d:IsA("Bone") and string.find(d.Name, "^mixamorig6:") then
					local baseName = string.gsub(d.Name, "^mixamorig6:", "mixamorig:")
					local sourceBone = clone:FindFirstChild(baseName, true)
					if sourceBone and sourceBone:IsA("Bone") then
						table.insert(currentSyncPairs, { Source = sourceBone, Target = d })
					end
				end
			end

			local profile = SurvivorRigConfig.GetProfile(state.SelectedCharacterId)
			applyAntiZombiePose(clone, profile)

			for _, pair in ipairs(currentSyncPairs) do
				pair.Target.Transform = pair.Source.Transform
			end

			local humanoid = clone:FindFirstChildOfClass("Humanoid")
			local rootPart = clone:FindFirstChild("HumanoidRootPart")
			if humanoid then
				humanoid.AutoRotate = false
				humanoid.WalkSpeed = 0
				humanoid.JumpPower = 0
				humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
				if profile and profile.HipHeight then
					humanoid.HipHeight = profile.HipHeight
				end
				local animator = humanoid:FindFirstChildOfClass("Animator")
				if not animator then
					animator = Instance.new("Animator")
					animator.Parent = humanoid
				end
				previewAnimator = animator
			end

			for _, item in ipairs(clone:GetDescendants()) do
				if item:IsA("BasePart") then
					item.Anchored = item == rootPart
					item.CanCollide = false
					item.CanTouch = false
					item.CastShadow = true
				elseif item:IsA("BaseScript") then
					item:Destroy()
				end
			end

			state.RotationY = math.rad(15)
			state.TargetRotationY = math.rad(15)
			clone:PivotTo(CFrame.new(0, 0, 0) * CFrame.Angles(0, state.RotationY, 0))
			clone.Parent = worldModel
			previewClone = clone

			-- Camera Framing Head-to-Toe with comfortable margin
			local boxCFrame, boxSize = clone:GetBoundingBox()
			local focus = boxCFrame.Position + Vector3.new(0, boxSize.Y * 0.02, 0)
			local distance = math.max(boxSize.Y * 2.18, 8.8)
			previewCamera.CFrame = CFrame.lookAt(focus + Vector3.new(0, boxSize.Y * 0.03, -distance), focus)

			-- 2. Preload and start selected idle animation
			local targetAnimId = IDLE_ANIMATIONS[state.CurrentIdleName] or charDef.RecommendedIdle
			local animation = Instance.new("Animation")
			animation.Name = "WardrobePreviewIdle"
			local numericId = string.match(targetAnimId, "(%d+)")
			animation.AnimationId = if numericId then "rbxassetid://" .. numericId else targetAnimId
			animation.Parent = clone

			pcall(function()
				ContentProvider:PreloadAsync({ animation })
			end)
			if generation ~= previewGeneration or not clone.Parent or not previewAnimator then return end

			local loaded, track = pcall(function()
				return previewAnimator:LoadAnimation(animation)
			end)
			if loaded and track then
				track.Priority = Enum.AnimationPriority.Idle
				track.Looped = true
				track:Play(0)
				previewTrack = track

				local t0 = os.clock()
				while track.Length == 0 and os.clock() - t0 < 1.2 do
					task.wait(0.03)
				end
				if generation ~= previewGeneration or not clone.Parent then
					track:Destroy()
					return
				end
				pcall(function()
					previewAnimator:StepAnimations(0.05)
				end)
				for _, pair in ipairs(currentSyncPairs) do
					pair.Target.Transform = pair.Source.Transform
				end
			end

			-- Ensure GPU renders textured, posed frame before revealing (Zero pop-in guarantee)
			RunService.RenderStepped:Wait()
			RunService.RenderStepped:Wait()
			if generation == previewGeneration then
				hideLoadingVeil()
			end
		end)
	end

	----------------------------------------------------------------------------
	-- POSE SWITCHER BUTTONS SETUP
	----------------------------------------------------------------------------
	local poseOptions = { "Relaxed Tilt", "Main Idle", "Check Nails" }
	for _, poseName in ipairs(poseOptions) do
		local btn = Instance.new("TextButton")
		btn.Name = "PoseBtn_" .. string.gsub(poseName, "%s+", "")
		btn.Size = UDim2.new(0.31, -2, 1, -6)
		btn.AutoButtonColor = false
		btn.Text = string.upper(poseName)
		btn.TextColor3 = UI.Theme.Colors.TextPrimary
		btn.TextSize = 9
		btn.Font = UI.Theme.Fonts.Heading
		btn.BackgroundColor3 = UI.Theme.Colors.GlassSurface
		btn.BackgroundTransparency = 0.4
		btn.BorderSizePixel = 0
		btn.ZIndex = 76
		btn.Parent = poseBar

		UI.Theme.ApplyGlass(btn, {
			CornerRadius = 6,
			StrokeColor = UI.Theme.Colors.BorderGlass,
			StrokeThickness = 1,
		})

		btn.Activated:Connect(function()
			UI.Theme.PlayClick()
			state.CurrentIdleName = poseName
			refreshUI()
			local animId = IDLE_ANIMATIONS[poseName]
			if animId and previewAnimator and previewClone then
				local animation = Instance.new("Animation")
				animation.Name = "WardrobePreviewIdle"
				local numericId = string.match(animId, "(%d+)")
				animation.AnimationId = if numericId then "rbxassetid://" .. numericId else animId
				animation.Parent = previewClone

				task.spawn(function()
					local myGen = previewGeneration
					local loaded, track = pcall(function()
						return previewAnimator:LoadAnimation(animation)
					end)
					if loaded and track and myGen == previewGeneration and previewClone and previewClone.Parent then
						if previewTrack then
							previewTrack:Stop(0.18)
							previewTrack:Destroy()
						end
						track.Priority = Enum.AnimationPriority.Idle
						track.Looped = true
						track:Play(0.2)
						previewTrack = track
						pcall(function()
							previewAnimator:StepAnimations(0.05)
						end)
						if #currentSyncPairs > 0 then
							for _, pair in ipairs(currentSyncPairs) do
								pair.Target.Transform = pair.Source.Transform
							end
						end
					end
				end)
			end
		end)

		poseButtons[poseName] = btn
	end

	----------------------------------------------------------------------------
	-- SURVIVOR CARDS SETUP
	----------------------------------------------------------------------------
	type CardWidget = {
		Button: TextButton,
		TitleLabel: TextLabel,
		RoleLabel: TextLabel,
		BadgeText: TextLabel,
		Stroke: UIStroke?,
		GenderTag: TextLabel,
	}
	local survivorCardWidgets: { [string]: CardWidget } = {}

	for orderIndex, charId in ipairs(Config.CharacterOrder) do
		local charDef = Config.Characters[charId]
		local cardBtn = Instance.new("TextButton")
		cardBtn.Name = "Card_" .. charId
		cardBtn.LayoutOrder = orderIndex
		cardBtn.AutoButtonColor = false
		cardBtn.Text = ""
		cardBtn.BackgroundColor3 = UI.Theme.Colors.GlassSurface
		cardBtn.BackgroundTransparency = 0.35
		cardBtn.BorderSizePixel = 0
		cardBtn.ZIndex = 74
		cardBtn.Parent = cardsContainer

		UI.Theme.ApplyGlass(cardBtn, {
			CornerRadius = 10,
			StrokeColor = UI.Theme.Colors.BorderSubtle,
			StrokeThickness = 1.2,
		})

		local cStroke = cardBtn:FindFirstChildOfClass("UIStroke")

		-- Left Avatar Box
		local avBox = Instance.new("Frame")
		avBox.Name = "AvatarBox"
		avBox.Size = UDim2.fromOffset(38, 38)
		avBox.Position = UDim2.new(0, 10, 0.5, 0)
		avBox.AnchorPoint = Vector2.new(0, 0.5)
		avBox.BackgroundColor3 = UI.Theme.Colors.GlassElevated
		avBox.BackgroundTransparency = 0.35
		avBox.ZIndex = 75
		avBox.Parent = cardBtn

		local avCorner = Instance.new("UICorner")
		avCorner.CornerRadius = UDim.new(0, 8)
		avCorner.Parent = avBox

		local avLetter = makeText(avBox, string.sub(charDef.DisplayName, 1, 1), 16, UI.Theme.Colors.EmberGold, UI.Theme.Fonts.Title, 76, Enum.TextXAlignment.Center)
		avLetter.Size = UDim2.fromScale(1, 1)

		-- Info text
		local tLbl = makeText(cardBtn, string.upper(charDef.DisplayName), 13, UI.Theme.Colors.TextPrimary, UI.Theme.Fonts.Title, 75)
		tLbl.Position = UDim2.new(0, 56, 0, 12)
		tLbl.Size = UDim2.new(1, -80, 0, 18)

		local rLbl = makeText(cardBtn, charDef.Role, 9, UI.Theme.Colors.EmberHot, UI.Theme.Fonts.Heading, 75)
		rLbl.Position = UDim2.new(0, 56, 0, 30)
		rLbl.Size = UDim2.new(1, -80, 0, 14)

		local gTag = makeText(cardBtn, string.upper(charDef.Gender), 8, UI.Theme.Colors.TextMuted, UI.Theme.Fonts.Heading, 75)
		gTag.Position = UDim2.new(0, 56, 0, 46)
		gTag.Size = UDim2.new(1, -80, 0, 14)

		-- Status Badge
		local badge = Instance.new("Frame")
		badge.Name = "StatusBadge"
		badge.Size = UDim2.new(0, 64, 0, 24)
		badge.Position = UDim2.new(1, -10, 0.5, 0)
		badge.AnchorPoint = Vector2.new(1, 0.5)
		badge.BackgroundColor3 = UI.Theme.Colors.GlassElevated
		badge.BackgroundTransparency = 0.4
		badge.BorderSizePixel = 0
		badge.ZIndex = 75
		badge.Parent = cardBtn

		local bCorner = Instance.new("UICorner")
		bCorner.CornerRadius = UDim.new(0, 6)
		bCorner.Parent = badge

		local bStroke = Instance.new("UIStroke")
		bStroke.Thickness = 1.0
		bStroke.Color = UI.Theme.Colors.BorderGlass
		bStroke.Parent = badge

		local bText = makeText(badge, "SELECT", 9, UI.Theme.Colors.TextMuted, UI.Theme.Fonts.Heading, 76, Enum.TextXAlignment.Center)
		bText.Size = UDim2.fromScale(1, 1)

		cardBtn.Activated:Connect(function()
			if state.SelectedCharacterId ~= charId then
				state.SelectedCharacterId = charId
				state.CurrentIdleName = charDef.RecommendedIdle == IDLE_ANIMATIONS["Relaxed Tilt"] and "Relaxed Tilt" or "Main Idle"
				UI.Theme.PlayClick()
				refreshUI()
				refreshPreview()
			end
		end)

		cardBtn.MouseEnter:Connect(function()
			if state.SelectedCharacterId ~= charId then
				cardBtn.BackgroundTransparency = 0.20
			end
		end)

		cardBtn.MouseLeave:Connect(function()
			if state.SelectedCharacterId ~= charId then
				cardBtn.BackgroundTransparency = 0.35
			end
		end)

		survivorCardWidgets[charId] = {
			Button = cardBtn,
			TitleLabel = tLbl,
			RoleLabel = rLbl,
			BadgeText = bText,
			Stroke = cStroke,
			GenderTag = gTag,
		}
	end

	----------------------------------------------------------------------------
	-- FILTER BUTTONS SETUP (ALL, FEMALE, MALE)
	----------------------------------------------------------------------------
	local filterDefs = {
		{ Id = "ALL", Label = "ALL SURVIVORS (4)", Width = 0.36 },
		{ Id = "FEMALE", Label = "FEMALE (2)", Width = 0.31 },
		{ Id = "MALE", Label = "MALE (2)", Width = 0.31 },
	}

	local currentX = 0
	for _, fDef in ipairs(filterDefs) do
		local btn = Instance.new("TextButton")
		btn.Name = "Filter_" .. fDef.Id
		btn.Size = UDim2.new(fDef.Width, -4, 1, 0)
		btn.Position = UDim2.new(currentX, 0, 0, 0)
		btn.AutoButtonColor = false
		btn.Text = fDef.Label
		btn.TextColor3 = UI.Theme.Colors.TextPrimary
		btn.TextSize = 10
		btn.Font = UI.Theme.Fonts.Heading
		btn.BackgroundColor3 = UI.Theme.Colors.GlassSurface
		btn.BackgroundTransparency = 0.35
		btn.BorderSizePixel = 0
		btn.ZIndex = 74
		btn.Parent = filterRow

		UI.Theme.ApplyGlass(btn, {
			CornerRadius = 8,
			StrokeColor = UI.Theme.Colors.BorderSubtle,
			StrokeThickness = 1,
		})

		btn.Activated:Connect(function()
			UI.Theme.PlayClick()
			state.SelectedFilter = fDef.Id
			refreshUI()
		end)

		filterButtons[fDef.Id] = btn
		currentX += fDef.Width
	end

	----------------------------------------------------------------------------
	-- UI REFRESH (CARDS, DOSSIER, STATS, TABS)
	----------------------------------------------------------------------------
	refreshUI = function()
		local activeDef = Config.Characters[state.SelectedCharacterId]
		if not activeDef then return end

		-- 1. Filter tabs highlight
		for fId, btn in pairs(filterButtons) do
			local isActive = state.SelectedFilter == fId
			btn.BackgroundColor3 = isActive and Color3.fromRGB(48, 28, 20) or UI.Theme.Colors.GlassSurface
			btn.BackgroundTransparency = isActive and 0.12 or 0.35
			local stroke = btn:FindFirstChildOfClass("UIStroke")
			if stroke then
				stroke.Color = isActive and UI.Theme.Colors.BorderGlow or UI.Theme.Colors.BorderSubtle
				stroke.Thickness = isActive and 1.6 or 1.0
			end
		end

		-- 2. Survivor Cards visibility & active glow
		for charId, widget in pairs(survivorCardWidgets) do
			local charDef = Config.Characters[charId]
			local matchesFilter = (state.SelectedFilter == "ALL") or (string.upper(charDef.Gender) == state.SelectedFilter)
			widget.Button.Visible = matchesFilter

			local isSelected = (state.SelectedCharacterId == charId)
			if isSelected then
				widget.Button.BackgroundColor3 = Color3.fromRGB(46, 26, 18)
				widget.Button.BackgroundTransparency = 0.14
				if widget.Stroke then
					widget.Stroke.Color = UI.Theme.Colors.BorderGlow
					widget.Stroke.Thickness = 1.8
				end
				widget.TitleLabel.TextColor3 = UI.Theme.Colors.EmberGold
				widget.RoleLabel.TextColor3 = Color3.fromRGB(255, 160, 90)
				widget.BadgeText.Text = "✔ ACTIVE"
				widget.BadgeText.TextColor3 = UI.Theme.Colors.EmberGold
			else
				widget.Button.BackgroundColor3 = UI.Theme.Colors.GlassSurface
				widget.Button.BackgroundTransparency = 0.35
				if widget.Stroke then
					widget.Stroke.Color = UI.Theme.Colors.BorderSubtle
					widget.Stroke.Thickness = 1.0
				end
				widget.TitleLabel.TextColor3 = UI.Theme.Colors.TextPrimary
				widget.RoleLabel.TextColor3 = UI.Theme.Colors.EmberHot
				widget.BadgeText.Text = "SELECT"
				widget.BadgeText.TextColor3 = UI.Theme.Colors.TextMuted
			end
		end

		-- 3. Dossier text
		dossierTagline.Text = activeDef.Tagline
		dossierDesc.Text = activeDef.Description

		-- 4. Stat bars
		local stats = activeDef.Stats
		for statName, widget in pairs(statWidgets) do
			local val = stats[statName] or 50
			widget.ValueLabel.Text = tostring(val) .. "%"
			TweenService:Create(widget.BarFill, TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				Size = UDim2.new(val / 100, 0, 1, 0),
			}):Play()
		end

		-- 5. Pose buttons highlight
		for pName, btn in pairs(poseButtons) do
			local isCurrent = (state.CurrentIdleName == pName)
			btn.BackgroundColor3 = isCurrent and Color3.fromRGB(56, 32, 20) or UI.Theme.Colors.GlassSurface
			btn.BackgroundTransparency = isCurrent and 0.12 or 0.4
			btn.TextColor3 = isCurrent and UI.Theme.Colors.EmberGold or UI.Theme.Colors.TextPrimary
			local stroke = btn:FindFirstChildOfClass("UIStroke")
			if stroke then
				stroke.Color = isCurrent and UI.Theme.Colors.BorderGlow or UI.Theme.Colors.BorderGlass
			end
		end
	end

	----------------------------------------------------------------------------
	-- CONTINUOUS RENDERSTEPPED LOOP (Turntable Rotation, Spinner & Anti-Zombie Hold)
	----------------------------------------------------------------------------
	local renderSteppedConn: RBXScriptConnection? = nil
	renderSteppedConn = RunService.RenderStepped:Connect(function(dt: number)
		if not state.IsOpen then return end

		-- 1. Rotate loading spinner ring if veil is visible
		if previewVeil.Visible then
			spinnerRing.Rotation = (spinnerRing.Rotation + dt * 300) % 360
		end

		if not previewClone or not previewClone.Parent then return end

		-- 2. Inertial turntable rotation
		if not state.IsDragging then
			state.TargetRotationY += dt * 0.035
		end
		state.RotationY += (state.TargetRotationY - state.RotationY) * math.clamp(dt * 12, 0, 1)

		local rootPart = previewClone:FindFirstChild("HumanoidRootPart")
		if rootPart then
			previewClone:PivotTo(CFrame.new(0, 0, 0) * CFrame.Angles(0, state.RotationY, 0))
		end

		-- 3. Step animator so animations update with 100% reliability in ViewportFrame
		local profile = SurvivorRigConfig.GetProfile(state.SelectedCharacterId)
		if previewAnimator and previewTrack and previewTrack.IsPlaying then
			pcall(function()
				previewAnimator:StepAnimations(dt)
			end)
		else
			-- If animation track is loading or not playing, maintain natural relaxed stance every frame (Anti-T-Pose)
			applyAntiZombiePose(previewClone, profile)
		end

		-- Posture adjustment: Arch thoracic spine to elaborate chest, level gaze, and retract shoulders
		if profile and profile.Posture then
			local posture = profile.Posture
			local s1 = previewClone:FindFirstChild("mixamorig:Spine1", true)
			local s2 = previewClone:FindFirstChild("mixamorig:Spine2", true)
			local neck = previewClone:FindFirstChild("mixamorig:Neck", true)
			local lSh = previewClone:FindFirstChild("mixamorig:LeftShoulder", true)
			local rSh = previewClone:FindFirstChild("mixamorig:RightShoulder", true)

			if s1 and s1:IsA("Bone") and posture.Spine1ArchDeg then
				s1.Transform = s1.Transform * CFrame.Angles(math.rad(posture.Spine1ArchDeg), 0, 0)
			end
			if s2 and s2:IsA("Bone") and posture.Spine2ArchDeg then
				s2.Transform = s2.Transform * CFrame.Angles(math.rad(posture.Spine2ArchDeg), 0, 0)
			end
			if neck and neck:IsA("Bone") and posture.NeckCounterDeg then
				neck.Transform = neck.Transform * CFrame.Angles(math.rad(posture.NeckCounterDeg), 0, 0)
			end
			if lSh and lSh:IsA("Bone") and posture.ShoulderRetractDeg then
				lSh.Transform = lSh.Transform * CFrame.Angles(0, math.rad(-posture.ShoulderRetractDeg), math.rad(posture.ShoulderRetractDeg * 0.8))
			end
			if rSh and rSh:IsA("Bone") and posture.ShoulderRetractDeg then
				rSh.Transform = rSh.Transform * CFrame.Angles(0, math.rad(posture.ShoulderRetractDeg), math.rad(-posture.ShoulderRetractDeg * 0.8))
			end
		end

		-- 4. Continuous bone synchronization for aliased deformer rigs (e.g. mixamorig6 for Jody)
		if #currentSyncPairs > 0 then
			for _, pair in ipairs(currentSyncPairs) do
				pair.Target.Transform = pair.Source.Transform
			end
		end
	end)

	----------------------------------------------------------------------------
	-- RESPONSIVE LAYOUT
	----------------------------------------------------------------------------
	local camera = workspace.CurrentCamera
	local viewportResizeConn: RBXScriptConnection? = nil
	local function updateResponsive()
		camera = workspace.CurrentCamera or camera
		local vpSize = camera and camera.ViewportSize or Vector2.new(1280, 720)
		if vpSize.X < 760 then
			panel.Size = UDim2.fromScale(0.96, 0.94)
			previewPanel.Position = UDim2.new(0.03, 0, 0.10, 0)
			previewPanel.Size = UDim2.new(0.94, 0, 0.36, 0)
			controls.Position = UDim2.new(0.03, 0, 0.48, 0)
			controls.Size = UDim2.new(0.94, 0, 0.50, 0)
			cardsContainer.Size = UDim2.new(1, 0, 0, 120)
			cardsLayout.CellSize = UDim2.new(0.485, 0, 0, 54)
			dossierCard.Position = UDim2.new(0, 0, 0, 170)
			dossierCard.Size = UDim2.new(1, 0, 0, 130)
		else
			panel.Size = UDim2.fromScale(0.94, 0.90)
			previewPanel.Position = UDim2.new(0.035, 0, 0.115, 0)
			previewPanel.Size = UDim2.new(0.41, 0, 0.85, 0)
			controls.Position = UDim2.new(0.47, 0, 0.115, 0)
			controls.Size = UDim2.new(0.495, 0, 0.85, 0)
			cardsContainer.Size = UDim2.new(1, 0, 0, 168)
			cardsLayout.CellSize = UDim2.new(0.488, 0, 0, 76)
			dossierCard.Position = UDim2.new(0, 0, 0, 222)
			dossierCard.Size = UDim2.new(1, 0, 0, 180)
		end
	end
	updateResponsive()
	if camera then
		viewportResizeConn = camera:GetPropertyChangedSignal("ViewportSize"):Connect(updateResponsive)
	end

	----------------------------------------------------------------------------
	-- PUBLIC INTERFACE
	----------------------------------------------------------------------------
	Wardrobe.Open = function(onBack: () -> (), onConfirm: (any) -> ())
		state.OnBack = onBack
		state.OnConfirm = onConfirm
		state.IsOpen = true
		overlay.Visible = true
		refreshUI()
		refreshPreview()
		UI.Theme.PlayClick()
	end

	Wardrobe.Close = function()
		state.IsOpen = false
		overlay.Visible = false
	end

	Wardrobe.Destroy = function()
		Wardrobe.Close()
		previewGeneration += 1
		if previewTrack then
			previewTrack:Stop(0)
			previewTrack:Destroy()
			previewTrack = nil
		end
		if previewClone then
			previewClone:Destroy()
			previewClone = nil
		end
		if renderSteppedConn then
			renderSteppedConn:Disconnect()
			renderSteppedConn = nil
		end
		if viewportResizeConn then
			viewportResizeConn:Disconnect()
			viewportResizeConn = nil
		end
		if inputBeganConn then inputBeganConn:Disconnect() end
		if inputChangedConn then inputChangedConn:Disconnect() end
		if inputEndedConn then inputEndedConn:Disconnect() end
		overlay:Destroy()
	end

	Wardrobe.GetSelection = function()
		return Config.ValidateSelection({ CharacterId = state.SelectedCharacterId })
	end

	Wardrobe.Panel = panel
	return Wardrobe
end

return Wardrobe
