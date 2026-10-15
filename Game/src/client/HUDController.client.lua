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
    - UIComponents.CreateSystemMenu: Fullscreen glassmorphic ESC / settings menu
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui") :: PlayerGui

-- UI Theme
local UITheme = require(script.Parent:WaitForChild("UITheme"))

-- Ensure audio routing to MasterSoundGroup is initialized
UITheme.InitAudioRouting()

local hudFolder = script.Parent:WaitForChild("hud")
local HUDCompass = require(hudFolder:WaitForChild("HUDCompass"))
local HUDTopRightWidget = require(hudFolder:WaitForChild("HUDTopRightWidget"))
local HUDHotbar = require(hudFolder:WaitForChild("HUDHotbar"))
local HUDVitals = require(hudFolder:WaitForChild("HUDVitals"))
local HUDInventoryModal = require(hudFolder:WaitForChild("HUDInventoryModal"))
local HUDBarterModal = require(hudFolder:WaitForChild("HUDBarterModal"))
local HUDCrosshair = require(hudFolder:WaitForChild("HUDCrosshair"))
local UI = require(script.Parent:WaitForChild("UI"))

local sharedFolder = ReplicatedStorage:WaitForChild("FluenosityShared")
local InventoryConfig = require(sharedFolder:WaitForChild("InventoryConfig"))
local IconPack = require(sharedFolder:WaitForChild("IconPack"))
local AudioManager = require(script.Parent:WaitForChild("AudioManager"))
local ModalManager = require(script.Parent:WaitForChild("ModalManager"))

--------------------------------------------------------------------------------
-- STATE
--------------------------------------------------------------------------------
-- Development Controls
local UNLIMITED_STAMINA_DEV = true

local maxStamina = 100.0
local currentStamina = 100.0
local isSprinting = false
local isFatigued = false
local lastSprintTime = 0.0

local maxHunger = 100.0
local currentHunger = 78.0 -- Matches mockup baseline (Food 78)

local normalWalkSpeed = 12
local sprintWalkSpeed = 24
local fatiguedWalkSpeed = 8
local normalJumpPower = 38
local fatiguedJumpPower = 0

local selectedHotbarSlot = 1
local activeCharacter: Model? = nil
local activeHumanoid: Humanoid? = nil
local characterJumpConn: RBXScriptConnection? = nil
local characterHealthConn: RBXScriptConnection? = nil
local jumpCooldownThread: thread? = nil
local isJumpInputHeld = false
local JUMP_RECOVERY_GAP = 0.10 -- Snappy 100ms grounded recovery gap (prevents hold-to-bunnyhop & mid-air spam)

local function isJumpPhysicallyHeld(): boolean
    if isJumpInputHeld then return true end
    if UserInputService:IsKeyDown(Enum.KeyCode.Space) then return true end
    local ok, isDown = pcall(function()
        return UserInputService:IsGamepadButtonDown(Enum.UserInputType.Gamepad1, Enum.KeyCode.ButtonA)
    end)
    return ok and isDown == true
end

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
-- Top-Center Minimal Horizon Tape Compass
local compassInstance = HUDCompass.Create(hudGui)

-- Top-Right Global Survival Component (Day/Clock, Backpack [B], Settings [ESC])
local topRightWidget = HUDTopRightWidget.Create(hudGui)

-- Bottom-Center 3-Slot Hotbar
local hotbarInstance = HUDHotbar.Create(hudGui)

-- Bottom-Right Health / Hunger / Stamina Vitals
local vitalsInstance = HUDVitals.Create(hudGui)

vitalsInstance.OnSprintToggle(function()
    if not UNLIMITED_STAMINA_DEV and (isFatigued or currentStamina <= 0) then return end
    isSprinting = not isSprinting
    vitalsInstance.SetSprinting(isSprinting)
    if activeHumanoid then
        activeHumanoid.WalkSpeed = isSprinting and sprintWalkSpeed or normalWalkSpeed
    end
end)

-- Center Survival Backpack Modal (12 Slots Grid + Inspector)
local inventoryModal = HUDInventoryModal.Create(hudGui)

-- Silas Barter Trading Modal (Recipe Exchanges)
local barterModal = HUDBarterModal.Create(hudGui)

-- GTA V Style Minimalist Center Dot Crosshair
local crosshairInstance = HUDCrosshair.Create(hudGui)

