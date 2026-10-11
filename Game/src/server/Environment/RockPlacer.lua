--!strict
--[[
    RockPlacer.lua
    Algorithmic rock outcrop and scattered boulder generator.
    Developed for "Don't Let the Fire Die" (Fluenosity Studio).
    
    Features:
    - Multi-scale rock distribution (small stones, medium mossy rocks, massive ridge boulders)
    - Preferential placement on sloping terrain and woodland margins
    - Surface embedding (rocks seat naturally 20-30% into terrain rather than sitting on top)
    - Full template support with procedural geometric fallback
]]

local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local envConfigScript = ReplicatedStorage:WaitForChild("FluenosityShared"):WaitForChild("EnvironmentConfig")
local okConfig, freshConfig = pcall(function() return require(envConfigScript:Clone()) end)
local EnvironmentConfig = (okConfig and freshConfig) or require(envConfigScript)

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

local function findGroundPosition(x: number, z: number): (Vector3?, Vector3?)
    local rayOrigin = Vector3.new(x, 150, z)
    local rayDir = Vector3.new(0, -250, 0)
    
    local rayParams = RaycastParams.new()
    rayParams.FilterType = Enum.RaycastFilterType.Include
    rayParams.FilterDescendantsInstances = { Workspace.Terrain }
    
    local hit = Workspace:Raycast(rayOrigin, rayDir, rayParams)
    if hit then
        return hit.Position, hit.Normal
    end
    return nil, nil
end

