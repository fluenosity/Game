--!strict
--[[
    TimeConfig.lua
    Configuration for the custom day/night cycle, time system, and cloud system
    for "Don't Let the Fire Die". Developed for Fluenosity Studio.
    
    Defines lighting keyframes, cloud behavior, atmospheric states, and per-day
    darkness modifiers that make each successive night more oppressive.
]]

local TimeConfig = {}

-- Phase definitions in game hours (24-hour clock)
-- Night wraps past midnight: 19:00 to 05:00
TimeConfig.Phases = {
	{ Name = "Dawn",  StartHour = 5.0,  EndHour = 7.0  },
	{ Name = "Day",   StartHour = 7.0,  EndHour = 17.0 },
	{ Name = "Dusk",  StartHour = 17.0, EndHour = 19.0 },
	{ Name = "Night", StartHour = 19.0, EndHour = 5.0  },
}

-- Duration of each phase in real seconds
-- Nights are longer than days for survival horror tension
TimeConfig.PhaseDurations = {
	Dawn  = 25,
	Day   = 120,
	Dusk  = 25,
	Night = 180,
}

-- Starting state
TimeConfig.StartDay = 0
TimeConfig.StartHour = 8.0

-- Maximum day (game ends after surviving night 5)
TimeConfig.MaxDay = 5

