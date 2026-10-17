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
title.TextColor3 = Color3.fromRGB(28, 28, 28)
title.TextScaled = false
title.TextSize = 28
title.Parent = background

local titleConstraint = Instance.new("UITextSizeConstraint")
titleConstraint.MinTextSize = 14
titleConstraint.MaxTextSize = 32
titleConstraint.Parent = title

-- ── Bottom area: status text + thin progress bar ──────────────────────────────
local statusLabel = Instance.new("TextLabel")
statusLabel.Name = "StatusLabel"
statusLabel.AnchorPoint = Vector2.new(0.5, 1)
statusLabel.Position = UDim2.new(0.5, 0, 1, -52)
statusLabel.Size = UDim2.new(0.5, 0, 0, 18)
statusLabel.BackgroundTransparency = 1
statusLabel.Font = Enum.Font.GothamMedium
statusLabel.Text = "LOADING"
statusLabel.TextColor3 = Color3.fromRGB(140, 140, 140)
statusLabel.TextSize = 11
statusLabel.Parent = background

-- Track
local track = Instance.new("Frame")
track.Name = "Track"
track.AnchorPoint = Vector2.new(0.5, 1)
track.Position = UDim2.new(0.5, 0, 1, -28)
track.Size = UDim2.new(0.36, 0, 0, 2)
track.BackgroundColor3 = Color3.fromRGB(220, 220, 220)
track.BorderSizePixel = 0
track.Parent = background
local trackCorner = Instance.new("UICorner")
trackCorner.CornerRadius = UDim.new(1, 0)
trackCorner.Parent = track

-- Fill
local fill = Instance.new("Frame")
fill.Name = "Fill"
fill.Size = UDim2.fromScale(0.02, 1)
fill.BackgroundColor3 = Color3.fromRGB(200, 100, 30)
fill.BorderSizePixel = 0
fill.Parent = track
local fillCorner = Instance.new("UICorner")
fillCorner.CornerRadius = UDim.new(1, 0)
fillCorner.Parent = fill

local function setProgress(ratio: number, message: string)
	statusLabel.Text = message
	TweenService:Create(fill, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Size = UDim2.fromScale(math.clamp(ratio, 0.02, 1), 1),
	}):Play()
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
player:SetAttribute("EarlyCurtainFinished", true)
