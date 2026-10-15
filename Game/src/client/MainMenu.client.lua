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
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui") :: PlayerGui

local UITheme = require(script.Parent:WaitForChild("UITheme"))
local UI = require(script.Parent:WaitForChild("UI"))
local EmberParticles = require(script.Parent:WaitForChild("EmberParticles"))
local CampfireEmblem = require(script.Parent:WaitForChild("CampfireEmblem"))
local LoadingManager = require(script.Parent:WaitForChild("LoadingManager"))
local AudioManager = require(script.Parent:WaitForChild("AudioManager"))
local SurvivorWardrobe = require(script.Parent:WaitForChild("SurvivorWardrobe"))

local sharedFolder = ReplicatedStorage:WaitForChild("FluenosityShared")
local GameConfig = require(sharedFolder:WaitForChild("GameConfig"))
local IconPack = require(sharedFolder:WaitForChild("IconPack"))

-- Initialize game-wide audio routing to MasterSoundGroup
UITheme.InitAudioRouting()

--------------------------------------------------------------------------------
-- STATE MACHINE & CAMERA LOCK
--------------------------------------------------------------------------------
local isBusy = false
local hasIntroCompleted = false
local reducedMotionEnabled = false
local rightArea: Frame? = nil

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
            humanoid.JumpPower = enabled and 38 or 0
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

    local devLoading = UI.LoadingScreen.Create(devScreenGui)
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
setCharacterControlsEnabled(false)
UserInputService.MouseBehavior = Enum.MouseBehavior.Default
UserInputService.MouseIconEnabled = true

--------------------------------------------------------------------------------
-- LIVE 3D FOREST CAMPFIRE SIMULATION AT NIGHT (Reference Image Alignment)
--------------------------------------------------------------------------------
local campCenter = Vector3.new(2.5, 12, -430)
local baseCamPos = Vector3.new(0, 26, -385)
local menuCameraConn: RBXScriptConnection? = nil
local menuStartTime = os.clock()

local function setMenuNightLighting()
    pcall(function()
        Lighting.ClockTime = 22.0
        Lighting.Brightness = 0.8
        Lighting.FogEnd = 400
        Lighting.OutdoorAmbient = Color3.fromRGB(22, 28, 45)
    end)
end

setMenuNightLighting()

if camera then
    camera.CameraType = Enum.CameraType.Scriptable
    camera.FieldOfView = 65
    camera.CFrame = CFrame.lookAt(baseCamPos, campCenter)
end

local function startMenuCameraSimulation()
    if menuCameraConn then
        menuCameraConn:Disconnect()
    end
    menuStartTime = os.clock()
    menuCameraConn = RunService.RenderStepped:Connect(function()
        if player:GetAttribute("IsInGameplay") == true then
            if menuCameraConn then
                menuCameraConn:Disconnect()
                menuCameraConn = nil
            end
            return
        end

        local elapsed = os.clock() - menuStartTime

        -- Keep live 3D campfire scene at night while in main menu
        if Lighting.ClockTime ~= 22.0 then
            Lighting.ClockTime = 22.0
            Lighting.Brightness = 0.8
            Lighting.FogEnd = 400
        end

        -- Gentle cinematic drone drift across the high 3/4 camp perspective
        local driftX = math.sin(elapsed * 0.22) * 2.2
        local driftY = math.cos(elapsed * 0.35) * 0.7
        local driftZ = math.sin(elapsed * 0.18) * 1.5

        local camPos = baseCamPos + Vector3.new(driftX, driftY, driftZ)
        local target = campCenter + Vector3.new(math.sin(elapsed * 0.15) * 0.5, 0, 0)
        camera.CFrame = CFrame.lookAt(camPos, target)
    end)
end

startMenuCameraSimulation()

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
-- ATMOSPHERIC GLASS & VIGNETTE (Live 3D World Visible Behind Glassmorphic UI)
--------------------------------------------------------------------------------
local background = Instance.new("Frame")
background.Name = "Background"
background.Size = UDim2.fromScale(1, 1)
background.BackgroundTransparency = 1 -- Fully transparent so live 3D forest simulation is clear
background.BorderSizePixel = 0
background.ZIndex = 1
background.Parent = screenGui

