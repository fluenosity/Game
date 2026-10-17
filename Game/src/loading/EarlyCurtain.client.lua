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

-- ── Palette ───────────────────────────────────────────────────────────────────
local EMBER = Color3.fromRGB(200, 100, 30)
local FILL_COLOR = Color3.fromRGB(28, 28, 28) -- swap to EMBER for an orange bar
local TRACK_COLOR = Color3.fromRGB(225, 225, 225)
local TEXT_DARK = Color3.fromRGB(28, 28, 28)
local TEXT_MUTED = Color3.fromRGB(120, 120, 120)

-- ── Root GUI ──────────────────────────────────────────────────────────────────
local gui = Instance.new("ScreenGui")
gui.Name = "DontLetTheFireDie_EarlyCurtain"
gui.IgnoreGuiInset = true
gui.ResetOnSpawn = false
gui.DisplayOrder = 1000
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = playerGui

-- Pure white background (clean minimal)
local background = Instance.new("Frame")
background.Name = "Background"
background.Size = UDim2.fromScale(1, 1)
background.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
background.BorderSizePixel = 0
background.Parent = gui

-- ── Centre: Game title ────────────────────────────────────────────────────────
local title = Instance.new("TextLabel")
title.Name = "Title"
title.AnchorPoint = Vector2.new(0.5, 0.5)
title.Position = UDim2.fromScale(0.5, 0.5)
title.Size = UDim2.new(0.9, 0, 0, 42)
title.BackgroundTransparency = 1
title.Font = Enum.Font.Oswald
title.Text = "DON'T LET THE FIRE DIE"
title.TextColor3 = TEXT_DARK
title.TextScaled = false
title.TextSize = 28
title.Parent = background

local titleConstraint = Instance.new("UITextSizeConstraint")
titleConstraint.MinTextSize = 14
titleConstraint.MaxTextSize = 32
titleConstraint.Parent = title

-- ── Bottom area: status, percentage, progress bar (stacked, bottom-centre) ────
-- Layout from the bottom up:  bar  →  percentage  →  status text

-- Status text (top line)
local statusLabel = Instance.new("TextLabel")
statusLabel.Name = "StatusLabel"
statusLabel.AnchorPoint = Vector2.new(0.5, 1)
statusLabel.Position = UDim2.new(0.5, 0, 1, -74)
statusLabel.Size = UDim2.new(0.6, 0, 0, 20)
statusLabel.BackgroundTransparency = 1
statusLabel.Font = Enum.Font.GothamMedium
statusLabel.Text = "LOADING"
statusLabel.TextColor3 = TEXT_DARK
statusLabel.TextSize = 15
statusLabel.Parent = background

local statusConstraint = Instance.new("UITextSizeConstraint")
statusConstraint.MinTextSize = 12
statusConstraint.MaxTextSize = 17
statusConstraint.Parent = statusLabel

-- Percentage (second line)
local percentLabel = Instance.new("TextLabel")
percentLabel.Name = "PercentLabel"
percentLabel.AnchorPoint = Vector2.new(0.5, 1)
percentLabel.Position = UDim2.new(0.5, 0, 1, -54)
percentLabel.Size = UDim2.new(0.6, 0, 0, 18)
percentLabel.BackgroundTransparency = 1
percentLabel.Font = Enum.Font.Gotham
percentLabel.Text = "0.00%"
percentLabel.TextColor3 = TEXT_MUTED
percentLabel.TextSize = 13
percentLabel.Parent = background

-- Track (flat, thick pill)
local track = Instance.new("Frame")
track.Name = "Track"
track.AnchorPoint = Vector2.new(0.5, 1)
track.Position = UDim2.new(0.5, 0, 1, -30)
track.Size = UDim2.new(0.3, 0, 0, 10)
track.BackgroundColor3 = TRACK_COLOR
track.BorderSizePixel = 0
track.Parent = background

