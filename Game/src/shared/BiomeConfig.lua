--!strict
--[[
    BiomeConfig.lua
    Master Biome & Asset-Driven Ecological Configuration
    for "Don't Let the Fire Die" (Fluenosity Studio).
    
    World Generation V4 (Realistic Human-Scale Edition):
    - Absolute Target Heights in Studs:
      * Mature Redwoods & Beechwoods: 17..24 studs (majestic yet believable, player is 5 studs)
      * Mid-Canopy Maples & Broadleafs: 13..18 studs
      * Understory Dogwood & Saplings: 6..12 studs
      * Large Boulders: 4..6.5 studs
    - Biomes:
      * CampsiteSanctuary (Region A): South camp clearing, safe, zero tree obstacles.
      * DenseConifer (Region B): Redwood canopy, fallen logs, ferns, falling leaf FX.
      * OpenWoodland (Region C): Sunlit glades, broadleaf beechwood, maple, dogwood, clover & wildflowers.
      * RockyHighlands (Region D): Elevated ridges & slopes, large boulders, weathered redwoods, saplings.
      * DampLowlands (Region E): Shaded hollows, mossy boulders, mossy logs, rich ferns.
      * LakeShore (Region F): Alpine lake perimeter, driftwood sticks, small stones, shore foliage.
      * Landmarks (Region G): Village, Watchtower, Trader Silas, Gas Station buffers.
    - Excludes all animated wildlife scripts (Fish, Dragonfly, Butterfly, Hawk).
]]

export type BiomeType = 
    | "CampsiteSanctuary"
    | "DenseConifer"
    | "OpenWoodland"
    | "RockyHighlands"
    | "DampLowlands"
    | "LakeShore"
    | "WatchtowerClearing"
    | "VillageTerrace"
    | "TraderOutpost"
    | "GasStationSalvage"
    | "LakeWater"

local BiomeConfig = {}

-- ---------------------------------------------------------------------------
-- 1. ASSET PACK MANIFEST (Exact authored names from Tree-Pack)
-- ---------------------------------------------------------------------------
BiomeConfig.ASSETS = {
    Trees_Conifer = {
        "RedwoodTreeLarge-Var01",
        "RedwoodTree-Var01",
        "Redwoodtree-LowLOD-Var01",
        "Redwood_Snowy01",
    },
    Trees_Broadleaf = {
        "BeechwoodTreeLarge_Var01",
        "BeechwoodTree_Var01",
        "BeechwoodTree_Var03",
        "MapleLeafTreeVar01",
        "BroadLeafTree_Var01",
        "DogwoodTree_Var01",
    },
    Trees_Sapling = {
        "BeechwoodSapling_Var01",
        "BeechwoodTree_Var02",
    },
    Rocks_Large = {
        "LargeBoulder_Var01",
        "LargeBoulder_Var02",
    },
    Rocks_Medium = {
        "MediumBoulderVar01",
        "MediumMossBoulder01",
    },
    Rocks_Small = {
        "SmallRock01",
        "SmallRockGroupVar02",
        "SmallRockGroupVar03",
        "SmallRockVar04",
    },
    Foliage_Ferns = {
        "FernTallVar01",
        "Fern_Var01",
        "DyingFern01",
    },
    Foliage_Shrubs = {
        "MountainLaurelBush_Var01",
        "RhododendronVar01",
        "RhododendronVar02",
    },
    Foliage_Flowers = {
        "WildFlower01",
        "Wildflower02",
        "WildFlower03",
        "WildFlower04",
    },
    Foliage_GroundPatches = {
        "DenseLeafPatch",
        "CloverPatch",
    },
    Deadwood_Logs = {
        "FallenTree",
        "FallenTreeMossyVar01",
    },
    Deadwood_Stumps = {
        "TreeStump",
    },
    Deadwood_Sticks = {
        "BranchVar01",
        "StickVar01",
        "StickVar03",
        "StickVar04",
        "StickVar05",
        "StickVar06",
    },
    Atmospherics = {
        "ParticleEffect-LeavesFalling01",
    },
}

