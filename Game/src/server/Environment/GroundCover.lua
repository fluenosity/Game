--!strict
--[[
    GroundCover.lua
    Procedural Forest Floor Detailing V3 (Realistic Engine).
    Developed for "Don't Let the Fire Die" (Fluenosity Studio).
    
    V3 Architecture:
    - Zero Primitive Box Slats: Banishes crude rectangular block parts.
    - Native Terrain 3D Grass Priority: Leverages Roblox's native animated 3D grass on Grass terrain.
    - Template Mesh Foliage: If Creator Store foliage meshes exist in ReplicatedStorage.EnvironmentTemplates,
      they are utilized; otherwise, crude block-part mockups are strictly rejected.
    - Fallen Logs & Roots: Completely disabled per user request (Zero log models spawned).
    - Embedded Forest Stones: Low-profile rock wedges seated 50% into the earth.
    - Clean Stone Mountains: Strictly 0 ground cover items on the outer mountain boundary or stone cliffs.
    - Zero Physics Overhead: CanCollide = false, CanTouch = false, CanQuery = false, CastShadow = false.
]]

local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local envConfigScript = ReplicatedStorage:WaitForChild("FluenosityShared"):WaitForChild("EnvironmentConfig")
local okConfig, freshConfig = pcall(function() return require(envConfigScript:Clone()) end)
local EnvironmentConfig = (okConfig and freshConfig) or require(envConfigScript)

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

-- Raycast ground query returning position, normal, and hit material
local function findGroundPosition(x: number, z: number): (Vector3?, Vector3?, Enum.Material?)
    local rayOrigin = Vector3.new(x, 150, z)
    local rayDir = Vector3.new(0, -250, 0)
    
    local rayParams = RaycastParams.new()
    rayParams.FilterType = Enum.RaycastFilterType.Include
    rayParams.FilterDescendantsInstances = { Workspace.Terrain }
    
    local hit = Workspace:Raycast(rayOrigin, rayDir, rayParams)
    if hit then
        return hit.Position, hit.Normal, hit.Material
    end
    return nil, nil, nil
end

-- ---------------------------------------------------------------------------
-- REALISTIC ASSET BUILDERS
-- ---------------------------------------------------------------------------

