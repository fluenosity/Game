--!strict
--[[
    WoodPileBuilder.lua
    Procedural AAA Rustic Woodland Log Pile Generator for "Don't Let the Fire Die".
    Builds a clean, anchored, high-aesthetic twin-cord log pile at Vector3.new(188.3, 33.8, -39.7)
    with a wide, reliable central interaction prompt.
]]

local Workspace = game:GetService("Workspace")
local CollectionService = game:GetService("CollectionService")

local WoodPileBuilder = {}

local TARGET_ORIGIN = Vector3.new(-23.0, 8.5, -180.5)

-- Raycast down to find exact forest ground surface
local function getGroundHeight(x: number, z: number, defaultY: number): number
    local rayOrigin = Vector3.new(x, 150, z)
    local rayDir = Vector3.new(0, -250, 0)
    local rayParams = RaycastParams.new()
    rayParams.FilterType = Enum.RaycastFilterType.Include
    local terrain = Workspace:FindFirstChildOfClass("Terrain") or Workspace.Terrain
    if terrain then
        rayParams.FilterDescendantsInstances = { terrain }
    end
    local hit = Workspace:Raycast(rayOrigin, rayDir, rayParams)
    if hit then
        return hit.Position.Y
    end
    return defaultY
end

function WoodPileBuilder.Build(): Model
    -- 1. If WoodlandLogPile or any tagged WoodPile already exists in Workspace, preserve it!
    local existingPile = Workspace:FindFirstChild("WoodlandLogPile")
    if existingPile and existingPile:IsA("Model") then
        CollectionService:AddTag(existingPile, "WoodPile")
        return existingPile
    end

    local tagged = CollectionService:GetTagged("WoodPile")
    for _, obj in ipairs(tagged) do
        if obj:IsA("Model") and not obj.Name:lower():find("barrel") and not obj.Name:lower():find("trader") then
            return obj
        end
    end

    local groundY = getGroundHeight(TARGET_ORIGIN.X, TARGET_ORIGIN.Z, TARGET_ORIGIN.Y)
    local rootCFrame = CFrame.new(TARGET_ORIGIN.X, groundY, TARGET_ORIGIN.Z) * CFrame.Angles(0, math.rad(-12), 0)

    local model = Instance.new("Model")
    model.Name = "WoodlandLogPile"
    CollectionService:AddTag(model, "WoodPile")

    -- Primary interaction anchor part
    local promptAnchor = Instance.new("Part")
    promptAnchor.Name = "WoodInteractionPromptPart"
    promptAnchor.Size = Vector3.new(18, 5, 11)
    promptAnchor.CFrame = rootCFrame * CFrame.new(0, 2.5, 0)
    promptAnchor.Transparency = 1
    promptAnchor.CanCollide = false
    promptAnchor.CanTouch = false
    promptAnchor.CanQuery = true
    promptAnchor.Anchored = true
    promptAnchor.Parent = model
    model.PrimaryPart = promptAnchor

    -- Foundation timber skids (sleepers) on the ground
    local skidOffsets = { -6.5, -2.0, 2.0, 6.5 }
    for i, sx in ipairs(skidOffsets) do
        local skid = Instance.new("Part")
        skid.Name = "BaseSkid_" .. i
        skid.Size = Vector3.new(0.65, 0.45, 9.8)
        skid.CFrame = rootCFrame * CFrame.new(sx, 0.22, 0)
        skid.Color = Color3.fromRGB(62, 44, 30)
        skid.Material = Enum.Material.Wood
        skid.Anchored = true
        skid.CanCollide = true
        skid.Parent = model
    end

    -- Vertical timber end stakes (keeping logs from rolling out)
    local stakeCoords = {
        { x = -8.6, z = -4.3 }, { x = -8.6, z = 4.3 },
        { x = -0.3, z = -4.3 }, { x = -0.3, z = 4.3 },
        { x =  0.3, z = -4.3 }, { x =  0.3, z = 4.3 },
        { x =  8.6, z = -4.3 }, { x =  8.6, z = 4.3 },
    }
    for i, sc in ipairs(stakeCoords) do
        local stake = Instance.new("Part")
        stake.Name = "EndStake_" .. i
        stake.Size = Vector3.new(0.55, 3.8, 0.55)
        stake.CFrame = rootCFrame * CFrame.new(sc.x, 1.9, sc.z)
        stake.Color = Color3.fromRGB(72, 50, 36)
        stake.Material = Enum.Material.Wood
        stake.Anchored = true
        stake.CanCollide = true
        stake.Parent = model
    end

    -- Symmetrical double cords (Left stack & Right stack)
    local stackCentersX = { -4.4, 4.4 }
    local logLength = 8.5
    local logDiameter = 1.15
    local logRadius = logDiameter / 2

    local barkColors = {
        Color3.fromRGB(105, 75, 52),
        Color3.fromRGB(95, 68, 48),
        Color3.fromRGB(112, 82, 58),
        Color3.fromRGB(88, 62, 44),
    }

    local layers = {
        { count = 6, yOffset = 0.50 + logRadius },
        { count = 5, yOffset = 0.50 + logRadius + 0.95 },
        { count = 4, yOffset = 0.50 + logRadius + 1.90 },
        { count = 3, yOffset = 0.50 + logRadius + 2.85 },
        { count = 2, yOffset = 0.50 + logRadius + 3.80 },
    }

    local logIndex = 0
    for _, stackCenterX in ipairs(stackCentersX) do
        for layerIdx, layer in ipairs(layers) do
            local count = layer.count
            local totalWidth = (count - 1) * 1.18
            local startX = stackCenterX - (totalWidth / 2)

            for i = 1, count do
                logIndex += 1
                local posX = startX + (i - 1) * 1.18
                local posY = layer.yOffset
                local rotZ = math.rad((((logIndex * 17) % 7) - 3) * 0.8)

                -- Main cylindrical log (oriented along Z)
                local log = Instance.new("Part")
                log.Name = "TimberLog_" .. logIndex
                log.Shape = Enum.PartType.Cylinder
                log.Size = Vector3.new(logLength, logDiameter, logDiameter)
                -- Roblox cylinders are oriented along X axis by default, rotate 90 deg around Y to align with Z
                log.CFrame = rootCFrame * CFrame.new(posX, posY, 0) * CFrame.Angles(0, math.rad(90), rotZ)
                log.Color = barkColors[((logIndex - 1) % #barkColors) + 1]
                log.Material = Enum.Material.Wood
                log.Anchored = true
                log.CanCollide = true
                log.Parent = model

                -- Decorative light wood end caps (annual rings look)
                for _, capZ in ipairs({ -logLength / 2 - 0.02, logLength / 2 + 0.02 }) do
                    local cap = Instance.new("Part")
                    cap.Name = "LogCap"
                    cap.Shape = Enum.PartType.Cylinder
                    cap.Size = Vector3.new(0.06, logDiameter * 0.92, logDiameter * 0.92)
                    cap.CFrame = rootCFrame * CFrame.new(posX, posY, capZ) * CFrame.Angles(0, math.rad(90), 0)
                    cap.Color = Color3.fromRGB(224, 202, 168)
                    cap.Material = Enum.Material.WoodPlanks
                    cap.Anchored = true
                    cap.CanCollide = false
                    cap.Parent = model
                end
            end
        end
    end

    -- Proximity Prompt setup
    local prompt = Instance.new("ProximityPrompt")
    prompt.Name = "WoodGatherPrompt"
    prompt.ActionText = "Take Wood Log"
    prompt.ObjectText = "Wood Pile (Max 5)"
    prompt.KeyboardKeyCode = Enum.KeyCode.E
    prompt.GamepadKeyCode = Enum.KeyCode.ButtonX
    prompt.HoldDuration = 0.2
    prompt.MaxActivationDistance = 20.0
    prompt.RequiresLineOfSight = false
    prompt.Exclusivity = Enum.ProximityPromptExclusivity.OnePerButton
    prompt.ClickablePrompt = false
    prompt.Parent = promptAnchor

    model.Parent = Workspace
    print(string.format("🪵 [WoodPileBuilder] Custom AAA WoodlandLogPile created at Vector3.new(%.1f, %.1f, %.1f) with %d logs!", TARGET_ORIGIN.X, groundY, TARGET_ORIGIN.Z, logIndex))
    return model
end

return WoodPileBuilder