--------------------------------------------------------------------------------
-- 2. CURSOR MANAGEMENT & FIRST-PERSON MOUSE LOCK SYSTEM
--------------------------------------------------------------------------------
local isAltHeld = false
local isAltToggled = false
local altPressTime = 0
local savedCameraRotation: CFrame? = nil

-- Invisible modal catch button to natively unlock cursor in Roblox engine
local modalBypassBtn = Instance.new("TextButton")
modalBypassBtn.Name = "ModalBypassHelper"
modalBypassBtn.Size = UDim2.fromOffset(0, 0)
modalBypassBtn.BackgroundTransparency = 1
modalBypassBtn.Text = ""
modalBypassBtn.AutoButtonColor = false
modalBypassBtn.Modal = false
modalBypassBtn.ZIndex = 999
modalBypassBtn.Parent = hudGui

local isSystemMenuOpen = false
local systemMenuInstance: any = nil

local function isAnyModalOpen(): boolean
    local invOpen = (inventoryModal and inventoryModal.IsOpen and inventoryModal.IsOpen()) or false
    local barterOpen = (barterModal and barterModal.IsOpen and barterModal.IsOpen()) or false
    local sysOpen = isSystemMenuOpen or (systemMenuInstance and systemMenuInstance.IsOpen and systemMenuInstance.IsOpen()) or false
    return sysOpen or invOpen or barterOpen or ModalManager.IsAnyModalOpen()
end

local function isCursorFree(): boolean
    return isAltHeld or isAltToggled or isAnyModalOpen()
end

local isTPP = player:GetAttribute("IsTPP") ~= false -- Default to true for testing realistic 3D character!
player:SetAttribute("IsTPP", isTPP)

local function enforcePerspective()
    if player:GetAttribute("IsInGameplay") ~= true then return end
    if isCursorFree() then return end

    local cam = workspace.CurrentCamera
    if isTPP then
        player.CameraMode = Enum.CameraMode.Classic
        player.CameraMinZoomDistance = 7
        player.CameraMaxZoomDistance = 22
        if cam and cam.CameraType ~= Enum.CameraType.Custom then
            cam.CameraType = Enum.CameraType.Custom
        end
    else
        player.CameraMode = Enum.CameraMode.LockFirstPerson
        player.CameraMinZoomDistance = 0.5
        player.CameraMaxZoomDistance = 0.5
        if cam and cam.CameraType ~= Enum.CameraType.Custom then
            cam.CameraType = Enum.CameraType.Custom
        end
    end
end

local function updateMouseBehavior()
    local inGameplay = player:GetAttribute("IsInGameplay") == true
    local cam = workspace.CurrentCamera

    if not inGameplay then
        hudGui.Enabled = false
        modalBypassBtn.Modal = false
        savedCameraRotation = nil
        player.CameraMode = Enum.CameraMode.Classic
        if cam and cam.CameraType ~= Enum.CameraType.Custom then
            cam.CameraType = Enum.CameraType.Custom
        end
        UserInputService.MouseBehavior = Enum.MouseBehavior.Default
        UserInputService.MouseIconEnabled = true
        if crosshairInstance then
            crosshairInstance.SetVisible(false)
        end
        return
    end

    hudGui.Enabled = true

    if isCursorFree() then
        -- Freeze camera look completely so mouse movement does NOT rotate main camera
        if cam then
            if not savedCameraRotation then
                savedCameraRotation = cam.CFrame.Rotation
            end
            if cam.CameraType ~= Enum.CameraType.Scriptable then
                cam.CameraType = Enum.CameraType.Scriptable
            end
        end
        player.CameraMode = Enum.CameraMode.Classic
        modalBypassBtn.Modal = true
        UserInputService.MouseBehavior = Enum.MouseBehavior.Default
        UserInputService.MouseIconEnabled = true
        if crosshairInstance then
            crosshairInstance.SetVisible(false)
        end
    elseif isTPP then
        -- Third-Person Perspective (TPP): Orbit camera with locked center mouse for smooth look
        savedCameraRotation = nil
        modalBypassBtn.Modal = false
        player.CameraMode = Enum.CameraMode.Classic
        player.CameraMinZoomDistance = 7
        player.CameraMaxZoomDistance = 22
        if cam and cam.CameraType ~= Enum.CameraType.Custom then
            cam.CameraType = Enum.CameraType.Custom
        end
        UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
        UserInputService.MouseIconEnabled = false
        if crosshairInstance then
            crosshairInstance.SetVisible(false)
        end
    else
        -- Active first-person gameplay: lock mouse to center, hide OS cursor, show GTA V reticle
        savedCameraRotation = nil
        modalBypassBtn.Modal = false
        player.CameraMode = Enum.CameraMode.LockFirstPerson
        player.CameraMinZoomDistance = 0.5
        player.CameraMaxZoomDistance = 0.5
        if cam and cam.CameraType ~= Enum.CameraType.Custom then
            cam.CameraType = Enum.CameraType.Custom
        end
        UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
        UserInputService.MouseIconEnabled = false
        if crosshairInstance then
            crosshairInstance.SetVisible(true)
        end
    end
