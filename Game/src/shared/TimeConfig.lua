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
-- Tuned for realistic survival gameplay pacing
TimeConfig.PhaseDurations = {
	Dawn  = 60,
	Day   = 480,  -- 8 minutes daytime
	Dusk  = 60,
	Night = 480,  -- 8 minutes nighttime
}

-- Starting state
TimeConfig.StartDay = 0
TimeConfig.StartHour = 14.0

-- Development / Testing Controls
-- Set FreezeTime to true to freeze time at FreezeHour for development & building
TimeConfig.FreezeTime = true
TimeConfig.FreezeHour = 14.0  -- 14.0 = midday clear daylight
TimeConfig.TimeSpeedMultiplier = 1.0  -- Multiplier for clock speed when not frozen

-- Maximum day (game ends after surviving night 5)
TimeConfig.MaxDay = 5

-- Lighting keyframes (sorted by hour, 0-24)
-- Each keyframe defines all visual properties at that game hour.
-- The DayNightCycle script interpolates between adjacent keyframes.
TimeConfig.Keyframes = {
	{
		Hour = 0.0,
		Brightness = 0.45,
		Ambient = Color3.fromRGB(35, 42, 60),
		OutdoorAmbient = Color3.fromRGB(30, 36, 52),
		ColorShift_Top = Color3.fromRGB(160, 180, 215), -- Gentle soft moonlight
		ColorShift_Bottom = Color3.fromRGB(10, 14, 20),
		SunRaysIntensity = 0.0,
		SunRaysSpread = 0.5,
		FogEnd = 2400,
		FogColor = Color3.fromRGB(16, 20, 32),
		ExposureCompensation = -0.08,
		CloudCover = 0.35,
		CloudColor = Color3.fromRGB(45, 50, 70),
		CloudDensity = 0.55,
		AtmosphereDensity = 0.26,
		AtmosphereOffset = 0.18,
		AtmosphereColor = Color3.fromRGB(65, 78, 105),
		AtmosphereDecay = Color3.fromRGB(22, 28, 45),
		AtmosphereGlare = 0.0,
		AtmosphereHaze = 0.35,
	},
	{
		Hour = 5.0,
		Brightness = 1.3,
		Ambient = Color3.fromRGB(52, 60, 78),
		OutdoorAmbient = Color3.fromRGB(70, 80, 100),
		ColorShift_Top = Color3.fromRGB(255, 225, 200),
		ColorShift_Bottom = Color3.fromRGB(35, 38, 42),
		SunRaysIntensity = 0.035,
		SunRaysSpread = 0.65,
		FogEnd = 2400,
		FogColor = Color3.fromRGB(55, 58, 76),
		ExposureCompensation = 0.0,
		CloudCover = 0.55,
		CloudColor = Color3.fromRGB(225, 205, 215),
		CloudDensity = 0.65,
		AtmosphereDensity = 0.28,
		AtmosphereOffset = 0.18,
		AtmosphereColor = Color3.fromRGB(195, 185, 210),
		AtmosphereDecay = Color3.fromRGB(85, 80, 105),
		AtmosphereGlare = 0.05,
		AtmosphereHaze = 0.35,
	},
	{
		Hour = 6.5,
		Brightness = 2.4,
		Ambient = Color3.fromRGB(70, 80, 95),
		OutdoorAmbient = Color3.fromRGB(115, 122, 135),
		ColorShift_Top = Color3.fromRGB(255, 238, 215),
		ColorShift_Bottom = Color3.fromRGB(55, 58, 62),
		SunRaysIntensity = 0.042,
		SunRaysSpread = 0.68,
		FogEnd = 2400,
		FogColor = Color3.fromRGB(185, 160, 145),
		ExposureCompensation = 0.02,
		CloudCover = 0.62,
		CloudColor = Color3.fromRGB(245, 235, 230),
		CloudDensity = 0.70,
		AtmosphereDensity = 0.28,
		AtmosphereOffset = 0.18,
		AtmosphereColor = Color3.fromRGB(200, 215, 235),
		AtmosphereDecay = Color3.fromRGB(110, 125, 150),
		AtmosphereGlare = 0.06,
		AtmosphereHaze = 0.32,
	},
	{
		Hour = 10.0,
		Brightness = 2.8,
		Ambient = Color3.fromRGB(75, 90, 110),
		OutdoorAmbient = Color3.fromRGB(115, 132, 150),
		ColorShift_Top = Color3.fromRGB(255, 248, 238), -- Natural crisp alpine daylight
		ColorShift_Bottom = Color3.fromRGB(65, 68, 72),
		SunRaysIntensity = 0.045,
		SunRaysSpread = 0.68,
		FogEnd = 2400,
		FogColor = Color3.fromRGB(195, 180, 165),
		ExposureCompensation = 0.02,
		CloudCover = 0.62,
		CloudColor = Color3.fromRGB(255, 255, 255),
		CloudDensity = 0.70,
		AtmosphereDensity = 0.32,
		AtmosphereOffset = 0.18,
		AtmosphereColor = Color3.fromRGB(175, 200, 225), -- Restored natural alpine atmosphere
		AtmosphereDecay = Color3.fromRGB(95, 120, 145),
		AtmosphereGlare = 0.12,
		AtmosphereHaze = 0.90, -- Restored natural mountain horizon
	},
	{
		Hour = 14.0,
		Brightness = 2.8,
		Ambient = Color3.fromRGB(75, 90, 110),
		OutdoorAmbient = Color3.fromRGB(115, 132, 150),
		ColorShift_Top = Color3.fromRGB(255, 248, 238),
		ColorShift_Bottom = Color3.fromRGB(65, 68, 72),
		SunRaysIntensity = 0.045,
		SunRaysSpread = 0.68,
		FogEnd = 2400,
		FogColor = Color3.fromRGB(195, 180, 165),
		ExposureCompensation = 0.02,
		CloudCover = 0.62,
		CloudColor = Color3.fromRGB(255, 255, 255),
		CloudDensity = 0.70,
		AtmosphereDensity = 0.32,
		AtmosphereOffset = 0.18,
		AtmosphereColor = Color3.fromRGB(175, 200, 225),
		AtmosphereDecay = Color3.fromRGB(95, 120, 145),
		AtmosphereGlare = 0.12,
		AtmosphereHaze = 0.90,
	},
	{
		Hour = 16.5,
		Brightness = 2.7,
		Ambient = Color3.fromRGB(75, 88, 108),
		OutdoorAmbient = Color3.fromRGB(115, 128, 145),
		ColorShift_Top = Color3.fromRGB(255, 236, 210),
		ColorShift_Bottom = Color3.fromRGB(60, 62, 65),
		SunRaysIntensity = 0.048,
		SunRaysSpread = 0.70,
		FogEnd = 2400,
		FogColor = Color3.fromRGB(205, 175, 150),
		ExposureCompensation = 0.03,
		CloudCover = 0.60,
		CloudColor = Color3.fromRGB(255, 248, 240),
		CloudDensity = 0.68,
		AtmosphereDensity = 0.32,
		AtmosphereOffset = 0.18,
		AtmosphereColor = Color3.fromRGB(180, 200, 225),
		AtmosphereDecay = Color3.fromRGB(100, 118, 140),
		AtmosphereGlare = 0.12,
		AtmosphereHaze = 0.90,
	},
	{
		Hour = 17.5,
		Brightness = 2.4,
		Ambient = Color3.fromRGB(75, 82, 102),
		OutdoorAmbient = Color3.fromRGB(115, 118, 136),
		ColorShift_Top = Color3.fromRGB(255, 215, 175),
		ColorShift_Bottom = Color3.fromRGB(50, 48, 50),
		SunRaysIntensity = 0.055,
		SunRaysSpread = 0.72,
		FogEnd = 2400,
		FogColor = Color3.fromRGB(188, 142, 112),
		ExposureCompensation = 0.05,
		CloudCover = 0.58,
		CloudColor = Color3.fromRGB(245, 195, 170),
		CloudDensity = 0.68,
		AtmosphereDensity = 0.30,
		AtmosphereOffset = 0.20,
		AtmosphereColor = Color3.fromRGB(225, 185, 160),
		AtmosphereDecay = Color3.fromRGB(110, 95, 120),
		AtmosphereGlare = 0.08,
		AtmosphereHaze = 0.38,
	},
	{
		Hour = 19.0,
		Brightness = 1.1,
		Ambient = Color3.fromRGB(48, 55, 75),
		OutdoorAmbient = Color3.fromRGB(65, 75, 98),
		ColorShift_Top = Color3.fromRGB(175, 185, 205),
		ColorShift_Bottom = Color3.fromRGB(22, 24, 28),
		SunRaysIntensity = 0.02,
		SunRaysSpread = 0.60,
		FogEnd = 2400,
		FogColor = Color3.fromRGB(48, 45, 68),
		ExposureCompensation = -0.04,
		CloudCover = 0.45,
		CloudColor = Color3.fromRGB(120, 105, 135),
		CloudDensity = 0.60,
		AtmosphereDensity = 0.28,
		AtmosphereOffset = 0.18,
		AtmosphereColor = Color3.fromRGB(125, 125, 155),
		AtmosphereDecay = Color3.fromRGB(55, 55, 75),
		AtmosphereGlare = 0.02,
		AtmosphereHaze = 0.35,
	},
	{
		Hour = 22.0,
		Brightness = 0.55,
		Ambient = Color3.fromRGB(28, 35, 52),
		OutdoorAmbient = Color3.fromRGB(35, 45, 65),
		ColorShift_Top = Color3.fromRGB(160, 180, 220),
		ColorShift_Bottom = Color3.fromRGB(10, 14, 20),
		SunRaysIntensity = 0.0,
		SunRaysSpread = 0.5,
		FogEnd = 2400,
		FogColor = Color3.fromRGB(18, 22, 36),
		ExposureCompensation = -0.08,
		CloudCover = 0.35,
		CloudColor = Color3.fromRGB(48, 52, 72),
		CloudDensity = 0.55,
		AtmosphereDensity = 0.26,
		AtmosphereOffset = 0.18,
		AtmosphereColor = Color3.fromRGB(55, 72, 105),
		AtmosphereDecay = Color3.fromRGB(20, 28, 45),
		AtmosphereGlare = 0.0,
		AtmosphereHaze = 0.35,
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
