--!strict
--[[
    RockPlacer.lua
    Asset-Driven Boulder & Outcrop Placement Engine (World Gen V4).
    Developed for "Don't Let the Fire Die" (Fluenosity Studio).
    
    V4 Architecture:
    - Full-Map Distribution: Spreads across the entire 820x860 world extent (X: -415..415, Z: -455..410)
    - 100% Authored Mesh Models from Tree-Pack:
      * Large: LargeBoulder_Var01, LargeBoulder_Var02
      * Medium: MediumBoulderVar01, MediumMossBoulder01
      * Small: SmallRock01, SmallRockGroupVar02, SmallRockGroupVar03, SmallRockVar04
    - Biome-Aware Natural Geology:
      * Highlands & Slopes: Heavy concentration of large boulders & rocky ridges
      * Damp Lowlands & Lake Shore: Moss-covered boulders (MediumMossBoulder01) & river stones
      * Open Woodland: Scattered weathered stones & low outcrops
    - Surface Embedding:
      * Large/Medium boulders embedded 18-22% into terrain (never floating on top)
    - Full Safeguards: Zero rocks on walking trails, South camp, Watchtower, or inside Village.
]]

local Workspace = game:GetService("Workspace")
local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local sharedFolder = ReplicatedStorage:WaitForChild("FluenosityShared")
local envConfigScript = sharedFolder:WaitForChild("EnvironmentConfig")
local okConfig, freshConfig = pcall(function() return require(envConfigScript:Clone()) end)
local EnvironmentConfig = (okConfig and freshConfig) or require(envConfigScript)

local BiomeConfig = require(sharedFolder:WaitForChild("BiomeConfig"))

local envFolder = script.Parent or game:GetService("ServerScriptService"):WaitForChild("FluenosityServer"):WaitForChild("Environment")
local PathSystem = require(envFolder:WaitForChild("PathSystem"))

local RockPlacer = {}

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

-- Cache rock templates
local function loadRockTemplates(assetLib: Folder): { [string]: Model }
    local templates: { [string]: Model } = {}
    local cats = { "Rocks_Large", "Rocks_Medium", "Rocks_Small" }
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

-- Raycast down to find ground surface
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

-- Embed model with specific depth into terrain
local function placeRockPrecisely(model: Model, groundPos: Vector3, yawAngle: number, pitchAngle: number, rollAngle: number, embedDepth: number)
    local _, sz = model:GetBoundingBox()
    local r = math.max(sz.X, sz.Z) * 0.4
    local rp = RaycastParams.new()
    rp.FilterType = Enum.RaycastFilterType.Include
    rp.FilterDescendantsInstances = { Workspace.Terrain }
    
    local minY = groundPos.Y
    for _, off in ipairs({ Vector2.new(r, 0), Vector2.new(-r, 0), Vector2.new(0, r), Vector2.new(0, -r) }) do
        local h = Workspace:Raycast(Vector3.new(groundPos.X + off.X, 220, groundPos.Z + off.Y), Vector3.new(0, -350, 0), rp)
        if h and h.Position.Y < minY then
            minY = h.Position.Y
        end
    end
    local safeY = math.min(groundPos.Y, (groundPos.Y * 0.4) + (minY * 0.6))
    
    model:PivotTo(CFrame.new(Vector3.new(groundPos.X, safeY, groundPos.Z)) * CFrame.Angles(pitchAngle, yawAngle, rollAngle))
    local lowestY = getModelBottomY(model)
    if lowestY == math.huge then return end
    local deltaY = (safeY - embedDepth) - lowestY
    model:PivotTo(model:GetPivot() + Vector3.new(0, deltaY, 0))
end

