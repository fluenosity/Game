--!strict
--[[
    UI/ProgressBar.lua
    Modular Glassmorphic Progress & Vitals Bar Component
    "Don't Let the Fire Die" — Fluenosity Studio
]]

local TweenService = game:GetService("TweenService")
local UITheme = require(script.Parent:WaitForChild("UITheme"))

export type ProgressBarConfig = {
    Current: number,
    Max: number,
    FillColor: Color3?,
    TrackColor: Color3?,
    Label: string?,
    ShowPercent: boolean?,
    Height: number?,
    CornerRadius: number?,
    Size: UDim2?,
    Position: UDim2?,
    AnchorPoint: Vector2?,
    LayoutOrder: number?,
    ZIndex: number?,
    Parent: Instance?,
}

export type ProgressBarInstance = {
    Frame: Frame,
    SetProgress: (current: number, max: number?, tweenTime: number?) -> (),
    SetColor: (color: Color3) -> (),
    Destroy: () -> (),
}

local ProgressBar = {}

function ProgressBar.Create(config: ProgressBarConfig): ProgressBarInstance
    local height = config.Height or 10
    local cornerRadius = config.CornerRadius or 999

    local container = Instance.new("Frame")
    container.Name = "ProgressBar_" .. (config.Label or "Bar")
    container.Size = config.Size or UDim2.new(1, 0, 0, height)
    if config.Position then container.Position = config.Position end
    if config.AnchorPoint then container.AnchorPoint = config.AnchorPoint end
    container.LayoutOrder = config.LayoutOrder or 0
    container.ZIndex = config.ZIndex or 5
    container.BackgroundTransparency = 1

    -- Track background
    local track = Instance.new("Frame")
    track.Name = "Track"
    track.Size = UDim2.fromScale(1, 1)
    track.BackgroundColor3 = config.TrackColor or UITheme.Colors.GlassElevated
    track.BackgroundTransparency = 0.35
    track.BorderSizePixel = 0
    track.Parent = container

    local tCorner = Instance.new("UICorner")
    tCorner.CornerRadius = UDim.new(0, cornerRadius)
    tCorner.Parent = track

    local tStroke = Instance.new("UIStroke")
    tStroke.Thickness = 1.0
    tStroke.Color = UITheme.Colors.BorderSubtle
    tStroke.Transparency = UITheme.Transparency.Stroke
    tStroke.Parent = track

    -- Fill Bar
    local currentRatio = math.clamp(config.Current / math.max(1, config.Max), 0, 1)
    local fill = Instance.new("Frame")
    fill.Name = "Fill"
    fill.Size = UDim2.new(currentRatio, 0, 1, 0)
    fill.BackgroundColor3 = config.FillColor or UITheme.Colors.EmberHot
    fill.BorderSizePixel = 0
    fill.Parent = track

    local fCorner = Instance.new("UICorner")
    fCorner.CornerRadius = UDim.new(0, cornerRadius)
    fCorner.Parent = fill

    local fGrad = Instance.new("UIGradient")
    fGrad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(200, 200, 200)),
    })
    fGrad.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.1),
        NumberSequenceKeypoint.new(1, 0.4),
    })
    fGrad.Parent = fill

    -- Optional Label / Text Readout
    local labelNode: TextLabel? = nil
    if config.Label or config.ShowPercent then
        labelNode = Instance.new("TextLabel")
        labelNode.Name = "Readout"
        labelNode.Size = UDim2.fromScale(1, 1)
        labelNode.BackgroundTransparency = 1
        labelNode.Font = UITheme.Fonts.Heading
        labelNode.TextColor3 = UITheme.Colors.TextPrimary
        labelNode.TextSize = math.clamp(height - 2, 9, 13)
        labelNode.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
        labelNode.TextStrokeTransparency = 0.5
        labelNode.ZIndex = track.ZIndex + 2
        labelNode.Text = config.Label or string.format("%d%%", math.floor(currentRatio * 100))
        labelNode.Parent = track
    end

    local barInstance: ProgressBarInstance = {
        Frame = container,
        SetProgress = function(current: number, max: number?, tweenTime: number?)
            local m = max or config.Max
            local ratio = math.clamp(current / math.max(1, m), 0, 1)
            local t = tweenTime or 0.22
            TweenService:Create(fill, TweenInfo.new(t, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                Size = UDim2.new(ratio, 0, 1, 0),
            }):Play()

            if labelNode then
                if config.ShowPercent then
                    labelNode.Text = string.format("%d%%", math.floor(ratio * 100))
                elseif config.Label then
                    labelNode.Text = string.format("%s (%d/%d)", config.Label, math.floor(current), math.floor(m))
                end
            end
        end,
        SetColor = function(color: Color3)
            fill.BackgroundColor3 = color
        end,
        Destroy = function()
            container:Destroy()
        end,
    }

    if config.Parent then
        container.Parent = config.Parent
    end

    return barInstance
end

return ProgressBar
