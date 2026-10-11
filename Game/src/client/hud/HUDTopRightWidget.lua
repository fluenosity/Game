--!strict
--[[
    HUDTopRightWidget.lua
    Ultra-sleek glassmorphic Top-Right Global Survival Component for "Don't Let the Fire Die".
    Developed for Fluenosity Studio.
    
    Features:
    - Campfire Flame & Sanctuary Status Monitor (Reactive ember glow + safe zone badge)
    - Celestial Day & Time tracker (Sun/Moon icon + Day number + Time of day)
    - Interactive Backpack quick-toggle button [B] with icon & tooltip
    - Interactive Settings gear button [ESC] with smooth rotation hover
    - Perfectly placed below Roblox CoreGui topbar so it never gets obscured!
]]

local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local sharedFolder = ReplicatedStorage:WaitForChild("FluenosityShared")
local IconPack = require(sharedFolder:WaitForChild("IconPack"))
local AudioManager = require(script.Parent.Parent:WaitForChild("AudioManager"))

export type HUDTopRightInstance = {
    Container: Frame,
    SetCampfireLit: (isLit: boolean) -> (),
    SetTime: (hour: number, day: number, phase: string?) -> (),
    SetSanctuaryStatus: (inSanctuary: boolean) -> (),
    SetOnBackpackClick: (callback: () -> ()) -> (),
    SetOnSettingsClick: (callback: () -> ()) -> (),
    Destroy: () -> (),
}

local HUDTopRightWidget = {}

