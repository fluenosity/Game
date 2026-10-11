--!strict
--[[
    InventorySystem.server.lua
    Server-authoritative item drop, pickup, and world resource interaction
    for "Don't Let the Fire Die". Based on docs/systems/INVENTORY_AND_ITEM_RULES.md.
    Developed for Fluenosity Studio.

    Features:
    - Empty starting inventory for all players (StartingLoadout = {})
    - Map-wide wood pile scanner: auto-attaches ProximityPrompt to genuine woodland log piles
    - Strict 5 Wood Logs carry limit enforced across the player's entire inventory
    - In-camp Vintage Matchbox pickup on dedicated stone pedestal (auto-respawn for co-op)
    - Full exclusion of campsite props (benches, hearth, fire, pedestal) from wood pile scanner
    - Toast notification event dispatching to clients
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")
local CollectionService = game:GetService("CollectionService")
local TweenService = game:GetService("TweenService")

local sharedFolder = ReplicatedStorage:WaitForChild("FluenosityShared")
local InventoryConfig = require(sharedFolder:WaitForChild("InventoryConfig"))

-- Ensure RemoteEvents exist
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

local dropItemEvent = getOrCreateRemoteEvent("RequestDropItem")
local pickupItemEvent = getOrCreateRemoteEvent("RequestPickupItem")
local syncInventoryEvent = getOrCreateRemoteEvent("SyncInventory")
local discardItemEvent = getOrCreateRemoteEvent("RequestDiscardItem")
local splitItemEvent = getOrCreateRemoteEvent("RequestSplitItem")
local notificationEvent = getOrCreateRemoteEvent("ShowNotification")

-- Folder for dropped items in workspace
local droppedItemsFolder = workspace:FindFirstChild("DroppedItems")
if not droppedItemsFolder then
    local folder = Instance.new("Folder")
    folder.Name = "DroppedItems"
    folder.Parent = workspace
    droppedItemsFolder = folder
end

-- Server inventory state shared via InventoryManager
local InventoryManager = require(script.Parent:WaitForChild("InventoryManager"))
local playerInventories = InventoryManager.GetInventoriesTable()

-- Send sleek toast notification to player
local function sendNotification(player: Player, message: string, iconName: string?, accentColor: Color3?)
    notificationEvent:FireClient(
        player,
        message,
        iconName or "info",
        accentColor or Color3.fromRGB(245, 160, 40)
    )
end

-- Count total wood across ALL inventory slots for a given player
local function getTotalWoodCount(player: Player): number
    return InventoryManager.GetWoodCount(player)
end

-- Check if player has at least one of a specific item
local function hasItem(player: Player, itemId: string): boolean
    local has = InventoryManager.HasItem(player, itemId)
    return has
end

-- Add item to player inventory respecting stack sizes and unlocked slots
local function addPlayerItem(player: Player, itemId: string, amount: number): boolean
    return InventoryManager.AddItem(player, itemId, amount)
end

-- Remove item count from player inventory
local function removePlayerItem(player: Player, itemId: string, amount: number): boolean
    return InventoryManager.ConsumeItem(player, itemId, amount)
end

-- Creates physical dropped item in workspace with ProximityPrompt
local function spawnDroppedItem(itemId: string, count: number, spawnCFrame: CFrame)
    local def = InventoryConfig.Items[itemId]
    if not def then return end

    local model = Instance.new("Model")
    model.Name = "Dropped_" .. def.Name:gsub("%s+", "")
    CollectionService:AddTag(model, "IgnoreWoodScanner")

    local part = Instance.new("Part")
    part.Name = "Handle"
    part.Size = Vector3.new(1.2, 0.8, 1.2)
    part.CFrame = spawnCFrame + Vector3.new(0, 0.5, 0)
    part.Color = def.AccentColor
    part.Material = Enum.Material.SmoothPlastic
    part.TopSurface = Enum.SurfaceType.Smooth
    part.BottomSurface = Enum.SurfaceType.Smooth
    part.CanCollide = true
    part.Anchored = false
    part.Parent = model

    local mesh = Instance.new("SpecialMesh")
    mesh.MeshType = Enum.MeshType.Brick
    mesh.Scale = Vector3.new(0.9, 0.7, 0.9)
    mesh.Parent = part

    local pointLight = Instance.new("PointLight")
    pointLight.Color = def.AccentColor
    pointLight.Range = 8
    pointLight.Brightness = 1.2
    pointLight.Parent = part

    local prompt = Instance.new("ProximityPrompt")
    prompt.Name = "PickupPrompt"
    prompt.ActionText = "Pick Up"
    prompt.ObjectText = def.Name .. (count > 1 and (" (x" .. count .. ")") or "")
    prompt.KeyboardKeyCode = Enum.KeyCode.E
    prompt.HoldDuration = 0
    prompt.MaxActivationDistance = 9
    prompt.RequiresLineOfSight = false
    prompt.Parent = part

    model.PrimaryPart = part
    model.Parent = droppedItemsFolder

    prompt.Triggered:Connect(function(playerTriggering: Player)
        -- Enforce strict 5 Wood limit when picking up dropped wood
        if itemId == "standard_wood" or itemId == "wood" then
            local currentWood = getTotalWoodCount(playerTriggering)
            if (currentWood + count) > 5 then
                sendNotification(
                    playerTriggering,
                    string.format("Cannot pick up: Exceeds 5 Wood Log carry limit (%d/5)", currentWood),
                    "alert-triangle",
                    Color3.fromRGB(255, 175, 45)
                )
                return
            end
        end

        local added = addPlayerItem(playerTriggering, itemId, count)
        if added then
            sendNotification(
                playerTriggering,
                "Picked up " .. def.Name .. (count > 1 and (" (x" .. count .. ")") or ""),
                def.IconName or "package",
                def.AccentColor
            )
            model:Destroy()
        else
            sendNotification(
                playerTriggering,
                "Backpack full! Free up a slot.",
                "backpack",
                Color3.fromRGB(255, 85, 85)
            )
        end
    end)

    if droppedItemsFolder and #droppedItemsFolder:GetChildren() > 200 then
        local oldest = droppedItemsFolder:GetChildren()[1]
        if oldest then
            oldest:Destroy()
        end
    end
end

-- Client requests drop of active item
dropItemEvent.OnServerEvent:Connect(function(player: Player, slotIndex: number)
    if typeof(slotIndex) ~= "number" then return end
    local inv = playerInventories[player]
    if not inv then return end

    local slot = inv[slotIndex]
    if not slot or slot.Count <= 0 then return end

    local char = player.Character
    if not char or not char.PrimaryPart then return end

    local itemId = slot.Id
    slot.Count = slot.Count - 1
    if slot.Count <= 0 then
        inv[slotIndex] = nil
    end

    syncInventoryEvent:FireClient(player, inv)

    local dropCFrame = char.PrimaryPart.CFrame * CFrame.new(0, 0, -2.5)
    spawnDroppedItem(itemId, 1, dropCFrame)
end)

-- Client requests permanent discard of item in slot
discardItemEvent.OnServerEvent:Connect(function(player: Player, slotIndex: number)
    if typeof(slotIndex) ~= "number" then return end
    local inv = playerInventories[player]
    if not inv then return end

    local slot = inv[slotIndex]
    if not slot then return end

    inv[slotIndex] = nil
    syncInventoryEvent:FireClient(player, inv)
end)

-- Client requests splitting an item stack in half
splitItemEvent.OnServerEvent:Connect(function(player: Player, slotIndex: number)
    if typeof(slotIndex) ~= "number" then return end
    local inv = playerInventories[player]
    if not inv then return end

    local slot = inv[slotIndex]
    if not slot or slot.Count <= 1 then return end

    local emptySlot: number? = nil
    for s = 1, (InventoryConfig.UNLOCKED_SLOTS or 9) do
        if not inv[s] then
            emptySlot = s
            break
        end
    end

    if emptySlot then
        local half = math.floor(slot.Count / 2)
        if half > 0 then
            slot.Count = slot.Count - half
            inv[emptySlot] = {
                Id = slot.Id,
                Count = half,
            }
            syncInventoryEvent:FireClient(player, inv)
        end
    end
end)

--------------------------------------------------------------------------------
-- 1. MAP-WIDE WOOD PILE DETECTOR & 5-LOG CARRY LIMIT LOGIC
--------------------------------------------------------------------------------
local processedWoodPiles: { [Instance]: boolean } = {}

-- Clean up any stray WoodGatherPrompt from non-wood props
local function purgeCampPrompts()
    local campContainers = {
        workspace:FindFirstChild("CampfireSeats"),
        workspace:FindFirstChild("Campfire"),
        workspace:FindFirstChild("CampMatchbox"),
        workspace:FindFirstChild("MatchboxPedestalModel"),
        workspace:FindFirstChild("MatchboxStumpModel"),
    }
    for _, container in ipairs(campContainers) do
        if container then
            for _, d in ipairs(container:GetDescendants()) do
                if d:IsA("ProximityPrompt") and d.Name == "WoodGatherPrompt" then
                    d:Destroy()
                end
            end
        end
    end
end

-- Determines if an instance represents a placed woodland log pile
local function isWoodPileInstance(inst: Instance): boolean
    if processedWoodPiles[inst] then return false end

    -- Explicit ignore tag
    if CollectionService:HasTag(inst, "IgnoreWoodScanner") then return false end

    -- Exclude generated forest environment trees, rocks, ground cover
    local forestEnv = workspace:FindFirstChild("ForestEnvironment")
    if forestEnv and inst:IsDescendantOf(forestEnv) then return false end

    -- Exclude player characters
    if inst:IsA("Model") and Players:GetPlayerFromCharacter(inst) then return false end
    for _, pl in ipairs(Players:GetPlayers()) do
        if pl.Character and inst:IsDescendantOf(pl.Character) then return false end
    end

    -- Exclude dropped items folder
    if inst:IsDescendantOf(droppedItemsFolder) then return false end

    -- Explicitly exclude the Campfire, Seats, Matchbox, Pedestal (CampFirewoodStack is kept!)
    for _, containerName in ipairs({ "CampfireSeats", "Campfire", "CampMatchbox", "MatchboxPedestalModel", "MatchboxStumpModel" }) do
        local container = workspace:FindFirstChild(containerName)
        if container and (inst == container or inst:IsDescendantOf(container)) then
            return false
        end
    end

    local lowerName = inst.Name:lower()

    -- Exclude campsite furniture, seats, matchbox, fences, structures
    if lowerName:find("seat") or lowerName:find("bench") or lowerName:find("hearth")
       or lowerName:find("pedestal") or lowerName:find("match") or lowerName:find("stump")
       or lowerName:find("bus") or lowerName:find("tower") or lowerName:find("fence")
       or lowerName:find("ash") then
        return false
    end

    -- If tagged with CollectionService
    if CollectionService:HasTag(inst, "WoodPile") or CollectionService:HasTag(inst, "WoodSource") then
        return true
    end

    -- Match any Model or Folder named with wood / log / timber / firewood / lumber / pile
    if inst:IsA("Model") or inst:IsA("Folder") then
        if lowerName:find("wood") or lowerName:find("log") or lowerName:find("timber")
           or lowerName:find("firewood") or lowerName:find("lumber") or lowerName:find("pile") then
            return true
        end

        -- Check if model contains wood cylinders/parts (e.g. from toolbox)
        local woodPartCount = 0
        local totalDescendants = 0
        for _, child in ipairs(inst:GetDescendants()) do
            if child:IsA("BasePart") then
                totalDescendants = totalDescendants + 1
                if child.Material == Enum.Material.Wood or child.Material == Enum.Material.WoodPlanks or child.Name:lower():find("log") or child.Name:lower():find("cylinder") then
                    woodPartCount = woodPartCount + 1
                end
            end
        end

        if totalDescendants >= 2 and totalDescendants <= 100 and (woodPartCount / totalDescendants) >= 0.5 then
            return true
        end
    end

    -- Match standalone BasePart in workspace
    if inst:IsA("BasePart") and inst.Parent == workspace then
        if lowerName:find("wood") or lowerName:find("log") or lowerName:find("firewood") or lowerName:find("timber") then
            return true
        end
    end

    return false
end

-- Attaches interaction prompt to a genuine woodland wood pile
local function setupWoodPilePrompt(woodPile: Instance)
    if processedWoodPiles[woodPile] then return end
    processedWoodPiles[woodPile] = true

    local targetPart: BasePart? = nil

    if woodPile:IsA("Model") then
        if woodPile.PrimaryPart then
            targetPart = woodPile.PrimaryPart
        else
            local parts = {}
            for _, d in ipairs(woodPile:GetDescendants()) do
                if d:IsA("BasePart") then
                    table.insert(parts, d)
                end
            end
            if #parts > 0 then
                targetPart = parts[math.ceil(#parts / 2)]
                woodPile.PrimaryPart = targetPart
            end
        end
    elseif woodPile:IsA("BasePart") then
        targetPart = woodPile
    elseif woodPile:IsA("Folder") then
        for _, d in ipairs(woodPile:GetDescendants()) do
            if d:IsA("BasePart") then
                targetPart = d
                break
            end
        end
    end

    if not targetPart then return end

    local existingPrompt = targetPart:FindFirstChild("WoodGatherPrompt") or woodPile:FindFirstChild("WoodGatherPrompt", true)
    if existingPrompt then return end

    local prompt = Instance.new("ProximityPrompt")
    prompt.Name = "WoodGatherPrompt"
    prompt.ActionText = "Take Wood Log"
    prompt.ObjectText = "Wood Pile (Max 5)"
    prompt.KeyboardKeyCode = Enum.KeyCode.E
    prompt.GamepadKeyCode = Enum.KeyCode.ButtonX
    prompt.HoldDuration = 0.25
    prompt.MaxActivationDistance = 9.0
    prompt.RequiresLineOfSight = false
    prompt.Parent = targetPart

    prompt.Triggered:Connect(function(player: Player)
        local curWood = getTotalWoodCount(player)

        -- Strict 5-Wood limit
        if curWood >= 5 then
            sendNotification(
                player,
                "Carrying capacity full! (Max 5 Wood Logs per user)",
                "alert-triangle",
                Color3.fromRGB(255, 175, 45)
            )
            return
        end

        local added = addPlayerItem(player, "standard_wood", 1)
        if added then
            local newTotal = curWood + 1
            sendNotification(
                player,
                string.format("Gathered Wood Log (%d/5)", newTotal),
                "tree-pine",
                Color3.fromRGB(170, 215, 120)
            )
        else
            sendNotification(
                player,
                "Backpack full! Free up a slot.",
                "backpack",
                Color3.fromRGB(255, 85, 85)
            )
        end
    end)
end

-- Scan workspace for placed wood piles
local function scanAndSetupWoodPiles()
    purgeCampPrompts()
    for _, obj in ipairs(workspace:GetChildren()) do
        if isWoodPileInstance(obj) then
            setupWoodPilePrompt(obj)
        end
    end

    -- Also check any models tagged with WoodPile anywhere in workspace
    for _, tagged in ipairs(CollectionService:GetTagged("WoodPile")) do
        if isWoodPileInstance(tagged) then
            setupWoodPilePrompt(tagged)
        end
    end
end

-- Run initial scan and listen for dynamic additions
task.defer(function()
    task.wait(1.0)
    scanAndSetupWoodPiles()

    workspace.ChildAdded:Connect(function(child)
        task.wait(0.4)
        if isWoodPileInstance(child) then
            setupWoodPilePrompt(child)
        end
    end)
end)

--------------------------------------------------------------------------------
-- 2. CAMP VINTAGE MATCHBOX PROP & INTERACTION
--------------------------------------------------------------------------------
local function spawnCampMatchbox()
    local existingBox = workspace:FindFirstChild("CampMatchbox")
    if existingBox then
        existingBox:Destroy()
    end

    local pedestalSlab = workspace:FindFirstChild("PedestalSlab", true)
    local targetCFrame: CFrame

    if pedestalSlab and pedestalSlab:IsA("BasePart") then
        local targetPos = pedestalSlab.Position + Vector3.new(0, (pedestalSlab.Size.Y / 2) + 0.20, 0)
        targetCFrame = CFrame.new(targetPos) * CFrame.Angles(0, math.rad(38), 0)
    else
        local groundY = 0
        local rayParams = RaycastParams.new()
        rayParams.FilterType = Enum.RaycastFilterType.Include
        local terrain = workspace:FindFirstChildOfClass("Terrain") or workspace.Terrain
        if terrain then rayParams.FilterDescendantsInstances = { terrain } end
        local hit = workspace:Raycast(Vector3.new(9.2, 150, -3.8), Vector3.new(0, -250, 0), rayParams)
        if hit then groundY = hit.Position.Y end

        local targetPos = Vector3.new(9.2, groundY + 1.45, -3.8)
        targetCFrame = CFrame.new(targetPos) * CFrame.Angles(0, math.rad(38), 0)
    end

    local matchboxModel = Instance.new("Model")
    matchboxModel.Name = "CampMatchbox"
    CollectionService:AddTag(matchboxModel, "IgnoreWoodScanner")

    local sleeve = Instance.new("Part")
    sleeve.Name = "Sleeve"
    sleeve.Size = Vector3.new(1.10, 0.40, 1.65)
    sleeve.CFrame = targetCFrame
    sleeve.Color = Color3.fromRGB(182, 42, 36)
    sleeve.Material = Enum.Material.SmoothPlastic
    sleeve.Anchored = true
    sleeve.CanCollide = true
    sleeve.TopSurface = Enum.SurfaceType.Smooth
    sleeve.BottomSurface = Enum.SurfaceType.Smooth
    sleeve.Parent = matchboxModel

    local surfaceGui = Instance.new("SurfaceGui")
    surfaceGui.Name = "VintageLabel"
    surfaceGui.Face = Enum.NormalId.Top
    surfaceGui.CanvasSize = Vector2.new(400, 600)
    surfaceGui.LightInfluence = 0.35
    surfaceGui.SizingMode = Enum.SurfaceGuiSizingMode.FixedSize
    surfaceGui.Parent = sleeve

    local cardFrame = Instance.new("Frame")
    cardFrame.Name = "CardFrame"
    cardFrame.Size = UDim2.fromScale(1, 1)
    cardFrame.BackgroundColor3 = Color3.fromRGB(246, 240, 224)
    cardFrame.BorderSizePixel = 0
    cardFrame.Parent = surfaceGui

    local innerBorder = Instance.new("UIStroke")
    innerBorder.Color = Color3.fromRGB(48, 38, 30)
    innerBorder.Thickness = 6
    innerBorder.Parent = cardFrame

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0.04, 0)
    corner.Parent = cardFrame

    local titleLabel = Instance.new("TextLabel")
    titleLabel.Name = "Title"
    titleLabel.Size = UDim2.new(1, -24, 0, 70)
    titleLabel.Position = UDim2.new(0, 12, 0, 28)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = "★ SAFETY MATCHES ★"
    titleLabel.TextColor3 = Color3.fromRGB(175, 35, 28)
    titleLabel.Font = Enum.Font.Fondamento
    titleLabel.TextSize = 26
    titleLabel.TextScaled = true
    titleLabel.Parent = cardFrame

    local emblem = Instance.new("TextLabel")
    emblem.Name = "Emblem"
    emblem.Size = UDim2.new(0, 100, 0, 100)
    emblem.Position = UDim2.new(0.5, -50, 0.30, 0)
    emblem.BackgroundTransparency = 1
    emblem.Text = "🔥"
    emblem.TextSize = 72
    emblem.Parent = cardFrame

    local subLabel = Instance.new("TextLabel")
    subLabel.Name = "Subtitle"
    subLabel.Size = UDim2.new(1, -24, 0, 50)
    subLabel.Position = UDim2.new(0, 12, 0.54, 0)
    subLabel.BackgroundTransparency = 1
    subLabel.Text = "THE SANCTUARY FLAME"
    subLabel.TextColor3 = Color3.fromRGB(52, 42, 34)
    subLabel.Font = Enum.Font.GothamBold
    subLabel.TextSize = 20
    subLabel.Parent = cardFrame

    local descLabel = Instance.new("TextLabel")
    descLabel.Name = "QualityMark"
    descLabel.Size = UDim2.new(1, -24, 0, 40)
    descLabel.Position = UDim2.new(0, 12, 0.68, 0)
    descLabel.BackgroundTransparency = 1
    descLabel.Text = "DAMP PROOF • SULPHUR TIP"
    descLabel.TextColor3 = Color3.fromRGB(110, 95, 80)
    descLabel.Font = Enum.Font.GothamMedium
    descLabel.TextSize = 15
    descLabel.Parent = cardFrame

    local footerLabel = Instance.new("TextLabel")
    footerLabel.Name = "Footer"
    footerLabel.Size = UDim2.new(1, -24, 0, 40)
    footerLabel.Position = UDim2.new(0, 12, 0.84, 0)
    footerLabel.BackgroundTransparency = 1
    footerLabel.Text = "STRIKE ON BOX • FLUENOSITY"
    footerLabel.TextColor3 = Color3.fromRGB(48, 38, 30)
    footerLabel.Font = Enum.Font.GothamBold
    footerLabel.TextSize = 16
    footerLabel.Parent = cardFrame

    for _, sideX in ipairs({ -0.56, 0.56 }) do
        local striker = Instance.new("Part")
        striker.Name = "StrikerStrip"
        striker.Size = Vector3.new(0.05, 0.34, 1.60)
        striker.CFrame = sleeve.CFrame * CFrame.new(sideX, 0, 0)
        striker.Color = Color3.fromRGB(46, 38, 34)
        striker.Material = Enum.Material.Slate
        striker.Anchored = true
        striker.CanCollide = false
        striker.Parent = matchboxModel
    end

    local drawer = Instance.new("Part")
    drawer.Name = "Drawer"
    drawer.Size = Vector3.new(0.96, 0.32, 0.65)
    drawer.CFrame = sleeve.CFrame * CFrame.new(0, 0, 0.72)
    drawer.Color = Color3.fromRGB(224, 210, 182)
    drawer.Material = Enum.Material.SmoothPlastic
    drawer.Anchored = true
    drawer.CanCollide = false
    drawer.Parent = matchboxModel

    local stickOffsets = { -0.32, -0.11, 0.11, 0.32 }
    for i, offX in ipairs(stickOffsets) do
        local stick = Instance.new("Part")
        stick.Name = "MatchstickStem_" .. i
        stick.Size = Vector3.new(0.07, 0.07, 0.48)
        stick.CFrame = drawer.CFrame * CFrame.new(offX, 0.05, 0.04)
        stick.Color = Color3.fromRGB(226, 204, 165)
        stick.Material = Enum.Material.Wood
        stick.Anchored = true
        stick.CanCollide = false
        stick.Parent = matchboxModel

        local head = Instance.new("Part")
        head.Name = "MatchHead_" .. i
        head.Shape = Enum.PartType.Ball
        head.Size = Vector3.new(0.13, 0.13, 0.13)
        head.CFrame = stick.CFrame * CFrame.new(0, 0, 0.25)
        head.Color = Color3.fromRGB(215, 34, 26)
        head.Material = Enum.Material.SmoothPlastic
        head.Anchored = true
        head.CanCollide = false
        head.Parent = matchboxModel
    end

    local glowLight = Instance.new("PointLight")
    glowLight.Name = "MatchboxGlow"
    glowLight.Color = Color3.fromRGB(255, 195, 75)
    glowLight.Range = 5.5
    glowLight.Brightness = 0.85
    glowLight.Shadows = false
    glowLight.Parent = sleeve

    local prompt = Instance.new("ProximityPrompt")
    prompt.Name = "MatchboxPrompt"
    prompt.ActionText = "Take Matchbox"
    prompt.ObjectText = "SAFETY MATCHES"
    prompt.KeyboardKeyCode = Enum.KeyCode.E
    prompt.GamepadKeyCode = Enum.KeyCode.ButtonX
    prompt.HoldDuration = 0.15
    prompt.MaxActivationDistance = 4.8
    prompt.RequiresLineOfSight = true
    prompt.Parent = sleeve

    matchboxModel.PrimaryPart = sleeve
    matchboxModel.Parent = workspace

    prompt.Triggered:Connect(function(player: Player)
        if InventoryManager.HasItem(player, "matchbox") then
            sendNotification(
                player,
                "You already carry a Safety Matchbox!",
                "flame",
                Color3.fromRGB(255, 190, 60)
            )
            return
        end

        local added = InventoryManager.AddItem(player, "matchbox", 1)
        if added then
            sendNotification(
                player,
                "Acquired Safety Matchbox! Use with wood logs to light the campfire.",
                "flame",
                Color3.fromRGB(255, 190, 60)
            )

            prompt.Enabled = false
            for _, part in ipairs(matchboxModel:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.Transparency = 1
                end
            end
            surfaceGui.Enabled = false
            glowLight.Enabled = false

            task.delay(20, function()
                if matchboxModel and matchboxModel.Parent then
                    for _, part in ipairs(matchboxModel:GetDescendants()) do
                        if part:IsA("BasePart") then
                            part.Transparency = 0
                        end
                    end
                    surfaceGui.Enabled = true
                    glowLight.Enabled = true
                    prompt.Enabled = true
                end
            end)
        else
            sendNotification(
                player,
                "Backpack full! Free up a slot.",
                "backpack",
                Color3.fromRGB(255, 85, 85)
            )
        end
    end)
end

task.defer(function()
    spawnCampMatchbox()
end)

print("[InventorySystem] Loaded: Wood Pile scanner & Camp Matchbox active.")
