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

    -- Bottom Area: Status text + thin progress bar
    local statusLabel = Instance.new("TextLabel")
    statusLabel.Name = "StatusLabel"
    statusLabel.AnchorPoint = Vector2.new(0.5, 1)
    statusLabel.Position = UDim2.new(0.5, 0, 1, -52)
    statusLabel.Size = UDim2.new(0.8, 0, 0, 18)
    statusLabel.BackgroundTransparency = 1
    statusLabel.Font = Enum.Font.GothamMedium
    statusLabel.Text = "LOADING"
    statusLabel.TextColor3 = Color3.fromRGB(140, 140, 140)
    statusLabel.TextSize = 11
    statusLabel.TextXAlignment = Enum.TextXAlignment.Center
    statusLabel.ZIndex = 86
    statusLabel.Parent = container

    -- Track
    local track = Instance.new("Frame")
    track.Name = "Track"
    track.AnchorPoint = Vector2.new(0.5, 1)
    track.Position = UDim2.new(0.5, 0, 1, -28)
    track.Size = UDim2.new(0.36, 0, 0, 2)
    track.BackgroundColor3 = Color3.fromRGB(220, 220, 220)
    track.BorderSizePixel = 0
    track.ZIndex = 86
    track.Parent = container

    local trackCorner = Instance.new("UICorner")
    trackCorner.CornerRadius = UDim.new(1, 0)
    trackCorner.Parent = track

    -- Fill
    local fill = Instance.new("Frame")
    fill.Name = "Fill"
    fill.Size = UDim2.fromScale(0.02, 1)
    fill.BackgroundColor3 = Color3.fromRGB(200, 100, 30)
    fill.BorderSizePixel = 0
    fill.ZIndex = 87
    fill.Parent = track

    local fillCorner = Instance.new("UICorner")
    fillCorner.CornerRadius = UDim.new(1, 0)
    fillCorner.Parent = fill

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
        currentRatio = math.clamp(ratio, 0.02, 1)

        TweenService:Create(fill, TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            Size = UDim2.fromScale(currentRatio, 1),
        }):Play()

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
            setProgress(0.02, options and options.Status, options and options.Detail)
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
            container:Destroy()
        end,
    }
end

return LoadingScreen
