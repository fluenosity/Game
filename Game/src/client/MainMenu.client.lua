--!strict
--[[
    MainMenu.client.lua
    Production-grade client intro sequence and interactive main menu for
    "Don't Let the Fire Die". Developed for Fluenosity Studio.
    
    Features:
    - Pure Safe Area Architecture with GuiService:GetGuiInset() (Zero clipping on PC/Mobile)
    - Fully responsive across desktop (1080p, 1440p, 4K), tablet, and phone screen ratios
    - Image 2 Layout Reference:
      * Left Header: Campfire Emblem + "DON'T LET THE FIRE DIE" + "THE NIGHT WILL CLAIM YOU"
      * Left Navigation: PLAY (ON TOP with glowing amber rules), SETTINGS, CREDITS
      * Bottom-Left: Co-op Party Slots (YOU + EMPTY [+] slots) perfectly within viewport
      * Right Column: Stacked feature showcase cards (auto-adapted for small screens)
    - Reusable Cinematic Loading Screen with bottom-right rotating ember spinner & survival tips
    - Unreal/Unity Lifecycle: Server spawns character only on PLAY with smooth loading transition
]]

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui") :: PlayerGui

local UITheme = require(script.Parent:WaitForChild("UITheme"))
local UIComponents = require(script.Parent:WaitForChild("UIComponents"))
local EmberParticles = require(script.Parent:WaitForChild("EmberParticles"))
local CampfireEmblem = require(script.Parent:WaitForChild("CampfireEmblem"))
local LoadingManager = require(script.Parent:WaitForChild("LoadingManager"))

local sharedFolder = ReplicatedStorage:WaitForChild("FluenosityShared")
local GameConfig = require(sharedFolder:WaitForChild("GameConfig"))

-- Initialize game-wide audio routing to MasterSoundGroup
UITheme.InitAudioRouting()

--------------------------------------------------------------------------------
-- STATE MACHINE & CAMERA LOCK
--------------------------------------------------------------------------------
local isBusy = false
local hasIntroCompleted = false
local reducedMotionEnabled = false

local camera = workspace.CurrentCamera
if not camera then
    camera = workspace:WaitForChild("Camera", 5) :: Camera
end

local function setCharacterControlsEnabled(enabled: boolean)
    pcall(function()
        local playerScripts = player:WaitForChild("PlayerScripts", 3)
        if playerScripts then
            local playerModule = require(playerScripts:WaitForChild("PlayerModule", 3)) :: any
            local controls = playerModule:GetControls()
            if enabled then
                controls:Enable()
            else
                controls:Disable()
            end
        end
    end)

    local character = player.Character
    if character then
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        if humanoid then
            humanoid.WalkSpeed = enabled and 16 or 0
            humanoid.JumpPower = enabled and 50 or 0
        end
    end
end

-- =============================================================================
-- DEV CONFIG CHECK: SKIP MAIN MENU
-- =============================================================================
if GameConfig.ShouldSkipMainMenu() then
    -- Fast Direct Play with Clean Shader & Asset Loading Screen (Prevents Pop-in & Flickering)
    local devScreenGui = Instance.new("ScreenGui")
    devScreenGui.Name = "DontLetTheFireDie_DevLoadingGui"
    devScreenGui.ResetOnSpawn = false
    devScreenGui.IgnoreGuiInset = true
    devScreenGui.DisplayOrder = 100
    devScreenGui.Parent = playerGui

    local devLoading = UIComponents.CreateLoadingScreen(devScreenGui)
    devLoading.Show({
        Status = "COMPILING SHADERS & PRELOADING WILDERNESS...",
        Tip = "Preloading environment assets, compiling shaders, and stabilizing physics...",
        Progress = 0.05,
        Detail = "Initializing Direct Play session...",
    })

    LoadingManager.LoadGame(devLoading, function()
        devLoading.Destroy()
        devScreenGui:Destroy()
        player:SetAttribute("IsInGameplay", true)
        setCharacterControlsEnabled(true)
        if camera then
            camera.CameraType = Enum.CameraType.Custom
        end
    end)

    print("[MainMenu] DevMode: SKIP_MAIN_MENU active. Running shader preloading pipeline...")
    return
end

