--!strict
-- Post-Play survivor and outfit selection. Previews are local ViewportFrames;
-- the server independently validates and applies the same selection on spawn.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local shared = ReplicatedStorage:WaitForChild("FluenosityShared")
local Config = require(shared:WaitForChild("SurvivorWardrobeConfig"))
local Applier = require(shared:WaitForChild("SurvivorWardrobeApplier"))
local roster = shared:WaitForChild("SurvivorRoster")

local Wardrobe = {}

local function makeText(parent: Instance, text: string, size: number, color: Color3, font: Enum.Font, z: number): TextLabel
	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Text = text
	label.TextColor3 = color
	label.TextSize = size
	label.Font = font
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.TextYAlignment = Enum.TextYAlignment.Center
	label.TextWrapped = true
	label.ZIndex = z
	label.Parent = parent
	return label
end

local function makeButton(parent: Instance, text: string, size: UDim2, z: number, UI: any, onClick: () -> ()): TextButton
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
	UI.Theme.ApplyGlass(button, { CornerRadius = 8, StrokeColor = UI.Theme.Colors.BorderSubtle, StrokeThickness = 1 })
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
		Selection = Config.GetDefaultSelection("Leo"),
		Gender = "Male",
		Category = "Top",
		OnBack = nil :: (() -> ())?,
		OnConfirm = nil :: ((any) -> ())?,
		IsOpen = false,
	}

	local overlay = Instance.new("Frame")
	overlay.Name = "SurvivorWardrobe"
	overlay.Size = UDim2.fromScale(1, 1)
	overlay.BackgroundColor3 = UI.Theme.Colors.Void
	overlay.BackgroundTransparency = 0.16
	overlay.BorderSizePixel = 0
	overlay.Visible = false
	overlay.ZIndex = 70
	overlay.Parent = screenGui

	local panel = Instance.new("Frame")
	panel.Name = "WardrobePanel"
	panel.Size = UDim2.fromScale(0.92, 0.88)
	panel.Position = UDim2.fromScale(0.5, 0.5)
	panel.AnchorPoint = Vector2.new(0.5, 0.5)
	panel.BackgroundColor3 = UI.Theme.Colors.GlassModal
	panel.BackgroundTransparency = 0.08
	panel.BorderSizePixel = 0
	panel.ZIndex = 71
	panel.Parent = overlay
	UI.Theme.ApplyGlass(panel, { CornerRadius = 16, StrokeColor = UI.Theme.Colors.BorderGlow, StrokeThickness = 1.3 })
	local sizeConstraint = Instance.new("UISizeConstraint")
	sizeConstraint.MinSize = Vector2.new(330, 390)
	sizeConstraint.MaxSize = Vector2.new(1180, 760)
	sizeConstraint.Parent = panel

	local headerTag = makeText(panel, "[ SURVIVOR PREPARATION ]", 10, UI.Theme.Colors.EmberHot, UI.Theme.Fonts.Heading, 72)
	headerTag.Name = "HeaderTag"
	headerTag.Position = UDim2.new(0.035, 0, 0.025, 0)
	headerTag.Size = UDim2.new(0.8, 0, 0, 16)
	local header = makeText(panel, "CHOOSE YOUR SURVIVOR", 24, UI.Theme.Colors.TextPrimary, UI.Theme.Fonts.Title, 72)
	header.Name = "Header"
	header.Position = UDim2.new(0.035, 0, 0.055, 0)
	header.Size = UDim2.new(0.8, 0, 0, 32)

	local previewPanel = Instance.new("Frame")
	previewPanel.Name = "PreviewPanel"
	previewPanel.Position = UDim2.new(0.035, 0, 0.145, 0)
	previewPanel.Size = UDim2.new(0.42, 0, 0.81, 0)
	previewPanel.BackgroundColor3 = UI.Theme.Colors.GlassSurface
	previewPanel.BackgroundTransparency = 0.34
	previewPanel.BorderSizePixel = 0
	previewPanel.ZIndex = 72
	previewPanel.Parent = panel
	UI.Theme.ApplyGlass(previewPanel, { CornerRadius = 12, StrokeColor = UI.Theme.Colors.BorderSubtle, StrokeThickness = 1 })

	local viewport = Instance.new("ViewportFrame")
	viewport.Name = "CharacterPreview"
	viewport.Size = UDim2.fromScale(1, 1)
	viewport.BackgroundTransparency = 1
	viewport.Ambient = Color3.fromRGB(175, 180, 192)
	viewport.LightColor = UI.Theme.Colors.EmberHot
	viewport.LightDirection = Vector3.new(-1, -2, -1)
	viewport.ZIndex = 73
	viewport.Parent = previewPanel
	local worldModel = Instance.new("WorldModel")
	worldModel.Parent = viewport
	local previewCamera = Instance.new("Camera")
	previewCamera.FieldOfView = 34
	previewCamera.Parent = viewport
	viewport.CurrentCamera = previewCamera

	local characterName = makeText(previewPanel, "LEO", 19, UI.Theme.Colors.TextPrimary, UI.Theme.Fonts.Title, 75)
	characterName.Position = UDim2.new(0.07, 0, 0.82, 0)
	characterName.Size = UDim2.new(0.86, 0, 0, 27)
	local characterRole = makeText(previewPanel, "THE TRACKER", 10, UI.Theme.Colors.EmberHot, UI.Theme.Fonts.Heading, 75)
	characterRole.Position = UDim2.new(0.07, 0, 0.89, 0)
	characterRole.Size = UDim2.new(0.86, 0, 0, 18)
	local refreshPreview: () -> ()
	local refreshOptions: () -> ()

	local controls = Instance.new("Frame")
	controls.Name = "WardrobeControls"
	controls.Position = UDim2.new(0.48, 0, 0.145, 0)
	controls.Size = UDim2.new(0.485, 0, 0.81, 0)
	controls.BackgroundTransparency = 1
	controls.ZIndex = 72
	controls.Parent = panel

	local genderRow = Instance.new("Frame")
	genderRow.Name = "GenderTabs"
	genderRow.Size = UDim2.new(1, 0, 0, 40)
	genderRow.BackgroundTransparency = 1
	genderRow.ZIndex = 73
	genderRow.Parent = controls
	local maleTab = makeButton(genderRow, "MALE SURVIVORS", UDim2.new(0.49, -4, 1, 0), 74, UI, function()
		state.Gender = "Male"
		local maleCharacter = if Config.Characters[state.Selection.CharacterId].Gender == "Male" then state.Selection.CharacterId else "Leo"
		state.Selection = Config.GetDefaultSelection(maleCharacter)
		refreshOptions()
		refreshPreview()
	end)
	local femaleTab = makeButton(genderRow, "FEMALE SURVIVORS", UDim2.new(0.49, -4, 1, 0), 74, UI, function()
		state.Gender = "Female"
		local femaleCharacter = if Config.Characters[state.Selection.CharacterId].Gender == "Female" then state.Selection.CharacterId else "Maya"
		state.Selection = Config.GetDefaultSelection(femaleCharacter)
		refreshOptions()
		refreshPreview()
	end)
	femaleTab.Position = UDim2.new(0.51, 4, 0, 0)

	local characterRow = Instance.new("Frame")
	characterRow.Name = "CharacterChoices"
	characterRow.Position = UDim2.new(0, 0, 0, 50)
	characterRow.Size = UDim2.new(1, 0, 0, 104)
	characterRow.BackgroundTransparency = 1
	characterRow.ZIndex = 73
	characterRow.Parent = controls
	local characterLayout = Instance.new("UIListLayout")
	characterLayout.FillDirection = Enum.FillDirection.Horizontal
	characterLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
	characterLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	characterLayout.Padding = UDim.new(0, 8)
	characterLayout.Parent = characterRow

	local categoryRow = Instance.new("Frame")
	categoryRow.Name = "CategoryTabs"
	categoryRow.Position = UDim2.new(0, 0, 0, 169)
	categoryRow.Size = UDim2.new(1, 0, 0, 38)
	categoryRow.BackgroundTransparency = 1
	categoryRow.ZIndex = 73
	categoryRow.Parent = controls

	local optionRow = Instance.new("ScrollingFrame")
	optionRow.Name = "WardrobeOptions"
	optionRow.Position = UDim2.new(0, 0, 0, 216)
	optionRow.Size = UDim2.new(1, 0, 0, 105)
	optionRow.BackgroundTransparency = 1
	optionRow.BorderSizePixel = 0
	optionRow.ScrollBarThickness = 3
	optionRow.ScrollBarImageColor3 = UI.Theme.Colors.BorderGlass
	optionRow.ScrollingDirection = Enum.ScrollingDirection.X
	optionRow.AutomaticCanvasSize = Enum.AutomaticSize.X
	optionRow.CanvasSize = UDim2.new(0, 0, 0, 0)
	optionRow.ZIndex = 73
	optionRow.Parent = controls
	local optionLayout = Instance.new("UIListLayout")
	optionLayout.FillDirection = Enum.FillDirection.Horizontal
	optionLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
	optionLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	optionLayout.Padding = UDim.new(0, 8)
	optionLayout.Parent = optionRow
	local optionPadding = Instance.new("UIPadding")
	optionPadding.PaddingRight = UDim.new(0, 4)
	optionPadding.Parent = optionRow

	local helper = makeText(controls, "Choose a survivor, then mix their field-ready gear.", 11, UI.Theme.Colors.TextMuted, UI.Theme.Fonts.Body, 74)
	helper.Position = UDim2.new(0, 0, 0, 332)
	helper.Size = UDim2.new(1, 0, 0, 28)

	local backButton = makeButton(controls, "BACK", UDim2.new(0.34, -4, 0, 44), 74, UI, function()
		Wardrobe.Close()
		if state.OnBack then state.OnBack() end
	end)
	backButton.Name = "BackButton"
	backButton.Position = UDim2.new(0, 0, 1, -46)
	local enterButton = makeButton(controls, "ENTER THE WILDERNESS", UDim2.new(0.62, -4, 0, 44), 74, UI, function()
		local validated = Config.ValidateSelection(state.Selection)
		if not validated then return end
		Wardrobe.Close()
		if state.OnConfirm then state.OnConfirm(validated) end
	end)
	enterButton.Name = "EnterButton"
	enterButton.Position = UDim2.new(0.38, 4, 1, -46)
	enterButton.BackgroundColor3 = UI.Theme.Colors.EmberCrimson

	local camera = workspace.CurrentCamera
	local viewportConnection: RBXScriptConnection? = nil
	local function updateResponsiveLayout()
		camera = workspace.CurrentCamera or camera
		local viewportSize = camera and camera.ViewportSize or Vector2.new(1280, 720)
		if viewportSize.X < 760 then
			panel.Size = UDim2.fromScale(0.96, 0.93)
			previewPanel.Position = UDim2.new(0.035, 0, 0.13, 0)
			previewPanel.Size = UDim2.new(0.93, 0, 0.34, 0)
			characterName.Position = UDim2.new(0.07, 0, 0.70, 0)
			characterRole.Position = UDim2.new(0.07, 0, 0.80, 0)
			controls.Position = UDim2.new(0.035, 0, 0.49, 0)
			controls.Size = UDim2.new(0.93, 0, 0.47, 0)
			genderRow.Size = UDim2.new(1, 0, 0, 34)
			characterRow.Position = UDim2.new(0, 0, 0, 40)
			characterRow.Size = UDim2.new(1, 0, 0, 68)
			categoryRow.Position = UDim2.new(0, 0, 0, 116)
			categoryRow.Size = UDim2.new(1, 0, 0, 32)
			optionRow.Position = UDim2.new(0, 0, 0, 157)
			optionRow.Size = UDim2.new(1, 0, 0, 76)
			helper.Position = UDim2.new(0, 0, 0, 237)
			helper.Size = UDim2.new(1, 0, 0, 24)
			backButton.Size = UDim2.new(0.34, -4, 0, 40)
			backButton.Position = UDim2.new(0, 0, 1, -42)
			enterButton.Size = UDim2.new(0.62, -4, 0, 40)
			enterButton.Position = UDim2.new(0.38, 4, 1, -42)
		else
			panel.Size = UDim2.fromScale(0.92, 0.88)
			previewPanel.Position = UDim2.new(0.035, 0, 0.145, 0)
			previewPanel.Size = UDim2.new(0.42, 0, 0.81, 0)
			characterName.Position = UDim2.new(0.07, 0, 0.82, 0)
			characterRole.Position = UDim2.new(0.07, 0, 0.89, 0)
			controls.Position = UDim2.new(0.48, 0, 0.145, 0)
			controls.Size = UDim2.new(0.485, 0, 0.81, 0)
			genderRow.Size = UDim2.new(1, 0, 0, 40)
			characterRow.Position = UDim2.new(0, 0, 0, 50)
			characterRow.Size = UDim2.new(1, 0, 0, 104)
			categoryRow.Position = UDim2.new(0, 0, 0, 169)
			categoryRow.Size = UDim2.new(1, 0, 0, 38)
			optionRow.Position = UDim2.new(0, 0, 0, 216)
			optionRow.Size = UDim2.new(1, 0, 0, 105)
			helper.Position = UDim2.new(0, 0, 0, 332)
			helper.Size = UDim2.new(1, 0, 0, 28)
			backButton.Size = UDim2.new(0.34, -4, 0, 44)
			backButton.Position = UDim2.new(0, 0, 1, -46)
			enterButton.Size = UDim2.new(0.62, -4, 0, 44)
			enterButton.Position = UDim2.new(0.38, 4, 1, -46)
		end
	end
	updateResponsiveLayout()
	if camera then viewportConnection = camera:GetPropertyChangedSignal("ViewportSize"):Connect(updateResponsiveLayout) end

	local characterButtons: { [string]: TextButton } = {}
	local categoryButtons: { [string]: TextButton } = {}
	local optionButtons: { [string]: TextButton } = {}
	local previewClone: Model? = nil

	local function clearLayoutButtons(container: Instance)
		for _, child in ipairs(container:GetChildren()) do
			if child:IsA("GuiButton") then child:Destroy() end
		end
	end

	refreshPreview = function()
		if previewClone then previewClone:Destroy() previewClone = nil end
		local source = roster:FindFirstChild(state.Selection.CharacterId)
		if not source or not source:IsA("Model") then
			characterName.Text = "SURVIVOR UNAVAILABLE"
			return
		end
		local clone = source:Clone()
		clone.Name = "WardrobePreview"
		local ok = Applier.Apply(clone, state.Selection, roster)
		if not ok then clone:Destroy() return end
		for _, item in ipairs(clone:GetDescendants()) do
			if item:IsA("BasePart") then
				item.Anchored = true
				item.CanCollide = false
				item.CastShadow = true
			elseif item:IsA("BaseScript") then
				item:Destroy()
			end
		end
		clone:PivotTo(CFrame.new(0, 0, 0))
		clone.Parent = worldModel
		previewClone = clone
		local boxCFrame, boxSize = clone:GetBoundingBox()
		local focus = boxCFrame.Position + Vector3.new(0, boxSize.Y * 0.08, 0)
		local distance = math.max(boxSize.Y * 1.5, 7)
		previewCamera.CFrame = CFrame.lookAt(focus + Vector3.new(0, boxSize.Y * 0.02, -distance), focus)
		local definition = Config.Characters[state.Selection.CharacterId]
		characterName.Text = string.upper(definition.DisplayName)
		characterRole.Text = definition.Role
	end

	refreshOptions = function()
		clearLayoutButtons(characterRow)
		characterButtons = {}
		for _, characterId in ipairs(Config.CharacterOrder) do
			local definition = Config.Characters[characterId]
			if definition.Gender == state.Gender then
				local button = makeButton(characterRow, string.upper(definition.DisplayName) .. "\n" .. definition.Role, UDim2.new(0.32, -6, 1, -8), 74, UI, function()
					state.Selection = Config.GetDefaultSelection(characterId)
					refreshPreview()
					refreshOptions()
				end)
				button.Name = "Character_" .. characterId
				button.TextWrapped = true
				button.TextSize = 10
				characterButtons[characterId] = button
			end
		end
		clearLayoutButtons(categoryRow)
		categoryButtons = {}
		local categories = { "Top", "Pants", "Shoes", "Head" }
		for index, categoryName in ipairs(categories) do
			local category = Config.Categories[categoryName]
			local button = makeButton(categoryRow, category.Label, UDim2.new(0.25, -5, 1, 0), 74, UI, function()
				state.Category = categoryName
				refreshOptions()
			end)
			button.Position = UDim2.new((index - 1) * 0.25, 0, 0, 0)
			categoryButtons[categoryName] = button
		end
		clearLayoutButtons(optionRow)
		optionButtons = {}
		local category = Config.Categories[state.Category]
		for _, option in ipairs(category.Options) do
			if option.Gender == state.Gender then
				local button = makeButton(optionRow, option.Label, UDim2.new(0, 132, 0, 58), 74, UI, function()
					state.Selection[state.Category] = option.Id
					refreshPreview()
					refreshOptions()
				end)
				button.Name = "Option_" .. option.Id
				optionButtons[option.Id] = button
			end
		end
		maleTab.BackgroundTransparency = if state.Gender == "Male" then 0.08 else 0.3
		femaleTab.BackgroundTransparency = if state.Gender == "Female" then 0.08 else 0.3
		for id, button in pairs(characterButtons) do
			button.BackgroundTransparency = if state.Selection.CharacterId == id then 0.08 else 0.3
		end
		for id, button in pairs(categoryButtons) do
			button.BackgroundTransparency = if state.Category == id then 0.08 else 0.3
		end
		for id, button in pairs(optionButtons) do
			button.BackgroundTransparency = if state.Selection[state.Category] == id then 0.08 else 0.3
		end
	end

	Wardrobe.Open = function(onBack: () -> (), onConfirm: (any) -> ())
		state.Selection = Config.ValidateSelection(state.Selection) or Config.GetDefaultSelection("Leo")
		state.Gender = Config.Characters[state.Selection.CharacterId].Gender
		state.Category = "Top"
		state.OnBack = onBack
		state.OnConfirm = onConfirm
		state.IsOpen = true
		overlay.Visible = true
		refreshOptions()
		refreshPreview()
		UI.Theme.PlayClick()
	end

	Wardrobe.Close = function()
		state.IsOpen = false
		overlay.Visible = false
	end

	Wardrobe.Destroy = function()
		Wardrobe.Close()
		if viewportConnection then
			viewportConnection:Disconnect()
			viewportConnection = nil
		end
		if previewClone then
			previewClone:Destroy()
			previewClone = nil
		end
		overlay:Destroy()
	end

	Wardrobe.GetSelection = function()
		return Config.ValidateSelection(state.Selection)
	end

	Wardrobe.Panel = panel
	return Wardrobe
end

return Wardrobe