end

player:GetAttributeChangedSignal("IsInGameplay"):Connect(function()
    updateMouseBehavior()
end)

-- Connect [V] keybind to toggle between Third-Person (TPP) and First-Person (FPP)
UserInputService.InputBegan:Connect(function(input: InputObject, gameProcessed: boolean)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.V then
        isTPP = not isTPP
        player:SetAttribute("IsTPP", isTPP)
        updateMouseBehavior()
    end
end)

-- Connect modal state change callbacks so closing via button/key instantly updates mouse
inventoryModal.SetOnOpen(updateMouseBehavior)
inventoryModal.SetOnClose(updateMouseBehavior)
barterModal.SetOnOpen(updateMouseBehavior)
barterModal.SetOnClose(updateMouseBehavior)

-- Continuous guard for camera properties during active play
local function onCameraPropChanged()
    if player:GetAttribute("IsInGameplay") == true and not isCursorFree() then
        enforcePerspective()
    end
end

player:GetPropertyChangedSignal("CameraMode"):Connect(onCameraPropChanged)
player:GetPropertyChangedSignal("CameraMaxZoomDistance"):Connect(onCameraPropChanged)
player:GetPropertyChangedSignal("CameraMinZoomDistance"):Connect(onCameraPropChanged)

--------------------------------------------------------------------------------
-- FULLSCREEN SETTINGS / ESC MENU
--------------------------------------------------------------------------------
systemMenuInstance = UI.SystemMenu.Create(hudGui, {
    OnResume = function()
        isSystemMenuOpen = false
        ModalManager.NotifyStateChange()
        updateMouseBehavior()
    end,
    OnClose = function()
        isSystemMenuOpen = false
        ModalManager.NotifyStateChange()
        updateMouseBehavior()
    end,
    OnQuit = function()
        isSystemMenuOpen = false
        if activeHumanoid then
            activeHumanoid.Health = 0
        end
        hudGui.Enabled = false
        UserInputService.MouseBehavior = Enum.MouseBehavior.Default
        ModalManager.NotifyStateChange()
        updateMouseBehavior()
    end,
})

-- Register all in-game modals with the global ModalManager coordinator
ModalManager.Register("InventoryModal", function()
    return (inventoryModal and inventoryModal.IsOpen and inventoryModal.IsOpen()) or false
end)
ModalManager.Register("BarterModal", function()
    return (barterModal and barterModal.IsOpen and barterModal.IsOpen()) or false
end)
ModalManager.Register("SettingsMenu", function()
    return isSystemMenuOpen or (systemMenuInstance and systemMenuInstance.IsOpen and systemMenuInstance.IsOpen()) or false
end)

-- Global modal listener: fires whenever any system (dialogue, trading, inventory) opens or closes
ModalManager.OnStateChanged(function()
    updateMouseBehavior()
end)

local function toggleSystemMenu()
    isAltToggled = false
    isAltHeld = false
    local wasOpen = isSystemMenuOpen or (systemMenuInstance and systemMenuInstance.IsOpen and systemMenuInstance.IsOpen())
    if wasOpen then
        isSystemMenuOpen = false
        systemMenuInstance.Close()
    else
        if inventoryModal.IsOpen() then
            inventoryModal.Close()
        end
        if barterModal.IsOpen() then
            barterModal.Close()
        end
        isSystemMenuOpen = true
        systemMenuInstance.Open()
    end
    updateMouseBehavior()
end

