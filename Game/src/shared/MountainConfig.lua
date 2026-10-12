--!strict
--[[
    MountainConfig.lua
    Configuration for the world-edge mountain barrier system
    for "Don't Let the Fire Die". Developed for Fluenosity Studio.
    
    Defines mountain generation parameters, terrain materials, noise settings,
    and world boundary. The MountainGenerator reads this config and creates
    realistic mountain terrain around the world edges.
]]

local MountainConfig = {}

-- World boundary (matches the true mountain ridge barrier enclosing the valley)
MountainConfig.WorldBounds = {
	MinX = -720,
	MaxX = 720,
	MinZ = -720,
	MaxZ = 720,
	Radius = 720, -- Circular mountain barrier radius
	GroundTopY = 2,
}

-- How far the mountain ring extends outward from the world bounds
MountainConfig.MountainBandWidth = 250

-- Height parameters (in studs)
MountainConfig.MinHeight = 45
MountainConfig.MaxHeight = 350

-- Voxel resolution (Roblox terrain is fixed at 4)
MountainConfig.VoxelResolution = 4

-- Material thresholds (height above ground in studs)
MountainConfig.MaterialThresholds = {
	Grass = 25,
	Rock = 60,
	Snow = 140,
}

-- Boundary & Barrier settings
MountainConfig.Barrier = {
	-- Circular boundary radius
	Radius = 720,
	-- Warning threshold (studs from center where horror dread and vignette activate)
	WarningRadius = 640,
	-- Smooth pushback distance (studs) back into the valley
	TeleportDistance = 35,
	-- Check interval (seconds)
	CheckInterval = 0.25,
	-- Warning duration (seconds)
	WarningDuration = 3.5,
	-- Atmospheric horror message
	Message = "The freezing mountain blizzard suffocates you... The wild mountains beyond are death.",
	WarningMessage = "A chilling dread grips you as the freezing wind howls... Return to the campfire.",
}

return MountainConfig

