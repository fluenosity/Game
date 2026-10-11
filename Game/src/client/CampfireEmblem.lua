--!strict
--[[
    CampfireEmblem.lua
    Stylized graphic campfire emblem for "Don't Let the Fire Die".
    Features layered flame shapes, crossed logs, and warm atmospheric glow.
    
    ASSET WORKFLOW:
    When logo.png is uploaded to Roblox via the Creator Dashboard / Studio Asset Manager,
    set ROBLOX_ASSET_ID below to the resulting asset URI (e.g. "rbxassetid://123456789").
    If ROBLOX_ASSET_ID is left empty or nil, the high-fidelity UI-based graphic emblem
    is rendered seamlessly.
]]

local TweenService = game:GetService("TweenService")
local MenuTheme = require(script.Parent:WaitForChild("MenuTheme"))

local CampfireEmblem = {}
CampfireEmblem.__index = CampfireEmblem

-- Set to a valid Roblox asset ID once logo.png is uploaded (e.g. "rbxassetid://123456789")
-- Note: Never use local file paths (such as I:\RobloxDev\logo.png) directly in Roblox ImageLabels.
CampfireEmblem.ROBLOX_ASSET_ID = "" :: string

export type EmblemInstance = {
    Root: Frame,
    Aura: Frame,
    FlamesContainer: Frame?,
    ImageLabel: ImageLabel?,
    FlickerTweens: { Tween },
    ReducedMotion: boolean,
    
    SetReducedMotion: (self: EmblemInstance, enabled: boolean) -> (),
    Destroy: (self: EmblemInstance) -> (),
}