topRightWidget.SetOnSettingsClick(function()
    toggleSystemMenu()
end)

topRightWidget.SetOnBackpackClick(function()
    if barterModal.IsOpen() then
        barterModal.Close()
    end
    inventoryModal.Toggle()
    updateMouseBehavior()
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

        local lowerMsg = message:lower()
        if lowerMsg:find("wood") then
            AudioManager.Play("WoodGather")
        elseif lowerMsg:find("matchbox") then
            AudioManager.Play("Matchbox")
        elseif lowerMsg:find("flame") or lowerMsg:find("fire") or lowerMsg:find("stoked") or lowerMsg:find("fed") then
            AudioManager.Play("CampfireFuel")
        elseif lowerMsg:find("full") or lowerMsg:find("limit") or lowerMsg:find("cannot") or lowerMsg:find("capacity") then
            AudioManager.Play("Warning")
        else
            AudioManager.Play("ItemPickup")
        end
    end)
end

local function refreshAllInventoryUI()
    -- Sync bottom hotbar (slots 1 to 3)
    for i = 1, InventoryConfig.MAX_HOTBAR_SLOTS do
        hotbarInstance.SetSlot(i, currentInventory[i])
    end

    -- Sync 12-slot backpack modal
    inventoryModal.UpdateInventory(currentInventory)

    -- Sync Silas barter modal
    barterModal.UpdateInventory(currentInventory)
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

local ProximityPromptService = game:GetService("ProximityPromptService")

-- Ensure ALL ProximityPrompts never sink mouse clicks or trap the FPS camera
local function sanitizePrompt(prompt: ProximityPrompt)
    prompt.ClickablePrompt = false
end

ProximityPromptService.PromptShown:Connect(sanitizePrompt)
for _, p in ipairs(workspace:GetDescendants()) do
    if p:IsA("ProximityPrompt") then
        sanitizePrompt(p)
    end
end
workspace.DescendantAdded:Connect(function(desc)
    if desc:IsA("ProximityPrompt") then
        sanitizePrompt(desc)
    end
end)

local function openBarterUI()
    if inventoryModal.IsOpen() then
        inventoryModal.Close()
    end
    barterModal.UpdateInventory(currentInventory)
    barterModal.Open()
    updateMouseBehavior()
end

-- 1. Direct Instant Client Prompt Hook (0ms latency, guaranteed trigger)
ProximityPromptService.PromptTriggered:Connect(function(prompt: ProximityPrompt, triggeringPlayer: Player)
    if triggeringPlayer == player and (prompt.Name == "SilasBarterPrompt" or prompt.ActionText == "Barter") then
        openBarterUI()
    end
end)

-- 2. Server Remote Event Backup
task.spawn(function()
    local openBarterMenuEvent = sharedFolder:WaitForChild("OpenBarterMenu") :: RemoteEvent
    openBarterMenuEvent.OnClientEvent:Connect(function()
        openBarterUI()
    end)
end)