-- Static bgImage and bgVideo removed: live 3D world rendered in real-time beneath UI!
local bgImage: ImageLabel? = nil
local bgVideo: VideoFrame? = nil

-- Ambient warm firelight radial gradient (biased to center-left where fire burns)
local ambientFirelight = Instance.new("Frame")
ambientFirelight.Name = "AmbientFirelight"
ambientFirelight.Size = UDim2.fromScale(1, 1)
ambientFirelight.BackgroundColor3 = (UITheme.Colors and UITheme.Colors.EmberCrimson) or Color3.fromRGB(205, 45, 25)
ambientFirelight.BackgroundTransparency = 0.95
ambientFirelight.BorderSizePixel = 0
ambientFirelight.ZIndex = 3

local fireGrad = Instance.new("UIGradient")
fireGrad.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, (UITheme.Colors and UITheme.Colors.EmberHot) or Color3.fromRGB(255, 160, 45)),
    ColorSequenceKeypoint.new(0.5, (UITheme.Colors and UITheme.Colors.EmberCrimson) or Color3.fromRGB(205, 45, 25)),
    ColorSequenceKeypoint.new(1, (UITheme.Colors and UITheme.Colors.Void) or Color3.fromRGB(4, 6, 10)),
})
fireGrad.Transparency = NumberSequence.new({
    NumberSequenceKeypoint.new(0, 0.85),
    NumberSequenceKeypoint.new(0.6, 0.96),
    NumberSequenceKeypoint.new(1, 1),
})
fireGrad.Rotation = 45
fireGrad.Parent = ambientFirelight
ambientFirelight.Parent = background

-- Vignette Border Shadow (Cinematic lens framing)
local vignette = Instance.new("Frame")
vignette.Name = "Vignette"
vignette.Size = UDim2.fromScale(1, 1)
vignette.BackgroundColor3 = (UITheme.Colors and UITheme.Colors.PureBlack) or Color3.fromRGB(0, 0, 0)
vignette.BackgroundTransparency = 0.85
vignette.BorderSizePixel = 0
vignette.ZIndex = 3

