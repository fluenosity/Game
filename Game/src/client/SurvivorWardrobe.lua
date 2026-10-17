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
local SocialService = game:GetService("SocialService")
local ModalManager = require(script.Parent:WaitForChild("ModalManager"))

local player = Players.LocalPlayer
local sharedFolder = ReplicatedStorage:WaitForChild("FluenosityShared")
local Config = require(sharedFolder:WaitForChild("SurvivorWardrobeConfig"))
local Applier = require(sharedFolder:WaitForChild("SurvivorWardrobeApplier"))
local SurvivorRigConfig = require(sharedFolder:WaitForChild("SurvivorRigConfig"))
local roster = sharedFolder:WaitForChild("SurvivorRoster")

local Wardrobe = {}

local IDLE_ANIMATIONS: { [string]: string } = {
	["Static Resting Idle"] = "rbxassetid://103828063959982",
	["Breathing Shift"] = "rbxassetid://132876566376642",
	["Observant Gaze"] = "rbxassetid://137772468102995",
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
		CurrentIdleName = "Static Resting Idle",
		RotationY = math.rad(15),
		TargetRotationY = math.rad(15),
		IsDragging = false,
		DragStartX = 0,
		DragStartRot = 0,
		OnBack = nil :: (() -> ())?,
		OnConfirm = nil :: ((any) -> ())?,
		HideOverlayForReturn = nil :: (() -> ())?,
		IsOpen = false,
		IsReturning = false,
		BackButtons = {} :: { TextButton },
	}

	local function requestBack()
		if not state.IsOpen or state.IsReturning then return end
		state.IsReturning = true
		for _, button in ipairs(state.BackButtons) do
			button.Active = false
			button.Selectable = false
			button.Text = "RETURNING..."
		end
		if state.HideOverlayForReturn then
			state.HideOverlayForReturn()
		end
		if state.OnBack then
			state.OnBack()
		else
			Wardrobe.Close()
		end
	end

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
	overlay.Name = "SurvivorPicker"
	overlay.Size = UDim2.fromScale(1, 1)
	overlay.BackgroundColor3 = UI.Theme.Colors.GlassBackdrop
    overlay.BackgroundTransparency = 1 -- Keep the live campsite visible behind the survivor preview.
	overlay.BorderSizePixel = 0
	overlay.Visible = false
	overlay.ZIndex = 70
	overlay.Parent = screenGui
	-- Fullscreen scrim used to fade the wardrobe out smoothly on back-transition.
	local returnScrim = Instance.new("Frame")
	returnScrim.Name = "ReturnScrim"
	returnScrim.Size = UDim2.fromScale(1, 1)
	returnScrim.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	returnScrim.BackgroundTransparency = 1
	returnScrim.BorderSizePixel = 0
	returnScrim.ZIndex = 99
	returnScrim.Visible = false
	returnScrim.Parent = overlay

	state.HideOverlayForReturn = function()
		-- Fade in the dark scrim over the wardrobe, then hide the whole overlay.
		-- The camera return tween (0.75s) runs concurrently so the wardrobe
		-- dissolves during flight — no empty-camp flash.
		returnScrim.BackgroundTransparency = 1
		returnScrim.Visible = true
		TweenService:Create(
			returnScrim,
			TweenInfo.new(0.30, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{ BackgroundTransparency = 0 }
		):Play()
		task.delay(0.32, function()
			if overlay and overlay.Parent then
				overlay.Visible = false
				returnScrim.Visible = false
				returnScrim.BackgroundTransparency = 1
			end
		end)
	end

	-- Main Central Luxury Glass Panel
	local panel = Instance.new("Frame")
	panel.Name = "WardrobePanel"
	panel.Size = UDim2.fromScale(0.94, 0.90)
	panel.Position = UDim2.fromScale(0.5, 0.5)
	panel.AnchorPoint = Vector2.new(0.5, 0.5)
	panel.BackgroundColor3 = UI.Theme.Colors.GlassModal
    panel.BackgroundTransparency = 1
	panel.BorderSizePixel = 0
	panel.ZIndex = 71
	panel.Parent = overlay

	UI.Theme.ApplyGlass(panel, {
		CornerRadius = 16,
		StrokeColor = UI.Theme.Colors.BorderGlow,
		StrokeThickness = 1.4,
	})
    local panelStroke = panel:FindFirstChildOfClass("UIStroke")
    if panelStroke then panelStroke.Transparency = 1 end

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
	previewPanel.Position = UDim2.new(0.62, 0, 0, 0)
	previewPanel.Size = UDim2.new(0.38, 0, 1, 0)
	previewPanel.BackgroundColor3 = Color3.fromRGB(8, 10, 14)
	previewPanel.BackgroundTransparency = 0.06
	previewPanel.BorderSizePixel = 0
	previewPanel.ZIndex = 72
	previewPanel.ClipsDescendants = true
	previewPanel.Parent = overlay

	UI.Theme.ApplyGlass(previewPanel, {
		CornerRadius = 14,
		StrokeColor = UI.Theme.Colors.BorderSubtle,
		StrokeThickness = 1.2,
	})
    local previewStroke = previewPanel:FindFirstChildOfClass("UIStroke")
    if previewStroke then previewStroke.Transparency = 1 end

	local viewport = Instance.new("ViewportFrame")
	viewport.Name = "CharacterViewport"
	viewport.Size = UDim2.fromScale(1, 1)
	viewport.BackgroundTransparency = 1
	viewport.Ambient = Color3.fromRGB(185, 190, 205)
	viewport.LightColor = Color3.fromRGB(255, 175, 110)
	viewport.LightDirection = Vector3.new(-1, -1.8, -1.2)
	viewport.ZIndex = 73
	viewport.Parent = previewPanel
	local selectorFooter = Instance.new("Frame")
	selectorFooter.Name = "SelectorFooter"
	selectorFooter.Position = UDim2.new(0, 0, 0.70, 0)
	selectorFooter.Size = UDim2.new(1, 0, 0.30, 0)
	selectorFooter.BackgroundColor3 = Color3.fromRGB(8, 10, 14)
	selectorFooter.BackgroundTransparency = 0.04
	selectorFooter.BorderSizePixel = 0
	selectorFooter.ZIndex = 76
	selectorFooter.Parent = previewPanel
	local footerDivider = Instance.new("Frame")
	footerDivider.Name = "FooterDivider"
	footerDivider.Size = UDim2.new(0.92, 0, 0, 1)
	footerDivider.Position = UDim2.new(0.04, 0, 0, 0)
	footerDivider.BackgroundColor3 = UI.Theme.Colors.BorderSubtle
	footerDivider.BackgroundTransparency = 0.25
	footerDivider.BorderSizePixel = 0
	footerDivider.ZIndex = 77
	footerDivider.Parent = selectorFooter

	local worldModel = Instance.new("WorldModel")
	worldModel.Parent = viewport

	local previewCamera = Instance.new("Camera")
    previewCamera.FieldOfView = 35
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
    previewVeil.BackgroundTransparency = 0.24
	previewVeil.BorderSizePixel = 0
	previewVeil.ZIndex = 74
	previewVeil.Visible = false
	previewVeil.Parent = viewport

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
	spinnerCenter.ZIndex = 75
	spinnerCenter.Parent = previewVeil

	local spinnerRing = Instance.new("Frame")
	spinnerRing.Name = "SpinnerRing"
	spinnerRing.Size = UDim2.fromOffset(36, 36)
	spinnerRing.Position = UDim2.new(0.5, 0, 0, 18)
	spinnerRing.AnchorPoint = Vector2.new(0.5, 0.5)
	spinnerRing.BackgroundTransparency = 1
	spinnerRing.ZIndex = 76
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
	centerDot.ZIndex = 77
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
		requestBack()
	end)
	backButton.Name = "BackButton"
	backButton.Position = UDim2.new(0, 0, 0, 0)
	table.insert(state.BackButtons, backButton)

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
	local selectorNameLabel: TextLabel? = nil
	local poseButtons: { [string]: TextButton } = {}

	local function showLoadingVeil(titleText: string?)
		if veilTitle then veilTitle.Text = titleText or "LOADING SURVIVOR..." end
		previewVeil.Visible = true
		previewVeil.BackgroundTransparency = 0.24
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
			local sourcePreloadFinished = false
			task.spawn(function()
				pcall(function() ContentProvider:PreloadAsync(toPreload) end)
				sourcePreloadFinished = true
			end)
			local preloadDeadline = os.clock() + 1.6
			while not sourcePreloadFinished and os.clock() < preloadDeadline and generation == previewGeneration do
				task.wait(0.03)
			end
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
			local distance = math.max(boxSize.Y * 1.85, 7.6)
			-- Three-quarter side profile keeps the survivor readable while the live
			-- campsite stays visible through the transparent viewport behind them.
			previewCamera.CFrame = CFrame.lookAt(
				focus + Vector3.new(distance * 1.35, boxSize.Y * 0.03, -distance * 0.05),
				focus
			)

			-- 2. Preload and start selected idle animation
			local targetAnimId = IDLE_ANIMATIONS[state.CurrentIdleName] or charDef.RecommendedIdle
			local animation = Instance.new("Animation")
			animation.Name = "WardrobePreviewIdle"
			local numericId = string.match(targetAnimId, "(%d+)")
			animation.AnimationId = if numericId then "rbxassetid://" .. numericId else targetAnimId
			animation.Parent = clone

			local animationPreloadFinished = false
			task.spawn(function()
				pcall(function() ContentProvider:PreloadAsync({ animation }) end)
				animationPreloadFinished = true
			end)
			local animationDeadline = os.clock() + 0.6
			while not animationPreloadFinished and os.clock() < animationDeadline and generation == previewGeneration do
				task.wait(0.03)
			end
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
	local poseOptions = { "Static Resting Idle", "Breathing Shift", "Observant Gaze" }
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

		if selectorNameLabel then
			selectorNameLabel.Text = string.upper(activeDef.DisplayName)
		end
	end

	----------------------------------------------------------------------------
	-- Minimal camp picker: survivor name, arrows, invite, back, and enter.
	----------------------------------------------------------------------------
	local selectorHeading = makeText(panel, "CHOOSE YOUR SURVIVOR", 14, UI.Theme.Colors.EmberHot, UI.Theme.Fonts.Heading, 78)
	selectorHeading.Position = UDim2.new(0.055, 0, 0.10, 0)
	selectorHeading.Size = UDim2.new(0.48, 0, 0, 22)

	local partyPanel = Instance.new("Frame")
	partyPanel.Name = "FireteamPanel"
	partyPanel.Position = UDim2.new(0.035, 0, 0.70, 0)
	partyPanel.Size = UDim2.new(0.55, 0, 0.25, 0)
	partyPanel.BackgroundColor3 = UI.Theme.Colors.GlassSurface
	partyPanel.BackgroundTransparency = 1
	partyPanel.BorderSizePixel = 0
	partyPanel.ZIndex = 74
	partyPanel.Parent = overlay

	local partyHeader = makeText(partyPanel, "SETTING UP SESSION...", 11, UI.Theme.Colors.EmberGold, UI.Theme.Fonts.Heading, 76)
	partyHeader.Position = UDim2.new(0.035, 0, 0, 0)
	partyHeader.Size = UDim2.new(0.65, 0, 0, 30)
	local partyCount = makeText(partyPanel, "1 / 4", 10, UI.Theme.Colors.TextMuted, UI.Theme.Fonts.Heading, 76, Enum.TextXAlignment.Right)
	partyCount.Position = UDim2.new(0.75, -10, 0, 0)
	partyCount.Size = UDim2.new(0.22, 0, 0, 30)

	local slotList = Instance.new("Frame")
	slotList.Name = "Slots"
	slotList.Position = UDim2.new(0.025, 0, 0, 32)
	slotList.Size = UDim2.new(0.95, 0, 1, -40)
	slotList.BackgroundTransparency = 1
	slotList.ZIndex = 75
	slotList.Parent = partyPanel
	local slotLayout = Instance.new("UIGridLayout")
	slotLayout.FillDirection = Enum.FillDirection.Horizontal
	slotLayout.FillDirectionMaxCells = 4
	slotLayout.CellSize = UDim2.new(0.235, 0, 1, 0)
	slotLayout.CellPadding = UDim2.new(0.015, 0, 0, 0)
	slotLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
	slotLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	slotLayout.SortOrder = Enum.SortOrder.LayoutOrder
	slotLayout.Parent = slotList

	local getLobbySnapshot = sharedFolder:FindFirstChild("GetLobbySnapshot") :: RemoteFunction?
	local lobbyStateChanged = sharedFolder:FindFirstChild("LobbyStateChanged") :: RemoteEvent?
	local setLobbySelection = sharedFolder:FindFirstChild("SetLobbySelection") :: RemoteEvent?
	local requestLobbyKick = sharedFolder:FindFirstChild("RequestLobbyKick") :: RemoteFunction?
	local lobbySnapshot: any = { Members = {}, HostUserId = 0, Capacity = 4 }
	local lobbyRows = {}
	local lobbyLoaded = false
	local lobbyStartedAt = os.clock()
	local pendingKickUserId: number? = nil
	local lobbyStateConnection: RBXScriptConnection? = nil
	local confirmKickButton: TextButton

	local kickDimmer = Instance.new("TextButton")
	kickDimmer.Name = "KickConfirmDimmer"
	kickDimmer.Size = UDim2.fromScale(1, 1)
	kickDimmer.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	kickDimmer.BackgroundTransparency = 0.42
	kickDimmer.Text = ""
	kickDimmer.AutoButtonColor = false
	kickDimmer.Visible = false
	kickDimmer.ZIndex = 110
	kickDimmer.Parent = overlay

	local kickDialog = Instance.new("Frame")
	kickDialog.Name = "KickConfirmation"
	kickDialog.Size = UDim2.new(0.38, 0, 0, 210)
	kickDialog.Position = UDim2.fromScale(0.5, 0.5)
	kickDialog.AnchorPoint = Vector2.new(0.5, 0.5)
	kickDialog.BackgroundColor3 = Color3.fromRGB(12, 14, 18)
	kickDialog.BackgroundTransparency = 0.04
	kickDialog.BorderSizePixel = 0
	kickDialog.Visible = false
	kickDialog.ZIndex = 111
	kickDialog.Parent = overlay
	UI.Theme.ApplyGlass(kickDialog, {
		CornerRadius = 14,
		StrokeColor = UI.Theme.Colors.BorderGlow,
		StrokeThickness = 1.2,
	})
	local kickTitle = makeText(kickDialog, "REMOVE PLAYER?", 18, UI.Theme.Colors.TextPrimary, UI.Theme.Fonts.Title, 112)
	kickTitle.Position = UDim2.new(0.08, 0, 0.12, 0)
	kickTitle.Size = UDim2.new(0.84, 0, 0, 30)
	local kickDescription = makeText(kickDialog, "The player will be removed from this lobby.", 12, UI.Theme.Colors.TextMuted, UI.Theme.Fonts.Body, 112)
	kickDescription.Position = UDim2.new(0.08, 0, 0.34, 0)
	kickDescription.Size = UDim2.new(0.84, 0, 0, 44)
	local function closeKickDialog()
		kickDialog.Visible = false
		kickDimmer.Visible = false
		pendingKickUserId = nil
		ModalManager.SetOpen("PartyKickConfirmation", false)
	end
	kickDimmer.Activated:Connect(closeKickDialog)
	local cancelKickButton = makeButton(kickDialog, "CANCEL", UDim2.new(0.40, -6, 0, 40), 113, UI, closeKickDialog)
	cancelKickButton.Position = UDim2.new(0.08, 0, 0.70, 0)
	confirmKickButton = makeButton(kickDialog, "REMOVE", UDim2.new(0.44, 0, 0, 40), 113, UI, function()
		local targetUserId = pendingKickUserId
		if not targetUserId or not requestLobbyKick then
			closeKickDialog()
			return
		end
		confirmKickButton.Active = false
		confirmKickButton.Text = "REMOVING..."
		task.spawn(function()
			local ok, removed = pcall(function()
				return requestLobbyKick:InvokeServer(targetUserId)
			end)
			if not ok or removed ~= true then
				kickDescription.Text = "The host could not remove that player. Refresh and try again."
				task.wait(1.2)
			end
			confirmKickButton.Active = true
			confirmKickButton.Text = "REMOVE"
			closeKickDialog()
		end)
	end)
	confirmKickButton.Position = UDim2.new(0.52, 0, 0.70, 0)
	confirmKickButton.BackgroundColor3 = UI.Theme.Colors.EmberCrimson
	confirmKickButton.TextColor3 = Color3.fromRGB(255, 245, 235)

	local function inviteFriend()
		local ok, canInvite = pcall(function()
			return SocialService:CanSendGameInviteAsync(player)
		end)
		if ok and canInvite == true then
			pcall(function()
				SocialService:PromptGameInvite(player)
			end)
		end
	end

	local function renderLobby()
		for _, row in ipairs(lobbyRows) do row:Destroy() end
		table.clear(lobbyRows)
		local members = lobbySnapshot.Members or {}
		local capacity = math.clamp(tonumber(lobbySnapshot.Capacity) or 4, 1, 4)
		local viewSize = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(1280, 720)
		local compact = viewSize.X < 760
		partyHeader.Text = lobbyLoaded and "YOUR FIRETEAM" or "SETTING UP SESSION..."
		partyCount.Text = lobbyLoaded and string.format("%d / %d", #members, capacity) or "SYNCING"
		for slotIndex = 1, capacity do
			local member = members[slotIndex]
			local row = Instance.new("Frame")
			row.Name = "FireteamSlot" .. slotIndex
			row.LayoutOrder = slotIndex
			row.Size = UDim2.new(0, 0, 0, 0)
			row.BackgroundColor3 = member and UI.Theme.Colors.GlassElevated or UI.Theme.Colors.GlassSurface
			row.BackgroundTransparency = 0.10
			row.BorderSizePixel = 0
			row.ZIndex = 76
			row.Parent = slotList
			table.insert(lobbyRows, row)
			UI.Theme.ApplyGlass(row, {
				CornerRadius = 9,
				StrokeColor = member and UI.Theme.Colors.BorderSubtle or UI.Theme.Colors.BorderEmber,
				StrokeThickness = 1,
			})

			local portrait = Instance.new("ImageLabel")
			portrait.Name = "PlayerPortrait"
			local portraitSize = compact and 32 or 48
			portrait.Size = UDim2.fromOffset(portraitSize, portraitSize)
			portrait.Position = UDim2.new(0.5, 0, 0, compact and 6 or 10)
			portrait.AnchorPoint = Vector2.new(0.5, 0)
			portrait.BackgroundColor3 = UI.Theme.Colors.GlassSurface
			portrait.BackgroundTransparency = 0.2
			portrait.Image = ""
			portrait.ZIndex = 77
			portrait.Parent = row
			local portraitCorner = Instance.new("UICorner")
			portraitCorner.CornerRadius = UDim.new(1, 0)
			portraitCorner.Parent = portrait

			local nameLabel = makeText(row, "", compact and 9 or 12, member and UI.Theme.Colors.TextPrimary or UI.Theme.Colors.TextMuted, UI.Theme.Fonts.Heading, 78, Enum.TextXAlignment.Center)
			nameLabel.Position = UDim2.new(0.05, 0, 0, compact and 42 or 65)
			nameLabel.Size = UDim2.new(0.90, 0, 0, compact and 14 or 19)
			nameLabel.TextTruncate = Enum.TextTruncate.AtEnd
			local selectedId = member and member.CharacterId
			local survivorDef = selectedId and Config.Characters[selectedId]
			local detailLabel = makeText(row, "", compact and 8 or 10, UI.Theme.Colors.EmberHot, UI.Theme.Fonts.Body, 78, Enum.TextXAlignment.Center)
			detailLabel.Position = UDim2.new(0.04, 0, 0, compact and 58 or 87)
			detailLabel.Size = UDim2.new(0.92, 0, 0, compact and 13 or 16)
			detailLabel.TextTruncate = Enum.TextTruncate.AtEnd
			if not lobbyLoaded then
				nameLabel.Text = ""
				detailLabel.Text = ""
				local shimmer = Instance.new("Frame")
				shimmer.Name = "LoadingSkeleton"
				shimmer.Size = UDim2.fromOffset(portraitSize, portraitSize)
				shimmer.Position = portrait.Position
				shimmer.AnchorPoint = portrait.AnchorPoint
				shimmer.BackgroundColor3 = Color3.fromRGB(82, 84, 91)
				shimmer.BackgroundTransparency = 0.24
				shimmer.BorderSizePixel = 0
				shimmer.ZIndex = 79
				shimmer.Parent = row
				local shimmerCorner = Instance.new("UICorner")
				shimmerCorner.CornerRadius = UDim.new(1, 0)
				shimmerCorner.Parent = shimmer
				for lineIndex = 1, 2 do
					local line = Instance.new("Frame")
					line.Size = UDim2.new(lineIndex == 1 and 0.68 or 0.48, 0, 0, compact and 4 or 6)
					line.Position = UDim2.new(0.5, 0, 0, (compact and 44 or 69) + (lineIndex - 1) * (compact and 10 or 14))
					line.AnchorPoint = Vector2.new(0.5, 0)
					line.BackgroundColor3 = Color3.fromRGB(89, 91, 97)
					line.BackgroundTransparency = 0.32
					line.BorderSizePixel = 0
					line.ZIndex = 79
					line.Parent = row
					local lineCorner = Instance.new("UICorner")
					lineCorner.CornerRadius = UDim.new(1, 0)
					lineCorner.Parent = line
				end
				continue
			end
			local shownName = member and (member.DisplayName or member.Name) or "INVITE FRIEND"
			nameLabel.Text = shownName
			local subtitle = member and (survivorDef and string.upper(survivorDef.DisplayName) or "CHOOSING SURVIVOR") or "OPEN SLOT"
			detailLabel.Text = subtitle
			if member then
				local usernameLabel = makeText(row, "@" .. tostring(member.Name), compact and 7 or 9, UI.Theme.Colors.TextMuted, UI.Theme.Fonts.Body, 78, Enum.TextXAlignment.Center)
				usernameLabel.Position = UDim2.new(0.04, 0, 1, compact and -14 or -19)
				usernameLabel.Size = UDim2.new(0.92, 0, 0, compact and 10 or 13)
				usernameLabel.TextTruncate = Enum.TextTruncate.AtEnd
				if member.UserId == player.UserId then
					detailLabel.Text ..= "  ·  YOU"
				end
				if member.IsHost then
					local hostBadge = makeText(row, "HOST", compact and 7 or 8, UI.Theme.Colors.EmberGold, UI.Theme.Fonts.Heading, 80, Enum.TextXAlignment.Center)
					hostBadge.Position = UDim2.new(0, 3, 0, 3)
					hostBadge.Size = UDim2.new(0, compact and 27 or 34, 0, compact and 13 or 16)
				end
				if lobbySnapshot.HostUserId == player.UserId and member.UserId ~= player.UserId then
					local targetId = member.UserId
					local kickButton = makeButton(row, "×", UDim2.fromOffset(32, 32), 80, UI, function()
						pendingKickUserId = targetId
						kickDescription.Text = "Remove " .. tostring(member.DisplayName or member.Name) .. " from this lobby?"
						kickDialog.Visible = true
						kickDimmer.Visible = true
						ModalManager.SetOpen("PartyKickConfirmation", true)
					end)
					kickButton.Name = "KickPlayer"
					kickButton.Position = UDim2.new(1, -34, 0, 3)
					kickButton.Size = UDim2.fromOffset(compact and 22 or 26, compact and 22 or 26)
					kickButton.TextSize = 24
					kickButton.BackgroundColor3 = Color3.fromRGB(74, 29, 25)
				end
				task.spawn(function()
					local ok, image = pcall(function()
						return Players:GetUserThumbnailAsync(member.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size100x100)
					end)
					if ok and portrait.Parent then portrait.Image = image end
				end)
			else
				local plus = makeText(row, "+", compact and 24 or 32, UI.Theme.Colors.EmberGold, Enum.Font.GothamMedium, 78, Enum.TextXAlignment.Center)
				plus.Position = UDim2.new(0.5, 0, 0, compact and 5 or 10)
				plus.AnchorPoint = Vector2.new(0.5, 0)
				plus.Size = UDim2.fromOffset(compact and 32 or 48, compact and 32 or 48)
				nameLabel.TextColor3 = UI.Theme.Colors.TextPrimary
				nameLabel.Position = UDim2.new(0.05, 0, 0, compact and 42 or 65)
				nameLabel.Size = UDim2.new(0.90, 0, 0, compact and 14 or 19)
				detailLabel.Position = UDim2.new(0.04, 0, 0, compact and 58 or 87)
				detailLabel.Size = UDim2.new(0.92, 0, 0, compact and 13 or 16)
				local inviteSlot = Instance.new("TextButton")
				inviteSlot.Name = "InviteFriend"
				inviteSlot.Size = UDim2.fromScale(1, 1)
				inviteSlot.BackgroundTransparency = 1
				inviteSlot.Text = ""
				inviteSlot.ZIndex = 81
				inviteSlot.Parent = row
				inviteSlot.Activated:Connect(inviteFriend)
			end
		end
	end

	local function syncLobbySelection()
		if setLobbySelection then setLobbySelection:FireServer(state.SelectedCharacterId) end
		for _, member in ipairs(lobbySnapshot.Members or {}) do
			if member.UserId == player.UserId then
				member.CharacterId = state.SelectedCharacterId
				break
			end
		end
		renderLobby()
	end

	if lobbyStateChanged and lobbyStateChanged:IsA("RemoteEvent") then
		lobbyStateConnection = lobbyStateChanged.OnClientEvent:Connect(function(snapshot)
			if typeof(snapshot) == "table" then
				lobbySnapshot = snapshot
				lobbyLoaded = true
				renderLobby()
			end
		end)
	end
	if getLobbySnapshot and getLobbySnapshot:IsA("RemoteFunction") then
		task.spawn(function()
			local ok, snapshot = pcall(function() return getLobbySnapshot:InvokeServer() end)
			local skeletonMinimum = 0.32
			local remainingSkeletonTime = skeletonMinimum - (os.clock() - lobbyStartedAt)
			if remainingSkeletonTime > 0 then task.wait(remainingSkeletonTime) end
			if ok and typeof(snapshot) == "table" then
				lobbySnapshot = snapshot
			else
				lobbySnapshot.Members = {{
					UserId = player.UserId,
					Name = player.Name,
					DisplayName = player.DisplayName,
					CharacterId = state.SelectedCharacterId,
					IsHost = true,
				}}
				lobbySnapshot.HostUserId = player.UserId
			end
			lobbyLoaded = true
			renderLobby()
		end)
	else
		lobbySnapshot.Members = {{
			UserId = player.UserId,
			Name = player.Name,
			DisplayName = player.DisplayName,
			CharacterId = state.SelectedCharacterId,
			IsHost = true,
		}}
		lobbySnapshot.HostUserId = player.UserId
		lobbyLoaded = true
	end

	selectorNameLabel = makeText(panel, "SOPHIE", 40, UI.Theme.Colors.TextPrimary, UI.Theme.Fonts.Title, 78)
	selectorNameLabel.Position = UDim2.new(0.20, 0, 0.08, 0)
	selectorNameLabel.Size = UDim2.new(0.60, 0, 0, 44)
	selectorNameLabel.TextXAlignment = Enum.TextXAlignment.Center
	selectorNameLabel.Parent = selectorFooter

	local function stepSurvivor(direction: number)
		local currentIndex = table.find(Config.CharacterOrder, state.SelectedCharacterId) or 1
		local nextIndex = ((currentIndex - 1 + direction) % #Config.CharacterOrder) + 1
		local nextId = Config.CharacterOrder[nextIndex]
		if not nextId or nextId == state.SelectedCharacterId then return end
		state.SelectedCharacterId = nextId
		state.CurrentIdleName = "Static Resting Idle"
		UI.Theme.PlayClick()
		syncLobbySelection()
		refreshUI()
		refreshPreview()
	end

	local previousButton = makeButton(panel, "‹", UDim2.fromOffset(44, 44), 79, UI, function()
		stepSurvivor(-1)
	end)
	previousButton.Name = "PreviousSurvivor"
	previousButton.Position = UDim2.new(0.055, 0, 0.06, 0)
	previousButton.TextSize = 32
	previousButton.Font = Enum.Font.GothamMedium
	previousButton.Parent = selectorFooter

	local nextButton = makeButton(panel, "›", UDim2.fromOffset(44, 44), 79, UI, function()
		stepSurvivor(1)
	end)
	nextButton.Name = "NextSurvivor"
	nextButton.Position = UDim2.new(0.865, -44, 0.06, 0)
	nextButton.TextSize = 32
	nextButton.Font = Enum.Font.GothamMedium
	nextButton.Parent = selectorFooter

	local pickerBackButton = makeButton(panel, "BACK", UDim2.new(0.13, 0, 0, 42), 79, UI, function()
		requestBack()
	end)
	pickerBackButton.Name = "PickerBack"
	pickerBackButton.Position = UDim2.new(0.045, 0, 0.60, 0)
	pickerBackButton.TextSize = 13
	pickerBackButton.Size = UDim2.new(0.34, -4, 0, 40)
	pickerBackButton.Parent = selectorFooter
	table.insert(state.BackButtons, pickerBackButton)

	local pickerEnterButton = makeButton(panel, "ENTER THE WILDERNESS", UDim2.new(0.29, 0, 0, 42), 79, UI, function()
		local validated = Config.ValidateSelection({ CharacterId = state.SelectedCharacterId })
		if not validated then return end
		Wardrobe.Close()
		if state.OnConfirm then state.OnConfirm(validated) end
	end)
	pickerEnterButton.Name = "PickerEnter"
	pickerEnterButton.Position = UDim2.new(0.405, 4, 0.60, 0)
	pickerEnterButton.Size = UDim2.new(0.55, -4, 0, 40)
	pickerEnterButton.BackgroundColor3 = UI.Theme.Colors.EmberCrimson
	pickerEnterButton.TextColor3 = Color3.fromRGB(255, 245, 235)
	pickerEnterButton.TextSize = 13
	pickerEnterButton.Parent = selectorFooter

	renderLobby()

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
		if profile and (profile.Posture or profile.Facial) then
			local posture = profile.Posture or {}
			local facial = profile.Facial or {}
			local s1 = previewClone:FindFirstChild("mixamorig:Spine1", true)
			local s2 = previewClone:FindFirstChild("mixamorig:Spine2", true)
			local neck = previewClone:FindFirstChild("mixamorig:Neck", true)
			local lSh = previewClone:FindFirstChild("mixamorig:LeftShoulder", true)
			local rSh = previewClone:FindFirstChild("mixamorig:RightShoulder", true)
			local head = previewClone:FindFirstChild("mixamorig:Head", true)

			if s1 and s1:IsA("Bone") and posture.Spine1ArchDeg then
				s1.Transform = s1.Transform * CFrame.Angles(math.rad(posture.Spine1ArchDeg), 0, 0)
			end
			if s2 and s2:IsA("Bone") and posture.Spine2ArchDeg then
				s2.Transform = s2.Transform * CFrame.Angles(math.rad(posture.Spine2ArchDeg), 0, 0)
			end
			if neck and neck:IsA("Bone") and posture.NeckCounterDeg then
				neck.Transform = neck.Transform * CFrame.Angles(math.rad(posture.NeckCounterDeg), 0, 0)
			end
			if state.CurrentIdleName == "Static Resting Idle" then
				local neckDeg = posture.NeckPostureBackDeg or facial.NeckPostureBackDeg
				local headDeg = posture.HeadPostureBackDeg or facial.HeadPostureBackDeg
				if neck and neck:IsA("Bone") and neckDeg then
					neck.Transform = neck.Transform * CFrame.Angles(math.rad(neckDeg), 0, 0)
				end
				if head and head:IsA("Bone") and headDeg then
					head.Transform = head.Transform * CFrame.Angles(math.rad(headDeg), 0, 0)
				end
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
			panel.Size = UDim2.fromScale(1, 1)
			previewPanel.Position = UDim2.new(0.04, 0, 0.02, 0)
			previewPanel.Size = UDim2.new(0.92, 0, 0.56, 0)
			viewport.Size = UDim2.new(1, 0, 0.65, 0)
			selectorFooter.Position = UDim2.new(0, 0, 0.65, 0)
			selectorFooter.Size = UDim2.new(1, 0, 0.35, 0)
			selectorHeading.Position = UDim2.new(0.055, 0, 0.60, 0)
			selectorHeading.Size = UDim2.new(0.88, 0, 0, 20)
			partyPanel.Position = UDim2.new(0.04, 0, 0.62, 0)
			partyPanel.Size = UDim2.new(0.92, 0, 0.36, 0)
		else
			panel.Size = UDim2.fromScale(0.94, 0.90)
			previewPanel.Position = UDim2.new(0.62, 0, 0, 0)
			previewPanel.Size = UDim2.new(0.38, 0, 1, 0)
			viewport.Size = UDim2.new(1, 0, 0.70, 0)
			selectorFooter.Position = UDim2.new(0, 0, 0.70, 0)
			selectorFooter.Size = UDim2.new(1, 0, 0.30, 0)
			partyPanel.Position = UDim2.new(0.035, 0, 0.70, 0)
			partyPanel.Size = UDim2.new(0.55, 0, 0.25, 0)
			selectorHeading.Position = UDim2.new(0.055, 0, 0.10, 0)
			selectorHeading.Size = UDim2.new(0.50, 0, 0, 20)
		end

		selectorNameLabel.Parent = selectorFooter
		previousButton.Parent = selectorFooter
		nextButton.Parent = selectorFooter
		pickerBackButton.Parent = selectorFooter
		pickerEnterButton.Parent = selectorFooter
		panel.BackgroundTransparency = 1
		previewPanel.BackgroundTransparency = 0.06
		controls.Visible = false
		bottomRow.Visible = false
		headerTag.Visible = false
		header.Visible = false
		headerDiv.Visible = false
		rimGlow.Visible = false
		previewInfoBox.Visible = false
		dragHint.Visible = false
		poseBar.Visible = false
		if previewVeil.Parent ~= viewport then previewVeil.Parent = viewport end
		kickDialog.Size = UDim2.new(vpSize.X < 760 and 0.88 or 0.38, 0, 0, 210)
		if previewStroke then previewStroke.Transparency = 0.42 end
		if panelStroke then panelStroke.Transparency = 1 end
	end
	updateResponsive()
	if camera then
		viewportResizeConn = camera:GetPropertyChangedSignal("ViewportSize"):Connect(updateResponsive)
	end

	----------------------------------------------------------------------------
	-- PUBLIC INTERFACE
	----------------------------------------------------------------------------
	Wardrobe.IsLobbyReady = function()
		return lobbyLoaded
	end

	-- Called by MainMenu at the start of the back-transition so the overlay
	-- fades concurrent with the camera returning to the wide menu framing.
	Wardrobe.HideForReturn = function()
		if state.HideOverlayForReturn then
			state.HideOverlayForReturn()
		end
	end

	Wardrobe.Open = function(onBack: () -> (), onConfirm: (any) -> ())
		state.OnBack = onBack
		state.OnConfirm = onConfirm
		state.IsReturning = false
		for _, button in ipairs(state.BackButtons) do
			button.Active = true
			button.Selectable = true
			button.Visible = true
			button.Text = "BACK"
		end
		state.IsOpen = true
		overlay.Visible = true
		refreshUI()
		syncLobbySelection()
		refreshPreview()
		UI.Theme.PlayClick()
	end

	Wardrobe.Close = function()
		state.IsOpen = false
		state.IsReturning = false
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
		if lobbyStateConnection then
			lobbyStateConnection:Disconnect()
			lobbyStateConnection = nil
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