local function dropActiveItem()
    if _G.FluenosityAnimController and _G.FluenosityAnimController.TriggerItemThrow then
        _G.FluenosityAnimController.TriggerItemThrow()
    end
    if dropItemEvent then
        AudioManager.Play("ItemDrop")
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

        if clockInstance and clockInstance.SetTime then
            clockInstance.SetTime(hour :: number, day :: number, phase :: string, progress :: number)
        end
        if topRightWidget and topRightWidget.SetTime then
            topRightWidget.SetTime(hour :: number, day :: number, phase :: string)
        end
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
        if campfire.PrimaryPart then
            topRightWidget.SetCampfirePosition(campfire.PrimaryPart.Position)
        end
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
-- 5. CHARACTER INTEGRATION & VITALS
--------------------------------------------------------------------------------
local function setupCharacter(character: Model)
    activeCharacter = character
    activeHumanoid = character:WaitForChild("Humanoid", 10) :: Humanoid?
    if not activeHumanoid then return end

    -- Clean up any lingering GenshinStaminaBar on character
    local oldGenshin = character:FindFirstChild("GenshinStaminaBar")
    if oldGenshin then
        oldGenshin:Destroy()
    end

    if characterJumpConn then
        characterJumpConn:Disconnect()
        characterJumpConn = nil
    end

    if jumpCooldownThread then
        task.cancel(jumpCooldownThread)
        jumpCooldownThread = nil
    end

    if characterHealthConn then
        characterHealthConn:Disconnect()
        characterHealthConn = nil
    end

    currentStamina = maxStamina
    isSprinting = false
    isFatigued = false
    activeHumanoid.WalkSpeed = normalWalkSpeed
    activeHumanoid.UseJumpPower = true
    activeHumanoid.JumpPower = normalJumpPower
    activeHumanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, true)
    if player:GetAttribute("IsTPP") == true then
        player.CameraMode = Enum.CameraMode.Classic
        player.CameraMinZoomDistance = 6
        player.CameraMaxZoomDistance = 14
    else
        player.CameraMode = Enum.CameraMode.LockFirstPerson
        player.CameraMinZoomDistance = 0.5
        player.CameraMaxZoomDistance = 0.5
    end

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

    -- Jump debounce & hold-prevention coordinator:
    -- 1. One Space = One Jump (no continuous bunny-hopping when holding Space).
    -- 2. Spam Prevention: Character must complete the jump, land, and finish the recovery gap
    --    before another jump can ever trigger.
    characterJumpConn = activeHumanoid.Jumping:Connect(function(isActive: boolean)
        if isActive and activeHumanoid.Health > 0 then
            -- Immediately lock jumping state so mid-air spam or holding space is blocked
            activeHumanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, false)

            if jumpCooldownThread then
                task.cancel(jumpCooldownThread)
            end

            jumpCooldownThread = task.spawn(function()
                -- 1. Wait until character leaves the ground (becomes airborne)
                local t0 = os.clock()
                while activeHumanoid and activeHumanoid.FloorMaterial ~= Enum.Material.Air and (os.clock() - t0 < 0.35) do
                    task.wait()
                end

                -- 2. Wait until character lands back on the ground
                t0 = os.clock()
                while activeHumanoid and activeHumanoid.FloorMaterial == Enum.Material.Air and (os.clock() - t0 < 8.0) do
                    task.wait()
                end

                -- 3. Recovery gap: Let the landing animation & physical compression finish cleanly
                task.wait(JUMP_RECOVERY_GAP)

                -- 4. Hold prevention: Wait until player releases the jump key
                while isJumpPhysicallyHeld() do
                    task.wait()
                end

                -- 5. Re-enable jumping for the next fresh jump press
                if activeHumanoid and not isFatigued then
                    activeHumanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, true)
                end
            end)

            if not UNLIMITED_STAMINA_DEV then
                if not isFatigued then
                    currentStamina = math.max(0, currentStamina - 8)
                    lastSprintTime = os.clock()
                    vitalsInstance.SetStamina(currentStamina, maxStamina)
                    if currentStamina <= 0 then
                        isFatigued = true
                        isSprinting = false
                        activeHumanoid.WalkSpeed = fatiguedWalkSpeed
                        activeHumanoid.JumpPower = fatiguedJumpPower
                    end
                end
            else
                currentStamina = maxStamina
                vitalsInstance.SetStamina(maxStamina, maxStamina)
            end
        end
    end)

    if player:GetAttribute("IsInGameplay") == true then
        updateMouseBehavior()
    else
        hudGui.Enabled = false
    end
end

if player.Character then
    setupCharacter(player.Character)
end
player.CharacterAdded:Connect(setupCharacter)

player:GetAttributeChangedSignal("IsInGameplay"):Connect(function()
    updateMouseBehavior()
end)

-- Initial check if already in gameplay (e.g. dev mode skip main menu)
if player:GetAttribute("IsInGameplay") == true then
    updateMouseBehavior()
end

