--!strict
--[[
    HUDTopRightWidget.lua
    Clean Glassmorphic Top-Right Corner Widget for "Don't Let the Fire Die".
    Developed for Fluenosity Studio.

    Design: Flat glass bar flush to top-right corner, no pill shape.
    - Celestial Day & Time tracker
    - Backpack [B] icon button
    - Settings gear [ESC] icon button
    - Tooltips show BELOW the widget (never covering it)
]]

local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local sharedFolder = ReplicatedStorage:WaitForChild("FluenosityShared")
local IconPack = require(sharedFolder:WaitForChild("IconPack"))
local AudioManager = require(script.Parent.Parent:WaitForChild("AudioManager"))
local UI = require(script.Parent.Parent:WaitForChild("UI"))

export type HUDTopRightInstance = {
    Container: Frame,
    SetCampfirePosition: (pos: Vector3) -> (),
    SetCampfireLit: (isLit: boolean) -> (),
    SetTime: (hour: number, day: number, phase: string?) -> (),
    SetSanctuaryStatus: (inSanctuary: boolean) -> (),
    SetOnBackpackClick: (callback: () -> ()) -> (),
    SetOnSettingsClick: (callback: () -> ()) -> (),
    Destroy: () -> (),
}

local HUDTopRightWidget = {}

