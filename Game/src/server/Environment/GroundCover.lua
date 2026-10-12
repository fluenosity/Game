--!strict
--[[
    GroundCover.lua
    Asset-Driven Forest Floor Ecology & Ground Detailing Engine (World Gen V8).
    Developed for "Don't Let the Fire Die" (Fluenosity Studio).
    
    100% Authored Mesh Assets from Tree-Pack (0 Primitives, 0 Old External Grass):
    - Ground Patches: DenseLeafPatch (dirt/mulch layer), CloverPatch (low vibrant clover)
    - Ferns: FernTallVar01, Fern_Var01, DyingFern01
    - Shrubs: MountainLaurelBush_Var01, RhododendronVar01, RhododendronVar02
    - Wildflowers: WildFlower01, Wildflower02, WildFlower03, WildFlower04
    - Micro-Pebbles: SmallRock01, SmallRockGroupVar02, SmallRockGroupVar03, SmallRockVar04
    - Deadwood Logs: FallenTree, FallenTreeMossyVar01 (Tagged "WoodPile" for foraging)
    - Stumps: TreeStump (Tagged "WoodPile")
    - Foraging Sticks: BranchVar01, StickVar01..06 (Tagged "WoodPile")
    
    Zero Physics Drag: Foliage, flowers, and patches have CanCollide=false, CanTouch=false, CanQuery=false
    Full Safeguards: Zero clutter on walking trails, South camp, Watchtower, or inside Village.
]]

local Workspace = game:GetService("Workspace")
local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")

local sharedFolder = ReplicatedStorage:WaitForChild("FluenosityShared")
local envConfigScript = sharedFolder:WaitForChild("EnvironmentConfig")
local okConfig, freshConfig = pcall(function() return require(envConfigScript:Clone()) end)
local EnvironmentConfig = (okConfig and freshConfig) or require(envConfigScript)

local BiomeConfig = require(sharedFolder:WaitForChild("BiomeConfig"))

local envFolder = script.Parent or game:GetService("ServerScriptService"):WaitForChild("FluenosityServer"):WaitForChild("Environment")
local PathSystem = require(envFolder:WaitForChild("PathSystem"))

local GroundCover = {}

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

-- Cache all ground cover templates strictly from the tree-pack
local function loadGroundCoverTemplates(assetLib: Folder): { [string]: Model }
    local templates: { [string]: Model } = {}
    local cats = {
        "Foliage_Ferns",
        "Foliage_Shrubs",
        "Foliage_Flowers",
        "Foliage_GroundPatches",
        "Rocks_Small",
        "Deadwood_Logs",
        "Deadwood_Stumps",
        "Deadwood_Sticks",
    }
    for _, catName in ipairs(cats) do
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

-- Raycast down to find ground elevation, normal, and material
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

local function getModelBottomY(model: Model): number
    local minY = math.huge
    for _, part in ipairs(model:GetDescendants()) do
        if part:IsA("BasePart") then
            local cf = part.CFrame
            local size = part.Size
            local hx, hy, hz = size.X * 0.5, size.Y * 0.5, size.Z * 0.5
            for sx = -1, 1, 2 do
                for sy = -1, 1, 2 do
                    for sz = -1, 1, 2 do
                        local cornerY = cf:PointToWorldSpace(Vector3.new(sx * hx, sy * hy, sz * hz)).Y
                        if cornerY < minY then
                            minY = cornerY
                        end
                    end
                end
            end
        end
    end
    return minY
end

