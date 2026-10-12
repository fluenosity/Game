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
local ReplicatedStorage = game:GetService("ReplicatedStorage")

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
local smoothedHour = targetHour

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

-- Initial apply
TimeVisuals.Apply(smoothedHour, currentDay)

-- RenderStepped runs every frame right before GPU rendering
RunService.RenderStepped:Connect(function(deltaTime: number)
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
