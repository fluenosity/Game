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
TimeConfig.StartHour = 14.0

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
		ColorShift_Top = Color3.fromRGB(160, 180, 215), -- Gentle soft moonlight (natural, non-harsh)
		ColorShift_Bottom = Color3.fromRGB(10, 14, 20), -- Deep neutral ground shadow
		SunRaysIntensity = 0.0,
		SunRaysSpread = 0.5,
		FogEnd = 2400,
		FogColor = Color3.fromRGB(16, 20, 32),
		ExposureCompensation = -0.08,
		CloudCover = 0.16,
		CloudColor = Color3.fromRGB(45, 50, 70),
		CloudDensity = 0.45,
		AtmosphereDensity = 0.28,
		AtmosphereOffset = 0.18,
		AtmosphereColor = Color3.fromRGB(65, 78, 105),
		AtmosphereDecay = Color3.fromRGB(22, 28, 45),
		AtmosphereGlare = 0.0,
		AtmosphereHaze = 0.60,
	},
	{
		Hour = 5.0,
		Brightness = 1.3,
		Ambient = Color3.fromRGB(52, 60, 78),
		OutdoorAmbient = Color3.fromRGB(70, 80, 100),
		ColorShift_Top = Color3.fromRGB(255, 225, 200), -- Soft early dawn horizon glow (natural, non-muddy)
		ColorShift_Bottom = Color3.fromRGB(35, 38, 42),
		SunRaysIntensity = 0.22,
		SunRaysSpread = 0.82,
		FogEnd = 2400,
		FogColor = Color3.fromRGB(55, 58, 76),
		ExposureCompensation = 0.0,
		CloudCover = 0.25,
		CloudColor = Color3.fromRGB(145, 130, 155),
		CloudDensity = 0.50,
		AtmosphereDensity = 0.30,
		AtmosphereOffset = 0.18,
		AtmosphereColor = Color3.fromRGB(175, 165, 190),
		AtmosphereDecay = Color3.fromRGB(70, 65, 88),
		AtmosphereGlare = 0.15,
		AtmosphereHaze = 1.30,
	},
	{
		Hour = 6.5,
		Brightness = 2.4,
		Ambient = Color3.fromRGB(70, 80, 95),
		OutdoorAmbient = Color3.fromRGB(115, 122, 135),
		ColorShift_Top = Color3.fromRGB(255, 238, 215), -- Warm morning sun
		ColorShift_Bottom = Color3.fromRGB(55, 58, 62),
		SunRaysIntensity = 0.28,
		SunRaysSpread = 0.88,
		FogEnd = 2400,
		FogColor = Color3.fromRGB(185, 160, 145),
		ExposureCompensation = 0.02,
		CloudCover = 0.30,
		CloudColor = Color3.fromRGB(220, 205, 190),
		CloudDensity = 0.55,
		AtmosphereDensity = 0.32,
		AtmosphereOffset = 0.18,
		AtmosphereColor = Color3.fromRGB(195, 205, 225),
		AtmosphereDecay = Color3.fromRGB(110, 115, 135),
		AtmosphereGlare = 0.25,
		AtmosphereHaze = 1.50,
	},
	{
		Hour = 10.0,
		Brightness = 2.8,
		Ambient = Color3.fromRGB(75, 90, 110),
		OutdoorAmbient = Color3.fromRGB(115, 132, 150),
		ColorShift_Top = Color3.fromRGB(255, 248, 238), -- Natural crisp alpine daylight
		ColorShift_Bottom = Color3.fromRGB(65, 68, 72), -- Neutral balanced earth bounce
		SunRaysIntensity = 0.28,
		SunRaysSpread = 0.86,
		FogEnd = 2400,
		FogColor = Color3.fromRGB(195, 180, 165),
		ExposureCompensation = 0.02,
		CloudCover = 0.32,
		CloudColor = Color3.fromRGB(245, 248, 255),
		CloudDensity = 0.55,
		AtmosphereDensity = 0.34,
		AtmosphereOffset = 0.18,
		AtmosphereColor = Color3.fromRGB(175, 200, 225), -- Matches Editor atmosphere
		AtmosphereDecay = Color3.fromRGB(95, 120, 145),
		AtmosphereGlare = 0.25,
		AtmosphereHaze = 1.80, -- Soft, beautiful mountain horizon mist matching Editor view!
	},
	{
		Hour = 14.0,
		Brightness = 2.8,
		Ambient = Color3.fromRGB(75, 90, 110),
		OutdoorAmbient = Color3.fromRGB(115, 132, 150),
		ColorShift_Top = Color3.fromRGB(255, 248, 238), -- Natural crisp alpine daylight
		ColorShift_Bottom = Color3.fromRGB(65, 68, 72),
		SunRaysIntensity = 0.28,
		SunRaysSpread = 0.88,
		FogEnd = 2400,
		FogColor = Color3.fromRGB(195, 180, 165),
		ExposureCompensation = 0.02,
		CloudCover = 0.32,
		CloudColor = Color3.fromRGB(245, 248, 255),
		CloudDensity = 0.55,
		AtmosphereDensity = 0.34,
		AtmosphereOffset = 0.18,
		AtmosphereColor = Color3.fromRGB(175, 200, 225), -- Matches Editor atmosphere
		AtmosphereDecay = Color3.fromRGB(95, 120, 145),
		AtmosphereGlare = 0.25,
		AtmosphereHaze = 1.80, -- Soft, beautiful mountain horizon mist matching Editor view!
	},
	{
		Hour = 16.5,
		Brightness = 2.7,
		Ambient = Color3.fromRGB(75, 88, 108),
		OutdoorAmbient = Color3.fromRGB(115, 128, 145),
		ColorShift_Top = Color3.fromRGB(255, 236, 210), -- Subtle warm late afternoon gold
		ColorShift_Bottom = Color3.fromRGB(60, 62, 65),
		SunRaysIntensity = 0.32,
		SunRaysSpread = 0.88,
		FogEnd = 2400,
		FogColor = Color3.fromRGB(205, 175, 150),
		ExposureCompensation = 0.03,
		CloudCover = 0.30,
		CloudColor = Color3.fromRGB(245, 235, 225),
		CloudDensity = 0.55,
		AtmosphereDensity = 0.34,
		AtmosphereOffset = 0.18,
		AtmosphereColor = Color3.fromRGB(180, 200, 225), -- Matches Editor atmosphere
		AtmosphereDecay = Color3.fromRGB(100, 118, 140),
		AtmosphereGlare = 0.25,
		AtmosphereHaze = 1.80, -- Soft, beautiful mountain horizon mist matching Editor view!
	},
	{
		Hour = 17.5,
		Brightness = 2.4,
		Ambient = Color3.fromRGB(75, 82, 102),
		OutdoorAmbient = Color3.fromRGB(115, 118, 136),
		ColorShift_Top = Color3.fromRGB(255, 215, 175), -- Soft warm golden sunset (natural, never orange paint)
		ColorShift_Bottom = Color3.fromRGB(50, 48, 50),
		SunRaysIntensity = 0.36,
		SunRaysSpread = 0.90,
		FogEnd = 2400,
		FogColor = Color3.fromRGB(188, 142, 112),
		ExposureCompensation = 0.05,
		CloudCover = 0.26,
		CloudColor = Color3.fromRGB(235, 170, 135),
		CloudDensity = 0.50,
		AtmosphereDensity = 0.34,
		AtmosphereOffset = 0.18,
		AtmosphereColor = Color3.fromRGB(225, 175, 140),
		AtmosphereDecay = Color3.fromRGB(95, 75, 90),
		AtmosphereGlare = 0.28,
		AtmosphereHaze = 1.60,
	},
	{
		Hour = 19.0,
		Brightness = 1.1,
		Ambient = Color3.fromRGB(48, 55, 75),
		OutdoorAmbient = Color3.fromRGB(65, 75, 98),
		ColorShift_Top = Color3.fromRGB(175, 185, 205), -- Soft neutral twilight dusk (NO purple tint on grass!)
		ColorShift_Bottom = Color3.fromRGB(22, 24, 28),
		SunRaysIntensity = 0.08,
		SunRaysSpread = 0.70,
		FogEnd = 2400,
		FogColor = Color3.fromRGB(48, 45, 68),
		ExposureCompensation = -0.04,
		CloudCover = 0.20,
		CloudColor = Color3.fromRGB(105, 90, 120),
		CloudDensity = 0.45,
		AtmosphereDensity = 0.30,
		AtmosphereOffset = 0.18,
		AtmosphereColor = Color3.fromRGB(115, 115, 145),
		AtmosphereDecay = Color3.fromRGB(45, 45, 65),
		AtmosphereGlare = 0.10,
		AtmosphereHaze = 1.10,
	},
	{
		Hour = 22.0,
		Brightness = 0.55,
		Ambient = Color3.fromRGB(28, 35, 52),
		OutdoorAmbient = Color3.fromRGB(35, 45, 65),
		ColorShift_Top = Color3.fromRGB(160, 180, 220), -- Soft gentle silver moonlight (natural)
		ColorShift_Bottom = Color3.fromRGB(10, 14, 20),
		SunRaysIntensity = 0.0,
		SunRaysSpread = 0.5,
		FogEnd = 2400,
		FogColor = Color3.fromRGB(18, 22, 36),
		ExposureCompensation = -0.08,
		CloudCover = 0.16, -- Parting clouds to showcase the Milky Way Galaxy!
		CloudColor = Color3.fromRGB(48, 52, 72),
		CloudDensity = 0.45,
		AtmosphereDensity = 0.28,
		AtmosphereOffset = 0.18,
		AtmosphereColor = Color3.fromRGB(55, 72, 105),
		AtmosphereDecay = Color3.fromRGB(20, 28, 45),
		AtmosphereGlare = 0.0,
		AtmosphereHaze = 0.60,
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
