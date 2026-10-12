--!strict
--[[
    TerrainGenerator.lua
    Procedural organic elevation and realistic multi-scale earth terrain generation.
    Developed for "Don't Let the Fire Die" (Fluenosity Studio).
    
    TERRAIN SCULPTING V3:
    1. Multi-Scale Elevation Hierarchy:
       - Scale A: Small ground bumps (0.95 studs micro-relief across clearings)
       - Scale B: Small rolling hills (2.8 studs low rounded hills & undulating slopes)
       - Scale C: Medium raised areas (5.4 studs broad elevated woodland rises & ridges)
       - Scale D: Lowlands & shallow valleys (3.0 studs meandering drainage swales)
       - Scale E: Landscape rhythm modulation (0.60 calm glades to 1.30 rolling ridges)
       - Domain Warping: Organically curved contours, zero grid artifacts.
    2. Protected Landmark Safeguards:
       - Campsite Sanctuary: Strictly flat at Y=3.85 (r <= 30), smooth S-curve blend to r=65
       - Alpine East Lake: Bed & water preserved 100%, seamless shoreline blend (d_lake = 0.90 to 1.35)
       - Mountain Foothills: Seamless blend into existing perimeter barrier (r >= 400 to 500)
    3. Realistic Earth Vegetation Clustering Engine (Eliminates Camouflage Look):
       - Zero artificial circle cutoffs or threshold steps: continuous S-curve blend
       - Continuous vegetation density function with natural cluster dithering
       - Dense grass on sunny knolls, sparse grass & clusters over needle mulch,
         exposed earth on trails & clearings, dark loam in moist hollows
       - Harmonized earth shader color palette
    4. Deterministic Chunked Voxel Writing with SDF continuous dual-contouring occupancies
]]

local Workspace = game:GetService("Workspace")
local Terrain = Workspace.Terrain

local envConfigScript = game:GetService("ReplicatedStorage"):WaitForChild("FluenosityShared"):WaitForChild("EnvironmentConfig")
local okConfig, freshConfig = pcall(function() return require(envConfigScript:Clone()) end)
local activeCfg = (okConfig and freshConfig) or require(envConfigScript)

local envFolder = (script.Parent and script.Parent.Name == "Environment" and script.Parent)
    or game:GetService("ServerScriptService"):WaitForChild("FluenosityServer"):WaitForChild("Environment")
local PathSystem = require(envFolder:WaitForChild("PathSystem"))

local TerrainGenerator = {}

-- ---------------------------------------------------------------------------
-- MULTI-SCALE ORGANIC ELEVATION HIERARCHY
-- ---------------------------------------------------------------------------

