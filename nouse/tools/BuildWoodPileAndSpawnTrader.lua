--!strict
--[[
    tools/BuildWoodPileAndSpawnTrader.lua
    Standalone Studio Command Bar runner for:
    1. Replacing the old glitchy wood pile with a custom, clean, AAA twin-cord log pile at Vector3.new(188.3, 33.8, -39.7)
    2. Spawning Silas the Ash Trader behind the counter in the Trader House with [E] Barter prompt
    Run directly in the Roblox Studio Command Bar (Edit Mode or Play Mode).
]]

local Workspace = game:GetService("Workspace")
local CollectionService = game:GetService("CollectionService")

print("----------------------------------------------------------------------")
print("🔥 [FLUENOSITY STUDIO] Building Custom Wood Pile & Spawning Silas...")
print("----------------------------------------------------------------------")

-- ============================================================================
-- PART 1: BUILD CUSTOM AAA WOOD PILE AT (188.3, 33.8, -39.7)
-- ============================================================================
local TARGET_ORIGIN = Vector3.new(188.3, 33.8, -39.7)

-- Destroy old models near coordinates
local destroyedCount = 0
for _, obj in ipairs(Workspace:GetChildren()) do
    if obj:IsA("Model") then
        local l = obj.Name:lower()
        local pivot = obj:GetPivot()
        local dist = (pivot.Position - TARGET_ORIGIN).Magnitude
        if dist < 30.0 and (obj.Name == "Model" or l:find("pile") or l:find("wood") or l:find("log")) then
            obj:Destroy()
            destroyedCount += 1
        end
    end
end
print(string.format("🧹 Cleared %d old wood pile models near (188.3, 33.8, -39.7)", destroyedCount))

local terrain = Workspace:FindFirstChildOfClass("Terrain") or Workspace.Terrain
local groundY = TARGET_ORIGIN.Y
if terrain then
    local rayOrigin = Vector3.new(TARGET_ORIGIN.X, 150, TARGET_ORIGIN.Z)
    local rayDir = Vector3.new(0, -250, 0)
    local rayParams = RaycastParams.new()
    rayParams.FilterType = Enum.RaycastFilterType.Include
    rayParams.FilterDescendantsInstances = { terrain }
    local hit = Workspace:Raycast(rayOrigin, rayDir, rayParams)
    if hit then groundY = hit.Position.Y end
end

local rootCFrame = CFrame.new(TARGET_ORIGIN.X, groundY, TARGET_ORIGIN.Z) * CFrame.Angles(0, math.rad(-12), 0)

local woodPileModel = Instance.new("Model")
woodPileModel.Name = "WoodlandLogPile"
CollectionService:AddTag(woodPileModel, "WoodPile")

-- Primary interaction hitbox
local promptAnchor = Instance.new("Part")
promptAnchor.Name = "WoodInteractionPromptPart"
promptAnchor.Size = Vector3.new(18, 5, 11)
promptAnchor.CFrame = rootCFrame * CFrame.new(0, 2.5, 0)
promptAnchor.Transparency = 1
promptAnchor.CanCollide = false
promptAnchor.CanTouch = false
promptAnchor.CanQuery = true
promptAnchor.Anchored = true
promptAnchor.Parent = woodPileModel
woodPileModel.PrimaryPart = promptAnchor

-- Timber foundation skids
for i, sx in ipairs({ -6.5, -2.0, 2.0, 6.5 }) do
    local skid = Instance.new("Part")
    skid.Name = "BaseSkid_" .. i
    skid.Size = Vector3.new(0.65, 0.45, 9.8)
    skid.CFrame = rootCFrame * CFrame.new(sx, 0.22, 0)
    skid.Color = Color3.fromRGB(62, 44, 30)
    skid.Material = Enum.Material.Wood
    skid.Anchored = true
    skid.CanCollide = true
    skid.Parent = woodPileModel
end