function HUDTopRightWidget.Create(parent: Instance): HUDTopRightInstance
    -- Main Root Bar anchored in the top-right corner
    local root = Instance.new("Frame")
    root.Name = "HUDTopRightWidget"
    root.Size = UDim2.fromOffset(390, 36)
    root.Position = UDim2.new(1, -22, 0, 48) -- Safe offset below Roblox Topbar
    root.AnchorPoint = Vector2.new(1, 0)
    root.BackgroundColor3 = Color3.fromRGB(14, 16, 20)
    root.BackgroundTransparency = 0.28
    root.BorderSizePixel = 0
    root.ZIndex = 50
    root.Parent = parent

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 18)
    corner.Parent = root

    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(255, 255, 255)
    stroke.Transparency = 0.86
    stroke.Thickness = 1
    stroke.Parent = root

    local layout = Instance.new("UIListLayout")
    layout.FillDirection = Enum.FillDirection.Horizontal
    layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    layout.VerticalAlignment = Enum.VerticalAlignment.Center
    layout.Padding = UDim.new(0, 10)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Parent = root

    local padding = Instance.new("UIPadding")
    padding.PaddingLeft = UDim.new(0, 12)
    padding.PaddingRight = UDim.new(0, 10)
    padding.Parent = root

    -- Helper to create 1px subtle vertical dividers
    local function createDivider(order: number)
        local div = Instance.new("Frame")
        div.Name = "Divider"
        div.Size = UDim2.new(0, 1, 0, 16)
        div.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        div.BackgroundTransparency = 0.88
        div.BorderSizePixel = 0
        div.LayoutOrder = order
        div.ZIndex = 51
        div.Parent = root
        return div
    end

    ----------------------------------------------------------------------------
    -- 1. CAMPFIRE SANCTUARY STATUS PILL (Left segment)
    ----------------------------------------------------------------------------
    local campFrame = Instance.new("Frame")
    campFrame.Name = "CampfirePill"
    campFrame.Size = UDim2.fromOffset(145, 26)
    campFrame.BackgroundTransparency = 1
    campFrame.LayoutOrder = 1
    campFrame.ZIndex = 51
    campFrame.Parent = root

    local campIcon = IconPack.CreateIcon("flame", 16, Color3.fromRGB(255, 160, 40))
    campIcon.Name = "FlameIcon"
    campIcon.Position = UDim2.new(0, 0, 0.5, 0)
    campIcon.AnchorPoint = Vector2.new(0, 0.5)
    campIcon.ZIndex = 52
    campIcon.Parent = campFrame

    local campLabel = Instance.new("TextLabel")
    campLabel.Name = "FlameLabel"
    campLabel.Size = UDim2.new(1, -22, 0, 13)
    campLabel.Position = UDim2.new(0, 22, 0, 0)
    campLabel.BackgroundTransparency = 1
    campLabel.Font = Enum.Font.GothamBold
    campLabel.Text = "FIRE: BURNING"
    campLabel.TextColor3 = Color3.fromRGB(255, 175, 60)
    campLabel.TextSize = 10
    campLabel.TextXAlignment = Enum.TextXAlignment.Left
    campLabel.ZIndex = 52
    campLabel.Parent = campFrame

    local sanctuaryBadge = Instance.new("TextLabel")
    sanctuaryBadge.Name = "SanctuaryBadge"
    sanctuaryBadge.Size = UDim2.new(1, -22, 0, 11)
    sanctuaryBadge.Position = UDim2.new(0, 22, 1, -11)
    sanctuaryBadge.BackgroundTransparency = 1
    sanctuaryBadge.Font = Enum.Font.GothamMedium
    sanctuaryBadge.Text = "SANCTUARY SAFE"
    sanctuaryBadge.TextColor3 = Color3.fromRGB(140, 220, 140)
    sanctuaryBadge.TextSize = 9
    sanctuaryBadge.TextXAlignment = Enum.TextXAlignment.Left
    sanctuaryBadge.ZIndex = 52
    sanctuaryBadge.Parent = campFrame

    -- Divider 1
    createDivider(2)

    ----------------------------------------------------------------------------
    -- 2. CELESTIAL TIME TRACKER (Center segment)
    ----------------------------------------------------------------------------
    local timeFrame = Instance.new("Frame")
    timeFrame.Name = "TimePill"
    timeFrame.Size = UDim2.fromOffset(115, 26)
    timeFrame.BackgroundTransparency = 1
    timeFrame.LayoutOrder = 3
    timeFrame.ZIndex = 51
    timeFrame.Parent = root

    local timeIcon = IconPack.CreateIcon("sun", 15, Color3.fromRGB(245, 195, 60))
    timeIcon.Name = "SunIcon"
    timeIcon.Position = UDim2.new(0, 0, 0.5, 0)
    timeIcon.AnchorPoint = Vector2.new(0, 0.5)
    timeIcon.ZIndex = 52
    timeIcon.Parent = timeFrame

    local dayLabel = Instance.new("TextLabel")
    dayLabel.Name = "DayText"
    dayLabel.Size = UDim2.new(1, -20, 0, 13)
    dayLabel.Position = UDim2.new(0, 20, 0, 0)
    dayLabel.BackgroundTransparency = 1
    dayLabel.Font = Enum.Font.GothamBold
    dayLabel.Text = "DAY 1"
    dayLabel.TextColor3 = Color3.fromRGB(245, 248, 255)
    dayLabel.TextSize = 10
    dayLabel.TextXAlignment = Enum.TextXAlignment.Left
    dayLabel.ZIndex = 52
    dayLabel.Parent = timeFrame

    local clockLabel = Instance.new("TextLabel")
    clockLabel.Name = "ClockText"
    clockLabel.Size = UDim2.new(1, -20, 0, 11)
    clockLabel.Position = UDim2.new(0, 20, 1, -11)
    clockLabel.BackgroundTransparency = 1
    clockLabel.Font = Enum.Font.GothamMedium
    clockLabel.Text = "10:27 AM"
    clockLabel.TextColor3 = Color3.fromRGB(180, 185, 195)
    clockLabel.TextSize = 9
    clockLabel.TextXAlignment = Enum.TextXAlignment.Left
    clockLabel.ZIndex = 52
    clockLabel.Parent = timeFrame

    -- Divider 2
    createDivider(4)

    ----------------------------------------------------------------------------
    -- 3. QUICK BACKPACK BUTTON [ B ]
    ----------------------------------------------------------------------------
    local btnBackpack = Instance.new("TextButton")
    btnBackpack.Name = "BackpackButton"
    btnBackpack.Size = UDim2.fromOffset(38, 26)
    btnBackpack.BackgroundColor3 = Color3.fromRGB(26, 28, 34)
    btnBackpack.BackgroundTransparency = 0.4
    btnBackpack.BorderSizePixel = 0
    btnBackpack.Text = ""
    btnBackpack.AutoButtonColor = false
    btnBackpack.LayoutOrder = 5
    btnBackpack.ZIndex = 52
    btnBackpack.Parent = root

    local bpCorner = Instance.new("UICorner")
    bpCorner.CornerRadius = UDim.new(0, 6)
    bpCorner.Parent = btnBackpack

    local bpStroke = Instance.new("UIStroke")
    bpStroke.Color = Color3.fromRGB(255, 255, 255)
    bpStroke.Transparency = 0.85
    bpStroke.Thickness = 1
    bpStroke.Parent = btnBackpack

    local bpIcon = IconPack.CreateIcon("backpack", 14, Color3.fromRGB(225, 230, 240))
    bpIcon.Name = "Icon"
    bpIcon.Position = UDim2.new(0, 6, 0.5, 0)
    bpIcon.AnchorPoint = Vector2.new(0, 0.5)
    bpIcon.ZIndex = 53
    bpIcon.Parent = btnBackpack

    local bpKeyBadge = Instance.new("TextLabel")
    bpKeyBadge.Name = "KeyBadge"
    bpKeyBadge.Size = UDim2.fromOffset(12, 12)
    bpKeyBadge.Position = UDim2.new(1, -6, 0.5, 0)
    bpKeyBadge.AnchorPoint = Vector2.new(1, 0.5)
    bpKeyBadge.BackgroundTransparency = 1
    bpKeyBadge.Font = Enum.Font.GothamBold
    bpKeyBadge.Text = "B"
    bpKeyBadge.TextColor3 = Color3.fromRGB(245, 175, 60)
    bpKeyBadge.TextSize = 9
    bpKeyBadge.ZIndex = 53
    bpKeyBadge.Parent = btnBackpack

    ----------------------------------------------------------------------------
    -- 4. SETTINGS GEAR BUTTON [ ESC ]
    ----------------------------------------------------------------------------
    local btnSettings = Instance.new("TextButton")
    btnSettings.Name = "SettingsButton"
    btnSettings.Size = UDim2.fromOffset(26, 26)
    btnSettings.BackgroundColor3 = Color3.fromRGB(26, 28, 34)
    btnSettings.BackgroundTransparency = 0.4
    btnSettings.BorderSizePixel = 0
    btnSettings.Text = ""
    btnSettings.AutoButtonColor = false
    btnSettings.LayoutOrder = 6
    btnSettings.ZIndex = 52
    btnSettings.Parent = root

    local setCorner = Instance.new("UICorner")
    setCorner.CornerRadius = UDim.new(0, 6)
    setCorner.Parent = btnSettings

    local setStroke = Instance.new("UIStroke")
    setStroke.Color = Color3.fromRGB(255, 255, 255)
    setStroke.Transparency = 0.85
    setStroke.Thickness = 1
    setStroke.Parent = btnSettings

    local setIcon = IconPack.CreateIcon("settings", 14, Color3.fromRGB(225, 230, 240))
    setIcon.Name = "Icon"
    setIcon.Position = UDim2.fromScale(0.5, 0.5)
    setIcon.AnchorPoint = Vector2.new(0.5, 0.5)
    setIcon.ZIndex = 53
    setIcon.Parent = btnSettings

    -- Button Hover Micro-interactions
    btnBackpack.MouseEnter:Connect(function()
        AudioManager.Play("Hover")
        TweenService:Create(btnBackpack, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            BackgroundTransparency = 0.15,
        }):Play()
        TweenService:Create(bpStroke, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            Color = Color3.fromRGB(245, 160, 40),
            Transparency = 0.3,
        }):Play()
    end)

    btnBackpack.MouseLeave:Connect(function()
        TweenService:Create(btnBackpack, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            BackgroundTransparency = 0.4,
        }):Play()
        TweenService:Create(bpStroke, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            Color = Color3.fromRGB(255, 255, 255),
            Transparency = 0.85,
        }):Play()
    end)

    btnSettings.MouseEnter:Connect(function()
        AudioManager.Play("Hover")
        TweenService:Create(btnSettings, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            BackgroundTransparency = 0.15,
        }):Play()
        TweenService:Create(setStroke, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            Color = Color3.fromRGB(245, 160, 40),
            Transparency = 0.3,
        }):Play()
        TweenService:Create(setIcon, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            Rotation = 45,
        }):Play()
    end)

    btnSettings.MouseLeave:Connect(function()
        TweenService:Create(btnSettings, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            BackgroundTransparency = 0.4,
        }):Play()
        TweenService:Create(setStroke, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            Color = Color3.fromRGB(255, 255, 255),
            Transparency = 0.85,
        }):Play()
        TweenService:Create(setIcon, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            Rotation = 0,
        }):Play()
    end)

    -- Callbacks
    local onBackpackCallback: (() -> ())? = nil
    local onSettingsCallback: (() -> ())? = nil

    btnBackpack.Activated:Connect(function()
        AudioManager.Play("Click")
        if onBackpackCallback then onBackpackCallback() end
    end)

    btnSettings.Activated:Connect(function()
        AudioManager.Play("Click")
        if onSettingsCallback then onSettingsCallback() end
    end)

    -- Controller Return
    local instance: HUDTopRightInstance = {
        Container = root,

        SetCampfireLit = function(isLit: boolean)
            if isLit then
                campLabel.Text = "FIRE: BURNING"
                campLabel.TextColor3 = Color3.fromRGB(255, 175, 60)
                IconPack.ApplyTo(campIcon, "flame", Color3.fromRGB(255, 160, 40), 0, 16)
            else
                campLabel.Text = "FIRE: EXTINGUISHED"
                campLabel.TextColor3 = Color3.fromRGB(160, 165, 175)
                IconPack.ApplyTo(campIcon, "flame", Color3.fromRGB(130, 135, 145), 0, 16)
            end
        end,

        SetSanctuaryStatus = function(inSanctuary: boolean)
            if inSanctuary then
                sanctuaryBadge.Text = "SANCTUARY SAFE"
                sanctuaryBadge.TextColor3 = Color3.fromRGB(140, 220, 140)
            else
                sanctuaryBadge.Text = "WILDERNESS (COLD)"
                sanctuaryBadge.TextColor3 = Color3.fromRGB(220, 130, 130)
            end
        end,

        SetTime = function(hour: number, day: number, phase: string?)
            dayLabel.Text = "DAY " .. tostring(day)
            
            local totalMinutes = math.floor((hour % 24) * 60)
            local h = math.floor(totalMinutes / 60)
            local m = totalMinutes % 60
            local ampm = if h >= 12 then "PM" else "AM"
            local displayH = if h == 0 then 12 elseif h > 12 then h - 12 else h
            
            clockLabel.Text = string.format("%d:%02d %s", displayH, m, ampm)

            local isNight = (h < 5 or h >= 19)
            if isNight then
                IconPack.ApplyTo(timeIcon, "moon", Color3.fromRGB(170, 200, 245), 0, 15)
            else
                IconPack.ApplyTo(timeIcon, "sun", Color3.fromRGB(250, 200, 60), 0, 15)
            end
        end,

        SetOnBackpackClick = function(callback)
            onBackpackCallback = callback
        end,

        SetOnSettingsClick = function(callback)
            onSettingsCallback = callback
        end,

        Destroy = function()
            root:Destroy()
        end,
    }

    return instance
end

return HUDTopRightWidget