-- Strictly excluded wildlife models containing active movement scripts
BiomeConfig.EXCLUDED_WILDLIFE = {
    "Butterfly_FlightPath01",
    "Butterfly_FlightPath02",
    "Butterfly_Idle01",
    "Dragonfly_Flight01",
    "Dragonfly_IdleFlight01",
    "Dragonfly_IdleFlight02",
    "Fish_IdleSwim01",
    "Fish_IdleSwim02",
    "Fish_IdleSwim03",
    "Fish_Jump01",
    "Fish_Jump02",
    "Hawk_FlightPath01",
    "Hawk_FlightPath02",
}

-- ---------------------------------------------------------------------------
-- 2. HUB CENTERS & SANCTUARIES
-- ---------------------------------------------------------------------------
BiomeConfig.HUBS = {
    Camp = {
        Center = Vector3.new(0, 0, -430),
        ExclusionRadius = 55.0,
    },
    Watchtower = {
        Center = Vector3.new(0, 0, 0),
        ExclusionRadius = 38.0,
    },
    Village = {
        BoundsMin = Vector2.new(-255, 430),
        BoundsMax = Vector2.new(20, 555),
    },
    Trader = {
        Center = Vector3.new(-403.5, 0, 133),
        ExclusionRadius = 32.0,
    },
    GasStation = {
        Center = Vector3.new(402, 0, 253),
        ExclusionRadius = 38.0,
    },
    Lake = {
        Center = Vector3.new(296, 0, -40),
        RadiusX = 72.0,
        RadiusZ = 92.0,
        ShoreMargin = 38.0,
    },
}

-- ---------------------------------------------------------------------------
-- PRESET & WORLD SNAPSHOT CONFIGURATION SYSTEM
-- Allows switching, rolling back, or moving forward between world versions!
-- ---------------------------------------------------------------------------
BiomeConfig.PRESETS = {
    -- V4 Base: Clean 440-tree distribution with strict central bounds
    V4_Base = {
        Name = "V4_Base (440 Trees, Basin Only)",
        TargetTotalTrees = 440,
        Bounds = { MinX = -415.0, MaxX = 415.0, MinZ = -455.0, MaxZ = 410.0 },
        MaxElevation = 25.0,
        MaxSlopeDeg = 28.0,
        AllowSnowyTrees = false,
        ClusterChanceConifer = 0.30,
        ClusterChanceWoodland = 0.15,
        GladeThresholdConifer = -0.38,
        GladeThresholdWoodland = -0.22,
    },
    
    -- V5 Dense: High-density 690-tree central basin (Saved Snapshot)
    V5_Dense = {
        Name = "V5_Dense (690 Trees, Central Basin)",
        TargetTotalTrees = 690,
        Bounds = { MinX = -415.0, MaxX = 415.0, MinZ = -455.0, MaxZ = 410.0 },
        MaxElevation = 25.0,
        MaxSlopeDeg = 28.0,
        AllowSnowyTrees = false,
        ClusterChanceConifer = 0.45,
        ClusterChanceWoodland = 0.20,
        GladeThresholdConifer = -0.42,
        GladeThresholdWoodland = -0.28,
    },
    
    -- V6 Full Perimeter Dense: 960 trees covering North, South, East, West perimeters + border-only snowy trees
    V6_FullPerimeterDense = {
        Name = "V6_FullPerimeterDense (960 Trees, Full Perimeters & Border Snow Trees)",
        TargetTotalTrees = 960,
        Bounds = { MinX = -490.0, MaxX = 490.0, MinZ = -535.0, MaxZ = 535.0 },
        MaxElevation = 42.0,
        MaxSlopeDeg = 30.0,
        AllowSnowyTrees = true,
        SnowyTreesBorderOnly = true,
        BorderMinRadius = 385.0,
        BorderMinCoord = { X = 380.0, Z_South = -480.0, Z_North = 530.0 },
        BorderMinElevation = 25.0,
        ClusterChanceConifer = 0.48,
        ClusterChanceWoodland = 0.22,
        GladeThresholdConifer = -0.44,
        GladeThresholdWoodland = -0.30,
        TargetGroundCover = 350,
    },
    
    -- V7 Dense Border & Lush Undergrowth: 1320 trees with dense unbroken mountain border wall & 1200 ground undergrowth items
    V7_DenseBorderAndUndergrowth = {
        Name = "V7_DenseBorderAndUndergrowth (1320 Trees, Dense Border Wall & Lush Understory)",
        TargetTotalTrees = 1320,
        Bounds = { MinX = -500.0, MaxX = 500.0, MinZ = -545.0, MaxZ = 545.0 },
        MaxElevation = 45.0,
        MaxSlopeDeg = 32.0,
        AllowSnowyTrees = true,
        SnowyTreesBorderOnly = true,
        BorderMinRadius = 385.0,
        BorderMinCoord = { X = 380.0, Z_South = -480.0, Z_North = 530.0 },
        BorderMinElevation = 25.0,
        BorderWallPassTrees = 280,
        PathShoulderPassTrees = 120,
        ClusterChanceConifer = 0.52,
        ClusterChanceWoodland = 0.28,
        GladeThresholdConifer = -0.48,
        GladeThresholdWoodland = -0.34,
        TargetGroundCover = 1200,
    },
    
    -- V8 World-Edge Forest & Dense Vegetation Layer: 1850 trees extending to world edges + 4500 items 3D grass & dirt layer
    V8_WorldEdgeForestAndVegetationLayer = {
        Name = "V8_WorldEdgeForestAndVegetationLayer (1850 Trees to Edge of World & 4500 Ground Vegetation Layer)",
        TargetTotalTrees = 1850,
        Bounds = { MinX = -720.0, MaxX = 720.0, MinZ = -740.0, MaxZ = 740.0 },
        MaxElevation = 68.0,
        MaxSlopeDeg = 36.0,
        AllowSnowyTrees = true,
        SnowyTreesBorderOnly = true,
        BorderMinRadius = 400.0,
        BorderMinCoord = { X = 380.0, Z_South = -470.0, Z_North = 520.0 },
        BorderMinElevation = 25.0,
        SectorTreesPerZone = 140,
        BorderWallPassTrees = 380,
        PathShoulderPassTrees = 120,
        ClusterChanceConifer = 0.55,
        ClusterChanceWoodland = 0.30,
        GladeThresholdConifer = -0.52,
        GladeThresholdWoodland = -0.38,
        TargetGroundCover = 4500,
    },
}