-- 1. Embedded Natural Stone Wedge (Seated 50% into earth)
local function buildEmbeddedPebble(seed: number, parentFolder: Instance, activeCfg: any): Model
    local rng = createRng(seed)
    local model = Instance.new("Model")
    model.Name = "ForestStone_" .. tostring(seed)
    
    local gCfg = activeCfg.GROUND_COVER or {}
    local pColors = gCfg.PebbleColors or {
        Color3.fromRGB(72, 70, 68),
        Color3.fromRGB(86, 82, 78),
        Color3.fromRGB(60, 58, 56),
    }
    local baseColor = pColors[math.floor(rng(1, #pColors + 0.99))]
    
    local sx = rng(1.0, 2.4)
    local sy = rng(0.5, 1.2)
    local sz = rng(0.9, 2.0)
    
    local pebble = Instance.new("Part")
    pebble.Name = "StoneCore"
    pebble.Material = (rng() < 0.5) and Enum.Material.Rock or Enum.Material.Basalt
    pebble.Color = baseColor
    pebble.Size = Vector3.new(sx, sy, sz)
    pebble.Anchored = true
    pebble.CanCollide = false
    pebble.CanTouch = false
    pebble.CanQuery = false
    pebble.CastShadow = false
    pebble.CFrame = CFrame.Angles(rng(-0.15, 0.15), rng(-math.pi, math.pi), rng(-0.15, 0.15))
    pebble.Parent = model
    
    model.PrimaryPart = pebble
    model.Parent = parentFolder
    return model
end





-- ---------------------------------------------------------------------------
-- PUBLIC EXECUTION API
-- ---------------------------------------------------------------------------
function GroundCover.Populate(folder: Folder, injectedCfg: any?, injectedPathSystem: any?)
    local startTime = os.clock()
    print("[GroundCover] Populating realistic forest floor detailing (0 primitive slats, 0 border clutter)...")
    
    if injectedPathSystem then
        PathSystem = injectedPathSystem
    end
    
    local activeCfg = injectedCfg or EnvironmentConfig
    local cfg = (activeCfg and activeCfg.GROUND_COVER) or {}
    local seed = (activeCfg and activeCfg.SEED) or 133742
    local rng = createRng(seed + 999)
    
    local campRadius = (activeCfg and activeCfg.CAMP_EXCLUSION_RADIUS) or 50.0
    -- Basin boundary: keeps detailing inside the expanded forest, strictly off stone mountains
    local maxBasinRadius = 195.0
    
    local function getSubfolder(name: string): Folder
        local sf = folder:FindFirstChild(name)
        if not sf then
            sf = Instance.new("Folder")
            sf.Name = name
            sf.Parent = folder
        end
        return sf :: Folder
    end
    
    -- Remove any legacy/stale Logs or Roots folders if they exist
    local staleLogs = folder:FindFirstChild("Logs")
    if staleLogs then
        staleLogs:Destroy()
    end
    local staleRoots = folder:FindFirstChild("Roots")
    if staleRoots then
        staleRoots:Destroy()
    end
    
    local foliageFolder = getSubfolder("Foliage")
    local stonesFolder = getSubfolder("Stones")
    
    -- Check for realistic external MeshPart foliage in ReplicatedStorage.EnvironmentTemplates
    local templates = ReplicatedStorage:FindFirstChild("EnvironmentTemplates")
    local meshGrassTemplates: { Model } = {}
    local meshFernTemplates: { Model } = {}
    
    if templates then
        for _, child in ipairs(templates:GetChildren()) do
            if child:IsA("Model") then
                local name = child.Name:lower()
                if name:find("grass") or name:find("tuft") or name:find("clump") then
                    table.insert(meshGrassTemplates, child)
                elseif name:find("fern") or name:find("plant") or name:find("bush") then
                    table.insert(meshFernTemplates, child)
                end
            end
        end
    end
    
    local stats = {
        MeshFoliage = 0,
        Stones = 0,
    }
    
    -- -----------------------------------------------------------------------
    -- 1. REALISTIC MESH FOLIAGE (If templates exist in EnvironmentTemplates)
    -- -----------------------------------------------------------------------
    if #meshGrassTemplates > 0 or #meshFernTemplates > 0 then
        local targetFoliage = 220
        local attempts = 0
        while stats.MeshFoliage < targetFoliage and attempts < (targetFoliage * 8) do
            attempts = attempts + 1
            local angle = rng(0, math.pi * 2)
            local dist = rng(campRadius + 2.0, maxBasinRadius)
            local px = math.cos(angle) * dist
            local pz = math.sin(angle) * dist
            
            -- Path check
            if PathSystem.IsOnPath(px, pz, 1.0, activeCfg) then continue end
            
            local groundPos, groundNormal, groundMat = findGroundPosition(px, pz)
            if not groundPos or not groundNormal or not groundMat then continue end
            
            -- Strict avoidance of stone cliffs and mountain rock
            if groundMat == Enum.Material.Rock or groundMat == Enum.Material.Slate or groundNormal.Y < 0.82 then
                continue
            end
            
            local templateList = (#meshFernTemplates > 0 and rng() < 0.35) and meshFernTemplates or meshGrassTemplates
            if #templateList == 0 then templateList = meshGrassTemplates end
            
            local pickedTemplate = templateList[math.floor(rng(1, #templateList + 0.99))]
            if pickedTemplate then
                local clone = pickedTemplate:Clone()
                clone:ScaleTo(rng(0.85, 1.25))
                for _, p in ipairs(clone:GetDescendants()) do
                    if p:IsA("BasePart") then
                        p.Anchored = true
                        p.CanCollide = false
                        p.CanTouch = false
                        p.CanQuery = false
                        p.CastShadow = false
                    end
                end
                clone:PivotTo(CFrame.new(groundPos) * CFrame.Angles(0, rng(-math.pi, math.pi), 0))
                clone.Parent = foliageFolder
                stats.MeshFoliage = stats.MeshFoliage + 1
            end
        end
    end
    
    -- -----------------------------------------------------------------------
    -- 2. NATURAL EMBEDDED FOREST STONES (Basin Only, Avoids Border Mountains)
    -- -----------------------------------------------------------------------
    local stoneBudget = cfg.EmbeddedPebblesBudget or 120
    local stoneCount = 0
    local stoneAttempts = 0
    
    while stoneCount < stoneBudget and stoneAttempts < (stoneBudget * 6) do
        stoneAttempts = stoneAttempts + 1
        local angle = rng(0, math.pi * 2)
        local dist = rng(campRadius + 2.0, maxBasinRadius)
        local px = math.cos(angle) * dist
        local pz = math.sin(angle) * dist
        
        -- Keeps stones off the open trail center
        if PathSystem.IsOnPath(px, pz, 0.5, activeCfg) then continue end
        
        local groundPos, groundNormal, groundMat = findGroundPosition(px, pz)
        if not groundPos or not groundNormal or not groundMat then continue end
        
        -- Do not spawn loose stones on the grey stone border ridge
        if groundMat == Enum.Material.Rock or groundMat == Enum.Material.Slate or groundNormal.Y < 0.82 then
            continue
        end
        
        local stone = buildEmbeddedPebble(math.floor(px * 100 + pz + stoneAttempts), stonesFolder, activeCfg)
        if stone and stone.PrimaryPart then
            stone:PivotTo(CFrame.new(groundPos - Vector3.new(0, 0.25, 0)) * CFrame.Angles(0, rng(-math.pi, math.pi), 0))
            stoneCount = stoneCount + 1
            stats.Stones = stats.Stones + 1
        end
    end
    
    local elapsed = math.round((os.clock() - startTime) * 100) / 100
    print(string.format(
        "[GroundCover] Completed Clean Forest Floor in %.2f seconds! | Mesh Foliage=%d | Embedded Stones=%d | Logs: DISABLED | Border Mountains: 100%% Clean",
        elapsed,
        stats.MeshFoliage,
        stats.Stones
    ))
end

return GroundCover
