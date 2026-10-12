--!strict
--[[
    EnvironmentConfig.lua
    Master Configuration for Realistic Heavy Forest Environment Generation
    for "Don't Let the Fire Die" (Fluenosity Studio).
    
    V3 Heavy Forest Overhaul:
    - High-Density Tree Population: 350 total trees (280 playable basin + 70 backdrop ridge silhouettes)
    - Precise Ground Snapping: 100% mathematical bounding-box grounding (0 buried trees)
    - Realistic Earth Terrain: Breaks the "carpet" look by blending LeafyGrass mulch, Ground soil, Mud hollows, and Grass
    - Camp Sanctuary Protection: Expanded 58-stud exclusion zone preserving bus, campfire, fence, and watchtower
    - Heavy Foliage: Abundant ferns, snaking surface roots, and mossy deadwood
]]

export type TreeSpeciesConfig = {
    Name: string,
    Archetype: "TallPine" | "Spruce" | "Fir" | "Sapling" | "DeadSnag",
    HeightMin: number,
    HeightMax: number,
    TrunkRadiusMin: number,
    TrunkRadiusMax: number,
    CrownRadiusMin: number,
    CrownRadiusMax: number,
    BranchTiersMin: number,
    BranchTiersMax: number,
    FoliageColors: { Color3 },
    BarkColors: { Color3 },
    Weight: number,
}

local EnvironmentConfig = {}

-- ---------------------------------------------------------------------------
-- 1. GLOBAL WORLD & REGENERATION SETTINGS
-- ---------------------------------------------------------------------------
EnvironmentConfig.WORLD_SIZE = Vector2.new(512, 512)
EnvironmentConfig.WORLD_CENTER = Vector3.new(0, 0, 0)
EnvironmentConfig.SEED = 133742

EnvironmentConfig.AUTO_GENERATE_ON_SERVER_START = false -- Only generate on manual trigger (prevents generating again and again)
EnvironmentConfig.REGENERATE_IF_EXISTS = false         -- Keep existing forest permanent
EnvironmentConfig.RESHAPE_ELEVATION = false            -- Preserves existing sculpted terrain, leveled village terraces & roads

EnvironmentConfig.CONTAINER_NAME = "ForestEnvironment"
EnvironmentConfig.FOLDER_TREES = "Trees"
EnvironmentConfig.FOLDER_ROCKS = "Rocks"
EnvironmentConfig.FOLDER_GROUND_COVER = "GroundCover"

-- ---------------------------------------------------------------------------
-- ---------------------------------------------------------------------------
-- 2. PROTECTED HUB EXCLUSION ZONES (Camp, Watchtower, Village)
-- ---------------------------------------------------------------------------
EnvironmentConfig.CAMP_CENTER = Vector3.new(0, 0, -430)
EnvironmentConfig.CAMP_EXCLUSION_RADIUS = 50.0  -- Protected South campsite perimeter
EnvironmentConfig.CAMP_BLEND_RADIUS = 56.0      -- Smooth rolling elevation transition into deep forest

EnvironmentConfig.WATCHTOWER_CENTER = Vector3.new(0, 0, 0)
EnvironmentConfig.WATCHTOWER_EXCLUSION_RADIUS = 35.0 -- Center Watch Tower clearing

EnvironmentConfig.VILLAGE_BOUNDS_MIN = Vector2.new(-230, 410)
EnvironmentConfig.VILLAGE_BOUNDS_MAX = Vector2.new(40, 590)

-- ---------------------------------------------------------------------------
-- 2B. WOODLAND TRAILS & EXPLORATION PATHWAYS (Production-Grade & Reversible)
-- ---------------------------------------------------------------------------
-- Set ENABLE_PATHS = false to INSTANTLY revert to 100% pathless dense forest!
EnvironmentConfig.ENABLE_PATHS = true

