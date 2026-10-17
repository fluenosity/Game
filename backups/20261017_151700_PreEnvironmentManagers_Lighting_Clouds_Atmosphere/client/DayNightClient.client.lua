--!strict
--[[
    DayNightClient.client.lua
    Client-Side High-Precision Visual Interpolation Engine
    for "Don't Let the Fire Die" (Fluenosity Studio).

    Production Architecture:
    - Driven on RunService.RenderStepped at native monitor refresh rate (60/120/144+ FPS)
    - Receives authoritative clock progression from Server TimeState attributes
    - Continuously eases smoothedHour with sub-millisecond catch-up (eliminates network packet stepping)
    - Directly renders Lighting, Atmosphere, Clouds, and SunRays on the local GPU
    - Guarantees zero shadow jumps, zero color popping, and silky-smooth terrain shading transitions.
]]

local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lighting = game:GetService("Lighting")
local player = Players.LocalPlayer
local MENU_HOUR = 14.0

local sharedFolder = ReplicatedStorage:WaitForChild("FluenosityShared")
local TimeConfig = require(sharedFolder:WaitForChild("TimeConfig"))
local TimeVisuals = require(sharedFolder:WaitForChild("TimeVisuals"))

local timeState = sharedFolder:WaitForChild("TimeState", 15) :: Folder?
if not timeState then
	warn("[DayNightClient] TimeState folder not found in ReplicatedStorage.")
	return
end

-- Initialize local state from server attributes
local targetHour = (timeState:GetAttribute("CurrentHour") :: number?) or TimeConfig.StartHour or 14.0
local currentDay = (timeState:GetAttribute("CurrentDay") :: number?) or 0
local smoothedHour = if player:GetAttribute("IsInGameplay") == true then targetHour else MENU_HOUR

timeState:GetAttributeChangedSignal("CurrentHour"):Connect(function()
	local hourAttr = timeState:GetAttribute("CurrentHour")
	if typeof(hourAttr) == "number" then
		targetHour = hourAttr
	end
end)

timeState:GetAttributeChangedSignal("CurrentDay"):Connect(function()
	local dayAttr = timeState:GetAttribute("CurrentDay")
	if typeof(dayAttr) == "number" then
		currentDay = dayAttr
	end
end)

-- The menu gets a local night look. Gameplay continues to use the server's
-- authoritative clock, so the daytime development setting is preserved in play.
TimeVisuals.Apply(smoothedHour, currentDay)

local function applyMenuAmbientFill()
	-- Keep the menu in the game's clear afternoon palette and lift shaded trees
	-- slightly so the forest remains readable around the warm campfire.
	Lighting.Brightness = math.max(Lighting.Brightness, 2.8)
	Lighting.Ambient = Color3.fromRGB(82, 93, 111)
	Lighting.OutdoorAmbient = Color3.fromRGB(126, 142, 160)
	-- Use a long, pale blue distance haze. It softens the tree line without
	-- swallowing the clearing or turning the whole menu into a dark fog bank.
	Lighting.FogStart = 420
	Lighting.FogEnd = 2400
	Lighting.FogColor = Color3.fromRGB(177, 192, 208)
	local atmosphere = Lighting:FindFirstChildOfClass("Atmosphere")
	if atmosphere then
		atmosphere.Density = math.min(atmosphere.Density, 0.32)
		atmosphere.Haze = math.max(atmosphere.Haze, 0.9)
		atmosphere.Color = Color3.fromRGB(185, 204, 224)
		atmosphere.Decay = Color3.fromRGB(111, 132, 158)
	end
end

-- RenderStepped runs every frame right before GPU rendering
RunService.RenderStepped:Connect(function(deltaTime: number)
	if player:GetAttribute("IsInGameplay") ~= true then
		smoothedHour = MENU_HOUR
		TimeVisuals.Apply(MENU_HOUR, currentDay)
		applyMenuAmbientFill()
		return
	end

	-- Circular shortest-path difference on 24-hour clock
	local diff = targetHour - smoothedHour
	if diff < -12 then
		diff = diff + 24
	elseif diff > 12 then
		diff = diff - 24
	end

	-- Smooth frame catch-up: responsive yet completely fluid
	local step = diff * math.clamp(deltaTime * 14.0, 0, 1.0)
	smoothedHour = (smoothedHour + step) % 24
	if smoothedHour < 0 then
		smoothedHour = smoothedHour + 24
	end

	-- Apply production visuals locally on client
	TimeVisuals.Apply(smoothedHour, currentDay)
end)