player:SetAttribute("IsInGameplay", false)
if camera then
    camera.CameraType = Enum.CameraType.Scriptable
end
setCharacterControlsEnabled(false)
UserInputService.MouseBehavior = Enum.MouseBehavior.Default
UserInputService.MouseIconEnabled = true


--------------------------------------------------------------------------------
-- ROOT SCREEN GUI CREATION
--------------------------------------------------------------------------------
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "DontLetTheFireDie_MenuGui"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true
screenGui.DisplayOrder = 100
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = playerGui

--------------------------------------------------------------------------------
-- ATMOSPHERIC BACKGROUND & CINEMATIC WALLPAPER
--------------------------------------------------------------------------------
local background = Instance.new("Frame")
background.Name = "Background"
background.Size = UDim2.fromScale(1, 1)
background.BackgroundColor3 = UITheme.Colors.Void
background.BorderSizePixel = 0
background.ZIndex = 1
background.Parent = screenGui

-- Main Menu Wallpaper Image (I:\RobloxDev\image\mainmenubg.png)
local bgImage = Instance.new("ImageLabel")
bgImage.Name = "BackgroundImage"
bgImage.Size = UDim2.fromScale(1, 1)
bgImage.Position = UDim2.fromScale(0.5, 0.5)
bgImage.AnchorPoint = Vector2.new(0.5, 0.5)
bgImage.BackgroundTransparency = 1
bgImage.Image = UITheme.GetBackgroundAsset()
bgImage.ScaleType = Enum.ScaleType.Crop
bgImage.ImageTransparency = 0.15
bgImage.ZIndex = 2
bgImage.Parent = background

-- Ambient warm firelight radial gradient (biased to left where fire burns)
local ambientFirelight = Instance.new("Frame")
ambientFirelight.Name = "AmbientFirelight"
ambientFirelight.Size = UDim2.fromScale(1, 1)
ambientFirelight.BackgroundColor3 = UITheme.Colors.EmberCrimson
ambientFirelight.BackgroundTransparency = 0.94
ambientFirelight.BorderSizePixel = 0
ambientFirelight.ZIndex = 3

local fireGrad = Instance.new("UIGradient")
fireGrad.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, UITheme.Colors.EmberHot),
    ColorSequenceKeypoint.new(0.5, UITheme.Colors.EmberCrimson),
    ColorSequenceKeypoint.new(1, UITheme.Colors.Void),
})
fireGrad.Transparency = NumberSequence.new({
    NumberSequenceKeypoint.new(0, 0.76),
    NumberSequenceKeypoint.new(0.6, 0.92),
    NumberSequenceKeypoint.new(1, 1),
})
fireGrad.Rotation = 45
fireGrad.Parent = ambientFirelight
ambientFirelight.Parent = background

-- Vignette Border Shadow
local vignette = Instance.new("Frame")
vignette.Name = "Vignette"
vignette.Size = UDim2.fromScale(1, 1)
vignette.BackgroundColor3 = UITheme.Colors.PureBlack
vignette.BackgroundTransparency = 0.8
vignette.BorderSizePixel = 0
vignette.ZIndex = 3

local vigGrad = Instance.new("UIGradient")
vigGrad.Transparency = NumberSequence.new({
    NumberSequenceKeypoint.new(0, 0.3),
    NumberSequenceKeypoint.new(0.8, 0.85),
    NumberSequenceKeypoint.new(1, 1),
})
vigGrad.Parent = vignette
vignette.Parent = background

local emberSystem = EmberParticles.new(background)

--------------------------------------------------------------------------------
-- TRUE SAFE AREA CONTAINER (Guarantees zero overlap with topbar or screen edges)
--------------------------------------------------------------------------------
local safeArea = Instance.new("Frame")
safeArea.Name = "SafeArea"
safeArea.Size = UDim2.fromScale(1, 1)
safeArea.Position = UDim2.fromScale(0, 0)
safeArea.BackgroundTransparency = 1
safeArea.ZIndex = 5
safeArea.Parent = screenGui

local safePadding = Instance.new("UIPadding")
safePadding.Parent = safeArea

