--!strict
--[[
    HUDVitals.lua
    Ultra-clean modern survival HUD vitals for "Don't Let the Fire Die".
    Developed for Fluenosity Studio. Matches Image 2 AAA minimalist layout:
    - Left Side: Frameless Health (100) & Food (78) with sleek glowing line bars.
    - Right Side: Frameless Stamina & Shift to Run key button (RUN [SHIFT]).
    - Zero background cards, zero border pills (floating clean like HUDClock).
]]

local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local sharedFolder = ReplicatedStorage:WaitForChild("FluenosityShared")
local IconPack = require(sharedFolder:WaitForChild("IconPack"))

export type HUDVitalsInstance = {
    Container: Frame,
    LeftContainer: Frame,
    RightContainer: Frame,
    SetHealth: (current: number, max: number) -> (),
    SetHunger: (current: number, max: number) -> (),
    SetStamina: (current: number, max: number) -> (),
    SetSprinting: (isSprinting: boolean) -> (),
    OnSprintToggle: (callback: () -> ()) -> (),
    Destroy: () -> (),
}

local HUDVitals = {}

-- Helper to create a frameless vital line row (Vector Icon | Number | Glowing Thin Bar)
local function createVitalLine(
    parent: Instance,
    iconName: string,
    iconColor: Color3,
    fillColor: Color3,
    defaultVal: string,
    barWidth: number
)
    local row = Instance.new("Frame")
    row.Name = "VitalRow_" .. iconName
    row.Size = UDim2.new(1, 0, 0, 18)
    row.BackgroundTransparency = 1
    row.ZIndex = 50
    row.Parent = parent

    -- Vector Icon (Leftmost)
    local icon = IconPack.CreateIcon(iconName, 15, iconColor)
    icon.Name = "Icon"
    icon.Position = UDim2.new(0, 0, 0.5, 0)
    icon.AnchorPoint = Vector2.new(0, 0.5)
    icon.ZIndex = 51
    icon.Parent = row

    -- Numeric Value Readout
    local lblValue = Instance.new("TextLabel")
    lblValue.Name = "Value"
    lblValue.Size = UDim2.fromOffset(30, 18)
    lblValue.Position = UDim2.new(0, 22, 0.5, 0)
    lblValue.AnchorPoint = Vector2.new(0, 0.5)
    lblValue.BackgroundTransparency = 1
    lblValue.Font = Enum.Font.GothamBold
    lblValue.Text = defaultVal
    lblValue.TextColor3 = Color3.fromRGB(240, 242, 248)
    lblValue.TextSize = 12
    lblValue.TextXAlignment = Enum.TextXAlignment.Left
    lblValue.ZIndex = 51
    lblValue.Parent = row

    -- Sleek Horizontal Bar Track (Floating line - no box)
    local track = Instance.new("Frame")
    track.Name = "BarTrack"
    track.Size = UDim2.new(0, barWidth, 0, 3)
    track.Position = UDim2.new(0, 56, 0.5, 0)
    track.AnchorPoint = Vector2.new(0, 0.5)
    track.BackgroundColor3 = Color3.fromRGB(48, 50, 58)
    track.BackgroundTransparency = 0.45
    track.BorderSizePixel = 0
    track.ZIndex = 51
    track.Parent = row

    local trackCorner = Instance.new("UICorner")
    trackCorner.CornerRadius = UDim.new(1, 0)
    trackCorner.Parent = track

    -- Active Glowing Bar Fill
    local fill = Instance.new("Frame")
    fill.Name = "BarFill"
    fill.Size = UDim2.fromScale(1, 1)
    fill.BackgroundColor3 = fillColor
    fill.BorderSizePixel = 0
    fill.ZIndex = 52
    fill.Parent = track

    local fillCorner = Instance.new("UICorner")
    fillCorner.CornerRadius = UDim.new(1, 0)
    fillCorner.Parent = fill

    return {
        Row = row,
        Label = lblValue,
        Fill = fill,
        FillColor = fillColor,
    }