EnvironmentConfig.PATHS = {
    DefaultPathWidth = 10.0,    -- 10 studs wide: ample space for 2 players sprinting side-by-side
    BlendMargin = 3.5,         -- Feathered natural earth blending at trail edges
    TreeClearance = 6.5,       -- Clear corridor keeping tree canopies off trail running corridors
    RockClearance = 2.0,       -- Keeps boulders from obstructing running corridors
    GroundCoverClearance = 1.0,-- Keeps logs and snags off the trail
    
    -- Organic Meander Settings (Transforms straight lines into natural winding trails)
    MeanderAmplitude = 12.0,   -- Gentle lateral curve deflection (curvy without being shaky)
    MeanderWavelength = 55.0,  -- Distance along path for smooth serpentine S-curves
    BuildClearingRadius = 18.0,-- Open clearing at trail junctions
    
    Definitions = {
        -- 1. Center Watch Tower <-> North Village (Red route W -> V)
        {
            Id = "WatchtowerToVillage",
            Name = "Watchtower to North Village Trail",
            Waypoints = {
                Vector2.new(0, 25),     -- Watch Tower North exit
                Vector2.new(-22, 110),  -- Curving West through pine grove
                Vector2.new(16, 200),   -- Sweeping East across rolling knoll
                Vector2.new(-28, 285),  -- Glade bend
                Vector2.new(-68, 365),  -- Village approach corridor
                Vector2.new(-100, 435), -- Village South Gate Plaza
            },
            ClearingCenter = Vector2.new(-100, 435),
            ClearingRadius = 22.0,
            MeanderPhase = 1.1,
            SeedOffset = 202,
        },
        
        -- 2. Center Watch Tower <-> Northwest Gas Station (Red route W -> GS)
        {
            Id = "WatchtowerToGasStation",
            Name = "Watchtower to Gas Station Trail",
            Waypoints = {
                Vector2.new(20, 20),    -- Watch Tower Northwest exit
                Vector2.new(105, 80),   -- Gentle sweep toward northwest ridge
                Vector2.new(195, 135),  -- Pine valley bend
                Vector2.new(290, 185),  -- Foothill road curve
                Vector2.new(355, 220),  -- Approach straightaway
                Vector2.new(398, 250),  -- Rusty Gas Station forecourt
            },
            ClearingCenter = Vector2.new(398, 250),
            ClearingRadius = 22.0,
            MeanderPhase = 0.8,
            SeedOffset = 505,
        },
        
        -- 3. North Village <-> East Trader Silas (Purple route V -> T)
        {
            Id = "VillageToTrader",
            Name = "Village to Silas East Foothills Trail",
            Waypoints = {
                Vector2.new(-160, 440), -- Village West/South Terrace exit
                Vector2.new(-220, 415), -- Mountain foothill traverse
                Vector2.new(-285, 365), -- Sweeping outer curve past boulders
                Vector2.new(-340, 290), -- Eastern ridge descent
                Vector2.new(-370, 210), -- Approaching Silas canyon
                Vector2.new(-398, 140), -- Trader Silas Trading Post
            },
            ClearingCenter = Vector2.new(-398, 140),
            ClearingRadius = 20.0,
            MeanderPhase = 0.6,
            SeedOffset = 808,
        },
        
        -- 4. South Camp <-> East Trader Silas (User hand-drawn winding route)
        {
            Id = "CampToTrader",
            Name = "Camp to Silas Winding Route",
            Waypoints = {
                Vector2.new(-20, -410), -- Camp East Gate
                Vector2.new(-60, -330), -- Sweep North-East into basin
                Vector2.new(-160, -290),-- Curving East across basin
                Vector2.new(-210, -225),-- Turning North
                Vector2.new(-140, -145),-- Inward S-curve loop toward basin
                Vector2.new(-250, -65), -- Sweeping Eastward S-loop
                Vector2.new(-330, 25),  -- Ascending North toward Silas canyon
                Vector2.new(-398, 125), -- Silas Trading Post
            },
            ClearingCenter = Vector2.new(-398, 125),
            ClearingRadius = 20.0,
            MeanderAmplitude = 2.0, -- Preserves exact hand-drawn Catmull-Rom spline curves
            MeanderPhase = 0.0,
            SeedOffset = 606,
        },
        
        -- 5. South Camp <-> West Lake Shore (User hand-drawn winding route)
        {
            Id = "CampToLake",
            Name = "Camp to Lake Shore Winding Route",
            Waypoints = {
                Vector2.new(25, -410),  -- Camp West Gate
                Vector2.new(75, -400),  -- Curving West-Northwest
                Vector2.new(85, -340),  -- Heading North
                Vector2.new(65, -275),  -- Inward S-curve bend
                Vector2.new(135, -205), -- Outward bend to the West
                Vector2.new(180, -140), -- Heading North past knolls
                Vector2.new(235, -85),  -- Curving along south rim of lake
                Vector2.new(285, -45),  -- Rustic Lake Pier Shoreline
            },
            ClearingCenter = Vector2.new(285, -45),
            ClearingRadius = 20.0,
            MeanderAmplitude = 2.0, -- Preserves exact hand-drawn Catmull-Rom spline curves
            MeanderPhase = 0.0,
            SeedOffset = 707,
        },
    },
}

