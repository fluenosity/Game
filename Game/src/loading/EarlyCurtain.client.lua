--!strict
-- Runs from ReplicatedFirst. Covers the default Roblox loader, prepares the
-- menu's survivor assets, then reveals the studio splash and live menu scene.

local ContentProvider = game:GetService("ContentProvider")
local Players = game:GetService("Players")
local ReplicatedFirst = game:GetService("ReplicatedFirst")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

pcall(function()
	ReplicatedFirst:RemoveDefaultLoadingScreen()
end)

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui") :: PlayerGui
local loadingStartedAt = os.clock()
local MINIMUM_LOADING_SECONDS = 4

local gui = Instance.new("ScreenGui")
gui.Name = "DontLetTheFireDie_EarlyCurtain"
gui.IgnoreGuiInset = true
gui.ResetOnSpawn = false
gui.DisplayOrder = 1000
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = playerGui

local background = Instance.new("Frame")
background.Name = "Background"
background.Size = UDim2.fromScale(1, 1)
background.BackgroundColor3 = Color3.fromRGB(249, 247, 240)
background.BorderSizePixel = 0
background.Parent = gui

local gradient = Instance.new("UIGradient")
gradient.Rotation = 90
gradient.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 254, 250)),
	ColorSequenceKeypoint.new(0.55, Color3.fromRGB(249, 247, 240)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(242, 238, 227)),
})
gradient.Parent = background

local title = Instance.new("TextLabel")
title.Name = "Title"
title.AnchorPoint = Vector2.new(0.5, 0.5)
title.Position = UDim2.fromScale(0.5, 0.44)
title.Size = UDim2.new(0.9, 0, 0, 52)
title.BackgroundTransparency = 1
title.Font = Enum.Font.Oswald
title.Text = "DON'T LET THE FIRE DIE"
title.TextColor3 = Color3.fromRGB(46, 51, 52)
title.TextScaled = true
title.Parent = background

local titleConstraint = Instance.new("UITextSizeConstraint")
titleConstraint.MinTextSize = 18
titleConstraint.MaxTextSize = 34
titleConstraint.Parent = title

local eyebrow = Instance.new("TextLabel")
eyebrow.AnchorPoint = Vector2.new(0.5, 0.5)
eyebrow.Position = UDim2.fromScale(0.5, 0.505)
eyebrow.Size = UDim2.new(0.8, 0, 0, 20)
eyebrow.BackgroundTransparency = 1
eyebrow.Font = Enum.Font.GothamMedium
eyebrow.Text = "A FLUENOSITY STUDIO SURVIVAL EXPERIENCE"
eyebrow.TextColor3 = Color3.fromRGB(179, 104, 48)
eyebrow.TextSize = 11
eyebrow.Parent = background

local sigilRow = Instance.new("Frame")
sigilRow.Name = "WildernessSigils"
sigilRow.AnchorPoint = Vector2.new(0.5, 0.5)
sigilRow.Position = UDim2.fromScale(0.5, 0.60)
sigilRow.Size = UDim2.fromOffset(230, 28)
sigilRow.BackgroundTransparency = 1
sigilRow.Parent = background

local sigilLayout = Instance.new("UIListLayout")
sigilLayout.FillDirection = Enum.FillDirection.Horizontal
sigilLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
sigilLayout.VerticalAlignment = Enum.VerticalAlignment.Center
sigilLayout.Padding = UDim.new(0, 16)
sigilLayout.Parent = sigilRow

for index = 1, 5 do
	local sigil = Instance.new("Frame")
	sigil.Name = "Sigil" .. index
	sigil.Size = UDim2.fromOffset(index == 3 and 20 or 16, index == 3 and 20 or 16)
	sigil.Rotation = 45
	sigil.BackgroundColor3 = index == 3 and Color3.fromRGB(230, 143, 62) or Color3.fromRGB(160, 153, 135)
	sigil.BackgroundTransparency = index == 3 and 0.12 or 0.72
	sigil.BorderSizePixel = 0
	sigil.Parent = sigilRow
	local sigilCorner = Instance.new("UICorner")
	sigilCorner.CornerRadius = UDim.new(0, 3)
	sigilCorner.Parent = sigil
	local core = Instance.new("Frame")
	core.Name = "Core"
	core.AnchorPoint = Vector2.new(0.5, 0.5)
	core.Position = UDim2.fromScale(0.5, 0.5)
	core.Size = UDim2.fromOffset(index == 3 and 5 or 3, index == 3 and 5 or 3)
	core.BackgroundColor3 = Color3.fromRGB(255, 248, 229)
	core.BorderSizePixel = 0
	core.Parent = sigil
	local coreCorner = Instance.new("UICorner")
	coreCorner.CornerRadius = UDim.new(1, 0)
	coreCorner.Parent = core
end

local headphoneTip = Instance.new("TextLabel")
headphoneTip.Name = "HeadphoneTip"
headphoneTip.AnchorPoint = Vector2.new(0.5, 0.5)
headphoneTip.Position = UDim2.fromScale(0.5, 0.835)
headphoneTip.Size = UDim2.new(0.9, 0, 0, 18)
headphoneTip.BackgroundTransparency = 1
headphoneTip.Font = Enum.Font.GothamMedium
headphoneTip.Text = "HEADPHONES RECOMMENDED FOR THE WILDERNESS"
headphoneTip.TextColor3 = Color3.fromRGB(127, 128, 123)
headphoneTip.TextSize = 10
headphoneTip.Parent = background