function RockPlacer.Populate(rocksFolder: Folder, injectedCfg: any?, injectedPathSystem: any?)
    local startTime = os.clock()
    print("[RockPlacer V4] Populating authored mesh boulders across entire map...")
    
    local assetLib = getAssetLibrary()
    if not assetLib then
        warn("[RockPlacer V4] ERROR: DontLetTheFireDieAssets.Environment not found!")
        return
    end
    
    local templates = loadRockTemplates(assetLib)
    
    if injectedPathSystem then
        PathSystem = injectedPathSystem
    end
    
    local freshBiomeScript = sharedFolder:WaitForChild("BiomeConfig") :: ModuleScript
    local okB, freshB = pcall(function() return require(freshBiomeScript:Clone()) end)
    local activeBiomeConfig = (okB and freshB) or BiomeConfig
    local activePreset = (activeBiomeConfig.GetActivePreset and activeBiomeConfig.GetActivePreset()) or {}

    local activeCfg = injectedCfg or EnvironmentConfig
    local rng = createRng((activeCfg and activeCfg.SEED) or 133742 + 999)
    
    local placedPositions: { Vector3 } = {}
    local rockCount = 0
    
    -- Targets distributed across full map (V7 Boulder & Outcrop detailing)
    local targetLarge = 25
    local targetMedium = 50
    local targetSmall = 75
    local targetTotal = targetLarge + targetMedium + targetSmall
    
    local minX = activePreset.Bounds and activePreset.Bounds.MinX or -500.0
    local maxX = activePreset.Bounds and activePreset.Bounds.MaxX or 500.0
    local minZ = activePreset.Bounds and activePreset.Bounds.MinZ or -545.0
    local maxZ = activePreset.Bounds and activePreset.Bounds.MaxZ or 545.0
    local maxElev = activePreset.MaxElevation or 45.0
    
    local maxAttempts = targetTotal * 35
    local attempts = 0
    
    while rockCount < targetTotal and attempts < maxAttempts do
        attempts = attempts + 1
        
        local tier = "Small"
        if rockCount < targetLarge then
            tier = "Large"
        elseif rockCount < (targetLarge + targetMedium) then
            tier = "Medium"
        else
            tier = "Small"
        end
        
        local candX = rng(minX, maxX)
        local candZ = rng(minZ, maxZ)
        
        local groundPos, groundNormal, groundMat = findGroundPosition(candX, candZ)
        if not groundPos or not groundNormal or not groundMat then
            continue
        end
        
        if groundPos.Y > maxElev then
            continue
        end
        
        local slopeAngleDeg = math.deg(math.acos(math.clamp(groundNormal.Y, -1, 1)))
        
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
        
        -- Trail corridor check: keep walking trails clear
        local rockClearance = (activeCfg.PATHS and activeCfg.PATHS.RockClearance) or 5.0
        if PathSystem.IsOnPath(candX, candZ, rockClearance, activeCfg) then
            continue
        end
        
        -- Minimum spacing
        local minDist = (tier == "Large") and 30.0 or ((tier == "Medium") and 18.0 or 10.0)
        local tooClose = false
        for _, pos in ipairs(placedPositions) do
            local dx = pos.X - candX
            local dz = pos.Z - candZ
            if (dx * dx + dz * dz) < (minDist * minDist) then
                tooClose = true
                break
            end
        end
        if tooClose then
            continue
        end
        
        local biomeDef = BiomeConfig.BIOMES[biomeKey]
        local rockList: { string } = {}
        if biomeDef and biomeDef.Rocks then
            rockList = biomeDef.Rocks[tier] or {}
        end
        
        if #rockList == 0 then
            if tier == "Large" then
                rockList = { "LargeBoulder_Var01", "LargeBoulder_Var02" }
            elseif tier == "Medium" then
                rockList = { "MediumBoulderVar01", "MediumMossBoulder01" }
            else
                rockList = { "SmallRock01", "SmallRockGroupVar02", "SmallRockGroupVar03", "SmallRockVar04" }
            end
        end
        
        local chosenName = rockList[math.floor(rng(1, #rockList + 0.99))]
        local template = templates[chosenName]
        if not template then continue end
        
        local rockInstance = template:Clone()
        rockInstance.Name = chosenName
        
        local scaleFactor = (tier == "Large") and rng(0.35, 0.49) or ((tier == "Medium") and rng(0.42, 0.60) or rng(0.56, 0.80))
        pcall(function()
            rockInstance:ScaleTo(rockInstance:GetScale() * scaleFactor)
        end)
        
        for _, desc in ipairs(rockInstance:GetDescendants()) do
            if desc:IsA("BasePart") then
                desc.Anchored = true
                desc.CastShadow = true
                if tier == "Small" then
                    desc.CanCollide = false
                    desc.CanTouch = false
                    desc.CanQuery = false
                else
                    desc.CanCollide = true
                    desc.CanTouch = true
                    desc.CanQuery = true
                end
            end
        end
        
        local cf, sz = rockInstance:GetBoundingBox()
        local embedDepth = (tier == "Large") and (sz.Y * 0.20) or ((tier == "Medium") and (sz.Y * 0.18) or 0.08)
        
        local yawAngle = rng(-math.pi, math.pi)
        local pitchAngle = (tier == "Small") and 0 or rng(-0.12, 0.12)
        local rollAngle = (tier == "Small") and 0 or rng(-0.12, 0.12)
        
        placeRockPrecisely(rockInstance, groundPos, yawAngle, pitchAngle, rollAngle, embedDepth)
        
        rockInstance.Parent = rocksFolder
        table.insert(placedPositions, groundPos)
        rockCount = rockCount + 1
        
        if rockCount % 25 == 0 then
            task.wait()
        end
    end
    
    local elapsed = math.round((os.clock() - startTime) * 100) / 100
    print(string.format("[RockPlacer V4] Successfully placed %d authored boulders across entire map in %.2f seconds.", rockCount, elapsed))
end

return RockPlacer
