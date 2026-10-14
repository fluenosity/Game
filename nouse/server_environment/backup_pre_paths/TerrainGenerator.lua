-- BACKUP COPY OF TerrainGenerator.lua (Pre-Paths Implementation)
local Workspace = game:GetService("Workspace")
local Terrain = Workspace.Terrain

local envConfigScript = game:GetService("ReplicatedStorage"):WaitForChild("FluenosityShared"):WaitForChild("EnvironmentConfig")
local okConfig, freshConfig = pcall(function() return require(envConfigScript:Clone()) end)
local activeCfg = (okConfig and freshConfig) or require(envConfigScript)

local TerrainGenerator = {}

local function sampleElevation(x: number, z: number): (number, number, number)
    local cfg = activeCfg.TERRAIN or {}
    local seed = activeCfg.SEED or 133742
    
    local distFromCenter = math.sqrt(x * x + z * z)
    local angle = math.atan2(z, x)
    
    local nLarge = math.noise(x * (cfg.LargeScale and cfg.LargeScale.Frequency or 0.007), z * (cfg.LargeScale and cfg.LargeScale.Frequency or 0.007), seed * 0.1)
    local nMed = math.noise(x * (cfg.MediumScale and cfg.MediumScale.Frequency or 0.022), z * (cfg.MediumScale and cfg.MediumScale.Frequency or 0.022), (seed + 101) * 0.1)
    local nSmall = math.noise(x * (cfg.SmallScale and cfg.SmallScale.Frequency or 0.065), z * (cfg.SmallScale and cfg.SmallScale.Frequency or 0.065), (seed + 202) * 0.1)
    
    local baseHeight = cfg.BaseHeight or 0.0
    local basinElevation = baseHeight
        + (nLarge * (cfg.LargeScale and cfg.LargeScale.Amplitude or 7.0))
        + (nMed * (cfg.MediumScale and cfg.MediumScale.Amplitude or 3.5))
        + (nSmall * (cfg.SmallScale and cfg.SmallScale.Amplitude or 1.0))
        
    local campExclusion = activeCfg.CAMP_EXCLUSION_RADIUS or 76.0
    local campBlend = activeCfg.CAMP_BLEND_RADIUS or 96.0
    
    local campWeight = 1.0
    if distFromCenter < campExclusion then
        campWeight = 0.0
    elseif distFromCenter < campBlend then
        local t = (distFromCenter - campExclusion) / (campBlend - campExclusion)
        campWeight = t * t * (3 - 2 * t)
    end
    
    local blendedElevation = baseHeight + ((basinElevation - baseHeight) * campWeight)
    
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

local function sampleSlopeAngle(x: number, z: number, step: number): number
    local hCenter, _, _ = sampleElevation(x, z)
    local hX, _, _ = sampleElevation(x + step, z)
    local hZ, _, _ = sampleElevation(x, z + step)
    local dhX = (hX - hCenter) / step
    local dhZ = (hZ - hCenter) / step
    return math.deg(math.atan(math.sqrt(dhX * dhX + dhZ * dhZ)))
end

local function determineMaterial(x: number, z: number, elevation: number, slopeDeg: number, distCenter: number, mountainFactor: number): Enum.Material
    local mats = (activeCfg.TERRAIN and activeCfg.TERRAIN.Materials) or {}
    local campRadius = activeCfg.CAMP_EXCLUSION_RADIUS or 76.0
    if distCenter < campRadius then return mats.Camp or Enum.Material.Ground end
    if mountainFactor > 0.5 then
        if elevation > 26.0 and slopeDeg > 32.0 then return mats.Slate or Enum.Material.Slate end
        return mats.Rock or Enum.Material.Rock
    end
    if slopeDeg >= (mats.SteepSlopeThreshold or 36.0) then return mats.Rock or Enum.Material.Rock end
    if slopeDeg >= (mats.ModerateSlopeThreshold or 24.0) then return mats.Ground or Enum.Material.Ground end
    local baseH = (activeCfg.TERRAIN and activeCfg.TERRAIN.BaseHeight) or 0.0
    if elevation < (baseH - 2.5) then return mats.Mud or Enum.Material.Mud end
    local soilNoise = math.noise(x * 0.035, z * 0.035, 777)
    local microNoise = math.noise(x * 0.08, z * 0.08, 888)
    local combined = soilNoise + (microNoise * 0.35)
    if combined > 0.28 then return mats.Grass or Enum.Material.Grass
    elseif combined < -0.15 then return mats.Ground or Enum.Material.Ground
    else return mats.LeafyGrass or Enum.Material.LeafyGrass end
end

function TerrainGenerator.Generate(injectedCfg: any?)
    local startTime = os.clock()
    print("[TerrainGenerator] Sculpting organic rolling terrain with multi-material earth...")
    if injectedCfg then activeCfg = injectedCfg
    else local ok, fresh = pcall(function() return require(envConfigScript:Clone()) end) if ok and fresh then activeCfg = fresh end end
    pcall(function() (Terrain :: any).Decoration = true end)
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
