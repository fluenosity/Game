--!strict
--[[
    EnvironmentManager.lua
    Master Orchestrator for "Don't Let the Fire Die" Environment & Visuals Suite.
    Fluenosity Studio Production Architecture.
    
    Coordinates the 4 standalone environment subsystems:
    1. CloudManager: Volumetric clouds, physical wind drift, procedural morphing.
    2. VolumetricLightingManager: SunRays godbeams, campfire volumetric cones, light shafts.
    3. FogAtmosphereManager: Horizon depth fog, mountain mist, aerial perspective.
    4. CelestialSkyManager: Alpine day <-> 4K Milky Way Galaxy night, starfield emergence.
]]

local Lighting = game:GetService("Lighting")

local CloudManager = require(script.Parent:WaitForChild("CloudManager"))
local VolumetricLightingManager = require(script.Parent:WaitForChild("VolumetricLightingManager"))
local FogAtmosphereManager = require(script.Parent:WaitForChild("FogAtmosphereManager"))
local CelestialSkyManager = require(script.Parent:WaitForChild("CelestialSkyManager"))

local EnvironmentManager = {
	Clouds = CloudManager,
	VolumetricLighting = VolumetricLightingManager,
	Atmosphere = FogAtmosphereManager,
	Sky = CelestialSkyManager,
}

local initialized = false

-- -----------------------------------------------------------------------------
-- Master Post-Processing Instances (ColorCorrection, Bloom, DepthOfField)
-- -----------------------------------------------------------------------------

local cachedCC: ColorCorrectionEffect? = nil
local cachedBloom: BloomEffect? = nil
local cachedDOF: DepthOfFieldEffect? = nil

local function ensureCorePostProcessing()
	if not cachedCC or not cachedCC.Parent then
		local existing = Lighting:FindFirstChild("ForestColorCorrection") :: ColorCorrectionEffect?
		if not existing then
			existing = Instance.new("ColorCorrectionEffect")
			existing.Name = "ForestColorCorrection"
			existing.Parent = Lighting
		end
		existing.Brightness = 0.02
		existing.Contrast = 0.05
		existing.Saturation = 0.12
		existing.TintColor = Color3.fromRGB(255, 252, 246)
		existing.Enabled = true
		cachedCC = existing
	end

	if not cachedBloom or not cachedBloom.Parent then
		local existing = Lighting:FindFirstChild("ForestBloom") :: BloomEffect?
		if not existing then
			existing = Instance.new("BloomEffect")
			existing.Name = "ForestBloom"
			existing.Parent = Lighting
		end
		existing.Intensity = 0.25
		existing.Size = 14
		existing.Threshold = 1.25
		existing.Enabled = true
		cachedBloom = existing
	end

	if not cachedDOF or not cachedDOF.Parent then
		local existing = Lighting:FindFirstChild("ForestDepthOfField") :: DepthOfFieldEffect?
		if not existing then
			existing = Instance.new("DepthOfFieldEffect")
			existing.Name = "ForestDepthOfField"
			existing.Parent = Lighting
		end
		existing.FarIntensity = 0.20
		existing.FocusDistance = 280.0
		existing.InFocusRadius = 240.0
		existing.NearIntensity = 0.0
		existing.Enabled = true
		cachedDOF = existing
	end
end

-- -----------------------------------------------------------------------------
-- Master Lifecycle
-- -----------------------------------------------------------------------------

function EnvironmentManager.Init()
	if initialized then return end
	initialized = true

	ensureCorePostProcessing()
	CloudManager.Init()
	VolumetricLightingManager.Init()
	FogAtmosphereManager.Init()
	CelestialSkyManager.Init()
end

-- Synchronized Frame Update (Call from DayNightClient or TimeVisuals)
function EnvironmentManager.Update(dt: number, hour: number, day: number, keyframeParams: any?)
	if not initialized then
		EnvironmentManager.Init()
	end

	-- 1. Celestial Sky & IBL
	local envDiffuse, envSpecular = CelestialSkyManager.Update(hour, dt)
	Lighting.EnvironmentDiffuseScale = envDiffuse
	Lighting.EnvironmentSpecularScale = envSpecular

	-- 2. Atmospheric Fog & Mist
	if keyframeParams then
		FogAtmosphereManager.Update(dt, {
			Density = keyframeParams.AtmosphereDensity,
			Offset = keyframeParams.AtmosphereOffset,
			Haze = keyframeParams.AtmosphereHaze,
			Color = keyframeParams.AtmosphereColor,
			Decay = keyframeParams.AtmosphereDecay,
			Glare = keyframeParams.AtmosphereGlare,
			FogStart = 0,
			FogEnd = keyframeParams.FogEnd,
			FogColor = keyframeParams.FogColor,
		})
	else
		FogAtmosphereManager.Update(dt)
	end

	-- 3. Volumetric Clouds
	if keyframeParams then
		CloudManager.Update(dt, keyframeParams.CloudCover, keyframeParams.CloudDensity, keyframeParams.CloudColor)
	else
		CloudManager.Update(dt)
	end

	-- 4. Volumetric Light & Shafts
	VolumetricLightingManager.Update(dt, hour)
end

return EnvironmentManager
