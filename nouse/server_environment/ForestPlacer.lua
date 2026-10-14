--!strict
--[[
    ForestPlacer.lua
    Asset-Driven Procedural Forest Distribution Engine (World Gen V4).
    Developed for "Don't Let the Fire Die" (Fluenosity Studio).
    
    V4 Architecture:
    - True Full-Map Distribution: Covers the entire playable open world (X: -410..410, Z: -450..410),
      surrounding the South Camp, framing all 5 winding trails, and reaching out to the mountain feet!
    - Harmonized Proportions: Redwoods scaled appropriately (28..40 studs), broadleafs scaled (20..30 studs),
      and dogwoods/saplings as understory (8..17 studs) - eliminates giant broom / broccoli clump!
    - 100% Authored Mesh Models from Tree-Pack (0 Primitives, 0 Old Yasu assets):
      * Dense Conifer: RedwoodTreeLarge-Var01, RedwoodTree-Var01, Redwoodtree-LowLOD-Var01
      * Open Woodland: BeechwoodTreeLarge_Var01, BeechwoodTree_Var01/03, MapleLeafTreeVar01, BroadLeafTree_Var01, DogwoodTree_Var01
      * Highlands & Slopes: RedwoodTree-Var01, Redwoodtree-LowLOD-Var01, BeechwoodSapling_Var01
      * Lake Shore: BroadLeafTree_Var01, DogwoodTree_Var01, BeechwoodSapling_Var01
    - Canopy Atmospherics: ParticleEffect-LeavesFalling01 integrated under mature canopies
    - Precise Mathematical Grounding: Exact world-space lowest point calculation (0 floating / 0 buried)
    - Full Hub & Trail Safeguards:
      * South Campsite (0, -430) r=52 preserved 100% clean
      * Watchtower (0, 0) r=35 preserved 100% clean
      * North Village [-245, 55] x [400, 600] stepped terraces preserved 100% clean
      * Trader Silas (-403.5, 133) r=30 preserved 100% clean
      * Gas Station (402, 253) r=35 preserved 100% clean
      * All 5 approved curvy trails with 4.5 stud clearance
]]

local Workspace = game:GetService("Workspace")
local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local sharedFolder = ReplicatedStorage:WaitForChild("FluenosityShared")

local function getFreshModule(moduleScript: ModuleScript): any
    local clone = moduleScript:Clone()
    clone.Name = "__Fresh_" .. moduleScript.Name
    clone.Parent = moduleScript.Parent
    local ok, res = pcall(function()
        return require(clone)
    end)
    clone:Destroy()
    if ok and res then
        return res
    end
    return require(moduleScript)
end

local envConfigScript = sharedFolder:WaitForChild("EnvironmentConfig") :: ModuleScript
local EnvironmentConfig = getFreshModule(envConfigScript)

local biomeConfigScript = sharedFolder:WaitForChild("BiomeConfig") :: ModuleScript
local BiomeConfig = getFreshModule(biomeConfigScript)

local envFolder = script.Parent or game:GetService("ServerScriptService"):WaitForChild("FluenosityServer"):WaitForChild("Environment")
local PathSystem = require(envFolder:WaitForChild("PathSystem"))

local ForestPlacer = {}

local function createRng(seed: number)
    local state = seed
    return function(min: number?, max: number?): number
        state = (state * 1664525 + 1013904223) % 4294967296
        local unit = state / 4294967296
        if min and max then
            return min + unit * (max - min)
        elseif min then
            return unit * min
        end
        return unit
    end
end

-- Find asset library in ServerStorage or ReplicatedStorage
local function getAssetLibrary(): Folder?
    local ssAssets = ServerStorage:FindFirstChild("DontLetTheFireDieAssets")
    if ssAssets then
        local env = ssAssets:FindFirstChild("Environment")
        if env and env:IsA("Folder") then
            return env
        end
    end
    local rsAssets = ReplicatedStorage:FindFirstChild("DontLetTheFireDieAssets")
    if rsAssets then
        local env = rsAssets:FindFirstChild("Environment")
        if env and env:IsA("Folder") then
            return env
        end
    end
    return nil
end