local function buildProceduralRock(
    sizeTier: string,
    rockSeed: number,
    parentFolder: Instance
): Model
    local rng = createRng(rockSeed)
    local cfg = EnvironmentConfig.ROCKS
    local sizeCfg = cfg.Sizes[sizeTier] or cfg.Sizes.Medium
    
    local rockModel = Instance.new("Model")
    rockModel.Name = "Rock_" .. sizeTier .. "_" .. tostring(rockSeed)
    
    -- Pick material & natural weathered tint
    local mat = cfg.Materials[math.floor(rng(1, #cfg.Materials + 0.99))]
    local baseColor = cfg.Colors[math.floor(rng(1, #cfg.Colors + 0.99))]
    local color = Color3.new(
        math.clamp(baseColor.R + rng(-0.03, 0.03), 0, 1),
        math.clamp(baseColor.G + rng(-0.03, 0.03), 0, 1),
        math.clamp(baseColor.B + rng(-0.03, 0.03), 0, 1)
    )
    
    -- Main core boulder part
    local scale = Vector3.new(
        rng(sizeCfg.ScaleMin.X, sizeCfg.ScaleMax.X),
        rng(sizeCfg.ScaleMin.Y, sizeCfg.ScaleMax.Y),
        rng(sizeCfg.ScaleMin.Z, sizeCfg.ScaleMax.Z)
    )
    
    local corePart = Instance.new("Part")
    corePart.Name = "RockCore"
    corePart.Material = mat
    corePart.Color = color
    corePart.Size = scale
    corePart.Anchored = true
    corePart.CanCollide = true
    corePart.CastShadow = true
    corePart.Parent = rockModel
    rockModel.PrimaryPart = corePart
    
    -- Add 1-2 faceted secondary lobes to avoid simple rectangular boxes
    if sizeTier ~= "Small" then
        local subLobe = Instance.new("Part")
        subLobe.Name = "RockFacet"
        subLobe.Material = mat
        subLobe.Color = color
        subLobe.Size = scale * rng(0.6, 0.85)
        subLobe.Anchored = true
        subLobe.CanCollide = true
        subLobe.CastShadow = true
        
        local offset = Vector3.new(rng(-scale.X * 0.25, scale.X * 0.25), rng(-scale.Y * 0.15, scale.Y * 0.1), rng(-scale.Z * 0.25, scale.Z * 0.25))
        local rot = CFrame.Angles(rng(-0.4, 0.4), rng(-1.5, 1.5), rng(-0.4, 0.4))
        subLobe.CFrame = CFrame.new(offset) * rot
        subLobe.Parent = rockModel
    end
    
    rockModel.Parent = parentFolder
    return rockModel
end

function RockPlacer.Populate(rocksFolder: Folder, injectedCfg: any?, injectedPathSystem: any?)
    local startTime = os.clock()
    print("[RockPlacer] Placing boulders and natural rock outcrops...")
    
    if injectedPathSystem then
        PathSystem = injectedPathSystem
    end
    
    local activeCfg = injectedCfg or EnvironmentConfig
    local cfg = (activeCfg and activeCfg.ROCKS) or {}
    local rng = createRng(((activeCfg and activeCfg.SEED) or 133742) + 999)
    
    local worldSize = (activeCfg and activeCfg.WORLD_SIZE) or Vector2.new(500, 500)
    local halfX = worldSize.X / 2 - 25
    local halfZ = worldSize.Y / 2 - 25
    local campRadius = (activeCfg and activeCfg.CAMP_EXCLUSION_RADIUS) or 76.0
    local totalBudget = cfg.TotalRockBudget or 55
    local minRockDist = cfg.MinRockDistance or 14.0
    
    local placedPositions: { Vector3 } = {}
    local rockCount = 0
    local maxAttempts = totalBudget * 12
    local attempts = 0
    
    while rockCount < totalBudget and attempts < maxAttempts do
        attempts = attempts + 1
        
        local candX = rng(-halfX, halfX)
        local candZ = rng(-halfZ, halfZ)
        local distFromCenter = math.sqrt(candX * candX + candZ * candZ)
        
        if distFromCenter < campRadius or distFromCenter > 200.0 then
            continue
        end
        
        local rockClearance = (activeCfg.PATHS and activeCfg.PATHS.RockClearance) or 1.5
        if PathSystem.IsOnPath(candX, candZ, rockClearance, activeCfg) then
            continue
        end
        
        -- Spacing check
        local tooClose = false
        for _, pos in ipairs(placedPositions) do
            local dx = pos.X - candX
            local dz = pos.Z - candZ
            if (dx * dx + dz * dz) < (minRockDist * minRockDist) then
                tooClose = true
                break
            end
        end
        if tooClose then
            continue
        end
        
        local groundPos, groundNormal = findGroundPosition(candX, candZ)
        if not groundPos or not groundNormal or groundPos.Y > 16.0 or groundNormal.Y < 0.85 then
            continue
        end
        
        -- Size distribution (Small 50%, Medium 35%, Large 15%)
        local roll = rng(1, 100)
        local sizeTier = "Small"
        if roll > 85 then
            sizeTier = "LargeBoulder"
        elseif roll > 50 then
            sizeTier = "Medium"
        end
        
        -- Check for template model in ReplicatedStorage
        local templatesFolder = ReplicatedStorage:FindFirstChild("EnvironmentTemplates")
        local rockInstance: Model? = nil
        
        if templatesFolder then
            local meshTemplate = templatesFolder:FindFirstChild("Rock_" .. sizeTier)
                or templatesFolder:FindFirstChild("Rock")
                or templatesFolder:FindFirstChild("Boulder")
                
            if meshTemplate and meshTemplate:IsA("Model") then
                rockInstance = meshTemplate:Clone()
                local scaleFactor = rng(0.8, 1.3)
                rockInstance:ScaleTo(scaleFactor)
                rockInstance.Parent = rocksFolder
            end
        end
        
        if not rockInstance then
            local rockSeed = math.floor(candX * 500 + candZ + attempts)
            rockInstance = buildProceduralRock(sizeTier, rockSeed, rocksFolder)
        end
        
        if rockInstance and rockInstance.PrimaryPart then
            -- Embed partially into terrain (seat by 25% of height)
            local embedDepth = rockInstance.PrimaryPart.Size.Y * 0.28
            local yawAngle = rng(-math.pi, math.pi)
            local pitchAngle = rng(-0.2, 0.2)
            local rollAngle = rng(-0.2, 0.2)
            
            local targetCFrame = CFrame.new(groundPos - Vector3.new(0, embedDepth, 0))
                * CFrame.Angles(pitchAngle, yawAngle, rollAngle)
                
            rockInstance:PivotTo(targetCFrame)
            table.insert(placedPositions, groundPos)
            rockCount = rockCount + 1
        end
    end
    
    local elapsed = math.round((os.clock() - startTime) * 100) / 100
    print(string.format("[RockPlacer] Successfully placed %d rocks in %.2f seconds.", rockCount, elapsed))
end

return RockPlacer