--------------------------------------------------------------------------------
-- LEFT HERO COLUMN (Poster-Style Layout matching Reference Image)
--------------------------------------------------------------------------------
local leftArea = Instance.new("Frame")
leftArea.Name = "LeftArea"
leftArea.Size = UDim2.new(0, 360, 0, 480)
leftArea.Position = UDim2.new(0, 48, 0.46, 0)
leftArea.AnchorPoint = Vector2.new(0, 0.5)
leftArea.BackgroundTransparency = 1
leftArea.Visible = false
leftArea.ZIndex = 6
leftArea.Parent = safeArea

-- 1. Top Branding Group (Campfire Emblem + 2-Line Condensed Title + Burnt Ember Subtitle)
local brandingHeader = Instance.new("Frame")
brandingHeader.Name = "BrandingHeader"
brandingHeader.Size = UDim2.new(1, 0, 0, 210)
brandingHeader.Position = UDim2.new(0, 0, 0, 0)
brandingHeader.BackgroundTransparency = 1
brandingHeader.ZIndex = 7
brandingHeader.Parent = leftArea

-- Campfire Emblem Centered Above Title
local emblem = CampfireEmblem.new(UDim2.fromOffset(76, 76))
emblem.Root.Position = UDim2.new(0.5, 0, 0, 0)
emblem.Root.AnchorPoint = Vector2.new(0.5, 0)
emblem.Root.Parent = brandingHeader

-- Title & Subtitle Stacked Directly Below Emblem
local titleContainer = Instance.new("Frame")
titleContainer.Name = "TitleContainer"
titleContainer.Size = UDim2.new(1, 0, 0, 130)
titleContainer.Position = UDim2.new(0.5, 0, 0, 80)
titleContainer.AnchorPoint = Vector2.new(0.5, 0)
titleContainer.BackgroundTransparency = 1
titleContainer.ZIndex = 7
titleContainer.Parent = brandingHeader

local titleLayout = Instance.new("UIListLayout")
titleLayout.FillDirection = Enum.FillDirection.Vertical
titleLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
titleLayout.VerticalAlignment = Enum.VerticalAlignment.Top
titleLayout.Padding = UDim.new(0, 8)
titleLayout.Parent = titleContainer

-- 2-Line High-Impact Oswald Bold Title ("DON'T LET \n THE FIRE DIE")
local mainTitle = Instance.new("TextLabel")
mainTitle.Name = "MainTitle"
mainTitle.Size = UDim2.new(1, 0, 0, 92)
mainTitle.BackgroundTransparency = 1
mainTitle.Font = Enum.Font.Oswald
mainTitle.Text = "DON'T LET\nTHE FIRE DIE"
mainTitle.TextColor3 = Color3.fromRGB(240, 235, 225) -- Off-white ivory parchment
mainTitle.TextSize = 44
mainTitle.LineHeight = 0.94
mainTitle.TextXAlignment = Enum.TextXAlignment.Center
mainTitle.TextStrokeColor3 = Color3.fromRGB(12, 10, 8)
mainTitle.TextStrokeTransparency = 0.35
mainTitle.ZIndex = 8
mainTitle.Parent = titleContainer

-- Glowing Burnt Ember Subtitle ("THE NIGHT WILL CLAIM YOU")
local subTitle = Instance.new("TextLabel")
subTitle.Name = "SubTitle"
subTitle.Size = UDim2.new(1, 0, 0, 22)
subTitle.BackgroundTransparency = 1
subTitle.Font = Enum.Font.Oswald
subTitle.Text = "THE NIGHT WILL CLAIM YOU"
subTitle.TextColor3 = Color3.fromRGB(245, 130, 48) -- Vibrant amber/ember orange
subTitle.TextSize = 15
subTitle.TextXAlignment = Enum.TextXAlignment.Center
subTitle.TextStrokeColor3 = Color3.fromRGB(15, 6, 4)
subTitle.TextStrokeTransparency = 0.4
subTitle.ZIndex = 8
subTitle.Parent = titleContainer

-- 2. Navigation Actions Container (PLAY, SETTINGS, CREDITS)
local navContainer = Instance.new("Frame")
navContainer.Name = "NavContainer"
navContainer.Size = UDim2.new(1, 0, 0, 210)
navContainer.Position = UDim2.new(0.5, 0, 0, 240)
navContainer.AnchorPoint = Vector2.new(0.5, 0)
navContainer.BackgroundTransparency = 1
navContainer.ZIndex = 9
navContainer.Parent = leftArea

