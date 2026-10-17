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

-- Dynamic resolver for authoritative Day Skybox (respects ReplicatedStorage.RealisticDaySkybox or custom store skybox)
function CelestialSkyManager.GetAuthoritativeDaySky(): SkyboxConfig
	local rs = game:GetService("ReplicatedStorage")
	local storeSky = rs:FindFirstChild("RealisticDaySkybox") :: Sky?
	if storeSky and storeSky:IsA("Sky") and storeSky.SkyboxBk and storeSky.SkyboxBk ~= "" and not string.find(storeSky.SkyboxBk, "91458024") then
		return {
			SkyboxBk = storeSky.SkyboxBk,
			SkyboxDn = storeSky.SkyboxDn,
			SkyboxFt = storeSky.SkyboxFt,
			SkyboxLf = storeSky.SkyboxLf,
			SkyboxRt = storeSky.SkyboxRt,
			SkyboxUp = storeSky.SkyboxUp,
			SunTextureId = storeSky.SunTextureId ~= "" and storeSky.SunTextureId or "rbxasset://sky/sun.jpg",
			MoonTextureId = storeSky.MoonTextureId ~= "" and storeSky.MoonTextureId or "rbxasset://sky/moon.jpg",
			SunAngularSize = storeSky.SunAngularSize > 0 and storeSky.SunAngularSize or 5,
			MoonAngularSize = storeSky.MoonAngularSize > 0 and storeSky.MoonAngularSize or 11,
			CelestialBodiesShown = storeSky.CelestialBodiesShown,
			MaxStars = 1500,
		}
	end
	return DAY_SKY
end

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

	local authoritativeDay = CelestialSkyManager.GetAuthoritativeDaySky()
	local existing = Lighting:FindFirstChildOfClass("Sky")
	if existing then
		cachedSky = existing
		-- If existing sky has legacy 2012 texture 91458024, immediately purge and overwrite with realistic store skybox!
		if existing.SkyboxBk and string.find(existing.SkyboxBk, "91458024") then
			CelestialSkyManager.ApplyConfig(authoritativeDay)
		elseif existing.SkyboxBk and existing.SkyboxBk ~= "" 
			and not string.find(existing.SkyboxBk, "15146674442") 
			and not string.find(existing.SkyboxBk, "91458024") then
			-- Adopt custom store skybox authored by the user in Studio
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

	CelestialSkyManager.ApplyConfig(authoritativeDay)
	return sky
end

function CelestialSkyManager.ApplyConfig(cfg: SkyboxConfig)
	local sky = CelestialSkyManager.EnsureSky()
	-- Guard: Never allow legacy 91458024 textures to be applied
	local actualCfg = cfg
	if cfg.SkyboxBk and string.find(cfg.SkyboxBk, "91458024") then
		actualCfg = CelestialSkyManager.GetAuthoritativeDaySky()
	end

	sky.SkyboxBk = actualCfg.SkyboxBk
	sky.SkyboxDn = actualCfg.SkyboxDn
	sky.SkyboxFt = actualCfg.SkyboxFt
	sky.SkyboxLf = actualCfg.SkyboxLf
	sky.SkyboxRt = actualCfg.SkyboxRt
	sky.SkyboxUp = actualCfg.SkyboxUp
	sky.SunTextureId = actualCfg.SunTextureId
	sky.MoonTextureId = actualCfg.MoonTextureId
	sky.SunAngularSize = actualCfg.SunAngularSize
	sky.MoonAngularSize = actualCfg.MoonAngularSize
	sky.CelestialBodiesShown = actualCfg.CelestialBodiesShown
end

-- -----------------------------------------------------------------------------
-- Frame Update & Transitions
-- -----------------------------------------------------------------------------

function CelestialSkyManager.Update(hour: number, dt: number): (number, number)
	local sky = CelestialSkyManager.EnsureSky()

	-- 1. Determine Night vs Day Skybox
	local isNight = (hour >= 18.25 or hour < 5.75)
	local targetConfig = isNight and NIGHT_SKY or CelestialSkyManager.GetAuthoritativeDaySky()
	if isNight ~= isCurrentlyNightSky or sky.SkyboxBk ~= targetConfig.SkyboxBk then
		isCurrentlyNightSky = isNight
		CelestialSkyManager.ApplyConfig(targetConfig)
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
	local sky = CelestialSkyManager.EnsureSky()
	local hour = Lighting.ClockTime
	local isNight = (hour >= 18.25 or hour < 5.75)
	isCurrentlyNightSky = isNight
	if isNight then
		CelestialSkyManager.ApplyConfig(NIGHT_SKY)
	else
		CelestialSkyManager.ApplyConfig(CelestialSkyManager.GetAuthoritativeDaySky())
	end
end

return CelestialSkyManager