-- ACTIVE PRESET SWITCH: Set to "V5_Dense", "V6_FullPerimeterDense", "V7_DenseBorderAndUndergrowth" to roll back!
BiomeConfig.ACTIVE_PRESET = "V8_WorldEdgeForestAndVegetationLayer"

function BiomeConfig.GetActivePreset()
    return BiomeConfig.PRESETS[BiomeConfig.ACTIVE_PRESET] or BiomeConfig.PRESETS.V8_WorldEdgeForestAndVegetationLayer
end

-- ---------------------------------------------------------------------------
-- 3. BIOME DEFINITION TABLES (Absolute Realistic Heights in Studs)
-- ---------------------------------------------------------------------------
BiomeConfig.BIOMES = {
    DenseConifer = {
        Name = "Dense Conifer Forest",
        Trees = {
            { Model = "RedwoodTreeLarge-Var01", Weight = 35, ScaleMin = 0.29, ScaleMax = 0.37 },
            { Model = "RedwoodTree-Var01", Weight = 40, ScaleMin = 0.50, ScaleMax = 0.67 },
            { Model = "Redwoodtree-LowLOD-Var01", Weight = 25, ScaleMin = 0.32, ScaleMax = 0.43 },
            { Model = "Redwood_Snowy01", Weight = 18, ScaleMin = 0.28, ScaleMax = 0.38 }, -- Filtered to border-only
            { Model = "DogwoodTree_Var01", Weight = 12, ScaleMin = 0.95, ScaleMax = 1.35 },
        },
        CanopyFallingLeavesChance = 0.28,
        MinTreeDistance = 7.5,
        Rocks = {
            Large = { "LargeBoulder_Var01" },
            Medium = { "MediumBoulderVar01", "MediumMossBoulder01" },
            Small = { "SmallRock01", "SmallRockGroupVar02" },
        },
        GroundCover = {
            Ferns = { "FernTallVar01", "Fern_Var01", "DyingFern01" },
            Shrubs = { "MountainLaurelBush_Var01", "RhododendronVar01" },
            Patches = { "DenseLeafPatch" },
            Deadwood = { "FallenTree", "FallenTreeMossyVar01", "TreeStump" },
            Sticks = { "BranchVar01", "StickVar01", "StickVar03", "StickVar05" },
        },
    },

    OpenWoodland = {
        Name = "Open Sunlit Woodland",
        Trees = {
            { Model = "BeechwoodTreeLarge_Var01", Weight = 25, ScaleMin = 0.44, ScaleMax = 0.58 },
            { Model = "BeechwoodTree_Var01", Weight = 25, ScaleMin = 0.57, ScaleMax = 0.73 },
            { Model = "BeechwoodTree_Var03", Weight = 15, ScaleMin = 0.88, ScaleMax = 1.13 },
            { Model = "MapleLeafTreeVar01", Weight = 15, ScaleMin = 1.39, ScaleMax = 1.76 },
            { Model = "BroadLeafTree_Var01", Weight = 10, ScaleMin = 1.26, ScaleMax = 1.64 },
            { Model = "DogwoodTree_Var01", Weight = 10, ScaleMin = 1.13, ScaleMax = 1.51 },
            { Model = "BeechwoodSapling_Var01", Weight = 10, ScaleMin = 1.13, ScaleMax = 1.58 },
        },
        CanopyFallingLeavesChance = 0.12,
        MinTreeDistance = 11.5,
        Rocks = {
            Large = { "LargeBoulder_Var02" },
            Medium = { "MediumBoulderVar01" },
            Small = { "SmallRock01", "SmallRockGroupVar02", "SmallRockVar04" },
        },
        GroundCover = {
            Ferns = { "Fern_Var01" },
            Shrubs = { "MountainLaurelBush_Var01", "RhododendronVar02" },
            Flowers = { "WildFlower01", "Wildflower02", "WildFlower03", "WildFlower04" },
            Patches = { "CloverPatch", "DenseLeafPatch" },
            Deadwood = { "FallenTree", "TreeStump" },
            Sticks = { "BranchVar01", "StickVar04", "StickVar06" },
        },
    },

    RockyHighlands = {
        Name = "Rocky Highlands & Ridges",
        Trees = {
            { Model = "RedwoodTree-Var01", Weight = 35, ScaleMin = 0.41, ScaleMax = 0.56 },
            { Model = "Redwoodtree-LowLOD-Var01", Weight = 30, ScaleMin = 0.26, ScaleMax = 0.37 },
            { Model = "Redwood_Snowy01", Weight = 35, ScaleMin = 0.28, ScaleMax = 0.38 }, -- Filtered to border-only
            { Model = "BeechwoodSapling_Var01", Weight = 20, ScaleMin = 1.13, ScaleMax = 1.58 },
        },
        CanopyFallingLeavesChance = 0.05,
        MinTreeDistance = 10.0,
        Rocks = {
            Large = { "LargeBoulder_Var01", "LargeBoulder_Var02" },
            Medium = { "MediumBoulderVar01" },
            Small = { "SmallRock01", "SmallRockGroupVar03", "SmallRockVar04" },
        },
        GroundCover = {
            Ferns = { "DyingFern01" },
            Shrubs = { "RhododendronVar01" },
            Patches = {},
            Deadwood = { "TreeStump" },
            Sticks = { "StickVar01", "StickVar05" },
        },
    },

    DampLowlands = {
        Name = "Damp Lowlands & Shaded Hollows",
        Trees = {
            { Model = "RedwoodTree-Var01", Weight = 35, ScaleMin = 0.44, ScaleMax = 0.60 },
            { Model = "DogwoodTree_Var01", Weight = 35, ScaleMin = 1.13, ScaleMax = 1.51 },
            { Model = "BeechwoodTree_Var01", Weight = 30, ScaleMin = 0.54, ScaleMax = 0.69 },
        },
        CanopyFallingLeavesChance = 0.15,
        MinTreeDistance = 9.5,
        Rocks = {
            Large = { "LargeBoulder_Var01" },
            Medium = { "MediumMossBoulder01" },
            Small = { "SmallRockGroupVar02", "SmallRock01" },
        },
        GroundCover = {
            Ferns = { "FernTallVar01", "Fern_Var01" },
            Shrubs = { "MountainLaurelBush_Var01" },
            Patches = { "DenseLeafPatch" },
            Deadwood = { "FallenTreeMossyVar01", "TreeStump" },
            Sticks = { "BranchVar01", "StickVar03", "StickVar04" },
        },
    },

    LakeShore = {
        Name = "Lake Shoreline & Driftwood Margin",
        Trees = {
            { Model = "BroadLeafTree_Var01", Weight = 40, ScaleMin = 1.13, ScaleMax = 1.51 },
            { Model = "DogwoodTree_Var01", Weight = 35, ScaleMin = 1.01, ScaleMax = 1.39 },
            { Model = "BeechwoodSapling_Var01", Weight = 25, ScaleMin = 1.13, ScaleMax = 1.58 },
        },
        CanopyFallingLeavesChance = 0.05,
        MinTreeDistance = 12.0,
        Rocks = {
            Large = {},
            Medium = { "MediumMossBoulder01" },
            Small = { "SmallRock01", "SmallRockGroupVar02", "SmallRockGroupVar03" },
        },
        GroundCover = {
            Ferns = { "Fern_Var01" },
            Shrubs = { "MountainLaurelBush_Var01" },
            Flowers = { "Wildflower02", "WildFlower04" },
            Patches = {},
            Deadwood = { "FallenTreeMossyVar01" },
            Sticks = { "BranchVar01", "StickVar01", "StickVar03", "StickVar04", "StickVar06" },
        },
    },
}

