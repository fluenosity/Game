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
local sfxSoundGroup: SoundGroup? = nil
local musicSoundGroup: SoundGroup? = nil
local environmentSoundGroup: SoundGroup? = nil
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

function UITheme.GetSFXSoundGroup(): SoundGroup
    if sfxSoundGroup and sfxSoundGroup.Parent then
        return sfxSoundGroup
    end

    local master = UITheme.GetMasterSoundGroup()
    local existing = master:FindFirstChild("SFXSoundGroup")
    if existing and existing:IsA("SoundGroup") then
        sfxSoundGroup = existing
        return existing
    end

    local group = Instance.new("SoundGroup")
    group.Name = "SFXSoundGroup"
    group.Volume = 1.0
    group.Parent = master
    sfxSoundGroup = group
    return group
end

function UITheme.GetMusicSoundGroup(): SoundGroup
    if musicSoundGroup and musicSoundGroup.Parent then
        return musicSoundGroup
    end

    local master = UITheme.GetMasterSoundGroup()
    local existing = master:FindFirstChild("MusicSoundGroup")
    if existing and existing:IsA("SoundGroup") then
        musicSoundGroup = existing
        return existing
    end

    local group = Instance.new("SoundGroup")
    group.Name = "MusicSoundGroup"
    group.Volume = 0.7
    group.Parent = master
    musicSoundGroup = group
    return group
end

function UITheme.GetEnvironmentSoundGroup(): SoundGroup
    if environmentSoundGroup and environmentSoundGroup.Parent then
        return environmentSoundGroup
    end

    local master = UITheme.GetMasterSoundGroup()
    local existing = master:FindFirstChild("EnvironmentSoundGroup")
    if existing and existing:IsA("SoundGroup") then
        environmentSoundGroup = existing
        return existing
    end

    local group = Instance.new("SoundGroup")
    group.Name = "EnvironmentSoundGroup"
    group.Volume = 1.0
    group.Parent = master
    environmentSoundGroup = group
    return group
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

function UITheme.SetSFXVolume(volume: number)
    local clamped = math.clamp(volume, 0, 1)
    local group = UITheme.GetSFXSoundGroup()
    group.Volume = clamped
end

function UITheme.GetSFXVolume(): number
    return UITheme.GetSFXSoundGroup().Volume
end

function UITheme.SetMusicVolume(volume: number)
    local clamped = math.clamp(volume, 0, 1)
    local group = UITheme.GetMusicSoundGroup()
    group.Volume = clamped
end

function UITheme.GetMusicVolume(): number
    return UITheme.GetMusicSoundGroup().Volume
end

function UITheme.SetEnvironmentVolume(volume: number)
    local clamped = math.clamp(volume, 0, 1)
    local group = UITheme.GetEnvironmentSoundGroup()
    group.Volume = clamped
end

function UITheme.GetEnvironmentVolume(): number
    return UITheme.GetEnvironmentSoundGroup().Volume
end

-- Camera Mouse Look Sensitivity (0.2x to 3.0x, default 1.0x)
local currentSensitivity = 1.0

function UITheme.SetMouseSensitivity(sens: number)
    local clamped = math.clamp(sens, 0.2, 3.0)
    currentSensitivity = clamped
    local uis = game:GetService("UserInputService")
    pcall(function()
        uis.MouseDeltaSensitivity = clamped
    end)
end

function UITheme.GetMouseSensitivity(): number
    local uis = game:GetService("UserInputService")
    return uis.MouseDeltaSensitivity or currentSensitivity
end

function UITheme.InitAudioRouting()
    if audioRoutingActive then return end
    audioRoutingActive = true

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

