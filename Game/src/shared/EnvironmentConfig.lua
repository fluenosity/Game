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
EnvironmentConfig.RESHAPE_ELEVATION = true

EnvironmentConfig.CONTAINER_NAME = "ForestEnvironment"
EnvironmentConfig.FOLDER_TREES = "Trees"
EnvironmentConfig.FOLDER_ROCKS = "Rocks"
EnvironmentConfig.FOLDER_GROUND_COVER = "GroundCover"

-- ---------------------------------------------------------------------------
-- 2. PROTECTED CAMPSITE EXCLUSION ZONE (School Bus, Fence, Fire, Watchtower)
-- ---------------------------------------------------------------------------
EnvironmentConfig.CAMP_EXCLUSION_RADIUS = 50.0  -- Protected campsite perimeter
EnvironmentConfig.CAMP_BLEND_RADIUS = 56.0      -- Smooth rolling elevation transition into deep forest

-- ---------------------------------------------------------------------------
-- 2B. WOODLAND TRAILS & EXPLORATION PATHWAYS (Production-Grade & Reversible)
-- ---------------------------------------------------------------------------
-- Set ENABLE_PATHS = false to INSTANTLY revert to 100% pathless dense forest!
EnvironmentConfig.ENABLE_PATHS = true

EnvironmentConfig.PATHS = {
    DefaultPathWidth = 10.0,    -- 10 studs wide: ample space for 2 players sprinting side-by-side
    BlendMargin = 3.5,         -- Feathered natural earth blending at trail edges
    TreeClearance = 2.5,       -- Distance from path edge where tree trunks can spawn
    RockClearance = 1.5,       -- Keeps boulders from obstructing running corridors
    GroundCoverClearance = 0.5,-- Keeps logs and snags off the trail
    
    -- Organic Meander Settings (Transforms straight lines into natural winding trails)
    MeanderAmplitude = 18.0,   -- Lateral curve deflection (studs)
    MeanderWavelength = 46.0,  -- Distance along path for a full serpentine S-curve
    BuildClearingRadius = 15.0,-- Building space radius at the end of every trail (30-stud open circle)
    
    Definitions = {
        -- 1. North Path -> Watchtower Outpost ("Items")
        {
            Id = "WatchtowerNorth",
            Name = "Watchtower Outpost Trail",
            Waypoints = {
                Vector2.new(0, -45),
                Vector2.new(38, -80),
                Vector2.new(-32, -125),
                Vector2.new(-15, -165),
            },
            ClearingCenter = Vector2.new(-15, -165),
            ClearingRadius = 16.0,
            MeanderPhase = 0.0,
            SeedOffset = 101,
        },
        
        -- 2. Northwest Path -> Wilderness Cache ("Items")
        {
            Id = "NorthwestItems",
            Name = "Northwest Cache Trail",
            Waypoints = {
                Vector2.new(-38, -35),
                Vector2.new(-92, -48),
                Vector2.new(-68, -112),
                Vector2.new(-138, -115),
                Vector2.new(-160, -155),
            },
            ClearingCenter = Vector2.new(-160, -155),
            ClearingRadius = 15.0,
            MeanderPhase = 1.2,
            SeedOffset = 202,
        },
        
        -- 3. West Path -> Mountain Wall ("Nothing")
        {
            Id = "WestTrail",
            Name = "West Exploration Trail",
            Waypoints = {
                Vector2.new(-48, 5),
                Vector2.new(-88, 42),
                Vector2.new(-135, -22),
                Vector2.new(-180, 15),
            },
            ClearingCenter = Vector2.new(-180, 15),
            ClearingRadius = 15.0,
            MeanderPhase = 2.4,
            SeedOffset = 303,
        },
        
        -- 4. South-Southwest Path -> Day 1 Wood Glade ("Day 1 / Wood")
        {
            Id = "Day1Wood",
            Name = "Day 1 Wood Gathering Trail",
            Waypoints = {
                Vector2.new(-18, 52),
                Vector2.new(-68, 85),
                Vector2.new(-25, 135),
                Vector2.new(-75, 185),
            },
            ClearingCenter = Vector2.new(-75, 185),
            ClearingRadius = 18.0, -- Wood gathering clearing
            MeanderPhase = 0.7,
            SeedOffset = 404,
        },
        
        -- 5. Southeast Path -> Trader Compound ("Trader")
        {
            Id = "TraderTrail",
            Name = "Southeast Trader Trail",
            Waypoints = {
                Vector2.new(38, 38),
                Vector2.new(95, 48),
                Vector2.new(100, 108),
                Vector2.new(145, 138),
            },
            ClearingCenter = Vector2.new(145, 138),
            ClearingRadius = 18.0, -- Trader campsite clearing
            MeanderPhase = 1.9,
            SeedOffset = 505,
        },
        
        -- 6. Northeast Path -> Outer Ridge ("Nothing")
        {
            Id = "NortheastTrail",
            Name = "Northeast Ridge Trail",
            Waypoints = {
                Vector2.new(42, -28),
                Vector2.new(75, -78),
                Vector2.new(138, -68),
                Vector2.new(165, -135),
            },
            ClearingCenter = Vector2.new(165, -135),
            ClearingRadius = 15.0,
            MeanderPhase = 3.1,
            SeedOffset = 606,
        },
    },
}

