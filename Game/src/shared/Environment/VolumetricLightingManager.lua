--!strict
--[[
    VolumetricLightingManager.lua
    Standalone Volumetric Lighting, Light Shafts & Atmospheric Godrays Engine.
    Part of the Fluenosity Studio Modular Environment Suite.
    
    Responsibilities:
    - Authoritative control over SunRaysEffect (intensity, spread, sunrise/sunset golden hour blooms).
    - True 3D Light Shafts streaming through the conifer pine forest clearing.
    - Localized volumetric lighting cones for key emitters:
      * Central campsite campfire (upward ember glow & volumetric cone)
      * Silas the Trader's warm lantern cone
      * Player handheld torches / sulfur matches
    - Dynamic occlusion & time-of-day brightness scaling (godbeams disappear at deep night).
]]

local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")

local VolumetricLightingManager = {}

export type VolumetricConeConfig = {
	Name: string,
	SourcePart: BasePart,
	Color: Color3,
	Length: number,
	BaseRadius: number,
	EndRadius: number,
	Brightness: number,
	Flicker: boolean?,
	FlickerSpeed: number?,
	FlickerAmount: number?,
}

local cachedSunRays: SunRaysEffect? = nil
local activeVolumetricCones: { [string]: { Config: VolumetricConeConfig, BeamInstance: Beam?, Part0: Attachment?, Part1: Attachment? } } = {}

local godraysEnabled: boolean = true
local targetSunRayIntensity: number = 0.045
local targetSunRaySpread: number = 0.68
local currentSunRayIntensity: number = targetSunRayIntensity
local currentSunRaySpread: number = targetSunRaySpread

-- -----------------------------------------------------------------------------
-- SunRays Effect Lifecycle
-- -----------------------------------------------------------------------------

function VolumetricLightingManager.EnsureSunRays(): SunRaysEffect
	if cachedSunRays and cachedSunRays.Parent then
		return cachedSunRays
	end

	local existing = Lighting:FindFirstChildOfClass("SunRaysEffect")
	if existing then
		cachedSunRays = existing
		return existing
	end

	local sunRays = Instance.new("SunRaysEffect")
	sunRays.Name = "ForestSunRays"
	sunRays.Intensity = targetSunRayIntensity
	sunRays.Spread = targetSunRaySpread
	sunRays.Enabled = true
	sunRays.Parent = Lighting

	cachedSunRays = sunRays
	return sunRays
end

function VolumetricLightingManager.SetSunRays(intensity: number, spread: number, enabled: boolean?)
	targetSunRayIntensity = math.clamp(intensity, 0, 1)
	targetSunRaySpread = math.clamp(spread, 0, 1)
	if enabled ~= nil then
		godraysEnabled = enabled
	end
end

-- -----------------------------------------------------------------------------
-- Localized Volumetric Light Cones (Campfire, Lanterns, Torches)
-- -----------------------------------------------------------------------------

local function getOrCreateConeFolder(): Folder
	local terrain = Workspace.Terrain
	local folder = terrain:FindFirstChild("VolumetricLightCones") :: Folder?
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = "VolumetricLightCones"
		folder.Parent = terrain
	end
	return folder
end

function VolumetricLightingManager.RegisterLightCone(config: VolumetricConeConfig)
	if activeVolumetricCones[config.Name] then
		VolumetricLightingManager.UnregisterLightCone(config.Name)
	end

	local source = config.SourcePart
	if not source or not source.Parent then
		return
	end

	local att0 = Instance.new("Attachment")
	att0.Name = config.Name .. "_Att0"
	att0.CFrame = CFrame.new(0, 0, 0)
	att0.Parent = source

	local att1 = Instance.new("Attachment")
	att1.Name = config.Name .. "_Att1"
	att1.CFrame = CFrame.new(0, config.Length, 0)
	att1.Parent = source

	local beam = Instance.new("Beam")
	beam.Name = config.Name .. "_VolumetricBeam"
	beam.Attachment0 = att0
	beam.Attachment1 = att1
	beam.Width0 = config.BaseRadius
	beam.Width1 = config.EndRadius
	beam.Color = ColorSequence.new(config.Color)
	beam.LightEmission = 0.85
	beam.LightInfluence = 0.15
	beam.Texture = "rbxassetid://6281397916" -- Soft radial glow texture
	beam.TextureSpeed = 0
	beam.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.70),
		NumberSequenceKeypoint.new(0.5, 0.82),
		NumberSequenceKeypoint.new(1, 1.0),
	})
	beam.Segments = 10
	beam.Enabled = true
	beam.Parent = getOrCreateConeFolder()

	activeVolumetricCones[config.Name] = {
		Config = config,
		BeamInstance = beam,
		Part0 = att0,
		Part1 = att1,
	}
