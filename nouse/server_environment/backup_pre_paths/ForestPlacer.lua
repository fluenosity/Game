-- BACKUP COPY OF ForestPlacer.lua (Pre-Paths Implementation)
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local envConfigScript = ReplicatedStorage:WaitForChild("FluenosityShared"):WaitForChild("EnvironmentConfig")
local okConfig, freshConfig = pcall(function() return require(envConfigScript:Clone()) end)
local EnvironmentConfig = (okConfig and freshConfig) or require(envConfigScript)
local envFolder = script.Parent or game:GetService("ServerScriptService"):WaitForChild("FluenosityServer"):WaitForChild("Environment")
local TreeFactory = require(envFolder:WaitForChild("TreeFactory"))

local ForestPlacer = {}

local function createRng(seed: number)
    local state = seed
    return function(min: number?, max: number?): number
        state = (state * 1664525 + 1013904223) % 4294967296
        local unit = state / 4294967296
        if min and max then return min + unit * (max - min)
        elseif min then return unit * min end
        return unit
    end
end

local function pickSpecies(rng: (number?, number?) -> number): string
    local roll = rng(1, 100)
    if roll <= 40 then return "TallPine"
    elseif roll <= 75 then return "MountainSpruce"
    elseif roll <= 90 then return "AlpineFir"
    else return "DeadPineSnag" end
end

local function findGroundPosition(x: number, z: number): (Vector3?, Vector3?)
    local rayOrigin = Vector3.new(x, 220, z)
    local rayDir = Vector3.new(0, -350, 0)
    local rayParams = RaycastParams.new()
    rayParams.FilterType = Enum.RaycastFilterType.Include
    rayParams.FilterDescendantsInstances = { Workspace.Terrain }
    local hit = Workspace:Raycast(rayOrigin, rayDir, rayParams)
    if hit then return hit.Position, hit.Normal end
    return nil, nil
end

local function getModelBottomY(model: Model): number
    local minY = math.huge
    for _, part in ipairs(model:GetDescendants()) do
        if part:IsA("BasePart") and (part.Transparency < 1 or part.CanCollide) then
            local cf = part.CFrame
            local size = part.Size
            local hx, hy, hz = size.X * 0.5, size.Y * 0.5, size.Z * 0.5
            for sx = -1, 1, 2 do
                for sy = -1, 1, 2 do
                    for sz = -1, 1, 2 do
                        local cornerY = cf:PointToWorldSpace(Vector3.new(sx * hx, sy * hy, sz * hz)).Y
                        if cornerY < minY then minY = cornerY end
                    end
                end
            end
        end
    end
    return minY
end

local function groundModelPrecisely(model: Model, groundPos: Vector3, yawAngle: number)
    model:PivotTo(CFrame.new(groundPos) * CFrame.Angles(0, yawAngle, 0))
    local lowestY = getModelBottomY(model)
    if lowestY == math.huge then return end
    local deltaY = (groundPos.Y - 0.2) - lowestY
    model:PivotTo(model:GetPivot() + Vector3.new(0, deltaY, 0))
end

function ForestPlacer.Populate(treesFolder: Folder, injectedCfg: any?)
    local startTime = os.clock()
    print("[ForestPlacer] Distributing heavy forest population (350 trees target)...")
    local activeCfg = injectedCfg or EnvironmentConfig
    local cfg = (activeCfg and activeCfg.TREES) or {}
    local rng = createRng((activeCfg and activeCfg.SEED) or 133742 + 888)
    local maxPlayableBudget = cfg.MaxPlayableTreeBudget or (cfg :: any).PlayableTreeBudget or (cfg :: any).MaxTrees or 320
    local backdropBudget = cfg.BackdropTreeBudget or 80
    local minTreeDist = cfg.MinTreeDistance or 8.5
    local maxSlope = cfg.MaxSlopeAngle or 42.0
    local campRadius = (activeCfg and activeCfg.CAMP_EXCLUSION_RADIUS) or 76.0
    local placedPositions: { Vector3 } = {}
    local treeCount = 0
    local basinRadius = 188.0
    local maxAttempts = maxPlayableBudget * 18
    local attempts = 0
    while treeCount < maxPlayableBudget and attempts < maxAttempts do
        attempts = attempts + 1
        local angle = rng(0, math.pi * 2)
        local dist = math.sqrt(rng(campRadius * campRadius, basinRadius * basinRadius))
        local candX = math.cos(angle) * dist
        local candZ = math.sin(angle) * dist
        if math.sqrt(candX * candX + candZ * candZ) < campRadius then continue end
        local gladeNoise = math.noise(candX * 0.016, candZ * 0.016, 456)
        if gladeNoise < -0.32 then continue end
        local tooClose = false
        for _, pos in ipairs(placedPositions) do
            local dx = pos.X - candX
            local dz = pos.Z - candZ
            if (dx * dx + dz * dz) < (minTreeDist * minTreeDist) then
                tooClose = true
                break
            end
        end
        if tooClose then continue end
        local groundPos, groundNormal = findGroundPosition(candX, candZ)
        if not groundPos or not groundNormal then continue end
        local slopeAngleDeg = math.deg(math.acos(math.clamp(groundNormal.Y, -1, 1)))
        if slopeAngleDeg > maxSlope then continue end
        local species = pickSpecies(rng)
        local treeSeed = math.floor(candX * 1000 + candZ + attempts)
        local treeInstance = TreeFactory.CreateTree(species, treeSeed, treesFolder)
        if treeInstance then
            local yawAngle = rng(-math.pi, math.pi)
            groundModelPrecisely(treeInstance, groundPos, yawAngle)
            table.insert(placedPositions, groundPos)
            treeCount = treeCount + 1
        end
    end
    local backdropCount = 0
    local bAttempts = 0
    while backdropCount < backdropBudget and bAttempts < (backdropBudget * 10) do
        bAttempts = bAttempts + 1
        local angle = rng(0, math.pi * 2)
        local dist = rng(185.0, 240.0)
        local candX = math.cos(angle) * dist
        local candZ = math.sin(angle) * dist
        local groundPos, groundNormal = findGroundPosition(candX, candZ)
        if not groundPos or not groundNormal then continue end
        local species = (rng(1, 100) > 40) and "TallPine" or "MountainSpruce"
        local treeSeed = math.floor(candX * 500 + candZ + bAttempts)
        local treeInstance = TreeFactory.CreateTree(species, treeSeed, treesFolder)
        if treeInstance then
            local yawAngle = rng(-math.pi, math.pi)
            groundModelPrecisely(treeInstance, groundPos, yawAngle)
            backdropCount = backdropCount + 1
            treeCount = treeCount + 1
        end
    end
    local elapsed = math.round((os.clock() - startTime) * 100) / 100
    print(string.format("[ForestPlacer] Successfully placed %d total trees (%d playable + %d backdrop silhouettes) seated FLUSH on terrain in %.2f seconds.", treeCount, treeCount - backdropCount, backdropCount, elapsed))
end

return ForestPlacer
