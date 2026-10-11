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
		Brightness = 0.40,
		Ambient = Color3.fromRGB(42, 45, 62),
		OutdoorAmbient = Color3.fromRGB(36, 40, 55),
		FogEnd = 800,
		FogColor = Color3.fromRGB(24, 26, 42),
		ExposureCompensation = -0.15,
		CloudCover = 0.55,
		CloudColor = Color3.fromRGB(45, 45, 65),
		CloudDensity = 0.28,
		AtmosphereDensity = 0.28,
		AtmosphereColor = Color3.fromRGB(80, 90, 125),
		AtmosphereDecay = Color3.fromRGB(40, 45, 65),
		AtmosphereGlare = 0.0,
		AtmosphereHaze = 1.6,
	},
	{
		Hour = 5.0,
		Brightness = 0.85,
		Ambient = Color3.fromRGB(65, 62, 80),
		OutdoorAmbient = Color3.fromRGB(58, 56, 72),
		FogEnd = 1200,
		FogColor = Color3.fromRGB(45, 42, 60),
		ExposureCompensation = -0.05,
		CloudCover = 0.45,
		CloudColor = Color3.fromRGB(75, 70, 90),
		CloudDensity = 0.22,
		AtmosphereDensity = 0.26,
		AtmosphereColor = Color3.fromRGB(100, 95, 130),
		AtmosphereDecay = Color3.fromRGB(48, 50, 72),
		AtmosphereGlare = 0.05,
		AtmosphereHaze = 1.8,
	},
	{
		Hour = 6.5,
		Brightness = 1.8,
		Ambient = Color3.fromRGB(118, 108, 125),
		OutdoorAmbient = Color3.fromRGB(110, 100, 118),
		FogEnd = 1800,
		FogColor = Color3.fromRGB(145, 125, 120),
		ExposureCompensation = 0.12,
		CloudCover = 0.35,
		CloudColor = Color3.fromRGB(160, 135, 135),
		CloudDensity = 0.18,
		AtmosphereDensity = 0.25,
		AtmosphereColor = Color3.fromRGB(165, 145, 135),
		AtmosphereDecay = Color3.fromRGB(65, 55, 75),
		AtmosphereGlare = 0.15,
		AtmosphereHaze = 2.0,
	},
	{
		Hour = 8.0,
		Brightness = 2.9,
		Ambient = Color3.fromRGB(145, 148, 158),
		OutdoorAmbient = Color3.fromRGB(140, 145, 155),
		FogEnd = 2500,
		FogColor = Color3.fromRGB(195, 205, 215),
		ExposureCompensation = 0.22,
		CloudCover = 0.25,
		CloudColor = Color3.fromRGB(220, 225, 235),
		CloudDensity = 0.12,
		AtmosphereDensity = 0.24,
		AtmosphereColor = Color3.fromRGB(175, 195, 220),
		AtmosphereDecay = Color3.fromRGB(95, 115, 140),
		AtmosphereGlare = 0.22,
		AtmosphereHaze = 2.2,
	},
	{
		Hour = 12.0,
		Brightness = 3.5,
		Ambient = Color3.fromRGB(165, 168, 178),
		OutdoorAmbient = Color3.fromRGB(158, 162, 172),
		FogEnd = 3000,
		FogColor = Color3.fromRGB(215, 222, 232),
		ExposureCompensation = 0.28,
		CloudCover = 0.18,
		CloudColor = Color3.fromRGB(235, 238, 248),
		CloudDensity = 0.08,
		AtmosphereDensity = 0.22,
		AtmosphereColor = Color3.fromRGB(180, 205, 230),
		AtmosphereDecay = Color3.fromRGB(100, 125, 150),
		AtmosphereGlare = 0.32,
		AtmosphereHaze = 2.4,
	},
	{
		Hour = 16.0,
		Brightness = 2.9,
		Ambient = Color3.fromRGB(150, 145, 140),
		OutdoorAmbient = Color3.fromRGB(145, 140, 135),
		FogEnd = 2400,
		FogColor = Color3.fromRGB(210, 200, 190),
		ExposureCompensation = 0.20,
		CloudCover = 0.25,
		CloudColor = Color3.fromRGB(225, 215, 205),
		CloudDensity = 0.12,
		AtmosphereDensity = 0.24,
		AtmosphereColor = Color3.fromRGB(185, 180, 170),
		AtmosphereDecay = Color3.fromRGB(85, 80, 95),
		AtmosphereGlare = 0.22,
		AtmosphereHaze = 2.2,
	},
	{
		Hour = 17.5,
		Brightness = 1.9,
		Ambient = Color3.fromRGB(125, 102, 95),
		OutdoorAmbient = Color3.fromRGB(118, 95, 90),
		FogEnd = 1800,
		FogColor = Color3.fromRGB(165, 120, 100),
		ExposureCompensation = 0.08,
		CloudCover = 0.38,
		CloudColor = Color3.fromRGB(175, 125, 110),
		CloudDensity = 0.18,
		AtmosphereDensity = 0.26,
		AtmosphereColor = Color3.fromRGB(178, 135, 115),
		AtmosphereDecay = Color3.fromRGB(68, 50, 60),
		AtmosphereGlare = 0.18,
		AtmosphereHaze = 2.0,
	},
	{
		Hour = 19.0,
		Brightness = 0.85,
		Ambient = Color3.fromRGB(65, 58, 80),
		OutdoorAmbient = Color3.fromRGB(56, 50, 72),
		FogEnd = 1000,
		FogColor = Color3.fromRGB(48, 42, 65),
		ExposureCompensation = -0.08,
		CloudCover = 0.48,
		CloudColor = Color3.fromRGB(70, 60, 85),
		CloudDensity = 0.24,
		AtmosphereDensity = 0.28,
		AtmosphereColor = Color3.fromRGB(95, 90, 120),
		AtmosphereDecay = Color3.fromRGB(45, 42, 60),
		AtmosphereGlare = 0.05,
		AtmosphereHaze = 1.8,
	},
	{
		Hour = 22.0,
		Brightness = 0.42,
		Ambient = Color3.fromRGB(45, 48, 65),
		OutdoorAmbient = Color3.fromRGB(38, 42, 58),
		FogEnd = 800,
		FogColor = Color3.fromRGB(26, 28, 45),
		ExposureCompensation = -0.15,
		CloudCover = 0.55,
		CloudColor = Color3.fromRGB(48, 48, 68),
		CloudDensity = 0.28,
		AtmosphereDensity = 0.28,
		AtmosphereColor = Color3.fromRGB(80, 85, 120),
		AtmosphereDecay = Color3.fromRGB(38, 40, 60),
		AtmosphereGlare = 0.0,
		AtmosphereHaze = 1.6,
	},
}

-- Day modifiers (0-5): progressive darkness, fog, and cloud oppression
TimeConfig.DayModifiers = {
	[0] = { Darkness = 0.0,  FogMul = 1.0,  CloudMul = 1.0,  ExposureOffset = 0.0   },
	[1] = { Darkness = 0.08, FogMul = 1.02, CloudMul = 1.02, ExposureOffset = -0.02 },
	[2] = { Darkness = 0.16, FogMul = 1.05, CloudMul = 1.05, ExposureOffset = -0.04 },
	[3] = { Darkness = 0.25, FogMul = 1.08, CloudMul = 1.08, ExposureOffset = -0.06 },
	[4] = { Darkness = 0.35, FogMul = 1.12, CloudMul = 1.12, ExposureOffset = -0.08 },
	[5] = { Darkness = 0.45, FogMul = 1.16, CloudMul = 1.16, ExposureOffset = -0.10 },
}

return TimeConfig
