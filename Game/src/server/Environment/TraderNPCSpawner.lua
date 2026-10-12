--!strict
--[[
    TraderNPCSpawner.lua
    Spawns and configures Silas the Ash Trader inside the Trader House.
    Features:
    - Stylized survivor merchant character model (duster coat, winter scarf, backpack)
    - Golden overhead nameplate BillboardGui ("SILAS — Ash Trader")
    - ProximityPrompt [E] Barter that opens the barter trading modal
    - Authoritative placement behind the counter table inside the Trader House
]]

local Workspace = game:GetService("Workspace")
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local TraderNPCSpawner = {}

local sharedFolder = ReplicatedStorage:WaitForChild("FluenosityShared")

local function getOrCreateRemoteEvent(name: string): RemoteEvent
    local ev = sharedFolder:FindFirstChild(name)
    if not ev then
        local newEv = Instance.new("RemoteEvent")
        newEv.Name = name
        newEv.Parent = sharedFolder
        return newEv
    end
    return ev :: RemoteEvent
end

local openBarterMenuEvent = getOrCreateRemoteEvent("OpenBarterMenu")

-- Helper to find floor height under a position
local function getFloorY(pos: Vector3): number
    local rayOrigin = Vector3.new(pos.X, pos.Y + 8, pos.Z)
    local rayDir = Vector3.new(0, -35, 0)
    local rayParams = RaycastParams.new()
    rayParams.FilterType = Enum.RaycastFilterType.Exclude
    local existing = Workspace:FindFirstChild("TraderSilas")
    if existing then
        rayParams.FilterDescendantsInstances = { existing }
    end
    local hit = Workspace:Raycast(rayOrigin, rayDir, rayParams)
    if hit then
        return hit.Position.Y
    end
    return pos.Y
end

-- Helper to find the best spot behind the counter inside the Trader House
local function findTraderSpawnCFrame(): CFrame?
    -- 1. Check if model tagged TraderHouse exists
    local traderHouse: Instance? = nil
    local tagged = CollectionService:GetTagged("TraderHouse")
    if #tagged > 0 then
        traderHouse = tagged[1]
    end

    -- 2. Search for the counter table or candelabra from the interior
    local candelabraOrCounter: BasePart? = nil
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("BasePart") then
            local l = obj.Name:lower()
            if l:find("candelabra") or l:find("counter") or l:find("cashier") or l:find("traderdesk") then
                candelabraOrCounter = obj
                break
            end
        end
    end

    if candelabraOrCounter then
        local floorY = getFloorY(candelabraOrCounter.Position + Vector3.new(0, 0, -3.2))
        local spawnPos = Vector3.new(candelabraOrCounter.Position.X, floorY + 3.2, candelabraOrCounter.Position.Z - 3.2)
        local lookAt = Vector3.new(candelabraOrCounter.Position.X, spawnPos.Y, candelabraOrCounter.Position.Z)
        return CFrame.new(spawnPos, lookAt)
    end

    -- 3. Search for models matching house, cabin, cottage, trader, etc.
    if not traderHouse then
        local candidateKeywords = { "trader", "merchant", "shop", "cabin", "house", "cottage", "shed", "hut", "building" }
        for _, obj in ipairs(Workspace:GetDescendants()) do
            if obj:IsA("Model") then
                local l = obj.Name:lower()
                for _, kw in ipairs(candidateKeywords) do
                    if l:find(kw) and not l:find("campfire") and not l:find("tent") and not l:find("barrel") then
                        traderHouse = obj
                        CollectionService:AddTag(obj, "TraderHouse")
                        break
                    end
                end
                if traderHouse then break end
            end
        end
    end

    -- 4. Search near Steak Dinner on the deck table
    local steakDinner = Workspace:FindFirstChild("Steak Dinner", true)
    if not traderHouse and steakDinner then
        local sPos: Vector3? = nil
        if steakDinner:IsA("BasePart") then
            sPos = steakDinner.Position
        elseif steakDinner:IsA("Model") then
            sPos = steakDinner:GetPivot().Position
        end
        if sPos then
            for _, obj in ipairs(Workspace:GetDescendants()) do
                if obj:IsA("Model") and (obj:GetPivot().Position - sPos).Magnitude < 45.0 then
                    local l = obj.Name:lower()
                    if l:find("house") or l:find("cabin") or l:find("model") or l:find("building") then
                        traderHouse = obj
                        break
                    end
                end
            end
        end
    end

    -- 5. Fallback using Trader House bounding box
    if traderHouse and traderHouse:IsA("Model") then
        local bbCF, bbSize = traderHouse:GetBoundingBox()
        local rawPos = bbCF.Position + Vector3.new(0, -(bbSize.Y / 2) + 3.0, -(bbSize.Z * 0.22))
        local floorY = getFloorY(rawPos)
        local spawnPos = Vector3.new(rawPos.X, floorY + 3.2, rawPos.Z)
        return CFrame.new(spawnPos, spawnPos + (bbCF.LookVector * 10))
    end

    -- 6. Fallback using player character position
    for _, m in ipairs(Workspace:GetChildren()) do
        if m:FindFirstChildOfClass("Humanoid") and m:FindFirstChild("HumanoidRootPart") then
            local hrp = m:FindFirstChild("HumanoidRootPart") :: BasePart
            return hrp.CFrame * CFrame.new(0, 0, -6) * CFrame.Angles(0, math.rad(180), 0)
        end
    end

    return nil