local function sampleElevation(x: number, z: number): (number, number, number)
    local cfg = activeCfg.TERRAIN or {}
    local seed = activeCfg.SEED or 133742
    
    local distFromCenter = math.sqrt(x * x + z * z)
    
    -- 0. Organic Domain Warping (Curves and meanders landforms organically)
    local warpCfg = cfg.DomainWarp or { Frequency = 0.004, Strength = 32.0 }
    local wFreq = warpCfg.Frequency or 0.004
    local wStr = warpCfg.Strength or 32.0
    local warpX = math.noise(x * wFreq, z * wFreq, (seed + 77) * 0.1) * wStr
    local warpZ = math.noise((x + 123) * wFreq, (z - 231) * wFreq, (seed + 88) * 0.1) * wStr
    local wx = x + warpX
    local wz = z + warpZ
    
    -- 1. Multi-Scale Elevation Hierarchy
    -- A. Small Ground Bumps (Noticeable rounded micro-relief across open ground)
    local bumpCfg = cfg.SmallBumps or { Frequency = 0.065, Amplitude = 1.6 }
    local bFreq = bumpCfg.Frequency or 0.065
    local bAmp = bumpCfg.Amplitude or 1.6
    local nBump1 = math.noise(wx * bFreq, wz * bFreq, (seed + 11) * 0.1) / 0.45
    local nBump2 = math.noise(wx * (bFreq * 1.6) + 33, wz * (bFreq * 1.6) - 44, (seed + 22) * 0.1) / 0.45
    local hBumps = math.clamp((nBump1 * 0.7 + nBump2 * 0.3), -1, 1) * bAmp
    
    -- B. Small Rolling Hills (Local knolls, undulating slopes & shoulders)
    local hillCfg = cfg.RollingHills or { Frequency = 0.018, Amplitude = 4.2, ShoulderFrequency = 0.028, ShoulderAmplitude = 2.4 }
    local hFreq = hillCfg.Frequency or 0.018
    local hAmp = hillCfg.Amplitude or 4.2
    local sFreq = hillCfg.ShoulderFrequency or 0.028
    local sAmp = hillCfg.ShoulderAmplitude or 2.4
    local nHill = math.noise(wx * hFreq, wz * hFreq, (seed + 33) * 0.1) / 0.45
    local nShoulder = math.noise((wx + 45) * sFreq, (wz - 67) * sFreq, (seed + 44) * 0.1) / 0.45
    local hRolling = (math.clamp(nHill, -1, 1) * hAmp) + (math.clamp(nShoulder, -1, 1) * sAmp)
    
    -- C. Medium Raised Areas (Elevated conifer ridges & prominent woodland mounds: Y reaching 17-20)
    local riseCfg = cfg.MediumRises or { Frequency = 0.009, Amplitude = 9.0 }
    local rFreq = riseCfg.Frequency or 0.009
    local rAmp = riseCfg.Amplitude or 9.0
    local nRise = math.noise(wx * rFreq, wz * rFreq, (seed + 55) * 0.1) / 0.45
    local hMedium = 0
    if nRise > 0 then
        local tRise = math.clamp(nRise, 0, 1)
        hMedium = (tRise * tRise * (3 - 2 * tRise)) * rAmp
    end
    
    -- D. Lowlands and Shallow Valleys (Natural meandering drainage swales)
    local lowCfg = cfg.Lowlands or { Frequency = 0.007, Depth = 2.8 }
    local lFreq = lowCfg.Frequency or 0.007
    local lDepth = lowCfg.Depth or 2.8
    local nLow = math.noise(wx * lFreq, wz * lFreq, (seed + 66) * 0.1) / 0.45
    local hLowland = 0
    if nLow < 0 then
        local tLow = math.clamp(-nLow, 0, 1)
        hLowland = -(tLow * tLow * (3 - 2 * tLow)) * lDepth
    end
    
    -- E. Landscape Rhythm Modulation (Alternates between calm clearings & rolling woodland)
    local modCfg = cfg.ReliefModulation or { Frequency = 0.0035, MinFactor = 0.75, MaxFactor = 1.25 }
    local mFreq = modCfg.Frequency or 0.0035
    local minF = modCfg.MinFactor or 0.75
    local maxF = modCfg.MaxFactor or 1.25
    local nMod = math.clamp((math.noise(wx * mFreq, wz * mFreq, (seed + 99) * 0.1) / 0.45 + 1) * 0.5, 0, 1)
    local reliefFactor = minF + (maxF - minF) * nMod
    
    -- Perimeter Foothills Transition: gently blend interior relief into existing perimeter base
    local distInteriorEnd = 390.0
    local distPerimeterStart = 490.0
    local interiorReliefWeight = 1.0
    if distFromCenter > distInteriorEnd then
        local tPeri = math.clamp((distFromCenter - distInteriorEnd) / (distPerimeterStart - distInteriorEnd), 0, 1)
        interiorReliefWeight = 1.0 - (tPeri * tPeri * (3 - 2 * tPeri))
    end
    
    local reshapeStrength = cfg.ReshapingStrength or 1.0
    local baseHeight = cfg.BaseHeight or 5.5
    local totalBasinRelief = (hBumps + hRolling + hMedium + hLowland) * reliefFactor * reshapeStrength * interiorReliefWeight
    local naturalElevation = math.max(1.8, baseHeight + totalBasinRelief)
    
    -- 2. PROTECTED REGIONS SAFEGUARDS
    local prot = cfg.ProtectedRegions or {}
    
    -- Campsite Sanctuary (Core strictly preserved at Y=3.85, smooth S-curve blend to r=45)
    local campProt = prot.Camp or { Center = Vector3.new(0, 3.85, 0), CoreRadius = 28.0, BlendRadius = 45.0, SurfaceRoughness = 0.08 }
    local campFloor = (campProt.Center and campProt.Center.Y) or 3.85
    local coreR = campProt.CoreRadius or 28.0
    local blendR = campProt.BlendRadius or 45.0
    local campWeight = 1.0
    if distFromCenter < coreR then
        campWeight = 0.0
    elseif distFromCenter < blendR then
        local t = (distFromCenter - coreR) / (blendR - coreR)
        campWeight = t * t * (3 - 2 * t)
    end
    
    local campRoughness = 0
    if campWeight < 1.0 then
        campRoughness = math.noise(x * 0.18, z * 0.18, (seed + 15) * 0.1) * (campProt.SurfaceRoughness or 0.08)
    end
    
    local blendedElevation = (campFloor + campRoughness) + ((naturalElevation - (campFloor + campRoughness)) * campWeight)
    
    -- East Lake Shoreline Protection
    local lakeProt = prot.Lake or { Center = Vector2.new(416, -48), RadiusX = 136.0, RadiusZ = 104.0, WaterLevel = 1.02, ShoreBlendStart = 0.90, ShoreBlendEnd = 1.35 }
    local dxLake = (x - lakeProt.Center.X) / lakeProt.RadiusX
    local dzLake = (z - lakeProt.Center.Y) / lakeProt.RadiusZ
    local dLake = math.sqrt(dxLake * dxLake + dzLake * dzLake)
    
    if dLake < lakeProt.ShoreBlendStart then
        blendedElevation = lakeProt.WaterLevel - 14.0
    elseif dLake < lakeProt.ShoreBlendEnd then
        local tShore = (dLake - lakeProt.ShoreBlendStart) / (lakeProt.ShoreBlendEnd - lakeProt.ShoreBlendStart)
        local wShore = tShore * tShore * (3 - 2 * tShore)
        local shoreElevation = lakeProt.WaterLevel + 0.35
        blendedElevation = shoreElevation + ((blendedElevation - shoreElevation) * wShore)
    end
    
    -- Perimeter Mountain Foothills Transition
    local footProt = prot.Foothills or { InnerRadius = 400.0, OuterRadius = 660.0, PeakRise = 48.0, CragNoiseAmp = 14.0 }
    local mountainFactor = 0.0
    if distFromCenter > footProt.InnerRadius then
        local tWall = math.clamp((distFromCenter - footProt.InnerRadius) / (footProt.OuterRadius - footProt.InnerRadius), 0, 1)
        mountainFactor = tWall * tWall
        local cragNoise = math.noise(wx * 0.016, wz * 0.016, (seed + 333) * 0.1) * (footProt.CragNoiseAmp or 14.0)
        blendedElevation = blendedElevation + (mountainFactor * (footProt.PeakRise or 48.0)) + (cragNoise * mountainFactor)
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
-- REALISTIC EARTH MATERIAL MAPPING V3 (Zero Camouflage Cow Spots!)
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
    local seed = activeCfg.SEED or 133742
    local baseH = (activeCfg.TERRAIN and activeCfg.TERRAIN.BaseHeight) or 5.5
    
    local warpCfg = (activeCfg.TERRAIN and activeCfg.TERRAIN.DomainWarp) or { Frequency = 0.004, Strength = 28.0 }
    local wFreq = warpCfg.Frequency or 0.004
    local wStr = warpCfg.Strength or 28.0
    local wx = x + math.noise(x * wFreq, z * wFreq, (seed + 77) * 0.1) * wStr
    local wz = z + math.noise((x + 123) * wFreq, (z - 231) * wFreq, (seed + 88) * 0.1) * wStr
    
    -- 1. CAMPSITE INTERIOR & SURROUNDING WORN VERGE
    -- Bare earth is STRICTLY confined to the trodden camp sanctuary!
    if distCenter < 28.0 then
        return mats.Ground or Enum.Material.Ground
    elseif distCenter < 40.0 then
        local tCamp = (distCenter - 28.0) / (40.0 - 28.0)
        local campDither = math.noise(wx * 0.08, wz * 0.08, (seed + 15) * 0.1)
        if tCamp + campDither * 0.25 < 0.35 then
            return mats.Ground or Enum.Material.Ground
        else
            return mats.LeafyGrass or Enum.Material.LeafyGrass
        end
    end
    
    -- 2. EAST LAKE SHORELINE
    local lakeProt = (activeCfg.TERRAIN and activeCfg.TERRAIN.ProtectedRegions and activeCfg.TERRAIN.ProtectedRegions.Lake)
    if lakeProt then
        local dxLake = (x - lakeProt.Center.X) / lakeProt.RadiusX
        local dzLake = (z - lakeProt.Center.Y) / lakeProt.RadiusZ
        local dLake = math.sqrt(dxLake * dxLake + dzLake * dzLake)
        if dLake < 0.98 then
            return mats.Sand or Enum.Material.Sand
        elseif dLake < 1.12 then
            local sandNoise = math.noise(wx * 0.09, wz * 0.09, (seed + 19) * 0.1)
            if sandNoise > 0.25 then
                return mats.Cobblestone or mats.Rock or Enum.Material.Rock
            else
                return mats.Sand or Enum.Material.Sand
            end
        elseif dLake < 1.28 then
            local shoreTurfNoise = math.noise(wx * 0.06, wz * 0.06, (seed + 29) * 0.1)
            if shoreTurfNoise > 0.10 then
                return mats.Grass or Enum.Material.Grass
            elseif shoreTurfNoise < -0.20 then
                return mats.Sand or Enum.Material.Sand
            else
                return mats.LeafyGrass or Enum.Material.LeafyGrass
            end
        end
    end
    
    -- 3. WOODLAND TRAILS (Only narrow beaten center is dirt, edges are mossy duff)
    local pathWeight = PathSystem.GetPathTerrainWeight(x, z, activeCfg)
    if pathWeight > 0.85 then
        local trailNoise = math.noise(wx * 0.09, wz * 0.09, (seed + 444) * 0.1)
        if trailNoise > 0.35 then
            return mats.Cobblestone or mats.Rock or Enum.Material.Rock
        else
            return mats.Ground or Enum.Material.Ground
        end
    elseif pathWeight > 0.50 then
        return mats.LeafyGrass or Enum.Material.LeafyGrass
    end
    
    -- 4. SLOPE & MOUNTAIN RIDGE MAPPING (Only real cliffs & mountain crags show rock)
    local cliffThreshold = mats.RockCliffThreshold or 36.0
    local steepThreshold = mats.SteepSlopeThreshold or 28.0
    
    if slopeDeg >= cliffThreshold or (mountainFactor > 0.5 and slopeDeg >= steepThreshold) then
        if elevation > 30.0 then
            return mats.Slate or Enum.Material.Slate
        end
        return mats.Rock or Enum.Material.Rock
    elseif slopeDeg >= steepThreshold then
        local cragNoise = math.noise(wx * 0.03, wz * 0.03, (seed + 333) * 0.1)
        if cragNoise > 0.15 or mountainFactor > 0.4 then
            return mats.Rock or Enum.Material.Rock
        else
            return mats.LeafyGrass or Enum.Material.LeafyGrass
        end
    end
    
    -- 5. DEEP DAMP WATER MARGINS ONLY (Restricted right to water line so no dark mud blotches in hollows)
    if elevation < 1.35 then
        local waterMarginNoise = math.noise(wx * 0.08, wz * 0.08, (seed + 888) * 0.1)
        if waterMarginNoise < -0.20 then
            return mats.Mud or Enum.Material.Mud
        else
            return mats.LeafyGrass or Enum.Material.LeafyGrass
        end
    end
    
    -- 6. CONTINUOUS NATURAL VEGETATION ENGINE (Irregular, Feathered, Low-Contrast Transitions)
    -- Multi-scale noise with high-frequency fractal breakup eliminates large rounded blotches!
    local vegMacro = math.noise(wx * 0.018, wz * 0.018, (seed + 512) * 0.1) / 0.45
    local vegCluster = math.noise(wx * 0.045, wz * 0.045, (seed + 613) * 0.1) / 0.45
    local vegDither = math.noise(wx * 0.10, wz * 0.10, (seed + 714) * 0.1) / 0.45
    local vegMicro = math.noise(wx * 0.22, wz * 0.22, (seed + 725) * 0.1) / 0.45
    local vegFractal = math.noise(wx * 0.48, wz * 0.48, (seed + 836) * 0.1) / 0.45
    
    -- Subtle knoll bonus (sunny knolls lean towards lush 3D grass, hollows lean toward mossy duff)
    local knollBonus = math.clamp((elevation - baseH) * 0.06, -0.25, 0.30)
    local V = (vegMacro * 0.30) + (vegCluster * 0.35) + (vegDither * 0.15) + knollBonus
    
    -- Rare weathered stone outcroppings on prominent ridges
    local pebbleNoise = math.noise(wx * 0.14, wz * 0.14, (seed + 921) * 0.1) / 0.45
    if pebbleNoise > 0.88 and elevation > (baseH + 7.0) then
        return mats.Rock or Enum.Material.Rock
    end
    
    -- High-frequency irregular fractal dithering:
    -- Feathered transitions seamlessly interweave lush 3D Grass and soft mossy LeafyGrass
    local fractalDither = (vegDither * 0.35) + (vegMicro * 0.40) + (vegFractal * 0.25)
    local blendThreshold = V + (fractalDither * 0.32)
    
    if blendThreshold > -0.08 then
        return mats.Grass or Enum.Material.Grass
    else
        return mats.LeafyGrass or Enum.Material.LeafyGrass
    end