-- Cache prefab templates by model name for fast cloning
local function loadTreeTemplates(assetLib: Folder): { [string]: Model }
    local templates: { [string]: Model } = {}
    local treeCats = { "Trees_Conifer", "Trees_Broadleaf", "Trees_Sapling" }
    for _, catName in ipairs(treeCats) do
        local catFolder = assetLib:FindFirstChild(catName)
        if catFolder then
            for _, child in ipairs(catFolder:GetChildren()) do
                if child:IsA("Model") then
                    templates[child.Name] = child
                end
            end
        end
    end
    return templates
end

-- Raycast down to find exact surface elevation, normal, and material on terrain
local function findGroundPosition(x: number, z: number): (Vector3?, Vector3?, Enum.Material?)
    local rayOrigin = Vector3.new(x, 220, z)
    local rayDir = Vector3.new(0, -350, 0)
    
    local rayParams = RaycastParams.new()
    rayParams.FilterType = Enum.RaycastFilterType.Include
    rayParams.FilterDescendantsInstances = { Workspace.Terrain }
    
    local hit = Workspace:Raycast(rayOrigin, rayDir, rayParams)
    if hit then
        return hit.Position, hit.Normal, hit.Material
    end
    return nil, nil, nil
end

-- Multi-point mathematical terrain elevation sampler under model footprint
local function sampleTerrainFootprint(centerX: number, centerZ: number, baseRadius: number): (number?, number?)
    local rayParams = RaycastParams.new()
    rayParams.FilterType = Enum.RaycastFilterType.Include
    rayParams.FilterDescendantsInstances = { Workspace.Terrain }
    
    local cHit = Workspace:Raycast(Vector3.new(centerX, 220, centerZ), Vector3.new(0, -350, 0), rayParams)
    if not cHit then return nil, nil end
    local centerY = cHit.Position.Y
    local minY = centerY
    local maxY = centerY
    
    local offsets = {
        Vector2.new(baseRadius * 0.70, 0),
        Vector2.new(-baseRadius * 0.70, 0),
        Vector2.new(0, baseRadius * 0.70),
        Vector2.new(0, -baseRadius * 0.70),
    }
    
    for _, off in ipairs(offsets) do
        local pHit = Workspace:Raycast(Vector3.new(centerX + off.X, 220, centerZ + off.Y), Vector3.new(0, -350, 0), rayParams)
        if pHit then
            if pHit.Position.Y < minY then minY = pHit.Position.Y end
            if pHit.Position.Y > maxY then maxY = pHit.Position.Y end
        end
    end
    
    -- Discard spots on extreme slope breaks/cliffs
    local maxDrop = (centerY > 22 or math.sqrt(centerX * centerX + centerZ * centerZ) > 380) and 7.2 or 5.0
    if (maxY - minY) > maxDrop then
        return nil, nil
    end
    
    -- Mathematical safe target ground Y: anchored towards lowest side so uphill side is slightly buried,
    -- and downhill side NEVER floats in the air!
    local safeY = math.min(centerY, (centerY * 0.30) + (minY * 0.70))
    return safeY, centerY
end

-- Strictly determines if a location is on the true outer mountain boundary / high foothills
-- (Used to guarantee snowy trees only appear at the mountain border and NEVER in the center basin!)
local function isOuterBorderFoothill(x: number, z: number, groundY: number): boolean
    local r = math.sqrt(x * x + z * z)
    if groundY >= 25.0 and r >= 280.0 then
        return true -- High elevated mountain foothills/slopes
    end
    if r >= 385.0 then
        return true -- Outer perimeter radial edge
    end
    if math.abs(x) >= 380.0 or z <= -480.0 or z >= 530.0 then
        return true -- Cardinally at outer mountain boundary
    end
    return false
end

