--!strict
--[[
    CelestialSkyManager.lua
    Standalone Celestial Skybox, Sun, Moon, Stars & IBL Transition Engine.
    Part of the Fluenosity Studio Modular Environment Suite.
    
    Responsibilities:
    - Authoritative lifecycle of Lighting.Sky.
    - Seamless day-to-night skybox swapping (Day Alpine <-> 4K NASA Milky Way Galaxy).
    - Starfield emergence: dynamic Hermite-curve star fade-in/fade-out during twilight.
    - Zero-Flash IBL Dips: smoothly scales Lighting.EnvironmentDiffuseScale around asset swap
      windows so terrain lighting never pops.
    - Configurable Sun/Moon textures and angular sizes.
]]

local Lighting = game:GetService("Lighting")

local CelestialSkyManager = {}

export type SkyboxConfig = {
	SkyboxBk: string,
	SkyboxDn: string,
	SkyboxFt: string,
	SkyboxLf: string,
	SkyboxRt: string,
	SkyboxUp: string,
	SunTextureId: string,
	MoonTextureId: string,
	SunAngularSize: number,
	MoonAngularSize: number,
	CelestialBodiesShown: boolean,
	MaxStars: number,
}

local DAY_SKY: SkyboxConfig = {
	SkyboxBk = "http://www.roblox.com/asset/?id=144933338",
	SkyboxDn = "http://www.roblox.com/asset/?id=144931530",
	SkyboxFt = "http://www.roblox.com/asset/?id=144933262",
	SkyboxLf = "http://www.roblox.com/asset/?id=144933244",
	SkyboxRt = "http://www.roblox.com/asset/?id=144933299",
	SkyboxUp = "http://www.roblox.com/asset/?id=144931564",
	SunTextureId = "rbxasset://sky/sun.jpg",
	MoonTextureId = "rbxasset://sky/moon.jpg",
	SunAngularSize = 5,
	MoonAngularSize = 11,
	CelestialBodiesShown = true,
	MaxStars = 1500,
}

local NIGHT_SKY: SkyboxConfig = {
	SkyboxBk = "rbxassetid://15146674442",
	SkyboxDn = "rbxassetid://15146673704",
	SkyboxFt = "rbxassetid://15146672849",
	SkyboxLf = "rbxassetid://15146672013",
	SkyboxRt = "rbxassetid://15146671172",
	SkyboxUp = "rbxassetid://15146670489",
	SunTextureId = "rbxasset://sky/sun.jpg",
	MoonTextureId = "rbxasset://sky/moon.jpg",
	SunAngularSize = 5,
	MoonAngularSize = 14,
	CelestialBodiesShown = true,
	MaxStars = 3000,
}

local cachedSky: Sky? = nil
local isCurrentlyNightSky: boolean = false

local function smoothstep(t: number): number
	local clamped = math.clamp(t, 0, 1)
	return clamped * clamped * (3 - 2 * clamped)
end

-- -----------------------------------------------------------------------------
-- Instance Lifecycle
-- -----------------------------------------------------------------------------

function CelestialSkyManager.EnsureSky(): Sky
	if cachedSky and cachedSky.Parent then
		return cachedSky
	end

	local existing = Lighting:FindFirstChildOfClass("Sky")
	if existing then
		cachedSky = existing
		-- If existing sky has custom user textures (not default empty), capture them as DAY_SKY!
		if existing.SkyboxBk and existing.SkyboxBk ~= "" and not string.find(existing.SkyboxBk, "15146674442") then
			DAY_SKY.SkyboxBk = existing.SkyboxBk
			DAY_SKY.SkyboxDn = existing.SkyboxDn
			DAY_SKY.SkyboxFt = existing.SkyboxFt
			DAY_SKY.SkyboxLf = existing.SkyboxLf
			DAY_SKY.SkyboxRt = existing.SkyboxRt
			DAY_SKY.SkyboxUp = existing.SkyboxUp
			DAY_SKY.SunTextureId = existing.SunTextureId
			DAY_SKY.MoonTextureId = existing.MoonTextureId
			DAY_SKY.SunAngularSize = existing.SunAngularSize
			DAY_SKY.MoonAngularSize = existing.MoonAngularSize
			DAY_SKY.CelestialBodiesShown = existing.CelestialBodiesShown
		end
		return existing
	end

	local sky = Instance.new("Sky")
	sky.Name = "Sky"
	sky.Parent = Lighting
	cachedSky = sky

	CelestialSkyManager.ApplyConfig(DAY_SKY)
	return sky
end

function CelestialSkyManager.ApplyConfig(cfg: SkyboxConfig)
	local sky = CelestialSkyManager.EnsureSky()
	sky.SkyboxBk = cfg.SkyboxBk
	sky.SkyboxDn = cfg.SkyboxDn
	sky.SkyboxFt = cfg.SkyboxFt
	sky.SkyboxLf = cfg.SkyboxLf
	sky.SkyboxRt = cfg.SkyboxRt
	sky.SkyboxUp = cfg.SkyboxUp
	sky.SunTextureId = cfg.SunTextureId
	sky.MoonTextureId = cfg.MoonTextureId
	sky.SunAngularSize = cfg.SunAngularSize
	sky.MoonAngularSize = cfg.MoonAngularSize
	sky.CelestialBodiesShown = cfg.CelestialBodiesShown
end

-- -----------------------------------------------------------------------------
-- Frame Update & Transitions
-- -----------------------------------------------------------------------------

function CelestialSkyManager.Update(hour: number, dt: number): (number, number)
	local sky = CelestialSkyManager.EnsureSky()

	-- 1. Determine Night vs Day Skybox
	local isNight = (hour >= 18.25 or hour < 5.75)
	if isNight ~= isCurrentlyNightSky then
		isCurrentlyNightSky = isNight
		if isNight then
			CelestialSkyManager.ApplyConfig(NIGHT_SKY)
		else
			CelestialSkyManager.ApplyConfig(DAY_SKY)
		end
	end

	-- 2. Starfield Emergence (Hermite-interpolated fade-in of stars across twilight)
	local starFactor = 0.0
	if hour >= 19.5 or hour < 4.5 then
		starFactor = 1.0
	elseif hour >= 17.5 and hour < 19.5 then
		starFactor = smoothstep((hour - 17.5) / 2.0)
	elseif hour >= 4.5 and hour < 6.5 then
		starFactor = 1.0 - smoothstep((hour - 4.5) / 2.0)
	end
	sky.StarCount = math.floor(starFactor * 3000)

	-- 3. Seamless IBL Dip (Prevents terrain pop during skybox texture swap)
	local envDiffuse = 1.0
	local envSpecular = 0.85
	if hour >= 17.8 and hour <= 18.6 then
		local progress = (hour - 17.8) / 0.8
		local dip = 1.0 - math.sin(progress * math.pi)
		envDiffuse = math.clamp(0.08 + 0.92 * dip, 0.08, 1.0)
		envSpecular = math.clamp(0.15 + 0.70 * dip, 0.15, 0.85)
	elseif hour >= 5.4 and hour <= 6.2 then
		local progress = (hour - 5.4) / 0.8
		local dip = 1.0 - math.sin(progress * math.pi)
		envDiffuse = math.clamp(0.08 + 0.92 * dip, 0.08, 1.0)
		envSpecular = math.clamp(0.15 + 0.70 * dip, 0.15, 0.85)
	end

	return envDiffuse, envSpecular
end

-- -----------------------------------------------------------------------------
-- Initialization
-- -----------------------------------------------------------------------------

function CelestialSkyManager.Init()
	CelestialSkyManager.EnsureSky()
end

return CelestialSkyManager