end

-- ---------------------------------------------------------------------------
-- PUBLIC EXECUTION API
-- ---------------------------------------------------------------------------
function TerrainGenerator.Generate(injectedCfg: any?, injectedPathSystem: any?)
    local startTime = os.clock()
    print("[TerrainGenerator] Sculpting natural rolling hills, bumps & lowlands (V3)...")
    
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
    
    -- Apply harmonized earth palette to terrain shaders (Removes camouflage & high contrast)
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
    
    local VR = (activeCfg.TERRAIN and activeCfg.TERRAIN.VoxelResolution) or 4
    local chunkSize = 64
    local chunkVoxels = chunkSize / VR -- 16 voxels per chunk dimension
    
    local minCoord = -512
    local maxCoord = 512
    local bottomY = -24.0
    local topY = 64.0
    local voxY = math.floor((topY - bottomY) / VR) -- 22 voxels
    
    local lakeProt = activeCfg.TERRAIN and activeCfg.TERRAIN.ProtectedRegions and activeCfg.TERRAIN.ProtectedRegions.Lake
    local lakeCenterX = lakeProt and lakeProt.Center.X or 416
    local lakeCenterZ = lakeProt and lakeProt.Center.Y or -48
    local lakeRadX = lakeProt and lakeProt.RadiusX or 136
    local lakeRadZ = lakeProt and lakeProt.RadiusZ or 104
    local waterLevel = lakeProt and lakeProt.WaterLevel or 1.02
    local bedLevel = -14.0
    
    local chunksProcessed = 0
    
    for cx = minCoord, maxCoord - chunkSize, chunkSize do
        for cz = minCoord, maxCoord - chunkSize, chunkSize do
            local region = Region3.new(
                Vector3.new(cx, bottomY, cz),
                Vector3.new(cx + chunkSize, topY, cz + chunkSize)
            )
            
            -- Pre-allocate 3D voxel arrays [x][y][z]
            local matArr = table.create(chunkVoxels)
            local occArr = table.create(chunkVoxels)
            for vx = 1, chunkVoxels do
                matArr[vx] = table.create(voxY)
                occArr[vx] = table.create(voxY)
                for vy = 1, voxY do
                    matArr[vx][vy] = table.create(chunkVoxels)
                    occArr[vx][vy] = table.create(chunkVoxels)
                end
            end
            
            for vx = 1, chunkVoxels do
                local worldX = cx + (vx - 1) * VR + (VR / 2)
                for vz = 1, chunkVoxels do
                    local worldZ = cz + (vz - 1) * VR + (VR / 2)
                    
                    local dxLake = (worldX - lakeCenterX) / lakeRadX
                    local dzLake = (worldZ - lakeCenterZ) / lakeRadZ
                    local dLake = math.sqrt(dxLake * dxLake + dzLake * dzLake)
                    
                    if dLake < 0.98 then
                        local bedY = bedLevel
                        if dLake > 0.78 then
                            local t = (dLake - 0.78) / (0.98 - 0.78)
                            local w = t * t * (3 - 2 * t)
                            bedY = bedLevel + (waterLevel - bedLevel) * w
                        end
                        
                        for vy = 1, voxY do
                            local worldY = bottomY + (vy - 1) * VR + (VR / 2)
                            if worldY < (bedY - 2.0) then
                                matArr[vx][vy][vz] = Enum.Material.Sand
                                occArr[vx][vy][vz] = 1.0
                            elseif worldY < bedY + 2.0 then
                                local diff = worldY - bedY
                                matArr[vx][vy][vz] = Enum.Material.Sand
                                occArr[vx][vy][vz] = math.clamp(0.5 - (diff / 4.0), 0.01, 0.99)
                            elseif worldY < (waterLevel - 2.0) then
                                matArr[vx][vy][vz] = Enum.Material.Water
                                occArr[vx][vy][vz] = 1.0
                            elseif worldY < (waterLevel + 2.0) then
                                local diff = worldY - waterLevel
                                matArr[vx][vy][vz] = Enum.Material.Water
                                occArr[vx][vy][vz] = math.clamp(0.5 - (diff / 4.0), 0.01, 0.99)
                            else
                                matArr[vx][vy][vz] = Enum.Material.Air
                                occArr[vx][vy][vz] = 0.0
                            end
                        end
                    else
                        local hSurf, distC, mFactor = sampleElevation(worldX, worldZ)
                        local slope = sampleSlopeAngle(worldX, worldZ, VR)
                        local surfMat = determineMaterial(worldX, worldZ, hSurf, slope, distC, mFactor)
                        
                        for vy = 1, voxY do
                            local worldY = bottomY + (vy - 1) * VR + (VR / 2)
                            local diff = worldY - hSurf
                            if diff <= -2.0 then
                                if worldY < (hSurf - 8.0) then
                                    matArr[vx][vy][vz] = Enum.Material.Rock
                                else
                                    matArr[vx][vy][vz] = surfMat
                                end
                                occArr[vx][vy][vz] = 1.0
                            elseif diff >= 2.0 then
                                matArr[vx][vy][vz] = Enum.Material.Air
                                occArr[vx][vy][vz] = 0.0
                            else
                                matArr[vx][vy][vz] = surfMat
                                occArr[vx][vy][vz] = math.clamp(0.5 - (diff / 4.0), 0.01, 0.99)
                            end
                        end
                    end
                end
            end
            
            pcall(function()
                Terrain:WriteVoxels(region, VR, matArr, occArr)
            end)
            
            chunksProcessed = chunksProcessed + 1
            if chunksProcessed % 16 == 0 then
                task.wait()
            end
        end
    end
    
    local elapsed = math.round((os.clock() - startTime) * 100) / 100
    print(string.format("[TerrainGenerator] Completed terrain sculpting V3 in %.2f seconds (%d chunks).", elapsed, chunksProcessed))
end

function TerrainGenerator.GetElevationAt(x: number, z: number): (number, number, number)
    return sampleElevation(x, z)
end

function TerrainGenerator.GetSlopeAt(x: number, z: number): number
    return sampleSlopeAngle(x, z, 4.0)
end

function TerrainGenerator.GetMaterialAt(x: number, z: number): Enum.Material
    local elev, distC, mFactor = sampleElevation(x, z)
    local slope = sampleSlopeAngle(x, z, 4.0)
    return determineMaterial(x, z, elev, slope, distC, mFactor)
end

return TerrainGenerator