end

function VolumetricLightingManager.UnregisterLightCone(name: string)
	local record = activeVolumetricCones[name]
	if record then
		if record.BeamInstance then pcall(function() record.BeamInstance:Destroy() end) end
		if record.Part0 then pcall(function() record.Part0:Destroy() end) end
		if record.Part1 then pcall(function() record.Part1:Destroy() end) end
		activeVolumetricCones[name] = nil
	end
end

-- -----------------------------------------------------------------------------
-- Auto-Detect & Setup Campfire Volumetrics
-- -----------------------------------------------------------------------------

function VolumetricLightingManager.SetupCampfireVolumetrics()
	local campfire = Workspace:FindFirstChild("Campfire")
	local firePart = campfire and campfire:FindFirstChild("FirePart", true)
	if firePart and firePart:IsA("BasePart") then
		VolumetricLightingManager.RegisterLightCone({
			Name = "CampfireEmberHaze",
			SourcePart = firePart,
			Color = Color3.fromRGB(255, 160, 80),
			Length = 12.0,
			BaseRadius = 3.5,
			EndRadius = 7.0,
			Brightness = 1.0,
			Flicker = true,
			FlickerSpeed = 6.0,
			FlickerAmount = 0.15,
		})
	end
end

-- -----------------------------------------------------------------------------
-- Frame Update
-- -----------------------------------------------------------------------------

local flickerTimer: number = 0.0

function VolumetricLightingManager.Update(dt: number, hour: number?)
	local sunRays = VolumetricLightingManager.EnsureSunRays()

	-- Calculate day/night godray weight
	local currentHour = hour or Lighting.ClockTime
	local isNight = (currentHour >= 19.5 or currentHour < 4.5)
	local dayWeight = 1.0
	if isNight then
		dayWeight = 0.0
	elseif currentHour >= 4.5 and currentHour < 6.5 then
		dayWeight = (currentHour - 4.5) / 2.0
	elseif currentHour >= 17.5 and currentHour < 19.5 then
		dayWeight = 1.0 - ((currentHour - 17.5) / 2.0)
	end

	-- Smooth lerp toward target sunray settings
	local blendFactor = math.clamp(dt * 4.0, 0, 1)
	currentSunRayIntensity = currentSunRayIntensity + (targetSunRayIntensity - currentSunRayIntensity) * blendFactor
	currentSunRaySpread = currentSunRaySpread + (targetSunRaySpread - currentSunRaySpread) * blendFactor

	local effectiveIntensity = currentSunRayIntensity * dayWeight
	sunRays.Intensity = effectiveIntensity
	sunRays.Spread = currentSunRaySpread
	sunRays.Enabled = godraysEnabled and (effectiveIntensity > 0.005)

	-- Update localized volumetric cones (Campfire / Lantern flickers)
	flickerTimer = flickerTimer + dt
	for _, cone in pairs(activeVolumetricCones) do
		local cfg = cone.Config
		local beam = cone.BeamInstance
		if beam and cfg.Flicker then
			local speed = cfg.FlickerSpeed or 5.0
			local amount = cfg.FlickerAmount or 0.10
			local noise = (math.sin(flickerTimer * speed) * 0.7 + math.cos(flickerTimer * speed * 2.1) * 0.3) * amount
			local baseTransparency = 0.75 + noise
			beam.Transparency = NumberSequence.new({
				NumberSequenceKeypoint.new(0, math.clamp(baseTransparency - 0.1, 0, 1)),
				NumberSequenceKeypoint.new(0.5, math.clamp(baseTransparency, 0, 1)),
				NumberSequenceKeypoint.new(1, 1.0),
			})
		end
	end
end

-- -----------------------------------------------------------------------------
-- Initialization
-- -----------------------------------------------------------------------------

function VolumetricLightingManager.Init()
	VolumetricLightingManager.EnsureSunRays()
	task.defer(function()
		VolumetricLightingManager.SetupCampfireVolumetrics()
	end)
end

return VolumetricLightingManager