-- ---------------------------------------------------------------------------
-- 4. SPATIAL BIOME EVALUATION
-- ---------------------------------------------------------------------------
function BiomeConfig.GetBiome(x: number, z: number, groundY: number, slopeDeg: number): BiomeType
    -- 1. Check Protected Hubs
    local camp = BiomeConfig.HUBS.Camp
    local dCamp = math.sqrt((x - camp.Center.X)^2 + (z - camp.Center.Z)^2)
    if dCamp < camp.ExclusionRadius then
        return "CampsiteSanctuary"
    end

    local tower = BiomeConfig.HUBS.Watchtower
    local dTower = math.sqrt((x - tower.Center.X)^2 + (z - tower.Center.Z)^2)
    if dTower < tower.ExclusionRadius then
        return "WatchtowerClearing"
    end

    local vMin = BiomeConfig.HUBS.Village.BoundsMin
    local vMax = BiomeConfig.HUBS.Village.BoundsMax
    if x >= vMin.X and x <= vMax.X and z >= vMin.Y and z <= vMax.Y then
        return "VillageTerrace"
    end

    local trader = BiomeConfig.HUBS.Trader
    local dTrader = math.sqrt((x - trader.Center.X)^2 + (z - trader.Center.Z)^2)
    if dTrader < trader.ExclusionRadius then
        return "TraderOutpost"
    end

    local gas = BiomeConfig.HUBS.GasStation
    local dGas = math.sqrt((x - gas.Center.X)^2 + (z - gas.Center.Z)^2)
    if dGas < gas.ExclusionRadius then
        return "GasStationSalvage"
    end

    -- 2. Check Lake & Shoreline
    local lake = BiomeConfig.HUBS.Lake
    local dxL = (x - lake.Center.X) / lake.RadiusX
    local dzL = (z - lake.Center.Z) / lake.RadiusZ
    local dLake = math.sqrt(dxL * dxL + dzL * dzL)
    if dLake < 0.98 then
        return "LakeWater"
    elseif dLake < 1.48 then
        return "LakeShore"
    end

    -- 3. Check Elevation & Slope (Highlands are high ridges, lowlands are shaded hollows)
    if groundY > 24.0 or (slopeDeg > 25.0 and groundY > 14.0) then
        return "RockyHighlands"
    end

    if groundY < 5.0 and slopeDeg < 10.0 then
        return "DampLowlands"
    end

    -- 4. Basin Division (Coherent macro-noise blending between Conifer and Woodland)
    local macroNoise = math.noise(x * 0.004, z * 0.004, 543)
    local bias = (x < 10) and -0.15 or 0.15
    if (macroNoise + bias) < 0.0 then
        return "DenseConifer"
    else
        return "OpenWoodland"
    end
end

return BiomeConfig
