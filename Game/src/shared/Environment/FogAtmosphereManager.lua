--!strict
--[[
    FogAtmosphereManager.lua
    Standalone Atmospheric Fog, Horizon Depth & Mountain Aerial Perspective Engine.
    Part of the Fluenosity Studio Modular Environment Suite.
    
    Responsibilities:
    - Authoritative control over Lighting.Atmosphere (Density, Offset, Haze, Color, Decay, Glare).
    - Authoritative control over Lighting distance fog (FogStart, FogEnd, FogColor).
    - Publishes BaseFogEnd and BaseFogColor attributes to Lighting so underwater/submersion
      controllers can blend seamlessly without hard-overriding world fog.
    - Presets for weather conditions and cinematic moods (Alpine Crisp, Horizon Mist, Dense Fog, etc.).
]]

local Lighting = game:GetService("Lighting")

local FogAtmosphereManager = {}

export type AtmospherePreset = {
	Density: number,
	Offset: number,
	Haze: number,
	Color: Color3,
	Decay: Color3,
	Glare: number,
	FogStart: number,
	FogEnd: number,
	FogColor: Color3,
}

local PRESETS: { [string]: AtmospherePreset } = {
	AlpineCrisp = {
		Density = 0.41,
		Offset = 0.857,
		Haze = 0.0,
		Color = Color3.fromRGB(97, 99, 97),
		Decay = Color3.fromRGB(106, 112, 125),
		Glare = 2.86,
		FogStart = 0,
		FogEnd = 2400,
		FogColor = Color3.fromRGB(195, 180, 165),
	},
	MountainMist = {
		Density = 0.36,
		Offset = 0.20,
		Haze = 1.60, -- Soft atmospheric mountain horizon mist
		Color = Color3.fromRGB(180, 204, 228),
		Decay = Color3.fromRGB(100, 125, 155),
		Glare = 0.12,
		FogStart = 100,
		FogEnd = 1800,
		FogColor = Color3.fromRGB(185, 195, 210),
	},
	DenseFogHazard = {
		Density = 0.52,
		Offset = 0.25,
		Haze = 2.80,
		Color = Color3.fromRGB(140, 150, 165),
		Decay = Color3.fromRGB(70, 78, 90),
		Glare = 0.02,
		FogStart = 0,
		FogEnd = 450, -- Closes distance visibility for intense survival tension
		FogColor = Color3.fromRGB(120, 128, 140),
	},
	NightValley = {
		Density = 0.30,
		Offset = 0.857,
		Haze = 0.0,
		Color = Color3.fromRGB(60, 75, 105),
		Decay = Color3.fromRGB(22, 28, 45),
		Glare = 0.0,
		FogStart = 0,
		FogEnd = 2400,
		FogColor = Color3.fromRGB(16, 20, 32),
	},
}

local cachedAtmosphere: Atmosphere? = nil
local currentPreset: string = "AlpineCrisp"

-- Current active values matching authored studio editor
local targetDensity: number = 0.41
local targetOffset: number = 0.857
local targetHaze: number = 0.0
local targetColor: Color3 = Color3.fromRGB(97, 99, 97)
local targetDecay: Color3 = Color3.fromRGB(106, 112, 125)
local targetGlare: number = 2.86

local targetFogStart: number = 0
local targetFogEnd: number = 2400
local targetFogColor: Color3 = Color3.fromRGB(195, 180, 165)

local currentDensity: number = targetDensity
local currentOffset: number = targetOffset
local currentHaze: number = targetHaze
local currentColor: Color3 = targetColor
local currentDecay: Color3 = targetDecay
local currentGlare: number = targetGlare

local currentFogStart: number = targetFogStart
local currentFogEnd: number = targetFogEnd
local currentFogColor: Color3 = targetFogColor

-- -----------------------------------------------------------------------------
-- Instance Lifecycle
-- -----------------------------------------------------------------------------

function FogAtmosphereManager.EnsureAtmosphere(): Atmosphere
	if cachedAtmosphere and cachedAtmosphere.Parent then
		return cachedAtmosphere
	end

	local existing = Lighting:FindFirstChildOfClass("Atmosphere")
	if existing then
		cachedAtmosphere = existing
		-- Adopt authored properties if not empty
		targetDensity = existing.Density
		targetOffset = existing.Offset
		targetHaze = existing.Haze
		targetColor = existing.Color
		targetDecay = existing.Decay
		targetGlare = existing.Glare
		currentDensity = targetDensity
		currentOffset = targetOffset
		currentHaze = targetHaze
		currentColor = targetColor
		currentDecay = targetDecay
		currentGlare = targetGlare
		return existing
	end

	local atmo = Instance.new("Atmosphere")
	atmo.Name = "ForestAtmosphere"
	atmo.Density = targetDensity
	atmo.Offset = targetOffset
	atmo.Haze = targetHaze
	atmo.Color = targetColor
	atmo.Decay = targetDecay
	atmo.Glare = targetGlare
	atmo.Parent = Lighting

	cachedAtmosphere = atmo
	return atmo
