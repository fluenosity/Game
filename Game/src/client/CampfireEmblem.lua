--!strict
--[[
    CampfireEmblem.lua
    Razor-sharp stylized graphic campfire emblem for "Don't Let the Fire Die".
    Crafted with native Luau UI vector primitives, multi-layer gradient flames,
    crossed timber logs, and warm atmospheric firelight glow.
    
    Rendered with native vector geometry—NO CanvasGroup rasterization blur!
]]

local TweenService = game:GetService("TweenService")
local UITheme = require(script.Parent:WaitForChild("UITheme"))

local CampfireEmblem = {}
CampfireEmblem.__index = CampfireEmblem

-- Set to a valid Roblox asset ID once logo.png is uploaded (e.g. "rbxassetid://123456789")
CampfireEmblem.ROBLOX_ASSET_ID = ""

export type EmblemInstance = {
    Root: Frame,
    Aura: Frame,
    ArtContainer: Frame?,
    ImageLabel: ImageLabel?,
    FlickerTweens: { Tween },
    FadingElements: { { Object: GuiObject, BaseTransparency: number } },
    ReducedMotion: boolean,
    
    SetTransparency: (self: EmblemInstance, alpha: number) -> (),
    AnimateFade: (self: EmblemInstance, targetAlpha: number, tweenInfo: TweenInfo) -> Tween?,
    SetReducedMotion: (self: EmblemInstance, enabled: boolean) -> (),
    Destroy: (self: EmblemInstance) -> (),
}