end

function HUDVitals.Create(parent: Instance): HUDVitalsInstance
    -- Master root frame
    local root = Instance.new("Frame")
    root.Name = "HUDVitalsRoot"
    root.Size = UDim2.fromScale(1, 1)
    root.Position = UDim2.fromScale(0, 0)
    root.BackgroundTransparency = 1
    root.ZIndex = 50
    root.Parent = parent

    ----------------------------------------------------------------------------
    -- 1. LEFT SIDE: HEALTH (100) & FOOD (78)
    ----------------------------------------------------------------------------
    local leftContainer = Instance.new("Frame")
    leftContainer.Name = "LeftVitals"
    leftContainer.Size = UDim2.fromOffset(250, 44)
    leftContainer.Position = UDim2.new(0, 36, 1, -26)
    leftContainer.AnchorPoint = Vector2.new(0, 1)
    leftContainer.BackgroundTransparency = 1
    leftContainer.ZIndex = 50
    leftContainer.Parent = root

    local leftLayout = Instance.new("UIListLayout")
    leftLayout.FillDirection = Enum.FillDirection.Vertical
    leftLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
    leftLayout.VerticalAlignment = Enum.VerticalAlignment.Center
    leftLayout.Padding = UDim.new(0, 7)
    leftLayout.SortOrder = Enum.SortOrder.LayoutOrder
    leftLayout.Parent = leftContainer

    -- Health Line (vector heart + 100 with long red bar line)
    local healthLine = createVitalLine(
        leftContainer,
        "heart",
        Color3.fromRGB(250, 50, 60),
        Color3.fromRGB(245, 45, 60),
        "100",
        170
    )
    healthLine.Row.LayoutOrder = 1

    -- Food Line (vector drumstick + 78 with glowing amber bar line)
    local foodLine = createVitalLine(
        leftContainer,
        "drumstick",
        Color3.fromRGB(245, 150, 45),
        Color3.fromRGB(245, 150, 45),
        "78",
        170
    )
    foodLine.Row.LayoutOrder = 2

    ----------------------------------------------------------------------------
    -- 2. RIGHT SIDE: STAMINA & SHIFT TO RUN BUTTON (RUN [SHIFT])
    ----------------------------------------------------------------------------
    local rightContainer = Instance.new("Frame")
    rightContainer.Name = "RightVitals"
    rightContainer.Size = UDim2.fromOffset(260, 32)
    rightContainer.Position = UDim2.new(1, -36, 1, -26)
    rightContainer.AnchorPoint = Vector2.new(1, 1)
    rightContainer.BackgroundTransparency = 1
    rightContainer.ZIndex = 50
    rightContainer.Parent = root

    local rightLayout = Instance.new("UIListLayout")
    rightLayout.FillDirection = Enum.FillDirection.Horizontal
    rightLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
    rightLayout.VerticalAlignment = Enum.VerticalAlignment.Center
    rightLayout.Padding = UDim.new(0, 18)
    rightLayout.SortOrder = Enum.SortOrder.LayoutOrder
    rightLayout.Parent = rightContainer

    -- Stamina Indicator (vector zap lightning + thin yellow line bar)
    local staminaHolder = Instance.new("Frame")
    staminaHolder.Name = "StaminaHolder"
    staminaHolder.Size = UDim2.fromOffset(116, 20)
    staminaHolder.BackgroundTransparency = 1
    staminaHolder.LayoutOrder = 1
    staminaHolder.ZIndex = 51
    staminaHolder.Parent = rightContainer

    local stamIcon = IconPack.CreateIcon("zap", 15, Color3.fromRGB(250, 195, 45))
    stamIcon.Name = "StamIcon"
    stamIcon.Position = UDim2.new(0, 0, 0.5, 0)
    stamIcon.AnchorPoint = Vector2.new(0, 0.5)
    stamIcon.ZIndex = 52
    stamIcon.Parent = staminaHolder

    local stamTrack = Instance.new("Frame")
    stamTrack.Name = "StamTrack"
    stamTrack.Size = UDim2.new(1, -22, 0, 3)
    stamTrack.Position = UDim2.new(0, 22, 0.5, 0)
    stamTrack.AnchorPoint = Vector2.new(0, 0.5)
    stamTrack.BackgroundColor3 = Color3.fromRGB(48, 50, 58)
    stamTrack.BackgroundTransparency = 0.45
    stamTrack.BorderSizePixel = 0
    stamTrack.ZIndex = 52
    stamTrack.Parent = staminaHolder

    local stamTrackCorner = Instance.new("UICorner")
    stamTrackCorner.CornerRadius = UDim.new(1, 0)
    stamTrackCorner.Parent = stamTrack

    local stamFill = Instance.new("Frame")
    stamFill.Name = "StamFill"
    stamFill.Size = UDim2.fromScale(1, 1)
    stamFill.BackgroundColor3 = Color3.fromRGB(250, 195, 45)
    stamFill.BorderSizePixel = 0
    stamFill.ZIndex = 53
    stamFill.Parent = stamTrack

    local stamFillCorner = Instance.new("UICorner")
    stamFillCorner.CornerRadius = UDim.new(1, 0)
    stamFillCorner.Parent = stamFill

    -- Shift to Run Button (vector footprints + RUN [ SHIFT ])
    local runBtn = Instance.new("TextButton")
    runBtn.Name = "ShiftToRunButton"
    runBtn.Size = UDim2.fromOffset(96, 26)
    runBtn.BackgroundTransparency = 1
    runBtn.AutoButtonColor = false
    runBtn.Text = ""
    runBtn.LayoutOrder = 2
    runBtn.ZIndex = 51
    runBtn.Parent = rightContainer

    local runnerIcon = IconPack.CreateIcon("footprints", 15, Color3.fromRGB(240, 242, 248))
    runnerIcon.Name = "RunnerIcon"
    runnerIcon.Position = UDim2.new(0, 0, 0.5, 0)
    runnerIcon.AnchorPoint = Vector2.new(0, 0.5)
    runnerIcon.ZIndex = 52
    runnerIcon.Parent = runBtn

    local runLabel = Instance.new("TextLabel")
    runLabel.Name = "RunLabel"
    runLabel.Size = UDim2.fromOffset(26, 16)
    runLabel.Position = UDim2.new(0, 20, 0.5, 0)
    runLabel.AnchorPoint = Vector2.new(0, 0.5)
    runLabel.BackgroundTransparency = 1
    runLabel.Font = Enum.Font.GothamBold
    runLabel.Text = "RUN"
    runLabel.TextColor3 = Color3.fromRGB(240, 242, 248)
    runLabel.TextSize = 11
    runLabel.ZIndex = 52
    runLabel.Parent = runBtn

    -- [ SHIFT ] key badge outline
    local keyBadge = Instance.new("Frame")
    keyBadge.Name = "KeyBadge"
    keyBadge.Size = UDim2.fromOffset(44, 18)
    keyBadge.Position = UDim2.new(1, 0, 0.5, 0)
    keyBadge.AnchorPoint = Vector2.new(1, 0.5)
    keyBadge.BackgroundColor3 = Color3.fromRGB(16, 18, 22)
    keyBadge.BackgroundTransparency = 0.35
    keyBadge.BorderSizePixel = 0
    keyBadge.ZIndex = 52
    keyBadge.Parent = runBtn

    local badgeCorner = Instance.new("UICorner")
    badgeCorner.CornerRadius = UDim.new(0, 4)
    badgeCorner.Parent = keyBadge

    local badgeStroke = Instance.new("UIStroke")
    badgeStroke.Color = Color3.fromRGB(255, 255, 255)
    badgeStroke.Transparency = 0.78
    badgeStroke.Thickness = 1
    badgeStroke.Parent = keyBadge

    local badgeLabel = Instance.new("TextLabel")
    badgeLabel.Name = "BadgeLabel"
    badgeLabel.Size = UDim2.fromScale(1, 1)
    badgeLabel.BackgroundTransparency = 1
    badgeLabel.Font = Enum.Font.GothamBold
    badgeLabel.Text = "SHIFT"
    badgeLabel.TextColor3 = Color3.fromRGB(235, 238, 245)
    badgeLabel.TextSize = 10
    badgeLabel.ZIndex = 53
    badgeLabel.Parent = keyBadge

    local sprintToggleCallback: (() -> ())? = nil

    runBtn.Activated:Connect(function()
        if sprintToggleCallback then
            sprintToggleCallback()
        end
    end)

    ----------------------------------------------------------------------------
    -- VISUAL UPDATE LOGIC
    ----------------------------------------------------------------------------
    local function setHealth(current: number, max: number)
        local safeMax = math.max(max, 1)
        local ratio = math.clamp(current / safeMax, 0, 1)
        healthLine.Label.Text = tostring(math.round(current))

        TweenService:Create(healthLine.Fill, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            Size = UDim2.fromScale(ratio, 1),
        }):Play()

        if ratio < 0.25 then
            healthLine.Fill.BackgroundColor3 = Color3.fromRGB(255, 30, 30)
        else
            healthLine.Fill.BackgroundColor3 = Color3.fromRGB(245, 45, 60)
        end
    end

    local function setHunger(current: number, max: number)
        local safeMax = math.max(max, 1)
        local ratio = math.clamp(current / safeMax, 0, 1)
        foodLine.Label.Text = tostring(math.round(current))

        TweenService:Create(foodLine.Fill, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            Size = UDim2.fromScale(ratio, 1),
        }):Play()
    end

    local function setStamina(current: number, max: number)
        local safeMax = math.max(max, 1)
        local ratio = math.clamp(current / safeMax, 0, 1)

        TweenService:Create(stamFill, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            Size = UDim2.fromScale(ratio, 1),
        }):Play()

        if ratio < 0.22 then
            stamFill.BackgroundColor3 = Color3.fromRGB(255, 75, 75)
            stamIcon.ImageColor3 = Color3.fromRGB(255, 75, 75)
        else
            stamFill.BackgroundColor3 = Color3.fromRGB(250, 195, 45)
            stamIcon.ImageColor3 = Color3.fromRGB(250, 195, 45)
        end
    end

    local function setSprinting(isSprinting: boolean)
        if isSprinting then
            TweenService:Create(badgeStroke, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                Color = Color3.fromRGB(245, 160, 40),
                Transparency = 0.1,
            }):Play()
            TweenService:Create(badgeLabel, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                TextColor3 = Color3.fromRGB(255, 205, 100),
            }):Play()
            TweenService:Create(runnerIcon, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                ImageColor3 = Color3.fromRGB(255, 205, 100),
            }):Play()
            TweenService:Create(runLabel, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                TextColor3 = Color3.fromRGB(255, 205, 100),
            }):Play()
        else
            TweenService:Create(badgeStroke, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                Color = Color3.fromRGB(255, 255, 255),
                Transparency = 0.78,
            }):Play()
            TweenService:Create(badgeLabel, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                TextColor3 = Color3.fromRGB(235, 238, 245),
            }):Play()
            TweenService:Create(runnerIcon, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                ImageColor3 = Color3.fromRGB(240, 242, 248),
            }):Play()
            TweenService:Create(runLabel, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                TextColor3 = Color3.fromRGB(240, 242, 248),
            }):Play()
        end
    end

    return {
        Container = root,
        LeftContainer = leftContainer,
        RightContainer = rightContainer,
        SetHealth = setHealth,
        SetHunger = setHunger,
        SetStamina = setStamina,
        SetSprinting = setSprinting,
        OnSprintToggle = function(callback: () -> ())
            sprintToggleCallback = callback
        end,
        Destroy = function()
            root:Destroy()
        end,
    }
end

return HUDVitals
