--!strict
--[[
    HUDClock.lua
    Topmost celestial Day & Time tracker for "Don't Let the Fire Die".
    Developed for Fluenosity Studio. Matches Image 2 reference:
    - Pure frameless, borderless floating layout (NO dark pill box/stroke)
    - Positioned at the very top of the screen
    - Crisp white "DAY 0" with subtle drop shadow
    - Glowing amber dual-tone track with radiant sun orb (halo + core)
    - Glowing amber digital time "10:27"
]]

local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local sharedFolder = ReplicatedStorage:WaitForChild("FluenosityShared")
local IconPack = require(sharedFolder:WaitForChild("IconPack"))

export type HUDClockInstance = {
    Container: Frame,
    SetTime: (hour: number, day: number, phase: string?, progress: number?) -> (),
    Destroy: () -> (),
}

local HUDClock = {}

function HUDClock.Create(parent: Instance): HUDClockInstance
    -- Frameless container sitting at the topmost center of the screen
    local container = Instance.new("Frame")
    container.Name = "HUDClock"
    container.Size = UDim2.fromOffset(390, 26)
    container.Position = UDim2.new(0.5, 0, 0, 10)
    container.AnchorPoint = Vector2.new(0.5, 0)
    container.BackgroundTransparency = 1
    container.BorderSizePixel = 0
    container.ZIndex = 50
    container.Parent = parent

    -- 1. Day Label (Left: crisp bold white with subtle text shadow)
    local lblDay = Instance.new("TextLabel")
    lblDay.Name = "DayLabel"
    lblDay.Size = UDim2.fromOffset(70, 24)
    lblDay.Position = UDim2.new(0, 0, 0.5, 0)
    lblDay.AnchorPoint = Vector2.new(0, 0.5)
    lblDay.BackgroundTransparency = 1
    lblDay.Font = Enum.Font.GothamBold
    lblDay.Text = "DAY 0"
    lblDay.TextColor3 = Color3.fromRGB(245, 248, 255)
    lblDay.TextSize = 14
    lblDay.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    lblDay.TextStrokeTransparency = 0.65
    lblDay.TextXAlignment = Enum.TextXAlignment.Left
    lblDay.ZIndex = 52
    lblDay.Parent = container

    -- 2. Celestial Timeline Track (Center)
    local timelineContainer = Instance.new("Frame")
    timelineContainer.Name = "Timeline"
    timelineContainer.Size = UDim2.fromOffset(170, 22)
    timelineContainer.Position = UDim2.new(0.5, 0, 0.5, 0)
    timelineContainer.AnchorPoint = Vector2.new(0.5, 0.5)
    timelineContainer.BackgroundTransparency = 1
    timelineContainer.ZIndex = 52
    timelineContainer.Parent = container

    -- Sun vector icon (left)
    local iconSun = IconPack.CreateIcon("sun-medium", 16, Color3.fromRGB(255, 185, 45))
    iconSun.Name = "SunIcon"
    iconSun.Position = UDim2.new(0, 0, 0.5, 0)
    iconSun.AnchorPoint = Vector2.new(0, 0.5)
    iconSun.ZIndex = 53
    iconSun.Parent = timelineContainer

    -- Moon vector icon (right)
    local iconMoon = IconPack.CreateIcon("moon", 15, Color3.fromRGB(205, 215, 235))
    iconMoon.Name = "MoonIcon"
    iconMoon.Position = UDim2.new(1, 0, 0.5, 0)
    iconMoon.AnchorPoint = Vector2.new(1, 0.5)
    iconMoon.ZIndex = 53
    iconMoon.Parent = timelineContainer

    -- Horizontal progress track background (dark translucent track)
    local trackBg = Instance.new("Frame")
    trackBg.Name = "TrackBg"
    trackBg.Size = UDim2.new(1, -52, 0, 3)
    trackBg.Position = UDim2.new(0, 26, 0.5, 0)
    trackBg.AnchorPoint = Vector2.new(0, 0.5)
    trackBg.BackgroundColor3 = Color3.fromRGB(75, 80, 92)
    trackBg.BackgroundTransparency = 0.45
    trackBg.BorderSizePixel = 0
    trackBg.ZIndex = 53
    trackBg.Parent = timelineContainer

    local trackCorner = Instance.new("UICorner")
    trackCorner.CornerRadius = UDim.new(1, 0)
    trackCorner.Parent = trackBg

    -- Active glowing amber fill (from 0 to thumb position)
    local trackFill = Instance.new("Frame")
    trackFill.Name = "TrackFill"
    trackFill.Size = UDim2.fromScale(0.5, 1)
    trackFill.BackgroundColor3 = Color3.fromRGB(245, 160, 40)
    trackFill.BorderSizePixel = 0
    trackFill.ZIndex = 54
    trackFill.Parent = trackBg

    local fillCorner = Instance.new("UICorner")
    fillCorner.CornerRadius = UDim.new(1, 0)
    fillCorner.Parent = trackFill

    -- Glowing Sun Indicator Thumb (radiant ambient halo + bright golden core)
    local thumbHalo = Instance.new("Frame")
    thumbHalo.Name = "ThumbHalo"
    thumbHalo.Size = UDim2.fromOffset(22, 22)
    thumbHalo.AnchorPoint = Vector2.new(0.5, 0.5)
    thumbHalo.Position = UDim2.fromScale(0.5, 0.5)
    thumbHalo.BackgroundColor3 = Color3.fromRGB(255, 140, 25)
    thumbHalo.BackgroundTransparency = 0.62
    thumbHalo.BorderSizePixel = 0
    thumbHalo.ZIndex = 55
    thumbHalo.Parent = trackBg

    local haloCorner = Instance.new("UICorner")
    haloCorner.CornerRadius = UDim.new(1, 0)
    haloCorner.Parent = thumbHalo

    local thumbCore = Instance.new("Frame")
    thumbCore.Name = "ThumbCore"
    thumbCore.Size = UDim2.fromOffset(10, 10)
    thumbCore.AnchorPoint = Vector2.new(0.5, 0.5)
    thumbCore.Position = UDim2.fromScale(0.5, 0.5)
    thumbCore.BackgroundColor3 = Color3.fromRGB(255, 220, 100)
    thumbCore.BorderSizePixel = 0
    thumbCore.ZIndex = 56
    thumbCore.Parent = thumbHalo

    local coreCorner = Instance.new("UICorner")
    coreCorner.CornerRadius = UDim.new(1, 0)
    coreCorner.Parent = thumbCore

    -- 3. Digital Clock (Right: glowing amber gold with drop shadow)
    local lblClock = Instance.new("TextLabel")
    lblClock.Name = "ClockLabel"
    lblClock.Size = UDim2.fromOffset(60, 24)
    lblClock.Position = UDim2.new(1, 0, 0.5, 0)
    lblClock.AnchorPoint = Vector2.new(1, 0.5)
    lblClock.BackgroundTransparency = 1
    lblClock.Font = Enum.Font.GothamBold
    lblClock.Text = "10:27"
    lblClock.TextColor3 = Color3.fromRGB(245, 165, 45) -- Rich luminous amber gold
    lblClock.TextSize = 14
    lblClock.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    lblClock.TextStrokeTransparency = 0.65
    lblClock.TextXAlignment = Enum.TextXAlignment.Right
    lblClock.ZIndex = 52
    lblClock.Parent = container

    local function setTime(hour: number, day: number, phase: string?, progress: number?)
        lblDay.Text = "DAY " .. tostring(math.max(0, day))

        local h = math.floor(hour) % 24
        local m = math.floor((hour - math.floor(hour)) * 60)
        lblClock.Text = string.format("%02d:%02d", h, m)

        -- Celestial progress calculation:
        -- Daytime spans 6:00 to 18:00 (ratio 0 to 1). Night spans 18:00 to 6:00.
        local celestialRatio = 0.5
        if hour >= 6 and hour <= 18 then
            celestialRatio = (hour - 6) / 12
            trackFill.BackgroundColor3 = Color3.fromRGB(245, 160, 40)
            thumbHalo.BackgroundColor3 = Color3.fromRGB(255, 140, 25)
            thumbCore.BackgroundColor3 = Color3.fromRGB(255, 220, 100)
        else
            -- Night progress towards Moon
            local nightHour = (hour >= 18) and (hour - 18) or (hour + 6)
            celestialRatio = nightHour / 12
            trackFill.BackgroundColor3 = Color3.fromRGB(130, 160, 235)
            thumbHalo.BackgroundColor3 = Color3.fromRGB(120, 155, 240)
            thumbCore.BackgroundColor3 = Color3.fromRGB(215, 230, 255)
        end
        celestialRatio = math.clamp(celestialRatio, 0, 1)

        TweenService:Create(trackFill, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            Size = UDim2.fromScale(celestialRatio, 1),
        }):Play()

        TweenService:Create(thumbHalo, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            Position = UDim2.fromScale(celestialRatio, 0.5),
        }):Play()
    end

    return {
        Container = container,
        SetTime = setTime,
        Destroy = function()
            container:Destroy()
        end,
    }
end

return HUDClock