-- ---------------------------------------------------------------------------
-- 3. VOXEL TERRAIN CONFIGURATION (Organic Elevation & Realistic Earth Blending)
-- ---------------------------------------------------------------------------
EnvironmentConfig.TERRAIN = {
    BaseHeight = 5.5,
    VoxelResolution = 4,
    ReshapingStrength = 1.0, -- Overall terrain sculpting intensity
    
    -- Multi-Scale Elevation Hierarchy (Natural Woodland Sculpting V3 - Visible Rolling Hills)
    -- A. Small Ground Bumps (Noticeable rounded micro-relief across open ground)
    SmallBumps = {
        Frequency = 0.065,
        Amplitude = 1.6,       -- Distinct rounded micro-mounds & depressions underfoot
    },
    
    -- B. Small Rolling Hills (Local knolls, undulating slopes & shoulders)
    RollingHills = {
        Frequency = 0.018,
        Amplitude = 4.2,       -- Rolling woodland hills & crests
        ShoulderFrequency = 0.028,
        ShoulderAmplitude = 2.4,
    },
    
    -- C. Medium Raised Areas (Elevated conifer ridges & prominent woodland mounds)
    MediumRises = {
        Frequency = 0.009,
        Amplitude = 9.0,       -- Broad prominent woodland ridges (Y reaching 17-20)
    },
    
    -- D. Lowlands and Shallow Valleys (Natural meandering drainage swales)
    Lowlands = {
        Frequency = 0.007,
        Depth = 2.8,           -- Shallow swales flowing naturally
    },
    
    -- E. Landscape Rhythm Modulation (Alternates between calm clearings & rolling woodland)
    ReliefModulation = {
        Frequency = 0.0035,    -- Macro wavelength (~280 studs)
        MinFactor = 0.75,      -- Calm glades
        MaxFactor = 1.25,      -- Rolling ridges
    },
    
    -- Organic Domain Warping (Curves and meanders landforms organically)
    DomainWarp = {
        Frequency = 0.004,
        Strength = 28.0,
    },
    
    -- Protected Regions & Landmark Safeguards
    ProtectedRegions = {
        Camp = {
            Center = Vector3.new(0, 3.85, 0),
            CoreRadius = 28.0,       -- Strictly preserved flat sanctuary floor at Y=3.85
            BlendRadius = 45.0,      -- Tight, smooth transition so terrain rolls right outside fence
            SurfaceRoughness = 0.08, -- Subtle trodden dirt roughness
        },
        Lake = {
            Center = Vector2.new(416, -48),
            RadiusX = 136.0,
            RadiusZ = 104.0,
            WaterLevel = 1.02,
            ShoreBlendStart = 0.90,  -- Water line
            ShoreBlendEnd = 1.35,    -- Full merge into rolling valley
        },
        Foothills = {
            InnerRadius = 400.0,
            OuterRadius = 660.0,
            PeakRise = 48.0,
            CragNoiseAmp = 14.0,
        },
    },
    
    -- Multi-Material Wilderness Blending
    Materials = {
        Camp = Enum.Material.Ground,
        CampVerge = Enum.Material.Ground,
        LeafyGrass = Enum.Material.LeafyGrass,
        Ground = Enum.Material.Ground,
        Grass = Enum.Material.Grass,
        Mud = Enum.Material.Mud,
        Rock = Enum.Material.Rock,
        Slate = Enum.Material.Slate,
        Basalt = Enum.Material.Basalt,
        Cobblestone = Enum.Material.Cobblestone,
        Sand = Enum.Material.Sand,
        
        SteepSlopeThreshold = 30.0,
        ModerateSlopeThreshold = 22.0,
        RockCliffThreshold = 42.0,
    },
    
    -- Harmonized Earth Shaders (Low Contrast, Organic Natural Forest Palette)
    -- Curated with minimal contrast delta so transitions look like organic needle duff fading into wild grass
    MaterialColors = {
        [Enum.Material.Grass] = Color3.fromRGB(86, 114, 60),       -- Vibrant alpine conifer meadow green
        [Enum.Material.LeafyGrass] = Color3.fromRGB(80, 98, 56),  -- Soft mossy needle duff (harmonized near grass)
        [Enum.Material.Ground] = Color3.fromRGB(82, 78, 62),      -- Natural trodden campsite earth (low contrast)
        [Enum.Material.Mud] = Color3.fromRGB(68, 66, 54),         -- Subtle damp swale loam (no dark black spots)
        [Enum.Material.Rock] = Color3.fromRGB(92, 90, 86),        -- Granite crag grey
        [Enum.Material.Slate] = Color3.fromRGB(72, 70, 68),       -- Slate cliff face grey
        [Enum.Material.Basalt] = Color3.fromRGB(54, 52, 50),      -- Volcanic dark stone
        [Enum.Material.Cobblestone] = Color3.fromRGB(88, 84, 76), -- Weathered trail stones
        [Enum.Material.Sand] = Color3.fromRGB(158, 142, 112),     -- Natural alpine lakeshore sand
    },
}

