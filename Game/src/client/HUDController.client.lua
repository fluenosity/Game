--!strict
--[[
    HUDController.client.lua
    Revamped In-Game HUD Controller for "Don't Let the Fire Die".
    Developed for Fluenosity Studio.
    
    Modular Components:
    - hud/HUDClock: Top-center celestial Day & Time tracker
    - hud/HUDSettingsButton: Top-right glassmorphic settings gear button
    - hud/HUDHotbar: Bottom-center 3-slot quickbar with glowing amber selection
    - hud/HUDVitals: Bottom-right Health, Hunger (78), Stamina status pills
    - hud/HUDInventoryModal: Center survival backpack modal (Tabs, 4x3 Grid, Inspector)
    - UIComponents.CreateGenshinStaminaBar: Smooth crescent arc attached to player
    - UIComponents.CreateSystemMenu: Fullscreen glassmorphic ESC / settings menu
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui") :: PlayerGui

local UITheme = require(script.Parent:WaitForChild("UITheme"))
local UIComponents = require(script.Parent:WaitForChild("UIComponents"))

-- Ensure audio routing to MasterSoundGroup is initialized
UITheme.InitAudioRouting()

local hudFolder = script.Parent:WaitForChild("hud")
local HUDClock = require(hudFolder:WaitForChild("HUDClock"))
local HUDTopRightWidget = require(hudFolder:WaitForChild("HUDTopRightWidget"))
local HUDHotbar = require(hudFolder:WaitForChild("HUDHotbar"))
local HUDVitals = require(hudFolder:WaitForChild("HUDVitals"))
local HUDInventoryModal = require(hudFolder:WaitForChild("HUDInventoryModal"))

local sharedFolder = ReplicatedStorage:WaitForChild("FluenosityShared")
local InventoryConfig = require(sharedFolder:WaitForChild("InventoryConfig"))
local IconPack = require(sharedFolder:WaitForChild("IconPack"))

--------------------------------------------------------------------------------
-- STATE
--------------------------------------------------------------------------------
local maxStamina = 100.0
local currentStamina = 100.0
local isSprinting = false
local isFatigued = false
local lastSprintTime = 0.0

local maxHunger = 100.0
local currentHunger = 78.0 -- Matches mockup baseline (Food 78)

local normalWalkSpeed = 16
local sprintWalkSpeed = 24
local fatiguedWalkSpeed = 10
local normalJumpPower = 50
local fatiguedJumpPower = 0

local selectedHotbarSlot = 1
local activeCharacter: Model? = nil
local activeHumanoid: Humanoid? = nil
local characterJumpConn: RBXScriptConnection? = nil
local characterHealthConn: RBXScriptConnection? = nil

-- Client inventory state (12 slots)
local currentInventory: { [number]: { Id: string, Count: number }? } = {}
for slotIdx = 1, InventoryConfig.TOTAL_PERSONAL_SLOTS do
    local defaultItem = InventoryConfig.StartingLoadout[slotIdx]
    if defaultItem then
        currentInventory[slotIdx] = {
            Id = defaultItem.Id,
            Count = defaultItem.Count,
        }
    else
        currentInventory[slotIdx] = nil
    end
end

--------------------------------------------------------------------------------
-- ROOT HUD SCREENGUI
--------------------------------------------------------------------------------
local hudGui = Instance.new("ScreenGui")
hudGui.Name = "DontLetTheFireDie_InGameHUD"
hudGui.ResetOnSpawn = false
hudGui.IgnoreGuiInset = true
hudGui.DisplayOrder = 20
hudGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
hudGui.Enabled = false
hudGui.Parent = playerGui

--------------------------------------------------------------------------------
-- 1. INSTANTIATE MODULAR HUD COMPONENTS
--------------------------------------------------------------------------------
-- Top-Center Celestial Clock & Day Tracker
local clockInstance = HUDClock.Create(hudGui)

-- Top-Right Global Survival Component (Campfire Sanctuary, Day/Clock, Backpack [B], Settings [ESC])
local topRightWidget = HUDTopRightWidget.Create(hudGui)

-- Bottom-Center 3-Slot Hotbar
local hotbarInstance = HUDHotbar.Create(hudGui)

-- Bottom-Right Health / Hunger / Stamina Vitals
local vitalsInstance = HUDVitals.Create(hudGui)

vitalsInstance.OnSprintToggle(function()
    if isFatigued or currentStamina <= 0 then return end
    isSprinting = not isSprinting
    vitalsInstance.SetSprinting(isSprinting)
    if activeHumanoid then
        activeHumanoid.WalkSpeed = isSprinting and sprintWalkSpeed or normalWalkSpeed
    end
end)

-- Center Survival Backpack Modal (12 Slots Grid + Inspector)
local inventoryModal = HUDInventoryModal.Create(hudGui)

--------------------------------------------------------------------------------
-- 2. FULLSCREEN AAA SYSTEM / ESC MENU
--------------------------------------------------------------------------------
local isSystemMenuOpen = false
local systemMenuInstance = UIComponents.CreateSystemMenu(hudGui, {
    OnResume = function()
        isSystemMenuOpen = false
    end,
    OnQuit = function()
        isSystemMenuOpen = false
        if activeHumanoid then
            activeHumanoid.Health = 0
        end
        hudGui.Enabled = false
    end,
})

local function toggleSystemMenu()
    if isSystemMenuOpen then
        systemMenuInstance.Close()
        isSystemMenuOpen = false
    else
        if inventoryModal.IsOpen() then
            inventoryModal.Close()
        end
        systemMenuInstance.Open()
        isSystemMenuOpen = true
    end
end

topRightWidget.SetOnSettingsClick(function()
    toggleSystemMenu()
end)

topRightWidget.SetOnBackpackClick(function()
    inventoryModal.Toggle()
end)

--------------------------------------------------------------------------------
-- 3. NETWORKING & INVENTORY SYNC
--------------------------------------------------------------------------------
local dropItemEvent = sharedFolder:WaitForChild("RequestDropItem", 5) :: RemoteEvent?
local syncInventoryEvent = sharedFolder:WaitForChild("SyncInventory", 5) :: RemoteEvent?
local discardItemEvent = sharedFolder:WaitForChild("RequestDiscardItem", 5) :: RemoteEvent?
local splitItemEvent = sharedFolder:WaitForChild("RequestSplitItem", 5) :: RemoteEvent?
local notificationEvent = sharedFolder:WaitForChild("ShowNotification", 5) :: RemoteEvent?

--------------------------------------------------------------------------------
-- TOAST NOTIFICATION BANNER (Floating Glassmorphic Pill above Hotbar)
--------------------------------------------------------------------------------
local toastFrame = Instance.new("Frame")
toastFrame.Name = "HUDToastNotification"
toastFrame.Size = UDim2.fromOffset(360, 44)
toastFrame.Position = UDim2.new(0.5, 0, 1, -120)
toastFrame.AnchorPoint = Vector2.new(0.5, 1)
toastFrame.BackgroundColor3 = Color3.fromRGB(18, 17, 22)
toastFrame.BackgroundTransparency = 1
toastFrame.BorderSizePixel = 0
toastFrame.ZIndex = 90
toastFrame.Visible = false
toastFrame.Parent = hudGui

local toastCorner = Instance.new("UICorner")
toastCorner.CornerRadius = UDim.new(0, 22)
toastCorner.Parent = toastFrame

local toastStroke = Instance.new("UIStroke")
toastStroke.Color = Color3.fromRGB(245, 160, 40)
toastStroke.Thickness = 1.2
toastStroke.Transparency = 1
toastStroke.Parent = toastFrame

local toastIcon = Instance.new("ImageLabel")
toastIcon.Name = "ToastIcon"
toastIcon.Size = UDim2.fromOffset(22, 22)
toastIcon.Position = UDim2.new(0, 14, 0.5, 0)
toastIcon.AnchorPoint = Vector2.new(0, 0.5)
toastIcon.BackgroundTransparency = 1
toastIcon.ZIndex = 91
toastIcon.Parent = toastFrame

local toastLabel = Instance.new("TextLabel")
toastLabel.Name = "ToastLabel"
toastLabel.Size = UDim2.new(1, -54, 1, 0)
toastLabel.Position = UDim2.fromOffset(44, 0)
toastLabel.BackgroundTransparency = 1
toastLabel.Font = Enum.Font.GothamBold
toastLabel.Text = ""
toastLabel.TextColor3 = Color3.fromRGB(245, 248, 255)
toastLabel.TextSize = 13
toastLabel.TextXAlignment = Enum.TextXAlignment.Left
toastLabel.ZIndex = 91
toastLabel.Parent = toastFrame

local toastHideThread: thread? = nil

local function showToast(message: string, iconName: string?, accentColor: Color3?)
    local col = accentColor or Color3.fromRGB(245, 160, 40)
    local icon = iconName or "info"

    toastLabel.Text = message
    toastStroke.Color = col
    IconPack.ApplyTo(toastIcon, icon, col, 0, 48)

    toastFrame.Visible = true

    TweenService:Create(toastFrame, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        BackgroundTransparency = 0.20,
        Position = UDim2.new(0.5, 0, 1, -122),
    }):Play()
    TweenService:Create(toastStroke, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        Transparency = 0.35,
    }):Play()
    TweenService:Create(toastLabel, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        TextTransparency = 0,
    }):Play()
    TweenService:Create(toastIcon, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        ImageTransparency = 0,
    }):Play()

    if toastHideThread then
        task.cancel(toastHideThread)
    end

    toastHideThread = task.delay(3.0, function()
        local hideTween = TweenService:Create(toastFrame, TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
            BackgroundTransparency = 1,
            Position = UDim2.new(0.5, 0, 1, -112),
        })
        TweenService:Create(toastStroke, TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
            Transparency = 1,
        }):Play()
        TweenService:Create(toastLabel, TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
            TextTransparency = 1,
        }):Play()
        TweenService:Create(toastIcon, TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
            ImageTransparency = 1,
        }):Play()

        hideTween:Play()
        hideTween.Completed:Connect(function()
            if toastFrame.BackgroundTransparency >= 0.99 then
                toastFrame.Visible = false
            end
        end)
    end)