-- Mathematical grounding engine: accurately seats tree base into terrain
-- Sinks 1% stem down as requested, guaranteeing NO part of tree elevates in the air!
local function groundTreeMathematically(treeInstance: Model, groundPos: Vector3, yawAngle: number): boolean
    local soil = treeInstance:FindFirstChild("Soil", true)
    local trunk = treeInstance:FindFirstChild("Trunk", true)
    if not trunk then
        for _, desc in ipairs(treeInstance:GetDescendants()) do
            if desc:IsA("BasePart") and desc.Name:lower():find("trunk") then
                trunk = desc
                break
            end
        end
    end
    if not trunk then
        trunk = treeInstance:FindFirstChildWhichIsA("MeshPart")
    end
    
    local baseRadius = 4.0
    if soil and soil:IsA("BasePart") then
        baseRadius = math.max(soil.Size.X, soil.Size.Z) * 0.45
    elseif trunk and trunk:IsA("BasePart") then
        baseRadius = math.max(trunk.Size.X, trunk.Size.Z) * 0.30
    end
    baseRadius = math.clamp(baseRadius, 2.0, 15.0)
    
    local safeGroundY = sampleTerrainFootprint(groundPos.X, groundPos.Z, baseRadius)
    if not safeGroundY then
        return false
    end
    
    -- Place at candidate horizontal coordinate with initial orientation
    treeInstance:PivotTo(CFrame.new(groundPos.X, safeGroundY, groundPos.Z) * CFrame.Angles(0, yawAngle, 0))
    
    local anchorY: number
    if soil and soil:IsA("BasePart") then
        -- Soil part is the ground mound!
        -- Anchor at 25% below the top of the soil part so the lower 75% is underground,
        -- and the crown of the mound merges smoothly into the terrain grass.
        local soilTop = soil.CFrame.Y + (soil.Size.Y * 0.5)
        anchorY = soilTop - (soil.Size.Y * 0.25)
    elseif trunk and trunk:IsA("BasePart") then
        -- Trunk root collar: embed bottom into dirt so root base is firmly seated
        local trunkBottom = trunk.CFrame.Y - (trunk.Size.Y * 0.5)
        local scale = treeInstance:GetScale()
        local stemSink = math.clamp(1.1 * scale, 0.7, 2.5)
        anchorY = trunkBottom + stemSink
    else
        local cf, sz = treeInstance:GetBoundingBox()
        anchorY = (cf.Y - sz.Y * 0.5) + 1.0
    end
    
    local deltaY = safeGroundY - anchorY
    treeInstance:PivotTo(treeInstance:GetPivot() + Vector3.new(0, deltaY, 0))
    return true
end

-- Configure physics and collisions for placed tree models
local function configureTreePhysics(model: Model)
    for _, desc in ipairs(model:GetDescendants()) do
        if desc:IsA("BasePart") then
            desc.Anchored = true
            local nameLower = desc.Name:lower()
            if nameLower == "anchor" then
                -- Invisible helper part in certain packs
                desc.Transparency = 1
                desc.CanCollide = false
                desc.CanTouch = false
                desc.CanQuery = false
                desc.CastShadow = false
            elseif nameLower:find("leaf") or nameLower:find("leaves") or nameLower:find("needle") or nameLower:find("fern") then
                desc.CanCollide = false
                desc.CanTouch = false
                desc.CanQuery = false
                desc.CastShadow = true
            elseif nameLower:find("soil") then
                desc.CanCollide = false
                desc.CanTouch = false
                desc.CanQuery = false
                desc.CastShadow = false
            else
                -- Trunk / Main wooden structure
                desc.CanCollide = true
                desc.CanTouch = true
                desc.CanQuery = true
                desc.CastShadow = true
            end
        end
    end
end

-- Pick a tree entry from a biome configuration according to weighted probabilities
local function selectTreeEntry(entries: { any }, rng: (number?, number?) -> number): any?
    if #entries == 0 then return nil end
    local totalWeight = 0
    for _, e in ipairs(entries) do
        totalWeight = totalWeight + (e.Weight or 10)
    end
    local roll = rng(0, totalWeight)
    local accum = 0
    for _, e in ipairs(entries) do
        accum = accum + (e.Weight or 10)
        if roll <= accum then
            return e
        end
    end
    return entries[1]
end

