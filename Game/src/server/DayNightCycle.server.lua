--!strict
--[[
    DayNightCycle.server.lua
    Custom day/night cycle, time progression, and cloud system driver
    for "Don't Let the Fire Die". Developed for Fluenosity Studio.
    
    Advances a custom game clock through phases (Dawn -> Day -> Dusk -> Night),
    interpolating Lighting, Clouds, and Atmosphere properties between keyframes.
    Each successive night gets darker and more oppressive via DayModifiers.
    
    Exposes current state via attributes on ReplicatedStorage.FluenosityShared.TimeState
    and fires BindableEvents on phase and day changes for other server systems.
]]

local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Load configuration
local sharedFolder = ReplicatedStorage:WaitForChild("FluenosityShared")
local TimeConfig = require(sharedFolder:WaitForChild("TimeConfig"))

-- Get references to visual instances (with bootstrap auto-creation if running on fresh place)
local atmosphere = Lighting:FindFirstChildOfClass("Atmosphere")
if not atmosphere then
	atmosphere = Instance.new("Atmosphere")
	atmosphere.Name = "Atmosphere"
	atmosphere.Parent = Lighting
end

local clouds = Lighting:FindFirstChildOfClass("Clouds")
if not clouds then
	clouds = Instance.new("Clouds")
	clouds.Name = "Clouds"
	clouds.Parent = Lighting
end

-- Get or initialize TimeState folder and events
local timeState = sharedFolder:FindFirstChild("TimeState") :: Folder?
if not timeState then
	timeState = Instance.new("Folder")
	timeState.Name = "TimeState"
	timeState.Parent = sharedFolder
end

local phaseChangedEvent = timeState:FindFirstChild("PhaseChanged") :: BindableEvent?
if not phaseChangedEvent then
	phaseChangedEvent = Instance.new("BindableEvent")
	phaseChangedEvent.Name = "PhaseChanged"
	phaseChangedEvent.Parent = timeState
end

local dayChangedEvent = timeState:FindFirstChild("DayChanged") :: BindableEvent?
if not dayChangedEvent then
	dayChangedEvent = Instance.new("BindableEvent")
	dayChangedEvent.Name = "DayChanged"
	dayChangedEvent.Parent = timeState
end

-- ---------------------------------------------------------------------------
-- State
-- ---------------------------------------------------------------------------

local currentDay: number = TimeConfig.StartDay
local currentHour: number = TimeConfig.StartHour
local currentPhase: string = "Day"
local phaseProgress: number = 0.0

local lastPhase: string = ""
local lastDay: number = -1

-- ---------------------------------------------------------------------------
-- Helpers
-- ---------------------------------------------------------------------------

local function lerp(a: number, b: number, t: number): number
	return a + (b - a) * t
end

local function getPhaseFromHour(hour: number): string
	for _, phase in ipairs(TimeConfig.Phases) do
		if phase.Name == "Night" then
			if hour >= phase.StartHour or hour < phase.EndHour then
				return phase.Name
			end
		else
			if hour >= phase.StartHour and hour < phase.EndHour then
				return phase.Name
			end
		end
	end
	return "Day"
end

type Keyframe = {
	Hour: number,
	Brightness: number,
	Ambient: Color3,
	OutdoorAmbient: Color3,
	FogEnd: number,
	FogColor: Color3,
	ExposureCompensation: number,
	CloudCover: number,
	CloudColor: Color3,
	CloudDensity: number,
	AtmosphereDensity: number,
	AtmosphereColor: Color3,
	AtmosphereDecay: Color3,
	AtmosphereGlare: number,
	AtmosphereHaze: number,
}

local function getSurroundingKeyframes(hour: number): (Keyframe, Keyframe)
	local keyframes = TimeConfig.Keyframes
	local count = #keyframes

	if hour >= keyframes[count].Hour then
		return keyframes[count] :: Keyframe, keyframes[1] :: Keyframe
	end

	for i = 1, count - 1 do
		if hour >= keyframes[i].Hour and hour < keyframes[i + 1].Hour then
			return keyframes[i] :: Keyframe, keyframes[i + 1] :: Keyframe
		end
	end

	-- Before first keyframe: wrap from last to first
	return keyframes[count] :: Keyframe, keyframes[1] :: Keyframe