end

-- Wires up the ProximityPrompt and network events for an existing or newly placed Silas model
function TraderNPCSpawner.WireNPC(npc: Model)
    CollectionService:AddTag(npc, "TraderNPC")

    -- Ensure PrimaryPart is set
    if not npc.PrimaryPart then
        npc.PrimaryPart = npc:FindFirstChild("HumanoidRootPart") :: BasePart?
            or npc:FindFirstChild("Torso") :: BasePart?
            or npc:FindFirstChildWhichIsA("BasePart")
    end

    -- Ensure all parts are anchored so physics won't knock him over
    for _, part in ipairs(npc:GetDescendants()) do
        if part:IsA("BasePart") then
            part.Anchored = true
        end
    end

    -- Find Torso or PrimaryPart to hold interaction prompt
    local torso = npc:FindFirstChild("Torso") or npc.PrimaryPart or npc:FindFirstChildWhichIsA("BasePart")
    if not torso or not torso:IsA("BasePart") then
        warn("[TraderNPCSpawner] Cannot wire Silas: No BasePart found in model.")
        return
    end

    -- Ensure prompt exists
    local prompt = torso:FindFirstChild("SilasBarterPrompt")
    if not prompt or not prompt:IsA("ProximityPrompt") then
        local newPrompt = Instance.new("ProximityPrompt")
        newPrompt.Name = "SilasBarterPrompt"
        newPrompt.ActionText = "Barter"
        newPrompt.ObjectText = "Silas (Ash Trader)"
        newPrompt.KeyboardKeyCode = Enum.KeyCode.E
        newPrompt.GamepadKeyCode = Enum.KeyCode.ButtonX
        newPrompt.HoldDuration = 0.2
        newPrompt.MaxActivationDistance = 11.0
        newPrompt.RequiresLineOfSight = false
        newPrompt.ClickablePrompt = false
        newPrompt.Parent = torso
        prompt = newPrompt
    end

    -- Connect Triggered event once
    if not prompt:GetAttribute("IsWired") then
        prompt:SetAttribute("IsWired", true)
        local proxPrompt = prompt :: ProximityPrompt
        proxPrompt.Triggered:Connect(function(player: Player)
            openBarterMenuEvent:FireClient(player)
        end)
    end

    local pos = npc:GetPivot().Position
    print(string.format("🤝 [TraderNPCSpawner] Silas is wired and active at Vector3.new(%.1f, %.1f, %.1f)!", pos.X, pos.Y, pos.Z))
end

