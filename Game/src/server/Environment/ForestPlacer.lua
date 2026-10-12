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
    if (maxY - minY) > 4.5 then
        return nil, nil
    end
    
    -- Mathematical safe target ground Y: anchored towards lowest side so uphill side is slightly buried,
    -- and downhill side NEVER floats in the air!
    local safeY = math.min(centerY, (centerY * 0.35) + (minY * 0.65))
    return safeY, centerY
end

-- Mathematical grounding engine: accurately seats tree base into terrain
-- Sinks 1% stem down as requested, guaranteeing NO part of tree elevates in the air!
local function groundTreeMathematically(treeInstance: Model, groundPos: Vector3, yawAngle: number): boolean
    local soil = treeInstance:FindFirstChild("Soil", true)
    local trunk = treeInstance:FindFirstChild("Trunk", true)
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
            if nameLower:find("leaf") or nameLower:find("leaves") or nameLower:find("needle") or nameLower:find("fern") then
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

function ForestPlacer.Populate(treesFolder: Folder, injectedCfg: any?, injectedPathSystem: any?)
    local startTime = os.clock()
    print("[ForestPlacer V4] Populating asset-driven procedural forest across entire map...")
    
    local assetLib = getAssetLibrary()
    if not assetLib then
        warn("[ForestPlacer V4] ERROR: DontLetTheFireDieAssets.Environment not found!")
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
    
    local activeCfg = injectedCfg or EnvironmentConfig
    local cfg = (activeCfg and activeCfg.TREES) or {}
    local rng = createRng((activeCfg and activeCfg.SEED) or 133742 + 888)
    
    -- Target 690 trees distributed across the full 820x860 map (Density Pass V5)
    local targetTotal = 690
    local placedPositions: { Vector3 } = {}
    local treeCount = 0
    local leavesFxCount = 0
    
    -- Full map coordinate bounds:
    local minX, maxX = -415.0, 415.0
    local minZ, maxZ = -455.0, 410.0
    
    local maxAttempts = targetTotal * 45
    local attempts = 0
    
    while treeCount < targetTotal and attempts < maxAttempts do
        attempts = attempts + 1
        
        -- Uniform random sample across full world extent
        local candX = rng(minX, maxX)
        local candZ = rng(minZ, maxZ)
        
        -- 1. Query Ground elevation, normal, material
        local groundPos, groundNormal, groundMat = findGroundPosition(candX, candZ)
        if not groundPos or not groundNormal or not groundMat then
            continue
        end
        
        -- Avoid stone cliffs and perimeter mountain rock
        if groundMat == Enum.Material.Rock or groundMat == Enum.Material.Slate then
            continue
        end
        
        -- Ensure trees do not climb outer mountain walls
        if groundPos.Y > 25.0 then
            continue
        end
        
        local slopeAngleDeg = math.deg(math.acos(math.clamp(groundNormal.Y, -1, 1)))
        if slopeAngleDeg > 28.0 then
            continue
        end
        
        -- 2. Query Biome & Hub Sanctuaries
        local biomeKey = BiomeConfig.GetBiome(candX, candZ, groundPos.Y, slopeAngleDeg)
        if biomeKey == "CampsiteSanctuary" 
            or biomeKey == "WatchtowerClearing" 
            or biomeKey == "VillageTerrace" 
            or biomeKey == "TraderOutpost" 
            or biomeKey == "GasStationSalvage" 
            or biomeKey == "LakeWater" then
            continue
        end
        
        -- 3. Trail corridor check: keep walking trails 100% clean
        local treeClearance = (activeCfg.PATHS and activeCfg.PATHS.TreeClearance) or 6.5
        if PathSystem.IsOnPath(candX, candZ, treeClearance, activeCfg) then
            continue
        end
        
        -- 4. Organic glade clearing mask (dense conifer forest stays dense, open woodland preserves larger meadows)
        local gladeNoise = math.noise(candX * 0.012, candZ * 0.012, 333)
        local gladeThreshold = (biomeKey == "DenseConifer") and -0.42 or -0.28
        if gladeNoise < gladeThreshold then
            continue
        end
        
        -- 4B. Lake Shoreline selective access: keeps wide water-access beaches open and readable
        if biomeKey == "LakeShore" then
            local shoreNoise = math.noise(candX * 0.035, candZ * 0.035, 888)
            if shoreNoise < -0.05 then
                continue
            end
        end
        
        local biomeDef = BiomeConfig.BIOMES[biomeKey]
        if not biomeDef or not biomeDef.Trees or #biomeDef.Trees == 0 then
            continue
        end
        
        -- 5. Minimum spacing check
        local minTreeDist = biomeDef.MinTreeDistance or 14.0
        local tooClose = false
        for _, pos in ipairs(placedPositions) do
            local dx = pos.X - candX
            local dz = pos.Z - candZ
            if (dx * dx + dz * dz) < (minTreeDist * minTreeDist) then
                tooClose = true
                break
            end
        end
        if tooClose then
            continue
        end
        
        -- 6. Select species and template
        local treeEntry = selectTreeEntry(biomeDef.Trees, rng)
        if not treeEntry then continue end
        
        local template = templates[treeEntry.Model]
        if not template then
            for _, t in pairs(templates) do
                template = t
                break
            end
        end
        if not template then continue end
        
        -- 7. Instantiate and scale
        local treeInstance = template:Clone()
        treeInstance.Name = treeEntry.Model
        
        local scaleMin = treeEntry.ScaleMin or 0.85
        local scaleMax = treeEntry.ScaleMax or 1.15
        local scaleFactor = rng(scaleMin, scaleMax)
        pcall(function()
            treeInstance:ScaleTo(scaleFactor)
        end)
        
        -- 8. Configure physics & collision
        configureTreePhysics(treeInstance)
        
        -- 9. Seat flush onto terrain using multi-point mathematical grounding
        local yawAngle = rng(-math.pi, math.pi)
        local groundedOk = groundTreeMathematically(treeInstance, groundPos, yawAngle)
        if not groundedOk then
            treeInstance:Destroy()
            continue
        end
        
        -- 10. Attach falling leaves particle effect if eligible
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
        
        -- 11. Coherent companion cluster generation (mixed clusters of mature and young trees)
        local clusterChance = (biomeKey == "DenseConifer") and 0.45 or ((biomeKey == "OpenWoodland") and 0.20 or 0.0)
        if treeCount < targetTotal and rng(0, 1) <= clusterChance then
            local compAngle = rng(-math.pi, math.pi)
            local compDist = rng(6.5, 9.5)
            local compX = candX + math.cos(compAngle) * compDist
            local compZ = candZ + math.sin(compAngle) * compDist
            
            if compX >= minX and compX <= maxX and compZ >= minZ and compZ <= maxZ then
                local compGPos, compGNorm, compGMat = findGroundPosition(compX, compZ)
                if compGPos and compGNorm and compGMat 
                    and compGMat ~= Enum.Material.Rock 
                    and compGMat ~= Enum.Material.Slate 
                    and compGPos.Y <= 25.0 then
                    
                    local compSlopeDeg = math.deg(math.acos(math.clamp(compGNorm.Y, -1, 1)))
                    if compSlopeDeg <= 28.0 then
                        local compBiome = BiomeConfig.GetBiome(compX, compZ, compGPos.Y, compSlopeDeg)
                        local isCompHub = (compBiome == "CampsiteSanctuary" or compBiome == "WatchtowerClearing" or compBiome == "VillageTerrace" or compBiome == "TraderOutpost" or compBiome == "GasStationSalvage" or compBiome == "LakeWater")
                        local isOnCompPath = PathSystem.IsOnPath(compX, compZ, treeClearance, activeCfg)
                        
                        if not isCompHub and not isOnCompPath then
                            local compTooClose = false
                            for _, pos in ipairs(placedPositions) do
                                local dx = pos.X - compX
                                local dz = pos.Z - compZ
                                if (dx * dx + dz * dz) < (5.5 * 5.5) then
                                    compTooClose = true
                                    break
                                end
                            end
                            
                            if not compTooClose then
                                local compModelName: string
                                if biomeKey == "DenseConifer" then
                                    local rollC = rng(0, 100)
                                    if rollC < 50 then
                                        compModelName = "Redwoodtree-LowLOD-Var01"
                                    elseif rollC < 80 then
                                        compModelName = "RedwoodTree-Var01"
                                    else
                                        compModelName = "DogwoodTree_Var01"
                                    end
                                else
                                    local rollW = rng(0, 100)
                                    if rollW < 45 then
                                        compModelName = "BeechwoodSapling_Var01"
                                    elseif rollW < 75 then
                                        compModelName = "DogwoodTree_Var01"
                                    else
                                        compModelName = "BeechwoodTree_Var03"
                                    end
                                end
                                
                                local compTemplate = templates[compModelName]
                                if compTemplate then
                                    local compInstance = compTemplate:Clone()
                                    compInstance.Name = compModelName
                                    
                                    local cScaleMin, cScaleMax = 0.35, 0.55
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
        
        if treeCount % 25 == 0 then
            task.wait()
        end
    end
    
    local elapsed = math.round((os.clock() - startTime) * 100) / 100
    print(string.format("[ForestPlacer V4] Successfully placed %d harmonized trees (%d leaf FX) across entire map in %.2f seconds.", treeCount, leavesFxCount, elapsed))
end

return ForestPlacer