function CampfireEmblem.new(size: UDim2?): EmblemInstance
    local root = Instance.new("Frame")
    root.Name = "CampfireEmblem"
    root.Size = size or UDim2.fromOffset(140, 140)
    root.AnchorPoint = Vector2.new(0.5, 0.5)
    root.BackgroundTransparency = 1
    root.BorderSizePixel = 0

    local aspectRatio = Instance.new("UIAspectRatioConstraint")
    aspectRatio.AspectRatio = 1.0
    aspectRatio.Parent = root

    -- Warm radial aura glow
    local aura = Instance.new("Frame")
    aura.Name = "Aura"
    aura.Size = UDim2.fromScale(1.4, 1.4)
    aura.Position = UDim2.fromScale(0.5, 0.5)
    aura.AnchorPoint = Vector2.new(0.5, 0.5)
    aura.BackgroundColor3 = UITheme.Colors.EmberPrimary
    aura.BackgroundTransparency = 0.88
    aura.BorderSizePixel = 0
    aura.ZIndex = 1

    local auraCorner = Instance.new("UICorner")
    auraCorner.CornerRadius = UDim.new(1, 0)
    auraCorner.Parent = aura

    local auraGrad = Instance.new("UIGradient")
    auraGrad.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.4),
        NumberSequenceKeypoint.new(0.65, 0.85),
        NumberSequenceKeypoint.new(1, 1),
    })
    auraGrad.Parent = aura
    aura.Parent = root

    local flickerTweens: { Tween } = {}
    local fadingElements: { { Object: GuiObject, BaseTransparency: number } } = {
        { Object = aura, BaseTransparency = 0.88 },
    }
    local artContainer: Frame? = nil
    local imageLabel: ImageLabel? = nil

    if CampfireEmblem.ROBLOX_ASSET_ID and CampfireEmblem.ROBLOX_ASSET_ID ~= "" then
        imageLabel = Instance.new("ImageLabel")
        imageLabel.Name = "UploadedLogo"
        imageLabel.Size = UDim2.fromScale(1, 1)
        imageLabel.Position = UDim2.fromScale(0.5, 0.5)
        imageLabel.AnchorPoint = Vector2.new(0.5, 0.5)
        imageLabel.BackgroundTransparency = 1
        imageLabel.Image = CampfireEmblem.ROBLOX_ASSET_ID
        imageLabel.ScaleType = Enum.ScaleType.Fit
        imageLabel.ZIndex = 2
        imageLabel.Parent = root

        table.insert(fadingElements, { Object = imageLabel, BaseTransparency = 0 })
    else
        artContainer = Instance.new("Frame")
        artContainer.Name = "GraphicEmblemArt"
        artContainer.Size = UDim2.fromScale(1, 1)
        artContainer.Position = UDim2.fromScale(0.5, 0.5)
        artContainer.AnchorPoint = Vector2.new(0.5, 0.5)
        artContainer.BackgroundTransparency = 1
        artContainer.ZIndex = 2
        artContainer.Parent = root

        -- 1. BASE: Crossed Wood Logs
        local logsContainer = Instance.new("Frame")
        logsContainer.Name = "Logs"
        logsContainer.Size = UDim2.fromScale(0.92, 0.36)
        logsContainer.Position = UDim2.fromScale(0.5, 0.82)
        logsContainer.AnchorPoint = Vector2.new(0.5, 0.5)
        logsContainer.BackgroundTransparency = 1
        logsContainer.ZIndex = 3
        logsContainer.Parent = artContainer

        -- Back Log
        local logBack = Instance.new("Frame")
        logBack.Name = "LogBack"
        logBack.Size = UDim2.fromScale(0.92, 0.40)
        logBack.Position = UDim2.fromScale(0.5, 0.46)
        logBack.AnchorPoint = Vector2.new(0.5, 0.5)
        logBack.Rotation = -20
        logBack.BackgroundColor3 = UITheme.Colors.WoodCharcoal
        logBack.BorderSizePixel = 0
        logBack.ZIndex = 3

        local logBackCorner = Instance.new("UICorner")
        logBackCorner.CornerRadius = UDim.new(0.45, 0)
        logBackCorner.Parent = logBack
        logBack.Parent = logsContainer
        table.insert(fadingElements, { Object = logBack, BaseTransparency = 0 })

        -- Back Log End Cap Ring
        local logBackCap = Instance.new("Frame")
        logBackCap.Name = "Cap"
        logBackCap.Size = UDim2.fromScale(0.24, 0.88)
        logBackCap.Position = UDim2.fromScale(0.02, 0.5)
        logBackCap.AnchorPoint = Vector2.new(0, 0.5)
        logBackCap.BackgroundColor3 = Color3.fromRGB(130, 80, 50)
        logBackCap.BorderSizePixel = 0
        logBackCap.ZIndex = 4

        local logBackCapCorner = Instance.new("UICorner")
        logBackCapCorner.CornerRadius = UDim.new(1, 0)
        logBackCapCorner.Parent = logBackCap
        logBackCap.Parent = logBack
        table.insert(fadingElements, { Object = logBackCap, BaseTransparency = 0 })

        -- Front Log
        local logFront = Instance.new("Frame")
        logFront.Name = "LogFront"
        logFront.Size = UDim2.fromScale(0.94, 0.44)
        logFront.Position = UDim2.fromScale(0.5, 0.56)
        logFront.AnchorPoint = Vector2.new(0.5, 0.5)
        logFront.Rotation = 20
        logFront.BackgroundColor3 = UITheme.Colors.WoodCedar
        logFront.BorderSizePixel = 0
        logFront.ZIndex = 5

        local logFrontCorner = Instance.new("UICorner")
        logFrontCorner.CornerRadius = UDim.new(0.45, 0)
        logFrontCorner.Parent = logFront
        logFront.Parent = logsContainer
        table.insert(fadingElements, { Object = logFront, BaseTransparency = 0 })

        -- Front Log End Cap Ring
        local logFrontCap = Instance.new("Frame")
        logFrontCap.Name = "Cap"
        logFrontCap.Size = UDim2.fromScale(0.24, 0.88)
        logFrontCap.Position = UDim2.fromScale(0.98, 0.5)
        logFrontCap.AnchorPoint = Vector2.new(1, 0.5)
        logFrontCap.BackgroundColor3 = Color3.fromRGB(156, 100, 64)
        logFrontCap.BorderSizePixel = 0
        logFrontCap.ZIndex = 6

        local logFrontCapCorner = Instance.new("UICorner")
        logFrontCapCorner.CornerRadius = UDim.new(1, 0)
        logFrontCapCorner.Parent = logFrontCap
        logFrontCap.Parent = logFront
        table.insert(fadingElements, { Object = logFrontCap, BaseTransparency = 0 })

        -- 2. FLAMES CONTAINER
        local flamesContainer = Instance.new("Frame")
        flamesContainer.Name = "Flames"
        flamesContainer.Size = UDim2.fromScale(0.86, 0.74)
        flamesContainer.Position = UDim2.fromScale(0.5, 0.52)
        flamesContainer.AnchorPoint = Vector2.new(0.5, 0.5)
        flamesContainer.BackgroundTransparency = 1
        flamesContainer.ZIndex = 7
        flamesContainer.Parent = artContainer

        -- Outer Flame Silhouette (Crimson Fire)
        local flameOuter = Instance.new("Frame")
        flameOuter.Name = "FlameOuter"
        flameOuter.Size = UDim2.fromScale(0.78, 0.95)
        flameOuter.Position = UDim2.fromScale(0.5, 0.52)
        flameOuter.AnchorPoint = Vector2.new(0.5, 0.5)
        flameOuter.BackgroundColor3 = UITheme.Colors.EmberCrimson
        flameOuter.BorderSizePixel = 0
        flameOuter.ZIndex = 7

        local flameOuterCorner = Instance.new("UICorner")
        flameOuterCorner.CornerRadius = UDim.new(0.5, 0)
        flameOuterCorner.Parent = flameOuter

        local flameOuterGrad = Instance.new("UIGradient")
        flameOuterGrad.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, UITheme.Colors.EmberHot),
            ColorSequenceKeypoint.new(0.5, UITheme.Colors.EmberCrimson),
            ColorSequenceKeypoint.new(1, UITheme.Colors.EmberDeep),
        })
        flameOuterGrad.Rotation = 90
        flameOuterGrad.Parent = flameOuter
        flameOuter.Parent = flamesContainer
        table.insert(fadingElements, { Object = flameOuter, BaseTransparency = 0 })

        -- Mid Flame (Vivid Orange)
        local flameMid = Instance.new("Frame")
        flameMid.Name = "FlameMid"
        flameMid.Size = UDim2.fromScale(0.58, 0.78)
        flameMid.Position = UDim2.fromScale(0.5, 0.6)
        flameMid.AnchorPoint = Vector2.new(0.5, 0.5)
        flameMid.BackgroundColor3 = UITheme.Colors.EmberPrimary
        flameMid.BorderSizePixel = 0
        flameMid.ZIndex = 8

        local flameMidCorner = Instance.new("UICorner")
        flameMidCorner.CornerRadius = UDim.new(0.48, 0)
        flameMidCorner.Parent = flameMid

        local flameMidGrad = Instance.new("UIGradient")
        flameMidGrad.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, UITheme.Colors.EmberGold),
            ColorSequenceKeypoint.new(0.7, UITheme.Colors.EmberHot),
            ColorSequenceKeypoint.new(1, UITheme.Colors.EmberCrimson),
        })
        flameMidGrad.Rotation = 90
        flameMidGrad.Parent = flameMid
        flameMid.Parent = flamesContainer
        table.insert(fadingElements, { Object = flameMid, BaseTransparency = 0 })

        -- Inner Flame Heart (Golden Core)
        local flameCore = Instance.new("Frame")
        flameCore.Name = "FlameCore"
        flameCore.Size = UDim2.fromScale(0.35, 0.52)
        flameCore.Position = UDim2.fromScale(0.5, 0.72)
        flameCore.AnchorPoint = Vector2.new(0.5, 0.5)
        flameCore.BackgroundColor3 = UITheme.Colors.EmberGold
        flameCore.BorderSizePixel = 0
        flameCore.ZIndex = 9

        local flameCoreCorner = Instance.new("UICorner")
        flameCoreCorner.CornerRadius = UDim.new(0.5, 0)
        flameCoreCorner.Parent = flameCore
        flameCore.Parent = flamesContainer
        table.insert(fadingElements, { Object = flameCore, BaseTransparency = 0 })

        -- Gentle idle campfire flicker tween
        local tweenInfo = TweenInfo.new(1.1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true)
        local flamePulse = TweenService:Create(flameMid, tweenInfo, {
            Size = UDim2.fromScale(0.61, 0.82),
            Position = UDim2.fromScale(0.5, 0.58),
        })
        local auraPulse = TweenService:Create(aura, tweenInfo, {
            Size = UDim2.fromScale(1.48, 1.48),
            BackgroundTransparency = 0.82,
        })

        table.insert(flickerTweens, flamePulse)
        table.insert(flickerTweens, auraPulse)

        flamePulse:Play()
        auraPulse:Play()
    end

    local self = setmetatable({}, CampfireEmblem) :: any
    self.Root = root
    self.Aura = aura
    self.ArtContainer = artContainer
    self.ImageLabel = imageLabel
    self.FlickerTweens = flickerTweens
    self.FadingElements = fadingElements
    self.ReducedMotion = false

    return self
