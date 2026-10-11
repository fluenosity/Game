--!strict
--[[
    TerrainGenerator.lua
    Procedural organic elevation and realistic multi-material earth terrain generation.
    Developed for "Don't Let the Fire Die" (Fluenosity Studio).
    
    Features:
    - Non-Circular Mountain Ridges (No artificial circular ring walls)
    - Natural Rolling Basin: Gentle knolls, swales, and shallow forest depressions
    - Realistic Earth Surface Blending: Shatters the "carpet" look by organically blending
      LeafyGrass (pine needle mulch), Ground (rich soil), Grass (3D blades), and Mud
    - Protected Camp Compound: 58-stud flat sanctuary preserving bus, campfire, and fence
]]

local Workspace = game:GetService("Workspace")
local Terrain = Workspace.Terrain

local envConfigScript = game:GetService("ReplicatedStorage"):WaitForChild("FluenosityShared"):WaitForChild("EnvironmentConfig")
local okConfig, freshConfig = pcall(function() return require(envConfigScript:Clone()) end)
local activeCfg = (okConfig and freshConfig) or require(envConfigScript)

local envFolder = script.Parent or game:GetService("ServerScriptService"):WaitForChild("FluenosityServer"):WaitForChild("Environment")
local PathSystem = require(envFolder:WaitForChild("PathSystem"))

local TerrainGenerator = {}

-- ---------------------------------------------------------------------------
-- ORGANIC ELEVATION & PERIMETER RIDGES
-- ---------------------------------------------------------------------------

local function sampleElevation(x: number, z: number): (number, number, number)
    local cfg = activeCfg.TERRAIN or {}
    local seed = activeCfg.SEED or 133742
    
    local distFromCenter = math.sqrt(x * x + z * z)
    local angle = math.atan2(z, x)
    
    -- 1. Multi-scale Perlin Noise for natural rolling mounds & hollows
    local nLarge = math.noise(x * (cfg.LargeScale and cfg.LargeScale.Frequency or 0.007), z * (cfg.LargeScale and cfg.LargeScale.Frequency or 0.007), seed * 0.1)
    local nMed = math.noise(x * (cfg.MediumScale and cfg.MediumScale.Frequency or 0.022), z * (cfg.MediumScale and cfg.MediumScale.Frequency or 0.022), (seed + 101) * 0.1)
    local nSmall = math.noise(x * (cfg.SmallScale and cfg.SmallScale.Frequency or 0.065), z * (cfg.SmallScale and cfg.SmallScale.Frequency or 0.065), (seed + 202) * 0.1)
    
    local baseHeight = cfg.BaseHeight or 0.0
    local basinElevation = baseHeight
        + (nLarge * (cfg.LargeScale and cfg.LargeScale.Amplitude or 7.0))
        + (nMed * (cfg.MediumScale and cfg.MediumScale.Amplitude or 3.5))
        + (nSmall * (cfg.SmallScale and cfg.SmallScale.Amplitude or 1.0))
        
    -- 2. Camp Exclusion Zone Smoothing (S-curve blend)
    local campExclusion = activeCfg.CAMP_EXCLUSION_RADIUS or 76.0
    local campBlend = activeCfg.CAMP_BLEND_RADIUS or 96.0
    
    local campWeight = 1.0
    if distFromCenter < campExclusion then
        campWeight = 0.0
    elseif distFromCenter < campBlend then
        local t = (distFromCenter - campExclusion) / (campBlend - campExclusion)
        campWeight = t * t * (3 - 2 * t) -- Smooth cubic hermite curve
    end
    
    local blendedElevation = baseHeight + ((basinElevation - baseHeight) * campWeight)
    
    -- 3. Non-Circular Organic Perimeter Mountain Barrier
    local bCfg = cfg.Boundary
    local radialNoise = math.noise(math.cos(angle) * 1.6, math.sin(angle) * 1.6, seed * 0.3)
    local effectiveInnerRadius = bCfg.BaseRadius + (radialNoise * bCfg.RadialNoiseAmp)
    local effectiveOuterRadius = effectiveInnerRadius + bCfg.TransitionWidth
    
    local mountainFactor = 0.0
    if distFromCenter > effectiveInnerRadius then
        local tWall = math.clamp((distFromCenter - effectiveInnerRadius) / (effectiveOuterRadius - effectiveInnerRadius), 0, 1)
        mountainFactor = tWall * tWall
        
        local cragNoise = math.noise(x * 0.016, z * 0.016, (seed + 333) * 0.1) * 10.0
        blendedElevation = blendedElevation + (mountainFactor * bCfg.PeakHeight) + (cragNoise * mountainFactor)
    end
    
    return blendedElevation, distFromCenter, mountainFactor
