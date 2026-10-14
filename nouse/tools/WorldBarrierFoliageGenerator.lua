--!strict
--[[
    WorldBarrierFoliageGenerator.lua
    Giant Bush Line World Barrier Generator.
    "Don't Let the Fire Die" — Fluenosity Studio

    Design:
    - Single, continuous line of GIANT, TALL bushes centered strictly on the barrier line.
    - Bushes are scaled to 9.5 - 13.0 studs tall and 16.0 - 22.0 studs wide.
    - Sits half inside, half outside the barrier wall.
    - Thick, dense overlap (placed every 7.0 studs) so there are ZERO sightline gaps.
    - Completely blocks sight beyond the world boundary without requiring extra background clutter.
    - When a player walks up to the barrier in FPP, they walk directly into giant towering leaves,
      and the invisible collision wall in the center stops them.
    - Ultra-optimized: only 1 line of bushes (~16 models per 120 studs, ~550 for the entire map).
    - CanCollide = false, CanTouch = false, CastShadow = false for zero physics or draw-call lag.
]]

local Workspace = game:GetService("Workspace")
local Terrain = Workspace.Terrain

local WorldBarrierFoliageGenerator = {}

-- Source giant bush templates
local function getBushTemplates(): { Model }
    local fol = Workspace:FindFirstChild("ForestEnvironment")
    local groundCover = fol and fol:FindFirstChild("GroundCover")
    local foliageFolder = groundCover and groundCover:FindFirstChild("Foliage")

    local bushes = {}
    if foliageFolder then
        for _, name in ipairs({ "RhododendronVar01", "RhododendronVar02", "MountainLaurelBush_Var01" }) do
            local item = foliageFolder:FindFirstChild(name)
            if item and item:IsA("Model") then
                table.insert(bushes, item)
            end
        end
    end

    -- Fallback to workspace root templates if not found in folder
    if #bushes == 0 then
        for _, name in ipairs({ "RhododendronVar01", "RhododendronVar02", "MountainLaurelBush_Var01" }) do
            local item = Workspace:FindFirstChild(name)
            if item and item:IsA("Model") then
                table.insert(bushes, item)
            end
        end
    end

    return bushes
end

-- Ground elevation check (only hits Terrain)
local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Include
rayParams.FilterDescendantsInstances = { Terrain }

local function snapToGround(worldX: number, worldZ: number, approxY: number): (Vector3?, Vector3?)
    local rayOrigin = Vector3.new(worldX, approxY + 80, worldZ)
    local hit = Workspace:Raycast(rayOrigin, Vector3.new(0, -200, 0), rayParams)
    if hit then
        return hit.Position, hit.Normal
    end
    local hitWide = Workspace:Raycast(Vector3.new(worldX, 350, worldZ), Vector3.new(0, -500, 0), rayParams)
    if hitWide then
        return hitWide.Position, hitWide.Normal
    end
    return nil, nil
end

-- Spawn a single giant bush
local function spawnGiantBush(template: Model, pos: Vector3, scale: number, parent: Instance): Model?
    local clone = template:Clone()
    clone:ScaleTo(scale)

    for _, desc in ipairs(clone:GetDescendants()) do
        if desc:IsA("MeshPart") then
            desc.CanCollide = false
            desc.CanTouch = false
            desc.CanQuery = false
            desc.Anchored = true
            desc.CastShadow = false
            desc.RenderFidelity = Enum.RenderFidelity.Performance
        elseif desc:IsA("BasePart") then
            desc.CanCollide = false
            desc.CanTouch = false
            desc.CanQuery = false
            desc.Anchored = true
            desc.CastShadow = false
        end
    end

    -- Calculate true bottom of the scaled model so roots/trunks sit on the ground
    local cf0, sz0 = clone:GetBoundingBox()
    local p0 = clone:GetPivot()
    local bottomY = cf0.Position.Y - (sz0.Y / 2)
    local bottomToPivot = p0.Position.Y - bottomY

    -- Ground anchor: sink only 0.4 studs into terrain so it sits firmly on ground without burying
    local finalY = pos.Y + bottomToPivot - 0.4

    local yaw = math.rad(math.random(0, 360))
    local tiltX = math.rad(math.random(-2, 2))
    local tiltZ = math.rad(math.random(-2, 2))

    local placedCFrame = CFrame.new(pos.X, finalY, pos.Z)
        * CFrame.Angles(tiltX, yaw, tiltZ)

    clone:PivotTo(placedCFrame)
    clone.Parent = parent
    return clone
end