end

-- -----------------------------------------------------------------------------
-- Preset Management
-- -----------------------------------------------------------------------------

function FogAtmosphereManager.SetPreset(presetName: string, transitionDuration: number?)
	local preset = PRESETS[presetName]
	if not preset then
		warn(string.format("[FogAtmosphereManager] Unknown preset: %s", tostring(presetName)))
		return
	end

	currentPreset = presetName
	targetDensity = preset.Density
	targetOffset = preset.Offset
	targetHaze = preset.Haze
	targetColor = preset.Color
	targetDecay = preset.Decay
	targetGlare = preset.Glare
	targetFogStart = preset.FogStart
	targetFogEnd = preset.FogEnd
	targetFogColor = preset.FogColor

	local duration = transitionDuration or 2.0
	if duration <= 0 then
		currentDensity = targetDensity
		currentOffset = targetOffset
		currentHaze = targetHaze
		currentColor = targetColor
		currentDecay = targetDecay
		currentGlare = targetGlare
		currentFogStart = targetFogStart
		currentFogEnd = targetFogEnd
		currentFogColor = targetFogColor
	end
end

function FogAtmosphereManager.GetPreset(): string
	return currentPreset
end

function FogAtmosphereManager.GetPresets(): { [string]: AtmospherePreset }
	return PRESETS
end

-- -----------------------------------------------------------------------------
-- Frame Update
-- -----------------------------------------------------------------------------

export type BaseAtmosphereParams = {
	Density: number?,
	Offset: number?,
	Haze: number?,
	Color: Color3?,
	Decay: Color3?,
	Glare: number?,
	FogStart: number?,
	FogEnd: number?,
	FogColor: Color3?,
}

function FogAtmosphereManager.Update(dt: number, baseParams: BaseAtmosphereParams?)
	local atmo = FogAtmosphereManager.EnsureAtmosphere()

	local activeDensity = (baseParams and baseParams.Density) or targetDensity
	local activeOffset = (baseParams and baseParams.Offset) or targetOffset
	local activeHaze = (baseParams and baseParams.Haze) or targetHaze
	local activeColor = (baseParams and baseParams.Color) or targetColor
	local activeDecay = (baseParams and baseParams.Decay) or targetDecay
	local activeGlare = (baseParams and baseParams.Glare) or targetGlare

	local activeFogStart = (baseParams and baseParams.FogStart) or targetFogStart
	local activeFogEnd = (baseParams and baseParams.FogEnd) or targetFogEnd
	local activeFogColor = (baseParams and baseParams.FogColor) or targetFogColor

	if baseParams then
		currentDensity = activeDensity
		currentOffset = activeOffset
		currentHaze = activeHaze
		currentColor = activeColor
		currentDecay = activeDecay
		currentGlare = activeGlare
		currentFogStart = activeFogStart
		currentFogEnd = activeFogEnd
		currentFogColor = activeFogColor
	else
		-- Smooth exponential lerp for preset switching
		local blend = math.clamp(dt * 3.5, 0, 1)
		currentDensity = currentDensity + (activeDensity - currentDensity) * blend
		currentOffset = currentOffset + (activeOffset - currentOffset) * blend
		currentHaze = currentHaze + (activeHaze - currentHaze) * blend
		currentColor = currentColor:Lerp(activeColor, blend)
		currentDecay = currentDecay:Lerp(activeDecay, blend)
		currentGlare = currentGlare + (activeGlare - currentGlare) * blend

		currentFogStart = currentFogStart + (activeFogStart - currentFogStart) * blend
		currentFogEnd = currentFogEnd + (activeFogEnd - currentFogEnd) * blend
		currentFogColor = currentFogColor:Lerp(activeFogColor, blend)
	end

	-- Apply to Atmosphere
	atmo.Density = currentDensity
	atmo.Offset = currentOffset
	atmo.Haze = currentHaze
	atmo.Color = currentColor
	atmo.Decay = currentDecay
	atmo.Glare = currentGlare

	-- Apply to Lighting Fog
	Lighting.FogStart = currentFogStart
	Lighting.FogEnd = currentFogEnd
	Lighting.FogColor = currentFogColor

	-- Expose current baseline to other systems (e.g. UnderwaterController)
	Lighting:SetAttribute("BaseFogEnd", currentFogEnd)
	Lighting:SetAttribute("BaseFogColor", currentFogColor)
	Lighting:SetAttribute("BaseFogStart", currentFogStart)
end

-- -----------------------------------------------------------------------------
-- Initialization
-- -----------------------------------------------------------------------------

function FogAtmosphereManager.Init()
	FogAtmosphereManager.EnsureAtmosphere()
	Lighting.FogStart = targetFogStart
	Lighting.FogEnd = targetFogEnd
	Lighting.FogColor = targetFogColor
	Lighting:SetAttribute("BaseFogEnd", targetFogEnd)
	Lighting:SetAttribute("BaseFogColor", targetFogColor)
	Lighting:SetAttribute("BaseFogStart", targetFogStart)
end

return FogAtmosphereManager