-- ---------------------------------------------------------------------------
-- 3B. POST-PROCESSING & ATMOSPHERE (Editor & Game Balanced Horizon Aerial Fog)
-- ---------------------------------------------------------------------------
EnvironmentConfig.POST_PROCESSING = {
    EnableFutureLighting = true,
    EnableTerrainDecoration = true,
    
    Lighting = {
        Brightness = 2.8,
        Ambient = Color3.fromRGB(75, 90, 110),
        OutdoorAmbient = Color3.fromRGB(115, 132, 150),
        ShadowSoftness = 0.15,
        ClockTime = 14.5,
        GeographicLatitude = 48.0,
        ExposureCompensation = 0.02,
        EnvironmentDiffuseScale = 1.0,
        EnvironmentSpecularScale = 0.85,
        FogEnd = 2400, -- High FogEnd so foreground/midground terrain is crisp
    },
    Atmosphere = {
        Density = 0.34,                           -- Balanced aerial perspective
        Offset = 0.18,                            -- Keeps valley floor clear while veiling distant mountain base
        Haze = 1.80,                              -- Soft atmospheric mountain horizon mist matching Editor view!
        Color = Color3.fromRGB(175, 200, 225),
        Decay = Color3.fromRGB(95, 120, 145),
        Glare = 0.25,
    },
    DepthOfField = {
        FarIntensity = 0.20,    -- Subtly softens distant low-poly mountain polygon silhouettes
        FocusDistance = 280.0,  -- Full interior basin (0 to 520 studs) in crisp focus
        InFocusRadius = 240.0,
        NearIntensity = 0.0,
    },
    ColorCorrection = {
        Brightness = 0.02,
        Contrast = 0.05,
        Saturation = 0.12,
        TintColor = Color3.fromRGB(255, 252, 246),
    },
    Bloom = {
        Intensity = 0.25,
        Size = 14,
        Threshold = 1.25,
    },
    SunRays = {
        Intensity = 0.18,
        Spread = 0.82,
    },
}

-- ---------------------------------------------------------------------------
-- 3C. DYNAMIC SKY & VOLUMETRIC DRIFTING CLOUDS (Day & 4K Milky Way Galaxy Night)
-- ---------------------------------------------------------------------------
EnvironmentConfig.SKY = {
    -- Day: Crisp, realistic alpine daytime skybox
    Day = {
        SkyboxBk = "http://www.roblox.com/asset/?id=91458024",
        SkyboxDn = "http://www.roblox.com/asset/?id=91457980",
        SkyboxFt = "http://www.roblox.com/asset/?id=91458024",
        SkyboxLf = "http://www.roblox.com/asset/?id=91458024",
        SkyboxRt = "http://www.roblox.com/asset/?id=91458024",
        SkyboxUp = "http://www.roblox.com/asset/?id=91458002",
        SunAngularSize = 21,
        MoonAngularSize = 12,
        CelestialBodiesShown = true,
    },
    -- Night: NASA 4K Deep Star Map & Luminous Milky Way Galaxy
    Night = {
        SkyboxBk = "rbxassetid://15146674442",
        SkyboxDn = "rbxassetid://15146673704",
        SkyboxFt = "rbxassetid://15146672849",
        SkyboxLf = "rbxassetid://15146672013",
        SkyboxRt = "rbxassetid://15146671172",
        SkyboxUp = "rbxassetid://15146670489",
        SunAngularSize = 21,
        MoonAngularSize = 14,
        CelestialBodiesShown = false, -- Skybox has its own high-res starfield and lunar glow
        StarCount = 3000,
    },
    -- Animated Volumetric Clouds
    Clouds = {
        DayCover = 0.32,
        NightCover = 0.16,      -- Opens up at night to showcase the Milky Way Galaxy
        Density = 0.55,         -- Volumetric thickness
        GlobalWind = Vector3.new(16, 0, 10), -- Continuously animates cloud drift across the sky
    },
}

