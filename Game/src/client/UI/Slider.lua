--!strict
--[[
    UI/Slider.lua
    Modular Glassmorphic Slider Component (Volume, Look Sensitivity, FOV)
    "Don't Let the Fire Die" — Fluenosity Studio
]]

local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local UITheme = require(script.Parent:WaitForChild("UITheme"))

export type SliderConfig = {
    Label: string,
    Sublabel: string?,
    Description: string?,
    Min: number?,
    MinValue: number?,
    Max: number?,
    MaxValue: number?,
    Default: number?,
    InitialValue: number?,
    Step: number?,
    ValueFormat: ((val: number) -> string)?,
    Size: UDim2?,
    LayoutOrder: number?,
    ZIndex: number?,
    Parent: Instance?,
    OnChange: ((newVal: number) -> ())?,
    OnChanged: ((newVal: number) -> ())?,
}

local Slider = {}

function Slider.Create(config: SliderConfig): Frame
    local minVal = config.Min or config.MinValue or 0
    local maxVal = config.Max or config.MaxValue or 1
    local defaultVal = config.Default or config.InitialValue or minVal
    local currentVal = math.clamp(defaultVal, minVal, maxVal)
    local step = config.Step or 0.05
    local isDragging = false
    local onChangeCallback = config.OnChange or config.OnChanged

    local container = Instance.new("Frame")
    container.Name = "Slider_" .. config.Label:gsub("%s+", "")
    container.Size = config.Size or UDim2.new(1, 0, 0, 56)
    container.BackgroundTransparency = 1
    container.LayoutOrder = config.LayoutOrder or 0
    container.ZIndex = config.ZIndex or 5

    local vLayout = Instance.new("UIListLayout")
    vLayout.FillDirection = Enum.FillDirection.Vertical
    vLayout.Padding = UDim.new(0, 6)
    vLayout.Parent = container

    -- Top Label & Value Readout Row
    local topRow = Instance.new("Frame")
    topRow.Name = "TopRow"
    topRow.Size = UDim2.new(1, 0, 0, 18)
    topRow.BackgroundTransparency = 1
    topRow.Parent = container

    local label = Instance.new("TextLabel")
    label.Name = "Label"
    label.Size = UDim2.new(0.65, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.Font = UITheme.Fonts.Subheading
    label.Text = config.Label
    label.TextColor3 = UITheme.Colors.TextPrimary
    label.TextSize = UITheme.FontSizes.Body
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = topRow

    local valLabel = Instance.new("TextLabel")
    valLabel.Name = "ValueLabel"
    valLabel.Size = UDim2.new(0.35, 0, 1, 0)
    valLabel.Position = UDim2.fromScale(0.65, 0)
    valLabel.BackgroundTransparency = 1
    valLabel.Font = UITheme.Fonts.Subheading
    valLabel.TextColor3 = UITheme.Colors.EmberHot
    valLabel.TextSize = UITheme.FontSizes.Body
    valLabel.TextXAlignment = Enum.TextXAlignment.Right
    valLabel.Parent = topRow

    local function formatValue(val: number): string
        if config.ValueFormat then
            return config.ValueFormat(val)
        else
            return string.format("%d%%", math.floor(val * 100 + 0.5))
        end
    end

    valLabel.Text = formatValue(currentVal)

    -- Bottom Slider Track & Control Row
    local trackRow = Instance.new("Frame")
    trackRow.Name = "TrackRow"
    trackRow.Size = UDim2.new(1, 0, 0, 24)
    trackRow.BackgroundTransparency = 1
    trackRow.Parent = container

    -- Step Minus Button
    local minusBtn = Instance.new("TextButton")
    minusBtn.Name = "MinusBtn"
    minusBtn.Size = UDim2.new(0, 24, 0, 24)
    minusBtn.BackgroundColor3 = UITheme.Colors.GlassSurface
    minusBtn.BackgroundTransparency = UITheme.Transparency.Button
    minusBtn.Text = "–"
    minusBtn.TextColor3 = UITheme.Colors.TextSecondary
    minusBtn.Font = UITheme.Fonts.Heading
    minusBtn.TextSize = 14
    minusBtn.AutoButtonColor = false
    minusBtn.Parent = trackRow

    local mCorner = Instance.new("UICorner")
    mCorner.CornerRadius = UDim.new(0, 6)
    mCorner.Parent = minusBtn

    -- Step Plus Button
    local plusBtn = Instance.new("TextButton")
    plusBtn.Name = "PlusBtn"
    plusBtn.Size = UDim2.new(0, 24, 0, 24)
    plusBtn.Position = UDim2.new(1, -24, 0, 0)
    plusBtn.BackgroundColor3 = UITheme.Colors.GlassSurface
    plusBtn.BackgroundTransparency = UITheme.Transparency.Button
    plusBtn.Text = "+"
    plusBtn.TextColor3 = UITheme.Colors.TextSecondary
    plusBtn.Font = UITheme.Fonts.Heading
    plusBtn.TextSize = 14
    plusBtn.AutoButtonColor = false
    plusBtn.Parent = trackRow

    local pCorner = Instance.new("UICorner")
    pCorner.CornerRadius = UDim.new(0, 6)
    pCorner.Parent = plusBtn

    -- Track Container
    local trackContainer = Instance.new("Frame")
    trackContainer.Name = "TrackContainer"
    trackContainer.Size = UDim2.new(1, -64, 0, 24)
    trackContainer.Position = UDim2.new(0, 32, 0, 0)
    trackContainer.BackgroundTransparency = 1
    trackContainer.Parent = trackRow

    -- Track Bar
    local track = Instance.new("Frame")
    track.Name = "Track"
    track.Size = UDim2.new(1, 0, 0, 6)
    track.AnchorPoint = Vector2.new(0, 0.5)
    track.Position = UDim2.new(0, 0, 0.5, 0)
    track.BackgroundColor3 = UITheme.Colors.GlassElevated
    track.BackgroundTransparency = 0.35
    track.BorderSizePixel = 0
    track.Parent = trackContainer

    local trackCorner = Instance.new("UICorner")
    trackCorner.CornerRadius = UDim.new(0, 999)
    trackCorner.Parent = track

    -- Active Ember Fill Bar
    local fill = Instance.new("Frame")
    fill.Name = "Fill"
    local initialAlpha = math.clamp((currentVal - minVal) / (maxVal - minVal), 0, 1)
    fill.Size = UDim2.new(initialAlpha, 0, 1, 0)
    fill.BackgroundColor3 = UITheme.Colors.EmberHot
    fill.BorderSizePixel = 0
    fill.Parent = track

    local fillCorner = Instance.new("UICorner")
    fillCorner.CornerRadius = UDim.new(0, 999)
    fillCorner.Parent = fill

    local fillGrad = Instance.new("UIGradient")
    fillGrad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, UITheme.Colors.EmberPrimary),
        ColorSequenceKeypoint.new(1, UITheme.Colors.EmberGold),
    })
    fillGrad.Parent = fill

    -- Draggable Thumb
    local thumb = Instance.new("Frame")
    thumb.Name = "Thumb"
    thumb.Size = UDim2.new(0, 16, 0, 16)
    thumb.AnchorPoint = Vector2.new(0.5, 0.5)
    thumb.Position = UDim2.new(initialAlpha, 0, 0.5, 0)
    thumb.BackgroundColor3 = UITheme.Colors.TextPrimary
    thumb.BorderSizePixel = 0
    thumb.Parent = trackContainer

    local tCorner = Instance.new("UICorner")
    tCorner.CornerRadius = UDim.new(0, 999)
    tCorner.Parent = thumb

    local tStroke = Instance.new("UIStroke")
    tStroke.Thickness = 2.0
    tStroke.Color = UITheme.Colors.EmberHot
    tStroke.Parent = thumb

    local function updateValueFromAlpha(alpha: number)
        local rawVal = minVal + alpha * (maxVal - minVal)
        -- Snap to step
        local steppedVal = math.floor((rawVal / step) + 0.5) * step
        currentVal = math.clamp(steppedVal, minVal, maxVal)

        local visualAlpha = (currentVal - minVal) / (maxVal - minVal)
        fill.Size = UDim2.new(visualAlpha, 0, 1, 0)
        thumb.Position = UDim2.new(visualAlpha, 0, 0.5, 0)
        valLabel.Text = formatValue(currentVal)

        if onChangeCallback then
            onChangeCallback(currentVal)
        end
    end

    -- Drag Interaction
    local function processInput(input: InputObject)
        local trackAbsPos = trackContainer.AbsolutePosition.X
        local trackAbsSize = trackContainer.AbsoluteSize.X
        if trackAbsSize <= 0 then return end
        local clickX = input.Position.X
        local alpha = math.clamp((clickX - trackAbsPos) / trackAbsSize, 0, 1)
        updateValueFromAlpha(alpha)
    end

    trackContainer.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            isDragging = true
            UITheme.PlayClick()
            processInput(input)
        end
    end)

    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            isDragging = false
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if isDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            processInput(input)
        end
    end)

    minusBtn.Activated:Connect(function()
        UITheme.PlayClick()
        local nextVal = math.clamp(currentVal - step, minVal, maxVal)
        local alpha = (nextVal - minVal) / (maxVal - minVal)
        updateValueFromAlpha(alpha)
    end)

    plusBtn.Activated:Connect(function()
        UITheme.PlayClick()
        local nextVal = math.clamp(currentVal + step, minVal, maxVal)
        local alpha = (nextVal - minVal) / (maxVal - minVal)
        updateValueFromAlpha(alpha)
    end)

    if config.Parent then
        container.Parent = config.Parent
    end

    return container
end

return Slider