end

-- ---------------------------------------------------------------------------
-- SLOPE CALCULATION
-- ---------------------------------------------------------------------------
local function sampleSlopeAngle(x: number, z: number, step: number): number
    local hCenter, _, _ = sampleElevation(x, z)
    local hX, _, _ = sampleElevation(x + step, z)
    local hZ, _, _ = sampleElevation(x, z + step)
    
    local dhX = (hX - hCenter) / step
    local dhZ = (hZ - hCenter) / step
    local slopeGrad = math.sqrt(dhX * dhX + dhZ * dhZ)
    return math.deg(math.atan(slopeGrad))
end

-- ---------------------------------------------------------------------------
-- REALISTIC EARTH MATERIAL MAPPING (Breaks the "carpet" look!)
-- ---------------------------------------------------------------------------
-- ---------------------------------------------------------------------------
-- REALISTIC EARTH MATERIAL MAPPING V3 (Eliminates carpet & grey perimeter!)
-- ---------------------------------------------------------------------------
local function determineMaterial(
    x: number,
    z: number,
    elevation: number,
    slopeDeg: number,
    distCenter: number,
    mountainFactor: number
): Enum.Material
    local mats = (activeCfg.TERRAIN and activeCfg.TERRAIN.Materials) or {}
    local blendCfg = (activeCfg.TERRAIN and activeCfg.TERRAIN.Blending) or {}
    local seed = activeCfg.SEED or 133742
    
    local campCore = blendCfg.CampCoreRadius or 46.0
    local campVerge = blendCfg.CampVergeRadius or 66.0
    local campOuter = blendCfg.CampOuterBlend or 80.0
    
    -- 1. CAMPSITE INTERIOR: Worn, compacted sanctuary earth
    if distCenter < campCore then
        return mats.Camp or Enum.Material.Ground
    end
    
    -- 1B. CAMPSITE PERIMETER TRANSITION (Areas A, B, C, D, E)
    -- Naturally feathers worn soil into the forest floor; no sharp circular cutoffs!
    if distCenter < campOuter then
        local angle = math.atan2(z, x)
        local vergeNoise = math.noise(x * 0.055, z * 0.055, seed * 0.1 + 808)
        local radialWobble = vergeNoise * 8.0
        local effectiveVerge = campVerge + radialWobble
        
        -- Area B: Broken Gate Approach (North/Northwest towards paths - Circled Top Right)
        -- Intense foot traffic extends worn earth and path gravel outwards
        local isGateSector = (angle > -2.4 and angle < -1.0)
        if isGateSector and distCenter < (campVerge + 10.0) then
            local gatePebbleNoise = math.noise(x * 0.12, z * 0.12, 112)
            if gatePebbleNoise > 0.35 then
                return mats.Cobblestone or mats.Rock or Enum.Material.Rock
            else
                return mats.Ground or Enum.Material.Ground
            end
        end
        
        -- Area E: Foreground Outside Front Fence (South Exterior - Circled Bottom)
        -- Rich multi-material mix: real 3D grass clumps, dark exposed earth, embedded stones, needle mulch
        local isForegroundSector = (z > 28.0)
        if isForegroundSector and distCenter < (campOuter - 2.0) then
            local fgStoneNoise = math.noise(x * 0.11, z * 0.11, seed * 0.1 + 101)
            local fgGrassNoise = math.noise(x * 0.055, z * 0.055, seed * 0.1 + 202)
            if fgStoneNoise > 0.42 then
                return mats.Rock or mats.Cobblestone or Enum.Material.Rock -- Embedded stones along ledge
            elseif fgGrassNoise > 0.05 then
                return mats.Grass or Enum.Material.Grass -- Real 3D wild grass tufts
            elseif fgGrassNoise < -0.18 then
                return mats.Ground or Enum.Material.Ground -- Rich dark exposed soil
            else
                return mats.LeafyGrass or Enum.Material.LeafyGrass -- Pine needle mulch
            end
        end
        
        -- Area A: Behind Rear Fence (North Exterior - Circled Top Center)
        -- Deep shadowed forest undergrowth: real 3D grass, dark needle mulch, damp earth, rich soil
        local isRearSector = (z < -30.0)
        if isRearSector and distCenter < effectiveVerge then
            local rearNoise = math.noise(x * 0.045, z * 0.045, seed * 0.1 + 303)
            if rearNoise > 0.02 then
                return mats.Grass or Enum.Material.Grass -- Real 3D wild grass along rear fence
            elseif rearNoise < -0.22 then
                return mats.Mud or Enum.Material.Mud -- Damp shaded depression
            else
                return mats.LeafyGrass or Enum.Material.LeafyGrass -- Dark pine needle mulch
            end
        end
        
        -- Area D & General Verge: Feathered soil, mulch, and damp earth around fence lines
        if distCenter < effectiveVerge then
            local vergeBlendNoise = math.noise(x * 0.04, z * 0.04, seed * 0.1 + 909)
            if vergeBlendNoise > 0.15 then
                return mats.LeafyGrass or Enum.Material.LeafyGrass
            elseif vergeBlendNoise < -0.25 then
                return mats.Mud or Enum.Material.Mud
            else
                return mats.Ground or Enum.Material.Ground
            end
        end
    end
    
    -- 2. WOODLAND TRAILS & CORRIDORS (Dirt trail way with organic edges)
    local pathWeight = PathSystem.GetPathTerrainWeight(x, z, activeCfg)
    if pathWeight > 0.25 then
        local trailNoise = math.noise(x * 0.08, z * 0.08, 444)
        if pathWeight > 0.65 then
            -- Trail core: Compacted worn walking dirt with embedded pebbles or damp ruts
            if trailNoise > 0.38 then
                return mats.Cobblestone or mats.Rock or Enum.Material.Rock
            elseif trailNoise < -0.36 then
                return mats.Mud or Enum.Material.Mud
            else
                return mats.Ground or Enum.Material.Ground
            end
        else
            -- Trail verge: Feathered transition between path soil and forest floor
            if trailNoise > 0.10 then
                return mats.Ground or Enum.Material.Ground
            else
                return mats.LeafyGrass or Enum.Material.LeafyGrass
            end
        end
    end
    
    -- 3. SLOPE & MOUNTAIN RIDGE MATERIAL MAPPING
    -- Solves the "stark grey perimeter ring" by anchoring rock to actual slope & crag noise,
    -- allowing gentle mountain slopes to retain pine mulch and alpine soil!
    local steepThreshold = mats.SteepSlopeThreshold or 34.0
    local moderateThreshold = mats.ModerateSlopeThreshold or 22.0
    local cliffThreshold = mats.RockCliffThreshold or 42.0
    
    if slopeDeg >= cliffThreshold then
        -- Sheer vertical rock faces
        if elevation > 28.0 then
            return mats.Slate or Enum.Material.Slate
        end
        return mats.Rock or Enum.Material.Rock
    elseif slopeDeg >= steepThreshold then
        -- Steep slopes: exposed weathered rock and crags
        local cragNoise = math.noise(x * 0.03, z * 0.03, seed * 0.1 + 333)
        if cragNoise > -0.15 or mountainFactor > 0.4 then
            return mats.Rock or Enum.Material.Rock
        else
            return mats.Ground or Enum.Material.Ground
        end
    elseif slopeDeg >= moderateThreshold and mountainFactor > 0.55 then
        -- Moderate mountain slopes: blend between rocky ground and exposed rock
        local slopeNoise = math.noise(x * 0.045, z * 0.045, seed * 0.1 + 444)
        if slopeNoise > 0.18 then
            return mats.Rock or Enum.Material.Rock
        else
            return mats.Ground or Enum.Material.Ground
        end
    end
    
    -- 4. DAMP DEPRESSIONS & SHADED HOLLOWS
    local baseH = (activeCfg.TERRAIN and activeCfg.TERRAIN.BaseHeight) or 0.0
    if elevation < (baseH - 2.2) then
        return mats.Mud or Enum.Material.Mud
    end
    
    -- 5. NATURAL FOREST FLOOR MULTI-MATERIAL PATCHWORK (AAA Image 3 standard)
    -- Balanced mixture: LeafyGrass (~42%), Ground (~36%), Grass (~14%), Mud (~5%), Rock (~3%)
    local macroNoise = math.noise(x * 0.012, z * 0.012, seed * 0.1 + 555)  -- Broad soil vs mulch biomes
    local patchNoise = math.noise(x * 0.038, z * 0.038, seed * 0.1 + 666)  -- 10-25 stud organic patches
    local microNoise = math.noise(x * 0.09, z * 0.09, seed * 0.1 + 777)    -- Micro stones / damp spots
    
    local composite = (patchNoise * 0.65) + (macroNoise * 0.35)
    
    -- Micro damp earth pockets in low ground
    if microNoise < -0.38 and elevation < (baseH + 1.2) then
        return mats.Mud or Enum.Material.Mud
    end
    
    -- Micro gravel and embedded forest pebbles on terrain swells
    if microNoise > 0.42 and elevation > (baseH + 1.0) then
        return mats.Rock or Enum.Material.Rock
    end
    
    -- Natural patchwork between real 3D grass, rich exposed earth, and pine needle mulch
    if composite > 0.12 and elevation >= (baseH - 0.5) then
        -- Natural clusters of real 3D grass blades
        return mats.Grass or Enum.Material.Grass
    elseif composite < -0.08 then
        -- Rich exposed forest loam & trodden clearings (Shuts down the green carpet!)
        return mats.Ground or Enum.Material.Ground
    else
        -- Deep forest floor pine needle mulch (Authentic decomposing wilderness base)
        return mats.LeafyGrass or Enum.Material.LeafyGrass
    end