-- ---------------------------------------------------------------------------
-- 4. HEAVY TREE POPULATION & TEMPLATE MESH PREFERENCE
-- ---------------------------------------------------------------------------
EnvironmentConfig.TREES = {
    MaxPlayableTreeBudget = 320,  -- Dense, thick wilderness canopy
    BackdropTreeBudget = 80,     -- Dense ridge silhouettes (400 total)
    MinTreeDistance = 8.5,       -- Closer spacing for dense overlapping thickets
    MaxSlopeAngle = 42.0,
    
    Species = {
        TallPine = {
            Name = "TallPine",
            Archetype = "TallPine",
            HeightMin = 36.0,
            HeightMax = 52.0,
            TrunkRadiusMin = 1.5,
            TrunkRadiusMax = 2.2,
            CrownRadiusMin = 11.0,
            CrownRadiusMax = 15.5,
            BranchTiersMin = 13,
            BranchTiersMax = 18,
            FoliageColors = {
                Color3.fromRGB(34, 54, 36),
                Color3.fromRGB(40, 62, 42),
                Color3.fromRGB(28, 48, 32),
            },
            BarkColors = {
                Color3.fromRGB(72, 54, 42),
                Color3.fromRGB(60, 46, 36),
            },
            Weight = 45,
        } :: TreeSpeciesConfig,

        MountainSpruce = {
            Name = "MountainSpruce",
            Archetype = "Spruce",
            HeightMin = 28.0,
            HeightMax = 42.0,
            TrunkRadiusMin = 1.2,
            TrunkRadiusMax = 1.8,
            CrownRadiusMin = 9.0,
            CrownRadiusMax = 13.0,
            BranchTiersMin = 14,
            BranchTiersMax = 20,
            FoliageColors = {
                Color3.fromRGB(24, 46, 38),
                Color3.fromRGB(20, 40, 34),
            },
            BarkColors = {
                Color3.fromRGB(56, 48, 42),
            },
            Weight = 35,
        } :: TreeSpeciesConfig,

        AlpineFir = {
            Name = "AlpineFir",
            Archetype = "Fir",
            HeightMin = 24.0,
            HeightMax = 36.0,
            TrunkRadiusMin = 1.1,
            TrunkRadiusMax = 1.6,
            CrownRadiusMin = 9.5,
            CrownRadiusMax = 13.5,
            BranchTiersMin = 13,
            BranchTiersMax = 19,
            FoliageColors = {
                Color3.fromRGB(32, 56, 36),
            },
            BarkColors = {
                Color3.fromRGB(66, 54, 44),
            },
            Weight = 15,
        } :: TreeSpeciesConfig,

        DeadPineSnag = {
            Name = "DeadPineSnag",
            Archetype = "DeadSnag",
            HeightMin = 18.0,
            HeightMax = 28.0,
            TrunkRadiusMin = 1.1,
            TrunkRadiusMax = 1.6,
            CrownRadiusMin = 2.0,
            CrownRadiusMax = 3.5,
            BranchTiersMin = 2,
            BranchTiersMax = 4,
            FoliageColors = {},
            BarkColors = {
                Color3.fromRGB(86, 82, 78),
                Color3.fromRGB(68, 65, 62),
            },
            Weight = 5,
        } :: TreeSpeciesConfig,
    },
    
    TrunkCanCollide = true,
    FoliageCanCollide = false,
    FoliageCanTouch = false,
    FoliageCanQuery = false,
    CastShadow = true,
}