-- End stakes
for i, sc in ipairs({
    { x = -8.6, z = -4.3 }, { x = -8.6, z = 4.3 },
    { x = -0.3, z = -4.3 }, { x = -0.3, z = 4.3 },
    { x =  0.3, z = -4.3 }, { x =  0.3, z = 4.3 },
    { x =  8.6, z = -4.3 }, { x =  8.6, z = 4.3 },
}) do
    local stake = Instance.new("Part")
    stake.Name = "EndStake_" .. i
    stake.Size = Vector3.new(0.55, 3.8, 0.55)
    stake.CFrame = rootCFrame * CFrame.new(sc.x, 1.9, sc.z)
    stake.Color = Color3.fromRGB(72, 50, 36)
    stake.Material = Enum.Material.Wood
    stake.Anchored = true
    stake.CanCollide = true
    stake.Parent = woodPileModel
end

-- Stacked logs
local stackCentersX = { -4.4, 4.4 }
local logLength = 8.5
local logDiameter = 1.15
local logRadius = logDiameter / 2
local barkColors = { Color3.fromRGB(105, 75, 52), Color3.fromRGB(95, 68, 48), Color3.fromRGB(112, 82, 58), Color3.fromRGB(88, 62, 44) }
local layers = {
    { count = 6, yOffset = 0.50 + logRadius },
    { count = 5, yOffset = 0.50 + logRadius + 0.95 },
    { count = 4, yOffset = 0.50 + logRadius + 1.90 },
    { count = 3, yOffset = 0.50 + logRadius + 2.85 },
    { count = 2, yOffset = 0.50 + logRadius + 3.80 },
}

