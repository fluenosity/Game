--!strict
--[[
    UI/UITheme.lua
    Unified Production-Grade Glassmorphism Design Tokens & Visual Primitives
    "Don't Let the Fire Die" — Fluenosity Studio
]]

local SoundService = game:GetService("SoundService")

local UITheme = {}

--------------------------------------------------------------------------------
-- 1. LUXURY GLASSMORPHISM COLOR PALETTE
--------------------------------------------------------------------------------
UITheme.Colors = {
    -- True Glassmorphism Surfaces (Translucent Obsidian & Deep Frost)
    GlassBackground = Color3.fromRGB(12, 16, 22),
    GlassElevated   = Color3.fromRGB(18, 24, 34),
    GlassSurface    = Color3.fromRGB(14, 18, 26),
    GlassModal      = Color3.fromRGB(10, 14, 20),
    GlassBackdrop   = Color3.fromRGB(4, 6, 10),
    GlassCardHover  = Color3.fromRGB(24, 32, 46),
    GlassActive     = Color3.fromRGB(30, 24, 20),

    -- Specular Glass Strokes & Hairline Borders
    BorderGlass     = Color3.fromRGB(160, 180, 210),
    BorderSubtle    = Color3.fromRGB(70, 85, 110),
    BorderEmber     = Color3.fromRGB(255, 145, 40),
    BorderActive    = Color3.fromRGB(255, 175, 60),
    BorderGlow      = Color3.fromRGB(255, 195, 80),
    BorderDanger    = Color3.fromRGB(255, 75, 75),

    -- Typography
    TextPrimary     = Color3.fromRGB(252, 252, 255),
    TextSecondary   = Color3.fromRGB(175, 185, 205),
    TextMuted       = Color3.fromRGB(110, 122, 142),
    TextEmber       = Color3.fromRGB(255, 160, 50),
    TextGold        = Color3.fromRGB(255, 215, 85),
    TextDanger      = Color3.fromRGB(255, 85, 85),
    TextSuccess     = Color3.fromRGB(90, 230, 145),

    -- Ember & Atmosphere
    EmberPrimary    = Color3.fromRGB(245, 125, 30),
    EmberHot        = Color3.fromRGB(255, 160, 45),
    EmberGold       = Color3.fromRGB(255, 215, 80),
    EmberCrimson    = Color3.fromRGB(205, 45, 25),

    -- Button Specific Tints
    ButtonPrimaryBg   = Color3.fromRGB(38, 26, 20),
    ButtonPrimaryStroke = Color3.fromRGB(245, 135, 35),
    ButtonSecondaryBg = Color3.fromRGB(18, 24, 34),
    ButtonSecondaryStroke = Color3.fromRGB(75, 90, 115),
    ButtonDangerBg    = Color3.fromRGB(36, 14, 16),
    ButtonDangerStroke = Color3.fromRGB(220, 55, 55),
    ButtonGhostBg     = Color3.fromRGB(255, 255, 255),
}

--------------------------------------------------------------------------------
-- 2. GLASS TRANSPARENCIES
--------------------------------------------------------------------------------
UITheme.Transparency = {
    ModalBackdrop = 0.40,
    ModalSurface  = 0.18,
    Card          = 0.28,
    CardElevated  = 0.20,
    Button        = 0.25,
    ButtonGhost   = 0.88,
    Stroke        = 0.65,
    StrokeSpecular= 0.35,
    StrokeSubtle  = 0.78,
    StrokeActive  = 0.10,
}

--------------------------------------------------------------------------------
-- 3. TYPOGRAPHY HIERARCHY
--------------------------------------------------------------------------------
UITheme.Fonts = {
    Title       = Enum.Font.GothamBold,
    Heading     = Enum.Font.GothamBold,
    Subheading  = Enum.Font.GothamMedium,
    Button      = Enum.Font.GothamBold,
    Body        = Enum.Font.Gotham,
    BodyMedium  = Enum.Font.GothamMedium,
    Caption     = Enum.Font.Gotham,
    Tag         = Enum.Font.GothamMedium,
    Code        = Enum.Font.Code,
    Mono        = Enum.Font.RobotoMono,
}

UITheme.FontSizes = {
    Hero        = 34,
    Title       = 24,
    Heading     = 18,
    Subheading  = 15,
    Button      = 14,
    Body        = 13,
    Caption     = 11,
    Badge       = 10,
}