local navLayout = Instance.new("UIListLayout")
navLayout.FillDirection = Enum.FillDirection.Vertical
navLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
navLayout.VerticalAlignment = Enum.VerticalAlignment.Top
navLayout.SortOrder = Enum.SortOrder.LayoutOrder
navLayout.Padding = UDim.new(0, 16)
navLayout.Parent = navContainer

-- 3. Bottom-Left Studio Watermark Stamp (Image reference: "A FLUENOSITY STUDIO GAME")
local studioStamp = Instance.new("TextLabel")
studioStamp.Name = "StudioStamp"
studioStamp.Size = UDim2.new(0, 320, 0, 20)
studioStamp.Position = UDim2.new(0, 4, 1, -8)
studioStamp.AnchorPoint = Vector2.new(0, 1)
studioStamp.BackgroundTransparency = 1
studioStamp.Font = Enum.Font.GothamMedium
studioStamp.Text = "A FLUENOSITY STUDIO GAME"
studioStamp.TextColor3 = Color3.fromRGB(115, 122, 136) -- Subtle muted slate grey
studioStamp.TextSize = 11
studioStamp.TextXAlignment = Enum.TextXAlignment.Left
studioStamp.TextStrokeColor3 = Color3.fromRGB(6, 7, 10)
studioStamp.TextStrokeTransparency = 0.7
studioStamp.ZIndex = 8
studioStamp.Parent = safeArea

--------------------------------------------------------------------------------
-- PRODUCTION-GRADE RESPONSIVE ADAPTATION ENGINE
--------------------------------------------------------------------------------
local function updateLayoutResponsiveness()
    if not camera then return end
    local viewport = camera.ViewportSize
    if viewport.X == 0 or viewport.Y == 0 then return end

    local topInset, bottomInset = GuiService:GetGuiInset()
    local sidePad = math.clamp(math.round(viewport.X * 0.05), 32, 72)
    local topPad = math.max(topInset.Y, 36) + 10
    local botPad = math.max(bottomInset.Y, 16) + 12

    safePadding.PaddingTop = UDim.new(0, topPad)
    safePadding.PaddingBottom = UDim.new(0, botPad)
    safePadding.PaddingLeft = UDim.new(0, sidePad)
    safePadding.PaddingRight = UDim.new(0, sidePad)

    -- Dynamic vertical adapting for short screens (laptops / mobile landscape)
    if viewport.Y < 600 then
        leftArea.Size = UDim2.new(0, 320, 0, 420)
        brandingHeader.Size = UDim2.new(1, 0, 0, 180)
        emblem.Root.Size = UDim2.fromOffset(60, 60)
        titleContainer.Position = UDim2.new(0.5, 0, 0, 65)
        mainTitle.TextSize = 34
        subTitle.TextSize = 13
        navContainer.Position = UDim2.new(0.5, 0, 0, 205)
    else
        leftArea.Size = UDim2.new(0, 360, 0, 480)
        brandingHeader.Size = UDim2.new(1, 0, 0, 210)
        emblem.Root.Size = UDim2.fromOffset(76, 76)
        titleContainer.Position = UDim2.new(0.5, 0, 0, 80)
        mainTitle.TextSize = 44
        subTitle.TextSize = 15
        navContainer.Position = UDim2.new(0.5, 0, 0, 240)
    end

    if viewport.X < 700 then
        -- Mobile portrait / narrow screens: center menu horizontally
        leftArea.Position = UDim2.new(0.5, 0, 0.46, 0)
        leftArea.AnchorPoint = Vector2.new(0.5, 0.5)
    else
        -- Desktop / wide screens: left-aligned
        leftArea.Position = UDim2.new(0, 10, 0.46, 0)
        leftArea.AnchorPoint = Vector2.new(0, 0.5)
    end
end

updateLayoutResponsiveness()
if camera then
    camera:GetPropertyChangedSignal("ViewportSize"):Connect(updateLayoutResponsiveness)
end

--------------------------------------------------------------------------------
-- REUSABLE CINEMATIC LOADING SCREEN COMPONENT
--------------------------------------------------------------------------------
local loadingScreen = UIComponents.CreateLoadingScreen(screenGui)

