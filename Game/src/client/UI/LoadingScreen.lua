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
    container.BackgroundColor3 = Color3.fromRGB(249, 247, 240)
    container.BorderSizePixel = 0
    container.Visible = false
    container.ZIndex = 80
    container.Parent = parent

    -- The loader uses a calm ivory page and does not depend on a thumbnail or video.
    local bgOverlay = Instance.new("Frame")
    bgOverlay.Name = "BgOverlay"
    bgOverlay.Size = UDim2.fromScale(1, 1)
    bgOverlay.BackgroundColor3 = Color3.fromRGB(249, 247, 240)
    bgOverlay.BackgroundTransparency = 0
    bgOverlay.BorderSizePixel = 0
    bgOverlay.ZIndex = 82
    bgOverlay.Parent = container

    local vigGrad = Instance.new("UIGradient")
    vigGrad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 254, 250)),
        ColorSequenceKeypoint.new(0.55, Color3.fromRGB(249, 247, 240)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(242, 238, 227)),
    })
    vigGrad.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0),
        NumberSequenceKeypoint.new(0.5, 0),
        NumberSequenceKeypoint.new(1, 0),
    })
    vigGrad.Rotation = 90
    vigGrad.Parent = bgOverlay

    local sigilRow = Instance.new("Frame")
    sigilRow.Name = "WildernessSigils"
    sigilRow.AnchorPoint = Vector2.new(0.5, 0.5)
    sigilRow.Position = UDim2.fromScale(0.5, 0.47)
    sigilRow.Size = UDim2.fromOffset(230, 28)
    sigilRow.BackgroundTransparency = 1
    sigilRow.ZIndex = 84
    sigilRow.Parent = container

    local sigilLayout = Instance.new("UIListLayout")
    sigilLayout.FillDirection = Enum.FillDirection.Horizontal
    sigilLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    sigilLayout.VerticalAlignment = Enum.VerticalAlignment.Center
    sigilLayout.Padding = UDim.new(0, 16)
    sigilLayout.Parent = sigilRow

    for index = 1, 5 do
        local sigil = Instance.new("Frame")
        sigil.Name = "Sigil" .. index
        sigil.Size = UDim2.fromOffset(index == 3 and 20 or 16, index == 3 and 20 or 16)
        sigil.Rotation = 45
        sigil.BackgroundColor3 = index == 3 and Color3.fromRGB(225, 142, 63) or Color3.fromRGB(155, 148, 132)
        sigil.BackgroundTransparency = index == 3 and 0.12 or 0.72
        sigil.BorderSizePixel = 0
        sigil.ZIndex = 85
        sigil.Parent = sigilRow
        local core = Instance.new("Frame")
        core.Name = "Core"
        core.AnchorPoint = Vector2.new(0.5, 0.5)
        core.Position = UDim2.fromScale(0.5, 0.5)
        core.Size = UDim2.fromOffset(index == 3 and 5 or 3, index == 3 and 5 or 3)
        core.BackgroundColor3 = Color3.fromRGB(255, 248, 229)
        core.BorderSizePixel = 0
        core.ZIndex = 86
        core.Parent = sigil
        local coreCorner = Instance.new("UICorner")
        coreCorner.CornerRadius = UDim.new(1, 0)
        coreCorner.Parent = core
    end

    local brandTitle = Instance.new("TextLabel")
    brandTitle.Name = "LoadingBrandTitle"
    brandTitle.AnchorPoint = Vector2.new(0.5, 0.5)
    brandTitle.Position = UDim2.fromScale(0.5, 0.535)
    brandTitle.Size = UDim2.new(0.9, 0, 0, 30)
    brandTitle.BackgroundTransparency = 1
    brandTitle.Font = Enum.Font.Oswald
    brandTitle.Text = "DON'T LET THE FIRE DIE"
    brandTitle.TextColor3 = Color3.fromRGB(54, 59, 59)
    brandTitle.TextSize = 22
    brandTitle.ZIndex = 84
    brandTitle.Parent = container

    local headphoneTip = Instance.new("TextLabel")
    headphoneTip.Name = "HeadphoneTip"
    headphoneTip.AnchorPoint = Vector2.new(0.5, 0.5)
    headphoneTip.Position = UDim2.fromScale(0.5, 0.835)
    headphoneTip.Size = UDim2.new(0.9, 0, 0, 20)
    headphoneTip.BackgroundTransparency = 1
    headphoneTip.Font = UITheme.Fonts.Body
    headphoneTip.Text = "HEADPHONES RECOMMENDED FOR THE WILDERNESS"
    headphoneTip.TextColor3 = Color3.fromRGB(127, 128, 123)
    headphoneTip.TextSize = 10
    headphoneTip.ZIndex = 86
    headphoneTip.Parent = container

    -- 3. Top-Right Content Banner with Horizontal Gradient Glass
    local topRightBanner = Instance.new("Frame")
    topRightBanner.Name = "TopRightBanner"
    topRightBanner.Size = UDim2.fromOffset(450, 86)
    topRightBanner.Position = UDim2.new(1, -32, 0, 32)
    topRightBanner.AnchorPoint = Vector2.new(1, 0)
    topRightBanner.BackgroundColor3 = Color3.fromRGB(8, 10, 14)
    topRightBanner.BorderSizePixel = 0
    topRightBanner.ZIndex = 83
    topRightBanner.Visible = false
    topRightBanner.Parent = container

    local bannerCorner = Instance.new("UICorner")
    bannerCorner.CornerRadius = UDim.new(0, 8)
    bannerCorner.Parent = topRightBanner

    local bannerGrad = Instance.new("UIGradient")
    bannerGrad.Rotation = 0
    bannerGrad.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 1.0),
        NumberSequenceKeypoint.new(0.25, 0.45),
        NumberSequenceKeypoint.new(0.65, 0.15),
        NumberSequenceKeypoint.new(1, 0.05),
    })
    bannerGrad.Parent = topRightBanner

    local bannerStroke = Instance.new("UIStroke")
    bannerStroke.Color = Color3.fromRGB(255, 190, 80)
    bannerStroke.Transparency = 0.90
    bannerStroke.Thickness = 1
    bannerStroke.Parent = topRightBanner

    local strokeGrad = Instance.new("UIGradient")
    strokeGrad.Rotation = 0
    strokeGrad.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 1.0),
        NumberSequenceKeypoint.new(0.35, 0.95),
        NumberSequenceKeypoint.new(1, 0.82),
    })
    strokeGrad.Parent = bannerStroke

    local bannerPadding = Instance.new("UIPadding")
    bannerPadding.PaddingTop = UDim.new(0, 12)
    bannerPadding.PaddingBottom = UDim.new(0, 12)
    bannerPadding.PaddingLeft = UDim.new(0, 26)
    bannerPadding.PaddingRight = UDim.new(0, 22)
    bannerPadding.Parent = topRightBanner

    local headerRow = Instance.new("Frame")
    headerRow.Name = "TipHeaderRow"
    headerRow.Size = UDim2.new(1, 0, 0, 16)
    headerRow.BackgroundTransparency = 1
    headerRow.ZIndex = 84
    headerRow.Parent = topRightBanner

    local tipIcon = IconPack.CreateIcon("radio", 13, Color3.fromRGB(245, 160, 40), 0)
    tipIcon.Position = UDim2.fromOffset(0, 1)
    tipIcon.ZIndex = 85
    tipIcon.Parent = headerRow

    local tipHeader = Instance.new("TextLabel")
    tipHeader.Name = "TipHeader"
    tipHeader.Size = UDim2.new(1, -20, 1, 0)
    tipHeader.Position = UDim2.fromOffset(20, 0)
    tipHeader.BackgroundTransparency = 1
    tipHeader.Font = UITheme.Fonts.Heading
    tipHeader.Text = "SURVIVAL INTEL"
    tipHeader.TextColor3 = Color3.fromRGB(245, 160, 40)
    tipHeader.TextSize = 12
    tipHeader.TextXAlignment = Enum.TextXAlignment.Left
    tipHeader.ZIndex = 85
    tipHeader.Parent = headerRow

    local tipBody = Instance.new("TextLabel")
    tipBody.Name = "TipBody"
    tipBody.Size = UDim2.new(1, 0, 0, 44)
    tipBody.Position = UDim2.fromOffset(0, 20)
    tipBody.BackgroundTransparency = 1
    tipBody.Font = UITheme.Fonts.Body
    tipBody.Text = SURVIVAL_TIPS[math.random(1, #SURVIVAL_TIPS)]
    tipBody.TextColor3 = Color3.fromRGB(225, 230, 240)
    tipBody.TextSize = 13
    tipBody.TextWrapped = true
    tipBody.TextXAlignment = Enum.TextXAlignment.Left
    tipBody.ZIndex = 84
    tipBody.Parent = topRightBanner

    -- 4. Center-Bottom Glowing Progress Bar HUD
    local progressHUD = Instance.new("Frame")
    progressHUD.Name = "ProgressHUD"
    progressHUD.Size = UDim2.new(0.68, 0, 0, 68)
    progressHUD.Position = UDim2.new(0.5, 0, 1, -48)
    progressHUD.AnchorPoint = Vector2.new(0.5, 1)
    progressHUD.BackgroundTransparency = 1
    progressHUD.ZIndex = 86
    progressHUD.Parent = container

    local hudConstraint = Instance.new("UISizeConstraint")
    hudConstraint.MaxSize = Vector2.new(720, 90)
    hudConstraint.MinSize = Vector2.new(280, 50)
    hudConstraint.Parent = progressHUD

    -- Top Row: Stage Name (Left) + Percentage (Right)
    local topRow = Instance.new("Frame")
    topRow.Name = "TopRow"
    topRow.Size = UDim2.new(1, 0, 0, 20)
    topRow.BackgroundTransparency = 1
    topRow.ZIndex = 87
    topRow.Parent = progressHUD

    local stageLabel = Instance.new("TextLabel")
    stageLabel.Name = "StageLabel"
    stageLabel.Size = UDim2.new(1, -70, 1, 0)
    stageLabel.Position = UDim2.new(0, 0, 0, 0)
    stageLabel.BackgroundTransparency = 1
    stageLabel.Font = UITheme.Fonts.Heading
    stageLabel.Text = "INITIALIZING WORLD..."
    stageLabel.TextColor3 = Color3.fromRGB(84, 91, 92)
    stageLabel.TextSize = 13
    stageLabel.TextXAlignment = Enum.TextXAlignment.Left
    stageLabel.ZIndex = 88
    stageLabel.Parent = topRow

    local percentLabel = Instance.new("TextLabel")
    percentLabel.Name = "PercentLabel"
    percentLabel.Size = UDim2.new(0, 60, 1, 0)
    percentLabel.Position = UDim2.new(1, 0, 0, 0)
    percentLabel.AnchorPoint = Vector2.new(1, 0)
    percentLabel.BackgroundTransparency = 1
    percentLabel.Font = UITheme.Fonts.Heading
    percentLabel.Text = "0%"
    percentLabel.TextColor3 = UITheme.Colors.EmberHot
    percentLabel.TextSize = 14
    percentLabel.TextXAlignment = Enum.TextXAlignment.Right
    percentLabel.ZIndex = 88
    percentLabel.Parent = topRow

    -- Progress Track Bar
    local trackBar = Instance.new("Frame")
    trackBar.Name = "TrackBar"
    trackBar.Size = UDim2.new(1, 0, 0, 8)
    trackBar.Position = UDim2.new(0, 0, 0, 25)
    trackBar.BackgroundColor3 = Color3.fromRGB(221, 217, 206)
    trackBar.BorderSizePixel = 0
    trackBar.ZIndex = 87
    trackBar.Parent = progressHUD

    local trackCorner = Instance.new("UICorner")
    trackCorner.CornerRadius = UDim.new(0, 4)
    trackCorner.Parent = trackBar

    local trackStroke = Instance.new("UIStroke")
    trackStroke.Color = Color3.fromRGB(245, 140, 40)
    trackStroke.Transparency = 0.82
    trackStroke.Thickness = 1
    trackStroke.Parent = trackBar

    -- Progress Fill Bar
    local fillBar = Instance.new("Frame")
    fillBar.Name = "FillBar"
    fillBar.Size = UDim2.new(0, 0, 1, 0)
    fillBar.BackgroundColor3 = Color3.fromRGB(255, 140, 30)
    fillBar.BorderSizePixel = 0
    fillBar.ZIndex = 88
    fillBar.Parent = trackBar

    local fillCorner = Instance.new("UICorner")
    fillCorner.CornerRadius = UDim.new(0, 4)
    fillCorner.Parent = fillBar

    local fillGrad = Instance.new("UIGradient")
    fillGrad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(180, 40, 15)),
        ColorSequenceKeypoint.new(0.65, Color3.fromRGB(255, 135, 25)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 235, 160)),
    })
    fillGrad.Parent = fillBar

    -- Leading edge glow head
    local glowHead = Instance.new("Frame")
    glowHead.Name = "GlowHead"
    glowHead.Size = UDim2.fromOffset(8, 8)
    glowHead.Position = UDim2.new(1, 0, 0.5, 0)
    glowHead.AnchorPoint = Vector2.new(0.5, 0.5)
    glowHead.BackgroundColor3 = Color3.fromRGB(255, 245, 210)
    glowHead.BorderSizePixel = 0
    glowHead.ZIndex = 89
    glowHead.Visible = false
    glowHead.Parent = fillBar

    local glowCorner = Instance.new("UICorner")
    glowCorner.CornerRadius = UDim.new(1, 0)
    glowCorner.Parent = glowHead

    -- Bottom Details Sub-Row
    local bottomRow = Instance.new("Frame")
    bottomRow.Name = "BottomRow"
    bottomRow.Size = UDim2.new(1, 0, 0, 18)
    bottomRow.Position = UDim2.new(0, 0, 0, 39)
    bottomRow.BackgroundTransparency = 1
    bottomRow.ZIndex = 87
    bottomRow.Parent = progressHUD

    local detailLabel = Instance.new("TextLabel")
    detailLabel.Name = "DetailLabel"
    detailLabel.Size = UDim2.new(0.65, 0, 1, 0)
    detailLabel.Position = UDim2.new(0, 0, 0, 0)
    detailLabel.BackgroundTransparency = 1
    detailLabel.Font = UITheme.Fonts.Body
    detailLabel.Text = "Synchronizing survival environment..."
    detailLabel.TextColor3 = Color3.fromRGB(116, 119, 113)
    detailLabel.TextSize = 11
    detailLabel.TextXAlignment = Enum.TextXAlignment.Left
    detailLabel.ZIndex = 88
    detailLabel.Parent = bottomRow

    local sectorLabel = Instance.new("TextLabel")
    sectorLabel.Name = "SectorLabel"
    sectorLabel.Size = UDim2.new(0.35, 0, 1, 0)
    sectorLabel.Position = UDim2.new(1, 0, 0, 0)
    sectorLabel.AnchorPoint = Vector2.new(1, 0)
    sectorLabel.BackgroundTransparency = 1
    sectorLabel.Font = UITheme.Fonts.Body
    sectorLabel.Text = "SECTOR // ALPINE WILDERNESS"
    sectorLabel.TextColor3 = Color3.fromRGB(150, 148, 137)
    sectorLabel.TextSize = 11
    sectorLabel.TextXAlignment = Enum.TextXAlignment.Right
    sectorLabel.ZIndex = 88
    sectorLabel.Parent = bottomRow

    -- 5. Bottom-Right Animated Spinner
    local spinnerHolder = Instance.new("Frame")
    spinnerHolder.Name = "SpinnerHolder"
    spinnerHolder.Size = UDim2.fromOffset(260, 38)
    spinnerHolder.Position = UDim2.new(1, -32, 1, -28)
    spinnerHolder.AnchorPoint = Vector2.new(1, 1)
    spinnerHolder.BackgroundTransparency = 1
    spinnerHolder.ZIndex = 85
    spinnerHolder.Visible = false
    spinnerHolder.Parent = container

    local spinner = LoadingScreen.CreateSpinner(spinnerHolder, "INITIALIZING WORLD...")

    -- 6. Native Smooth Transition Curtain
    local fadeCurtain = Instance.new("Frame")
    fadeCurtain.Name = "FadeCurtain"
    fadeCurtain.Size = UDim2.fromScale(1, 1)
    fadeCurtain.Position = UDim2.fromScale(0, 0)
    fadeCurtain.BackgroundColor3 = Color3.fromRGB(249, 247, 240)
    fadeCurtain.BackgroundTransparency = 0
    fadeCurtain.BorderSizePixel = 0
    fadeCurtain.ZIndex = 95
    fadeCurtain.Parent = container

    local isTransitioning = false
    local currentRatio = 0

    local function setProgress(ratio: number, statusText: string?, detailText: string?)
        currentRatio = math.clamp(ratio, 0, 1)
        glowHead.Visible = currentRatio > 0.01 and currentRatio < 0.99

        TweenService:Create(fillBar, TweenInfo.new(0.24, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            Size = UDim2.new(currentRatio, 0, 1, 0),
        }):Play()

        percentLabel.Text = string.format("%d%%", math.floor(currentRatio * 100))
        if statusText then
            stageLabel.Text = statusText:upper()
            spinner.SetStatus(statusText)
        end
        if detailText then
            detailLabel.Text = detailText
        end
    end

    local function showLoading(options: { Status: string?, Tip: string?, Progress: number?, Detail: string? }?)
        if isTransitioning then return end
        isTransitioning = true

        if options and options.Status then
            stageLabel.Text = options.Status:upper()
            spinner.SetStatus(options.Status)
        end
        if options and options.Detail then
            detailLabel.Text = options.Detail
        end
        if options and options.Progress then
            setProgress(options.Progress, options.Status, options.Detail)
        else
            setProgress(0, options and options.Status, options and options.Detail)
        end
        if options and options.Tip then
            headphoneTip.Text = options.Tip
        else
            headphoneTip.Text = SURVIVAL_TIPS[math.random(1, #SURVIVAL_TIPS)]
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
            stageLabel.Text = statusText:upper()
            spinner.SetStatus(statusText)
        end,
        SetTip = function(tipText: string)
            headphoneTip.Text = tipText
        end,
        Hide = hideLoading,
        Destroy = function()
            spinner.Destroy()
            container:Destroy()
        end,
    }
end

return LoadingScreen