-- Lighting keyframes (sorted by hour, 0-24)
-- Each keyframe defines all visual properties at that game hour.
-- The DayNightCycle script interpolates between adjacent keyframes.
TimeConfig.Keyframes = {
	{
		Hour = 0.0,
		Brightness = 0.1,
		Ambient = Color3.fromRGB(15, 18, 35),
		OutdoorAmbient = Color3.fromRGB(10, 12, 28),
		FogEnd = 80,
		FogColor = Color3.fromRGB(14, 15, 25),
		ExposureCompensation = -0.5,
		CloudCover = 0.65,
		CloudColor = Color3.fromRGB(35, 35, 50),
		CloudDensity = 0.35,
		AtmosphereDensity = 0.35,
		AtmosphereColor = Color3.fromRGB(40, 45, 70),
		AtmosphereDecay = Color3.fromRGB(20, 25, 40),
		AtmosphereGlare = 0.0,
		AtmosphereHaze = 1.8,
	},
	{
		Hour = 5.0,
		Brightness = 0.2,
		Ambient = Color3.fromRGB(28, 25, 45),
		OutdoorAmbient = Color3.fromRGB(22, 20, 38),
		FogEnd = 100,
		FogColor = Color3.fromRGB(25, 25, 40),
		ExposureCompensation = -0.35,
		CloudCover = 0.55,
		CloudColor = Color3.fromRGB(55, 50, 70),
		CloudDensity = 0.28,
		AtmosphereDensity = 0.32,
		AtmosphereColor = Color3.fromRGB(50, 50, 75),
		AtmosphereDecay = Color3.fromRGB(25, 28, 42),
		AtmosphereGlare = 0.0,
		AtmosphereHaze = 1.6,
	},
	{
		Hour = 6.5,
		Brightness = 0.8,
		Ambient = Color3.fromRGB(85, 75, 95),
		OutdoorAmbient = Color3.fromRGB(75, 65, 88),
		FogEnd = 160,
		FogColor = Color3.fromRGB(110, 90, 85),
		ExposureCompensation = -0.1,
		CloudCover = 0.4,
		CloudColor = Color3.fromRGB(130, 110, 115),
		CloudDensity = 0.2,
		AtmosphereDensity = 0.3,
		AtmosphereColor = Color3.fromRGB(70, 65, 80),
		AtmosphereDecay = Color3.fromRGB(35, 30, 45),
		AtmosphereGlare = 0.1,
		AtmosphereHaze = 2.0,
	},
	{
		Hour = 8.0,
		Brightness = 2.0,
		Ambient = Color3.fromRGB(125, 125, 135),
		OutdoorAmbient = Color3.fromRGB(115, 118, 130),
		FogEnd = 400,
		FogColor = Color3.fromRGB(185, 185, 195),
		ExposureCompensation = 0.0,
		CloudCover = 0.3,
		CloudColor = Color3.fromRGB(205, 205, 215),
		CloudDensity = 0.15,
		AtmosphereDensity = 0.28,
		AtmosphereColor = Color3.fromRGB(65, 70, 85),
		AtmosphereDecay = Color3.fromRGB(30, 35, 45),
		AtmosphereGlare = 0.2,
		AtmosphereHaze = 2.5,
	},
	{
		Hour = 12.0,
		Brightness = 3.0,
		Ambient = Color3.fromRGB(145, 145, 155),
		OutdoorAmbient = Color3.fromRGB(135, 138, 148),
		FogEnd = 500,
		FogColor = Color3.fromRGB(205, 205, 215),
		ExposureCompensation = 0.1,
		CloudCover = 0.2,
		CloudColor = Color3.fromRGB(225, 225, 235),
		CloudDensity = 0.1,
		AtmosphereDensity = 0.25,
		AtmosphereColor = Color3.fromRGB(60, 65, 80),
		AtmosphereDecay = Color3.fromRGB(28, 32, 42),
		AtmosphereGlare = 0.3,
		AtmosphereHaze = 2.8,
	},
	{
		Hour = 16.0,
		Brightness = 2.5,
		Ambient = Color3.fromRGB(135, 128, 120),
		OutdoorAmbient = Color3.fromRGB(128, 122, 115),
		FogEnd = 350,
		FogColor = Color3.fromRGB(195, 182, 170),
		ExposureCompensation = 0.0,
		CloudCover = 0.3,
		CloudColor = Color3.fromRGB(215, 200, 190),
		CloudDensity = 0.15,
		AtmosphereDensity = 0.27,
		AtmosphereColor = Color3.fromRGB(65, 68, 82),
		AtmosphereDecay = Color3.fromRGB(32, 35, 42),
		AtmosphereGlare = 0.2,
		AtmosphereHaze = 2.5,
	},
	{
		Hour = 17.5,
		Brightness = 1.2,
		Ambient = Color3.fromRGB(95, 72, 78),
		OutdoorAmbient = Color3.fromRGB(88, 66, 72),
		FogEnd = 200,
		FogColor = Color3.fromRGB(135, 90, 70),
		ExposureCompensation = -0.1,
		CloudCover = 0.45,
		CloudColor = Color3.fromRGB(145, 95, 80),
		CloudDensity = 0.22,
		AtmosphereDensity = 0.3,
		AtmosphereColor = Color3.fromRGB(72, 65, 78),
		AtmosphereDecay = Color3.fromRGB(38, 30, 40),
		AtmosphereGlare = 0.15,
		AtmosphereHaze = 2.2,
	},
	{
		Hour = 19.0,
		Brightness = 0.4,
		Ambient = Color3.fromRGB(32, 28, 50),
		OutdoorAmbient = Color3.fromRGB(26, 22, 44),
		FogEnd = 120,
		FogColor = Color3.fromRGB(30, 26, 45),
		ExposureCompensation = -0.3,
		CloudCover = 0.55,
		CloudColor = Color3.fromRGB(50, 42, 65),
		CloudDensity = 0.28,
		AtmosphereDensity = 0.33,
		AtmosphereColor = Color3.fromRGB(45, 45, 68),
		AtmosphereDecay = Color3.fromRGB(22, 25, 38),
		AtmosphereGlare = 0.0,
		AtmosphereHaze = 1.8,
	},
	{
		Hour = 22.0,
		Brightness = 0.15,
		Ambient = Color3.fromRGB(18, 20, 38),
		OutdoorAmbient = Color3.fromRGB(12, 15, 32),
		FogEnd = 90,
		FogColor = Color3.fromRGB(16, 17, 28),
		ExposureCompensation = -0.4,
		CloudCover = 0.62,
		CloudColor = Color3.fromRGB(38, 38, 52),
		CloudDensity = 0.32,
		AtmosphereDensity = 0.35,
		AtmosphereColor = Color3.fromRGB(40, 42, 68),
		AtmosphereDecay = Color3.fromRGB(20, 23, 38),
		AtmosphereGlare = 0.0,
		AtmosphereHaze = 1.7,
	},
}

-- Day modifiers (0-5): progressive darkness, fog, and cloud oppression
-- Darkness: 0 = normal, 1 = maximum oppression (applied mainly at night)
-- FogMul: fog density multiplier (higher = thicker fog)
-- CloudMul: cloud cover/density multiplier
-- ExposureOffset: additional exposure reduction at night
TimeConfig.DayModifiers = {
	[0] = { Darkness = 0.0,  FogMul = 1.0,  CloudMul = 1.0,  ExposureOffset = 0.0   },
	[1] = { Darkness = 0.15, FogMul = 1.05, CloudMul = 1.05, ExposureOffset = -0.05 },
	[2] = { Darkness = 0.30, FogMul = 1.12, CloudMul = 1.12, ExposureOffset = -0.1  },
	[3] = { Darkness = 0.50, FogMul = 1.20, CloudMul = 1.20, ExposureOffset = -0.15 },
	[4] = { Darkness = 0.70, FogMul = 1.30, CloudMul = 1.30, ExposureOffset = -0.2  },
	[5] = { Darkness = 0.90, FogMul = 1.45, CloudMul = 1.45, ExposureOffset = -0.25 },
}

return TimeConfig
