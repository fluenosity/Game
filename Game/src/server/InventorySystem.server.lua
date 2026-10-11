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
-- 1. UNIVERSAL WOOD PILE INTERACTION SYSTEM (ALL WOOD PILES SUPPORTED)
--------------------------------------------------------------------------------
local registeredWoodPiles: { [Instance]: boolean } = {}

-- Checks whether a ProximityPrompt is a wood gather prompt
local function isWoodPromptInstance(prompt: ProximityPrompt): boolean
    if prompt.Name == "WoodGatherPrompt" or prompt.Name == "WoodPilePrompt" then
        return true
    end
    if prompt.ActionText == "Take Wood Log" or prompt.ActionText == "Gather Wood" then
        return true
    end
    local objText = prompt.ObjectText
    if objText and (objText:find("Wood Pile") or objText:find("Wood Log")) then
        return true
    end
    return false
end

-- Check if an instance is part of something that should NEVER be a wood gather pile
local function isBlacklistedWoodObject(inst: Instance): boolean
    local current: Instance? = inst
    while current and current ~= workspace do
        local l = current.Name:lower()
        if l:find("barrel") or l:find("tent") or l:find("trader") or l:find("silas")
            or l:find("merchant") or l:find("house") or l:find("cabin") or l:find("shop")
            or l:find("camp") or l:find("bench") or l:find("chair") or l:find("seat")
            or l:find("table") or l:find("counter") or l:find("shelf") or l:find("crate")
            or l:find("chest") or l:find("matchbox") or l:find("torch") or l:find("lantern")
            or l:find("dropped") then
            return true
        end
        if CollectionService:HasTag(current, "ChoppableTree") or CollectionService:HasTag(current, "TraderHouse") then
            return true
        end
        if current:IsA("Model") and current:FindFirstChildOfClass("Humanoid") then
            return true
        end
        current = current.Parent
    end
    return false
end

-- Checks if a Model or BasePart is a legitimate wood log pile
local function isCandidateWoodPile(inst: Instance): boolean
    if isBlacklistedWoodObject(inst) then
        return false
    end

    if CollectionService:HasTag(inst, "WoodPile") then
        return true
    end

    local name = inst.Name:lower()
    local exactNames = {
        ["woodlandlogpile"] = true,
        ["woodpile"] = true,
        ["wood pile"] = true,
        ["wood_pile"] = true,
        ["logpile"] = true,
        ["log pile"] = true,
        ["log_pile"] = true,
        ["firewoodpile"] = true,
        ["stackedlogs"] = true,
        ["logstack"] = true,
        ["woodstack"] = true,
        ["logs"] = true,
        ["woodlogs"] = true,
        ["wood_logs"] = true,
        ["cutlogs"] = true,
        ["firewood"] = true,
        ["timberpile"] = true,
        ["timberlogs"] = true,
    }
    if exactNames[name] then
        return true
    end

    -- If it's a Model, inspect parts inside
    if inst:IsA("Model") then
        local woodPartCount = 0
        local logNameCount = 0
        for _, child in ipairs(inst:GetDescendants()) do
            if child:IsA("BasePart") then
                local cName = child.Name:lower()
                if cName:find("log") or cName:find("timber") or cName:find("cord") or cName:find("firewood") or cName:find("wood") then
                    logNameCount += 1
                end
                if child.Material == Enum.Material.Wood or child.Material == Enum.Material.WoodPlanks or child.Shape == Enum.PartType.Cylinder then
                    woodPartCount += 1
                end
            end
        end

        if logNameCount >= 2 or woodPartCount >= 4 then
            return true
        end

        -- Check if near the woodland forest clearing at (188.3, 33.8, -39.7)
        local pivot = inst:GetPivot()
        local dist = (pivot.Position - Vector3.new(188.3, 33.8, -39.7)).Magnitude
        if dist < 45.0 and woodPartCount >= 1 then
            return true
        end
    end

    return false
end