end

if notificationEvent then
    notificationEvent.OnClientEvent:Connect(function(message: string, iconName: string?, accentColor: Color3?)
        showToast(message, iconName, accentColor)
    end)
end

local function refreshAllInventoryUI()
    -- Sync bottom hotbar (slots 1 to 3)
    for i = 1, InventoryConfig.MAX_HOTBAR_SLOTS do
        hotbarInstance.SetSlot(i, currentInventory[i])
    end

    -- Sync 12-slot backpack modal
    inventoryModal.UpdateInventory(currentInventory)
end

refreshAllInventoryUI()

if syncInventoryEvent then
    syncInventoryEvent.OnClientEvent:Connect(function(serverInv)
        if type(serverInv) == "table" then
            currentInventory = serverInv
            refreshAllInventoryUI()
        end
    end)
end

local function dropActiveItem()
    if dropItemEvent then
        dropItemEvent:FireServer(selectedHotbarSlot)
    end
end

hotbarInstance.OnSlotSelected(function(slotIdx)
    selectedHotbarSlot = slotIdx
end)

-- Equip / Swap item from backpack into active hotbar
inventoryModal.SetOnEquip(function(slotIdx)
    local item = currentInventory[slotIdx]
    if not item then return end

    local def = InventoryConfig.Items[item.Id]
    if not def then return end

    if def.Category == "Medical" and activeHumanoid then
        -- Consume bandage / medicine
        activeHumanoid.Health = math.min(activeHumanoid.MaxHealth, activeHumanoid.Health + 30)
        item.Count = item.Count - 1
        if item.Count <= 0 then
            currentInventory[slotIdx] = nil
        end
        refreshAllInventoryUI()
    elseif def.Category == "Consumable" and item.Id == "raw_meat" then
        -- Eat food to restore hunger
        currentHunger = math.min(maxHunger, currentHunger + 30)
        vitalsInstance.SetHunger(currentHunger, maxHunger)
        item.Count = item.Count - 1
        if item.Count <= 0 then
            currentInventory[slotIdx] = nil
        end
        refreshAllInventoryUI()
    elseif slotIdx > InventoryConfig.MAX_HOTBAR_SLOTS then
        -- Swap backpack item into currently selected hotbar slot
        local temp = currentInventory[selectedHotbarSlot]
        currentInventory[selectedHotbarSlot] = item
        currentInventory[slotIdx] = temp
        refreshAllInventoryUI()
    else
        -- Already in hotbar, simply select that hotbar slot
        hotbarInstance.SelectSlot(slotIdx)
    end
end)