-- Populate a wall with giant bushes
local function populateWallGiant(
    wall: BasePart,
    templates: { Model },
    container: Instance,
    rng: Random
): number
    local cf = wall.CFrame
    local wallLen = wall.Size.X
    local wallPos = cf.Position
    local right = cf.RightVector
    local normal = cf.LookVector
    local halfLen = wallLen / 2

    local step = 11.5 -- 1 colossal bush every 11.5 studs (each is 35-65 studs wide -> massive overlap)
    local numBushes = math.floor(wallLen / step)
    local placed = 0

    for i = 0, numBushes do
        local distAlong = -halfLen + (i * step) + rng:NextNumber(-0.6, 0.6)
        local stagger = rng:NextNumber(-0.5, 0.5) -- strictly centered on the wall line

        local targetX = wallPos.X + (right.X * distAlong) + (normal.X * stagger)
        local targetZ = wallPos.Z + (right.Z * distAlong) + (normal.Z * stagger)

        local groundPos = snapToGround(targetX, targetZ, wallPos.Y)
        if groundPos and #templates > 0 then
            local template = templates[rng:NextInteger(1, #templates)]
            -- Colossal scale (27 to 34 studs tall above ground, 35 to 65 studs wide)
            local scale = rng:NextNumber(4.60, 5.60)
            spawnGiantBush(template, groundPos, scale, container)
            placed += 1
        end
    end

    return placed
end

--------------------------------------------------------------------------------
-- PUBLIC API
--------------------------------------------------------------------------------

-- Generate ~120-stud preview of giant bushes along preview walls
function WorldBarrierFoliageGenerator.GeneratePreview(): (number, Model)
    WorldBarrierFoliageGenerator.ClearPreview()

    local wb = Workspace:FindFirstChild("WorldBarrier")
    local wallsFolder = wb and wb:FindFirstChild("CollisionWalls")
    if not wallsFolder then
        error("[WorldBarrierFoliageGenerator] Workspace.WorldBarrier.CollisionWalls not found!")
    end

    local previewWalls = {
        wallsFolder:FindFirstChild("Wall_43_to_44"),
        wallsFolder:FindFirstChild("Wall_44_to_45"),
        wallsFolder:FindFirstChild("Wall_45_to_46"),
    }

    local container = Instance.new("Model")
    container.Name = "WorldBarrier_FoliagePreview"
    container.Parent = Workspace

    local templates = getBushTemplates()
    local rng = Random.new(999)
    local totalPlaced = 0

    for _, wall in ipairs(previewWalls) do
        if wall and wall:IsA("BasePart") then
            local count = populateWallGiant(wall, templates, container, rng)
            totalPlaced += count
        end
    end

    print(string.format("🌿 [WorldBarrierFoliageGenerator] Giant bush preview generated! Placed %d giant bushes in %s",
        totalPlaced, container:GetFullName()))
    return totalPlaced, container
end

-- Clear preview
function WorldBarrierFoliageGenerator.ClearPreview()
    local existing = Workspace:FindFirstChild("WorldBarrier_FoliagePreview")
    if existing then
        existing:Destroy()
        print("🗑️ [WorldBarrierFoliageGenerator] Preview cleared.")
    end
end

-- Generate full perimeter giant bush wall (all 121 walls)
function WorldBarrierFoliageGenerator.GenerateFull(): (number, Model)
    WorldBarrierFoliageGenerator.ClearPreview()
    WorldBarrierFoliageGenerator.ClearFull()

    local wb = Workspace:FindFirstChild("WorldBarrier")
    local wallsFolder = wb and wb:FindFirstChild("CollisionWalls")
    if not wallsFolder then
        error("[WorldBarrierFoliageGenerator] Workspace.WorldBarrier.CollisionWalls not found!")
    end

    local walls = wallsFolder:GetChildren()
    local container = Instance.new("Model")
    container.Name = "WorldBarrier_Foliage"
    container.Parent = Workspace

    local templates = getBushTemplates()
    local rng = Random.new(2026)
    local totalPlaced = 0

    for idx, wall in ipairs(walls) do
        if wall:IsA("BasePart") then
            local count = populateWallGiant(wall, templates, container, rng)
            totalPlaced += count

            if idx % 10 == 0 then
                task.wait()
            end
        end
    end

    print(string.format("🌿 [WorldBarrierFoliageGenerator] Full giant bush barrier generated! Placed %d giant bushes in %s",
        totalPlaced, container:GetFullName()))
    return totalPlaced, container
end

-- Clear full barrier
function WorldBarrierFoliageGenerator.ClearFull()
    local existing = Workspace:FindFirstChild("WorldBarrier_Foliage")
    if existing then
        existing:Destroy()
        print("🗑️ [WorldBarrierFoliageGenerator] Full foliage cleared.")
    end
end

return WorldBarrierFoliageGenerator
