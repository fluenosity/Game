--!strict
--[[
    LoadingScreen.lua
    Production-grade cinematic glassmorphic loading screen for "Don't Let the Fire Die".
    Fluenosity Studio — Modular UI Library.

    Features:
    - Obsidian transition curtain with a subtle vignette over the live world.
    - Top-right glassmorphic Survival Intel banner with rotating tips.
    - Responsive center-bottom progress bar HUD with percentage readout.
    - Ember-pulsing animated loading spinner.
    - Smooth native fade curtain transitions (zero CanvasGroup downsampling blur).
]]

local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local UITheme = require(script.Parent:WaitForChild("UITheme"))
local IconPack = require(ReplicatedStorage:WaitForChild("FluenosityShared"):WaitForChild("IconPack"))

local SURVIVAL_TIPS = {
    "The campfire is your only safe haven. When it dies, the forest takes you.",
    "The Hollow avoids bright light, but tests the perimeter when embers dim.",
    "Wood is fuel and life. Scavenge nearby timber during the day.",
    "Never wander into the deep forest alone after dusk falls.",
    "Light Relays can be placed to carve safe corridors through the dark.",
    "Keep your ears open. Sound carries far in the frozen silence.",
}

export type LoadingSpinnerInstance = {
    Container: Frame,
    SetStatus: (status: string) -> (),
    Destroy: () -> (),
}

export type LoadingScreenInstance = {
    Container: Frame,
    Show: (options: { Status: string?, Tip: string?, Progress: number?, Detail: string? }?) -> (),
    SetProgress: (ratio: number, statusText: string?, detailText: string?) -> (),
    SetStatus: (statusText: string) -> (),
    SetTip: (tipText: string) -> (),
    Hide: (onCompleted: (() -> ())?) -> (),
    Destroy: () -> (),
}

local LoadingScreen = {}