-- Drop item from backpack inspector
inventoryModal.SetOnDrop(function(slotIdx)
    if dropItemEvent then
        dropItemEvent:FireServer(slotIdx)
    end
end)

-- Discard item from backpack inspector
inventoryModal.SetOnDiscard(function(slotIdx)
    if discardItemEvent then
        discardItemEvent:FireServer(slotIdx)
    end
end)

-- Split item stack from backpack inspector
inventoryModal.SetOnSplit(function(slotIdx)
    if splitItemEvent then
        splitItemEvent:FireServer(slotIdx)
    end
end)

--------------------------------------------------------------------------------
-- 4. CELESTIAL TIME & SURVIVAL CLOCK SYNC
--------------------------------------------------------------------------------
local timeState = sharedFolder:WaitForChild("TimeState", 10) :: Folder?
if timeState then
    local function syncTime()
        local day = timeState:GetAttribute("CurrentDay") or 0
        local hour = timeState:GetAttribute("CurrentHour") or 10.45 -- 10:27 AM default
        local phase = timeState:GetAttribute("CurrentPhase") or "Day"
        local progress = timeState:GetAttribute("PhaseProgress") or 0.5

        clockInstance.SetTime(hour :: number, day :: number, phase :: string, progress :: number)
        topRightWidget.SetTime(hour :: number, day :: number, phase :: string)
    end

    syncTime()
    timeState:GetAttributeChangedSignal("CurrentDay"):Connect(syncTime)
    timeState:GetAttributeChangedSignal("CurrentHour"):Connect(syncTime)
    timeState:GetAttributeChangedSignal("CurrentPhase"):Connect(syncTime)
    timeState:GetAttributeChangedSignal("PhaseProgress"):Connect(syncTime)
