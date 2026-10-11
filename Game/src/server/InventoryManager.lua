--!strict
--[[
    InventoryManager.lua
    Centralized server-authoritative inventory state and operations
    for "Don't Let the Fire Die" (Fluenosity Studio).
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local sharedFolder = ReplicatedStorage:FindFirstChild("FluenosityShared")
if not sharedFolder and RunService:IsRunning() then
    sharedFolder = ReplicatedStorage:WaitForChild("FluenosityShared", 5)
end

local InventoryConfig
if sharedFolder then
    local cfgMod = sharedFolder:FindFirstChild("InventoryConfig")
    if cfgMod and cfgMod:IsA("ModuleScript") then
        local ok, res = pcall(require, cfgMod)
        if ok then InventoryConfig = res end
    end
end

local function getOrCreateRemoteEvent(name: string): RemoteEvent?
    if not sharedFolder then return nil end
    local ev = sharedFolder:FindFirstChild(name)
    if not ev and RunService:IsRunning() then
        local newEv = Instance.new("RemoteEvent")
        newEv.Name = name
        newEv.Parent = sharedFolder
        return newEv
    end
    return ev :: RemoteEvent?
end

local syncInventoryEvent = getOrCreateRemoteEvent("SyncInventory")

local InventoryManager = {}

local playerInventories: { [Player]: { [number]: { Id: string, Count: number }? } } = {}

function InventoryManager.GetInventoriesTable(): { [Player]: { [number]: { Id: string, Count: number }? } }
    return playerInventories
end

function InventoryManager.InitPlayer(player: Player)
    if playerInventories[player] then return end
    local inv = {}
    local totalSlots = (InventoryConfig and InventoryConfig.TOTAL_PERSONAL_SLOTS) or 12
    local startingLoadout = (InventoryConfig and InventoryConfig.StartingLoadout) or {}

    for slotIdx = 1, totalSlots do
        local starting = startingLoadout[slotIdx]
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
    if syncInventoryEvent then
        syncInventoryEvent:FireClient(player, inv)
    end
end

function InventoryManager.RemovePlayer(player: Player)
    playerInventories[player] = nil
end

function InventoryManager.GetInventory(player: Player): { [number]: { Id: string, Count: number }? }?
    if not playerInventories[player] then
        InventoryManager.InitPlayer(player)
    end
    return playerInventories[player]
end

function InventoryManager.Sync(player: Player)
    local inv = playerInventories[player]
    if inv and syncInventoryEvent then
        syncInventoryEvent:FireClient(player, inv)
    end
end

-- Checks whether a player has an item (accepts string or list of alternative IDs)
function InventoryManager.HasItem(player: Player, itemIdOrList: string | { string }): (boolean, number, number?)
    local inv = InventoryManager.GetInventory(player)
    if not inv then return false, 0, nil end
    
    local targetIds: { [string]: boolean } = {}
    if typeof(itemIdOrList) == "string" then
        targetIds[itemIdOrList] = true
    elseif typeof(itemIdOrList) == "table" then
        for _, id in ipairs(itemIdOrList) do
            targetIds[id] = true
        end
    end
    
    local totalCount = 0
    local firstSlot: number? = nil
    local totalSlots = (InventoryConfig and InventoryConfig.TOTAL_PERSONAL_SLOTS) or 12
    for slotIdx = 1, totalSlots do
        local slotData = inv[slotIdx]
        if slotData and targetIds[slotData.Id] and slotData.Count > 0 then
            totalCount += slotData.Count
            if not firstSlot then
                firstSlot = slotIdx
            end
        end
    end
    
    return totalCount > 0, totalCount, firstSlot
end

-- Consumes amount of an item from the player's inventory
function InventoryManager.ConsumeItem(player: Player, itemIdOrList: string | { string }, amountToConsume: number?): boolean
    local amountNeeded = amountToConsume or 1
    local inv = InventoryManager.GetInventory(player)
    if not inv then return false end
    
    local targetIds: { [string]: boolean } = {}
    if typeof(itemIdOrList) == "string" then
        targetIds[itemIdOrList] = true
    elseif typeof(itemIdOrList) == "table" then
        for _, id in ipairs(itemIdOrList) do
            targetIds[id] = true
        end
    end
    
    local hasEnough, totalAvailable = InventoryManager.HasItem(player, itemIdOrList)
    if not hasEnough or totalAvailable < amountNeeded then
        return false
    end
    
    local remaining = amountNeeded
    local totalSlots = (InventoryConfig and InventoryConfig.TOTAL_PERSONAL_SLOTS) or 12
    for slotIdx = 1, totalSlots do
        local slotData = inv[slotIdx]
        if slotData and targetIds[slotData.Id] then
            if slotData.Count <= remaining then
                remaining -= slotData.Count
                inv[slotIdx] = nil
            else
                slotData.Count -= remaining
                remaining = 0
            end
            if remaining <= 0 then
                break
            end
        end
    end
    
    InventoryManager.Sync(player)
    return true
end

-- Adds an item to the player's inventory
function InventoryManager.AddItem(player: Player, itemId: string, count: number): boolean
    local inv = InventoryManager.GetInventory(player)
    if not inv then return false end
    
    local items = InventoryConfig and InventoryConfig.Items
    local def = items and items[itemId]
    local maxStack = (def and def.MaxStack) or 20
    local totalSlots = (InventoryConfig and InventoryConfig.TOTAL_PERSONAL_SLOTS) or 12
    local unlockedSlots = (InventoryConfig and InventoryConfig.UNLOCKED_SLOTS) or 9

    -- Enforce strict 5 Wood Logs carry limit across the entire inventory
    if itemId == "standard_wood" then
        local currentWood = 0
        for s = 1, totalSlots do
            local slotData = inv[s]
            if slotData and slotData.Id == "standard_wood" then
                currentWood += (slotData.Count or 0)
            end
        end
        if (currentWood + count) > 5 then
            return false
        end
    end

    -- Stack into existing slot first
    for s = 1, totalSlots do
        local slotData = inv[s]
        if slotData and slotData.Id == itemId and (slotData.Count + count) <= maxStack then
            slotData.Count += count
            InventoryManager.Sync(player)
            return true
        end
    end
    
    -- Or first empty unlocked slot
    for s = 1, unlockedSlots do
        if not inv[s] then
            inv[s] = { Id = itemId, Count = count }
            InventoryManager.Sync(player)
            return true
        end
    end
    
    return false
end

-- Only attach runtime listeners if game is active
if RunService:IsRunning() then
    Players.PlayerAdded:Connect(function(player)
        InventoryManager.InitPlayer(player)
    end)

    Players.PlayerRemoving:Connect(function(player)
        InventoryManager.RemovePlayer(player)
    end)

    for _, p in ipairs(Players:GetPlayers()) do
        InventoryManager.InitPlayer(p)
    end
end

return InventoryManager