--------------------------------------------------------------------------------
-- MODALS (SETTINGS & CREDITS)
--------------------------------------------------------------------------------
local settingsModal = UIComponents.CreateModal({
    Title = "SETTINGS",
    CategoryTag = "[ AUDIO & CONTROLS ]",
    Width = 460,
    Height = 490,
    Parent = screenGui,
})

local settingsLayout = Instance.new("UIListLayout")
settingsLayout.FillDirection = Enum.FillDirection.Vertical
settingsLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
settingsLayout.Padding = UDim.new(0, 14)
settingsLayout.Parent = settingsModal.Content

-- 1. Master Audio Volume
UIComponents.CreateSlider({
    Label = "MASTER VOLUME",
    Description = "Master sound level for the entire game",
    InitialValue = UITheme.GetMasterVolume(),
    Parent = settingsModal.Content,
    OnChanged = function(val: number)
        UITheme.SetMasterVolume(val)
    end,
})

UIComponents.CreateDivider(settingsModal.Content)

-- 2. SFX Volume
UIComponents.CreateSlider({
    Label = "SFX VOLUME",
    Description = "UI clicks, item interaction, wood gathering & clicks",
    InitialValue = UITheme.GetSFXVolume(),
    Parent = settingsModal.Content,
    OnChanged = function(val: number)
        UITheme.SetSFXVolume(val)
    end,
})

UIComponents.CreateDivider(settingsModal.Content)

-- 3. Music Volume
UIComponents.CreateSlider({
    Label = "MUSIC VOLUME",
    Description = "Melodic scores & atmospheric background soundtrack",
    InitialValue = UITheme.GetMusicVolume(),
    Parent = settingsModal.Content,
    OnChanged = function(val: number)
        UITheme.SetMusicVolume(val)
    end,
})

UIComponents.CreateDivider(settingsModal.Content)

-- 4. Game Native Audio (Environment)
UIComponents.CreateSlider({
    Label = "GAME NATIVE AUDIO",
    Description = "Campfire crackles, wind blowing, crickets & 3D nature sounds",
    InitialValue = UITheme.GetEnvironmentVolume(),
    Parent = settingsModal.Content,
    OnChanged = function(val: number)
        UITheme.SetEnvironmentVolume(val)
    end,
})

UIComponents.CreateDivider(settingsModal.Content)

-- 5. Look Sensitivity (0.2x to 3.0x)
UIComponents.CreateSlider({
    Label = "LOOK SENSITIVITY",
    Description = "First-person camera mouse sensitivity (0.2x to 3.0x)",
    InitialValue = UITheme.GetMouseSensitivity(),
    MinValue = 0.2,
    MaxValue = 3.0,
    Step = 0.1,
    ValueFormat = function(v: number)
        return string.format("%.1fx", v)
    end,
    Parent = settingsModal.Content,
    OnChanged = function(val: number)
        UITheme.SetMouseSensitivity(val)
    end,
})

UIComponents.CreateDivider(settingsModal.Content)

-- 6. Reduced Motion
UIComponents.CreateToggle({
    Label = "REDUCED MOTION",
    Description = "Disables background embers & breathing animations",
    InitialValue = reducedMotionEnabled,
    Parent = settingsModal.Content,
    OnChanged = function(enabled: boolean)
        reducedMotionEnabled = enabled
        emberSystem:SetReducedMotion(enabled)
        emblem:SetReducedMotion(enabled)
    end,
})

local creditsModal = UIComponents.CreateModal({
    Title = "CREDITS",
    CategoryTag = "[ PRODUCTION TEAM ]",
    Width = 450,
    Height = 410,
    Parent = screenGui,
})

local creditsLayout = Instance.new("UIListLayout")
creditsLayout.FillDirection = Enum.FillDirection.Vertical
creditsLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
creditsLayout.Padding = UDim.new(0, 14)
creditsLayout.Parent = creditsModal.Content

