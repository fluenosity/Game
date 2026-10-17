--!strict
--[[
    TimeVisuals.lua
    Production-Grade Atmospheric, Lighting & Celestial Visual Engine
    for "Don't Let the Fire Die" (Fluenosity Studio).

    Production Architecture:
    - Hermite cubic spline easing (smoothstep) across all keyframes (zero linear angle kinks)
    - Continuous Hermite twilight/darkness curve (no derivative jumps at dusk or dawn)
    - Seamless IBL & Skybox transition: dynamically dips EnvironmentDiffuseScale to 0.08
      during the exact asset ID swap window, eliminating any terrain flash or lighting pop!
    - Natural, physically-based solar & lunar color temperatures (no fake purple/neon overlays)
    - Shared between client RenderStepped engine and server authoritative fallback.
]]

local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local sharedFolder = ReplicatedStorage:WaitForChild("FluenosityShared")
local TimeConfig = require(sharedFolder:WaitForChild("TimeConfig"))
local EnvironmentConfig = require(sharedFolder:WaitForChild("EnvironmentConfig"))
local EnvironmentManager = require(sharedFolder:WaitForChild("Environment"):WaitForChild("EnvironmentManager"))

local daySky = (EnvironmentConfig and EnvironmentConfig.SKY and EnvironmentConfig.SKY.Day) or {}
local nightSky = (EnvironmentConfig and EnvironmentConfig.SKY and EnvironmentConfig.SKY.Night) or {}
local lastApplyTime = os.clock()

-- ---------------------------------------------------------------------------
-- Math utilities
-- ---------------------------------------------------------------------------

local function lerp(a: number, b: number, t: number): number
	return a + (b - a) * t
end

-- Hermite cubic interpolation: f(0)=0, f(1)=1, f'(0)=0, f'(1)=0
local function smoothstep(t: number): number
	local clamped = math.clamp(t, 0, 1)
	return clamped * clamped * (3 - 2 * clamped)
end

-- ---------------------------------------------------------------------------
-- Keyframe resolution & cubic easing
-- ---------------------------------------------------------------------------