--------------------------------------------------------------------------------
-- 4. TWEEN PROFILES
--------------------------------------------------------------------------------
UITheme.Tweens = {
    Snap    = TweenInfo.new(0.08, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
    Fast    = TweenInfo.new(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
    Normal  = TweenInfo.new(0.28, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
    Smooth  = TweenInfo.new(0.42, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out),
    Modal   = TweenInfo.new(0.32, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
}

--------------------------------------------------------------------------------
-- 5. GLASSMORPHISM HELPER (Specular gradient border + rounded acrylic)
--------------------------------------------------------------------------------
export type GlassOptions = {
    CornerRadius: number?,
    StrokeThickness: number?,
    StrokeColor: Color3?,
    StrokeTransparency: number?,
    IsActive: boolean?,
    SpecularAngle: number?,
}

function UITheme.ApplyGlass(frame: GuiObject, options: GlassOptions?)
    local opt = options or {}
    local cornerRadius = opt.CornerRadius or 12
    local strokeColor = opt.StrokeColor or (opt.IsActive and UITheme.Colors.BorderActive or UITheme.Colors.BorderGlass)
    local strokeTransparency = opt.StrokeTransparency or (opt.IsActive and UITheme.Transparency.StrokeActive or UITheme.Transparency.Stroke)
    local strokeThickness = opt.StrokeThickness or (opt.IsActive and 1.8 or 1.2)

    -- 1. Rounded Corner
    local corner = frame:FindFirstChildOfClass("UICorner") or Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, cornerRadius)
    corner.Parent = frame

    -- 2. Hairline Specular Stroke
    local stroke = frame:FindFirstChildOfClass("UIStroke") or Instance.new("UIStroke")
    stroke.Thickness = strokeThickness
    stroke.Color = strokeColor
    stroke.Transparency = strokeTransparency
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    stroke.Parent = frame

    -- 3. Specular Light Gradient on Stroke (Top-left light source reflection)
    local strokeGrad = stroke:FindFirstChildOfClass("UIGradient") or Instance.new("UIGradient")
    strokeGrad.Rotation = opt.SpecularAngle or 45
    if opt.IsActive then
        strokeGrad.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, UITheme.Colors.EmberGold),
            ColorSequenceKeypoint.new(0.5, UITheme.Colors.EmberHot),
            ColorSequenceKeypoint.new(1, UITheme.Colors.EmberPrimary),
        })
        strokeGrad.Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0),
            NumberSequenceKeypoint.new(0.5, 0.15),
            NumberSequenceKeypoint.new(1, 0.4),
        })
    else
        strokeGrad.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(240, 245, 255)),
            ColorSequenceKeypoint.new(0.4, Color3.fromRGB(150, 175, 205)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(50, 65, 85)),
        })
        strokeGrad.Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.2),
            NumberSequenceKeypoint.new(0.5, 0.55),
            NumberSequenceKeypoint.new(1, 0.85),
        })
    end
    strokeGrad.Parent = stroke

    -- 4. Subtle frosted inner sheen gradient on background
    if frame:IsA("Frame") or frame:IsA("TextButton") or frame:IsA("ImageButton") then
        local bgGrad = frame:FindFirstChild("GlassSheen") :: UIGradient? or Instance.new("UIGradient")
        bgGrad.Name = "GlassSheen"
        bgGrad.Rotation = 90
        bgGrad.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(180, 195, 215)),
        })
        bgGrad.Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0),
            NumberSequenceKeypoint.new(0.12, 0.25),
            NumberSequenceKeypoint.new(1, 0.75),
        })
        bgGrad.Parent = frame
    end
end

--------------------------------------------------------------------------------
-- 6. PLEASANT AUDIO HOOKS (No ear-blasting, no annoying hover chirps)
--------------------------------------------------------------------------------
function UITheme.PlayClick()
    task.spawn(function()
        local success, audio = pcall(function()
            return require(script.Parent.Parent:WaitForChild("AudioManager"))
        end)
        if success and audio and audio.Play then
            pcall(function() audio.Play("Click") end)
        end
    end)
end

function UITheme.PlayClose()
    task.spawn(function()
        local success, audio = pcall(function()
            return require(script.Parent.Parent:WaitForChild("AudioManager"))
        end)
        if success and audio and audio.Play then
            pcall(function() audio.Play("InventoryClose") end)
        end
    end)
end

