--!strict
--[[
    HUDHotbar.lua
    Bottom-center 3 QuickSlots hotbar for "Don't Let the Fire Die".
    Developed for Fluenosity Studio. Matches Image 2 AAA layout:
    - Translucent dark square slots with subtle hairline borders.
    - Selected slot features radiant amber glowing border + active underline indicator.
    - Inactive slots have subtle dim underline dashes.
]]

local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local sharedFolder = ReplicatedStorage:WaitForChild("FluenosityShared")
local InventoryConfig = require(sharedFolder:WaitForChild("InventoryConfig"))
local IconPack = require(sharedFolder:WaitForChild("IconPack"))
local AudioManager = require(script.Parent.Parent:WaitForChild("AudioManager"))
local UI = require(script.Parent.Parent:WaitForChild("UI"))

export type HotbarSlotData = {
    Id: string,
    Count: number,
}

export type HUDHotbarInstance = {
    Container: Frame,
    SetSlot: (slotIdx: number, item: HotbarSlotData?) -> (),
    SelectSlot: (slotIdx: number) -> (),
    GetSelectedSlot: () -> number,
    OnSlotSelected: (callback: (slot: number) -> ()) -> (),
    Destroy: () -> (),
}

local HUDHotbar = {}

function HUDHotbar.Create(parent: Instance): HUDHotbarInstance
    local container = Instance.new("Frame")
    container.Name = "HUDHotbar"
    container.Size = UDim2.fromOffset(230, 80)
    container.Position = UDim2.new(0.5, 0, 1, -26)
    container.AnchorPoint = Vector2.new(0.5, 1)
    container.BackgroundTransparency = 1
    container.ZIndex = 50
    container.Parent = parent

    local layout = Instance.new("UIListLayout")
    layout.FillDirection = Enum.FillDirection.Horizontal
    layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    layout.VerticalAlignment = Enum.VerticalAlignment.Top
    layout.Padding = UDim.new(0, 12)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Parent = container

    local slots: {
        [number]: {
            Frame: TextButton,
            Stroke: UIStroke,
            Icon: ImageLabel,
            Count: TextLabel,
            KeyBadge: TextLabel,
            SelectionGlow: Frame,
            Underline: Frame,
        }
    } = {}

    local selectedSlot = 1
    local slotSelectedCallback: ((slot: number) -> ())? = nil

    local function updateSlotVisuals(slotIdx: number)
        local slotData = slots[slotIdx]
        if not slotData then return end

        local isSelected = (slotIdx == selectedSlot)
        if isSelected then
            TweenService:Create(slotData.Frame, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                BackgroundTransparency = 0.28,
            }):Play()
            TweenService:Create(slotData.Stroke, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                Color = Color3.fromRGB(245, 160, 40), -- Radiant Ember Gold
                Thickness = 2,
                Transparency = 0.05,
            }):Play()
            TweenService:Create(slotData.Underline, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                Size = UDim2.fromOffset(36, 3),
                BackgroundColor3 = Color3.fromRGB(245, 160, 40),
                BackgroundTransparency = 0,
            }):Play()
            slotData.SelectionGlow.Visible = true
            TweenService:Create(slotData.SelectionGlow, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                BackgroundTransparency = 0.88,
            }):Play()
            slotData.KeyBadge.TextColor3 = Color3.fromRGB(255, 205, 100)
        else
            TweenService:Create(slotData.Frame, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                BackgroundTransparency = 0.45,
            }):Play()
            TweenService:Create(slotData.Stroke, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                Color = Color3.fromRGB(255, 255, 255),
                Thickness = 1,
                Transparency = 0.88,
            }):Play()
            TweenService:Create(slotData.Underline, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                Size = UDim2.fromOffset(24, 2),
                BackgroundColor3 = Color3.fromRGB(75, 80, 92),
                BackgroundTransparency = 0.65,
            }):Play()
            slotData.SelectionGlow.Visible = false
            slotData.KeyBadge.TextColor3 = Color3.fromRGB(165, 170, 180)
        end
    end

    for i = 1, InventoryConfig.MAX_HOTBAR_SLOTS do
        local slotBtn = Instance.new("TextButton")
        slotBtn.Name = "Slot_" .. i
        slotBtn.Size = UDim2.fromOffset(64, 64)
        slotBtn.BackgroundColor3 = Color3.fromRGB(16, 17, 22)
        slotBtn.BackgroundTransparency = 0.45
        slotBtn.BorderSizePixel = 0
        slotBtn.AutoButtonColor = false
        slotBtn.Text = ""
        slotBtn.LayoutOrder = i
        slotBtn.ZIndex = 51
        slotBtn.Parent = container

        local slotCorner = Instance.new("UICorner")
        slotCorner.CornerRadius = UDim.new(0, 8)
        slotCorner.Parent = slotBtn

        local slotStroke = Instance.new("UIStroke")
        slotStroke.Color = Color3.fromRGB(255, 255, 255)
        slotStroke.Transparency = 0.88
        slotStroke.Thickness = 1
        slotStroke.Parent = slotBtn

        -- Inner warm selection glow
        local selGlow = Instance.new("Frame")
        selGlow.Name = "Glow"
        selGlow.Size = UDim2.fromScale(1, 1)
        selGlow.BackgroundColor3 = Color3.fromRGB(245, 160, 40)
        selGlow.BackgroundTransparency = 1
        selGlow.BorderSizePixel = 0
        selGlow.Visible = false
        selGlow.ZIndex = 52
        selGlow.Parent = slotBtn

        local glowCorner = Instance.new("UICorner")
        glowCorner.CornerRadius = UDim.new(0, 8)
        glowCorner.Parent = selGlow

        -- Keybind number indicator (top-left)
        local keyBadge = Instance.new("TextLabel")
        keyBadge.Name = "KeyBadge"
        keyBadge.Size = UDim2.fromOffset(16, 16)
        keyBadge.Position = UDim2.fromOffset(6, 4)
        keyBadge.BackgroundTransparency = 1
        keyBadge.Font = Enum.Font.GothamBold
        keyBadge.Text = tostring(i)
        keyBadge.TextColor3 = Color3.fromRGB(165, 170, 180)
        keyBadge.TextSize = 11
        keyBadge.TextXAlignment = Enum.TextXAlignment.Left
        keyBadge.ZIndex = 53
        keyBadge.Parent = slotBtn

        -- Item icon in center (vector ImageLabel)
        local icon = Instance.new("ImageLabel")
        icon.Name = "Icon"
        icon.Size = UDim2.fromOffset(36, 36)
        icon.Position = UDim2.fromScale(0.5, 0.5)
        icon.AnchorPoint = Vector2.new(0.5, 0.5)
        icon.BackgroundTransparency = 1
        icon.ScaleType = Enum.ScaleType.Fit
        icon.Visible = false
        icon.ZIndex = 53
        icon.Parent = slotBtn

        -- Stack count badge in bottom-right
        local countLabel = Instance.new("TextLabel")
        countLabel.Name = "Count"
        countLabel.Size = UDim2.fromOffset(28, 14)
        countLabel.Position = UDim2.new(1, -6, 1, -5)
        countLabel.AnchorPoint = Vector2.new(1, 1)
        countLabel.BackgroundTransparency = 1
        countLabel.Font = Enum.Font.GothamBold
        countLabel.Text = ""
        countLabel.TextColor3 = Color3.fromRGB(225, 230, 240)
        countLabel.TextSize = 11
        countLabel.TextXAlignment = Enum.TextXAlignment.Right
        countLabel.ZIndex = 53
        countLabel.Parent = slotBtn

        -- Active/Inactive indicator underline beneath slot (Image 2 style)
        local underline = Instance.new("Frame")
        underline.Name = "Underline"
        underline.Size = UDim2.fromOffset(24, 2)
        underline.Position = UDim2.new(0.5, 0, 1, 6)
        underline.AnchorPoint = Vector2.new(0.5, 0)
        underline.BackgroundColor3 = Color3.fromRGB(75, 80, 92)
        underline.BackgroundTransparency = 0.65
        underline.BorderSizePixel = 0
        underline.ZIndex = 52
        underline.Parent = slotBtn

        local underlineCorner = Instance.new("UICorner")
        underlineCorner.CornerRadius = UDim.new(1, 0)
        underlineCorner.Parent = underline

        local slotScale = Instance.new("UIScale")
        slotScale.Scale = 1.0
        slotScale.Parent = slotBtn

        slots[i] = {
            Frame = slotBtn,
            Stroke = slotStroke,
            Icon = icon,
            Count = countLabel,
            KeyBadge = keyBadge,
            SelectionGlow = selGlow,
            Underline = underline,
        }

        slotBtn.Activated:Connect(function()
            AudioManager.Play("ItemEquip")
            TweenService:Create(slotScale, TweenInfo.new(0.06, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Scale = 0.94 }):Play()
            task.delay(0.08, function()
                TweenService:Create(slotScale, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Scale = 1.0 }):Play()
            end)
            selectedSlot = i
            for s = 1, InventoryConfig.MAX_HOTBAR_SLOTS do
                updateSlotVisuals(s)
            end
            if slotSelectedCallback then
                slotSelectedCallback(i)
            end
        end)
    end

    -- Initial visual state
    for s = 1, InventoryConfig.MAX_HOTBAR_SLOTS do
        updateSlotVisuals(s)
    end

    local function setSlot(slotIdx: number, item: HotbarSlotData?)
        local s = slots[slotIdx]
        if not s then return end

        if item and item.Id and item.Count and item.Count > 0 then
            local def = InventoryConfig.Items[item.Id]
            s.Icon.Visible = true
            if def then
                IconPack.ApplyTo(s.Icon, def.IconName, def.AccentColor, 0, 48)
                UI.Tooltip.Attach(s.Frame, {
                    Title = def.Name,
                    Category = def.Category or "ITEM",
                    Description = def.Description or "Equip to use.",
                    ActionHint = "Slot [" .. tostring(slotIdx) .. "] · Press key to equip",
                    Width = 220,
                })
            else
                IconPack.ApplyTo(s.Icon, "package", Color3.fromRGB(240, 245, 255), 0, 48)
                UI.Tooltip.Attach(s.Frame, {
                    Title = item.Id,
                    Category = "ITEM",
                    Description = "Equip to use.",
                    ActionHint = "Slot [" .. tostring(slotIdx) .. "] · Press key to equip",
                    Width = 220,
                })
            end
            s.Count.Text = (item.Count > 1) and ("x" .. tostring(item.Count)) or ""
        else
            s.Icon.Visible = false
            s.Count.Text = ""
            UI.Tooltip.Detach(s.Frame)
        end
    end

    local function selectSlot(slotIdx: number)
        if slotIdx < 1 or slotIdx > InventoryConfig.MAX_HOTBAR_SLOTS then return end
        AudioManager.Play("ItemEquip")
        selectedSlot = slotIdx
        for s = 1, InventoryConfig.MAX_HOTBAR_SLOTS do
            updateSlotVisuals(s)
        end
        if slotSelectedCallback then
            slotSelectedCallback(slotIdx)
        end
    end

    return {
        Container = container,
        SetSlot = setSlot,
        SelectSlot = selectSlot,
        GetSelectedSlot = function()
            return selectedSlot
        end,
        OnSlotSelected = function(callback: (slot: number) -> ())
            slotSelectedCallback = callback
        end,
        Destroy = function()
            container:Destroy()
        end,
    }
end

return HUDHotbar