end

local function getKeyframeT(hour: number, k1: Keyframe, k2: Keyframe): number
	local span = k2.Hour - k1.Hour
	if span < 0 then
		span = (24 - k1.Hour) + k2.Hour
	end
	if span == 0 then return 0 end

	local diff = hour - k1.Hour
	if diff < 0 then
		diff = (24 - k1.Hour) + hour
	end
	return math.clamp(diff / span, 0, 1)
end

type DayModifier = { Darkness: number, FogMul: number, CloudMul: number, ExposureOffset: number }

local function getDayModifier(day: number): DayModifier
	local mod = TimeConfig.DayModifiers[day] or TimeConfig.DayModifiers[TimeConfig.MaxDay]
	if mod then
		return mod :: DayModifier
	end
	return { Darkness = 0, FogMul = 1, CloudMul = 1, ExposureOffset = 0 } :: DayModifier
end

-- Returns 0 during full day, 1 during full night, fading during dawn/dusk
local function getDarknessWeight(hour: number): number
	if hour >= 19 or hour < 5 then
		return 1.0
	elseif hour >= 5 and hour < 7 then
		return 1.0 - ((hour - 5) / 2)
	elseif hour >= 17 and hour < 19 then
		return (hour - 17) / 2
	end
	return 0.0
end

-- ---------------------------------------------------------------------------
-- Visual state application
-- ---------------------------------------------------------------------------

local function applyVisualState(hour: number, day: number)
	local k1, k2 = getSurroundingKeyframes(hour)
	local t = getKeyframeT(hour, k1, k2)
	local modifier = getDayModifier(day)
	local darknessWeight = getDarknessWeight(hour)

	-- Interpolate base properties
	local brightness = lerp(k1.Brightness, k2.Brightness, t)
	local ambient = k1.Ambient:lerp(k2.Ambient, t)
	local outdoorAmbient = k1.OutdoorAmbient:lerp(k2.OutdoorAmbient, t)
	local fogEnd = lerp(k1.FogEnd, k2.FogEnd, t)
	local fogColor = k1.FogColor:lerp(k2.FogColor, t)
	local exposure = lerp(k1.ExposureCompensation, k2.ExposureCompensation, t)

	local cloudCover = lerp(k1.CloudCover, k2.CloudCover, t)
	local cloudColor = k1.CloudColor:lerp(k2.CloudColor, t)
	local cloudDensity = lerp(k1.CloudDensity, k2.CloudDensity, t)

	local atmoDensity = lerp(k1.AtmosphereDensity, k2.AtmosphereDensity, t)
	local atmoColor = k1.AtmosphereColor:lerp(k2.AtmosphereColor, t)
	local atmoDecay = k1.AtmosphereDecay:lerp(k2.AtmosphereDecay, t)
	local atmoGlare = lerp(k1.AtmosphereGlare, k2.AtmosphereGlare, t)
	local atmoHaze = lerp(k1.AtmosphereHaze, k2.AtmosphereHaze, t)

	-- Apply day modifiers (weighted by how dark it currently is)
	local darkness = modifier.Darkness * darknessWeight
	local fogMul = lerp(1.0, modifier.FogMul, darknessWeight)
	local cloudMul = lerp(1.0, modifier.CloudMul, darknessWeight)

	-- Darken brightness
	brightness = brightness * (1.0 - darkness * 0.85)

	-- Darken ambient colors
	ambient = ambient:lerp(Color3.new(0, 0, 0), darkness * 0.5)
	outdoorAmbient = outdoorAmbient:lerp(Color3.new(0, 0, 0), darkness * 0.6)

	-- Thicken fog (reduce visibility distance)
	fogEnd = fogEnd / fogMul
	fogColor = fogColor:lerp(Color3.fromRGB(12, 12, 20), darkness * 0.4)

	-- Heavier, darker clouds at night
	cloudCover = math.clamp(cloudCover * cloudMul, 0, 1)
	cloudDensity = cloudDensity * cloudMul
	cloudColor = cloudColor:lerp(Color3.fromRGB(8, 8, 14), darkness * 0.5)

	-- Reduce exposure and atmosphere glare at night
	exposure = exposure + (modifier.ExposureOffset * darknessWeight)
	atmoGlare = atmoGlare * (1.0 - darknessWeight * 0.8)
	atmoHaze = atmoHaze * (1.0 - darknessWeight * 0.3)
	atmoDensity = atmoDensity * fogMul

	-- Apply to Lighting
	Lighting.ClockTime = hour
	Lighting.Brightness = brightness
	Lighting.Ambient = ambient
	Lighting.OutdoorAmbient = outdoorAmbient
	Lighting.FogEnd = fogEnd
	Lighting.FogColor = fogColor
	Lighting.ExposureCompensation = exposure

	-- Apply to Clouds
	if clouds then
		clouds.Cover = cloudCover
		clouds.Color = cloudColor
		clouds.Density = cloudDensity
	end

	-- Apply to Atmosphere
	if atmosphere then
		atmosphere.Density = atmoDensity
		atmosphere.Color = atmoColor
		atmosphere.Decay = atmoDecay
		atmosphere.Glare = atmoGlare
		atmosphere.Haze = atmoHaze
	end