local logIndex = 0
for _, stackCenterX in ipairs(stackCentersX) do
    for _, layer in ipairs(layers) do
        local count = layer.count
        local totalWidth = (count - 1) * 1.18
        local startX = stackCenterX - (totalWidth / 2)
        for i = 1, count do
            logIndex += 1
            local posX = startX + (i - 1) * 1.18
            local posY = layer.yOffset
            local rotZ = math.rad((((logIndex * 17) % 7) - 3) * 0.8)

            local log = Instance.new("Part")
            log.Name = "TimberLog_" .. logIndex
            log.Shape = Enum.PartType.Cylinder
            log.Size = Vector3.new(logLength, logDiameter, logDiameter)
            log.CFrame = rootCFrame * CFrame.new(posX, posY, 0) * CFrame.Angles(0, math.rad(90), rotZ)
            log.Color = barkColors[((logIndex - 1) % #barkColors) + 1]
            log.Material = Enum.Material.Wood
            log.Anchored = true
            log.CanCollide = true
            log.Parent = woodPileModel

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
                cap.Parent = woodPileModel
            end
        end
    end
end

local woodPrompt = Instance.new("ProximityPrompt")
woodPrompt.Name = "WoodGatherPrompt"
woodPrompt.ActionText = "Take Wood Log"
woodPrompt.ObjectText = "Wood Pile (Max 5)"
woodPrompt.KeyboardKeyCode = Enum.KeyCode.E
woodPrompt.GamepadKeyCode = Enum.KeyCode.ButtonX
woodPrompt.HoldDuration = 0.25
woodPrompt.MaxActivationDistance = 16.0
woodPrompt.RequiresLineOfSight = false
woodPrompt.Parent = promptAnchor

woodPileModel.Parent = Workspace
print(string.format("✅ [WOOD PILE READY] Built custom AAA log pile at Vector3.new(%.1f, %.1f, %.1f) with %d logs!", TARGET_ORIGIN.X, groundY, TARGET_ORIGIN.Z, logIndex))

-- ============================================================================
-- PART 2: SPAWN SILAS THE ASH TRADER IN TRADER HOUSE
-- ============================================================================
local existingSilas = Workspace:FindFirstChild("TraderSilas")
if existingSilas then
    print("ℹ️ Existing TraderSilas found in Workspace. Preserving position!")
end

-- Locate Trader House
local traderHouse: Instance? = nil
for _, obj in ipairs(Workspace:GetDescendants()) do
    if obj:IsA("Model") then
        local l = obj.Name:lower()
        if l:find("trader") or l:find("merchant") or l:find("shop") or l:find("cabin") then
            traderHouse = obj
            CollectionService:AddTag(obj, "TraderHouse")
            break
        end
    end
end

local silasCF: CFrame? = nil

-- Check if developer is currently standing in Trader House
local char: Model? = nil
for _, m in ipairs(Workspace:GetChildren()) do
    if m:FindFirstChildOfClass("Humanoid") and m:FindFirstChild("HumanoidRootPart") then
        char = m; break
    end
end

-- Look for counter table in Trader House
local counterPart: BasePart? = nil
if traderHouse then
    for _, part in ipairs(traderHouse:GetDescendants()) do
        if part:IsA("BasePart") then
            local pName = part.Name:lower()
            if pName:find("counter") or pName:find("table") or pName:find("desk") or pName:find("bar") then
                counterPart = part
                break
            end
        end
    end
end

if counterPart then
    local pos = counterPart.Position + Vector3.new(0, (counterPart.Size.Y / 2) + 2.8, -3.2)
    local lookAt = counterPart.Position + Vector3.new(0, counterPart.Size.Y / 2, 0)
    silasCF = CFrame.new(pos, lookAt)
elseif char and char.PrimaryPart then
    -- Place Silas directly in front of the player character inside the house!
    silasCF = char.PrimaryPart.CFrame * CFrame.new(0, 0, -4.5) * CFrame.Angles(0, math.rad(180), 0)
elseif traderHouse then
    local bbCF, bbSize = (traderHouse :: Model):GetBoundingBox()
    silasCF = CFrame.new(bbCF.Position + Vector3.new(0, -(bbSize.Y / 2) + 3.0, -(bbSize.Z * 0.25)))
else
    silasCF = CFrame.new(0, 5, 0)
end

local silas = Instance.new("Model")
silas.Name = "TraderSilas"
CollectionService:AddTag(silas, "TraderNPC")

local hrp = Instance.new("Part")
hrp.Name = "HumanoidRootPart"
hrp.Size = Vector3.new(2, 2, 1)
hrp.CFrame = silasCF
hrp.Transparency = 1
hrp.CanCollide = false
hrp.Anchored = true
hrp.Parent = silas
silas.PrimaryPart = hrp

local torso = Instance.new("Part")
torso.Name = "Torso"
torso.Size = Vector3.new(2.1, 2.2, 1.2)
torso.CFrame = silasCF
torso.Color = Color3.fromRGB(48, 42, 38)
torso.Material = Enum.Material.Fabric
torso.Anchored = true
torso.CanCollide = false
torso.Parent = silas

local head = Instance.new("Part")
head.Name = "Head"
head.Size = Vector3.new(1.25, 1.25, 1.25)
head.CFrame = silasCF * CFrame.new(0, 1.65, 0)
head.Color = Color3.fromRGB(224, 178, 142)
head.Material = Enum.Material.SmoothPlastic
head.Anchored = true
head.CanCollide = false
head.Parent = silas

local scarf = Instance.new("Part")
scarf.Name = "Scarf"
scarf.Size = Vector3.new(1.7, 0.5, 1.5)
scarf.CFrame = silasCF * CFrame.new(0, 1.15, 0)
scarf.Color = Color3.fromRGB(165, 48, 40)
scarf.Material = Enum.Material.Fabric
scarf.Anchored = true
scarf.CanCollide = false
scarf.Parent = silas

local hatBrim = Instance.new("Part")
hatBrim.Name = "HatBrim"
hatBrim.Size = Vector3.new(2.4, 0.15, 2.4)
hatBrim.CFrame = silasCF * CFrame.new(0, 2.25, 0)
hatBrim.Color = Color3.fromRGB(38, 32, 28)
hatBrim.Material = Enum.Material.Slate
hatBrim.Anchored = true
hatBrim.CanCollide = false
hatBrim.Parent = silas

for _, sideX in ipairs({ -1.35, 1.35 }) do
    local arm = Instance.new("Part")
    arm.Name = sideX < 0 and "LeftArm" or "RightArm"
    arm.Size = Vector3.new(0.9, 2.1, 0.9)
    arm.CFrame = silasCF * CFrame.new(sideX, -0.05, 0)
    arm.Color = Color3.fromRGB(48, 42, 38)
    arm.Material = Enum.Material.Fabric
    arm.Anchored = true
    arm.CanCollide = false
    arm.Parent = silas
end

for _, sideX in ipairs({ -0.55, 0.55 }) do
    local leg = Instance.new("Part")
    leg.Name = sideX < 0 and "LeftLeg" or "RightLeg"
    leg.Size = Vector3.new(0.9, 2.2, 0.9)
    leg.CFrame = silasCF * CFrame.new(sideX, -2.1, 0)
    leg.Color = Color3.fromRGB(34, 30, 28)
    leg.Material = Enum.Material.Fabric
    leg.Anchored = true
    leg.CanCollide = false
    leg.Parent = silas
end

-- Floating Nameplate
local bbg = Instance.new("BillboardGui")
bbg.Name = "Nameplate"
bbg.Size = UDim2.new(0, 240, 0, 75)
bbg.StudsOffset = Vector3.new(0, 3.6, 0)
bbg.AlwaysOnTop = true
bbg.MaxDistance = 45
bbg.Adornee = head
bbg.Parent = head

local nameLabel = Instance.new("TextLabel")
nameLabel.Size = UDim2.new(1, 0, 0, 32)
nameLabel.BackgroundTransparency = 1
nameLabel.Text = "★ SILAS ★"
nameLabel.TextColor3 = Color3.fromRGB(255, 215, 80)
nameLabel.Font = Enum.Font.GothamBold
nameLabel.TextSize = 22
nameLabel.TextStrokeColor3 = Color3.fromRGB(20, 15, 10)
nameLabel.TextStrokeTransparency = 0.2
nameLabel.Parent = bbg

local subLabel = Instance.new("TextLabel")
subLabel.Size = UDim2.new(1, 0, 0, 22)
subLabel.Position = UDim2.new(0, 0, 0, 32)
subLabel.BackgroundTransparency = 1
subLabel.Text = "Ash Trader • Barter [E]"
subLabel.TextColor3 = Color3.fromRGB(235, 220, 195)
subLabel.Font = Enum.Font.GothamMedium
subLabel.TextSize = 14
subLabel.TextStrokeColor3 = Color3.fromRGB(15, 10, 5)
subLabel.TextStrokeTransparency = 0.3
subLabel.Parent = bbg

-- Silas Proximity Prompt
local barterPrompt = Instance.new("ProximityPrompt")
barterPrompt.Name = "SilasBarterPrompt"
barterPrompt.ActionText = "Barter"
barterPrompt.ObjectText = "Silas (Ash Trader)"
barterPrompt.KeyboardKeyCode = Enum.KeyCode.E
barterPrompt.GamepadKeyCode = Enum.KeyCode.ButtonX
barterPrompt.HoldDuration = 0.2
barterPrompt.MaxActivationDistance = 11.0
barterPrompt.RequiresLineOfSight = false
barterPrompt.Parent = torso

local shared = game:GetService("ReplicatedStorage"):WaitForChild("FluenosityShared")
local openEvent = shared:FindFirstChild("OpenBarterMenu") :: RemoteEvent?
if openEvent then
    barterPrompt.Triggered:Connect(function(player: Player)
        openEvent:FireClient(player)
    end)
end

silas.Parent = Workspace
print(string.format("✅ [SILAS SPAWNED] Silas is active at Vector3.new(%.1f, %.1f, %.1f) with [E] Barter prompt!", silasCF.Position.X, silasCF.Position.Y, silasCF.Position.Z))

print("----------------------------------------------------------------------")
print("🎉 [COMPLETE] Custom Wood Pile & Silas the Trader are now live!")
print("----------------------------------------------------------------------")
