--!strict
--[[
    GroundCover.lua
    Asset-Driven Forest Floor Ecology & Ground Detailing Engine (World Gen V4).
    Developed for "Don't Let the Fire Die" (Fluenosity Studio).
    
    V4 Architecture:
    - Full-Map Distribution: Spreads across the entire 820x860 open world extent (X: -415..415, Z: -455..410)
    - 100% Authored Mesh Assets from Tree-Pack (0 Primitives, 0 Old Yasu assets):
      * Ferns: FernTallVar01, Fern_Var01, DyingFern01
      * Shrubs: MountainLaurelBush_Var01, RhododendronVar01, RhododendronVar02
      * Wildflowers: WildFlower01, Wildflower02, WildFlower03, WildFlower04
      * Ground Patches: DenseLeafPatch, CloverPatch (Surface normal-aligned)
      * Deadwood Logs: FallenTree, FallenTreeMossyVar01 (Tagged "WoodPile" for foraging)
      * Stumps: TreeStump (Tagged "WoodPile")
      * Foraging Sticks: BranchVar01, StickVar01..06 (Tagged "WoodPile")
    - Zero Physics Drag: Foliage, flowers, and patches have CanCollide=false, CanQuery=false
    - Natural Biome Ecology:
      * Dense Conifer: Rich fern understory, fallen logs, leaf litter, deadwood sticks
      * Open Woodland: Sunny wildflower glades, clover patches, shrubs
      * Damp Lowlands: Mossy logs, tall ferns, dying ferns, decaying wood
      * Lake Shore: Driftwood branches, shoreline reeds/ferns, small stones
    - Full Safeguards: Zero clutter on walking trails, South camp, Watchtower, or inside Village.
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

-- Cache all ground cover templates
local function loadGroundCoverTemplates(assetLib: Folder): { [string]: Model }
    local templates: { [string]: Model } = {}
    local cats = {
        "Foliage_Ferns",
        "Foliage_Shrubs",
        "Foliage_Flowers",
        "Foliage_GroundPatches",
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

-- Mathematical grounding helper
local function groundModelPrecisely(model: Model, groundPos: Vector3, yawAngle: number, sinkY: number?, normal: Vector3?)
    if normal and math.abs(normal.Y) > 0.6 then
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
    local sink = sinkY or 0.15
    local deltaY = (groundPos.Y - sink) - lowestY
    model:PivotTo(model:GetPivot() + Vector3.new(0, deltaY, 0))
end

function GroundCover.Populate(groundFolder: Folder, injectedCfg: any?, injectedPathSystem: any?)
    local startTime = os.clock()
    print("[GroundCover V4] Populating asset-driven ground ecology across entire map...")
    
    local assetLib = getAssetLibrary()
    if not assetLib then
        warn("[GroundCover V4] ERROR: DontLetTheFireDieAssets.Environment not found!")
        return
    end
    
    local templates = loadGroundCoverTemplates(assetLib)
    
    if injectedPathSystem then
        PathSystem = injectedPathSystem
    end
    
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
    
    local foliageFolder = getSubfolder("Foliage")
    local deadwoodFolder = getSubfolder("Deadwood")
    local patchesFolder = getSubfolder("Patches")
    
    local placedPositions: { Vector3 } = {}
    local itemCount = 0
    local logStickCount = 0
    
    -- Category budgets across full map (Subtle natural detailing)
    local targetFerns = 45
    local targetShrubs = 25
    local targetFlowers = 35
    local targetPatches = 40
    local targetLogs = 18
    local targetSticks = 50
    local targetTotal = targetFerns + targetShrubs + targetFlowers + targetPatches + targetLogs + targetSticks
    
    local minX, maxX = -415.0, 415.0
    local minZ, maxZ = -455.0, 410.0
    
    local maxAttempts = targetTotal * 25
    local attempts = 0
    
    while itemCount < targetTotal and attempts < maxAttempts do
        attempts = attempts + 1
        
        local catType = "Fern"
        if itemCount < targetFerns then
            catType = "Fern"
        elseif itemCount < (targetFerns + targetShrubs) then
            catType = "Shrub"
        elseif itemCount < (targetFerns + targetShrubs + targetFlowers) then
            catType = "Flower"
        elseif itemCount < (targetFerns + targetShrubs + targetFlowers + targetPatches) then
            catType = "Patch"
        elseif itemCount < (targetFerns + targetShrubs + targetFlowers + targetPatches + targetLogs) then
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
        
        if groundPos.Y > 26.0 then
            continue
        end
        
        local slopeAngleDeg = math.deg(math.acos(math.clamp(groundNormal.Y, -1, 1)))
        if slopeAngleDeg > 32.0 then
            continue
        end
        
        -- Query Biome
        local biomeKey = BiomeConfig.GetBiome(candX, candZ, groundPos.Y, slopeAngleDeg)
        if biomeKey == "CampsiteSanctuary" 
            or biomeKey == "WatchtowerClearing" 
            or biomeKey == "VillageTerrace" 
            or biomeKey == "TraderOutpost" 
            or biomeKey == "GasStationSalvage" 
            or biomeKey == "LakeWater" then
            continue
        end
        
        -- Trail corridor check
        local groundClearance = (activeCfg.PATHS and activeCfg.PATHS.GroundCoverClearance) or 3.5
        if PathSystem.IsOnPath(candX, candZ, groundClearance, activeCfg) then
            continue
        end
        
        -- Spacing check
        local minItemDist = (catType == "Log") and 24.0 or ((catType == "Shrub") and 14.0 or 8.0)
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
        
        local biomeDef = BiomeConfig.BIOMES[biomeKey]
        local modelPool: { string } = {}
        
        if catType == "Fern" then
            modelPool = (biomeDef and biomeDef.GroundCover and biomeDef.GroundCover.Ferns) or { "Fern_Var01", "FernTallVar01", "DyingFern01" }
        elseif catType == "Shrub" then
            modelPool = (biomeDef and biomeDef.GroundCover and biomeDef.GroundCover.Shrubs) or { "MountainLaurelBush_Var01", "RhododendronVar01", "RhododendronVar02" }
        elseif catType == "Flower" then
            modelPool = (biomeDef and biomeDef.GroundCover and biomeDef.GroundCover.Flowers) or { "WildFlower01", "Wildflower02", "WildFlower03", "WildFlower04" }
        elseif catType == "Patch" then
            modelPool = (biomeDef and biomeDef.GroundCover and biomeDef.GroundCover.Patches) or { "DenseLeafPatch", "CloverPatch" }
        elseif catType == "Log" then
            modelPool = (biomeDef and biomeDef.GroundCover and biomeDef.GroundCover.Deadwood) or { "FallenTree", "FallenTreeMossyVar01", "TreeStump" }
        elseif catType == "Stick" then
            modelPool = (biomeDef and biomeDef.GroundCover and biomeDef.GroundCover.Sticks) or { "BranchVar01", "StickVar01", "StickVar03", "StickVar04", "StickVar05", "StickVar06" }
        end
        
        if #modelPool == 0 then
            continue
        end
        
        local chosenName = modelPool[math.floor(rng(1, #modelPool + 0.99))]
        local template = templates[chosenName]
        if not template then continue end
        
        local instance = template:Clone()
        instance.Name = chosenName
        
        local targetParent = foliageFolder
        if catType == "Log" or catType == "Stick" then
            targetParent = deadwoodFolder
        elseif catType == "Patch" then
            targetParent = patchesFolder
        end
        
        local scaleFactor = 1.0
        if catType == "Fern" or catType == "Shrub" then
            scaleFactor = rng(0.85, 1.20)
        elseif catType == "Flower" then
            scaleFactor = rng(0.90, 1.30)
        elseif catType == "Patch" then
            scaleFactor = rng(0.95, 1.40)
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
                    desc.CastShadow = true
                else
                    desc.CanCollide = false
                    desc.CanTouch = false
                    desc.CanQuery = false
                    desc.CastShadow = (catType == "Shrub" or catType == "Fern")
                end
            end
        end
        
        if catType == "Log" or catType == "Stick" or chosenName == "TreeStump" then
            CollectionService:AddTag(instance, "WoodPile")
            logStickCount = logStickCount + 1
        end
        
        local yawAngle = rng(-math.pi, math.pi)
        local cf, sz = instance:GetBoundingBox()
        local sink = 0.12
        local alignNormal: Vector3? = nil
        
        if catType == "Patch" then
            sink = 0.04
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
            sink = 0.18
        end
        
        groundModelPrecisely(instance, groundPos, yawAngle, sink, alignNormal)
        
        instance.Parent = targetParent
        table.insert(placedPositions, groundPos)
        itemCount = itemCount + 1
        
        if itemCount % 30 == 0 then
            task.wait()
        end
    end
    
    local elapsed = math.round((os.clock() - startTime) * 100) / 100
    print(string.format("[GroundCover V4] Successfully placed %d ground ecology assets (%d harvestable wood items) across entire map in %.2f seconds.", itemCount, logStickCount, elapsed))
end

return GroundCover