-- Purges prompts only from blacklisted objects (barrels, furniture, tents)
local function purgeStrayWoodPrompts()
    for _, prompt in ipairs(workspace:GetDescendants()) do
        if prompt:IsA("ProximityPrompt") and isWoodPromptInstance(prompt) then
            if isBlacklistedWoodObject(prompt) then
                local parentName = prompt.Parent and prompt.Parent:GetFullName() or "Unknown"
                prompt:Destroy()
                print("[InventorySystem] 🧹 Purged stray wood prompt from non-wood object: " .. parentName)
            end
        end
    end
end

-- Attaches interaction prompt to any valid wood pile model or part
local function setupWoodPilePrompt(woodPile: Instance)
    if registeredWoodPiles[woodPile] then
        return
    end

    if isBlacklistedWoodObject(woodPile) then
        return
    end

    registeredWoodPiles[woodPile] = true
    CollectionService:AddTag(woodPile, "WoodPile")

    local interactionPart: BasePart? = nil

    if woodPile:IsA("Model") then
        local cf, size = woodPile:GetBoundingBox()
        -- Ensure all base parts in the wood pile are anchored
        for _, desc in ipairs(woodPile:GetDescendants()) do
            if desc:IsA("BasePart") and desc.Name ~= "WoodInteractionPromptPart" then
                desc.Anchored = true
                -- Clean up any duplicate prompt on individual log cylinders
                for _, childPrompt in ipairs(desc:GetChildren()) do
                    if childPrompt:IsA("ProximityPrompt") and isWoodPromptInstance(childPrompt) then
                        childPrompt:Destroy()
                    end
                end
            end
        end

        interactionPart = woodPile:FindFirstChild("WoodInteractionPromptPart") :: BasePart?
        local hitboxSize = Vector3.new(
            math.clamp(size.X + 4, 8, 26),
            math.clamp(size.Y + 3, 5, 14),
            math.clamp(size.Z + 4, 8, 26)
        )
        if not interactionPart then
            interactionPart = Instance.new("Part")
            interactionPart.Name = "WoodInteractionPromptPart"
            interactionPart.Size = hitboxSize
            interactionPart.CFrame = cf + Vector3.new(0, 0.5, 0)
            interactionPart.Transparency = 1
            interactionPart.CanCollide = false
            interactionPart.CanTouch = false
            interactionPart.CanQuery = true
            interactionPart.Anchored = true
            interactionPart.Parent = woodPile
        else
            interactionPart.Size = hitboxSize
            interactionPart.CFrame = cf + Vector3.new(0, 0.5, 0)
            interactionPart.Transparency = 1
            interactionPart.CanCollide = false
            interactionPart.CanTouch = false
            interactionPart.CanQuery = true
            interactionPart.Anchored = true
        end
    elseif woodPile:IsA("BasePart") then
        interactionPart = woodPile
    end

    if not interactionPart then
        return
    end

    local prompt = interactionPart:FindFirstChild("WoodGatherPrompt") :: ProximityPrompt?
    if not prompt then
        prompt = Instance.new("ProximityPrompt")
        prompt.Name = "WoodGatherPrompt"
        prompt.Parent = interactionPart
    end

    prompt.ActionText = "Take Wood Log"
    prompt.ObjectText = "Wood Pile (Max 5)"
    prompt.KeyboardKeyCode = Enum.KeyCode.E
    prompt.GamepadKeyCode = Enum.KeyCode.ButtonX
    prompt.HoldDuration = 0.2
    prompt.MaxActivationDistance = 20.0
    prompt.RequiresLineOfSight = false
    prompt.Exclusivity = Enum.ProximityPromptExclusivity.OnePerButton
    prompt.Enabled = true

    if not prompt:GetAttribute("TriggerConnected") then
        prompt:SetAttribute("TriggerConnected", true)
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
                local newTotal = getTotalWoodCount(player)
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

    print(string.format("[InventorySystem] ✅ Wood Pile registered & prompt ready at: %s (Pos: %.1f, %.1f, %.1f)",
        woodPile:GetFullName(),
        interactionPart.Position.X,
        interactionPart.Position.Y,
        interactionPart.Position.Z
    ))
end