end

-- Campfire Flame & Sanctuary Status Synchronization
local function syncCampfireStatus()
    local campfire = workspace:FindFirstChild("Campfire")
    if campfire then
        local isLit = campfire:GetAttribute("IsLit")
        if isLit == nil then isLit = true end
        topRightWidget.SetCampfireLit(isLit)
    else
        topRightWidget.SetCampfireLit(true)
    end
end

syncCampfireStatus()
workspace.ChildAdded:Connect(function(child)
    if child.Name == "Campfire" then
        syncCampfireStatus()
        child:GetAttributeChangedSignal("IsLit"):Connect(syncCampfireStatus)
    end
end)
local existingCampfire = workspace:FindFirstChild("Campfire")
if existingCampfire then
    existingCampfire:GetAttributeChangedSignal("IsLit"):Connect(syncCampfireStatus)
end

--------------------------------------------------------------------------------
-- 5. GENSHIN IMPACT STAMINA BAR & CHARACTER INTEGRATION
--------------------------------------------------------------------------------
local currentStaminaBar: any = nil

local function setupCharacter(character: Model)
    activeCharacter = character
    activeHumanoid = character:WaitForChild("Humanoid", 10) :: Humanoid?
    if not activeHumanoid then return end

    if currentStaminaBar then
        currentStaminaBar.Destroy()
        currentStaminaBar = nil
    end

    if characterJumpConn then
        characterJumpConn:Disconnect()
        characterJumpConn = nil
    end

    if characterHealthConn then
        characterHealthConn:Disconnect()
        characterHealthConn = nil
    end

    currentStaminaBar = UIComponents.CreateGenshinStaminaBar(character)
    currentStamina = maxStamina
    isSprinting = false
    isFatigued = false
    activeHumanoid.WalkSpeed = normalWalkSpeed
    activeHumanoid.UseJumpPower = true
    activeHumanoid.JumpPower = normalJumpPower

    -- Initial vitals sync
    vitalsInstance.SetHealth(activeHumanoid.Health, activeHumanoid.MaxHealth)
    vitalsInstance.SetHunger(currentHunger, maxHunger)
    vitalsInstance.SetStamina(currentStamina, maxStamina)

    -- Live Health sync
    characterHealthConn = activeHumanoid.HealthChanged:Connect(function(newHealth)
        if activeHumanoid then
            vitalsInstance.SetHealth(newHealth, activeHumanoid.MaxHealth)
        end
    end)

    -- Jump stamina consumption & feedback (tracks player jump smoothly)
    characterJumpConn = activeHumanoid.Jumping:Connect(function(isActive: boolean)
        if isActive and not isFatigued and activeHumanoid.Health > 0 then
            currentStamina = math.max(0, currentStamina - 8)
            lastSprintTime = os.clock()
            vitalsInstance.SetStamina(currentStamina, maxStamina)
            if currentStaminaBar then
                currentStaminaBar.SetStamina(currentStamina, maxStamina, true)
            end
            if currentStamina <= 0 then
                isFatigued = true
                isSprinting = false
                activeHumanoid.WalkSpeed = fatiguedWalkSpeed
                activeHumanoid.JumpPower = fatiguedJumpPower
            end
        end
    end)

    hudGui.Enabled = true
end

if player.Character then
    setupCharacter(player.Character)
end
player.CharacterAdded:Connect(setupCharacter)

--------------------------------------------------------------------------------
-- 6. RUNTIME LOOPS (Stamina, Hunger, Camera Alignment)
--------------------------------------------------------------------------------
local hungerTimer = 0.0