end

function CampfireEmblem.SetTransparency(self: EmblemInstance, alpha: number)
    local clamped = math.clamp(alpha, 0, 1)
    for _, item in ipairs(self.FadingElements) do
        local target = item.BaseTransparency + (1 - item.BaseTransparency) * clamped
        if item.Object:IsA("ImageLabel") then
            item.Object.ImageTransparency = target
        else
            item.Object.BackgroundTransparency = target
        end
    end
end

function CampfireEmblem.AnimateFade(self: EmblemInstance, targetAlpha: number, tweenInfo: TweenInfo): Tween?
    local lastTween: Tween? = nil
    for _, item in ipairs(self.FadingElements) do
        local target = item.BaseTransparency + (1 - item.BaseTransparency) * targetAlpha
        if item.Object:IsA("ImageLabel") then
            lastTween = TweenService:Create(item.Object, tweenInfo, { ImageTransparency = target })
        else
            lastTween = TweenService:Create(item.Object, tweenInfo, { BackgroundTransparency = target })
        end
        if lastTween then
            lastTween:Play()
        end
    end
    return lastTween
end

function CampfireEmblem.SetReducedMotion(self: EmblemInstance, enabled: boolean)
    self.ReducedMotion = enabled
    for _, tw in ipairs(self.FlickerTweens) do
        if enabled then
            tw:Pause()
        else
            tw:Play()
        end
    end
end

function CampfireEmblem.Destroy(self: EmblemInstance)
    for _, tw in ipairs(self.FlickerTweens) do
        tw:Cancel()
    end
    table.clear(self.FlickerTweens)
    self.Root:Destroy()
end

return CampfireEmblem