-- Helper to locate and register the Trader House for upcoming objectives
local function locateTraderHouse(): Model?
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("Model") then
            local lName = obj.Name:lower()
            if lName:find("trader") or lName:find("merchant") or lName:find("shop") or lName:find("cabin") then
                local pivot = obj:GetPivot()
                print(string.format("[TraderHouseLocator] Found Trader House '%s' at Vector3.new(%.1f, %.1f, %.1f)", obj.Name, pivot.Position.X, pivot.Position.Y, pivot.Position.Z))
                CollectionService:AddTag(obj, "TraderHouse")

                -- Ensure all parts in the Trader House are anchored to prevent physics collapse
                for _, part in ipairs(obj:GetDescendants()) do
                    if part:IsA("BasePart") then
                        part.Anchored = true
                    end
                end

                return obj
            end
        end
    end
    print("[TraderHouseLocator] Trader House not found by name yet. (Tag with 'TraderHouse' or name 'TraderHouse')")
    return nil
end

local function initProductionWoodSystem()
    local function scanAndRegisterAll()
        local count = 0
        -- 1. Check all tagged WoodPile instances
        for _, inst in ipairs(CollectionService:GetTagged("WoodPile")) do
            if isCandidateWoodPile(inst) then
                setupWoodPilePrompt(inst)
                count += 1
            end
        end

        -- 2. Scan workspace for candidate models/parts
        for _, obj in ipairs(workspace:GetDescendants()) do
            if (obj:IsA("Model") or obj:IsA("BasePart")) and not registeredWoodPiles[obj] then
                if isCandidateWoodPile(obj) then
                    setupWoodPilePrompt(obj)
                    count += 1
                end
            end
        end

        -- 3. If no wood piles found anywhere on the map, generate fallback
        if count == 0 and next(registeredWoodPiles) == nil then
            local WoodPileBuilder = require(script.Parent.Environment:WaitForChild("WoodPileBuilder"))
            local built = WoodPileBuilder.Build()
            if built then
                setupWoodPilePrompt(built)
            end
        end

        -- 4. Clean stray prompts from barrels, tents, furniture
        purgeStrayWoodPrompts()
    end

    task.spawn(function()
        scanAndRegisterAll()
        -- Repeat scan after short delays to catch late-streaming models
        task.wait(1.0)
        scanAndRegisterAll()
        task.wait(2.5)
        scanAndRegisterAll()
    end)

    -- Listen for newly tagged or added wood piles dynamically
    CollectionService:GetInstanceAddedSignal("WoodPile"):Connect(function(inst)
        if isCandidateWoodPile(inst) then
            setupWoodPilePrompt(inst)
        end
    end)

    workspace.DescendantAdded:Connect(function(desc)
        if desc:IsA("Model") and isCandidateWoodPile(desc) then
            task.wait(0.1)
            setupWoodPilePrompt(desc)
        end
    end)
end

-- Run initial setup
task.defer(function()
    task.wait(0.3)
    initProductionWoodSystem()
    locateTraderHouse()
end)

--------------------------------------------------------------------------------
-- 2. CAMP VINTAGE MATCHBOX PROP & INTERACTION
--------------------------------------------------------------------------------
local function spawnCampMatchbox()
    local matchboxModel = workspace:FindFirstChild("CampMatchbox") :: Model?
    local sleeve: BasePart?
    local surfaceGui: SurfaceGui?
    local glowLight: PointLight?
    local prompt: ProximityPrompt?

    if matchboxModel then
        sleeve = (matchboxModel.PrimaryPart or matchboxModel:FindFirstChild("Sleeve")) :: BasePart?
        if sleeve then
            surfaceGui = sleeve:FindFirstChildOfClass("SurfaceGui")
            glowLight = sleeve:FindFirstChildOfClass("PointLight")
            prompt = sleeve:FindFirstChildOfClass("ProximityPrompt")
        end
    end

    if not matchboxModel or not sleeve or not prompt then
        if matchboxModel then
            matchboxModel:Destroy()
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

        matchboxModel = Instance.new("Model")
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

        glowLight = Instance.new("PointLight")
        glowLight.Name = "MatchboxGlow"
        glowLight.Color = Color3.fromRGB(255, 195, 75)
        glowLight.Range = 5.5
        glowLight.Brightness = 0.85
        glowLight.Shadows = false
        glowLight.Parent = sleeve

        prompt = Instance.new("ProximityPrompt")
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
    end

    if not prompt then return end

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