end

-- ---------------------------------------------------------------------------
-- PUBLIC EXECUTION API
-- ---------------------------------------------------------------------------
function TerrainGenerator.Generate(injectedCfg: any?, injectedPathSystem: any?)
    local startTime = os.clock()
    print("[TerrainGenerator] Sculpting organic rolling terrain with multi-material earth...")
    
    if injectedPathSystem then
        PathSystem = injectedPathSystem
    end
    
    if injectedCfg then
        activeCfg = injectedCfg
    else
        local ok, fresh = pcall(function() return require(envConfigScript:Clone()) end)
        if ok and fresh then activeCfg = fresh end
    end
    
    pcall(function()
        (Terrain :: any).Decoration = true
    end)
    
    -- Apply authentic AAA forest earth palette to terrain shaders (Removes bright lime lawn!)
    local matColors = (activeCfg.TERRAIN and activeCfg.TERRAIN.MaterialColors)
    if matColors then
        for matEnum, color in pairs(matColors) do
            pcall(function()
                Terrain:SetMaterialColor(matEnum, color)
            end)
        end
    end
    
    if not activeCfg.RESHAPE_ELEVATION then
        print("[TerrainGenerator] RESHAPE_ELEVATION is false. Keeping current elevation.")
        return
    end
    
    local worldSize = activeCfg.WORLD_SIZE or Vector2.new(500, 500)
    local halfX = worldSize.X / 2
    local halfZ = worldSize.Y / 2
    local step = (activeCfg.TERRAIN and activeCfg.TERRAIN.VoxelResolution) or 4
    local depthBelow = 28.0
    
    for x = -halfX, halfX, step do
        for z = -halfZ, halfZ, step do
            local elevation, distCenter, mountainFactor = sampleElevation(x, z)
            local slope = sampleSlopeAngle(x, z, step)
            local mat = determineMaterial(x, z, elevation, slope, distCenter, mountainFactor)
            
            local totalHeight = elevation - (-depthBelow)
            if totalHeight > 0.5 then
                local centerPos = Vector3.new(x, (-depthBelow + elevation) / 2, z)
                local size = Vector3.new(step, totalHeight, step)
                
                Terrain:FillBlock(CFrame.new(centerPos), size, mat)
            end
        end
    end
    
    local elapsed = math.round((os.clock() - startTime) * 100) / 100
    print(string.format("[TerrainGenerator] Completed organic earth terrain generation in %.2f seconds.", elapsed))
end

function TerrainGenerator.GetElevationAt(x: number, z: number): (number, number, number)
    return sampleElevation(x, z)
end

function TerrainGenerator.GetSlopeAt(x: number, z: number): number
    return sampleSlopeAngle(x, z, 4.0)
end

return TerrainGenerator