--------------------------------------------------------------------------------
-- 7. SOUND GROUPS & VOLUME CONTROLS (AGENTS.md Directive #5)
--------------------------------------------------------------------------------
local SoundService = game:GetService("SoundService")
local UserInputService = game:GetService("UserInputService")

local function getOrCreateSoundGroup(name: string, parent: Instance?): SoundGroup
    local p = parent or SoundService
    local found = p:FindFirstChild(name)
    if found and found:IsA("SoundGroup") then
        return found
    end
    local group = Instance.new("SoundGroup")
    group.Name = name
    group.Volume = 1
    group.Parent = p
    return group
end

function UITheme.GetMasterSoundGroup(): SoundGroup
    return getOrCreateSoundGroup("MasterSoundGroup", SoundService)
end

function UITheme.GetSFXSoundGroup(): SoundGroup
    local master = UITheme.GetMasterSoundGroup()
    return getOrCreateSoundGroup("SFXSoundGroup", master)
end

function UITheme.GetMusicSoundGroup(): SoundGroup
    local master = UITheme.GetMasterSoundGroup()
    return getOrCreateSoundGroup("MusicSoundGroup", master)
end

function UITheme.GetEnvironmentSoundGroup(): SoundGroup
    local master = UITheme.GetMasterSoundGroup()
    return getOrCreateSoundGroup("EnvironmentSoundGroup", master)
end

local audioRoutingInitialized = false
function UITheme.InitAudioRouting()
    if audioRoutingInitialized then return end
    audioRoutingInitialized = true

    local master = UITheme.GetMasterSoundGroup()
    local sfx = UITheme.GetSFXSoundGroup()
    local music = UITheme.GetMusicSoundGroup()
    local env = UITheme.GetEnvironmentSoundGroup()

    local function routeSound(sound: Instance)
        if sound:IsA("Sound") and (sound.SoundGroup == nil or sound.SoundGroup == master) then
            local name = sound.Name:lower()
            if name:find("music") or name:find("theme") or name:find("soundtrack") or name:find("song") then
                sound.SoundGroup = music
            elseif name:find("cricket") or name:find("fire") or name:find("wind") or name:find("ambient") or sound:IsDescendantOf(workspace) then
                sound.SoundGroup = env
            else
                sound.SoundGroup = sfx
            end
        end
    end

    for _, obj in ipairs(SoundService:GetDescendants()) do
        routeSound(obj)
    end
    for _, obj in ipairs(workspace:GetDescendants()) do
        routeSound(obj)
    end

    SoundService.DescendantAdded:Connect(routeSound)
    workspace.DescendantAdded:Connect(routeSound)
end

function UITheme.SetMasterVolume(volume: number)
    local clamped = math.clamp(volume, 0, 1)
    UITheme.GetMasterSoundGroup().Volume = clamped
end

function UITheme.GetMasterVolume(): number
    return UITheme.GetMasterSoundGroup().Volume
end

function UITheme.SetSFXVolume(volume: number)
    local clamped = math.clamp(volume, 0, 1)
    UITheme.GetSFXSoundGroup().Volume = clamped
end

function UITheme.GetSFXVolume(): number
    return UITheme.GetSFXSoundGroup().Volume
end

function UITheme.SetMusicVolume(volume: number)
    local clamped = math.clamp(volume, 0, 1)
    UITheme.GetMusicSoundGroup().Volume = clamped
end

function UITheme.GetMusicVolume(): number
    return UITheme.GetMusicSoundGroup().Volume
end

function UITheme.SetEnvironmentVolume(volume: number)
    local clamped = math.clamp(volume, 0, 1)
    UITheme.GetEnvironmentSoundGroup().Volume = clamped
end

function UITheme.GetEnvironmentVolume(): number
    return UITheme.GetEnvironmentSoundGroup().Volume
end

-- Camera Mouse Look Sensitivity (0.2x to 3.0x, default 1.0x)
local currentSensitivity = 1.0

function UITheme.SetMouseSensitivity(sens: number)
    local clamped = math.clamp(sens, 0.2, 3.0)
    currentSensitivity = clamped
    pcall(function()
        UserInputService.MouseDeltaSensitivity = clamped
    end)
end

function UITheme.GetMouseSensitivity(): number
    return UserInputService.MouseDeltaSensitivity or currentSensitivity
end

--------------------------------------------------------------------------------
-- 8. GLOBAL ASSETS REGISTRY (Main Menu Art, Game Logo, Posters)
--------------------------------------------------------------------------------
UITheme.Assets = {
    MainMenuVideo = "rbxasset://MainMenuMp4.mp4",        -- Animated Cinematic Background Video
    MainMenuBackground = "rbxassetid://77749440485321", -- Fallback Forest Campfire Thumbnail
    GameLogo = "rbxassetid://106299822759980",           -- Stylized Campfire Emblem Icon
}

function UITheme.GetBackgroundVideo(): string?
    if UITheme.Assets.MainMenuVideo and UITheme.Assets.MainMenuVideo ~= "" then
        return UITheme.Assets.MainMenuVideo
    end
    return nil
end

function UITheme.GetBackgroundAsset(): string
    if string.find(UITheme.Assets.MainMenuBackground, "rbxassetid://") then
        return UITheme.Assets.MainMenuBackground
    end
    if game.PlaceId > 0 then
        return string.format("rbxthumb://type=GameThumbnail&id=%d&w=768&h=432", game.PlaceId)
    end
    return UITheme.Assets.MainMenuBackground
end

function UITheme.GetLogoAsset(): string
    if string.find(UITheme.Assets.GameLogo, "rbxassetid://") then
        return UITheme.Assets.GameLogo
    end
    local targetId = if game.GameId > 0 then game.GameId else game.PlaceId
    if targetId > 0 then
        return string.format("rbxthumb://type=GameIcon&id=%d&w=150&h=150", targetId)
    end
    return UITheme.Assets.GameLogo
end

return UITheme

