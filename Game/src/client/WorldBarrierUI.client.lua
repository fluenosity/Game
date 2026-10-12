--!strict
--[[
    WorldBarrierUI.client.lua
    Client-side cinematic horror warning vignette & smooth return transition
    for "Don't Let the Fire Die" (Fluenosity Studio).
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local FluenosityShared = ReplicatedStorage:WaitForChild("FluenosityShared")
local warnRemote = FluenosityShared:WaitForChild("WorldBarrierWarning") :: RemoteEvent
local returnRemote = FluenosityShared:WaitForChild("WorldBarrierReturn") :: RemoteEvent

-- Build the ScreenGui
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "WorldBarrierWarning"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true
screenGui.DisplayOrder = 95
screenGui.Parent = playerGui

-- 1. Full-screen blackout transition frame for smooth teleport
local blackout = Instance.new("Frame")
blackout.Name = "Blackout"
blackout.Size = UDim2.new(1, 0, 1, 0)
blackout.BackgroundColor3 = Color3.fromRGB(8, 10, 15)
blackout.BackgroundTransparency = 1
blackout.BorderSizePixel = 0
blackout.ZIndex = 10
blackout.Parent = screenGui

local blackoutLabel = Instance.new("TextLabel")
blackoutLabel.Name = "BlackoutMessage"
blackoutLabel.Size = UDim2.new(0.8, 0, 0.12, 0)
blackoutLabel.Position = UDim2.new(0.1, 0, 0.44, 0)
blackoutLabel.BackgroundTransparency = 1
blackoutLabel.Text = "The mountain fog thickens..."
blackoutLabel.TextColor3 = Color3.fromRGB(240, 230, 220)
blackoutLabel.Font = Enum.Font.GothamMedium
blackoutLabel.TextScaled = true
blackoutLabel.TextTransparency = 1
blackoutLabel.ZIndex = 11
blackoutLabel.Parent = blackout

-- 2. Creeping Horror Perimeter Vignette (Radial gradient dark edges)
local vignette = Instance.new("ImageLabel")
vignette.Name = "Vignette"
vignette.Size = UDim2.new(1, 0, 1, 0)
vignette.BackgroundTransparency = 1
vignette.Image = "rbxassetid://4576475446" -- Clean radial vignette mask
vignette.ImageColor3 = Color3.fromRGB(15, 8, 8)
vignette.ImageTransparency = 1
vignette.ZIndex = 5
vignette.Parent = screenGui

-- 3. Subtle Warning Banner at Top of Screen
local banner = Instance.new("Frame")
banner.Name = "WarningBanner"
banner.Size = UDim2.new(0.4, 0, 0.05, 0)
banner.Position = UDim2.new(0.3, 0, 0.08, 0)
banner.BackgroundColor3 = Color3.fromRGB(20, 12, 12)
banner.BackgroundTransparency = 1
banner.BorderSizePixel = 0
banner.ZIndex = 6
banner.Parent = screenGui

local bannerCorner = Instance.new("UICorner")
bannerCorner.CornerRadius = UDim.new(0, 8)
bannerCorner.Parent = banner

local bannerStroke = Instance.new("UIStroke")
bannerStroke.Color = Color3.fromRGB(180, 50, 40)
bannerStroke.Transparency = 1
bannerStroke.Thickness = 1.2
bannerStroke.Parent = banner

local bannerText = Instance.new("TextLabel")
bannerText.Name = "BannerText"
bannerText.Size = UDim2.new(1, -20, 1, 0)
bannerText.Position = UDim2.new(0, 10, 0, 0)
bannerText.BackgroundTransparency = 1
bannerText.Text = "You feel a chilling dread. Return to camp."
bannerText.TextColor3 = Color3.fromRGB(255, 180, 160)
bannerText.Font = Enum.Font.GothamMedium
bannerText.TextScaled = true
bannerText.TextTransparency = 1
bannerText.ZIndex = 7
bannerText.Parent = banner

-- Remote listeners
warnRemote.OnClientEvent:Connect(function(action: string, arg1: any, arg2: any)
	if action == "proximity" then
		local ratio = typeof(arg1) == "number" and arg1 or 0
		local msg = typeof(arg2) == "string" and arg2 or "Return to camp."

		-- Smoothly update vignette transparency
		local targetTransparency = 1.0 - (ratio * 0.72)
		TweenService:Create(vignette, TweenInfo.new(0.25, Enum.EasingStyle.Quad), {
			ImageTransparency = targetTransparency
		}):Play()

		if ratio > 0.3 then
			bannerText.Text = msg
			TweenService:Create(banner, TweenInfo.new(0.3), { BackgroundTransparency = 0.35 }):Play()
			TweenService:Create(bannerStroke, TweenInfo.new(0.3), { Transparency = 0.4 }):Play()
			TweenService:Create(bannerText, TweenInfo.new(0.3), { TextTransparency = 0.0 }):Play()
		else
			TweenService:Create(banner, TweenInfo.new(0.3), { BackgroundTransparency = 1.0 }):Play()
			TweenService:Create(bannerStroke, TweenInfo.new(0.3), { Transparency = 1.0 }):Play()
			TweenService:Create(bannerText, TweenInfo.new(0.3), { TextTransparency = 1.0 }):Play()
		end

	elseif action == "clear" then
		TweenService:Create(vignette, TweenInfo.new(0.5, Enum.EasingStyle.Quad), { ImageTransparency = 1.0 }):Play()
		TweenService:Create(banner, TweenInfo.new(0.4), { BackgroundTransparency = 1.0 }):Play()
		TweenService:Create(bannerStroke, TweenInfo.new(0.4), { Transparency = 1.0 }):Play()
		TweenService:Create(bannerText, TweenInfo.new(0.4), { TextTransparency = 1.0 }):Play()
	end
end)

returnRemote.OnClientEvent:Connect(function(action: string, msg: string?)
	if action == "start_fade" then
		if msg then
			blackoutLabel.Text = msg
		end
		-- Smooth 0.25s blackout transition
		TweenService:Create(blackout, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			BackgroundTransparency = 0.0
		}):Play()
		TweenService:Create(blackoutLabel, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			TextTransparency = 0.0
		}):Play()

	elseif action == "complete_fade" then
		-- Smooth 0.6s fade back in
		task.delay(0.2, function()
			TweenService:Create(blackout, TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
				BackgroundTransparency = 1.0
			}):Play()
			TweenService:Create(blackoutLabel, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
				TextTransparency = 1.0
			}):Play()
			TweenService:Create(vignette, TweenInfo.new(0.5, Enum.EasingStyle.Quad), {
				ImageTransparency = 1.0
			}):Play()
		end)
	end
end)

print("🛡️ [WorldBarrierUI] Smooth horror boundary client active.")