-- Precise surface normal grounding
local function groundModelPrecisely(model: Model, groundPos: Vector3, yawAngle: number, sinkY: number?, normal: Vector3?)
    if normal and math.abs(normal.Y) > 0.45 then
        local up = normal.Unit
        local right = Vector3.new(1, 0, 0):Cross(up).Unit
        if right.Magnitude < 0.1 then
            right = Vector3.new(0, 0, 1):Cross(up).Unit
        end
        local forward = up:Cross(right).Unit
        local normalCF = CFrame.fromMatrix(groundPos, right, up, -forward) * CFrame.Angles(0, yawAngle, 0)
        model:PivotTo(normalCF)
    else
        model:PivotTo(CFrame.new(groundPos) * CFrame.Angles(0, yawAngle, 0))
    end

    local lowestY = getModelBottomY(model)
    if lowestY == math.huge then return end
    local sink = sinkY or 0.10
    local deltaY = (groundPos.Y - sink) - lowestY
    model:PivotTo(model:GetPivot() + Vector3.new(0, deltaY, 0))
end

function GroundCover.Populate(groundFolder: Folder, injectedCfg: any?, injectedPathSystem: any?)
    local startTime = os.clock()
    
    local assetLib = getAssetLibrary()
    if not assetLib then
        warn("[GroundCover V8] ERROR: DontLetTheFireDieAssets.Environment not found!")
        return
    end
    
    local templates = loadGroundCoverTemplates(assetLib)
    
    local freshBiomeScript = sharedFolder:WaitForChild("BiomeConfig") :: ModuleScript
    local okB, freshB = pcall(function() return require(freshBiomeScript:Clone()) end)
    local activeBiomeConfig = (okB and freshB) or BiomeConfig
    
    if injectedPathSystem then
        PathSystem = injectedPathSystem
    end
    
    local activePreset = (activeBiomeConfig.GetActivePreset and activeBiomeConfig.GetActivePreset()) or {
        Bounds = { MinX = -720.0, MaxX = 720.0, MinZ = -740.0, MaxZ = 740.0 },
        MaxElevation = 68.0,
        TargetGroundCover = 3200,
    }
    
    local targetTotal = math.min(activePreset.TargetGroundCover or 3200, 3200)
    print(string.format("[GroundCover V8] Populating clean tree-pack ground ecology (%d items, 0 external grass)...", targetTotal))
    
    local activeCfg = injectedCfg or EnvironmentConfig
    local rng = createRng((activeCfg and activeCfg.SEED) or 133742 + 777)
    
    local function getSubfolder(name: string): Folder
        local sf = groundFolder:FindFirstChild(name)
        if not sf then
            sf = Instance.new("Folder")
            sf.Name = name
            sf.Parent = groundFolder
        end
        return sf :: Folder
    end
    
    -- Clean subfolders (0 Grass folder!)
    local foliageFolder = getSubfolder("Foliage")
    local deadwoodFolder = getSubfolder("Deadwood")
    local patchesFolder = getSubfolder("Patches")
    local debrisFolder = getSubfolder("Debris")
    
    -- Clean up any legacy Grass subfolder
    local oldGrass = groundFolder:FindFirstChild("Grass")
    if oldGrass then oldGrass:Destroy() end
    
    local placedPositions: { Vector3 } = {}
    local itemCount = 0
    local logStickCount = 0
    
    -- Category budgets across full map (100% Tree-Pack Assets)
    local targetPatches = math.floor(targetTotal * 0.40) -- ~1280 patches (DenseLeafPatch soil layer + CloverPatch)
    local targetFerns = math.floor(targetTotal * 0.25)   -- ~800 ferns (Fern_Var01, FernTallVar01, DyingFern01)
    local targetFlowers = math.floor(targetTotal * 0.12) -- ~380 wildflowers
    local targetShrubs = math.floor(targetTotal * 0.08)  -- ~250 shrubs
    local targetDebris = math.floor(targetTotal * 0.08)  -- ~250 small rocks/pebbles
    local targetLogs = math.floor(targetTotal * 0.02)    -- ~60 fallen logs
    local targetSticks = targetTotal - (targetPatches + targetFerns + targetFlowers + targetShrubs + targetDebris + targetLogs) -- ~180 sticks
    
    local minX = activePreset.Bounds and activePreset.Bounds.MinX or -720.0
    local maxX = activePreset.Bounds and activePreset.Bounds.MaxX or 720.0
    local minZ = activePreset.Bounds and activePreset.Bounds.MinZ or -740.0
    local maxZ = activePreset.Bounds and activePreset.Bounds.MaxZ or 740.0
    local maxElev = activePreset.MaxElevation or 68.0
    
    local function placeItem(chosenName: string, catType: string, groundPos: Vector3, groundNormal: Vector3): boolean
        local template = templates[chosenName]
        if not template then return false end
        
        local instance = template:Clone()
        instance.Name = chosenName
        
        local targetParent = foliageFolder
        if catType == "Log" or catType == "Stick" then
            targetParent = deadwoodFolder
        elseif catType == "Patch" then
            targetParent = patchesFolder
        elseif catType == "Debris" then
            targetParent = debrisFolder
        end
        
        local scaleFactor = 1.0
        if catType == "Fern" or catType == "Shrub" then
            scaleFactor = rng(0.85, 1.25)
        elseif catType == "Flower" then
            scaleFactor = rng(0.90, 1.30)
        elseif catType == "Patch" then
            scaleFactor = (chosenName == "DenseLeafPatch") and rng(1.30, 2.10) or rng(1.05, 1.60)
        elseif catType == "Debris" then
            scaleFactor = rng(0.70, 1.20)
        elseif catType == "Log" then
            scaleFactor = rng(0.63, 0.80)
        elseif catType == "Stick" then
            scaleFactor = rng(0.90, 1.35)
        end
        pcall(function()
            instance:ScaleTo(instance:GetScale() * scaleFactor)
        end)
        
        for _, desc in ipairs(instance:GetDescendants()) do
            if desc:IsA("BasePart") then
                desc.Anchored = true
                if catType == "Log" or chosenName == "TreeStump" then
                    desc.CanCollide = true
                    desc.CanTouch = true
                    desc.CanQuery = true
                    desc.CastShadow = true
                elseif catType == "Stick" then
                    desc.CanCollide = false
                    desc.CanTouch = true
                    desc.CanQuery = true
                    desc.CastShadow = false
                else
                    -- Patches, Flowers, Ferns, Shrubs, Debris
                    desc.CanCollide = false
                    desc.CanTouch = false
                    desc.CanQuery = false
                    desc.CastShadow = false
                end
            end
        end
        
        if catType == "Log" or catType == "Stick" or chosenName == "TreeStump" then
            CollectionService:AddTag(instance, "WoodPile")
            logStickCount = logStickCount + 1
        end
        
        local yawAngle = rng(-math.pi, math.pi)
        local sink = 0.10
        local alignNormal: Vector3? = nil
        
        if catType == "Patch" then
            sink = 0.03
            alignNormal = groundNormal
        elseif catType == "Debris" then
            sink = 0.06
            alignNormal = groundNormal
        elseif catType == "Log" then
            sink = 0.35
            alignNormal = groundNormal
        elseif catType == "Stick" then
            sink = 0.05
            alignNormal = groundNormal
        elseif catType == "Flower" then
            sink = 0.08
        elseif catType == "Fern" or catType == "Shrub" then
            sink = 0.16
        end
        
        groundModelPrecisely(instance, groundPos, yawAngle, sink, alignNormal)
        instance.Parent = targetParent
        table.insert(placedPositions, groundPos)
        itemCount = itemCount + 1
        return true
    end
    
    -- -----------------------------------------------------------------------
    -- PASS 1: Tree Root Collar Mulch & Fern Dressing
    -- -----------------------------------------------------------------------
    local canopyTarget = 700
    local canopyAttempts = 0
    local envTreesFolder = Workspace:FindFirstChild("ForestEnvironment") and Workspace.ForestEnvironment:FindFirstChild("Trees")
    local treeChildren = (envTreesFolder and envTreesFolder:GetChildren()) or {}
    
    if #treeChildren > 0 then
        while canopyAttempts < 1500 and itemCount < canopyTarget and itemCount < targetTotal do
            canopyAttempts = canopyAttempts + 1
            local randTree = treeChildren[math.floor(rng(1, #treeChildren + 0.99))]
            local treePivot = randTree:GetPivot().Position
            local rad = rng(2.0, 7.5)
            local ang = rng(-math.pi, math.pi)
            local candX = treePivot.X + math.cos(ang) * rad
            local candZ = treePivot.Z + math.sin(ang) * rad
            
            local onCorridor = PathSystem.IsOnPath(candX, candZ, 2.5, activeCfg)
            if not onCorridor then
                local groundPos, groundNormal, groundMat = findGroundPosition(candX, candZ)
                if groundPos and groundNormal and groundMat and groundMat ~= Enum.Material.Rock then
                    local roll = rng(0, 100)
                    local cCat = "Patch"
                    local cName = "DenseLeafPatch"
                    if roll < 58 then
                        cCat = "Patch"
                        cName = "DenseLeafPatch" -- Natural dark soil & fallen leaves at tree base!
                    elseif roll < 85 then
                        cCat = "Fern"
                        cName = (roll < 72) and "Fern_Var01" or "FernTallVar01"
                    else
                        cCat = "Debris"
                        cName = "SmallRock01"
                    end
                    placeItem(cName, cCat, groundPos, groundNormal)
                end
            end
        end
    end
    
    -- -----------------------------------------------------------------------
    -- PASS 2: Trail Shoulder Detailing (Frames walking paths naturally)
    -- -----------------------------------------------------------------------
    local pathShoulderTarget = itemCount + 650
    local pathAttempts = 0
    while pathAttempts < 2400 and itemCount < pathShoulderTarget and itemCount < targetTotal do
        pathAttempts = pathAttempts + 1
        local candX = rng(minX * 0.65, maxX * 0.65)
        local candZ = rng(minZ * 0.65, maxZ * 0.65)
        
        local onCorridor = PathSystem.IsOnPath(candX, candZ, 2.5, activeCfg)
        local onShoulder = PathSystem.IsOnPath(candX, candZ, 8.5, activeCfg)
        if not onCorridor and onShoulder then
            local groundPos, groundNormal, groundMat = findGroundPosition(candX, candZ)
            if groundPos and groundNormal and groundMat and groundMat ~= Enum.Material.Rock then
                local biomeKey = activeBiomeConfig.GetBiome(candX, candZ, groundPos.Y, 10.0)
                if biomeKey ~= "CampsiteSanctuary" and biomeKey ~= "WatchtowerClearing" and biomeKey ~= "LakeWater" and biomeKey ~= "VillageTerrace" then
                    local roll = rng(0, 100)
                    local pCat = "Patch"
                    local pName = "CloverPatch"
                    if roll < 38 then
                        pCat = "Patch"
                        pName = (roll < 20) and "DenseLeafPatch" or "CloverPatch"
                    elseif roll < 68 then
                        pCat = "Flower"
                        pName = (roll < 52) and "WildFlower01" or "Wildflower02"
                    elseif roll < 88 then
                        pCat = "Fern"
                        pName = (roll < 78) and "Fern_Var01" or "FernTallVar01"
                    else
                        pCat = "Shrub"
                        pName = "MountainLaurelBush_Var01"
                    end
                    placeItem(pName, pCat, groundPos, groundNormal)
                end
            end
        end
    end
    
    -- -----------------------------------------------------------------------
    -- PASS 3: Ambient Woodland Floor (Patches, Ferns, Flowers, Debris)
    -- -----------------------------------------------------------------------
    local maxAttempts = targetTotal * 20
    local attempts = 0
    
    while itemCount < targetTotal and attempts < maxAttempts do
        attempts = attempts + 1
        
        local catType = "Patch"
        if itemCount < targetPatches then
            catType = "Patch"
        elseif itemCount < (targetPatches + targetFerns) then
            catType = "Fern"
        elseif itemCount < (targetPatches + targetFerns + targetFlowers) then
            catType = "Flower"
        elseif itemCount < (targetPatches + targetFerns + targetFlowers + targetShrubs) then
            catType = "Shrub"
        elseif itemCount < (targetPatches + targetFerns + targetFlowers + targetShrubs + targetDebris) then
            catType = "Debris"
        elseif itemCount < (targetPatches + targetFerns + targetFlowers + targetShrubs + targetDebris + targetLogs) then
            catType = "Log"
        else
            catType = "Stick"
        end
        
        local candX = rng(minX, maxX)
        local candZ = rng(minZ, maxZ)
        
        local groundPos, groundNormal, groundMat = findGroundPosition(candX, candZ)
        if not groundPos or not groundNormal or not groundMat then
            continue
        end
        
        if groundMat == Enum.Material.Rock or groundMat == Enum.Material.Slate then
            continue
        end
        
        if groundPos.Y > maxElev then
            continue
        end
        
        local slopeAngleDeg = math.deg(math.acos(math.clamp(groundNormal.Y, -1, 1)))
        if slopeAngleDeg > 35.0 then
            continue
        end
        
        local biomeKey = activeBiomeConfig.GetBiome(candX, candZ, groundPos.Y, slopeAngleDeg)
        if biomeKey == "CampsiteSanctuary" 
            or biomeKey == "WatchtowerClearing" 
            or biomeKey == "TraderOutpost" 
            or biomeKey == "GasStationSalvage" 
            or biomeKey == "LakeWater" then
            continue
        end
        
        if PathSystem.IsOnPath(candX, candZ, 2.5, activeCfg) then
            continue
        end
        
        -- Minimum spacing to avoid ugly stacking
        local minItemDist = (catType == "Log") and 16.0 or ((catType == "Shrub") and 8.0 or ((catType == "Fern") and 5.0 or 3.2))
        local tooClose = false
        for _, pos in ipairs(placedPositions) do
            local dx = pos.X - candX
            local dz = pos.Z - candZ
            if (dx * dx + dz * dz) < (minItemDist * minItemDist) then
                tooClose = true
                break
            end
        end
        if tooClose then
            continue
        end
        
        local modelPool: { string } = {}
        if catType == "Patch" then
            modelPool = { "DenseLeafPatch", "CloverPatch" }
        elseif catType == "Fern" then
            modelPool = { "Fern_Var01", "FernTallVar01", "DyingFern01" }
        elseif catType == "Shrub" then
            modelPool = { "MountainLaurelBush_Var01", "RhododendronVar01", "RhododendronVar02" }
        elseif catType == "Flower" then
            modelPool = { "WildFlower01", "Wildflower02", "WildFlower03", "WildFlower04" }
        elseif catType == "Debris" then
            modelPool = { "SmallRock01", "SmallRockGroupVar02", "SmallRockGroupVar03", "SmallRockVar04" }
        elseif catType == "Log" then
            modelPool = { "FallenTree", "FallenTreeMossyVar01", "TreeStump" }
        elseif catType == "Stick" then
            modelPool = { "BranchVar01", "StickVar01", "StickVar03", "StickVar04", "StickVar05", "StickVar06" }
        end
        
        if #modelPool == 0 then
            continue
        end
        
        local chosenName = modelPool[math.floor(rng(1, #modelPool + 0.99))]
        placeItem(chosenName, catType, groundPos, groundNormal)
        
        if itemCount % 80 == 0 then
            task.wait()
        end
    end
    
    local elapsed = math.round((os.clock() - startTime) * 100) / 100
    print(string.format("[GroundCover V8] Clean tree-pack ground cover placed %d items (%d wood items) in %.2f seconds.", itemCount, logStickCount, elapsed))
end

return GroundCover