local vigGrad = Instance.new("UIGradient")
vigGrad.Transparency = NumberSequence.new({
    NumberSequenceKeypoint.new(0, 0.4),
    NumberSequenceKeypoint.new(0.8, 0.92),
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
        navContainer.Size = UDim2.new(1, 0, 0, 210)
        navContainer.Position = UDim2.new(0.5, 0, 0, 205)
    else
        leftArea.Size = UDim2.new(0, 360, 0, 480)
        brandingHeader.Size = UDim2.new(1, 0, 0, 210)
        emblem.Root.Size = UDim2.fromOffset(76, 76)
        titleContainer.Position = UDim2.new(0.5, 0, 0, 80)
        mainTitle.TextSize = 44
        subTitle.TextSize = 15
        navContainer.Size = UDim2.new(1, 0, 0, 210)
        navContainer.Position = UDim2.new(0.5, 0, 0, 240)
    end

    if viewport.X < 850 then
        -- Mobile / narrow screens: center menu horizontally
        leftArea.Position = UDim2.new(0.5, 0, 0.46, 0)
        leftArea.AnchorPoint = Vector2.new(0.5, 0.5)
        if rightArea then
            rightArea.Position = UDim2.new(0.5, 0, 0.88, 0)
            rightArea.AnchorPoint = Vector2.new(0.5, 1)
            rightArea.Size = UDim2.new(0, 320, 0, 240)
        end
    else
        -- Desktop / wide screens: leftArea on left, rightArea on right
        leftArea.Position = UDim2.new(0, 48, 0.46, 0)
        leftArea.AnchorPoint = Vector2.new(0, 0.5)
        if rightArea then
            rightArea.Position = UDim2.new(1, -48, 0.46, 0)
            rightArea.AnchorPoint = Vector2.new(1, 0.5)
            rightArea.Size = UDim2.new(0, 320, 0, 290)
        end
    end
end

updateLayoutResponsiveness()
if camera then
    camera:GetPropertyChangedSignal("ViewportSize"):Connect(updateLayoutResponsiveness)
end

--------------------------------------------------------------------------------
-- REUSABLE CINEMATIC LOADING SCREEN COMPONENT
--------------------------------------------------------------------------------
local loadingScreen = UI.LoadingScreen.Create(screenGui)
local wardrobeScreen = SurvivorWardrobe.Create(screenGui, UI, UITheme)

--------------------------------------------------------------------------------
-- MODALS (SETTINGS & CREDITS)
--------------------------------------------------------------------------------
local settingsModal = UI.Modal.Create({
    Id = "SettingsMenu",
    Title = "SETTINGS",
    Subtitle = "AUDIO MIXING, SENSITIVITY & GAMEPLAY OPTIONS",
    Width = UDim.new(0.48, 0),
    Height = UDim.new(0.68, 0),
    Parent = screenGui,
})

local settingsScroll = Instance.new("ScrollingFrame")
settingsScroll.Name = "SettingsScroll"
settingsScroll.Size = UDim2.fromScale(1, 1)
settingsScroll.BackgroundTransparency = 1
settingsScroll.BorderSizePixel = 0
settingsScroll.ScrollBarThickness = 3
settingsScroll.ScrollBarImageColor3 = UI.Theme.Colors.BorderGlass
settingsScroll.CanvasSize = UDim2.new(0, 0, 0, 420)
settingsScroll.Parent = settingsModal.Content

local settingsLayout = Instance.new("UIListLayout")
settingsLayout.FillDirection = Enum.FillDirection.Vertical
settingsLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
settingsLayout.Padding = UDim.new(0, 8)
settingsLayout.Parent = settingsScroll

-- 1. Master Audio Volume
UI.Slider.Create({
    Label = "MASTER VOLUME",
    Min = 0,
    Max = 1,
    Default = UITheme.GetMasterVolume(),
    Step = 0.05,
    Parent = settingsScroll,
    OnChange = function(val: number)
        UITheme.SetMasterVolume(val)
    end,
})

-- 2. SFX Volume
UI.Slider.Create({
    Label = "SFX VOLUME",
    Min = 0,
    Max = 1,
    Default = UITheme.GetSFXVolume(),
    Step = 0.05,
    Parent = settingsScroll,
    OnChange = function(val: number)
        UITheme.SetSFXVolume(val)
    end,
})

-- 3. Music Volume
UI.Slider.Create({
    Label = "MUSIC VOLUME",
    Min = 0,
    Max = 1,
    Default = UITheme.GetMusicVolume(),
    Step = 0.05,
    Parent = settingsScroll,
    OnChange = function(val: number)
        UITheme.SetMusicVolume(val)
    end,
})

-- 4. Environment Audio
UI.Slider.Create({
    Label = "GAME NATIVE AUDIO",
    Min = 0,
    Max = 1,
    Default = UITheme.GetEnvironmentVolume(),
    Step = 0.05,
    Parent = settingsScroll,
    OnChange = function(val: number)
        UITheme.SetEnvironmentVolume(val)
    end,
})

-- 5. Look Sensitivity (0.2x to 3.0x)
UI.Slider.Create({
    Label = "LOOK SENSITIVITY",
    Min = 0.2,
    Max = 3.0,
    Default = UITheme.GetMouseSensitivity(),
    Step = 0.1,
    ValueFormat = function(v: number)
        return string.format("%.1fx", v)
    end,
    Parent = settingsScroll,
    OnChange = function(val: number)
        UITheme.SetMouseSensitivity(val)
    end,
})

-- 6. Reduced Motion Toggle
UI.Toggle.Create({
    Label = "REDUCED MOTION",
    Description = "Disables background embers & breathing animations",
    InitialValue = reducedMotionEnabled,
    Parent = settingsScroll,
    OnChanged = function(enabled: boolean)
        reducedMotionEnabled = enabled
        emberSystem:SetReducedMotion(enabled)
        emblem:SetReducedMotion(enabled)
        if bgVideo then
            if enabled then
                bgVideo:Pause()
            else
                bgVideo:Play()
            end
        end
    end,
})

local creditsModal = UI.Modal.Create({
    Id = "CreditsModal",
    Title = "CREDITS",
    Subtitle = "PRODUCTION TEAM & SYSTEMS ARCHITECTURE",
    Width = UDim.new(0.44, 0),
    Height = UDim.new(0.56, 0),
    Parent = screenGui,
})

local creditsLayout = Instance.new("UIListLayout")
creditsLayout.FillDirection = Enum.FillDirection.Vertical
creditsLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
creditsLayout.Padding = UDim.new(0, 10)
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
    roleLbl.Font = UI.Theme.Fonts.Heading
    roleLbl.Text = role
    roleLbl.TextColor3 = UI.Theme.Colors.TextMuted
    roleLbl.TextSize = 10
    roleLbl.TextXAlignment = Enum.TextXAlignment.Left
    roleLbl.ZIndex = 44
    roleLbl.Parent = row

    local nameLbl = Instance.new("TextLabel")
    nameLbl.Size = UDim2.new(1, 0, 0, 20)
    nameLbl.Position = UDim2.new(0, 0, 0, 14)
    nameLbl.BackgroundTransparency = 1
    nameLbl.Font = UI.Theme.Fonts.Heading
    nameLbl.Text = name
    nameLbl.TextColor3 = isAccent and UI.Theme.Colors.EmberHot or UI.Theme.Colors.TextPrimary
    nameLbl.TextSize = isAccent and 15 or 14
    nameLbl.TextXAlignment = Enum.TextXAlignment.Left
    nameLbl.ZIndex = 44
    nameLbl.Parent = row
end

addCreditItem("PRODUCED & DEVELOPED BY", "FLUENOSITY STUDIO", true)
addCreditItem("ENGINEERING & SYSTEMS ARCHITECTURE", "Fluenosity Studio Core Team", false)
addCreditItem("ATMOSPHERIC ART & AUDIO DIRECTION", "Fluenosity Studio", false)

UI.Divider.Create({ Parent = creditsModal.Content })

local quoteBox = Instance.new("Frame")
quoteBox.Size = UDim2.new(1, 0, 0, 36)
quoteBox.BackgroundColor3 = UI.Theme.Colors.GlassSurface
quoteBox.BackgroundTransparency = 0.35
quoteBox.BorderSizePixel = 0
quoteBox.ZIndex = 44
quoteBox.Parent = creditsModal.Content

local quoteCorner = Instance.new("UICorner")
quoteCorner.CornerRadius = UDim.new(0, 8)
quoteCorner.Parent = quoteBox

local quoteStroke = Instance.new("UIStroke")
quoteStroke.Thickness = 1.0
quoteStroke.Color = UI.Theme.Colors.BorderSubtle
quoteStroke.Transparency = 0.5
quoteStroke.Parent = quoteBox

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
-- RIGHT SURVIVOR SELECTION PANEL (Dedicated Luxury Character Selection)
--------------------------------------------------------------------------------
local selectedGender = "Male"

rightArea = UI.Panel.Create({
    Name = "RightSurvivorArea",
    Size = UDim2.new(0, 320, 0, 290),
    Position = UDim2.new(1, -48, 0.46, 0),
    AnchorPoint = Vector2.new(1, 0.5),
    CornerRadius = 14,
    Parent = safeArea,
})
rightArea.Visible = false

local rightLayout = Instance.new("UIListLayout")
rightLayout.FillDirection = Enum.FillDirection.Vertical
rightLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
rightLayout.VerticalAlignment = Enum.VerticalAlignment.Top
rightLayout.SortOrder = Enum.SortOrder.LayoutOrder
rightLayout.Padding = UDim.new(0, 10)
rightLayout.Parent = rightArea

-- Header Container
local panelHeaderBox = Instance.new("Frame")
panelHeaderBox.Name = "HeaderBox"
panelHeaderBox.Size = UDim2.new(1, 0, 0, 42)
panelHeaderBox.LayoutOrder = 1
panelHeaderBox.BackgroundTransparency = 1
panelHeaderBox.ZIndex = 9
panelHeaderBox.Parent = rightArea

local panelTag = Instance.new("TextLabel")
panelTag.Name = "Tag"
panelTag.Size = UDim2.new(1, 0, 0, 14)
panelTag.BackgroundTransparency = 1
panelTag.Font = UI.Theme.Fonts.Heading
panelTag.Text = "[ SURVIVOR ROSTER ]"
panelTag.TextColor3 = UI.Theme.Colors.EmberHot
panelTag.TextSize = 10
panelTag.TextXAlignment = Enum.TextXAlignment.Left
panelTag.ZIndex = 9
panelTag.Parent = panelHeaderBox

local panelTitle = Instance.new("TextLabel")
panelTitle.Name = "Title"
panelTitle.Size = UDim2.new(1, 0, 0, 24)
panelTitle.Position = UDim2.new(0, 0, 0, 16)
panelTitle.BackgroundTransparency = 1
panelTitle.Font = UI.Theme.Fonts.Title
panelTitle.Text = "SELECT SURVIVOR"
panelTitle.TextColor3 = UI.Theme.Colors.TextPrimary
panelTitle.TextSize = 18
panelTitle.TextXAlignment = Enum.TextXAlignment.Left
panelTitle.ZIndex = 9
panelTitle.Parent = panelHeaderBox

-- Hairline Divider
UI.Divider.Create({
    LayoutOrder = 2,
    Parent = rightArea,
})

-- Helper to create a luxury survivor card with modular glassmorphism & Lucide vector icons
local function createSurvivorCard(gender: string, titleText: string, subText: string, order: number)
    local cardBtn = Instance.new("TextButton")
    cardBtn.Name = "Card_" .. gender
    cardBtn.Size = UDim2.new(1, 0, 0, 84)
    cardBtn.LayoutOrder = order
    cardBtn.AutoButtonColor = false
    cardBtn.Active = true
    cardBtn.Selectable = true
    cardBtn.Text = ""
    cardBtn.BackgroundColor3 = UI.Theme.Colors.GlassSurface
    cardBtn.BackgroundTransparency = UI.Theme.Transparency.Card
    cardBtn.BorderSizePixel = 0
    cardBtn.ZIndex = 10
    cardBtn.Parent = rightArea

    UI.Theme.ApplyGlass(cardBtn, {
        CornerRadius = 10,
        StrokeColor = UI.Theme.Colors.BorderSubtle,
        StrokeThickness = 1.2,
    })

    local uiScale = Instance.new("UIScale")
    uiScale.Scale = 1.0
    uiScale.Parent = cardBtn

    cardBtn.MouseButton1Down:Connect(function()
        TweenService:Create(uiScale, UI.Theme.Tweens.Snap, { Scale = 0.98 }):Play()
    end)
    cardBtn.MouseButton1Up:Connect(function()
        TweenService:Create(uiScale, UI.Theme.Tweens.Snap, { Scale = 1.0 }):Play()
    end)

    -- Left Icon Box with Lucide vector user icon
    local iconBox = Instance.new("Frame")
    iconBox.Name = "IconBox"
    iconBox.Size = UDim2.fromOffset(40, 40)
    iconBox.Position = UDim2.new(0, 12, 0.5, 0)
    iconBox.AnchorPoint = Vector2.new(0, 0.5)
    iconBox.BackgroundColor3 = UI.Theme.Colors.GlassElevated
    iconBox.BackgroundTransparency = 0.35
    iconBox.ZIndex = 11
    iconBox.Parent = cardBtn

    local ibCorner = Instance.new("UICorner")
    ibCorner.CornerRadius = UDim.new(0, 8)
    ibCorner.Parent = iconBox

    local icon = IconPack.CreateIcon("user", 20, UI.Theme.Colors.TextPrimary, 0)
    icon.Name = "UserIcon"
    icon.Position = UDim2.fromScale(0.5, 0.5)
    icon.AnchorPoint = Vector2.new(0.5, 0.5)
    icon.ZIndex = 12
    icon.Parent = iconBox

    -- Center Text Group
    local titleLbl = Instance.new("TextLabel")
    titleLbl.Name = "Title"
    titleLbl.Size = UDim2.new(1, -145, 0, 20)
    titleLbl.Position = UDim2.new(0, 60, 0, 18)
    titleLbl.BackgroundTransparency = 1
    titleLbl.Font = UI.Theme.Fonts.Heading
    titleLbl.Text = titleText
    titleLbl.TextSize = 13
    titleLbl.TextColor3 = UI.Theme.Colors.TextPrimary
    titleLbl.TextXAlignment = Enum.TextXAlignment.Left
    titleLbl.ZIndex = 11
    titleLbl.Parent = cardBtn

    local descLbl = Instance.new("TextLabel")
    descLbl.Name = "Desc"
    descLbl.Size = UDim2.new(1, -145, 0, 16)
    descLbl.Position = UDim2.new(0, 60, 0, 40)
    descLbl.BackgroundTransparency = 1
    descLbl.Font = UI.Theme.Fonts.Body
    descLbl.Text = subText
    descLbl.TextSize = 11
    descLbl.TextColor3 = UI.Theme.Colors.TextMuted
    descLbl.TextXAlignment = Enum.TextXAlignment.Left
    descLbl.ZIndex = 11
    descLbl.Parent = cardBtn

    -- Right Status Badge using UI.Badge
    local statusBadge = UI.Badge.Create({
        Text = "SELECT",
        Variant = "Glass",
        Position = UDim2.new(1, -12, 0.5, 0),
        AnchorPoint = Vector2.new(1, 0.5),
        ZIndex = 12,
        Parent = cardBtn,
    })
    local badgeText = statusBadge:FindFirstChild("Text") :: TextLabel
    local badgeStroke = statusBadge:FindFirstChildOfClass("UIStroke")
    local cardStroke = cardBtn:FindFirstChildOfClass("UIStroke")

    return {
        Button = cardBtn,
        Stroke = cardStroke,
        IconBox = iconBox,
        Icon = icon,
        TitleLabel = titleLbl,
        DescLabel = descLbl,
        Badge = statusBadge,
        BadgeStroke = badgeStroke,
        BadgeText = badgeText,
    }
end

local maleCard = createSurvivorCard("Male", "MALE SURVIVOR", "Semi-Realistic Male", 3)
local femaleCard = createSurvivorCard("Female", "FEMALE SURVIVOR", "Semi-Realistic Female", 4)

local function updateSurvivorCards()
    if selectedGender == "Male" then
        -- Highlight Male Card (Warm Obsidian/Ember Glass Glow)
        maleCard.Button.BackgroundColor3 = Color3.fromRGB(46, 26, 18)
        maleCard.Button.BackgroundTransparency = 0.16
        if maleCard.Stroke then
            maleCard.Stroke.Color = UI.Theme.Colors.BorderGlow
            maleCard.Stroke.Transparency = 0.0
            maleCard.Stroke.Thickness = 1.8
        end
        maleCard.Icon.ImageColor3 = UI.Theme.Colors.EmberHot
        maleCard.TitleLabel.TextColor3 = UI.Theme.Colors.EmberGold
        maleCard.DescLabel.TextColor3 = Color3.fromRGB(240, 180, 120)
        maleCard.Badge.BackgroundColor3 = Color3.fromRGB(75, 32, 16)
        maleCard.Badge.BackgroundTransparency = 0.1
        if maleCard.BadgeStroke then
            maleCard.BadgeStroke.Color = UI.Theme.Colors.BorderEmber
            maleCard.BadgeStroke.Transparency = 0.0
        end
        maleCard.BadgeText.Text = "✔ ACTIVE"
        maleCard.BadgeText.TextColor3 = UI.Theme.Colors.EmberGold

        -- De-highlight Female Card
        femaleCard.Button.BackgroundColor3 = UI.Theme.Colors.GlassSurface
        femaleCard.Button.BackgroundTransparency = UI.Theme.Transparency.Card
        if femaleCard.Stroke then
            femaleCard.Stroke.Color = UI.Theme.Colors.BorderSubtle
            femaleCard.Stroke.Transparency = 0.5
            femaleCard.Stroke.Thickness = 1.0
        end
        femaleCard.Icon.ImageColor3 = UI.Theme.Colors.TextMuted
        femaleCard.TitleLabel.TextColor3 = UI.Theme.Colors.TextPrimary
        femaleCard.DescLabel.TextColor3 = UI.Theme.Colors.TextMuted
        femaleCard.Badge.BackgroundColor3 = UI.Theme.Colors.GlassElevated
        femaleCard.Badge.BackgroundTransparency = 0.35
        if femaleCard.BadgeStroke then
            femaleCard.BadgeStroke.Color = UI.Theme.Colors.BorderGlass
            femaleCard.BadgeStroke.Transparency = 0.6
        end
        femaleCard.BadgeText.Text = "SELECT"
        femaleCard.BadgeText.TextColor3 = UI.Theme.Colors.TextMuted
    else
        -- Highlight Female Card (Warm Obsidian/Ember Glass Glow)
        femaleCard.Button.BackgroundColor3 = Color3.fromRGB(46, 26, 18)
        femaleCard.Button.BackgroundTransparency = 0.16
        if femaleCard.Stroke then
            femaleCard.Stroke.Color = UI.Theme.Colors.BorderGlow
            femaleCard.Stroke.Transparency = 0.0
            femaleCard.Stroke.Thickness = 1.8
        end
        femaleCard.Icon.ImageColor3 = UI.Theme.Colors.EmberHot
        femaleCard.TitleLabel.TextColor3 = UI.Theme.Colors.EmberGold
        femaleCard.DescLabel.TextColor3 = Color3.fromRGB(240, 180, 120)
        femaleCard.Badge.BackgroundColor3 = Color3.fromRGB(75, 32, 16)
        femaleCard.Badge.BackgroundTransparency = 0.1
        if femaleCard.BadgeStroke then
            femaleCard.BadgeStroke.Color = UI.Theme.Colors.BorderEmber
            femaleCard.BadgeStroke.Transparency = 0.0
        end
        femaleCard.BadgeText.Text = "✔ ACTIVE"
        femaleCard.BadgeText.TextColor3 = UI.Theme.Colors.EmberGold

        -- De-highlight Male Card
        maleCard.Button.BackgroundColor3 = UI.Theme.Colors.GlassSurface
        maleCard.Button.BackgroundTransparency = UI.Theme.Transparency.Card
        if maleCard.Stroke then
            maleCard.Stroke.Color = UI.Theme.Colors.BorderSubtle
            maleCard.Stroke.Transparency = 0.5
            maleCard.Stroke.Thickness = 1.0
        end
        maleCard.Icon.ImageColor3 = UI.Theme.Colors.TextMuted
        maleCard.TitleLabel.TextColor3 = UI.Theme.Colors.TextPrimary
        maleCard.DescLabel.TextColor3 = UI.Theme.Colors.TextMuted
        maleCard.Badge.BackgroundColor3 = UI.Theme.Colors.GlassElevated
        maleCard.Badge.BackgroundTransparency = 0.35
        if maleCard.BadgeStroke then
            maleCard.BadgeStroke.Color = UI.Theme.Colors.BorderGlass
            maleCard.BadgeStroke.Transparency = 0.6
        end
        maleCard.BadgeText.Text = "SELECT"
        maleCard.BadgeText.TextColor3 = UI.Theme.Colors.TextMuted
    end
end

updateSurvivorCards()

local function wireCardEvents(cardData: any, gender: string)
    local function selectThisGender()
        if selectedGender ~= gender then
            selectedGender = gender
            updateSurvivorCards()
            UI.Theme.PlayClick()
        end
    end

    cardData.Button.Activated:Connect(selectThisGender)
    cardData.Button.MouseButton1Click:Connect(selectThisGender)

    -- Gentle visual ease on hover (no audio, no bouncing scale!)
    cardData.Button.MouseEnter:Connect(function()
        if selectedGender ~= gender then
            cardData.Button.BackgroundTransparency = 0.20
            if cardData.Stroke then
                cardData.Stroke.Color = UI.Theme.Colors.BorderGlass
                cardData.Stroke.Transparency = 0.25
            end
        end
    end)

    cardData.Button.MouseLeave:Connect(function()
        if selectedGender ~= gender then
            cardData.Button.BackgroundTransparency = UI.Theme.Transparency.Card
            if cardData.Stroke then
                cardData.Stroke.Color = UI.Theme.Colors.BorderSubtle
                cardData.Stroke.Transparency = 0.5
            end
        end
    end)
end

wireCardEvents(maleCard, "Male")
wireCardEvents(femaleCard, "Female")

--------------------------------------------------------------------------------
-- INTERACTIVE NAV ACTIONS (ORDER: 1. PLAY, 2. SETTINGS, 3. CREDITS)
--------------------------------------------------------------------------------
local function beginGame(selection: any)
    if menuCameraConn then
        menuCameraConn:Disconnect()
        menuCameraConn = nil
    end

    local fadeTime = reducedMotionEnabled and 0.25 or 0.45
    local fadeInfo = TweenInfo.new(fadeTime, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

    -- Smooth cinematic camera glide down from high 3/4 crane into the campsite
    if camera then
        local glideTargetCFrame = CFrame.lookAt(Vector3.new(1.5, 14.5, -408), campCenter)
        TweenService:Create(camera, TweenInfo.new(1.2, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut), {
            CFrame = glideTargetCFrame,
        }):Play()
    end

    -- Fade the main menu navigation cleanly
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

    loadingScreen.Show({
        Status = "CONNECTING TO FOREST SECTOR...",
        Tip = "The campfire is your only safe haven. When it dies, the forest claims you.",
        Progress = 0.05,
        Detail = "Preloading environment assets & compiling shaders...",
    })

    LoadingManager.LoadGame(loadingScreen, function()
        hasIntroCompleted = true
        emberSystem:Destroy()
        emblem:Destroy()
        if bgVideo then
            bgVideo:Pause()
            bgVideo:Destroy()
        end
        wardrobeScreen.Destroy()
        screenGui:Destroy()
        player:SetAttribute("IsInGameplay", true)
        setCharacterControlsEnabled(true)
        if camera then
            camera.CameraType = Enum.CameraType.Custom
        end
    end, selection)
end

local navPlay = UI.Button.Create({
    Text = "PLAY",
    Subtext = "ENTER WILDERNESS",
    Variant = "Primary",
    IconName = "flame",
    IconSize = 18,
    Size = UDim2.new(1, 0, 0, 52),
    LayoutOrder = 1,
    Parent = navContainer,
    OnClick = function()
        if isBusy then return end
        isBusy = true
        wardrobeScreen.Open(function()
            isBusy = false
        end, function(selection)
            beginGame(selection)
        end)
    end,
})

-- 2. SURVIVOR WARDROBE Action (Dedicated button to inspect and choose survivors)
local navWardrobe = UI.Button.Create({
    Text = "SURVIVORS",
    Subtext = "ROSTER & PREVIEW",
    Variant = "Secondary",
    IconName = "user",
    IconSize = 16,
    Size = UDim2.new(1, 0, 0, 46),
    LayoutOrder = 2,
    Parent = navContainer,
    OnClick = function()
        if isBusy then return end
        isBusy = true
        wardrobeScreen.Open(function()
            isBusy = false
        end, function(selection)
            beginGame(selection)
        end)
    end,
})

-- 3. SETTINGS Action (Secondary Glassmorphic button with Lucide Settings Icon)
local navSettings = UI.Button.Create({
    Text = "SETTINGS",
    Subtext = "AUDIO & CONTROLS",
    Variant = "Secondary",
    IconName = "settings",
    IconSize = 16,
    Size = UDim2.new(1, 0, 0, 46),
    LayoutOrder = 3,
    Parent = navContainer,
    OnClick = function()
        settingsModal.Open()
    end,
})

-- 4. CREDITS Action (Secondary Glassmorphic button with Lucide Sparkles Icon)
local navCredits = UI.Button.Create({
    Text = "CREDITS",
    Subtext = "FLUENOSITY STUDIO",
    Variant = "Secondary",
    IconName = "sparkles",
    IconSize = 16,
    Size = UDim2.new(1, 0, 0, 46),
    LayoutOrder = 4,
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
        splashScreen.BackgroundColor3 = (UITheme.Colors and UITheme.Colors.PureWhite) or Color3.fromRGB(255, 255, 255)
        splashScreen.BorderSizePixel = 0
        splashScreen.ZIndex = 60
        splashScreen.Parent = screenGui

        local studioTitle = Instance.new("TextLabel")
        studioTitle.Name = "StudioTitle"
        studioTitle.Size = UDim2.new(0.9, 0, 0, 36)
        studioTitle.Position = UDim2.fromScale(0.5, 0.5)
        studioTitle.AnchorPoint = Vector2.new(0.5, 0.5)
        studioTitle.BackgroundTransparency = 1
        studioTitle.Font = (UITheme.Fonts and UITheme.Fonts.Studio) or Enum.Font.GothamMedium
        studioTitle.Text = "A  F L U E N O S I T Y   S T U D I O   P R O D U C T I O N"
        studioTitle.TextColor3 = (UITheme.Colors and UITheme.Colors.TextStudioSplash) or Color3.fromRGB(245, 248, 255)
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
    -- PHASE 3: STAGGERED ENTRANCE FROM THE LEFT AND RIGHT
    ----------------------------------------------------------------------------
    leftArea.Visible = true
    if rightArea then
        rightArea.Visible = false
    end

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