-- ---------------------------------------------------------------------------
-- 5. WEATHERED ROCKS & BOUDERS
-- ---------------------------------------------------------------------------
EnvironmentConfig.ROCKS = {
    TotalRockBudget = 55,
    MinRockDistance = 14.0,
    
    Sizes = {
        Small = {
            ScaleMin = Vector3.new(2.4, 1.5, 2.2),
            ScaleMax = Vector3.new(4.0, 2.4, 3.6),
            Weight = 45,
        },
        Medium = {
            ScaleMin = Vector3.new(4.8, 3.2, 4.4),
            ScaleMax = Vector3.new(7.5, 5.2, 6.8),
            Weight = 40,
        },
        LargeBoulder = {
            ScaleMin = Vector3.new(8.5, 6.5, 8.0),
            ScaleMax = Vector3.new(13.0, 9.5, 11.5),
            Weight = 15,
        },
    },
    
    Materials = {
        Enum.Material.Rock,
        Enum.Material.Slate,
        Enum.Material.Basalt,
    },
    
    Colors = {
        Color3.fromRGB(82, 80, 77),
        Color3.fromRGB(94, 91, 86),
        Color3.fromRGB(68, 66, 63),
        Color3.fromRGB(88, 85, 78),
    },
}

-- ---------------------------------------------------------------------------
-- 6. GROUND COVER & NATURAL FOREST FLOOR V3 (3-Tier Density System)
-- ---------------------------------------------------------------------------
EnvironmentConfig.GROUND_COVER = {
    -- Budgets across the 512x512 world (Balanced for AAA fidelity + Mobile performance)
    GrassClumpsBudget = 340,         -- S-tier 3D multi-blade clumps distributed across 3 density tiers
    FernClumpsBudget = 160,          -- Layered woodland ferns in shaded/dense patches
    SurfaceRootsBudget = 0,          -- Surface roots removed per user request
    FallenLogsBudget = 0,            -- Fallen logs removed per user request
    EmbeddedPebblesBudget = 120,     -- Small natural stones embedded 40% into the earth
    MossCushionsBudget = 75,         -- Organic low moss mounds skirting rocks and trees
    
    -- Spatial 3-Tier Density Mask Settings (Continuous Perlin Field)
    DensityField = {
        MacroScale = 0.016,          -- Broad 60-stud spatial density waves
        MesoScale = 0.045,           -- 20-stud cluster variation
        
        -- Spatial Area Allocation (Prompt tuned):
        -- ~25% Sparse, ~50% Medium, ~25% Dense
        SparseThreshold = 0.32,      -- Density < 0.32 -> Level A (Sparse: 10-15% coverage)
        MediumThreshold = 0.72,      -- 0.32 <= Density <= 0.72 -> Level B (Medium: 30-45% coverage)
                                     -- Density > 0.72 -> Level C (Dense: 60-75% coverage)
    },
    
    -- Level A, B, C Characteristic Specifications
    Tiers = {
        Sparse = {
            Name = "Sparse",
            Description = "Open traversed ground, visible soil, wide separation",
            TargetCoveragePercent = 0.12,   -- 10-15%
            ClumpScaleMin = 0.65,
            ClumpScaleMax = 0.95,
            BladeCountMin = 2,
            BladeCountMax = 4,
            HeightMin = 0.8,
            HeightMax = 1.4,
            FernChance = 0.04,
            PebbleChance = 0.40,
            MossChance = 0.05,
        },
        Medium = {
            Name = "Medium",
            Description = "Dominant forest floor, irregular clusters, exposed soil gaps",
            TargetCoveragePercent = 0.38,   -- 30-45%
            ClumpScaleMin = 0.90,
            ClumpScaleMax = 1.35,
            BladeCountMin = 4,
            BladeCountMax = 7,
            HeightMin = 1.3,
            HeightMax = 2.4,
            FernChance = 0.22,
            PebbleChance = 0.20,
            MossChance = 0.15,
        },
        Dense = {
            Name = "Dense",
            Description = "Selected sheltered thickets, overlapping silhouettes, rich ferns",
            TargetCoveragePercent = 0.68,   -- 60-75%
            ClumpScaleMin = 1.30,
            ClumpScaleMax = 1.85,
            BladeCountMin = 7,
            BladeCountMax = 12,
            HeightMin = 2.0,
            HeightMax = 3.6,
            FernChance = 0.55,
            PebbleChance = 0.12,
            MossChance = 0.45,
        },
    },
    
    -- Campsite Perimeter Designated Zones (Areas A - E from Reference)
    PerimeterZones = {
        -- Area A: Behind Rear Fence (North/Northwest exterior)
        RearFence = {
            AngleMin = -3.14,
            AngleMax = -1.8,
            MinRadius = 48.0,
            MaxRadius = 78.0,
            PreferredTier = "Dense",
            FernWeightMultiplier = 1.6,
        },
        -- Area B: Broken Gate Approach
        BrokenGate = {
            AngleMin = -1.6,
            AngleMax = -0.9,
            MinRadius = 45.0,
            MaxRadius = 65.0,
            PreferredTier = "Sparse",
            KeepTraversable = true,
        },
        -- Area C: Winding Forest Paths
        ForestTrail = {
            CoreClearance = 1.5,     -- Studs from path edge kept 100% free of vegetation
            VergeMaxTier = "Sparse", -- Only sparse low tufts on edges
        },
        -- Area D: Right-Side Fence
        RightFence = {
            AngleMin = 0.5,
            AngleMax = 1.8,
            MinRadius = 48.0,
            MaxRadius = 75.0,
            PreferredTier = "Medium",
            StoneWeightMultiplier = 1.5,
        },
        -- Area E: Foreground Outside Fence (South exterior)
        Foreground = {
            AngleMin = 1.8,
            AngleMax = 3.14,
            MinRadius = 48.0,
            MaxRadius = 82.0,
            PreferredTier = "Medium", -- Rich mixture of dense thickets & exposed soil
            EnableRichForegroundMix = true,
        },
    },
    
    -- Curated Muted Color Palettes (Authentic wilderness tones from Image 3)
    GrassColors = {
        Color3.fromRGB(48, 74, 42),  -- Deep woodland conifer green
        Color3.fromRGB(58, 86, 48),  -- Muted forest green
        Color3.fromRGB(72, 94, 52),  -- Olive moss green
        Color3.fromRGB(42, 62, 38),  -- Shaded needle green
        Color3.fromRGB(86, 92, 54),  -- Sun-drenched olive tuft
    },
    
    FernColors = {
        Color3.fromRGB(36, 64, 38),
        Color3.fromRGB(44, 76, 46),
        Color3.fromRGB(32, 56, 34),
    },
    
    MossColors = {
        Color3.fromRGB(36, 58, 32),
        Color3.fromRGB(48, 72, 38),
        Color3.fromRGB(54, 76, 42),
    },
    
    PebbleColors = {
        Color3.fromRGB(72, 70, 68),
        Color3.fromRGB(86, 82, 78),
        Color3.fromRGB(60, 58, 56),
    },
    
    -- Placement Constraints & Performance
    MaxSlopeAngle = 32.0,            -- Vegetation does not hang off steep cliff faces
    MaxTreeCloseness = 2.8,          -- Minimum distance from trunk center
    CanCollide = false,              -- Zero physics overhead
    CanTouch = false,
    CanQuery = false,
    CastShadow = false,
    MobileQuality = "High",          -- "High" | "Medium" | "Low"
}

-- ---------------------------------------------------------------------------
-- 7. BACKWARD-COMPATIBLE ALIASES
-- ---------------------------------------------------------------------------
-- Top-level backward-compatible aliases (prevents attempt to index nil with 'Brightness' on older script versions)

-- Top-level backward-compatible aliases (prevents attempt to index nil with 'Brightness' on older script versions)
EnvironmentConfig.Lighting = EnvironmentConfig.POST_PROCESSING.Lighting
EnvironmentConfig.Atmosphere = EnvironmentConfig.POST_PROCESSING.Atmosphere
EnvironmentConfig.ColorCorrection = EnvironmentConfig.POST_PROCESSING.ColorCorrection
EnvironmentConfig.Bloom = EnvironmentConfig.POST_PROCESSING.Bloom
EnvironmentConfig.SunRays = EnvironmentConfig.POST_PROCESSING.SunRays
EnvironmentConfig.DepthOfField = EnvironmentConfig.POST_PROCESSING.DepthOfField

return EnvironmentConfig