function HUDTopRightWidget.Create(parent: Instance): HUDTopRightInstance
    -- Main Root Bar anchored flush to top-right corner (flat glass, no pill)
    local root = Instance.new("Frame")
    root.Name = "HUDTopRightWidget"
    root.Size = UDim2.fromOffset(210, 38)
    root.Position = UDim2.new(1, 0, 0, 36) -- Flush to right edge, just below Roblox topbar
    root.AnchorPoint = Vector2.new(1, 0)
    root.BackgroundColor3 = Color3.fromRGB(10, 11, 14)
    root.BackgroundTransparency = 0.18
    root.BorderSizePixel = 0
    root.ZIndex = 50
    root.Parent = parent

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 0) -- No rounding — flush corner
    corner.Parent = root

    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(255, 255, 255)
    stroke.Transparency = 0.88
    stroke.Thickness = 1
    stroke.Parent = root

    local layout = Instance.new("UIListLayout")
    layout.FillDirection = Enum.FillDirection.Horizontal
    layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    layout.VerticalAlignment = Enum.VerticalAlignment.Center
    layout.Padding = UDim.new(0, 8)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Parent = root

    local padding = Instance.new("UIPadding")
    padding.PaddingLeft = UDim.new(0, 10)
    padding.PaddingRight = UDim.new(0, 10)
    padding.Parent = root

    ----------------------------------------------------------------------------
    -- 1. CELESTIAL TIME TRACKER (Day & Clock Time)
    ----------------------------------------------------------------------------
    local timeFrame = Instance.new("Frame")
    timeFrame.Name = "TimePill"
    timeFrame.Size = UDim2.fromOffset(102, 26)
    timeFrame.BackgroundTransparency = 1
    timeFrame.LayoutOrder = 1
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
    dayLabel.Text = "DAY 0"
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
    clockLabel.Text = "14:00"
    clockLabel.TextColor3 = Color3.fromRGB(180, 185, 195)
    clockLabel.TextSize = 9
    clockLabel.TextXAlignment = Enum.TextXAlignment.Left
    clockLabel.ZIndex = 52
    clockLabel.Parent = timeFrame

    -- Hairline Divider between time and buttons
    local div = Instance.new("Frame")
    div.Name = "Divider"
    div.Size = UDim2.new(0, 1, 0, 16)
    div.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    div.BackgroundTransparency = 0.88
    div.BorderSizePixel = 0
    div.LayoutOrder = 2
    div.ZIndex = 51
    div.Parent = root

    ----------------------------------------------------------------------------
    -- 2. QUICK BACKPACK BUTTON [ B ]
    ----------------------------------------------------------------------------
    local btnBackpack = Instance.new("TextButton")
    btnBackpack.Name = "BackpackButton"
    btnBackpack.Size = UDim2.fromOffset(36, 26)
    btnBackpack.BackgroundColor3 = Color3.fromRGB(26, 28, 34)
    btnBackpack.BackgroundTransparency = 0.4
    btnBackpack.BorderSizePixel = 0
    btnBackpack.Text = ""
    btnBackpack.AutoButtonColor = false
    btnBackpack.LayoutOrder = 3
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

    local bpIcon = IconPack.CreateIcon("backpack", 13, Color3.fromRGB(235, 240, 250))
    bpIcon.Name = "BackpackIcon"
    bpIcon.Position = UDim2.new(0, 5, 0.5, 0)
    bpIcon.AnchorPoint = Vector2.new(0, 0.5)
    bpIcon.ZIndex = 53
    bpIcon.Parent = btnBackpack

    local bpKey = Instance.new("TextLabel")
    bpKey.Name = "KeyLabel"
    bpKey.Size = UDim2.new(0, 12, 1, 0)
    bpKey.Position = UDim2.new(1, -5, 0, 0)
    bpKey.AnchorPoint = Vector2.new(1, 0)
    bpKey.BackgroundTransparency = 1
    bpKey.Font = Enum.Font.GothamBold
    bpKey.Text = "B"
    bpKey.TextColor3 = Color3.fromRGB(255, 185, 75)
    bpKey.TextSize = 10
    bpKey.TextXAlignment = Enum.TextXAlignment.Right
    bpKey.ZIndex = 53
    bpKey.Parent = btnBackpack

    local bpScale = Instance.new("UIScale")
    bpScale.Scale = 1
    bpScale.Parent = btnBackpack

    ----------------------------------------------------------------------------
    -- 3. QUICK SETTINGS BUTTON [ ESC ]
    ----------------------------------------------------------------------------
    local btnSettings = Instance.new("TextButton")
    btnSettings.Name = "SettingsButton"
    btnSettings.Size = UDim2.fromOffset(26, 26)
    btnSettings.BackgroundColor3 = Color3.fromRGB(26, 28, 34)
    btnSettings.BackgroundTransparency = 0.4
    btnSettings.BorderSizePixel = 0
    btnSettings.Text = ""
    btnSettings.AutoButtonColor = false
    btnSettings.LayoutOrder = 4
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

    local setIcon = IconPack.CreateIcon("settings", 14, Color3.fromRGB(235, 240, 250))
    setIcon.Name = "GearIcon"
    setIcon.Position = UDim2.fromScale(0.5, 0.5)
    setIcon.AnchorPoint = Vector2.new(0.5, 0.5)
    setIcon.ZIndex = 53
    setIcon.Parent = btnSettings

    local setScale = Instance.new("UIScale")
    setScale.Scale = 1
    setScale.Parent = btnSettings

    -- Button Hover Micro-interactions (Color only, zero hover bounce)
    btnBackpack.MouseEnter:Connect(function()
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
        TweenService:Create(btnSettings, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            BackgroundTransparency = 0.15,
        }):Play()
        TweenService:Create(setStroke, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            Color = Color3.fromRGB(245, 160, 40),
            Transparency = 0.3,
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
    end)

    -- Callbacks with tactile micro-compression and audio
    local onBackpackCallback: (() -> ())? = nil
    local onSettingsCallback: (() -> ())? = nil

    btnBackpack.Activated:Connect(function()
        TweenService:Create(bpScale, TweenInfo.new(0.06, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Scale = 0.94 }):Play()
        task.delay(0.08, function()
            TweenService:Create(bpScale, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Scale = 1.0 }):Play()
        end)
        AudioManager.Play("Click")
        if onBackpackCallback then onBackpackCallback() end
    end)

    btnSettings.Activated:Connect(function()
        TweenService:Create(setScale, TweenInfo.new(0.06, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Scale = 0.94 }):Play()
        task.delay(0.08, function()
            TweenService:Create(setScale, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Scale = 1.0 }):Play()
        end)
        AudioManager.Play("Click")
        if onSettingsCallback then onSettingsCallback() end
    end)

    -- Attach luxury glassmorphic tooltips
    UI.Tooltip.Attach(btnBackpack, {
        Title = "Survival Backpack",
        Category = "HOTKEY [B]",
        Description = "Manage inventory, tools, firewood, and supplies.",
        ActionHint = "Click or press [B] to toggle",
    })

    UI.Tooltip.Attach(btnSettings, {
        Title = "System Settings",
        Category = "HOTKEY [ESC]",
        Description = "Adjust audio volume, look sensitivity, and options.",
        ActionHint = "Click or press [ESC] to toggle",
    })

    -- Controller Return
    local instance: HUDTopRightInstance = {
        Container = root,

        SetCampfirePosition = function(_pos: Vector3) end,
        SetCampfireLit = function(_isLit: boolean) end,
        SetSanctuaryStatus = function(_inSanctuary: boolean) end,

        SetTime = function(hour: number, day: number, _phase: string?)
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