local status = Instance.new("TextLabel")
status.AnchorPoint = Vector2.new(0.5, 0.5)
status.Position = UDim2.fromScale(0.5, 0.89)
status.Size = UDim2.new(0.8, 0, 0, 20)
status.BackgroundTransparency = 1
status.Font = Enum.Font.GothamMedium
status.Text = "PREPARING THE WILDERNESS"
status.TextColor3 = Color3.fromRGB(84, 91, 92)
status.TextSize = 12
status.Parent = background

local track = Instance.new("Frame")
track.AnchorPoint = Vector2.new(0.5, 0.5)
track.Position = UDim2.fromScale(0.5, 0.93)
track.Size = UDim2.new(0.42, 0, 0, 4)
track.BackgroundColor3 = Color3.fromRGB(221, 217, 206)
track.BorderSizePixel = 0
track.Parent = background
local trackCorner = Instance.new("UICorner")
trackCorner.CornerRadius = UDim.new(1, 0)
trackCorner.Parent = track

local fill = Instance.new("Frame")
fill.Size = UDim2.fromScale(0.04, 1)
fill.BackgroundColor3 = Color3.fromRGB(216, 125, 53)
fill.BorderSizePixel = 0
fill.Parent = track
local fillCorner = Instance.new("UICorner")
fillCorner.CornerRadius = UDim.new(1, 0)
fillCorner.Parent = fill

local function setProgress(ratio: number, message: string)
	status.Text = message
	TweenService:Create(fill, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Size = UDim2.fromScale(math.clamp(ratio, 0.04, 1), 1),
	}):Play()
end

local function preloadMenuAssets()
	setProgress(0.12, "CONNECTING TO THE FOREST")
	local shared = ReplicatedStorage:WaitForChild("FluenosityShared", 20)
	local roster = shared and shared:WaitForChild("SurvivorRoster", 20)
	local assets: { Instance } = {}
	if roster then
		for _, instance in ipairs(roster:GetDescendants()) do
			if instance:IsA("MeshPart") or instance:IsA("SpecialMesh")
				or instance:IsA("Decal") or instance:IsA("Texture")
				or instance:IsA("SurfaceAppearance") or instance:IsA("Animation")
				or instance:IsA("Shirt") or instance:IsA("Pants")
				or instance:IsA("ShirtGraphic") then
				table.insert(assets, instance)
			end
		end
	end

	setProgress(0.22, "PREPARING SURVIVOR PREVIEWS")
	if #assets > 0 then
		local completed = 0
		local lastProgress = 0.22
		local ok = pcall(function()
			ContentProvider:PreloadAsync(assets, function(_, _)
				completed += 1
				local ratio = 0.22 + 0.68 * (completed / #assets)
				if ratio >= lastProgress + 0.025 or completed >= #assets then
					lastProgress = ratio
					setProgress(ratio, "LOADING CHARACTER AND WARDROBE ASSETS")
				end
			end)
		end)
		if not ok then
			warn("[EarlyCurtain] Some menu preview assets could not be preloaded; Roblox will stream them as needed.")
		end
	end
	setProgress(0.82, "PREPARING THE LIVE FOREST SCENE")
	local sceneDeadline = os.clock() + 15
	while player:GetAttribute("MenuSceneReady") ~= true and os.clock() < sceneDeadline do
		task.wait(0.1)
	end
	setProgress(0.96, "FOREST SCENE READY")
	task.wait(0.12)
	setProgress(1, "READY")
	player:SetAttribute("InitialMenuAssetsReady", true)
end

task.spawn(preloadMenuAssets)

-- Keep the curtain up until the main menu has built its live camera and UI.
-- The watchdog prevents a missing menu script from trapping a player forever.
local startedAt = os.clock()
while os.clock() - startedAt < 45 do
	if player:GetAttribute("InitialMenuAssetsReady") == true
		and player:GetAttribute("MenuSceneReady") == true
		and playerGui:FindFirstChild("DontLetTheFireDie_MenuGui") then
		break
	end
	task.wait(0.05)
end

if player:GetAttribute("InitialMenuAssetsReady") ~= true then
	player:SetAttribute("InitialMenuAssetsReady", true)
	warn("[EarlyCurtain] Menu asset preparation timed out; continuing with Roblox streaming.")
end

local remainingLoadingTime = MINIMUM_LOADING_SECONDS - (os.clock() - loadingStartedAt)
if remainingLoadingTime > 0 then
	task.wait(remainingLoadingTime)
end

task.wait(0.1)
local fade = TweenService:Create(background, TweenInfo.new(0.45, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
	BackgroundTransparency = 1,
})
fade:Play()
for _, descendant in ipairs(background:GetDescendants()) do
	if descendant:IsA("TextLabel") then
		TweenService:Create(descendant, TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			TextTransparency = 1,
		}):Play()
	elseif descendant:IsA("Frame") and descendant ~= background then
		TweenService:Create(descendant, TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			BackgroundTransparency = 1,
		}):Play()
	end
end
fade.Completed:Wait()
gui:Destroy()