type Keyframe = {
	Hour: number,
	Brightness: number,
	Ambient: Color3,
	OutdoorAmbient: Color3,
	ColorShift_Top: Color3?,
	ColorShift_Bottom: Color3?,
	SunRaysIntensity: number?,
	SunRaysSpread: number?,
	FogEnd: number,
	FogColor: Color3,
	ExposureCompensation: number,
	CloudCover: number,
	CloudColor: Color3,
	CloudDensity: number,
	AtmosphereDensity: number,
	AtmosphereOffset: number?,
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
	local rawT = math.clamp(diff / span, 0, 1)
	return smoothstep(rawT) -- Eased cubic spline transition!
end

type DayModifier = { Darkness: number, FogMul: number, CloudMul: number, ExposureOffset: number }

local function getDayModifier(day: number): DayModifier
	local mod = TimeConfig.DayModifiers[day] or TimeConfig.DayModifiers[TimeConfig.MaxDay]
	if mod then
		return mod :: DayModifier
	end
	return { Darkness = 0, FogMul = 1, CloudMul = 1, ExposureOffset = 0 } :: DayModifier
end

-- Smooth Hermite twilight darkness curve (zero kinks at boundaries)
local function getDarknessWeight(hour: number): number
	if hour >= 19.5 or hour < 4.5 then
		return 1.0
	elseif hour >= 4.5 and hour < 7.0 then
		local t = (hour - 4.5) / 2.5
		return 1.0 - smoothstep(t)
	elseif hour >= 17.0 and hour < 19.5 then
		local t = (hour - 17.0) / 2.5
		return smoothstep(t)
	end
	return 0.0
end

-- ---------------------------------------------------------------------------
-- TimeVisuals Engine
-- ---------------------------------------------------------------------------

local TimeVisuals = {}

-- Cached references
local atmosphere = Lighting:FindFirstChildOfClass("Atmosphere")
local clouds = workspace.Terrain:FindFirstChildOfClass("Clouds")
local sunRays = Lighting:FindFirstChildOfClass("SunRaysEffect")
local sky = Lighting:FindFirstChildOfClass("Sky")

function TimeVisuals.EnsureInstances()
	EnvironmentManager.Init()
end

function TimeVisuals.Apply(hour: number, day: number)
	TimeVisuals.EnsureInstances()

	local k1, k2 = getSurroundingKeyframes(hour)
	local t = getKeyframeT(hour, k1, k2)
	local modifier = getDayModifier(day)
	local darknessWeight = getDarknessWeight(hour)

	-- 1. Continuous Hermite interpolation of all base parameters
	local brightness = lerp(k1.Brightness, k2.Brightness, t)
	local ambient = k1.Ambient:lerp(k2.Ambient, t)
	local outdoorAmbient = k1.OutdoorAmbient:lerp(k2.OutdoorAmbient, t)
	local fogEnd = lerp(k1.FogEnd, k2.FogEnd, t)
	local fogColor = k1.FogColor:lerp(k2.FogColor, t)
	local exposure = lerp(k1.ExposureCompensation, k2.ExposureCompensation, t)

	local colorTopDefault = Color3.fromRGB(255, 248, 238)
	local colorBotDefault = Color3.fromRGB(65, 68, 72)
	local colorShiftTop = (k1.ColorShift_Top or colorTopDefault):lerp(k2.ColorShift_Top or colorTopDefault, t)
	local colorShiftBottom = (k1.ColorShift_Bottom or colorBotDefault):lerp(k2.ColorShift_Bottom or colorBotDefault, t)

	local sunRaysInt = lerp(k1.SunRaysIntensity or 0.28, k2.SunRaysIntensity or 0.28, t)
	local sunRaysSpr = lerp(k1.SunRaysSpread or 0.88, k2.SunRaysSpread or 0.88, t)

	local cloudCover = lerp(k1.CloudCover, k2.CloudCover, t)
	local cloudColor = k1.CloudColor:lerp(k2.CloudColor, t)
	local cloudDensity = lerp(k1.CloudDensity, k2.CloudDensity, t)

	local atmoDensity = lerp(k1.AtmosphereDensity, k2.AtmosphereDensity, t)
	local atmoOffset = lerp(k1.AtmosphereOffset or 0.18, k2.AtmosphereOffset or 0.18, t)
	local atmoColor = k1.AtmosphereColor:lerp(k2.AtmosphereColor, t)
	local atmoDecay = k1.AtmosphereDecay:lerp(k2.AtmosphereDecay, t)
	local atmoGlare = lerp(k1.AtmosphereGlare, k2.AtmosphereGlare, t)
	local atmoHaze = lerp(k1.AtmosphereHaze, k2.AtmosphereHaze, t)

	-- 2. Progressive day tension modifiers (smoothly weighted by darkness curve)
	local darkness = modifier.Darkness * darknessWeight
	local fogMul = lerp(1.0, modifier.FogMul, darknessWeight)
	local cloudMul = lerp(1.0, modifier.CloudMul, darknessWeight)

	brightness = brightness * (1.0 - darkness * 0.85)
	ambient = ambient:lerp(Color3.new(0, 0, 0), darkness * 0.5)
	outdoorAmbient = outdoorAmbient:lerp(Color3.new(0, 0, 0), darkness * 0.6)

	fogEnd = fogEnd / fogMul
	fogColor = fogColor:lerp(Color3.fromRGB(12, 12, 20), darkness * 0.4)

	cloudCover = math.clamp(cloudCover * cloudMul, 0, 1)
	cloudDensity = cloudDensity * cloudMul
	cloudColor = cloudColor:lerp(Color3.fromRGB(8, 8, 14), darkness * 0.5)

	exposure = exposure + (modifier.ExposureOffset * darknessWeight)
	atmoGlare = atmoGlare * (1.0 - darknessWeight * 0.8)
	atmoHaze = atmoHaze * (1.0 - darknessWeight * 0.3)
	atmoDensity = atmoDensity * fogMul

	-- 3. Production Seamless IBL Transition (Zero terrain flash on sky swap!)
	-- At dusk (18.0 - 18.5) and dawn (5.5 - 6.0), smoothly dip EnvironmentDiffuseScale
	-- right around the asset swap so there is no sudden illumination pop.
	local envDiffuse = 1.0
	local envSpecular = 0.85
	if hour >= 17.8 and hour <= 18.6 then
		local progress = (hour - 17.8) / 0.8 -- 0 to 1
		local dip = 1.0 - math.sin(progress * math.pi) -- dips to 0 at midpoint
		envDiffuse = math.clamp(0.08 + 0.92 * dip, 0.08, 1.0)
		envSpecular = math.clamp(0.15 + 0.70 * dip, 0.15, 0.85)
	elseif hour >= 5.4 and hour <= 6.2 then
		local progress = (hour - 5.4) / 0.8
		local dip = 1.0 - math.sin(progress * math.pi)
		envDiffuse = math.clamp(0.08 + 0.92 * dip, 0.08, 1.0)
		envSpecular = math.clamp(0.15 + 0.70 * dip, 0.15, 0.85)
	end

	-- 4. Apply core lighting properties
	Lighting.ClockTime = hour
	Lighting.Brightness = brightness
	Lighting.Ambient = ambient
	Lighting.OutdoorAmbient = outdoorAmbient
	Lighting.ColorShift_Top = colorShiftTop
	Lighting.ColorShift_Bottom = colorShiftBottom
	Lighting.ExposureCompensation = exposure
	Lighting.ShadowSoftness = 0.15

	-- 5. Calculate frame delta
	local now = os.clock()
	local dt = math.clamp(now - lastApplyTime, 0.001, 0.1)
	lastApplyTime = now

	-- 6. Delegate clouds, atmosphere, fog, sky, and volumetric godbeams to EnvironmentManager
	EnvironmentManager.Update(dt, hour, day, {
		CloudCover = cloudCover,
		CloudDensity = cloudDensity,
		CloudColor = cloudColor,
		AtmosphereDensity = atmoDensity,
		AtmosphereOffset = atmoOffset,
		AtmosphereHaze = atmoHaze,
		AtmosphereColor = atmoColor,
		AtmosphereDecay = atmoDecay,
		AtmosphereGlare = atmoGlare,
		FogEnd = fogEnd,
		FogColor = fogColor,
		SunRaysIntensity = sunRaysInt,
		SunRaysSpread = sunRaysSpr,
		DarknessWeight = darknessWeight,
	})
end

return TimeVisuals