function TraderNPCSpawner.Spawn(targetCFrame: CFrame?): Model?
    -- 1. Check if Silas was already placed permanently in Workspace (e.g. by builder in Studio)
    local existing = Workspace:FindFirstChild("TraderSilas")
    if existing and existing:IsA("Model") then
        -- DO NOT DESTROY OR MOVE! Preserve developer's custom position!
        if targetCFrame then
            existing:PivotTo(targetCFrame)
        end
        TraderNPCSpawner.WireNPC(existing)
        return existing
    end

    -- 2. Fallback: Only create him if he does not exist at all in Workspace
    local spawnCF = targetCFrame or findTraderSpawnCFrame()
    if not spawnCF then
        warn("[TraderNPCSpawner] Could not determine Trader House position. Place Silas manually or tag TraderHouse.")
        return nil
    end

    local npc = Instance.new("Model")
    npc.Name = "TraderSilas"
    CollectionService:AddTag(npc, "TraderNPC")

    -- 1. HumanoidRootPart
    local hrp = Instance.new("Part")
    hrp.Name = "HumanoidRootPart"
    hrp.Size = Vector3.new(2, 2, 1)
    hrp.CFrame = spawnCF
    hrp.Transparency = 1
    hrp.CanCollide = false
    hrp.Anchored = true
    hrp.Parent = npc
    npc.PrimaryPart = hrp

    -- Humanoid for nameplate rendering
    local humanoid = Instance.new("Humanoid")
    humanoid.Name = "Humanoid"
    humanoid.MaxHealth = 100
    humanoid.Health = 100
    humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
    humanoid.Parent = npc

    -- 2. Torso (Rugged leather duster coat)
    local torso = Instance.new("Part")
    torso.Name = "Torso"
    torso.Size = Vector3.new(2.1, 2.2, 1.2)
    torso.CFrame = spawnCF
    torso.Color = Color3.fromRGB(48, 42, 38) -- Dark aged leather
    torso.Material = Enum.Material.Fabric
    torso.Anchored = true
    torso.CanCollide = false
    torso.Parent = npc

    -- Warm inner vest
    local vest = Instance.new("Part")
    vest.Name = "Vest"
    vest.Size = Vector3.new(1.4, 1.8, 1.25)
    vest.CFrame = spawnCF * CFrame.new(0, 0, 0.02)
    vest.Color = Color3.fromRGB(92, 68, 48) -- Warm wool vest
    vest.Material = Enum.Material.Fabric
    vest.Anchored = true
    vest.CanCollide = false
    vest.Parent = npc

    -- 3. Head
    local head = Instance.new("Part")
    head.Name = "Head"
    head.Size = Vector3.new(1.25, 1.25, 1.25)
    head.CFrame = spawnCF * CFrame.new(0, 1.65, 0)
    head.Color = Color3.fromRGB(224, 178, 142) -- Weathered survivor skin
    head.Material = Enum.Material.SmoothPlastic
    head.Anchored = true
    head.CanCollide = false
    head.Parent = npc

    local faceMesh = Instance.new("SpecialMesh")
    faceMesh.MeshType = Enum.MeshType.Head
    faceMesh.Scale = Vector3.new(1.25, 1.25, 1.25)
    faceMesh.Parent = head

    -- Crimson winter cowl / scarf around neck
    local scarf = Instance.new("Part")
    scarf.Name = "Scarf"
    scarf.Size = Vector3.new(1.7, 0.5, 1.5)
    scarf.CFrame = spawnCF * CFrame.new(0, 1.15, 0)
    scarf.Color = Color3.fromRGB(165, 48, 40) -- Crimson scarf
    scarf.Material = Enum.Material.Fabric
    scarf.Anchored = true
    scarf.CanCollide = false
    scarf.Parent = npc

    -- Explorer brimmed hat
    local hatBrim = Instance.new("Part")
    hatBrim.Name = "HatBrim"
    hatBrim.Size = Vector3.new(2.4, 0.15, 2.4)
    hatBrim.CFrame = spawnCF * CFrame.new(0, 2.25, 0)
    hatBrim.Color = Color3.fromRGB(38, 32, 28)
    hatBrim.Material = Enum.Material.Slate
    hatBrim.Anchored = true
    hatBrim.CanCollide = false
    hatBrim.Parent = npc

    local hatCrown = Instance.new("Part")
    hatCrown.Name = "HatCrown"
    hatCrown.Size = Vector3.new(1.4, 0.65, 1.4)
    hatCrown.CFrame = spawnCF * CFrame.new(0, 2.60, 0)
    hatCrown.Color = Color3.fromRGB(48, 40, 34)
    hatCrown.Material = Enum.Material.Slate
    hatCrown.Anchored = true
    hatCrown.CanCollide = false
    hatCrown.Parent = npc

    -- 4. Arms
    for _, sideX in ipairs({ -1.35, 1.35 }) do
        local arm = Instance.new("Part")
        arm.Name = sideX < 0 and "LeftArm" or "RightArm"
        arm.Size = Vector3.new(0.9, 2.1, 0.9)
        arm.CFrame = spawnCF * CFrame.new(sideX, -0.05, 0)
        arm.Color = Color3.fromRGB(48, 42, 38)
        arm.Material = Enum.Material.Fabric
        arm.Anchored = true
        arm.CanCollide = false
        arm.Parent = npc
    end

    -- 5. Legs
    for _, sideX in ipairs({ -0.55, 0.55 }) do
        local leg = Instance.new("Part")
        leg.Name = sideX < 0 and "LeftLeg" or "RightLeg"
        leg.Size = Vector3.new(0.9, 2.2, 0.9)
        leg.CFrame = spawnCF * CFrame.new(sideX, -2.1, 0)
        leg.Color = Color3.fromRGB(34, 30, 28)
        leg.Material = Enum.Material.Fabric
        leg.Anchored = true
        leg.CanCollide = false
        leg.Parent = npc
    end

    -- 6. Merchant Wooden Pack on Back
    local pack = Instance.new("Part")
    pack.Name = "MerchantPack"
    pack.Size = Vector3.new(1.8, 2.0, 0.9)
    pack.CFrame = spawnCF * CFrame.new(0, 0.1, -0.9)
    pack.Color = Color3.fromRGB(115, 82, 54)
    pack.Material = Enum.Material.Wood
    pack.Anchored = true
    pack.CanCollide = false
    pack.Parent = npc

    -- Tiny lantern hanging on pack
    local lantern = Instance.new("Part")
    lantern.Name = "PackLantern"
    lantern.Size = Vector3.new(0.4, 0.55, 0.4)
    lantern.CFrame = spawnCF * CFrame.new(0.85, 0.5, -1.2)
    lantern.Color = Color3.fromRGB(240, 190, 75)
    lantern.Material = Enum.Material.Neon
    lantern.Anchored = true
    lantern.CanCollide = false
    lantern.Parent = npc

    local lanternLight = Instance.new("PointLight")
    lanternLight.Color = Color3.fromRGB(255, 195, 80)
    lanternLight.Range = 8
    lanternLight.Brightness = 0.85
    lanternLight.Parent = lantern

    -- 7. Floating Overhead Nameplate BillboardGui
    local bbg = Instance.new("BillboardGui")
    bbg.Name = "Nameplate"
    bbg.Size = UDim2.new(0, 240, 0, 75)
    bbg.StudsOffset = Vector3.new(0, 3.6, 0)
    bbg.AlwaysOnTop = true
    bbg.MaxDistance = 45
    bbg.Adornee = head
    bbg.Parent = head

    local nameLabel = Instance.new("TextLabel")
    nameLabel.Name = "Title"
    nameLabel.Size = UDim2.new(1, 0, 0, 32)
    nameLabel.Position = UDim2.new(0, 0, 0, 0)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = "★ SILAS ★"
    nameLabel.TextColor3 = Color3.fromRGB(255, 215, 80) -- Gold
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.TextSize = 22
    nameLabel.TextStrokeColor3 = Color3.fromRGB(20, 15, 10)
    nameLabel.TextStrokeTransparency = 0.2
    nameLabel.Parent = bbg

    local subLabel = Instance.new("TextLabel")
    subLabel.Name = "Subtitle"
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

    npc.Parent = Workspace
    TraderNPCSpawner.WireNPC(npc)

    local pos = spawnCF.Position
    print(string.format("🤝 [TraderNPCSpawner] Silas spawned successfully at Vector3.new(%.1f, %.1f, %.1f)!", pos.X, pos.Y, pos.Z))
    return npc
end

return TraderNPCSpawner
