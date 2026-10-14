--!strict
--[[
    HUDInventoryModal.lua
    AAA Glassmorphic Survival Backpack Modal for "Don't Let the Fire Die".
    Developed for Fluenosity Studio. Matches the reference mockup layout:
    - Top Header: Backpack icon + "SURVIVAL BACKPACK" | "9 / 12" counter + [X] close
    - Left Column: Full 3x4 Grid (12 Slots):
        * Slots 1-9: Unlocked inventory tiles with count badges & radiant selection glow
        * Slots 10-12: Locked progression slots with centered padlock
    - Right Column (Inspector & Big Action Buttons):
        * Item Showcase with soft radial spotlight halo
        * Title ("STONE HATCHET") in Gotham Bold
        * Subtitle ("TOOL  |  COMMON") in amber/silver
        * Description in Gotham Regular
        * Stats Bars (DAMAGE, SPEED, DURABILITY) with animated amber lines
        * Primary Action: Big glowing [ EQUIP TO HANDS ]
        * Secondary Action Row: Big clickable [ Q ] DROP ITEM  and  [ DISCARD ]
]]

local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local sharedFolder = ReplicatedStorage:WaitForChild("FluenosityShared")
local InventoryConfig = require(sharedFolder:WaitForChild("InventoryConfig"))
local IconPack = require(sharedFolder:WaitForChild("IconPack"))
local AudioManager = require(script.Parent.Parent:WaitForChild("AudioManager"))
local UI = require(script.Parent.Parent:WaitForChild("UI"))

export type InventoryItemData = {
    Id: string,
    Count: number,
}

export type HUDInventoryModalInstance = {
    Container: Frame,
    Open: () -> (),
    Close: () -> (),
    Toggle: () -> (),
    IsOpen: () -> boolean,
    UpdateInventory: (inventory: { [number]: InventoryItemData? }) -> (),
    SetOnEquip: (callback: (slot: number) -> ()) -> (),
    SetOnDrop: (callback: (slot: number) -> ()) -> (),
    SetOnDiscard: (callback: (slot: number) -> ()) -> (),
    SetOnSplit: (callback: (slot: number) -> ()) -> (),
    Destroy: () -> (),
}

local HUDInventoryModal = {}

