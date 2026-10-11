--!strict
--[[
    InventorySystem.server.lua
    Server-authoritative item drop, pickup, and world resource interaction
    for "Don't Let the Fire Die". Based on docs/systems/INVENTORY_AND_ITEM_RULES.md.
    Developed for Fluenosity Studio.

    Features:
    - Empty starting inventory for all players (StartingLoadout = {})
    - Map-wide wood pile scanner: auto-attaches ProximityPrompt to user-placed wooden log piles
    - Strict 5 Wood Logs carry limit enforced across the player's entire inventory
    - In-camp Matchbox pickup (vintage matchbox with soft glow and auto-respawn)
    - Campfire fuel interaction (allows feeding collected wood into the campfire)
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
    local inv = playerInventories[player]
    if not inv then return 0 end

    local total = 0
    for s = 1, InventoryConfig.TOTAL_PERSONAL_SLOTS do
        local slot = inv[s]
        if slot and slot.Id == "standard_wood" then
            total = total + (slot.Count or 0)
        end
    end
    return total
end

-- Check if player has at least one of a specific item
local function hasItem(player: Player, itemId: string): boolean
    local inv = playerInventories[player]
    if not inv then return false end

    for s = 1, InventoryConfig.TOTAL_PERSONAL_SLOTS do
        local slot = inv[s]
        if slot and slot.Id == itemId and (slot.Count or 0) > 0 then
            return true
        end
    end
    return false
end

-- Add item to player inventory respecting stack sizes and unlocked slots
local function addPlayerItem(player: Player, itemId: string, amount: number): boolean
    local inv = playerInventories[player]
    if not inv then return false end

    local def = InventoryConfig.Items[itemId]
    if not def then return false end

    local maxStack = def.MaxStack or 1
    local unlockedSlots = InventoryConfig.UNLOCKED_SLOTS or 9

    -- 1. Try stacking into existing slot that has space
    local targetSlot: number? = nil
    for s = 1, unlockedSlots do
        local slot = inv[s]
        if slot and slot.Id == itemId and (slot.Count + amount) <= maxStack then
            targetSlot = s
            break
        end
    end

    -- 2. Otherwise find first empty unlocked slot
    if not targetSlot then
        for s = 1, unlockedSlots do
            if not inv[s] then
                targetSlot = s
                break
            end
        end
    end

    if not targetSlot then
        return false -- Inventory full
    end

    if inv[targetSlot] then
        inv[targetSlot].Count = inv[targetSlot].Count + amount
    else
        inv[targetSlot] = {
            Id = itemId,
            Count = amount,
        }
    end

    syncInventoryEvent:FireClient(player, inv)
    return true
end

-- Remove item count from player inventory
local function removePlayerItem(player: Player, itemId: string, amount: number): boolean
    local inv = playerInventories[player]
    if not inv then return false end

    local remainingToRemove = amount

    for s = 1, InventoryConfig.TOTAL_PERSONAL_SLOTS do
        local slot = inv[s]
        if slot and slot.Id == itemId then
            if slot.Count <= remainingToRemove then
                remainingToRemove = remainingToRemove - slot.Count
                inv[s] = nil
            else
                slot.Count = slot.Count - remainingToRemove
                remainingToRemove = 0
            end

            if remainingToRemove <= 0 then
                break
            end
        end
    end

    if remainingToRemove == 0 then
        syncInventoryEvent:FireClient(player, inv)
        return true
    end

    -- If not enough items found, re-sync anyway to stay consistent
    syncInventoryEvent:FireClient(player, inv)
    return false
end

local function initializePlayerInventory(player: Player)
    local inv = {}
    for slotIdx = 1, InventoryConfig.TOTAL_PERSONAL_SLOTS do
        local starting = InventoryConfig.StartingLoadout[slotIdx]
        if starting then
            inv[slotIdx] = {
                Id = starting.Id,
                Count = starting.Count,
            }
        else
            inv[slotIdx] = nil
        end
    end
    playerInventories[player] = inv
    syncInventoryEvent:FireClient(player, inv)
end

Players.PlayerAdded:Connect(function(player)
    initializePlayerInventory(player)
end)

Players.PlayerRemoving:Connect(function(player)
    playerInventories[player] = nil
end)

for _, p in ipairs(Players:GetPlayers()) do
    initializePlayerInventory(p)
end

-- Creates physical dropped item in workspace with ProximityPrompt
local function spawnDroppedItem(itemId: string, count: number, spawnCFrame: CFrame)
    local def = InventoryConfig.Items[itemId]
    if not def then return end

    local model = Instance.new("Model")
    model.Name = "Dropped_" .. def.Name:gsub("%s+", "")

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
        if itemId == "standard_wood" then
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

    -- Auto-clean low tier items if dropped items exceed 200
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

    -- Find first empty unlocked slot
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

-- Determines if an instance represents a placed wood log pile
local function isWoodPileInstance(inst: Instance): boolean
    if processedWoodPiles[inst] then return false end

    -- Exclude generated forest environment trees, rocks, ground cover
    local forestEnv = workspace:FindFirstChild("ForestEnvironment")
    if forestEnv and inst:IsDescendantOf(forestEnv) then
        return false
    end

    -- Exclude player characters
    if inst:IsA("Model") and Players:GetPlayerFromCharacter(inst) then
        return false
    end
    for _, pl in ipairs(Players:GetPlayers()) do
        if pl.Character and inst:IsDescendantOf(pl.Character) then
            return false
        end
    end

    -- Exclude dropped items folder and camp structures
    if inst:IsDescendantOf(droppedItemsFolder) then return false end
    local lowerName = inst.Name:lower()
    if lowerName:find("fence") or lowerName:find("bus") or lowerName:find("tower") then
        return false
    end

    -- Check CollectionService tag
    if CollectionService:HasTag(inst, "WoodPile") or CollectionService:HasTag(inst, "WoodSource") then
        return true
    end

    -- Check Model or Folder naming
    if inst:IsA("Model") or inst:IsA("Folder") then
        if lowerName:find("log") or lowerName:find("wood") or lowerName:find("timber") or lowerName:find("firewood") or lowerName:find("lumber") then
            return true
        end

        -- Check if model contains wood cylinders/parts (e.g. named Model from toolbox)
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

    -- Check standalone BasePart
    if inst:IsA("BasePart") and inst.Parent == workspace then
        if lowerName:find("log") or lowerName:find("woodpile") or lowerName:find("firewood") then
            return true
        end
    end

    return false
end

-- Attaches interaction prompt to a wood pile model or part
local function setupWoodPilePrompt(woodPile: Instance)
    if processedWoodPiles[woodPile] then return end
    processedWoodPiles[woodPile] = true

    local targetPart: BasePart? = nil

    if woodPile:IsA("Model") then
        if woodPile.PrimaryPart then
            targetPart = woodPile.PrimaryPart
        else
            -- Find the largest BasePart near the center
            local parts = {}
            for _, d in ipairs(woodPile:GetDescendants()) do
                if d:IsA("BasePart") then
                    table.insert(parts, d)
                end
            end
            if #parts > 0 then
                -- Sort by size or pick middle one
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

    -- Check if prompt already exists
    local existingPrompt = targetPart:FindFirstChild("WoodGatherPrompt") or woodPile:FindFirstChild("WoodGatherPrompt", true)
    if existingPrompt then return end

    local prompt = Instance.new("ProximityPrompt")
    prompt.Name = "WoodGatherPrompt"
    prompt.ActionText = "Take Wood Log"
    prompt.ObjectText = "Wood Pile (Max 5)"
    prompt.KeyboardKeyCode = Enum.KeyCode.E
    prompt.GamepadKeyCode = Enum.KeyCode.ButtonX
    prompt.HoldDuration = 0.35
    prompt.MaxActivationDistance = 12
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
    for _, obj in ipairs(workspace:GetChildren()) do
        if isWoodPileInstance(obj) then
            setupWoodPilePrompt(obj)
        end
    end
end

-- Run initial scan and listen for dynamic additions
task.defer(function()
    task.wait(1.5)
    scanAndSetupWoodPiles()

    workspace.ChildAdded:Connect(function(child)
        task.wait(0.5)
        if isWoodPileInstance(child) then
            setupWoodPilePrompt(child)
        end
    end)
end)

--------------------------------------------------------------------------------
-- 2. CAMP MATCHBOX PICKUP
--------------------------------------------------------------------------------
local function findCampsiteCenter(): (Vector3, BasePart?)
    -- 1. Look for part containing Fire instance (Campfire)
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("Fire") and obj.Parent and obj.Parent:IsA("BasePart") then
            return obj.Parent.Position, obj.Parent :: BasePart
        end
    end

    -- 2. Look for part named campfire or firepit
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("BasePart") and (obj.Name:lower() == "campfire" or obj.Name:lower() == "firepit") then
            return obj.Position, obj
        end
    end

    -- 3. Look for table or bus in campsite
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("BasePart") and (obj.Name:lower():find("table") or obj.Name:lower():find("bench")) then
            return obj.Position, obj
        end
    end

    return Vector3.new(0, 10, 0), nil
end

local function spawnCampMatchbox()
    -- Look specifically for the dedicated rustic MatchboxStump placed near the camp perimeter
    local matchboxStump = workspace:FindFirstChild("MatchboxStump", true)
    local targetPos: Vector3
    local targetCFrame: CFrame

    if matchboxStump and matchboxStump:IsA("BasePart") then
        targetPos = matchboxStump.Position + Vector3.new(0, (matchboxStump.Size.Y / 2) + 0.22, 0)
        targetCFrame = CFrame.new(targetPos) * CFrame.Angles(0, math.rad(28), 0)
    else
        -- Fallback: Raycast to ground outside the campfire ring (6.6, -4.8)
        local groundY = 0
        local rayParams = RaycastParams.new()
        rayParams.FilterType = Enum.RaycastFilterType.Include
        local terrain = workspace:FindFirstChildOfClass("Terrain") or workspace.Terrain
        if terrain then rayParams.FilterDescendantsInstances = { terrain } end
        local hit = workspace:Raycast(Vector3.new(6.6, 150, -4.8), Vector3.new(0, -250, 0), rayParams)
        if hit then groundY = hit.Position.Y end

        targetPos = Vector3.new(6.6, groundY + 0.35, -4.8)
        targetCFrame = CFrame.new(targetPos) * CFrame.Angles(0, math.rad(28), 0)
    end

    -- Clean up any existing CampMatchbox
    local existingBox = workspace:FindFirstChild("CampMatchbox")
    if existingBox then
        existingBox:Destroy()
    end

    -- Construct vintage AAA matchbox model
    local matchboxModel = Instance.new("Model")
    matchboxModel.Name = "CampMatchbox"

    -- Main Cardboard Sleeve (Deep Crimson Red)
    local sleeve = Instance.new("Part")
    sleeve.Name = "Sleeve"
    sleeve.Size = Vector3.new(0.85, 0.38, 1.35)
    sleeve.CFrame = targetCFrame
    sleeve.Color = Color3.fromRGB(182, 44, 38) -- Vintage crimson red
    sleeve.Material = Enum.Material.SmoothPlastic
    sleeve.Anchored = true
    sleeve.CanCollide = true
    sleeve.TopSurface = Enum.SurfaceType.Smooth
    sleeve.BottomSurface = Enum.SurfaceType.Smooth
    sleeve.Parent = matchboxModel

    -- Friction Strike Strip on lateral edge
    local striker = Instance.new("Part")
    striker.Name = "Striker"
    striker.Size = Vector3.new(0.06, 0.32, 1.30)
    striker.CFrame = sleeve.CFrame * CFrame.new(0.43, 0, 0)
    striker.Color = Color3.fromRGB(46, 38, 34) -- Charcoal friction sandpaper
    striker.Material = Enum.Material.Slate
    striker.Anchored = true
    striker.CanCollide = false
    striker.Parent = matchboxModel

    -- Inner Sliding Drawer (Cardboard cream)
    local drawer = Instance.new("Part")
    drawer.Name = "Drawer"
    drawer.Size = Vector3.new(0.74, 0.30, 0.40)
    drawer.CFrame = sleeve.CFrame * CFrame.new(0, 0, 0.65)
    drawer.Color = Color3.fromRGB(228, 215, 186) -- Warm aged cardboard
    drawer.Material = Enum.Material.SmoothPlastic
    drawer.Anchored = true
    drawer.CanCollide = false
    drawer.Parent = matchboxModel

    -- Tiny Matchstick tips peeking out
    for i = -1, 1 do
        local stick = Instance.new("Part")
        stick.Name = "Matchstick_" .. i
        stick.Size = Vector3.new(0.08, 0.08, 0.35)
        stick.CFrame = drawer.CFrame * CFrame.new(i * 0.16, 0.04, 0.12)
        stick.Color = Color3.fromRGB(215, 35, 35) -- Red sulfur phosphorus tip
        stick.Material = Enum.Material.SmoothPlastic
        stick.Anchored = true
        stick.CanCollide = false
        stick.Parent = matchboxModel
    end

    -- Inviting warm golden amber glow
    local glowLight = Instance.new("PointLight")
    glowLight.Name = "MatchboxGlow"
    glowLight.Color = Color3.fromRGB(255, 195, 75)
    glowLight.Range = 7.0
    glowLight.Brightness = 0.95
    glowLight.Shadows = false
    glowLight.Parent = sleeve

    -- Proximity Prompt (Tightened activation zone so it never overlaps with campfire or seats)
    local prompt = Instance.new("ProximityPrompt")
    prompt.Name = "MatchboxPrompt"
    prompt.ActionText = "Take Matchbox"
    prompt.ObjectText = "MATCHBOX"
    prompt.KeyboardKeyCode = Enum.KeyCode.E
    prompt.GamepadKeyCode = Enum.KeyCode.ButtonX
    prompt.HoldDuration = 0.2
    prompt.MaxActivationDistance = 5.2
    prompt.RequiresLineOfSight = true
    prompt.Parent = sleeve

    matchboxModel.PrimaryPart = sleeve
    matchboxModel.Parent = workspace

    prompt.Triggered:Connect(function(player: Player)
        if hasItem(player, "matches") then
            sendNotification(
                player,
                "You already have a Matchbox!",
                "flame",
                Color3.fromRGB(255, 190, 60)
            )
            return
        end

        local added = addPlayerItem(player, "matches", 1)
        if added then
            sendNotification(
                player,
                "Acquired Matchbox! Keep it safe to ignite the campfire.",
                "flame",
                Color3.fromRGB(255, 190, 60)
            )

            -- Smooth pickup feedback with 20s respawn timer
            prompt.Enabled = false
            for _, part in ipairs(matchboxModel:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.Transparency = 1
                end
            end
            glowLight.Enabled = false

            task.delay(20, function()
                if matchboxModel and matchboxModel.Parent then
                    for _, part in ipairs(matchboxModel:GetDescendants()) do
                        if part:IsA("BasePart") then
                            part.Transparency = 0
                        end
                    end
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

-- Initialize Camp items immediately without artificial delays
task.defer(function()
    spawnCampMatchbox()
end)

print("[InventorySystem] Loaded: Wood Pile scanner & Camp Matchbox active.")