function LoadingScreen.CreateSpinner(parent: Instance, initialStatus: string?): LoadingSpinnerInstance
    local container = Instance.new("Frame")
    container.Name = "LoadingSpinnerContainer"
    container.Size = UDim2.fromOffset(280, 36)
    container.BackgroundTransparency = 1
    container.ZIndex = 85
    container.Parent = parent

    -- Rotating Outer Ring
    local ring = Instance.new("Frame")
    ring.Name = "SpinnerRing"
    ring.Size = UDim2.fromOffset(26, 26)
    ring.Position = UDim2.new(0, 0, 0.5, 0)
    ring.AnchorPoint = Vector2.new(0, 0.5)
    ring.BackgroundTransparency = 1
    ring.ZIndex = 86
    ring.Parent = container

    local ringCorner = Instance.new("UICorner")
    ringCorner.CornerRadius = UDim.new(1, 0)
    ringCorner.Parent = ring

    local ringStroke = Instance.new("UIStroke")
    ringStroke.Color = UITheme.Colors.EmberHot
    ringStroke.Thickness = 2.4
    ringStroke.Parent = ring

    local ringGrad = Instance.new("UIGradient")
    ringGrad.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0),
        NumberSequenceKeypoint.new(0.4, 0.2),
        NumberSequenceKeypoint.new(0.8, 0.85),
        NumberSequenceKeypoint.new(1, 1),
    })
    ringGrad.Parent = ringStroke

    -- Center Glowing Ember Dot
    local centerDot = Instance.new("Frame")
    centerDot.Name = "CenterEmber"
    centerDot.Size = UDim2.fromOffset(6, 6)
    centerDot.Position = UDim2.fromScale(0.5, 0.5)
    centerDot.AnchorPoint = Vector2.new(0.5, 0.5)
    centerDot.BackgroundColor3 = UITheme.Colors.EmberGold
    centerDot.BorderSizePixel = 0
    centerDot.ZIndex = 87
    centerDot.Parent = ring

    local dotCorner = Instance.new("UICorner")
    dotCorner.CornerRadius = UDim.new(1, 0)
    dotCorner.Parent = centerDot

    -- Status Text beside spinner
    local statusLabel = Instance.new("TextLabel")
    statusLabel.Name = "StatusLabel"
    statusLabel.Size = UDim2.new(1, -38, 1, 0)
    statusLabel.Position = UDim2.new(0, 38, 0, 0)
    statusLabel.BackgroundTransparency = 1
    statusLabel.Font = UITheme.Fonts.Tag
    statusLabel.Text = initialStatus or "LOADING SECTOR..."
    statusLabel.TextColor3 = Color3.fromRGB(225, 230, 240)
    statusLabel.TextSize = 11
    statusLabel.TextXAlignment = Enum.TextXAlignment.Left
    statusLabel.ZIndex = 86
    statusLabel.Parent = container

    local spinConn: RBXScriptConnection? = RunService.RenderStepped:Connect(function(dt: number)
        ring.Rotation = (ring.Rotation + dt * 240) % 360
    end)

    local dotPulse = TweenService:Create(centerDot, TweenInfo.new(0.85, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {
        Size = UDim2.fromOffset(8, 8),
        BackgroundColor3 = UITheme.Colors.EmberPrimary,
    })
    dotPulse:Play()

    return {
        Container = container,
        SetStatus = function(status: string)
            statusLabel.Text = status
        end,
        Destroy = function()
            if spinConn then
                spinConn:Disconnect()
                spinConn = nil
            end
            dotPulse:Cancel()
            container:Destroy()
        end,
    }
end

function LoadingScreen.Create(parent: Instance): LoadingScreenInstance
    local container = Instance.new("Frame")
    container.Name = "CinematicLoadingScreen"
    container.Size = UDim2.fromScale(1, 1)
    container.Position = UDim2.fromScale(0, 0)
    container.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    container.BorderSizePixel = 0
    container.Visible = false
    container.ZIndex = 80
    container.Parent = parent

    -- Center: Game Title (Genshin clean minimal)
    local brandTitle = Instance.new("TextLabel")
    brandTitle.Name = "LoadingBrandTitle"
    brandTitle.AnchorPoint = Vector2.new(0.5, 0.5)
    brandTitle.Position = UDim2.fromScale(0.5, 0.5)
    brandTitle.Size = UDim2.new(0.9, 0, 0, 42)
    brandTitle.BackgroundTransparency = 1
    brandTitle.Font = Enum.Font.Oswald
    brandTitle.Text = "DON'T LET THE FIRE DIE"
    brandTitle.TextColor3 = Color3.fromRGB(28, 28, 28)
    brandTitle.TextScaled = false
    brandTitle.TextSize = 28
    brandTitle.ZIndex = 84
    brandTitle.Parent = container

    local titleConstraint = Instance.new("UITextSizeConstraint")
    titleConstraint.MinTextSize = 14
    titleConstraint.MaxTextSize = 32
    titleConstraint.Parent = brandTitle

    -- Bottom Area: status text, percentage, flat progress bar
    local TEXT_DARK = Color3.fromRGB(28, 28, 28)
    local TEXT_MUTED = Color3.fromRGB(120, 120, 120)

    local statusLabel = Instance.new("TextLabel")
    statusLabel.Name = "StatusLabel"
    statusLabel.AnchorPoint = Vector2.new(0.5, 1)
    statusLabel.Position = UDim2.new(0.5, 0, 1, -74)
    statusLabel.Size = UDim2.new(0.6, 0, 0, 20)
    statusLabel.BackgroundTransparency = 1
    statusLabel.Font = Enum.Font.GothamMedium
    statusLabel.Text = "LOADING"
    statusLabel.TextColor3 = TEXT_DARK
    statusLabel.TextSize = 15
    statusLabel.TextXAlignment = Enum.TextXAlignment.Center
    statusLabel.ZIndex = 86
    statusLabel.Parent = container

    local statusConstraint = Instance.new("UITextSizeConstraint")
    statusConstraint.MinTextSize = 12
    statusConstraint.MaxTextSize = 17
    statusConstraint.Parent = statusLabel

    local percentLabel = Instance.new("TextLabel")
    percentLabel.Name = "PercentLabel"
    percentLabel.AnchorPoint = Vector2.new(0.5, 1)
    percentLabel.Position = UDim2.new(0.5, 0, 1, -54)
    percentLabel.Size = UDim2.new(0.6, 0, 0, 18)
    percentLabel.BackgroundTransparency = 1
    percentLabel.Font = Enum.Font.Gotham
    percentLabel.Text = "0.00%"
    percentLabel.TextColor3 = TEXT_MUTED
    percentLabel.TextSize = 13
    percentLabel.ZIndex = 86
    percentLabel.Parent = container

    -- Track (flat, thick pill)
    local track = Instance.new("Frame")
    track.Name = "Track"
    track.AnchorPoint = Vector2.new(0.5, 1)
    track.Position = UDim2.new(0.5, 0, 1, -30)
    track.Size = UDim2.new(0.3, 0, 0, 10)
    track.BackgroundColor3 = Color3.fromRGB(225, 225, 225)
    track.BorderSizePixel = 0
    track.ZIndex = 86
    track.Parent = container

    local trackSizeLimit = Instance.new("UISizeConstraint")
    trackSizeLimit.MinSize = Vector2.new(200, 10)
    trackSizeLimit.MaxSize = Vector2.new(340, 10)
    trackSizeLimit.Parent = track

    local trackCorner = Instance.new("UICorner")
    trackCorner.CornerRadius = UDim.new(1, 0)
    trackCorner.Parent = track

    -- Small dots just outside both ends of the bar
    local function makeEndDot(name: string, xScale: number, xOffset: number)
        local dot = Instance.new("Frame")
        dot.Name = name
        dot.AnchorPoint = Vector2.new(0.5, 0.5)
        dot.Position = UDim2.new(xScale, xOffset, 0.5, 0)
        dot.Size = UDim2.fromOffset(5, 5)
        dot.BackgroundColor3 = TEXT_DARK
        dot.BorderSizePixel = 0
        dot.ZIndex = 86
        dot.Parent = track

        local endDotCorner = Instance.new("UICorner")
        endDotCorner.CornerRadius = UDim.new(1, 0)
        endDotCorner.Parent = dot
    end
    makeEndDot("StartDot", 0, -12)
    makeEndDot("EndDot", 1, 12)

    -- Fill (solid, flat). Swap to Color3.fromRGB(200, 100, 30) for an orange bar.
    local fill = Instance.new("Frame")
    fill.Name = "Fill"
    fill.Size = UDim2.fromScale(0.04, 1)
    fill.BackgroundColor3 = TEXT_DARK
    fill.BorderSizePixel = 0
    fill.ZIndex = 87
    fill.Parent = track

    local fillCorner = Instance.new("UICorner")
    fillCorner.CornerRadius = UDim.new(1, 0)
    fillCorner.Parent = fill

    -- Percentage counts up smoothly via a NumberValue
    local percentValue = Instance.new("NumberValue")
    percentValue.Value = 0
    percentValue.Changed:Connect(function(value: number)
        percentLabel.Text = string.format("%.2f%%", value)
    end)
    local percentTween: Tween? = nil

    -- Native Smooth Transition Curtain (pure white)
    local fadeCurtain = Instance.new("Frame")
    fadeCurtain.Name = "FadeCurtain"
    fadeCurtain.Size = UDim2.fromScale(1, 1)
    fadeCurtain.Position = UDim2.fromScale(0, 0)
    fadeCurtain.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    fadeCurtain.BackgroundTransparency = 0
    fadeCurtain.BorderSizePixel = 0
    fadeCurtain.ZIndex = 95
    fadeCurtain.Parent = container

    local isTransitioning = false
    local currentRatio = 0

    local function setProgress(ratio: number, statusText: string?, _detailText: string?)
        currentRatio = math.clamp(ratio, 0, 1)

        local info = TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
        TweenService:Create(fill, info, {
            Size = UDim2.fromScale(math.max(currentRatio, 0.04), 1),
        }):Play()

        if percentTween then
            percentTween:Cancel()
        end
        local tween = TweenService:Create(percentValue, info, { Value = currentRatio * 100 })
        percentTween = tween
        tween:Play()

        if statusText and statusText ~= "" then
            statusLabel.Text = statusText:upper()
        end
    end

    local function showLoading(options: { Status: string?, Tip: string?, Progress: number?, Detail: string? }?)
        if isTransitioning then return end
        isTransitioning = true

        if options and options.Status then
            statusLabel.Text = options.Status:upper()
        else
            statusLabel.Text = "LOADING"
        end

        if options and options.Progress then
            setProgress(options.Progress, options.Status, options.Detail)
        else
            setProgress(0, options and options.Status, options and options.Detail)
        end

        container.Visible = true
        fadeCurtain.BackgroundTransparency = 0

        local fadeTween = TweenService:Create(fadeCurtain, TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            BackgroundTransparency = 1,
        })
        fadeTween.Completed:Connect(function()
            isTransitioning = false
        end)
        fadeTween:Play()
    end

    local function hideLoading(onCompleted: (() -> ())?)
        if isTransitioning then return end
        isTransitioning = true

        local fadeTween = TweenService:Create(fadeCurtain, TweenInfo.new(0.45, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
            BackgroundTransparency = 0,
        })
        fadeTween.Completed:Connect(function()
            container.Visible = false
            isTransitioning = false
            if onCompleted then
                onCompleted()
            end
        end)
        fadeTween:Play()
    end

    return {
        Container = container,
        Show = showLoading,
        SetProgress = setProgress,
        SetStatus = function(statusText: string)
            if statusText and statusText ~= "" then
                statusLabel.Text = statusText:upper()
            end
        end,
        SetTip = function(_tipText: string)
            -- Minimal layout: no tips shown
        end,
        Hide = hideLoading,
        Destroy = function()
            percentValue:Destroy()
            container:Destroy()
        end,
    }
end

return LoadingScreen