--------------------------------------------------------------------------------
-- 6. RUNTIME LOOPS (Stamina, Hunger)
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

    -- Movement speed arbitration (attacks stay mobile; Crouch = 8, Walk = 16, Sprint = 26)
    local isAttacking = (activeCharacter and activeCharacter:GetAttribute("IsAttacking") == true)
    local isCrouched = (activeCharacter and activeCharacter:GetAttribute("IsCrouching") == true)

    if UNLIMITED_STAMINA_DEV then
        currentStamina = maxStamina
        isFatigued = false
        if activeHumanoid then
            local targetSpeed = normalWalkSpeed
            if isCrouched then
                targetSpeed = 8
            elseif isSprinting then
                targetSpeed = sprintWalkSpeed
            else
                targetSpeed = normalWalkSpeed
            end
            activeHumanoid.WalkSpeed = targetSpeed
            activeHumanoid.JumpPower = normalJumpPower
        end
        vitalsInstance.SetStamina(maxStamina, maxStamina)
    else
        if isSprinting and isMoving and not isFatigued and not isCrouched and not isAttacking then
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
                        local cCrouched = activeCharacter and activeCharacter:GetAttribute("IsCrouching") == true
                        activeHumanoid.WalkSpeed = cCrouched and 8 or normalWalkSpeed
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
                        local cCrouched = activeCharacter and activeCharacter:GetAttribute("IsCrouching") == true
                        activeHumanoid.WalkSpeed = cCrouched and 8 or normalWalkSpeed
                        activeHumanoid.JumpPower = normalJumpPower
                    end
                end
            end
        end

        if activeHumanoid then
            local targetSpeed = normalWalkSpeed
            if isCrouched then
                targetSpeed = 8
            elseif isFatigued then
                targetSpeed = fatiguedWalkSpeed
            elseif isSprinting and isMoving then
                targetSpeed = sprintWalkSpeed
            else
                targetSpeed = normalWalkSpeed
            end
            activeHumanoid.WalkSpeed = targetSpeed
        end

        -- Update vitals
        vitalsInstance.SetStamina(currentStamina, maxStamina)
    end

    -- Continuously maintain LockCenter during gameplay (prevents mouse escaping on interaction prompts)
    if player:GetAttribute("IsInGameplay") == true then
        if not isAnyModalOpen() and not isAltHeld then
            if UserInputService.MouseBehavior ~= Enum.MouseBehavior.LockCenter then
                UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
            end
        end
    end
end)

RunService.RenderStepped:Connect(function()
    if player:GetAttribute("IsInGameplay") == true then
        local cam = workspace.CurrentCamera
        if isCursorFree() then
            -- Cursor is free: keep camera Scriptable and freeze camera orientation
            if cam then
                if cam.CameraType ~= Enum.CameraType.Scriptable then
                    cam.CameraType = Enum.CameraType.Scriptable
                end
                if savedCameraRotation and activeCharacter and activeCharacter:FindFirstChild("Head") then
                    cam.CFrame = CFrame.new(activeCharacter.Head.Position) * savedCameraRotation
                end
            end
            if UserInputService.MouseBehavior ~= Enum.MouseBehavior.Default then
                UserInputService.MouseBehavior = Enum.MouseBehavior.Default
            end
            if UserInputService.MouseIconEnabled ~= true then
                UserInputService.MouseIconEnabled = true
            end
        else
            -- Normal gameplay: ensure Custom camera and LockCenter
            if cam and cam.CameraType ~= Enum.CameraType.Custom then
                cam.CameraType = Enum.CameraType.Custom
            end
            if UserInputService.MouseBehavior ~= Enum.MouseBehavior.LockCenter then
                UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
            end
            if UserInputService.MouseIconEnabled ~= false then
                UserInputService.MouseIconEnabled = false
            end

            -- Aim detection for GTA V dot interaction cue
            if cam and crosshairInstance then
                local centerRay = cam:ViewportPointToRay(cam.ViewportSize.X * 0.5, cam.ViewportSize.Y * 0.5)
                local rayParams = RaycastParams.new()
                rayParams.FilterType = Enum.RaycastFilterType.Exclude
                if activeCharacter then
                    rayParams.FilterDescendantsInstances = {activeCharacter}
                end
                local result = workspace:Raycast(centerRay.Origin, centerRay.Direction * 14, rayParams)
                local isHovering = false
                if result and result.Instance then
                    local hitPart = result.Instance
                    local prompt = hitPart:FindFirstChildOfClass("ProximityPrompt")
                        or (hitPart.Parent and hitPart.Parent:FindFirstChildOfClass("ProximityPrompt"))
                    if prompt and prompt.Enabled then
                        isHovering = true
                    end
                end
                crosshairInstance.SetHovering(isHovering)
            end
        end
    end
end)