-- ---------------------------------------------------------------------------
-- 3. VOXEL TERRAIN CONFIGURATION (Organic Elevation & Realistic Earth Blending)
-- ---------------------------------------------------------------------------
EnvironmentConfig.TERRAIN = {
    BaseHeight = 0.0,
    VoxelResolution = 4,
    
    -- Basin Undulation: Rolling mounds & shallow hollows
    LargeScale = {
        Frequency = 0.007,
        Amplitude = 7.0,       -- Rolling terrain swales
    },
    MediumScale = {
        Frequency = 0.022,
        Amplitude = 3.5,       -- Natural mounds and knolls
    },
    SmallScale = {
        Frequency = 0.065,
        Amplitude = 1.0,       -- Surface micro-variation
    },
    
    -- Organic Non-Circular Perimeter Mountain Barrier
    Boundary = {
        BaseRadius = 195.0,
        RadialNoiseAmp = 38.0, -- Warps mountain ridges organically
        TransitionWidth = 45.0,
        PeakHeight = 44.0,
    },
    
    -- Multi-Material Wilderness Blending (Shuts down the uniform carpet look!)
    Materials = {
        Camp = Enum.Material.Ground,             -- Worn packed soil inside camp
        CampVerge = Enum.Material.Ground,        -- Worn transition soil outside camp
        LeafyGrass = Enum.Material.LeafyGrass,   -- Dark pine needle mulch & decomposing forest litter
        Ground = Enum.Material.Ground,           -- Rich dark exposed forest soil
        Grass = Enum.Material.Grass,             -- 3D blade grass in sunny glades & knoll tops
        Mud = Enum.Material.Mud,                 -- Damp hollows, shaded ruts & moist depressions
        Rock = Enum.Material.Rock,               -- Steep rocky faces, embedded boulders
        Slate = Enum.Material.Slate,             -- High mountain crags & sheer cliff faces
        Basalt = Enum.Material.Basalt,           -- Dark weathered volcanic stone
        Cobblestone = Enum.Material.Cobblestone, -- Trodden trail gravel & embedded stones
        
        SteepSlopeThreshold = 34.0,              -- Slopes >= 34° transition to rock
        ModerateSlopeThreshold = 22.0,           -- Slopes >= 22° show rocky soil
        RockCliffThreshold = 42.0,               -- Slopes >= 42° become sheer slate/rock
        AlpineSoilMaxSlope = 24.0,               -- Mountain ridges below 24° retain alpine pine/soil
    },
    
    -- Organic Forest Floor Material Blending Parameters
    Blending = {
        MacroFrequency = 0.012,                  -- Broad ecological soil vs mulch biomes
        PatchFrequency = 0.038,                  -- Organic 10-25 stud material patches
        MicroFrequency = 0.088,                  -- Pebbles, moss margins & damp depression noise
        
        -- Target base material distribution in forest floor:
        -- LeafyGrass: ~42%, Ground: ~36%, Grass: ~14%, Mud: ~5%, Rock: ~3%
        LeafyGrassMulchBias = 0.06,
        ExposedSoilBias = -0.08,
        SunlitGrassThreshold = 0.30,
        DampMudThreshold = -0.32,
        GravelThreshold = 0.38,
        
        -- Campsite perimeter transition zone (Areas A, B, C, D, E)
        CampCoreRadius = 48.0,                   -- Flat sanctuary core
        CampVergeRadius = 66.0,                  -- Feathered transition radius
        CampOuterBlend = 80.0,                   -- Full merge into deep forest
    },
    
    -- Authentic AAA Forest Earth Palette Shaders (Banishes the neon/lime lawn look!)
    MaterialColors = {
        [Enum.Material.Grass] = Color3.fromRGB(64, 82, 52),       -- Muted deep conifer green
        [Enum.Material.LeafyGrass] = Color3.fromRGB(56, 62, 42),  -- Dark needle mulch & decaying pine litter
        [Enum.Material.Ground] = Color3.fromRGB(76, 58, 44),      -- Rich dark damp earth & trodden path loam
        [Enum.Material.Mud] = Color3.fromRGB(52, 42, 34),         -- Dark moist woodland hollows
        [Enum.Material.Rock] = Color3.fromRGB(86, 84, 82),        -- Weathered granite grey
        [Enum.Material.Slate] = Color3.fromRGB(68, 70, 72),       -- Mountain cliff face slate
        [Enum.Material.Basalt] = Color3.fromRGB(54, 52, 50),      -- Volcanic dark stone
        [Enum.Material.Cobblestone] = Color3.fromRGB(82, 78, 72), -- Worn trail stones
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
-- 7. LIGHTING & ATMOSPHERE
-- ---------------------------------------------------------------------------
EnvironmentConfig.POST_PROCESSING = {
    EnableFutureLighting = true,
    EnableTerrainDecoration = true,
    
    Lighting = {
        Brightness = 2.4,
        Ambient = Color3.fromRGB(82, 86, 94),
        OutdoorAmbient = Color3.fromRGB(96, 102, 110),
        ShadowSoftness = 0.35,
        ClockTime = 10.5,
        GeographicLatitude = 48.0,
    },
    
    Atmosphere = {
        Density = 0.36,
        Offset = 0.12,
        Color = Color3.fromRGB(160, 185, 205),
        Decay = Color3.fromRGB(95, 120, 145),
        Glare = 0.15,
        Haze = 2.4,
    },
    
    ColorCorrection = {
        Brightness = 0.03,
        Contrast = 0.05,
        Saturation = 0.02,
        TintColor = Color3.fromRGB(246, 244, 240),
    },
    
    Bloom = {
        Intensity = 0.55,
        Size = 16,
        Threshold = 0.90,
    },
    
    SunRays = {
        Intensity = 0.18,
        Spread = 0.76,
    },
    
    DepthOfField = {
        FarIntensity = 0.28,
        FocusDistance = 50.0,
        InFocusRadius = 75.0,
        NearIntensity = 0.0,
    },
}

-- Top-level backward-compatible aliases (prevents attempt to index nil with 'Brightness' on older script versions)
EnvironmentConfig.Lighting = EnvironmentConfig.POST_PROCESSING.Lighting
EnvironmentConfig.Atmosphere = EnvironmentConfig.POST_PROCESSING.Atmosphere
EnvironmentConfig.ColorCorrection = EnvironmentConfig.POST_PROCESSING.ColorCorrection
EnvironmentConfig.Bloom = EnvironmentConfig.POST_PROCESSING.Bloom
EnvironmentConfig.SunRays = EnvironmentConfig.POST_PROCESSING.SunRays
EnvironmentConfig.DepthOfField = EnvironmentConfig.POST_PROCESSING.DepthOfField

return EnvironmentConfig