function CampfireEmblem.new(size: UDim2?): EmblemInstance
    local root = Instance.new("Frame")
    root.Name = "CampfireEmblem"
    root.Size = size or UDim2.fromOffset(130, 130)
    root.AnchorPoint = Vector2.new(0.5, 0.5)
    root.BackgroundTransparency = 1
    root.BorderSizePixel = 0

    local aspectRatio = Instance.new("UIAspectRatioConstraint")
    aspectRatio.AspectRatio = 1.0
    aspectRatio.Parent = root

    -- Warm radial aura glow
    local aura = Instance.new("Frame")
    aura.Name = "Aura"
    aura.Size = UDim2.fromScale(1.35, 1.35)
    aura.Position = UDim2.fromScale(0.5, 0.5)
    aura.AnchorPoint = Vector2.new(0.5, 0.5)
    aura.BackgroundColor3 = MenuTheme.Colors.FireEmber
    aura.BackgroundTransparency = 0.85
    aura.BorderSizePixel = 0
    aura.ZIndex = 1

    local auraCorner = Instance.new("UICorner")
    auraCorner.CornerRadius = UDim.new(1, 0)
    auraCorner.Parent = aura

    local auraGrad = Instance.new("UIGradient")
    auraGrad.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.5),
        NumberSequenceKeypoint.new(0.65, 0.85),
        NumberSequenceKeypoint.new(1, 1),
    })
    auraGrad.Parent = aura
    aura.Parent = root

    local flickerTweens: { Tween } = {}
    local flamesContainer: Frame? = nil
    local imageLabel: ImageLabel? = nil

    -- Check if valid Roblox uploaded asset ID is configured
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
    else
        -- Procedural Graphic Emblem (Campfire with crossed logs and layered stylized flames)
        local emblemArt = Instance.new("Frame")
        emblemArt.Name = "GraphicEmblemArt"
        emblemArt.Size = UDim2.fromScale(1, 1)
        emblemArt.Position = UDim2.fromScale(0.5, 0.5)
        emblemArt.AnchorPoint = Vector2.new(0.5, 0.5)
        emblemArt.BackgroundTransparency = 1
        emblemArt.ZIndex = 2
        emblemArt.Parent = root

        -- 1. BASE: Crossed Wood Logs
        local logsContainer = Instance.new("Frame")
        logsContainer.Name = "Logs"
        logsContainer.Size = UDim2.fromScale(0.9, 0.35)
        logsContainer.Position = UDim2.fromScale(0.5, 0.82)
        logsContainer.AnchorPoint = Vector2.new(0.5, 0.5)
        logsContainer.BackgroundTransparency = 1
        logsContainer.ZIndex = 3
        logsContainer.Parent = emblemArt

        -- Back Log (Angled left-down)
        local logBack = Instance.new("Frame")
        logBack.Name = "LogBack"
        logBack.Size = UDim2.fromScale(0.9, 0.38)
        logBack.Position = UDim2.fromScale(0.5, 0.45)
        logBack.AnchorPoint = Vector2.new(0.5, 0.5)
        logBack.Rotation = -20
        logBack.BackgroundColor3 = MenuTheme.Colors.WoodDark
        logBack.BorderSizePixel = 0
        logBack.ZIndex = 3

        local logBackCorner = Instance.new("UICorner")
        logBackCorner.CornerRadius = UDim.new(0.45, 0)
        logBackCorner.Parent = logBack
        logBack.Parent = logsContainer

        -- Back Log End Ring Cap
        local logBackCap = Instance.new("Frame")
        logBackCap.Name = "Cap"
        logBackCap.Size = UDim2.fromScale(0.24, 0.85)
        logBackCap.Position = UDim2.fromScale(0.02, 0.5)
        logBackCap.AnchorPoint = Vector2.new(0, 0.5)
        logBackCap.BackgroundColor3 = Color3.fromRGB(135, 84, 52)
        logBackCap.BorderSizePixel = 0
        logBackCap.ZIndex = 4

        local logBackCapCorner = Instance.new("UICorner")
        logBackCapCorner.CornerRadius = UDim.new(1, 0)
        logBackCapCorner.Parent = logBackCap
        logBackCap.Parent = logBack

        -- Front Log (Angled right-down)
        local logFront = Instance.new("Frame")
        logFront.Name = "LogFront"
        logFront.Size = UDim2.fromScale(0.92, 0.42)
        logFront.Position = UDim2.fromScale(0.5, 0.55)
        logFront.AnchorPoint = Vector2.new(0.5, 0.5)
        logFront.Rotation = 20
        logFront.BackgroundColor3 = MenuTheme.Colors.WoodBrown
        logFront.BorderSizePixel = 0
        logFront.ZIndex = 5

        local logFrontCorner = Instance.new("UICorner")
        logFrontCorner.CornerRadius = UDim.new(0.45, 0)
        logFrontCorner.Parent = logFront
        logFront.Parent = logsContainer

        -- Front Log End Ring Cap
        local logFrontCap = Instance.new("Frame")
        logFrontCap.Name = "Cap"
        logFrontCap.Size = UDim2.fromScale(0.24, 0.85)
        logFrontCap.Position = UDim2.fromScale(0.98, 0.5)
        logFrontCap.AnchorPoint = Vector2.new(1, 0.5)
        logFrontCap.BackgroundColor3 = Color3.fromRGB(152, 98, 62)
        logFrontCap.BorderSizePixel = 0
        logFrontCap.ZIndex = 6

        local logFrontCapCorner = Instance.new("UICorner")
        logFrontCapCorner.CornerRadius = UDim.new(1, 0)
        logFrontCapCorner.Parent = logFrontCap
        logFrontCap.Parent = logFront

        -- 2. FLAMES CONTAINER
        flamesContainer = Instance.new("Frame")
        flamesContainer.Name = "Flames"
        flamesContainer.Size = UDim2.fromScale(0.85, 0.72)
        flamesContainer.Position = UDim2.fromScale(0.5, 0.54)
        flamesContainer.AnchorPoint = Vector2.new(0.5, 0.5)
        flamesContainer.BackgroundTransparency = 1
        flamesContainer.ZIndex = 7
        flamesContainer.Parent = emblemArt

        -- Outer Flame Silhouette (Crimson Fire)
        local flameOuter = Instance.new("Frame")
        flameOuter.Name = "FlameOuter"
        flameOuter.Size = UDim2.fromScale(0.78, 0.95)
        flameOuter.Position = UDim2.fromScale(0.5, 0.52)
        flameOuter.AnchorPoint = Vector2.new(0.5, 0.5)
        flameOuter.BackgroundColor3 = MenuTheme.Colors.FireCrimson
        flameOuter.BorderSizePixel = 0
        flameOuter.ZIndex = 7

        local flameOuterCorner = Instance.new("UICorner")
        flameOuterCorner.CornerRadius = UDim.new(0.5, 0)
        flameOuterCorner.Parent = flameOuter

        local flameOuterGrad = Instance.new("UIGradient")
        flameOuterGrad.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, MenuTheme.Colors.FireHot),
            ColorSequenceKeypoint.new(0.5, MenuTheme.Colors.FireCrimson),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(140, 28, 12)),
        })
        flameOuterGrad.Rotation = 90
        flameOuterGrad.Parent = flameOuter
        flameOuter.Parent = flamesContainer

        -- Mid Flame (Vivid Orange)
        local flameMid = Instance.new("Frame")
        flameMid.Name = "FlameMid"
        flameMid.Size = UDim2.fromScale(0.58, 0.78)
        flameMid.Position = UDim2.fromScale(0.5, 0.6)
        flameMid.AnchorPoint = Vector2.new(0.5, 0.5)
        flameMid.BackgroundColor3 = MenuTheme.Colors.FireEmber
        flameMid.BorderSizePixel = 0
        flameMid.ZIndex = 8

        local flameMidCorner = Instance.new("UICorner")
        flameMidCorner.CornerRadius = UDim.new(0.48, 0)
        flameMidCorner.Parent = flameMid

        local flameMidGrad = Instance.new("UIGradient")
        flameMidGrad.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, MenuTheme.Colors.FireCore),
            ColorSequenceKeypoint.new(0.7, MenuTheme.Colors.FireHot),
            ColorSequenceKeypoint.new(1, MenuTheme.Colors.FireCrimson),
        })
        flameMidGrad.Rotation = 90
        flameMidGrad.Parent = flameMid
        flameMid.Parent = flamesContainer

        -- Inner Flame Heart (Golden Core)
        local flameCore = Instance.new("Frame")
        flameCore.Name = "FlameCore"
        flameCore.Size = UDim2.fromScale(0.35, 0.52)
        flameCore.Position = UDim2.fromScale(0.5, 0.72)
        flameCore.AnchorPoint = Vector2.new(0.5, 0.5)
        flameCore.BackgroundColor3 = MenuTheme.Colors.FireCore
        flameCore.BorderSizePixel = 0
        flameCore.ZIndex = 9

        local flameCoreCorner = Instance.new("UICorner")
        flameCoreCorner.CornerRadius = UDim.new(0.5, 0)
        flameCoreCorner.Parent = flameCore
        flameCore.Parent = flamesContainer

        -- Gentle idle campfire flicker tween
        local tweenInfo = TweenInfo.new(1.1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true)
        local flamePulse = TweenService:Create(flameMid, tweenInfo, {
            Size = UDim2.fromScale(0.61, 0.82),
            Position = UDim2.fromScale(0.5, 0.58),
        })
        local auraPulse = TweenService:Create(aura, tweenInfo, {
            Size = UDim2.fromScale(1.45, 1.45),
            BackgroundTransparency = 0.80,
        })

        table.insert(flickerTweens, flamePulse)
        table.insert(flickerTweens, auraPulse)

        flamePulse:Play()
        auraPulse:Play()
    end

    local self = setmetatable({}, CampfireEmblem) :: any
    self.Root = root
    self.Aura = aura
    self.FlamesContainer = flamesContainer
    self.ImageLabel = imageLabel
    self.FlickerTweens = flickerTweens
    self.ReducedMotion = false

    return self
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