--------------------------------------------------------------------------------
-- 7. KEYBOARD & INPUT BINDINGS
--------------------------------------------------------------------------------
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    -- Ignore keystrokes if user is typing inside a text input (e.g. Chat, search)
    if UserInputService:GetFocusedTextBox() ~= nil then
        return
    end

    -- Alt cursor unlock & Shift sprint must NEVER be blocked by gameProcessed
    if input.KeyCode == Enum.KeyCode.LeftAlt or input.KeyCode == Enum.KeyCode.RightAlt then
        if player:GetAttribute("IsInGameplay") == true then
            altPressTime = os.clock()
            isAltHeld = true
            updateMouseBehavior()
        end
        return
    elseif input.KeyCode == Enum.KeyCode.LeftShift or input.KeyCode == Enum.KeyCode.RightShift then
        if player:GetAttribute("IsInGameplay") == true then
            if UNLIMITED_STAMINA_DEV or (not isFatigued and currentStamina > 0) then
                -- Sprinting automatically un-crouches the character
                if activeCharacter and activeCharacter:GetAttribute("IsCrouching") == true then
                    activeCharacter:SetAttribute("IsCrouching", false)
                end
                isSprinting = true
                vitalsInstance.SetSprinting(true)
                if activeHumanoid and not (activeCharacter and activeCharacter:GetAttribute("IsAttacking") == true) then
                    activeHumanoid.WalkSpeed = sprintWalkSpeed
                end
            end
        end
        return
    end

    -- Escape key handles closing open modals or toggling Settings Menu (processed even if gameProcessed)
    if input.KeyCode == Enum.KeyCode.Escape then
        if player:GetAttribute("IsInGameplay") == true then
            if isSystemMenuOpen or (systemMenuInstance and systemMenuInstance.IsOpen and systemMenuInstance.IsOpen()) then
                toggleSystemMenu()
            elseif inventoryModal.IsOpen() then
                inventoryModal.Close()
                updateMouseBehavior()
            elseif barterModal.IsOpen() then
                barterModal.Close()
                updateMouseBehavior()
            else
                toggleSystemMenu()
            end
        end
        return
    end

    -- If not yet in active gameplay (e.g. Main Menu), ignore in-game bindings
    if player:GetAttribute("IsInGameplay") ~= true then
        return
    end

    if input.KeyCode == Enum.KeyCode.Space or input.KeyCode == Enum.KeyCode.ButtonA then
        isJumpInputHeld = true
    end

    if gameProcessed then return end

    if input.KeyCode == Enum.KeyCode.One then
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
        if isSystemMenuOpen then
            systemMenuInstance.Close()
            isSystemMenuOpen = false
        end
        if barterModal.IsOpen() then
            barterModal.Close()
        end
        isAltToggled = false
        isAltHeld = false
        inventoryModal.Toggle()
        updateMouseBehavior()
    elseif input.KeyCode == Enum.KeyCode.V then
        isTPP = not isTPP
        player:SetAttribute("IsTPP", isTPP)
        enforcePerspective()
        updateMouseBehavior()
    elseif input.KeyCode == Enum.KeyCode.M or input.KeyCode == Enum.KeyCode.P then
        toggleSystemMenu()
    elseif input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.MouseButton2 then
        -- Clicking into the world cancels Alt free-look toggle if no modal is open
        if isAltToggled and not isAnyModalOpen() then
            isAltToggled = false
            updateMouseBehavior()
        elseif not isCursorFree() and player:GetAttribute("IsInGameplay") == true then
            updateMouseBehavior()
        end
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.KeyCode == Enum.KeyCode.Space or input.KeyCode == Enum.KeyCode.ButtonA then
        isJumpInputHeld = false
        return
    end

    if input.KeyCode == Enum.KeyCode.LeftAlt or input.KeyCode == Enum.KeyCode.RightAlt then
        if player:GetAttribute("IsInGameplay") == true then
            local heldDuration = os.clock() - altPressTime
            isAltHeld = false
            if heldDuration < 0.25 then
                isAltToggled = not isAltToggled
            else
                isAltToggled = false
            end
            updateMouseBehavior()
        end
        return
    elseif input.KeyCode == Enum.KeyCode.LeftShift or input.KeyCode == Enum.KeyCode.RightShift then
        isSprinting = false
        vitalsInstance.SetSprinting(false)
        if activeHumanoid and not isFatigued then
            local isCrouched = activeCharacter and activeCharacter:GetAttribute("IsCrouching") == true
            activeHumanoid.WalkSpeed = isCrouched and 8 or normalWalkSpeed
        end
    end
end)