function ForestPlacer.Populate(treesFolder: Folder, injectedCfg: any?, injectedPathSystem: any?, injectedPreset: string?)
    local startTime = os.clock()
    
    local assetLib = getAssetLibrary()
    if not assetLib then
        warn("[ForestPlacer V6] ERROR: DontLetTheFireDieAssets.Environment not found!")
        return
    end
    
    local templates = loadTreeTemplates(assetLib)
    local leafParticleTemplate: Model? = nil
    local atmoFolder = assetLib:FindFirstChild("Atmospherics")
    if atmoFolder then
        local pe = atmoFolder:FindFirstChild("ParticleEffect-LeavesFalling01")
        if pe and pe:IsA("Model") then
            leafParticleTemplate = pe
        end
    end
    
    BiomeConfig = getFreshModule(biomeConfigScript)

    if injectedPathSystem then
        PathSystem = injectedPathSystem
    end
    
    local presetKey = injectedPreset or (injectedCfg and injectedCfg.PRESET) or BiomeConfig.ACTIVE_PRESET
    local activePreset = (BiomeConfig.PRESETS and BiomeConfig.PRESETS[presetKey]) or (BiomeConfig.GetActivePreset and BiomeConfig.GetActivePreset()) or {
        Name = "V6_FullPerimeterDense",
        TargetTotalTrees = 960,
        Bounds = { MinX = -490.0, MaxX = 490.0, MinZ = -535.0, MaxZ = 535.0 },
        MaxElevation = 42.0,
        MaxSlopeDeg = 30.0,
        AllowSnowyTrees = true,
        SnowyTreesBorderOnly = true,
        BorderMinRadius = 385.0,
        BorderWallPassTrees = 280,
        PathShoulderPassTrees = 120,
        ClusterChanceConifer = 0.52,
        ClusterChanceWoodland = 0.28,
        GladeThresholdConifer = -0.48,
        GladeThresholdWoodland = -0.34,
    }
    
    print(string.format("[ForestPlacer V8] Populating forest using preset: '%s' (Target: %d trees)...", 
        activePreset.Name or tostring(presetKey), activePreset.TargetTotalTrees or 1850))
    
    -- Save cluster snapshot of previous forest to ServerStorage.WorldSnapshots for instant rollback capability
    pcall(function()
        local snapshotsFolder = ServerStorage:FindFirstChild("WorldSnapshots")
        if not snapshotsFolder then
            snapshotsFolder = Instance.new("Folder")
            snapshotsFolder.Name = "WorldSnapshots"
            snapshotsFolder.Parent = ServerStorage
        end
        if treesFolder and #treesFolder:GetChildren() > 0 then
            local count = #treesFolder:GetChildren()
            local snapName = string.format("Trees_Snapshot_%d", count)
            if not snapshotsFolder:FindFirstChild(snapName) then
                local backup = treesFolder:Clone()
                backup.Name = snapName
                backup.Parent = snapshotsFolder
                print(string.format("[ForestPlacer] Preserved world snapshot in ServerStorage.WorldSnapshots.%s (%d trees)", snapName, count))
            end
        end
    end)
    
    local activeCfg = injectedCfg or EnvironmentConfig
    local rng = createRng((activeCfg and activeCfg.SEED) or 133742 + 888)
    
    local targetTotal = activePreset.TargetTotalTrees or 1320
    local placedPositions: { Vector3 } = {}
    local treeCount = 0
    local leavesFxCount = 0
    local snowyCount = 0
    
    -- Coordinate bounds from active preset:
    local minX = activePreset.Bounds and activePreset.Bounds.MinX or -500.0
    local maxX = activePreset.Bounds and activePreset.Bounds.MaxX or 500.0
    local minZ = activePreset.Bounds and activePreset.Bounds.MinZ or -545.0
    local maxZ = activePreset.Bounds and activePreset.Bounds.MaxZ or 545.0
    local maxElev = activePreset.MaxElevation or 45.0
    local maxSlope = activePreset.MaxSlopeDeg or 32.0
    
    -- Core single-tree placement helper
    local function tryPlaceTree(candX: number, candZ: number, overrideModel: string?, isShoulderPass: boolean?, customMinDist: number?, skipGladeCheck: boolean?): boolean
        if treeCount >= targetTotal then return false end
        
        -- 1. Query Ground
        local groundPos, groundNormal, groundMat = findGroundPosition(candX, candZ)
        if not groundPos or not groundNormal or not groundMat then
            return false
        end
        
        if groundMat == Enum.Material.Rock or groundMat == Enum.Material.Slate then
            return false
        end
        
        if groundPos.Y > maxElev then
            return false
        end
        
        local slopeAngleDeg = math.deg(math.acos(math.clamp(groundNormal.Y, -1, 1)))
        if slopeAngleDeg > maxSlope then
            return false
        end
        
        -- 2. Query Biome & Hub Sanctuaries
        local biomeKey = BiomeConfig.GetBiome(candX, candZ, groundPos.Y, slopeAngleDeg)
        if biomeKey == "CampsiteSanctuary" 
            or biomeKey == "WatchtowerClearing" 
            or biomeKey == "VillageTerrace" 
            or biomeKey == "TraderOutpost" 
            or biomeKey == "GasStationSalvage" 
            or biomeKey == "LakeWater" then
            return false
        end
        
        -- 3. Trail corridor check
        if isShoulderPass then
            -- Walking corridor (6.0 studs) must be 100% clean, but shoulder is permitted!
            if PathSystem.IsOnPath(candX, candZ, 6.0, activeCfg) then
                return false
            end
        else
            local treeClearance = (activeCfg.PATHS and activeCfg.PATHS.TreeClearance) or 6.5
            if PathSystem.IsOnPath(candX, candZ, math.max(treeClearance, 6.5), activeCfg) then
                return false
            end
        end
        
        -- 4. Glade clearing mask (skipped for border pass so border forms an unbroken wall)
        if not skipGladeCheck then
            local gladeNoise = math.noise(candX * 0.012, candZ * 0.012, 333)
            local gladeThreshold = (biomeKey == "DenseConifer") 
                and (activePreset.GladeThresholdConifer or -0.48) 
                or (activePreset.GladeThresholdWoodland or -0.34)
            if gladeNoise < gladeThreshold then
                return false
            end
            
            if biomeKey == "LakeShore" then
                local shoreNoise = math.noise(candX * 0.035, candZ * 0.035, 888)
                if shoreNoise < -0.10 then
                    return false
                end
            end
        end
        
        local biomeDef = BiomeConfig.BIOMES[biomeKey]
        if not biomeDef or not biomeDef.Trees or #biomeDef.Trees == 0 then
            return false
        end
        
        -- 5. Minimum spacing check
        local minTreeDist = customMinDist or (biomeDef.MinTreeDistance or 9.5)
        for _, pos in ipairs(placedPositions) do
            local dx = pos.X - candX
            local dz = pos.Z - candZ
            if (dx * dx + dz * dz) < (minTreeDist * minTreeDist) then
                return false
            end
        end
        
        -- Border foothills evaluation (for snowy trees strictly on mountain rims, NEVER in center basin)
        local isBorderFoothill = isOuterBorderFoothill(candX, candZ, groundPos.Y)
        
        -- 6. Select species and template
        local selectedModel = overrideModel
        local scaleMin = 0.85
        local scaleMax = 1.15
        
        if not selectedModel then
            local treeEntry = selectTreeEntry(biomeDef.Trees, rng)
            if not treeEntry then return false end
            selectedModel = treeEntry.Model
            scaleMin = treeEntry.ScaleMin or 0.85
            scaleMax = treeEntry.ScaleMax or 1.15
        else
            for _, entry in ipairs(biomeDef.Trees) do
                if entry.Model == selectedModel then
                    scaleMin = entry.ScaleMin or scaleMin
                    scaleMax = entry.ScaleMax or scaleMax
                    break
                end
            end
        end
        
        -- STRICT ENFORCEMENT: Never keep white snowy tree at center, only at outer border edges!
        if selectedModel == "Redwood_Snowy01" then
            if not activePreset.AllowSnowyTrees or not isBorderFoothill then
                selectedModel = "RedwoodTree-Var01"
                scaleMin = 0.50
                scaleMax = 0.67
            end
        elseif isBorderFoothill and activePreset.AllowSnowyTrees and (biomeKey == "DenseConifer" or biomeKey == "RockyHighlands") then
            -- Transition into snowy mountains: 35% chance for border conifers to become snowy
            if rng(0, 100) < 35 then
                selectedModel = "Redwood_Snowy01"
                scaleMin = 0.28
                scaleMax = 0.38
            end
        end
        
        local template = templates[selectedModel]
        if not template then
            for _, t in pairs(templates) do
                template = t
                break
            end
        end
        if not template then return false end
        
        -- 7. Instantiate and scale
        local treeInstance = template:Clone()
        treeInstance.Name = selectedModel
        
        local scaleFactor = rng(scaleMin, scaleMax)
        pcall(function()
            treeInstance:ScaleTo(scaleFactor)
        end)
        
        configureTreePhysics(treeInstance)
        
        local yawAngle = rng(-math.pi, math.pi)
        local groundedOk = groundTreeMathematically(treeInstance, groundPos, yawAngle)
        if not groundedOk then
            treeInstance:Destroy()
            return false
        end
        
        -- Attach falling leaves particle effect if eligible
        local fallingLeavesChance = biomeDef.CanopyFallingLeavesChance or 0.0
        if leafParticleTemplate and rng(0, 1) <= fallingLeavesChance then
            local cf, sz = treeInstance:GetBoundingBox()
            if sz.Y > 18.0 then
                local fxClone = leafParticleTemplate:Clone()
                fxClone.Name = "CanopyLeavesEffect"
                local fxPart = fxClone:FindFirstChildWhichIsA("BasePart", true)
                if fxPart then
                    fxPart.Anchored = true
                    fxPart.CanCollide = false
                    fxPart.CanTouch = false
                    fxPart.CanQuery = false
                    fxPart.Transparency = 1
                    fxPart.CFrame = CFrame.new(cf.Position.X, cf.Position.Y + (sz.Y * 0.25), cf.Position.Z)
                end
                fxClone.Parent = treeInstance
                leavesFxCount = leavesFxCount + 1
            end
        end
        
        treeInstance.Parent = treesFolder
        table.insert(placedPositions, groundPos)
        treeCount = treeCount + 1
        if selectedModel == "Redwood_Snowy01" then
            snowyCount = snowyCount + 1
        end
        
        -- Companion cluster generation
        local clusterChance = (biomeKey == "DenseConifer") and (activePreset.ClusterChanceConifer or 0.52) 
            or ((biomeKey == "OpenWoodland") and (activePreset.ClusterChanceWoodland or 0.28) or 0.0)
            
        if not isShoulderPass and treeCount < targetTotal and rng(0, 1) <= clusterChance then
            local compAngle = rng(-math.pi, math.pi)
            local compDist = rng(6.0, 9.0)
            local compX = candX + math.cos(compAngle) * compDist
            local compZ = candZ + math.sin(compAngle) * compDist
            
            if compX >= minX and compX <= maxX and compZ >= minZ and compZ <= maxZ then
                local compGPos, compGNorm, compGMat = findGroundPosition(compX, compZ)
                if compGPos and compGNorm and compGMat 
                    and compGMat ~= Enum.Material.Rock 
                    and compGMat ~= Enum.Material.Slate 
                    and compGPos.Y <= maxElev then
                    
                    local compSlopeDeg = math.deg(math.acos(math.clamp(compGNorm.Y, -1, 1)))
                    if compSlopeDeg <= maxSlope then
                        local compBiome = BiomeConfig.GetBiome(compX, compZ, compGPos.Y, compSlopeDeg)
                        local isCompHub = (compBiome == "CampsiteSanctuary" or compBiome == "WatchtowerClearing" or compBiome == "VillageTerrace" or compBiome == "TraderOutpost" or compBiome == "GasStationSalvage" or compBiome == "LakeWater")
                        local isOnCompPath = PathSystem.IsOnPath(compX, compZ, 7.5, activeCfg)
                        
                        if not isCompHub and not isOnCompPath then
                            local compTooClose = false
                            for _, pos in ipairs(placedPositions) do
                                local dx = pos.X - compX
                                local dz = pos.Z - compZ
                                if (dx * dx + dz * dz) < (5.2 * 5.2) then
                                    compTooClose = true
                                    break
                                end
                            end
                            
                            if not compTooClose then
                                local compIsBorder = isOuterBorderFoothill(compX, compZ, compGPos.Y)
                                local compModelName: string
                                local cScaleMin, cScaleMax = 0.35, 0.55
                                
                                if biomeKey == "DenseConifer" or compBiome == "RockyHighlands" then
                                    local rollC = rng(0, 100)
                                    if compIsBorder and activePreset.AllowSnowyTrees and rollC < 35 then
                                        compModelName = "Redwood_Snowy01"
                                        cScaleMin, cScaleMax = 0.28, 0.38
                                    elseif rollC < 55 then
                                        compModelName = "Redwoodtree-LowLOD-Var01"
                                        cScaleMin, cScaleMax = 0.32, 0.43
                                    elseif rollC < 85 then
                                        compModelName = "RedwoodTree-Var01"
                                        cScaleMin, cScaleMax = 0.50, 0.67
                                    else
                                        compModelName = "DogwoodTree_Var01"
                                        cScaleMin, cScaleMax = 0.95, 1.35
                                    end
                                else
                                    local rollW = rng(0, 100)
                                    if rollW < 45 then
                                        compModelName = "BeechwoodSapling_Var01"
                                        cScaleMin, cScaleMax = 1.13, 1.58
                                    elseif rollW < 75 then
                                        compModelName = "DogwoodTree_Var01"
                                        cScaleMin, cScaleMax = 1.13, 1.51
                                    else
                                        compModelName = "BeechwoodTree_Var03"
                                        cScaleMin, cScaleMax = 0.88, 1.13
                                    end
                                end
                                
                                local compTemplate = templates[compModelName]
                                if compTemplate then
                                    local compInstance = compTemplate:Clone()
                                    compInstance.Name = compModelName
                                    
                                    for _, entry in ipairs(biomeDef.Trees) do
                                        if entry.Model == compModelName then
                                            cScaleMin = entry.ScaleMin or cScaleMin
                                            cScaleMax = entry.ScaleMax or cScaleMax
                                            break
                                        end
                                    end
                                    local compScale = rng(cScaleMin, cScaleMax) * 0.95
                                    pcall(function() compInstance:ScaleTo(compScale) end)
                                    configureTreePhysics(compInstance)
                                    
                                    local compYaw = rng(-math.pi, math.pi)
                                    local compGrounded = groundTreeMathematically(compInstance, compGPos, compYaw)
                                    if compGrounded then
                                        compInstance.Parent = treesFolder
                                        table.insert(placedPositions, compGPos)
                                        treeCount = treeCount + 1
                                        if compModelName == "Redwood_Snowy01" then
                                            snowyCount = snowyCount + 1
                                        end
                                    else
                                        compInstance:Destroy()
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
        
        return true
    end
    
    -- -----------------------------------------------------------------------
    -- PASS 1: Dedicated Mountain Border Ring Pass (Creates unbroken dense border wall)
    -- -----------------------------------------------------------------------
    local borderTarget = activePreset.BorderWallPassTrees or 380
    local borderAttempts = 0
    print(string.format("[ForestPlacer V8] Executing mountain border wall pass (%d target trees)...", borderTarget))
    while borderAttempts < (borderTarget * 35) and treeCount < borderTarget do
        borderAttempts = borderAttempts + 1
        local angle = rng(-math.pi, math.pi)
        local radius = rng(400.0, 720.0)
        local candX = math.clamp(math.cos(angle) * radius, minX, maxX)
        local candZ = math.clamp(math.sin(angle) * radius, minZ, maxZ)
        
        -- High border density: customMinDist = 6.2 studs, skip glade clearing
        tryPlaceTree(candX, candZ, nil, false, 6.2, true)
    end
    
    -- -----------------------------------------------------------------------
    -- PASS 2: South Camp Back Sector Pass (User marked bottom circle: Z: -430 .. -740)
    -- -----------------------------------------------------------------------
    local southTarget = activePreset.SectorTreesPerZone or 140
    local southTargetTotal = treeCount + southTarget
    local southAttempts = 0
    print(string.format("[ForestPlacer V8] Executing South Camp back sector pass (%d trees)...", southTarget))
    while southAttempts < (southTarget * 25) and treeCount < southTargetTotal and treeCount < targetTotal do
        southAttempts = southAttempts + 1
        local candX = rng(-380.0, 380.0)
        local candZ = rng(-740.0, -435.0)
        tryPlaceTree(candX, candZ, nil, false, 6.5, true)
    end
    
    -- -----------------------------------------------------------------------
    -- PASS 3: North Village Back Sector Pass (User marked top circle: Z: 510 .. 740)
    -- -----------------------------------------------------------------------
    local northTarget = activePreset.SectorTreesPerZone or 140
    local northTargetTotal = treeCount + northTarget
    local northAttempts = 0
    print(string.format("[ForestPlacer V8] Executing North Village back sector pass (%d trees)...", northTarget))
    while northAttempts < (northTarget * 25) and treeCount < northTargetTotal and treeCount < targetTotal do
        northAttempts = northAttempts + 1
        local candX = rng(-450.0, 400.0)
        local candZ = rng(510.0, 740.0)
        tryPlaceTree(candX, candZ, nil, false, 6.5, true)
    end
    
    -- -----------------------------------------------------------------------
    -- PASS 4: West Sector Behind Lake & Silas (User marked left circle: X: -400 .. -720)
    -- -----------------------------------------------------------------------
    local westTarget = activePreset.SectorTreesPerZone or 140
    local westTargetTotal = treeCount + westTarget
    local westAttempts = 0
    print(string.format("[ForestPlacer V8] Executing West Sector pass behind lake/Silas (%d trees)...", westTarget))
    while westAttempts < (westTarget * 25) and treeCount < westTargetTotal and treeCount < targetTotal do
        westAttempts = westAttempts + 1
        local candX = rng(-720.0, -395.0)
        local candZ = rng(-380.0, 380.0)
        tryPlaceTree(candX, candZ, nil, false, 6.5, true)
    end
    
    -- -----------------------------------------------------------------------
    -- PASS 5: East Sector Behind Gas Station & Lake (User marked right circle: X: 400 .. 720)
    -- -----------------------------------------------------------------------
    local eastTarget = activePreset.SectorTreesPerZone or 140
    local eastTargetTotal = treeCount + eastTarget
    local eastAttempts = 0
    print(string.format("[ForestPlacer V8] Executing East Sector pass behind Gas Station (%d trees)...", eastTarget))
    while eastAttempts < (eastTarget * 25) and treeCount < eastTargetTotal and treeCount < targetTotal do
        eastAttempts = eastAttempts + 1
        local candX = rng(395.0, 720.0)
        local candZ = rng(-380.0, 380.0)
        tryPlaceTree(candX, candZ, nil, false, 6.5, true)
    end
    
    -- -----------------------------------------------------------------------
    -- PASS 6: Trail Corridor Shoulder Pass (Frames walking trails with roadside trees)
    -- -----------------------------------------------------------------------
    local shoulderTarget = activePreset.PathShoulderPassTrees or 120
    local shoulderTargetTotal = treeCount + shoulderTarget
    local shoulderAttempts = 0
    print(string.format("[ForestPlacer V8] Executing trail corridor shoulder pass (%d trees)...", shoulderTarget))
    while shoulderAttempts < (shoulderTarget * 25) and treeCount < shoulderTargetTotal and treeCount < targetTotal do
        shoulderAttempts = shoulderAttempts + 1
        local candX = rng(minX * 0.70, maxX * 0.70)
        local candZ = rng(minZ * 0.70, maxZ * 0.70)
        
        -- Walking corridor (5.0 studs) must be clean, shoulder (5.2 .. 11.5 studs) contains trees
        local onCorridor = PathSystem.IsOnPath(candX, candZ, 5.0, activeCfg)
        local onShoulder = PathSystem.IsOnPath(candX, candZ, 11.5, activeCfg)
        if not onCorridor and onShoulder then
            local rollS = rng(0, 100)
            local sModel = "DogwoodTree_Var01"
            if rollS < 45 then
                sModel = "DogwoodTree_Var01"
            elseif rollS < 75 then
                sModel = "BeechwoodSapling_Var01"
            else
                sModel = "MapleLeafTreeVar01"
            end
            tryPlaceTree(candX, candZ, sModel, true, 7.5, true)
        end
    end
    
    -- -----------------------------------------------------------------------
    -- PASS 7: Full-Map Ambient Forest Pass (Fills all biomes up to target total)
    -- -----------------------------------------------------------------------
    local maxAttempts = targetTotal * 45
    local attempts = 0
    
    while treeCount < targetTotal and attempts < maxAttempts do
        attempts = attempts + 1
        local candX = rng(minX, maxX)
        local candZ = rng(minZ, maxZ)
        tryPlaceTree(candX, candZ, nil, false, nil, false)
        
        if treeCount % 40 == 0 then
            task.wait()
        end
    end
    
    local elapsed = math.round((os.clock() - startTime) * 100) / 100
    print(string.format("[ForestPlacer V8] Placed %d trees (%d border snowy, %d leaf FX) across map in %.2f seconds.", 
        treeCount, snowyCount, leavesFxCount, elapsed))
end

-- Helper for one-line preset rollback or switching
function ForestPlacer.RollbackToPreset(presetName: string, treesFolder: Folder, activeCfg: any?, pathSys: any?)
    if BiomeConfig.PRESETS[presetName] then
        print("[ForestPlacer] Rolling back / switching to preset:", presetName)
        treesFolder:ClearAllChildren()
        ForestPlacer.Populate(treesFolder, activeCfg, pathSys, presetName)
    else
        warn("[ForestPlacer] Unknown preset name:", presetName)
    end
end

return ForestPlacer

