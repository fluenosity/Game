--!strict
--[[
    CloudManager.lua
    Standalone Global Volumetric Cloud & Atmospheric Wind Engine.
    Part of the Fluenosity Studio Modular Environment Suite.
    
    Responsibilities:
    - Authoritative lifecycle of workspace.Terrain.Clouds.
    - Physical wind simulation via workspace.GlobalWind for realistic cloud drift.
    - Real-time procedural organic morphing (noise-based breathing of Cover and Density).
    - Smooth preset transitions (Alpine Clear, Fluffy Midday, Overcast, Stormy, Milky Way Night).
]]

local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")

local CloudManager = {}

export type CloudPreset = {
	Cover: number,
	Density: number,
	Color: Color3,
	Wind: Vector3,
	MorphSpeed: number,
	MorphAmount: number,
}

local PRESETS: { [string]: CloudPreset } = {
	AlpineClear = {
		Cover = 0.35,
		Density = 0.55,
		Color = Color3.fromRGB(250, 252, 255),
		Wind = Vector3.new(14, 0, 8),
		MorphSpeed = 0.04,
		MorphAmount = 0.03,
	},
	FluffyMidday = {
		Cover = 0.62,
		Density = 0.70,
		Color = Color3.fromRGB(255, 255, 255),
		Wind = Vector3.new(18, 0, 12),
		MorphSpeed = 0.05,
		MorphAmount = 0.04,
	},
	OvercastBrooding = {
		Cover = 0.82,
		Density = 0.78,
		Color = Color3.fromRGB(195, 202, 215),
		Wind = Vector3.new(24, 0, 16),
		MorphSpeed = 0.07,
		MorphAmount = 0.06,
	},
	StormyTension = {
		Cover = 0.92,
		Density = 0.88,
		Color = Color3.fromRGB(85, 92, 110),
		Wind = Vector3.new(34, 0, 22),
		MorphSpeed = 0.09,
		MorphAmount = 0.08,
	},
	MilkyWayNight = {
		Cover = 0.18, -- Opens up cloud cover so the 4K Milky Way Galaxy and starfield are prominently visible
		Density = 0.50,
		Color = Color3.fromRGB(48, 52, 72),
		Wind = Vector3.new(10, 0, 6),
		MorphSpeed = 0.03,
		MorphAmount = 0.02,
	},
}

local cachedClouds: Clouds? = nil
local currentPreset: string = "FluffyMidday"

-- Internal state for smooth blending
local targetCover: number = 0.62
local targetDensity: number = 0.70
local targetColor: Color3 = Color3.fromRGB(255, 255, 255)
local targetWind: Vector3 = Vector3.new(18, 0, 12)

local currentCover: number = targetCover
local currentDensity: number = targetDensity
local currentColor: Color3 = targetColor
local currentWind: Vector3 = targetWind

local morphSpeed: number = 0.05
local morphAmount: number = 0.04
local morphTimer: number = 0.0

-- -----------------------------------------------------------------------------
-- Instance Management
-- -----------------------------------------------------------------------------

function CloudManager.EnsureInstance(): Clouds
	if cachedClouds and cachedClouds.Parent then
		return cachedClouds
	end

	-- Purge any duplicate or accidental Clouds under Lighting
	for _, child in ipairs(Lighting:GetChildren()) do
		if child:IsA("Clouds") then
			pcall(function() child:Destroy() end)
		end
	end

	local terrain = Workspace.Terrain
	local existing = terrain:FindFirstChildOfClass("Clouds")
	if existing then
		cachedClouds = existing
		return existing
	end

	local newClouds = Instance.new("Clouds")
	newClouds.Name = "VolumetricClouds"
	newClouds.Cover = targetCover
	newClouds.Density = targetDensity
	newClouds.Color = targetColor
	newClouds.Enabled = true
	newClouds.Parent = terrain

	cachedClouds = newClouds
	return newClouds
end

-- -----------------------------------------------------------------------------
-- Presets & Controls
-- -----------------------------------------------------------------------------

function CloudManager.SetPreset(presetName: string, transitionDuration: number?)
	local preset = PRESETS[presetName]
	if not preset then
		warn(string.format("[CloudManager] Unknown preset: %s", tostring(presetName)))
		return
	end

	currentPreset = presetName
	targetCover = preset.Cover
	targetDensity = preset.Density
	targetColor = preset.Color
	targetWind = preset.Wind
	morphSpeed = preset.MorphSpeed
	morphAmount = preset.MorphAmount

	local duration = transitionDuration or 2.0
	if duration <= 0 then
		currentCover = targetCover
		currentDensity = targetDensity
		currentColor = targetColor
		currentWind = targetWind
		Workspace.GlobalWind = currentWind
	end
end

function CloudManager.GetPreset(): string
	return currentPreset
end

function CloudManager.GetPresets(): { [string]: CloudPreset }
	return PRESETS
end

function CloudManager.SetWind(wind: Vector3)
	targetWind = wind
	Workspace.GlobalWind = wind
end

function CloudManager.SetCustomValues(cover: number?, density: number?, color: Color3?, wind: Vector3?)
	if cover then targetCover = math.clamp(cover, 0, 1) end
	if density then targetDensity = math.clamp(density, 0, 1) end
	if color then targetColor = color end
	if wind then
		targetWind = wind
		Workspace.GlobalWind = wind
	end
end

-- -----------------------------------------------------------------------------
-- Frame Update (Called per frame or on visual tick)
-- -----------------------------------------------------------------------------

function CloudManager.Update(dt: number, baseCover: number?, baseDensity: number?, baseColor: Color3?)
	local clouds = CloudManager.EnsureInstance()

	-- If external caller provides base time-of-day values, blend toward them
	local activeTargetCover = baseCover or targetCover
	local activeTargetDensity = baseDensity or targetDensity
	local activeTargetColor = baseColor or targetColor

	-- Smooth exponential lerp toward target values
	local blendFactor = math.clamp(dt * 3.5, 0, 1)
	currentCover = currentCover + (activeTargetCover - currentCover) * blendFactor
	currentDensity = currentDensity + (activeTargetDensity - currentDensity) * blendFactor
	currentColor = currentColor:Lerp(activeTargetColor, blendFactor)

	-- Procedural organic breathing noise
	morphTimer = morphTimer + dt * morphSpeed
	local shapeNoise = (math.sin(morphTimer) * 0.7 + math.sin(morphTimer * 2.3) * 0.3) * morphAmount
	local densityNoise = math.cos(morphTimer * 0.8) * (morphAmount * 0.75)

	clouds.Cover = math.clamp(currentCover + shapeNoise, 0.05, 0.95)
	clouds.Density = math.clamp(currentDensity + densityNoise, 0.10, 0.95)
	clouds.Color = currentColor
	clouds.Enabled = true
end

-- -----------------------------------------------------------------------------
-- Initialization
-- -----------------------------------------------------------------------------

function CloudManager.Init()
	CloudManager.EnsureInstance()
	Workspace.GlobalWind = targetWind
end

return CloudManager