RunService.Heartbeat:Connect(function(deltaTime: number)
    if not activeHumanoid or not activeHumanoid.Parent or activeHumanoid.Health <= 0 then
        return
    end

    local isMoving = activeHumanoid.MoveDirection.Magnitude > 0.1

    -- Sanctuary distance check (Within 48 studs of campfire)
    if activeCharacter and activeCharacter.PrimaryPart then
        local charPos = activeCharacter.PrimaryPart.Position
        local campfire = workspace:FindFirstChild("Campfire")
        local campPos = Vector3.new(0, 0, 0)
        if campfire and campfire.PrimaryPart then
            campPos = campfire.PrimaryPart.Position
        end
        local dist = (Vector3.new(charPos.X, 0, charPos.Z) - Vector3.new(campPos.X, 0, campPos.Z)).Magnitude
        topRightWidget.SetSanctuaryStatus(dist <= 48)
    end

    -- Hunger gradual consumption (1 point every 30 seconds)
    hungerTimer = hungerTimer + deltaTime
    if hungerTimer >= 30.0 then
        hungerTimer = 0.0
        currentHunger = math.max(0, currentHunger - 1)
        vitalsInstance.SetHunger(currentHunger, maxHunger)
    end

    -- Sprint stamina drain / recovery
    if isSprinting and isMoving and not isFatigued then
        currentStamina = math.max(0, currentStamina - (20 * deltaTime))
        lastSprintTime = os.clock()

        if currentStamina <= 0 then
            isFatigued = true
            isSprinting = false
            vitalsInstance.SetSprinting(false)
            activeHumanoid.WalkSpeed = fatiguedWalkSpeed
            activeHumanoid.JumpPower = fatiguedJumpPower

            task.delay(1.2, function()
                if activeHumanoid and not isSprinting and not isFatigued then
                    activeHumanoid.WalkSpeed = normalWalkSpeed
                end
            end)
        end
    else
        -- Recovery after 0.4s cooldown
        local timeSinceSprint = os.clock() - lastSprintTime
        if timeSinceSprint > 0.4 then
            currentStamina = math.min(maxStamina, currentStamina + (30 * deltaTime))

            -- Recover from fatigue once stamina reaches 25%
            if isFatigued and currentStamina >= 25 then
                isFatigued = false
                if activeHumanoid and not isSprinting then
                    activeHumanoid.WalkSpeed = normalWalkSpeed
                    activeHumanoid.JumpPower = normalJumpPower
                end
            end
        end
    end

    -- Update vitals & Genshin meter
    vitalsInstance.SetStamina(currentStamina, maxStamina)
    local isConsuming = (isSprinting and isMoving) or (os.clock() - lastSprintTime < 0.45)
    if currentStaminaBar then
        currentStaminaBar.SetStamina(currentStamina, maxStamina, isConsuming)
    end
end)

-- Camera-relative tracking alignment on RenderStepped (ensures zero-jitter camera responsiveness)
RunService.RenderStepped:Connect(function()
    if currentStaminaBar and activeCharacter then
        local cam = workspace.CurrentCamera
        if cam then
            currentStaminaBar.UpdateCameraAlignment(cam.CFrame.RightVector, cam.CFrame.UpVector)
        end
    end
end)

--------------------------------------------------------------------------------
-- 7. KEYBOARD & INPUT BINDINGS
--------------------------------------------------------------------------------
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end

    if input.KeyCode == Enum.KeyCode.LeftShift or input.KeyCode == Enum.KeyCode.RightShift then
        if not isFatigued and currentStamina > 0 then
            isSprinting = true
            vitalsInstance.SetSprinting(true)
            if activeHumanoid then
                activeHumanoid.WalkSpeed = sprintWalkSpeed
            end
        end
    elseif input.KeyCode == Enum.KeyCode.One then
        hotbarInstance.SelectSlot(1)
    elseif input.KeyCode == Enum.KeyCode.Two then
        hotbarInstance.SelectSlot(2)
    elseif input.KeyCode == Enum.KeyCode.Three then
        hotbarInstance.SelectSlot(3)
    elseif input.KeyCode == Enum.KeyCode.Q then
        if not inventoryModal.IsOpen() then
            dropActiveItem()
        end
    elseif input.KeyCode == Enum.KeyCode.B or input.KeyCode == Enum.KeyCode.Tab then
        inventoryModal.Toggle()
    elseif input.KeyCode == Enum.KeyCode.Escape or input.KeyCode == Enum.KeyCode.M or input.KeyCode == Enum.KeyCode.P then
        toggleSystemMenu()
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.KeyCode == Enum.KeyCode.LeftShift or input.KeyCode == Enum.KeyCode.RightShift then
        isSprinting = false
        vitalsInstance.SetSprinting(false)
        if activeHumanoid and not isFatigued then
            activeHumanoid.WalkSpeed = normalWalkSpeed
        end
    end
end)