local function addCreditItem(role: string, name: string, isAccent: boolean)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, 0, 0, 36)
    row.BackgroundTransparency = 1
    row.ZIndex = 44
    row.Parent = creditsModal.Content

    local roleLbl = Instance.new("TextLabel")
    roleLbl.Size = UDim2.new(1, 0, 0, 14)
    roleLbl.BackgroundTransparency = 1
    roleLbl.Font = UITheme.Fonts.Tag
    roleLbl.Text = role
    roleLbl.TextColor3 = UITheme.Colors.TextMuted
    roleLbl.TextSize = 10
    roleLbl.TextXAlignment = Enum.TextXAlignment.Left
    roleLbl.ZIndex = 44
    roleLbl.Parent = row

    local nameLbl = Instance.new("TextLabel")
    nameLbl.Size = UDim2.new(1, 0, 0, 20)
    nameLbl.Position = UDim2.new(0, 0, 0, 14)
    nameLbl.BackgroundTransparency = 1
    nameLbl.Font = UITheme.Fonts.Heading
    nameLbl.Text = name
    nameLbl.TextColor3 = isAccent and UITheme.Colors.EmberHot or UITheme.Colors.TextPrimary
    nameLbl.TextSize = isAccent and 15 or 14
    nameLbl.TextXAlignment = Enum.TextXAlignment.Left
    nameLbl.ZIndex = 44
    nameLbl.Parent = row
end

addCreditItem("PRODUCED & DEVELOPED BY", "FLUENOSITY STUDIO", true)
addCreditItem("ENGINEERING & SYSTEMS ARCHITECTURE", "Fluenosity Studio Core Team", false)
addCreditItem("ATMOSPHERIC ART & AUDIO DIRECTION", "Fluenosity Studio", false)

UIComponents.CreateDivider(creditsModal.Content)

local quoteBox = Instance.new("Frame")
quoteBox.Size = UDim2.new(1, 0, 0, 36)
quoteBox.BackgroundColor3 = UITheme.Colors.Surface
quoteBox.BorderSizePixel = 0
quoteBox.ZIndex = 44
quoteBox.Parent = creditsModal.Content

local quoteCorner = Instance.new("UICorner")
quoteCorner.CornerRadius = UDim.new(0, 6)
quoteCorner.Parent = quoteBox

local quoteText = Instance.new("TextLabel")
quoteText.Size = UDim2.new(1, -20, 1, 0)
quoteText.Position = UDim2.fromScale(0.5, 0.5)
quoteText.AnchorPoint = Vector2.new(0.5, 0.5)
quoteText.BackgroundTransparency = 1
quoteText.Font = UITheme.Fonts.Body
quoteText.Text = '"The night is long. Never turn your back on the fire."'
quoteText.TextColor3 = UITheme.Colors.EmberHot
quoteText.TextSize = 11
quoteText.ZIndex = 45
quoteText.Parent = quoteBox