function HUDInventoryModal.Create(parent: Instance): HUDInventoryModalInstance
    -- Fullscreen backdrop veil
    local veil = Instance.new("TextButton")
    veil.Name = "InventoryModalVeil"
    veil.Size = UDim2.fromScale(1, 1)
    veil.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    veil.BackgroundTransparency = 1
    veil.BorderSizePixel = 0
    veil.Text = ""
    veil.AutoButtonColor = false
    veil.Visible = false
    veil.ZIndex = 80
    veil.Parent = parent

    -- Center Modal Card
    local card = Instance.new("Frame")
    card.Name = "ModalCard"
    card.Size = UDim2.fromOffset(760, 490)
    card.Position = UDim2.fromScale(0.5, 0.52)
    card.AnchorPoint = Vector2.new(0.5, 0.5)
    card.BackgroundColor3 = Color3.fromRGB(16, 15, 20)
    card.BackgroundTransparency = 0.15
    card.BorderSizePixel = 0
    card.ClipsDescendants = true
    card.ZIndex = 81
    card.Parent = veil

    UI.Theme.ApplyGlass(card, {
        CornerRadius = 18,
        StrokeTransparency = 0.82,
    })

    ----------------------------------------------------------------------------
    -- 1. TOP HEADER (Icon + SURVIVAL BACKPACK | 9 / 12 + Close X)
    ----------------------------------------------------------------------------
    local headerRow = Instance.new("Frame")
    headerRow.Name = "HeaderRow"
    headerRow.Size = UDim2.new(1, -52, 0, 32)
    headerRow.Position = UDim2.fromOffset(26, 20)
    headerRow.BackgroundTransparency = 1
    headerRow.ZIndex = 83
    headerRow.Parent = card

    -- Backpack Icon (Vector)
    local iconBackpack = IconPack.CreateIcon("backpack", 20, Color3.fromRGB(245, 160, 40))
    iconBackpack.Name = "BackpackIcon"
    iconBackpack.Position = UDim2.new(0, 0, 0.5, 0)
    iconBackpack.AnchorPoint = Vector2.new(0, 0.5)
    iconBackpack.ZIndex = 84
    iconBackpack.Parent = headerRow

    -- Title: SURVIVAL BACKPACK
    local lblTitle = Instance.new("TextLabel")
    lblTitle.Name = "Title"
    lblTitle.Size = UDim2.new(0.5, 0, 1, 0)
    lblTitle.Position = UDim2.new(0, 30, 0, 0)
    lblTitle.BackgroundTransparency = 1
    lblTitle.Font = Enum.Font.GothamBold
    lblTitle.Text = "SURVIVAL BACKPACK"
    lblTitle.TextColor3 = Color3.fromRGB(248, 250, 255)
    lblTitle.TextSize = 15
    lblTitle.TextXAlignment = Enum.TextXAlignment.Left
    lblTitle.ZIndex = 84
    lblTitle.Parent = headerRow

    -- Right-side Header container (Counter + [X])
    local headerRight = Instance.new("Frame")
    headerRight.Name = "HeaderRight"
    headerRight.Size = UDim2.new(0.3, 0, 1, 0)
    headerRight.Position = UDim2.new(1, 0, 0, 0)
    headerRight.AnchorPoint = Vector2.new(1, 0)
    headerRight.BackgroundTransparency = 1
    headerRight.ZIndex = 84
    headerRight.Parent = headerRow

    local hrLayout = Instance.new("UIListLayout")
    hrLayout.FillDirection = Enum.FillDirection.Horizontal
    hrLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
    hrLayout.VerticalAlignment = Enum.VerticalAlignment.Center
    hrLayout.Padding = UDim.new(0, 16)
    hrLayout.Parent = headerRight

    -- Slot Counter: 9 / 12
    local lblSlotCount = Instance.new("TextLabel")
    lblSlotCount.Name = "SlotCount"
    lblSlotCount.Size = UDim2.fromOffset(60, 24)
    lblSlotCount.BackgroundTransparency = 1
    lblSlotCount.Font = Enum.Font.GothamMedium
    lblSlotCount.Text = "9 / 12"
    lblSlotCount.TextColor3 = Color3.fromRGB(215, 165, 85) -- Warm amber gold
    lblSlotCount.TextSize = 13
    lblSlotCount.TextXAlignment = Enum.TextXAlignment.Right
    lblSlotCount.LayoutOrder = 1
    lblSlotCount.ZIndex = 85
    lblSlotCount.Parent = headerRight

    -- Close Button with modular UI.IconButton
    local btnClose = UI.IconButton.Create({
        IconName = "x",
        IconSize = 14,
        Size = UDim2.fromOffset(28, 28),
        CornerRadius = 8,
        Tooltip = "Close (B / ESC)",
        Parent = headerRight,
    })
    btnClose.LayoutOrder = 2
    btnClose.ZIndex = 85

    ----------------------------------------------------------------------------
    -- 2. MAIN BODY (Left Grid + Divider + Right Inspector with Action Buttons)
    ----------------------------------------------------------------------------
    local body = Instance.new("Frame")
    body.Name = "Body"
    body.Size = UDim2.new(1, -52, 1, -74)
    body.Position = UDim2.fromOffset(26, 58)
    body.BackgroundTransparency = 1
    body.ZIndex = 82
    body.Parent = card

    -- -------------------------------------------------------------------------
    -- LEFT COLUMN: 3x4 GRID (12 SLOTS - Cleanly filling left area)
    -- -------------------------------------------------------------------------
    local leftColumn = Instance.new("Frame")
    leftColumn.Name = "LeftColumn"
    leftColumn.Size = UDim2.new(0, 310, 1, 0)
    leftColumn.BackgroundTransparency = 1
    leftColumn.ZIndex = 83
    leftColumn.Parent = body

    local gridContainer = Instance.new("Frame")
    gridContainer.Name = "GridContainer"
    gridContainer.Size = UDim2.fromScale(1, 1)
    gridContainer.Position = UDim2.fromOffset(0, 0)
    gridContainer.BackgroundTransparency = 1
    gridContainer.ZIndex = 83
    gridContainer.Parent = leftColumn

    local gridLayout = Instance.new("UIGridLayout")
    gridLayout.CellSize = UDim2.fromOffset(94, 88)
    gridLayout.CellPadding = UDim2.fromOffset(12, 12)
    gridLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
    gridLayout.VerticalAlignment = Enum.VerticalAlignment.Top
    gridLayout.SortOrder = Enum.SortOrder.LayoutOrder
    gridLayout.Parent = gridContainer

    local TOTAL_SLOTS = 12
    local UNLOCKED_SLOTS = InventoryConfig.UNLOCKED_SLOTS or 9

    local gridSlots: {
        [number]: {
            Button: TextButton,
            Stroke: UIStroke,
            Glow: Frame,
            Icon: ImageLabel,
            Count: TextLabel,
            IsLocked: boolean,
            ItemData: InventoryItemData?,
        }
    } = {}

    local selectedSlotIndex = 1

    -- Forward declarations
    local updateInspector: (slotIdx: number) -> ()
    local updateSlotVisuals: () -> ()

    for i = 1, TOTAL_SLOTS do
        local isLocked = (i > UNLOCKED_SLOTS)

        local slotBtn = Instance.new("TextButton")
        slotBtn.Name = "Slot_" .. i
        slotBtn.Size = UDim2.fromOffset(94, 88)
        slotBtn.BackgroundColor3 = isLocked and Color3.fromRGB(15, 14, 18) or Color3.fromRGB(24, 23, 28)
        slotBtn.BackgroundTransparency = isLocked and 0.55 or 0.35
        slotBtn.BorderSizePixel = 0
        slotBtn.AutoButtonColor = false
        slotBtn.Text = ""
        slotBtn.LayoutOrder = i
        slotBtn.ZIndex = 84
        slotBtn.Parent = gridContainer

        local sCorner = Instance.new("UICorner")
        sCorner.CornerRadius = UDim.new(0, 12)
        sCorner.Parent = slotBtn

        local sStroke = Instance.new("UIStroke")
        sStroke.Color = Color3.fromRGB(255, 255, 255)
        sStroke.Transparency = isLocked and 0.95 or 0.90
        sStroke.Thickness = 1
        sStroke.Parent = slotBtn

        -- Tactile scale handle for click micro-compression
        local slotScale = Instance.new("UIScale")
        slotScale.Scale = 1.0
        slotScale.Parent = slotBtn

        -- Warm selection halo glow (Active only for selected slot)
        local selGlow = Instance.new("Frame")
        selGlow.Name = "Glow"
        selGlow.Size = UDim2.fromScale(1, 1)
        selGlow.BackgroundColor3 = Color3.fromRGB(245, 160, 40)
        selGlow.BackgroundTransparency = 1
        selGlow.BorderSizePixel = 0
        selGlow.Visible = false
        selGlow.ZIndex = 85
        selGlow.Parent = slotBtn

        local gCorner = Instance.new("UICorner")
        gCorner.CornerRadius = UDim.new(0, 12)
        gCorner.Parent = selGlow

        -- Item Vector Icon
        local icon = Instance.new("ImageLabel")
        icon.Name = "Icon"
        icon.Size = UDim2.fromOffset(46, 46)
        icon.Position = UDim2.fromScale(0.5, 0.46)
        icon.AnchorPoint = Vector2.new(0.5, 0.5)
        icon.BackgroundTransparency = 1
        icon.ScaleType = Enum.ScaleType.Fit
        icon.Visible = isLocked
        icon.ZIndex = 86
        icon.Parent = slotBtn

        if isLocked then
            IconPack.ApplyTo(icon, "lock", Color3.fromRGB(115, 110, 125), 0.3, 48)
        end

        -- Stack count badge in bottom-right (e.g. x12, x3)
        local count = Instance.new("TextLabel")
        count.Name = "Count"
        count.Size = UDim2.fromOffset(36, 16)
        count.Position = UDim2.new(1, -7, 1, -5)
        count.AnchorPoint = Vector2.new(1, 1)
        count.BackgroundTransparency = 1
        count.Font = Enum.Font.GothamBold
        count.Text = ""
        count.TextColor3 = Color3.fromRGB(225, 230, 240)
        count.TextSize = 11
        count.TextXAlignment = Enum.TextXAlignment.Right
        count.ZIndex = 86
        count.Parent = slotBtn

        gridSlots[i] = {
            Button = slotBtn,
            Stroke = sStroke,
            Glow = selGlow,
            Icon = icon,
            Count = count,
            IsLocked = isLocked,
            ItemData = nil,
        }

        if not isLocked then
            slotBtn.Activated:Connect(function()
                AudioManager.Play("Click")
                TweenService:Create(slotScale, TweenInfo.new(0.06, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Scale = 0.94 }):Play()
                task.delay(0.08, function()
                    TweenService:Create(slotScale, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Scale = 1.0 }):Play()
                end)
                selectedSlotIndex = i
                updateSlotVisuals()
                updateInspector(i)
            end)

            slotBtn.MouseEnter:Connect(function()
                if selectedSlotIndex ~= i then
                    TweenService:Create(sStroke, TweenInfo.new(0.12), {
                        Transparency = 0.65,
                    }):Play()
                end
            end)

            slotBtn.MouseLeave:Connect(function()
                if selectedSlotIndex ~= i then
                    TweenService:Create(sStroke, TweenInfo.new(0.12), {
                        Transparency = 0.90,
                    }):Play()
                end
            end)
        end
    end

    updateSlotVisuals = function()
        for i = 1, TOTAL_SLOTS do
            local s = gridSlots[i]
            if not s or s.IsLocked then continue end

            local isSelected = (i == selectedSlotIndex)
            if isSelected then
                TweenService:Create(s.Stroke, TweenInfo.new(0.15), {
                    Color = Color3.fromRGB(245, 160, 40), -- Radiant glowing amber
                    Thickness = 2,
                    Transparency = 0.05,
                }):Play()
                s.Glow.Visible = true
                TweenService:Create(s.Glow, TweenInfo.new(0.15), {
                    BackgroundTransparency = 0.88,
                }):Play()
                TweenService:Create(s.Button, TweenInfo.new(0.15), {
                    BackgroundTransparency = 0.22,
                }):Play()
            else
                TweenService:Create(s.Stroke, TweenInfo.new(0.15), {
                    Color = Color3.fromRGB(255, 255, 255),
                    Thickness = 1,
                    Transparency = 0.90,
                }):Play()
                s.Glow.Visible = false
                TweenService:Create(s.Button, TweenInfo.new(0.15), {
                    BackgroundTransparency = 0.35,
                }):Play()
            end
        end
    end


    -- -------------------------------------------------------------------------
    -- RIGHT COLUMN: ITEM INSPECTOR & BIG CLICKABLE ACTION BUTTONS
    -- -------------------------------------------------------------------------
    local rightSection = Instance.new("Frame")
    rightSection.Name = "RightInspector"
    rightSection.Size = UDim2.new(1, -354, 1, 0)
    rightSection.Position = UDim2.fromOffset(354, 0)
    rightSection.BackgroundTransparency = 1
    rightSection.ZIndex = 83
    rightSection.Parent = body

    -- Top Showcase Area (with soft ambient radial halo)
    local showcaseBox = Instance.new("Frame")
    showcaseBox.Name = "ShowcaseBox"
    showcaseBox.Size = UDim2.new(1, 0, 0, 130)
    showcaseBox.Position = UDim2.fromOffset(0, 0)
    showcaseBox.BackgroundTransparency = 1
    showcaseBox.ZIndex = 83
    showcaseBox.Parent = rightSection

    local spotGlow = Instance.new("Frame")
    spotGlow.Name = "SpotGlow"
    spotGlow.Size = UDim2.fromOffset(120, 120)
    spotGlow.Position = UDim2.fromScale(0.5, 0.5)
    spotGlow.AnchorPoint = Vector2.new(0.5, 0.5)
    spotGlow.BackgroundColor3 = Color3.fromRGB(245, 160, 40)
    spotGlow.BackgroundTransparency = 0.88
    spotGlow.BorderSizePixel = 0
    spotGlow.ZIndex = 84
    spotGlow.Parent = showcaseBox

    local spotCorner = Instance.new("UICorner")
    spotCorner.CornerRadius = UDim.new(1, 0)
    spotCorner.Parent = spotGlow

    local bigIcon = Instance.new("ImageLabel")
    bigIcon.Name = "BigIcon"
    bigIcon.Size = UDim2.fromOffset(72, 72)
    bigIcon.Position = UDim2.fromScale(0.5, 0.5)
    bigIcon.AnchorPoint = Vector2.new(0.5, 0.5)
    bigIcon.BackgroundTransparency = 1
    bigIcon.ScaleType = Enum.ScaleType.Fit
    bigIcon.Rotation = -8 -- Subtle modern tilt
    bigIcon.ZIndex = 85
    bigIcon.Parent = showcaseBox

    -- Item Title
    local lblItemTitle = Instance.new("TextLabel")
    lblItemTitle.Name = "ItemTitle"
    lblItemTitle.Size = UDim2.new(1, 0, 0, 22)
    lblItemTitle.Position = UDim2.fromOffset(0, 134)
    lblItemTitle.BackgroundTransparency = 1
    lblItemTitle.Font = Enum.Font.GothamBold
    lblItemTitle.Text = "STONE HATCHET"
    lblItemTitle.TextColor3 = Color3.fromRGB(248, 250, 255)
    lblItemTitle.TextSize = 16
    lblItemTitle.TextXAlignment = Enum.TextXAlignment.Left
    lblItemTitle.ZIndex = 84
    lblItemTitle.Parent = rightSection

    -- Subtitle: TOOL  |  COMMON (Amber Category | Silver Rarity)
    local lblSubRow = Instance.new("TextLabel")
    lblSubRow.Name = "SubRow"
    lblSubRow.Size = UDim2.new(1, 0, 0, 16)
    lblSubRow.Position = UDim2.fromOffset(0, 158)
    lblSubRow.BackgroundTransparency = 1
    lblSubRow.Font = Enum.Font.GothamMedium
    lblSubRow.Text = "TOOL  |  COMMON"
    lblSubRow.TextColor3 = Color3.fromRGB(245, 150, 40) -- Amber category
    lblSubRow.TextSize = 11
    lblSubRow.TextXAlignment = Enum.TextXAlignment.Left
    lblSubRow.ZIndex = 84
    lblSubRow.Parent = rightSection

    -- Description (Gotham Regular)
    local lblDesc = Instance.new("TextLabel")
    lblDesc.Name = "Description"
    lblDesc.Size = UDim2.new(1, 0, 0, 40)
    lblDesc.Position = UDim2.fromOffset(0, 178)
    lblDesc.BackgroundTransparency = 1
    lblDesc.Font = Enum.Font.Gotham
    lblDesc.Text = "A hand-crafted stone axe. Chop trees to gather wood before nightfall."
    lblDesc.TextColor3 = Color3.fromRGB(150, 155, 165)
    lblDesc.TextSize = 11
    lblDesc.TextWrapped = true
    lblDesc.TextXAlignment = Enum.TextXAlignment.Left
    lblDesc.TextYAlignment = Enum.TextYAlignment.Top
    lblDesc.ZIndex = 83
    lblDesc.Parent = rightSection

    -- -------------------------------------------------------------------------
    -- STATS SECTION (DAMAGE, SPEED, DURABILITY with Animated Amber Bars)
    -- -------------------------------------------------------------------------
    local statsContainer = Instance.new("Frame")
    statsContainer.Name = "StatsContainer"
    statsContainer.Size = UDim2.new(1, 0, 0, 64)
    statsContainer.Position = UDim2.fromOffset(0, 222)
    statsContainer.BackgroundTransparency = 1
    statsContainer.ZIndex = 83
    statsContainer.Parent = rightSection

    local statsLayout = Instance.new("UIListLayout")
    statsLayout.FillDirection = Enum.FillDirection.Vertical
    statsLayout.Padding = UDim.new(0, 6)
    statsLayout.Parent = statsContainer

    local function createStatRow(labelName: string, defaultRatio: number)
        local row = Instance.new("Frame")
        row.Name = "Stat_" .. labelName
        row.Size = UDim2.new(1, 0, 0, 16)
        row.BackgroundTransparency = 1
        row.ZIndex = 84
        row.Parent = statsContainer

        local lbl = Instance.new("TextLabel")
        lbl.Name = "Label"
        lbl.Size = UDim2.fromOffset(90, 16)
        lbl.BackgroundTransparency = 1
        lbl.Font = Enum.Font.Gotham
        lbl.Text = labelName
        lbl.TextColor3 = Color3.fromRGB(125, 128, 138)
        lbl.TextSize = 10
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.ZIndex = 85
        lbl.Parent = row

        local track = Instance.new("Frame")
        track.Name = "Track"
        track.Size = UDim2.new(1, -95, 0, 3)
        track.Position = UDim2.new(0, 95, 0.5, 0)
        track.AnchorPoint = Vector2.new(0, 0.5)
        track.BackgroundColor3 = Color3.fromRGB(42, 40, 48)
        track.BackgroundTransparency = 0.4
        track.BorderSizePixel = 0
        track.ZIndex = 85
        track.Parent = row

        local tCorner = Instance.new("UICorner")
        tCorner.CornerRadius = UDim.new(1, 0)
        tCorner.Parent = track

        local fill = Instance.new("Frame")
        fill.Name = "Fill"
        fill.Size = UDim2.fromScale(defaultRatio, 1)
        fill.BackgroundColor3 = Color3.fromRGB(245, 160, 40) -- Radiant amber fill
        fill.BorderSizePixel = 0
        fill.ZIndex = 86
        fill.Parent = track

        local fCorner = Instance.new("UICorner")
        fCorner.CornerRadius = UDim.new(1, 0)
        fCorner.Parent = fill

        return {
            Row = row,
            Fill = fill,
            SetRatio = function(ratio: number)
                TweenService:Create(fill, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                    Size = UDim2.fromScale(math.clamp(ratio, 0, 1), 1),
                }):Play()
            end,
        }
    end

    local statDamage = createStatRow("DAMAGE", 0.65)
    local statSpeed = createStatRow("SPEED", 0.35)
    local statDurability = createStatRow("DURABILITY", 0.78)

    -- -------------------------------------------------------------------------
    -- BIG ACTION BUTTONS ON THE RIGHT (Under Inspector)
    -- 1. [ EQUIP TO HANDS ]  (Big Primary Amber Button)
    -- 2. Row: [ Q ] DROP ITEM  and  [ DISCARD ]  (Big Clickable Buttons)
    -- -------------------------------------------------------------------------
    local actionArea = Instance.new("Frame")
    actionArea.Name = "ActionArea"
    actionArea.Size = UDim2.new(1, 0, 0, 84)
    actionArea.Position = UDim2.new(0, 0, 1, -86)
    actionArea.BackgroundTransparency = 1
    actionArea.ZIndex = 84
    actionArea.Parent = rightSection

    -- PRIMARY: [ EQUIP TO HANDS ]
    local btnEquip = Instance.new("TextButton")
    btnEquip.Name = "EquipToHandsButton"
    btnEquip.Size = UDim2.new(1, 0, 0, 40)
    btnEquip.Position = UDim2.fromOffset(0, 0)
    btnEquip.BackgroundColor3 = Color3.fromRGB(225, 140, 30)
    btnEquip.BorderSizePixel = 0
    btnEquip.AutoButtonColor = false
    btnEquip.Text = ""
    btnEquip.ZIndex = 85
    btnEquip.Parent = actionArea

    local eqScale = Instance.new("UIScale")
    eqScale.Scale = 1.0
    eqScale.Parent = btnEquip

    local eqCorner = Instance.new("UICorner")
    eqCorner.CornerRadius = UDim.new(0, 10)
    eqCorner.Parent = btnEquip

    local eqGrad = Instance.new("UIGradient")
    eqGrad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(195, 105, 20)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(245, 165, 40)),
    })
    eqGrad.Parent = btnEquip

    local eqStroke = Instance.new("UIStroke")
    eqStroke.Color = Color3.fromRGB(255, 200, 80)
    eqStroke.Transparency = 0.25
    eqStroke.Thickness = 1
    eqStroke.Parent = btnEquip

    local btnIcon = IconPack.CreateIcon("mouse-pointer", 16, Color3.fromRGB(255, 255, 255))
    btnIcon.Name = "ActionIcon"
    btnIcon.Position = UDim2.new(0, 14, 0.5, 0)
    btnIcon.AnchorPoint = Vector2.new(0, 0.5)
    btnIcon.ZIndex = 86
    btnIcon.Parent = btnEquip

    local btnText = Instance.new("TextLabel")
    btnText.Name = "ActionText"
    btnText.Size = UDim2.new(1, -60, 1, 0)
    btnText.Position = UDim2.fromOffset(36, 0)
    btnText.BackgroundTransparency = 1
    btnText.Font = Enum.Font.GothamBold
    btnText.Text = "EQUIP TO HANDS"
    btnText.TextColor3 = Color3.fromRGB(255, 248, 235)
    btnText.TextSize = 12
    btnText.TextXAlignment = Enum.TextXAlignment.Center
    btnText.ZIndex = 86
    btnText.Parent = btnEquip

    local btnChevron = IconPack.CreateIcon("chevron-right", 16, Color3.fromRGB(255, 225, 140))
    btnChevron.Name = "Chevron"
    btnChevron.Position = UDim2.new(1, -16, 0.5, 0)
    btnChevron.AnchorPoint = Vector2.new(1, 0.5)
    btnChevron.ZIndex = 86
    btnChevron.Parent = btnEquip

    btnEquip.MouseEnter:Connect(function()
        TweenService:Create(eqStroke, TweenInfo.new(0.15), { Transparency = 0.05 }):Play()
        TweenService:Create(btnEquip, TweenInfo.new(0.15), { BackgroundColor3 = Color3.fromRGB(245, 160, 40) }):Play()
    end)
    btnEquip.MouseLeave:Connect(function()
        TweenService:Create(eqStroke, TweenInfo.new(0.15), { Transparency = 0.25 }):Play()
        TweenService:Create(btnEquip, TweenInfo.new(0.15), { BackgroundColor3 = Color3.fromRGB(225, 140, 30) }):Play()
    end)

    -- SECONDARY ROW: [ Q ] DROP ITEM  |  [ ½ ] SPLIT  |  [ DISCARD ]
    local secondaryRow = Instance.new("Frame")
    secondaryRow.Name = "SecondaryRow"
    secondaryRow.Size = UDim2.new(1, 0, 0, 36)
    secondaryRow.Position = UDim2.fromOffset(0, 46)
    secondaryRow.BackgroundTransparency = 1
    secondaryRow.ZIndex = 85
    secondaryRow.Parent = actionArea

    -- 1. [ Q ] DROP BUTTON (Big Clickable Action Button)
    local btnDrop = Instance.new("TextButton")
    btnDrop.Name = "DropButton"
    btnDrop.Size = UDim2.new(0.58, -4, 1, 0)
    btnDrop.Position = UDim2.fromOffset(0, 0)
    btnDrop.BackgroundColor3 = Color3.fromRGB(24, 23, 28)
    btnDrop.BackgroundTransparency = 0.25
    btnDrop.BorderSizePixel = 0
    btnDrop.AutoButtonColor = false
    btnDrop.Text = ""
    btnDrop.ZIndex = 86
    btnDrop.Parent = secondaryRow

    local drScale = Instance.new("UIScale")
    drScale.Scale = 1.0
    drScale.Parent = btnDrop

    local drCorner = Instance.new("UICorner")
    drCorner.CornerRadius = UDim.new(0, 8)
    drCorner.Parent = btnDrop

    local drStroke = Instance.new("UIStroke")
    drStroke.Color = Color3.fromRGB(255, 255, 255)
    drStroke.Transparency = 0.82
    drStroke.Thickness = 1
    drStroke.Parent = btnDrop

    -- Keycap badge [ Q ]
    local keyCapQ = Instance.new("Frame")
    keyCapQ.Name = "KeyCapQ"
    keyCapQ.Size = UDim2.fromOffset(22, 20)
    keyCapQ.Position = UDim2.new(0, 8, 0.5, 0)
    keyCapQ.AnchorPoint = Vector2.new(0, 0.5)
    keyCapQ.BackgroundColor3 = Color3.fromRGB(36, 34, 42)
    keyCapQ.BackgroundTransparency = 0.2
    keyCapQ.BorderSizePixel = 0
    keyCapQ.ZIndex = 87
    keyCapQ.Parent = btnDrop

    local qCorner = Instance.new("UICorner")
    qCorner.CornerRadius = UDim.new(0, 4)
    qCorner.Parent = keyCapQ

    local qStroke = Instance.new("UIStroke")
    qStroke.Color = Color3.fromRGB(245, 160, 40)
    qStroke.Transparency = 0.25
    qStroke.Thickness = 1
    qStroke.Parent = keyCapQ

    local qLabel = Instance.new("TextLabel")
    qLabel.Size = UDim2.fromScale(1, 1)
    qLabel.BackgroundTransparency = 1
    qLabel.Font = Enum.Font.GothamBold
    qLabel.Text = "Q"
    qLabel.TextColor3 = Color3.fromRGB(255, 205, 100)
    qLabel.TextSize = 11
    qLabel.ZIndex = 88
    qLabel.Parent = keyCapQ

    local drLabel = Instance.new("TextLabel")
    drLabel.Name = "DropText"
    drLabel.Size = UDim2.new(1, -34, 1, 0)
    drLabel.Position = UDim2.fromOffset(34, 0)
    drLabel.BackgroundTransparency = 1
    drLabel.Font = Enum.Font.GothamBold
    drLabel.Text = "DROP ITEM"
    drLabel.TextColor3 = Color3.fromRGB(230, 235, 245)
    drLabel.TextSize = 11
    drLabel.TextXAlignment = Enum.TextXAlignment.Left
    drLabel.ZIndex = 87
    drLabel.Parent = btnDrop

    btnDrop.MouseEnter:Connect(function()
        TweenService:Create(drStroke, TweenInfo.new(0.15), {
            Color = Color3.fromRGB(245, 160, 40),
            Transparency = 0.2,
        }):Play()
        TweenService:Create(btnDrop, TweenInfo.new(0.15), {
            BackgroundColor3 = Color3.fromRGB(32, 30, 38),
        }):Play()
    end)
    btnDrop.MouseLeave:Connect(function()
        TweenService:Create(drStroke, TweenInfo.new(0.15), {
            Color = Color3.fromRGB(255, 255, 255),
            Transparency = 0.82,
        }):Play()
        TweenService:Create(btnDrop, TweenInfo.new(0.15), {
            BackgroundColor3 = Color3.fromRGB(24, 23, 28),
        }):Play()
    end)

    -- 2. [ ½ ] SPLIT BUTTON (Active for stacked items > 1)
    local btnSplit = Instance.new("TextButton")
    btnSplit.Name = "SplitButton"
    btnSplit.Size = UDim2.new(0.32, -4, 1, 0)
    btnSplit.Position = UDim2.new(0.36, 4, 0, 0)
    btnSplit.BackgroundColor3 = Color3.fromRGB(24, 25, 32)
    btnSplit.BackgroundTransparency = 0.25
    btnSplit.BorderSizePixel = 0
    btnSplit.AutoButtonColor = false
    btnSplit.Text = ""
    btnSplit.Visible = false
    btnSplit.ZIndex = 86
    btnSplit.Parent = secondaryRow

    local spScale = Instance.new("UIScale")
    spScale.Scale = 1.0
    spScale.Parent = btnSplit

    local spCorner = Instance.new("UICorner")
    spCorner.CornerRadius = UDim.new(0, 8)
    spCorner.Parent = btnSplit

    local spStroke = Instance.new("UIStroke")
    spStroke.Color = Color3.fromRGB(255, 255, 255)
    spStroke.Transparency = 0.82
    spStroke.Thickness = 1
    spStroke.Parent = btnSplit

    local spIcon = IconPack.CreateIcon("split", 14, Color3.fromRGB(130, 200, 245))
    spIcon.Name = "SplitIcon"
    spIcon.Position = UDim2.new(0, 8, 0.5, 0)
    spIcon.AnchorPoint = Vector2.new(0, 0.5)
    spIcon.ZIndex = 87
    spIcon.Parent = btnSplit

    local spLabel = Instance.new("TextLabel")
    spLabel.Size = UDim2.new(1, -28, 1, 0)
    spLabel.Position = UDim2.fromOffset(26, 0)
    spLabel.BackgroundTransparency = 1
    spLabel.Font = Enum.Font.GothamBold
    spLabel.Text = "SPLIT"
    spLabel.TextColor3 = Color3.fromRGB(220, 230, 245)
    spLabel.TextSize = 11
    spLabel.TextXAlignment = Enum.TextXAlignment.Left
    spLabel.ZIndex = 87
    spLabel.Parent = btnSplit

    btnSplit.MouseEnter:Connect(function()
        TweenService:Create(spStroke, TweenInfo.new(0.15), {
            Color = Color3.fromRGB(120, 190, 255),
            Transparency = 0.25,
        }):Play()
        TweenService:Create(btnSplit, TweenInfo.new(0.15), {
            BackgroundColor3 = Color3.fromRGB(28, 32, 44),
        }):Play()
    end)
    btnSplit.MouseLeave:Connect(function()
        TweenService:Create(spStroke, TweenInfo.new(0.15), {
            Color = Color3.fromRGB(255, 255, 255),
            Transparency = 0.82,
        }):Play()
        TweenService:Create(btnSplit, TweenInfo.new(0.15), {
            BackgroundColor3 = Color3.fromRGB(24, 25, 32),
        }):Play()
    end)

    -- 3. DISCARD BUTTON
    local btnDiscard = Instance.new("TextButton")
    btnDiscard.Name = "DiscardButton"
    btnDiscard.Size = UDim2.new(0.42, -4, 1, 0)
    btnDiscard.Position = UDim2.new(0.58, 4, 0, 0)
    btnDiscard.BackgroundColor3 = Color3.fromRGB(26, 22, 24)
    btnDiscard.BackgroundTransparency = 0.35
    btnDiscard.BorderSizePixel = 0
    btnDiscard.AutoButtonColor = false
    btnDiscard.Text = ""
    btnDiscard.ZIndex = 86
    btnDiscard.Parent = secondaryRow

    local discScale = Instance.new("UIScale")
    discScale.Scale = 1.0
    discScale.Parent = btnDiscard

    local discCorner = Instance.new("UICorner")
    discCorner.CornerRadius = UDim.new(0, 8)
    discCorner.Parent = btnDiscard

    local discStroke = Instance.new("UIStroke")
    discStroke.Color = Color3.fromRGB(255, 80, 80)
    discStroke.Transparency = 0.85
    discStroke.Thickness = 1
    discStroke.Parent = btnDiscard

    local discIcon = IconPack.CreateIcon("trash-2", 14, Color3.fromRGB(240, 120, 120))
    discIcon.Name = "DiscardIcon"
    discIcon.Position = UDim2.new(0, 8, 0.5, 0)
    discIcon.AnchorPoint = Vector2.new(0, 0.5)
    discIcon.ZIndex = 87
    discIcon.Parent = btnDiscard

    local discLabel = Instance.new("TextLabel")
    discLabel.Size = UDim2.new(1, -30, 1, 0)
    discLabel.Position = UDim2.fromOffset(28, 0)
    discLabel.BackgroundTransparency = 1
    discLabel.Font = Enum.Font.GothamBold
    discLabel.Text = "DISCARD"
    discLabel.TextColor3 = Color3.fromRGB(215, 205, 210)
    discLabel.TextSize = 11
    discLabel.TextXAlignment = Enum.TextXAlignment.Left
    discLabel.ZIndex = 87
    discLabel.Parent = btnDiscard

    btnDiscard.MouseEnter:Connect(function()
        TweenService:Create(discStroke, TweenInfo.new(0.15), {
            Transparency = 0.25,
            Color = Color3.fromRGB(255, 70, 70),
        }):Play()
        TweenService:Create(btnDiscard, TweenInfo.new(0.15), {
            BackgroundColor3 = Color3.fromRGB(36, 24, 28),
        }):Play()
    end)
    btnDiscard.MouseLeave:Connect(function()
        TweenService:Create(discStroke, TweenInfo.new(0.15), {
            Transparency = 0.85,
            Color = Color3.fromRGB(255, 80, 80),
        }):Play()
        TweenService:Create(btnDiscard, TweenInfo.new(0.15), {
            BackgroundColor3 = Color3.fromRGB(26, 22, 24),
        }):Play()
    end)

    ----------------------------------------------------------------------------
    -- INSPECTOR UPDATE LOGIC
    ----------------------------------------------------------------------------
    updateInspector = function(slotIdx: number)
        local slotData = gridSlots[slotIdx]
        local item = slotData and slotData.ItemData

        if item and item.Id and item.Count and item.Count > 0 then
            local def = InventoryConfig.Items[item.Id]
            if def then
                lblItemTitle.Text = string.upper(def.Name)
                bigIcon.Visible = true
                IconPack.ApplyTo(bigIcon, def.IconName, def.AccentColor, 0, 256)
                spotGlow.BackgroundColor3 = def.AccentColor
                spotGlow.BackgroundTransparency = 0.86
                local rarity = def.Rarity or "COMMON"
                lblSubRow.Text = string.upper(def.Category) .. "  |  " .. rarity
                lblDesc.Text = def.Description .. (def.IsProtected and "\n\nBOUND LOADOUT ITEM" or "")

                if def.Stats then
                    statsContainer.Visible = true
                    statDamage.SetRatio(def.Stats.Damage or 0.5)
                    statSpeed.SetRatio(def.Stats.Speed or 0.5)
                    statDurability.SetRatio(def.Stats.Durability or 0.5)
                else
                    statsContainer.Visible = false
                end

                -- Dynamic primary action button text & vector icon
                if def.Category == "Medical" then
                    btnText.Text = "USE / HEAL"
                    IconPack.ApplyTo(btnIcon, "heart-pulse", Color3.fromRGB(255, 255, 255), 0, 48)
                    btnEquip.Visible = true
                elseif def.Category == "Consumable" then
                    btnText.Text = "USE / CONSUME"
                    IconPack.ApplyTo(btnIcon, "utensils", Color3.fromRGB(255, 255, 255), 0, 48)
                    btnEquip.Visible = true
                elseif def.IsEquippable then
                    btnText.Text = "EQUIP TO HANDS"
                    IconPack.ApplyTo(btnIcon, "mouse-pointer", Color3.fromRGB(255, 255, 255), 0, 48)
                    btnEquip.Visible = true
                else
                    btnText.Text = "MOVE TO HOTBAR"
                    IconPack.ApplyTo(btnIcon, "backpack", Color3.fromRGB(255, 255, 255), 0, 48)
                    btnEquip.Visible = true
                end

                -- Secondary action row layout: 3 buttons if stack > 1, 2 buttons if stack == 1
                secondaryRow.Visible = not def.IsProtected
                if def.IsProtected then
                    btnSplit.Visible = false
                    btnEquip.Visible = false
                end
                if item.Count > 1 then
                    btnSplit.Visible = true
                    btnDrop.Size = UDim2.new(0.36, -4, 1, 0)
                    btnDrop.Position = UDim2.fromOffset(0, 0)
                    drLabel.Text = "DROP"

                    btnSplit.Size = UDim2.new(0.32, -4, 1, 0)
                    btnSplit.Position = UDim2.new(0.36, 4, 0, 0)

                    btnDiscard.Size = UDim2.new(0.32, -4, 1, 0)
                    btnDiscard.Position = UDim2.new(0.68, 8, 0, 0)
                else
                    btnSplit.Visible = false
                    btnDrop.Size = UDim2.new(0.58, -4, 1, 0)
                    btnDrop.Position = UDim2.fromOffset(0, 0)
                    drLabel.Text = "DROP ITEM"

                    btnDiscard.Size = UDim2.new(0.42, -4, 1, 0)
                    btnDiscard.Position = UDim2.new(0.58, 4, 0, 0)
                end
            else
                lblItemTitle.Text = string.upper(item.Id)
                bigIcon.Visible = true
                IconPack.ApplyTo(bigIcon, "package", Color3.fromRGB(240, 245, 255), 0, 256)
                spotGlow.BackgroundColor3 = Color3.fromRGB(180, 190, 205)
                lblSubRow.Text = "ITEM  |  COMMON"
                lblDesc.Text = "A survival item stored in the backpack."
                statsContainer.Visible = false
                btnText.Text = "EQUIP TO HANDS"
                IconPack.ApplyTo(btnIcon, "mouse-pointer", Color3.fromRGB(255, 255, 255), 0, 48)
                btnEquip.Visible = true

                secondaryRow.Visible = true
                btnSplit.Visible = false
                btnDrop.Size = UDim2.new(0.58, -4, 1, 0)
                btnDrop.Position = UDim2.fromOffset(0, 0)
                drLabel.Text = "DROP ITEM"

                btnDiscard.Size = UDim2.new(0.42, -4, 1, 0)
                btnDiscard.Position = UDim2.new(0.58, 4, 0, 0)
            end
        else
            lblItemTitle.Text = "EMPTY SLOT"
            bigIcon.Visible = false
            spotGlow.BackgroundColor3 = Color3.fromRGB(245, 160, 40)
            lblSubRow.Text = "NONE"
            lblDesc.Text = "This slot is empty. Scavenge firewood, tools, and supplies throughout the forest."
            statsContainer.Visible = false
            btnEquip.Visible = false
            secondaryRow.Visible = false
        end
    end

    ----------------------------------------------------------------------------
    -- INVENTORY REFRESH & BINDINGS
    ----------------------------------------------------------------------------
    local function updateInventory(inventory: { [number]: InventoryItemData? })
        local filledSlots = 0
        for i = 1, TOTAL_SLOTS do
            local item = inventory[i]
            local s = gridSlots[i]
            if not s then continue end

            s.ItemData = item
            if item and item.Id and item.Count and item.Count > 0 then
                filledSlots = filledSlots + 1
                local def = InventoryConfig.Items[item.Id]
                s.Icon.Visible = true
                if def then
                    IconPack.ApplyTo(s.Icon, def.IconName, def.AccentColor, 0, 48)
                else
                    IconPack.ApplyTo(s.Icon, "package", Color3.fromRGB(240, 245, 255), 0, 48)
                end
                s.Count.Text = (item.Count > 1) and ("x" .. tostring(item.Count)) or ""
            else
                if not s.IsLocked then
                    s.Icon.Visible = false
                    s.Count.Text = ""
                end
            end
        end

        lblSlotCount.Text = string.format("%d / %d", filledSlots, TOTAL_SLOTS)
        updateSlotVisuals()
        updateInspector(selectedSlotIndex)
    end

    -- Initial load from InventoryConfig.StartingLoadout
    local initialLoadout: { [number]: InventoryItemData? } = {}
    for i = 1, TOTAL_SLOTS do
        local starting = InventoryConfig.StartingLoadout[i]
        if starting then
            initialLoadout[i] = { Id = starting.Id, Count = starting.Count }
        else
            initialLoadout[i] = nil
        end
    end
    updateInventory(initialLoadout)

    local onEquipCallback: ((slot: number) -> ())? = nil
    local onDropCallback: ((slot: number) -> ())? = nil
    local onDiscardCallback: ((slot: number) -> ())? = nil
    local onSplitCallback: ((slot: number) -> ())? = nil

    btnEquip.Activated:Connect(function()
        AudioManager.Play("ItemEquip")
        TweenService:Create(eqScale, TweenInfo.new(0.06, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Scale = 0.96 }):Play()
        task.delay(0.08, function()
            TweenService:Create(eqScale, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Scale = 1.0 }):Play()
        end)
        if onEquipCallback then
            onEquipCallback(selectedSlotIndex)
        end
    end)

    btnDrop.Activated:Connect(function()
        AudioManager.Play("ItemDrop")
        TweenService:Create(drScale, TweenInfo.new(0.06, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Scale = 0.96 }):Play()
        task.delay(0.08, function()
            TweenService:Create(drScale, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Scale = 1.0 }):Play()
        end)
        if onDropCallback then
            onDropCallback(selectedSlotIndex)
        end
    end)

    btnSplit.Activated:Connect(function()
        AudioManager.Play("ItemSplit")
        TweenService:Create(spScale, TweenInfo.new(0.06, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Scale = 0.96 }):Play()
        task.delay(0.08, function()
            TweenService:Create(spScale, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Scale = 1.0 }):Play()
        end)
        if onSplitCallback then
            onSplitCallback(selectedSlotIndex)
        end
    end)

    btnDiscard.Activated:Connect(function()
        AudioManager.Play("ItemDrop")
        TweenService:Create(discScale, TweenInfo.new(0.06, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Scale = 0.96 }):Play()
        task.delay(0.08, function()
            TweenService:Create(discScale, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Scale = 1.0 }):Play()
        end)
        if onDiscardCallback then
            onDiscardCallback(selectedSlotIndex)
        elseif onDropCallback then
            onDropCallback(selectedSlotIndex)
        end
    end)

    ----------------------------------------------------------------------------
    -- MODAL OPEN / CLOSE TRANSITIONS & KEYBOARD DROP SHORTCUT [Q]
    ----------------------------------------------------------------------------
    local isTransitioning = false
    local isOpen = false

    local onOpenCallback: (() -> ())? = nil
    local onCloseCallback: (() -> ())? = nil

    local function openModal()
        if isTransitioning or isOpen then return end
        isTransitioning = true
        isOpen = true

        AudioManager.Play("InventoryOpen")

        veil.Visible = true
        veil.Modal = true
        veil.BackgroundTransparency = 1
        card.Position = UDim2.fromScale(0.5, 0.52)

        if onOpenCallback then
            onOpenCallback()
        end

        TweenService:Create(veil, TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            BackgroundTransparency = 0.45,
        }):Play()

        local cardTween = TweenService:Create(card, TweenInfo.new(0.24, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
            Position = UDim2.fromScale(0.5, 0.5),
        })
        cardTween.Completed:Connect(function()
            isTransitioning = false
        end)
        cardTween:Play()

        -- Listen for Q key press while modal is open to drop selected item
        if not inputConn then
            inputConn = UserInputService.InputBegan:Connect(function(input, gpe)
                if not isOpen or isTransitioning then return end
                if input.KeyCode == Enum.KeyCode.Q then
                    if onDropCallback then
                        onDropCallback(selectedSlotIndex)
                    end
                elseif input.KeyCode == Enum.KeyCode.E then
                    if onEquipCallback then
                        onEquipCallback(selectedSlotIndex)
                    end
                end
            end)
        end
    end

    local function closeModal()
        if isTransitioning or not isOpen then return end
        isTransitioning = true
        isOpen = false
        veil.Modal = false

        AudioManager.Play("InventoryClose")

        if onCloseCallback then
            onCloseCallback()
        end

        if inputConn then
            inputConn:Disconnect()
            inputConn = nil
        end

        TweenService:Create(veil, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
            BackgroundTransparency = 1,
        }):Play()

        local cardTween = TweenService:Create(card, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
            Position = UDim2.fromScale(0.5, 0.52),
        })
        cardTween.Completed:Connect(function()
            veil.Visible = false
            veil.Modal = false
            isTransitioning = false
        end)
        cardTween:Play()
    end

    btnClose.Activated:Connect(closeModal)
    veil.Activated:Connect(closeModal)

    return {
        Container = card,
        Open = openModal,
        Close = closeModal,
        Toggle = function()
            if isOpen then
                closeModal()
            else
                openModal()
            end
        end,
        IsOpen = function()
            return isOpen
        end,
        UpdateInventory = updateInventory,
        SetOnEquip = function(cb)
            onEquipCallback = cb
        end,
        SetOnDrop = function(cb)
            onDropCallback = cb
        end,
        SetOnDiscard = function(cb)
            onDiscardCallback = cb
        end,
        SetOnSplit = function(cb)
            onSplitCallback = cb
        end,
        SetOnOpen = function(cb)
            onOpenCallback = cb
        end,
        SetOnClose = function(cb)
            onCloseCallback = cb
        end,
        Destroy = function()
            if inputConn then
                inputConn:Disconnect()
                inputConn = nil
            end
            veil:Destroy()
        end,
    }
end

return HUDInventoryModal
