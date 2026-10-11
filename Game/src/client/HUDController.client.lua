--!strict
--[[
    HUDController.client.lua
    In-game HUD, survival clock, Genshin Impact stamina system, hotbar,
    backpack modal, and in-game pause menu for "Don't Let the Fire Die".
    Developed for Fluenosity Studio.
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ContextActionService = game:GetService("ContextActionService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui") :: PlayerGui

local UITheme = require(script.Parent:WaitForChild("UITheme"))
local UIComponents = require(script.Parent:WaitForChild("UIComponents"))

local sharedFolder = ReplicatedStorage:WaitForChild("FluenosityShared")
local InventoryConfig = require(sharedFolder:WaitForChild("InventoryConfig"))

--------------------------------------------------------------------------------
-- STATE
--------------------------------------------------------------------------------
local maxStamina = 100.0
local currentStamina = 100.0
local isSprinting = false
local isFatigued = false
local lastSprintTime = 0.0

local normalWalkSpeed = 16
local sprintWalkSpeed = 24
local fatiguedWalkSpeed = 10

local currentInventory = {}
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

local selectedHotbarSlot = 1
local activeCharacter: Model? = nil
local activeHumanoid: Humanoid? = nil

--------------------------------------------------------------------------------
-- ROOT HUD SCREENGUI
--------------------------------------------------------------------------------
local hudGui = Instance.new("ScreenGui")
hudGui.Name = "DontLetTheFireDie_InGameHUD"
hudGui.ResetOnSpawn = false
hudGui.IgnoreGuiInset = false
hudGui.DisplayOrder = 20
hudGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
hudGui.Enabled = false
hudGui.Parent = playerGui

--------------------------------------------------------------------------------
-- 1. TOP SURVIVAL CLOCK WIDGET
--------------------------------------------------------------------------------
local clockWidget = UIComponents.CreateHUDClock(hudGui)

local timeState = sharedFolder:WaitForChild("TimeState", 10) :: Folder?
if timeState then
    local function syncTime()
        local day = timeState:GetAttribute("CurrentDay") or 0
        local hour = timeState:GetAttribute("CurrentHour") or 8.0
        local phase = timeState:GetAttribute("CurrentPhase") or "Day"
        local progress = timeState:GetAttribute("PhaseProgress") or 0.0

        clockWidget.SetDay(day :: number)
        clockWidget.SetTime(hour :: number, phase :: string, progress :: number)
    end

    syncTime()
    timeState:GetAttributeChangedSignal("CurrentDay"):Connect(syncTime)
    timeState:GetAttributeChangedSignal("CurrentHour"):Connect(syncTime)
    timeState:GetAttributeChangedSignal("CurrentPhase"):Connect(syncTime)
    timeState:GetAttributeChangedSignal("PhaseProgress"):Connect(syncTime)
end

--------------------------------------------------------------------------------
-- 2. BOTTOM HOTBAR (3 SLOTS)
--------------------------------------------------------------------------------
local hotbarWidget = UIComponents.CreateHotbar(hudGui, function(slotIndex)
    selectedHotbarSlot = slotIndex
end)

local function refreshHotbarUI()
    for i = 1, 3 do
        local slot = currentInventory[i]
        if slot then
            local def = InventoryConfig.Items[slot.Id]
            if def then
                hotbarWidget.SetSlotItem(i, {
                    Id = def.Id,
                    Name = def.Name,
                    Count = slot.Count,
                    IconText = def.IconText,
                    Category = def.Category,
                })
            else
                hotbarWidget.SetSlotItem(i, nil)
            end
        else
            hotbarWidget.SetSlotItem(i, nil)
        end
    end
end

refreshHotbarUI()

--------------------------------------------------------------------------------
-- 3. GENSHIN IMPACT STYLE STAMINA BAR CONTROLLER
--------------------------------------------------------------------------------
local currentStaminaBar: any = nil

local function setupCharacterStamina(character: Model)
    activeCharacter = character
    activeHumanoid = character:WaitForChild("Humanoid", 10) :: Humanoid?
    if not activeHumanoid then return end

    if currentStaminaBar then
        currentStaminaBar.Destroy()
        currentStaminaBar = nil
    end

    currentStaminaBar = UIComponents.CreateGenshinStaminaBar(character)
    currentStamina = maxStamina
    isSprinting = false
    isFatigued = false
    activeHumanoid.WalkSpeed = normalWalkSpeed

    hudGui.Enabled = true
end

if player.Character then
    setupCharacterStamina(player.Character)
end
player.CharacterAdded:Connect(setupCharacterStamina)

-- Stamina drain / regen loop
RunService.Heartbeat:Connect(function(deltaTime: number)
    if not activeHumanoid or not activeHumanoid.Parent or activeHumanoid.Health <= 0 then
        return
    end

    local isMoving = activeHumanoid.MoveDirection.Magnitude > 0.1

    if isSprinting and isMoving and not isFatigued then
        -- Drain stamina (20 per second = 5s full sprint)
        currentStamina = math.max(0, currentStamina - (20 * deltaTime))
        lastSprintTime = os.clock()

        if currentStamina <= 0 then
            -- Fatigue triggered
            isFatigued = true
            isSprinting = false
            activeHumanoid.WalkSpeed = fatiguedWalkSpeed

            task.delay(1.2, function()
                if activeHumanoid and not isSprinting then
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
                end
            end
        end
    end

    -- Update Genshin stamina meter
    if currentStaminaBar then
        currentStaminaBar.SetStamina(currentStamina, maxStamina, isSprinting and isMoving)
    end
end)

--------------------------------------------------------------------------------
-- 4. IN-GAME SETTINGS & PAUSE MENU (ESC / M)
--------------------------------------------------------------------------------
local pauseMenuInstance: any = nil

local settingsModal = UIComponents.CreateModal({
    Title = "SETTINGS",
    CategoryTag = "[ IN-GAME AUDIO & GRAPHICS ]",
    Width = 440,
    Height = 390,
    Parent = hudGui,
})

local settingsLayout = Instance.new("UIListLayout")
settingsLayout.FillDirection = Enum.FillDirection.Vertical
settingsLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
settingsLayout.Padding = UDim.new(0, 18)
settingsLayout.Parent = settingsModal.Content

UIComponents.CreateSlider({
    Label = "MASTER VOLUME",
    Description = "Controls game-wide sound effects & ambience",
    InitialValue = UITheme.GetMasterVolume(),
    Parent = settingsModal.Content,
    OnChanged = function(val: number)
        UITheme.SetMasterVolume(val)
    end,
})

UIComponents.CreateDivider(settingsModal.Content)

UIComponents.CreateToggle({
    Label = "REDUCED MOTION",
    Description = "Limits intense camera shakes and screen distortions",
    InitialValue = false,
    Parent = settingsModal.Content,
    OnChanged = function(enabled: boolean)
        -- Hook to client motion preferences
    end,
})

pauseMenuInstance = UIComponents.CreatePauseMenu(hudGui, {
    OnResume = function()
        -- Game resumed
    end,
    OnSettings = function()
        settingsModal.Open()
    end,
    OnQuit = function()
        -- Return to main menu: reset character and trigger main menu
        if activeHumanoid then
            activeHumanoid.Health = 0
        end
        hudGui.Enabled = false
    end,
})

--------------------------------------------------------------------------------
-- 5. FULL 9-SLOT BACKPACK INVENTORY MODAL
--------------------------------------------------------------------------------
local backpackModal = UIComponents.CreateModal({
    Title = "SURVIVAL BACKPACK",
    CategoryTag = "[ CAPACITY: 9 PERSONAL SLOTS ]",
    Width = 620,
    Height = 490,
    Parent = hudGui,
})

local bpMainLayout = Instance.new("UIListLayout")
bpMainLayout.FillDirection = Enum.FillDirection.Horizontal
bpMainLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
bpMainLayout.VerticalAlignment = Enum.VerticalAlignment.Center
bpMainLayout.Padding = UDim.new(0, 18)
bpMainLayout.Parent = backpackModal.Content

-- Left Grid Section (Slots 1-3 Hotbar, Slots 4-9 Storage)
local gridFrame = Instance.new("Frame")
gridFrame.Name = "GridSection"
gridFrame.Size = UDim2.new(0, 240, 1, 0)
gridFrame.BackgroundTransparency = 1
gridFrame.Parent = backpackModal.Content

local gridList = Instance.new("UIListLayout")
gridList.FillDirection = Enum.FillDirection.Vertical
gridList.Padding = UDim.new(0, 10)
gridList.Parent = gridFrame

local hotbarHeader = Instance.new("TextLabel")
hotbarHeader.Size = UDim2.new(1, 0, 0, 16)
hotbarHeader.BackgroundTransparency = 1
hotbarHeader.Font = UITheme.Fonts.Tag
hotbarHeader.Text = "ACTIVE HOTBAR (SLOTS 1–3)"
hotbarHeader.TextColor3 = UITheme.Colors.EmberHot
hotbarHeader.TextSize = 10
hotbarHeader.TextXAlignment = Enum.TextXAlignment.Left
hotbarHeader.Parent = gridFrame

local hotbarRow = Instance.new("Frame")
hotbarRow.Size = UDim2.new(1, 0, 0, 68)
hotbarRow.BackgroundTransparency = 1
hotbarRow.Parent = gridFrame

local hotbarRowLayout = Instance.new("UIListLayout")
hotbarRowLayout.FillDirection = Enum.FillDirection.Horizontal
hotbarRowLayout.Padding = UDim.new(0, 10)
hotbarRowLayout.Parent = hotbarRow

local packHeader = Instance.new("TextLabel")
packHeader.Size = UDim2.new(1, 0, 0, 16)
packHeader.BackgroundTransparency = 1
packHeader.Font = UITheme.Fonts.Tag
packHeader.Text = "BACKPACK STORAGE (SLOTS 4–9)"
packHeader.TextColor3 = UITheme.Colors.TextMuted
packHeader.TextSize = 10
packHeader.TextXAlignment = Enum.TextXAlignment.Left
packHeader.Parent = gridFrame

local packGrid = Instance.new("Frame")
packGrid.Size = UDim2.new(1, 0, 0, 150)
packGrid.BackgroundTransparency = 1
packGrid.Parent = gridFrame

local packGridLayout = Instance.new("UIGridLayout")
packGridLayout.CellSize = UDim2.fromOffset(68, 68)
packGridLayout.CellPadding = UDim2.fromOffset(10, 10)
packGridLayout.Parent = packGrid

-- Right Inspector Section (Item preview, description, actions)
local inspector = Instance.new("Frame")
inspector.Name = "Inspector"
inspector.Size = UDim2.new(0, 290, 1, 0)
inspector.BackgroundColor3 = UITheme.Colors.Surface
inspector.BorderSizePixel = 0
inspector.Parent = backpackModal.Content

local inspectCorner = Instance.new("UICorner")
inspectCorner.CornerRadius = UDim.new(0, 10)
inspectCorner.Parent = inspector

local inspectStroke = Instance.new("UIStroke")
inspectStroke.Color = UITheme.Colors.BorderHairline
inspectStroke.Thickness = 1
inspectStroke.Parent = inspector

local inspectPadding = Instance.new("UIPadding")
inspectPadding.PaddingTop = UDim.new(0, 16)
inspectPadding.PaddingBottom = UDim.new(0, 16)
inspectPadding.PaddingLeft = UDim.new(0, 18)
inspectPadding.PaddingRight = UDim.new(0, 18)
inspectPadding.Parent = inspector

local inspectLayout = Instance.new("UIListLayout")
inspectLayout.FillDirection = Enum.FillDirection.Vertical
inspectLayout.Padding = UDim.new(0, 10)
inspectLayout.Parent = inspector

local itemIconLarge = Instance.new("TextLabel")
itemIconLarge.Size = UDim2.new(1, 0, 0, 52)
itemIconLarge.BackgroundTransparency = 1
itemIconLarge.Font = UITheme.Fonts.Heading
itemIconLarge.Text = "🪓"
itemIconLarge.TextColor3 = UITheme.Colors.TextPrimary
itemIconLarge.TextSize = 36
itemIconLarge.Parent = inspector

local itemCategoryTag = Instance.new("TextLabel")
itemCategoryTag.Size = UDim2.new(1, 0, 0, 14)
itemCategoryTag.BackgroundTransparency = 1
itemCategoryTag.Font = UITheme.Fonts.Tag
itemCategoryTag.Text = "[ TOOL ]"
itemCategoryTag.TextColor3 = UITheme.Colors.EmberHot
itemCategoryTag.TextSize = 10
itemCategoryTag.Parent = inspector

local itemNameLarge = Instance.new("TextLabel")
itemNameLarge.Size = UDim2.new(1, 0, 0, 22)
itemNameLarge.BackgroundTransparency = 1
itemNameLarge.Font = UITheme.Fonts.Heading
itemNameLarge.Text = "STONE HATCHET"
itemNameLarge.TextColor3 = UITheme.Colors.TextPrimary
itemNameLarge.TextSize = 16
itemNameLarge.Parent = inspector

local itemDesc = Instance.new("TextLabel")
itemDesc.Size = UDim2.new(1, 0, 0, 54)
itemDesc.BackgroundTransparency = 1
itemDesc.Font = UITheme.Fonts.Body
itemDesc.Text = "A hand-crafted stone axe. Chop trees to gather wood fuel before nightfall."
itemDesc.TextColor3 = UITheme.Colors.TextSecondary
itemDesc.TextSize = 11
itemDesc.TextWrapped = true
itemDesc.Parent = inspector

local stackLabel = Instance.new("TextLabel")
stackLabel.Size = UDim2.new(1, 0, 0, 16)
stackLabel.BackgroundTransparency = 1
stackLabel.Font = UITheme.Fonts.Tag
stackLabel.Text = "QUANTITY: 1 / 1"
stackLabel.TextColor3 = UITheme.Colors.EmberGold
stackLabel.TextSize = 10
stackLabel.Parent = inspector

local btnUse = Instance.new("TextButton")
btnUse.Size = UDim2.new(1, 0, 0, 36)
btnUse.BackgroundColor3 = UITheme.Colors.EmberPrimary
btnUse.AutoButtonColor = false
btnUse.Font = UITheme.Fonts.Heading
btnUse.Text = "USE / EQUIP"
btnUse.TextColor3 = UITheme.Colors.PureWhite
btnUse.TextSize = 12
btnUse.Parent = inspector

local btnUseCorner = Instance.new("UICorner")
btnUseCorner.CornerRadius = UDim.new(0, 6)
btnUseCorner.Parent = btnUse

local selectedInventorySlot = 1

local function updateInspector(slotIdx: number)
    selectedInventorySlot = slotIdx
    local slot = currentInventory[slotIdx]
    if slot then
        local def = InventoryConfig.Items[slot.Id]
        if def then
            itemIconLarge.Text = def.IconText
            itemCategoryTag.Text = string.format("[ %s ]", def.Category:upper())
            itemNameLarge.Text = def.Name
            itemDesc.Text = def.Description
            stackLabel.Text = string.format("QUANTITY: %d / %d", slot.Count, def.MaxStack)
            btnUse.Text = (def.Category == "Tool") and "EQUIP TO HANDS" or "USE ITEM"
            btnUse.Visible = true
            return
        end
    end

    -- Empty slot preview
    itemIconLarge.Text = "📦"
    itemCategoryTag.Text = "[ EMPTY SLOT ]"
    itemNameLarge.Text = "EMPTY"
    itemDesc.Text = "Scavenge resources from the wilderness or storage chests to fill this slot."
    stackLabel.Text = "QUANTITY: 0"
    btnUse.Visible = false
end

local slotButtons: { [number]: TextButton } = {}

local function createSlotButton(idx: number, parentSection: Instance)
    local btn = Instance.new("TextButton")
    btn.Name = "BpSlot_" .. idx
    btn.Size = UDim2.fromOffset(68, 68)
    btn.BackgroundColor3 = (idx == selectedInventorySlot) and UITheme.Colors.SurfaceHighlight or UITheme.Colors.Surface
    btn.AutoButtonColor = false
    btn.Text = ""
    btn.Parent = parentSection

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = btn

    local stroke = Instance.new("UIStroke")
    stroke.Color = (idx == selectedInventorySlot) and UITheme.Colors.EmberHot or UITheme.Colors.BorderHairline
    stroke.Thickness = (idx == selectedInventorySlot) and 2 or 1
    stroke.Parent = btn

    local icon = Instance.new("TextLabel")
    icon.Name = "Icon"
    icon.Size = UDim2.new(1, 0, 0, 32)
    icon.Position = UDim2.fromOffset(0, 8)
    icon.BackgroundTransparency = 1
    icon.Font = UITheme.Fonts.Heading
    icon.Text = ""
    icon.TextSize = 22
    icon.Parent = btn

    local countLbl = Instance.new("TextLabel")
    countLbl.Name = "Count"
    countLbl.Size = UDim2.fromOffset(22, 14)
    countLbl.Position = UDim2.new(1, -4, 1, -4)
    countLbl.AnchorPoint = Vector2.new(1, 1)
    countLbl.BackgroundColor3 = UITheme.Colors.Void
    countLbl.BackgroundTransparency = 0.3
    countLbl.Font = UITheme.Fonts.Tag
    countLbl.Text = ""
    countLbl.TextColor3 = UITheme.Colors.EmberGold
    countLbl.TextSize = 9
    countLbl.Visible = false
    countLbl.Parent = btn

    local badgeCorner = Instance.new("UICorner")
    badgeCorner.CornerRadius = UDim.new(0, 4)
    badgeCorner.Parent = countLbl

    slotButtons[idx] = btn

    btn.Activated:Connect(function()
        for sIdx, sBtn in pairs(slotButtons) do
            local isSel = (sIdx == idx)
            local sStroke = sBtn:FindFirstChildOfClass("UIStroke")
            if sStroke then
                sStroke.Color = isSel and UITheme.Colors.EmberHot or UITheme.Colors.BorderHairline
                sStroke.Thickness = isSel and 2 or 1
            end
            sBtn.BackgroundColor3 = isSel and UITheme.Colors.SurfaceHighlight or UITheme.Colors.Surface
        end
        updateInspector(idx)
    end)
end

-- Create 3 hotbar slots and 6 backpack slots
for i = 1, 3 do
    createSlotButton(i, hotbarRow)
end
for i = 4, 9 do
    createSlotButton(i, packGrid)
end

local function refreshBackpackUI()
    for i = 1, 9 do
        local btn = slotButtons[i]
        if btn then
            local icon = btn:FindFirstChild("Icon") :: TextLabel?
            local countLbl = btn:FindFirstChild("Count") :: TextLabel?
            local slot = currentInventory[i]
            if slot and icon and countLbl then
                local def = InventoryConfig.Items[slot.Id]
                if def then
                    icon.Text = def.IconText
                    if slot.Count > 1 then
                        countLbl.Text = "x" .. slot.Count
                        countLbl.Visible = true
                    else
                        countLbl.Visible = false
                    end
                else
                    icon.Text = ""
                    countLbl.Visible = false
                end
            elseif icon and countLbl then
                icon.Text = ""
                countLbl.Visible = false
            end
        end
    end
    updateInspector(selectedInventorySlot)
end

refreshBackpackUI()

-- Use Item Action
btnUse.Activated:Connect(function()
    local slot = currentInventory[selectedInventorySlot]
    if not slot then return end

    local def = InventoryConfig.Items[slot.Id]
    if not def then return end

    if def.Category == "Medical" and activeHumanoid then
        -- Heal player
        activeHumanoid.Health = math.min(activeHumanoid.MaxHealth, activeHumanoid.Health + 30)
        slot.Count = slot.Count - 1
        if slot.Count <= 0 then
            currentInventory[selectedInventorySlot] = nil
        end
        refreshBackpackUI()
        refreshHotbarUI()
    elseif def.Category == "Tool" and selectedInventorySlot > 3 then
        -- Quick-swap with hotbar slot 1
        local temp = currentInventory[1]
        currentInventory[1] = slot
        currentInventory[selectedInventorySlot] = temp
        refreshBackpackUI()
        refreshHotbarUI()
    end
end)

--------------------------------------------------------------------------------
-- 6. HUD BUTTONS & CONTROLS (Backpack, Pause, Mobile Sprint)
--------------------------------------------------------------------------------
local controlsHolder = Instance.new("Frame")
controlsHolder.Name = "HUDControls"
controlsHolder.Size = UDim2.fromOffset(180, 50)
controlsHolder.Position = UDim2.new(1, -20, 1, -22)
controlsHolder.AnchorPoint = Vector2.new(1, 1)
controlsHolder.BackgroundTransparency = 1
controlsHolder.ZIndex = 50
controlsHolder.Parent = hudGui

local controlsLayout = Instance.new("UIListLayout")
controlsLayout.FillDirection = Enum.FillDirection.Horizontal
controlsLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
controlsLayout.Padding = UDim.new(0, 10)
controlsLayout.Parent = controlsHolder

-- Backpack Button
local btnBackpack = Instance.new("TextButton")
btnBackpack.Name = "BtnBackpack"
btnBackpack.Size = UDim2.fromOffset(54, 54)
btnBackpack.BackgroundColor3 = UITheme.Colors.SurfaceElevated
btnBackpack.AutoButtonColor = false
btnBackpack.Font = UITheme.Fonts.Tag
btnBackpack.Text = "🎒\n[B]"
btnBackpack.TextColor3 = UITheme.Colors.TextPrimary
btnBackpack.TextSize = 11
btnBackpack.ZIndex = 51
btnBackpack.Parent = controlsHolder

local bpCorner = Instance.new("UICorner")
bpCorner.CornerRadius = UDim.new(0, 8)
bpCorner.Parent = btnBackpack

local bpStroke = Instance.new("UIStroke")
bpStroke.Color = UITheme.Colors.BorderSubtle
bpStroke.Thickness = 1
bpStroke.Parent = btnBackpack

btnBackpack.Activated:Connect(function()
    backpackModal.Open()
end)

-- Pause Menu Button (Top Right)
local btnPauseHUD = Instance.new("TextButton")
btnPauseHUD.Name = "BtnPauseHUD"
btnPauseHUD.Size = UDim2.fromOffset(40, 40)
btnPauseHUD.Position = UDim2.new(1, -20, 0, 16)
btnPauseHUD.AnchorPoint = Vector2.new(1, 0)
btnPauseHUD.BackgroundColor3 = UITheme.Colors.SurfaceElevated
btnPauseHUD.AutoButtonColor = false
btnPauseHUD.Font = UITheme.Fonts.Heading
btnPauseHUD.Text = "⚙"
btnPauseHUD.TextColor3 = UITheme.Colors.TextPrimary
btnPauseHUD.TextSize = 18
btnPauseHUD.ZIndex = 51
btnPauseHUD.Parent = hudGui

local pauseCorner = Instance.new("UICorner")
pauseCorner.CornerRadius = UDim.new(0, 8)
pauseCorner.Parent = btnPauseHUD

local pauseStroke = Instance.new("UIStroke")
pauseStroke.Color = UITheme.Colors.BorderSubtle
pauseStroke.Thickness = 1
pauseStroke.Parent = btnPauseHUD

btnPauseHUD.Activated:Connect(function()
    pauseMenuInstance.Open()
end)

--------------------------------------------------------------------------------
-- 7. KEYBOARD & INPUT BINDINGS
--------------------------------------------------------------------------------
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end

    if input.KeyCode == Enum.KeyCode.LeftShift or input.KeyCode == Enum.KeyCode.RightShift then
        if not isFatigued and currentStamina > 0 then
            isSprinting = true
            if activeHumanoid then
                activeHumanoid.WalkSpeed = sprintWalkSpeed
            end
        end
    elseif input.KeyCode == Enum.KeyCode.One then
        hotbarWidget.SelectSlot(1)
    elseif input.KeyCode == Enum.KeyCode.Two then
        hotbarWidget.SelectSlot(2)
    elseif input.KeyCode == Enum.KeyCode.Three then
        hotbarWidget.SelectSlot(3)
    elseif input.KeyCode == Enum.KeyCode.B or input.KeyCode == Enum.KeyCode.Tab then
        backpackModal.Open()
    elseif input.KeyCode == Enum.KeyCode.M or input.KeyCode == Enum.KeyCode.P then
        pauseMenuInstance.Open()
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.KeyCode == Enum.KeyCode.LeftShift or input.KeyCode == Enum.KeyCode.RightShift then
        isSprinting = false
        if activeHumanoid and not isFatigued then
            activeHumanoid.WalkSpeed = normalWalkSpeed
        end
    end
end)
