--!strict
--[[
    TradingSystem.server.lua
    Server-authoritative barter trading validation and transaction processor.
    Handles Silas the Ash Trader's economy exchanges.
    Developed for Fluenosity Studio.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local sharedFolder = ReplicatedStorage:WaitForChild("FluenosityShared")
local InventoryConfig = require(sharedFolder:WaitForChild("InventoryConfig"))
local TradingConfig = require(sharedFolder:WaitForChild("TradingConfig"))
local InventoryManager = require(script.Parent:WaitForChild("InventoryManager"))
local WoodPileBuilder = require(script.Parent.Environment:WaitForChild("WoodPileBuilder"))
local TraderNPCSpawner = require(script.Parent.Environment:WaitForChild("TraderNPCSpawner"))

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

local ProximityPromptService = game:GetService("ProximityPromptService")

local requestBarterEvent = getOrCreateRemoteEvent("RequestBarterTrade")
local barterResultEvent = getOrCreateRemoteEvent("BarterResult")
local notificationEvent = getOrCreateRemoteEvent("ShowNotification")
local openBarterMenuEvent = getOrCreateRemoteEvent("OpenBarterMenu")

-- Server-side fallback prompt listener
ProximityPromptService.PromptTriggered:Connect(function(prompt: ProximityPrompt, player: Player)
    if prompt.Name == "SilasBarterPrompt" or prompt.ActionText == "Barter" then
        openBarterMenuEvent:FireClient(player)
    end
end)

local function sendNotification(player: Player, message: string, iconName: string?, accentColor: Color3?)
    notificationEvent:FireClient(
        player,
        message,
        iconName or "info",
        accentColor or Color3.fromRGB(255, 195, 60)
    )
end

-- Process Barter Trade Request from Client
requestBarterEvent.OnServerEvent:Connect(function(player: Player, recipeId: unknown)
    if typeof(recipeId) ~= "string" then return end

    local char = player.Character
    if not char or not char.PrimaryPart then
        barterResultEvent:FireClient(player, false, recipeId, "Character not spawned.")
        return
    end

    -- 1. Find Recipe Definition
    local targetRecipe: TradingConfig.BarterRecipe? = nil
    for _, r in ipairs(TradingConfig.Recipes) do
        if r.Id == recipeId then
            targetRecipe = r
            break
        end
    end

    if not targetRecipe then
        barterResultEvent:FireClient(player, false, recipeId, "Unknown trade recipe.")
        return
    end

    -- 2. Range validation (must be reasonably near Silas or the Trader House)
    local silas = Workspace:FindFirstChild("TraderSilas")
    if silas and silas.PrimaryPart then
        local dist = (char.PrimaryPart.Position - silas.PrimaryPart.Position).Magnitude
        if dist > 35.0 then
            barterResultEvent:FireClient(player, false, recipeId, "Too far from Silas to trade.")
            sendNotification(player, "You must be near Silas to barter!", "alert-triangle", Color3.fromRGB(255, 90, 90))
            return
        end
    end

    -- 3. Check Input Resources
    local inputId = targetRecipe.InputItemId
    local hasEnough, currentCount = InventoryManager.HasItem(player, inputId, targetRecipe.InputCount)
    local inputDef = InventoryConfig.Items[inputId]
    local inputName = inputDef and inputDef.Name or inputId

    if not hasEnough then
        local needed = targetRecipe.InputCount - currentCount
        local msg = string.format("Need %d more %s!", needed, inputName)
        barterResultEvent:FireClient(player, false, recipeId, msg)
        sendNotification(player, msg, "alert-triangle", Color3.fromRGB(255, 120, 80))
        return
    end

    -- 4. Check Capacity Limits for Wood
    local outputId = targetRecipe.OutputItemId
    if outputId == "standard_wood" or outputId == "wood" then
        local currentWood = InventoryManager.GetWoodCount(player)
        if (currentWood + targetRecipe.OutputCount) > 5 then
            local msg = "Carrying capacity full! (Max 5 Wood Logs)"
            barterResultEvent:FireClient(player, false, recipeId, msg)
            sendNotification(player, msg, "alert-triangle", Color3.fromRGB(255, 175, 45))
            return
        end
    end

    -- 5. Atomic Transaction: Consume Input -> Grant Output
    local consumed = InventoryManager.ConsumeItem(player, inputId, targetRecipe.InputCount)
    if not consumed then
        barterResultEvent:FireClient(player, false, recipeId, "Transaction failed: could not deduct items.")
        return
    end

    local added = InventoryManager.AddItem(player, outputId, targetRecipe.OutputCount)
    if not added then
        -- Rollback in the rare case backpack was completely filled
        InventoryManager.AddItem(player, inputId, targetRecipe.InputCount)
        barterResultEvent:FireClient(player, false, recipeId, "Backpack full! Free up a slot.")
        sendNotification(player, "Backpack full! Free up a slot to receive traded goods.", "backpack", Color3.fromRGB(255, 85, 85))
        return
    end

    -- 6. Success Feedback
    local outputDef = InventoryConfig.Items[outputId]
    local outputName = outputDef and outputDef.Name or targetRecipe.Name
    local successMsg = string.format("Traded %dx %s for %dx %s!", targetRecipe.InputCount, inputName, targetRecipe.OutputCount, outputName)

    barterResultEvent:FireClient(player, true, recipeId, successMsg)
    sendNotification(
        player,
        successMsg,
        targetRecipe.Icon or "package",
        targetRecipe.AccentColor or Color3.fromRGB(100, 220, 140)
    )
    print(string.format("🤝 [TradingSystem] %s completed barter '%s'", player.Name, targetRecipe.Name))
end)

-- Startup: Spawn Silas
task.defer(function()
    task.wait(0.5)

    -- 1. Spawn Silas the Ash Trader inside the Trader House
    TraderNPCSpawner.Spawn()
end)

print("[TradingSystem] Server Barter Economy loaded & active.")
