--!strict
--[[
    UITheme.lua
    Production-grade design tokens, dark horror color palette, typography tokens,
    animation curves, and audio management for "Don't Let the Fire Die".
    Developed for Fluenosity Studio.
]]

local SoundService = game:GetService("SoundService")

local UITheme = {}

--------------------------------------------------------------------------------
-- COLOR PALETTE (Dark Atmospheric Survival Horror)
--------------------------------------------------------------------------------
UITheme.Colors = {
    -- Base Canvas & Surface
    PureWhite = Color3.fromRGB(255, 255, 255),
    PureBlack = Color3.fromRGB(0, 0, 0),
    Void = Color3.fromRGB(6, 6, 8),
    BackgroundDark = Color3.fromRGB(10, 9, 12),
    Surface = Color3.fromRGB(16, 15, 18),
    SurfaceElevated = Color3.fromRGB(22, 20, 24),
    SurfaceHighlight = Color3.fromRGB(30, 27, 32),

    -- Hairline Borders & Dividers
    BorderHairline = Color3.fromRGB(42, 36, 34),
    BorderSubtle = Color3.fromRGB(64, 52, 46),
    BorderHover = Color3.fromRGB(180, 80, 26),
    BorderActive = Color3.fromRGB(245, 115, 30),
    BorderGlow = Color3.fromRGB(255, 140, 40),

    -- Typography Colors
    TextStudioSplash = Color3.fromRGB(20, 20, 24),
    TextPrimary = Color3.fromRGB(248, 245, 240),
    TextSecondary = Color3.fromRGB(180, 172, 165),
    TextMuted = Color3.fromRGB(120, 112, 106),
    TextSubdued = Color3.fromRGB(85, 78, 74),
    TextEmberAccent = Color3.fromRGB(255, 150, 50),

    -- Campfire & Ember Accents
    EmberPrimary = Color3.fromRGB(245, 115, 28),
    EmberHot = Color3.fromRGB(255, 160, 45),
    EmberGold = Color3.fromRGB(255, 215, 80),
    EmberCrimson = Color3.fromRGB(195, 42, 18),
    EmberDeep = Color3.fromRGB(130, 24, 12),
    WoodCedar = Color3.fromRGB(115, 68, 42),
    WoodCharcoal = Color3.fromRGB(75, 44, 28),

    -- Button Specific Tokens
    ButtonPrimaryBg = Color3.fromRGB(32, 24, 22),
    ButtonPrimaryHover = Color3.fromRGB(46, 32, 28),
    ButtonPrimaryBorder = Color3.fromRGB(185, 78, 24),
    ButtonSecondaryBg = Color3.fromRGB(20, 18, 22),
    ButtonSecondaryHover = Color3.fromRGB(30, 26, 30),
    ButtonSecondaryBorder = Color3.fromRGB(56, 48, 46),
    ButtonPressed = Color3.fromRGB(14, 12, 14),
}

--------------------------------------------------------------------------------
-- TYPOGRAPHY HIERARCHY (Gotham Unified Project-Wide Standard)
--------------------------------------------------------------------------------
UITheme.Fonts = {
    Title = Enum.Font.GothamBold,
    Heading = Enum.Font.GothamBold,
    Subheading = Enum.Font.GothamMedium,
    Button = Enum.Font.GothamBold,
    ButtonSub = Enum.Font.Gotham,
    Body = Enum.Font.Gotham,
    Studio = Enum.Font.GothamMedium,
    Tag = Enum.Font.Gotham,            -- Gotham Regular (Type in ALL CAPS)
    SmallLabel = Enum.Font.Gotham,     -- Gotham Regular (Type in ALL CAPS)
    Regular = Enum.Font.Gotham,
    Medium = Enum.Font.GothamMedium,
    Bold = Enum.Font.GothamBold,
    Black = Enum.Font.GothamBlack,
}

--------------------------------------------------------------------------------
-- TWEEN PROFILES
--------------------------------------------------------------------------------
UITheme.Tweens = {
    Instant = TweenInfo.new(0.08, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
    Fast = TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
    Normal = TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
    Smooth = TweenInfo.new(0.55, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out),
    Cinematic = TweenInfo.new(0.9, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut),
    Fade = TweenInfo.new(0.4, Enum.EasingStyle.Linear),
}

--------------------------------------------------------------------------------
-- MASTER AUDIO & SOUND ROUTING
--------------------------------------------------------------------------------
local masterSoundGroup: SoundGroup? = nil
local audioRoutingActive = false

function UITheme.GetMasterSoundGroup(): SoundGroup
    if masterSoundGroup and masterSoundGroup.Parent then
        return masterSoundGroup
    end

    local existing = SoundService:FindFirstChild("MasterSoundGroup")
    if existing and existing:IsA("SoundGroup") then
        masterSoundGroup = existing
        return existing
    end

    local newGroup = Instance.new("SoundGroup")
    newGroup.Name = "MasterSoundGroup"
    newGroup.Volume = 0.5 -- 50% default volume per user request
    newGroup.Parent = SoundService
    masterSoundGroup = newGroup
    return newGroup
end

function UITheme.SetMasterVolume(volume: number)
    local clamped = math.clamp(volume, 0, 1)
    local group = UITheme.GetMasterSoundGroup()
    group.Volume = clamped
end

function UITheme.GetMasterVolume(): number
    local group = UITheme.GetMasterSoundGroup()
    return group.Volume
end

function UITheme.InitAudioRouting()
    if audioRoutingActive then return end
    audioRoutingActive = true

    local master = UITheme.GetMasterSoundGroup()

    local function routeSound(sound: Instance)
        if sound:IsA("Sound") and sound.SoundGroup == nil then
            sound.SoundGroup = master
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

--------------------------------------------------------------------------------
-- GLOBAL ASSETS REGISTRY (Main Menu Art, Game Logo, Posters)
--------------------------------------------------------------------------------
UITheme.Assets = {
    -- Verified Roblox Cloud Asset IDs uploaded by Fluenosity
    MainMenuBackground = "rbxassetid://77749440485321", -- Forest Campfire Thumbnail
    GameLogo = "rbxassetid://106299822759980",           -- Stylized Campfire Emblem Icon
}

-- Returns the best resolution background art, automatically pulling the
-- Creator Hub thumbnail for all collaborators in Roblox Studio if PlaceId > 0
function UITheme.GetBackgroundAsset(): string
    if string.find(UITheme.Assets.MainMenuBackground, "rbxassetid://") then
        return UITheme.Assets.MainMenuBackground
    end
    if game.PlaceId > 0 then
        return string.format("rbxthumb://type=GameThumbnail&id=%d&w=768&h=432", game.PlaceId)
    end
    return UITheme.Assets.MainMenuBackground
end

-- Returns the game logo/icon, automatically pulling the Creator Hub icon if PlaceId > 0
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

