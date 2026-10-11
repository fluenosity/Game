--!strict
--[[
    MenuTheme.lua
    Centralized design tokens, color palette, typography, audio routing, and UI helpers
    for Don't Let the Fire Die. Developed for Fluenosity Studio.
]]

local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")

local MenuTheme = {}

-- Visual Palette
MenuTheme.Colors = {
    PureWhite = Color3.fromRGB(255, 255, 255),
    PureBlack = Color3.fromRGB(0, 0, 0),
    Background = Color3.fromRGB(11, 10, 12),
    BackgroundDeep = Color3.fromRGB(7, 6, 8),
    CardBackground = Color3.fromRGB(18, 16, 18),
    CardBorder = Color3.fromRGB(52, 42, 38),
    CardBorderHover = Color3.fromRGB(225, 95, 28),
    
    -- Text Palette
    StudioSplashText = Color3.fromRGB(22, 22, 26),
    TextPrimary = Color3.fromRGB(246, 242, 238),
    TextMuted = Color3.fromRGB(165, 155, 150),
    TextSubdued = Color3.fromRGB(105, 98, 94),
    
    -- Warm Campfire Accents
    FireEmber = Color3.fromRGB(255, 120, 30),
    FireHot = Color3.fromRGB(255, 165, 45),
    FireCrimson = Color3.fromRGB(210, 52, 22),
    FireCore = Color3.fromRGB(255, 228, 95),
    WoodBrown = Color3.fromRGB(112, 68, 42),
    WoodDark = Color3.fromRGB(82, 48, 28),
    
    -- Interactive Buttons
    ButtonNormal = Color3.fromRGB(22, 20, 22),
    ButtonHover = Color3.fromRGB(34, 28, 27),
    ButtonPressed = Color3.fromRGB(16, 14, 15),
    ButtonBorderNormal = Color3.fromRGB(56, 46, 42),
    ButtonBorderHover = Color3.fromRGB(230, 105, 30),
}

-- Typography
MenuTheme.Fonts = {
    Title = Enum.Font.GothamBold,
    Studio = Enum.Font.GothamMedium,
    Heading = Enum.Font.GothamBold,
    Button = Enum.Font.GothamMedium,
    Body = Enum.Font.Gotham,
    Sub = Enum.Font.Gotham,
}

-- Standard Tween Profiles
MenuTheme.Tweens = {
    Instant = TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
    Fast = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
    Normal = TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
    Smooth = TweenInfo.new(0.6, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out),
    Slow = TweenInfo.new(1.0, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut),
    Fade = TweenInfo.new(0.5, Enum.EasingStyle.Linear),
}

-- Master Sound Group & Local Audio Routing
local masterSoundGroup: SoundGroup? = nil
local audioRoutingInitialized = false

function MenuTheme.GetMasterSoundGroup(): SoundGroup
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
    newGroup.Volume = 1.0
    newGroup.Parent = SoundService
    masterSoundGroup = newGroup
    return newGroup
end

function MenuTheme.SetMasterVolume(volume: number)
    local clamped = math.clamp(volume, 0, 1)
    local group = MenuTheme.GetMasterSoundGroup()
    group.Volume = clamped
end

function MenuTheme.GetMasterVolume(): number
    local group = MenuTheme.GetMasterSoundGroup()
    return group.Volume
end

-- Route game sounds into MasterSoundGroup so Master Volume controls all game audio
function MenuTheme.InitAudioRouting()
    if audioRoutingInitialized then return end
    audioRoutingInitialized = true

    local master = MenuTheme.GetMasterSoundGroup()

    local function routeSound(sound: Instance)
        if sound:IsA("Sound") and sound.SoundGroup == nil then
            sound.SoundGroup = master
        end
    end

    -- Route existing sounds
    for _, obj in ipairs(SoundService:GetDescendants()) do
        routeSound(obj)
    end
    for _, obj in ipairs(workspace:GetDescendants()) do
        routeSound(obj)
    end

    -- Route newly added sounds dynamically
    SoundService.DescendantAdded:Connect(routeSound)
    workspace.DescendantAdded:Connect(routeSound)
end

-- Convenient Instance Creation Helper
function MenuTheme.Create(className: string, properties: { [string]: any }): Instance
    local inst = Instance.new(className)
    for prop, val in pairs(properties) do
        if prop ~= "Parent" then
            (inst :: any)[prop] = val
        end
    end
    if properties.Parent then
        inst.Parent = properties.Parent
    end
    return inst
end

return MenuTheme