local trackSizeLimit = Instance.new("UISizeConstraint")
trackSizeLimit.MinSize = Vector2.new(200, 10)
trackSizeLimit.MaxSize = Vector2.new(340, 10)
trackSizeLimit.Parent = track

local trackCorner = Instance.new("UICorner")
trackCorner.CornerRadius = UDim.new(1, 0)
trackCorner.Parent = track

-- Small dots just outside both ends of the bar
local function makeEndDot(name: string, xScale: number, xOffset: number)
	local dot = Instance.new("Frame")
	dot.Name = name
	dot.AnchorPoint = Vector2.new(0.5, 0.5)
	dot.Position = UDim2.new(xScale, xOffset, 0.5, 0)
	dot.Size = UDim2.fromOffset(5, 5)
	dot.BackgroundColor3 = TEXT_DARK
	dot.BorderSizePixel = 0
	dot.Parent = track
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(1, 0)
	corner.Parent = dot
end
makeEndDot("StartDot", 0, -12)
makeEndDot("EndDot", 1, 12)

-- Fill (solid, flat)
local fill = Instance.new("Frame")
fill.Name = "Fill"
fill.Size = UDim2.fromScale(0.04, 1)
fill.BackgroundColor3 = FILL_COLOR
fill.BorderSizePixel = 0
fill.ZIndex = 2
fill.Parent = track

local fillCorner = Instance.new("UICorner")
fillCorner.CornerRadius = UDim.new(1, 0)
fillCorner.Parent = fill

-- ── Progress logic ────────────────────────────────────────────────────────────
-- The percentage text counts up smoothly (like the reference) via a NumberValue.
local percentValue = Instance.new("NumberValue")
percentValue.Value = 0
percentValue.Changed:Connect(function(value: number)
	percentLabel.Text = string.format("%.2f%%", value)
end)

local FILL_TWEEN = TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local currentPercentTween: Tween? = nil

local function setProgress(ratio: number, message: string)
	statusLabel.Text = message
	local clamped = math.clamp(ratio, 0, 1)

	TweenService:Create(fill, FILL_TWEEN, {
		Size = UDim2.fromScale(math.max(clamped, 0.02), 1),
	}):Play()

	if currentPercentTween then
		currentPercentTween:Cancel()
	end
	local tween = TweenService:Create(percentValue, FILL_TWEEN, { Value = clamped * 100 })
	currentPercentTween = tween
	tween:Play()
end

local function preloadMenuAssets()
	setProgress(0.12, "LOADING")
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

	local menuSound = Instance.new("Sound")
	menuSound.SoundId = "rbxasset://sounds/MainMenuAudio.mp3"
	table.insert(assets, menuSound)

	setProgress(0.22, "LOADING")
	if #assets > 0 then
		local completed = 0
		local lastProgress = 0.22
		local ok = pcall(function()
			ContentProvider:PreloadAsync(assets, function(_, _)
				completed += 1
				local ratio = 0.22 + 0.68 * (completed / #assets)
				if ratio >= lastProgress + 0.025 or completed >= #assets then
					lastProgress = ratio
					setProgress(ratio, "LOADING")
				end
			end)
		end)
		if not ok then
			warn("[EarlyCurtain] Some menu preview assets could not be preloaded; Roblox will stream them as needed.")
		end
	end
	menuSound:Destroy()

	setProgress(0.82, "PREPARING SCENE")
	local sceneDeadline = os.clock() + 15
	while player:GetAttribute("MenuSceneReady") ~= true and os.clock() < sceneDeadline do
		task.wait(0.1)
	end
	setProgress(0.96, "ALMOST READY")
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

-- Make sure the bar visibly finishes at 100% before the curtain lifts.
setProgress(1, "READY")

local remainingLoadingTime = MINIMUM_LOADING_SECONDS - (os.clock() - loadingStartedAt)
if remainingLoadingTime > 0 then
	task.wait(remainingLoadingTime)
end

percentValue:Destroy()
gui:Destroy()
player:SetAttribute("EarlyCurtainFinished", true)