end

-- ---------------------------------------------------------------------------
-- Time advancement
-- ---------------------------------------------------------------------------

local function getPhaseDuration(phaseName: string): number
	return TimeConfig.PhaseDurations[phaseName] or 60
end

local function getPhaseHours(phaseName: string): number
	for _, phase in ipairs(TimeConfig.Phases) do
		if phase.Name == phaseName then
			if phase.Name == "Night" then
				return (24 - phase.StartHour) + phase.EndHour
			else
				return phase.EndHour - phase.StartHour
			end
		end
	end
	return 10
end

local function advanceTime(deltaTime: number)
	local phaseName = getPhaseFromHour(currentHour)
	local duration = getPhaseDuration(phaseName)
	local phaseHours = getPhaseHours(phaseName)

	-- Advance game hours based on phase pacing
	local hoursPerSecond = phaseHours / duration
	currentHour = currentHour + (hoursPerSecond * deltaTime)

	-- Wrap past midnight
	if currentHour >= 24 then
		currentHour = currentHour - 24
	end

	local newPhase = getPhaseFromHour(currentHour)

	-- Day increments when transitioning from Night to Dawn
	if lastPhase == "Night" and newPhase == "Dawn" then
		currentDay = currentDay + 1
	end

	-- Calculate phase progress (0-1)
	for _, phase in ipairs(TimeConfig.Phases) do
		if phase.Name == newPhase then
			if phase.Name == "Night" then
				if currentHour >= phase.StartHour then
					phaseProgress = (currentHour - phase.StartHour) / phaseHours
				else
					phaseProgress = ((24 - phase.StartHour) + currentHour) / phaseHours
				end
			else
				phaseProgress = (currentHour - phase.StartHour) / phaseHours
			end
			break
		end
	end

	-- Fire phase change event
	if newPhase ~= lastPhase and lastPhase ~= "" then
		currentPhase = newPhase
		if phaseChangedEvent then
			phaseChangedEvent:Fire(currentPhase, currentDay)
		end
	end

	-- Fire day change event
	if currentDay ~= lastDay and lastDay ~= -1 then
		if dayChangedEvent then
			dayChangedEvent:Fire(currentDay)
		end
	end

	lastPhase = newPhase
	lastDay = currentDay

	-- Update TimeState attributes for other systems and clients
	if timeState then
		timeState:SetAttribute("CurrentDay", currentDay)
		timeState:SetAttribute("CurrentHour", currentHour)
		timeState:SetAttribute("CurrentPhase", newPhase)
		timeState:SetAttribute("PhaseProgress", phaseProgress)
	end

	-- Apply visual changes
	applyVisualState(currentHour, currentDay)
end

-- ---------------------------------------------------------------------------
-- Initialization
-- ---------------------------------------------------------------------------

currentPhase = getPhaseFromHour(currentHour)
lastPhase = currentPhase
lastDay = currentDay

applyVisualState(currentHour, currentDay)

if timeState then
	timeState:SetAttribute("CurrentDay", currentDay)
	timeState:SetAttribute("CurrentHour", currentHour)
	timeState:SetAttribute("CurrentPhase", currentPhase)
	timeState:SetAttribute("PhaseProgress", 0.0)
end

RunService.Heartbeat:Connect(function(deltaTime: number)
	advanceTime(deltaTime)
end)