--------------------------------------------------------------------------------
-- INTERACTIVE NAV ACTIONS (ORDER: 1. PLAY, 2. SETTINGS, 3. CREDITS)
--------------------------------------------------------------------------------
-- 1. PLAY Action (ON TOP with LayoutOrder = 1)
-- 1. PLAY Action (ON TOP with LayoutOrder = 1)
local navPlay = UIComponents.CreateNavAction({
    Text = "PLAY",
    IsPrimary = true,
    LayoutOrder = 1, -- Strictly on top!
    Parent = navContainer,
    OnClick = function()
        if isBusy then return end
        isBusy = true

        local fadeTime = reducedMotionEnabled and 0.25 or 0.4
        local fadeInfo = TweenInfo.new(fadeTime, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

        -- 1. Smoothly fade out menu navigation to the left
        local leftSlide = TweenService:Create(leftArea, fadeInfo, {
            Position = UDim2.new(leftArea.Position.X.Scale, leftArea.Position.X.Offset - 60, leftArea.Position.Y.Scale, leftArea.Position.Y.Offset),
        })
        leftSlide:Play()

        for _, desc in ipairs(safeArea:GetDescendants()) do
            if desc:IsA("TextLabel") then
                TweenService:Create(desc, fadeInfo, { TextTransparency = 1 }):Play()
            elseif desc:IsA("UIStroke") then
                TweenService:Create(desc, fadeInfo, { Transparency = 1 }):Play()
            elseif desc:IsA("Frame") or desc:IsA("TextButton") then
                TweenService:Create(desc, fadeInfo, { BackgroundTransparency = 1 }):Play()
            end
        end

        -- 2. Fade in Cinematic Loading Screen with Glowing Progress Bar
        loadingScreen.Show({
            Status = "CONNECTING TO FOREST SECTOR...",
            Tip = "The campfire is your only safe haven. When it dies, the forest claims you.",
            Progress = 0.05,
            Detail = "Preloading environment assets & compiling shaders...",
        })

        -- 3. Run production-grade LoadingManager pipeline
        LoadingManager.LoadGame(loadingScreen, function()
            hasIntroCompleted = true
            emberSystem:Destroy()
            emblem:Destroy()
            screenGui:Destroy()
            player:SetAttribute("IsInGameplay", true)
            setCharacterControlsEnabled(true)
            if camera then
                camera.CameraType = Enum.CameraType.Custom
            end
        end)
    end,
})

-- 2. SETTINGS Action (LayoutOrder = 2)
local navSettings = UIComponents.CreateNavAction({
    Text = "SETTINGS",
    IsPrimary = false,
    LayoutOrder = 2, -- Second
    Parent = navContainer,
    OnClick = function()
        settingsModal.Open()
    end,
})

-- 3. CREDITS Action (LayoutOrder = 3)
local navCredits = UIComponents.CreateNavAction({
    Text = "CREDITS",
    IsPrimary = false,
    LayoutOrder = 3, -- Third
    Parent = navContainer,
    OnClick = function()
        creditsModal.Open()
    end,
})

--------------------------------------------------------------------------------
-- CINEMATIC INTRO SEQUENCE (STAGGERED: LEFT FROM LEFT, RIGHT FROM RIGHT)
--------------------------------------------------------------------------------
local function runCinematicIntro()
    isBusy = true

    ----------------------------------------------------------------------------
    -- PHASE 1: Pure White Studio Splash Screen (~2.0s) [Configurable via GameConfig]
    ----------------------------------------------------------------------------
    if not GameConfig.ShouldSkipSplashScreen() then
        local splashScreen = Instance.new("Frame")
        splashScreen.Name = "StudioSplash"
        splashScreen.Size = UDim2.fromScale(1, 1)
        splashScreen.BackgroundColor3 = UITheme.Colors.PureWhite
        splashScreen.BorderSizePixel = 0
        splashScreen.ZIndex = 60
        splashScreen.Parent = screenGui

        local studioTitle = Instance.new("TextLabel")
        studioTitle.Name = "StudioTitle"
        studioTitle.Size = UDim2.new(0.9, 0, 0, 36)
        studioTitle.Position = UDim2.fromScale(0.5, 0.5)
        studioTitle.AnchorPoint = Vector2.new(0.5, 0.5)
        studioTitle.BackgroundTransparency = 1
        studioTitle.Font = UITheme.Fonts.Studio
        studioTitle.Text = "A  F L U E N O S I T Y   S T U D I O   P R O D U C T I O N"
        studioTitle.TextColor3 = UITheme.Colors.TextStudioSplash
        studioTitle.TextScaled = true
        studioTitle.TextWrapped = true
        studioTitle.TextSize = 18
        studioTitle.TextTransparency = 1
        studioTitle.ZIndex = 61
        studioTitle.Parent = splashScreen

        local studioConstraint = Instance.new("UITextSizeConstraint")
        studioConstraint.MaxTextSize = 20
        studioConstraint.MinTextSize = 12
        studioConstraint.Parent = studioTitle

        local fadeInText = TweenService:Create(studioTitle, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            TextTransparency = 0,
        })
        fadeInText:Play()
        fadeInText.Completed:Wait()

        task.wait(1.0)

        local fadeOutText = TweenService:Create(studioTitle, TweenInfo.new(0.45, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
            TextTransparency = 1,
        })
        fadeOutText:Play()
        fadeOutText.Completed:Wait()

        local darkTransition = TweenService:Create(splashScreen, TweenInfo.new(0.7, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut), {
            BackgroundTransparency = 1,
        })
        darkTransition:Play()
        darkTransition.Completed:Wait()
        splashScreen:Destroy()
    end


    local sparkIgnition = Instance.new("Frame")
    sparkIgnition.Name = "SparkIgnition"
    sparkIgnition.Size = UDim2.fromOffset(4, 4)
    sparkIgnition.Position = UDim2.fromScale(0.5, 0.5)
    sparkIgnition.AnchorPoint = Vector2.new(0.5, 0.5)
    sparkIgnition.BackgroundColor3 = UITheme.Colors.EmberHot
    sparkIgnition.BorderSizePixel = 0
    sparkIgnition.ZIndex = 30
    sparkIgnition.Parent = background

    local sparkCorner = Instance.new("UICorner")
    sparkCorner.CornerRadius = UDim.new(1, 0)
    sparkCorner.Parent = sparkIgnition

    local sparkGlow = TweenService:Create(sparkIgnition, TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        Size = UDim2.fromOffset(16, 16),
        BackgroundTransparency = 0.3,
    })
    sparkGlow:Play()
    sparkGlow.Completed:Wait()

    emberSystem:Start()

    local sparkFade = TweenService:Create(sparkIgnition, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        Size = UDim2.fromOffset(2, 2),
        BackgroundTransparency = 1,
    })
    sparkFade:Play()
    sparkFade.Completed:Wait()
    sparkIgnition:Destroy()

    ----------------------------------------------------------------------------
    -- PHASE 3: STAGGERED ENTRANCE FROM THE LEFT (Image Reference Style)
    ----------------------------------------------------------------------------
    leftArea.Visible = true

    local targetLeftPos = leftArea.Position
    local startLeftPos = UDim2.new(targetLeftPos.X.Scale, targetLeftPos.X.Offset - 50, targetLeftPos.Y.Scale, targetLeftPos.Y.Offset)
    leftArea.Position = startLeftPos

    brandingHeader.Position = UDim2.new(0, -40, 0, 0)
    mainTitle.TextTransparency = 1
    subTitle.TextTransparency = 1
    emblem:SetTransparency(1)
    studioStamp.TextTransparency = 1

    local areaTween = TweenService:Create(leftArea, TweenInfo.new(0.55, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        Position = targetLeftPos,
    })
    areaTween:Play()

    local headerTween = TweenService:Create(brandingHeader, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        Position = UDim2.new(0, 0, 0, 0),
    })
    headerTween:Play()
    emblem:AnimateFade(0, TweenInfo.new(0.45, Enum.EasingStyle.Quad, Enum.EasingDirection.Out))
    TweenService:Create(mainTitle, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { TextTransparency = 0 }):Play()
    TweenService:Create(subTitle, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { TextTransparency = 0 }):Play()
    TweenService:Create(studioStamp, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { TextTransparency = 0 }):Play()

    task.wait(0.12)

    -- Step 2: Nav Actions (PLAY, SETTINGS, CREDITS) arrive with staggered delays
    local navItems = { navPlay, navSettings, navCredits }
    for i, btn in ipairs(navItems) do
        local content = btn:FindFirstChild("Content") :: Frame?
        if content then
            content.Position = UDim2.new(0, -35, 0, 0)
            for _, d in ipairs(content:GetDescendants()) do
                if d:IsA("TextLabel") then
                    d.TextTransparency = 1
                elseif d:IsA("Frame") and (d.Name:find("Flare") or d.Name:find("Pip") or d.Name:find("Aura")) then
                    d.BackgroundTransparency = 1
                end
            end
            task.delay((i - 1) * 0.10, function()
                TweenService:Create(content, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                    Position = UDim2.new(0, 0, 0, 0),
                }):Play()
                for _, d in ipairs(content:GetDescendants()) do
                    if d:IsA("TextLabel") then
                        TweenService:Create(d, TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { TextTransparency = 0 }):Play()
                    elseif d:IsA("Frame") and d.Name == "GlowFlare" and i == 1 then
                        TweenService:Create(d, TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { BackgroundTransparency = 0 }):Play()
                    elseif d:IsA("Frame") and d.Name == "CenterPip" and i == 1 then
                        TweenService:Create(d, TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { BackgroundTransparency = 0 }):Play()
                    elseif d:IsA("Frame") and d.Name == "PipAura" and i == 1 then
                        TweenService:Create(d, TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { BackgroundTransparency = 0.55 }):Play()
                    end
                end
            end)
        end
    end

    hasIntroCompleted = true
    isBusy = false
end

task.spawn(runCinematicIntro)
