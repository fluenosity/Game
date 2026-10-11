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

if camera then
    camera.CameraType = Enum.CameraType.Scriptable
end
setCharacterControlsEnabled(false)

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
-- ATMOSPHERIC BACKGROUND & DRIFTING EMBERS
--------------------------------------------------------------------------------
local background = Instance.new("Frame")
background.Name = "Background"
background.Size = UDim2.fromScale(1, 1)
background.BackgroundColor3 = UITheme.Colors.Void
background.BorderSizePixel = 0
background.ZIndex = 1
background.Parent = screenGui

-- Ambient warm firelight radial gradient (biased to left where fire burns)
local ambientFirelight = Instance.new("Frame")
ambientFirelight.Name = "AmbientFirelight"
ambientFirelight.Size = UDim2.fromScale(1, 1)
ambientFirelight.BackgroundColor3 = UITheme.Colors.EmberCrimson
ambientFirelight.BackgroundTransparency = 0.94
ambientFirelight.BorderSizePixel = 0
ambientFirelight.ZIndex = 2

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
-- LEFT AREA: HEROIC TITLE, NAVIGATION (PLAY ON TOP) & PARTY SLOTS
--------------------------------------------------------------------------------
local leftArea = Instance.new("Frame")
leftArea.Name = "LeftArea"
leftArea.Size = UDim2.new(0.52, 0, 1, 0)
leftArea.Position = UDim2.new(0, 0, 0, 0)
leftArea.AnchorPoint = Vector2.new(0, 0)
leftArea.BackgroundTransparency = 1
leftArea.Visible = false
leftArea.ZIndex = 6
leftArea.Parent = safeArea

-- 1. Top Branding Group (Emblem + Title + Subtitle)
local brandingHeader = Instance.new("Frame")
brandingHeader.Name = "BrandingHeader"
brandingHeader.Size = UDim2.new(1, 0, 0, 100)
brandingHeader.Position = UDim2.new(0, 0, 0, 0)
brandingHeader.BackgroundTransparency = 1
brandingHeader.ZIndex = 7
brandingHeader.Parent = leftArea

-- Campfire Emblem
local emblem = CampfireEmblem.new(UDim2.fromOffset(80, 80))
emblem.Root.Position = UDim2.new(0, 40, 0, 40)
emblem.Root.AnchorPoint = Vector2.new(0.5, 0.5)
emblem.Root.Parent = brandingHeader

-- Title & Subtitle next to Emblem
local titleContainer = Instance.new("Frame")
titleContainer.Name = "TitleContainer"
titleContainer.Size = UDim2.new(1, -95, 1, 0)
titleContainer.Position = UDim2.new(0, 95, 0, 0)
titleContainer.BackgroundTransparency = 1
titleContainer.ZIndex = 7
titleContainer.Parent = brandingHeader

local titleLayout = Instance.new("UIListLayout")
titleLayout.FillDirection = Enum.FillDirection.Vertical
titleLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
titleLayout.VerticalAlignment = Enum.VerticalAlignment.Center
titleLayout.Padding = UDim.new(0, 2)
titleLayout.Parent = titleContainer

local mainTitle = Instance.new("TextLabel")
mainTitle.Name = "MainTitle"
mainTitle.Size = UDim2.new(1, 0, 0, 36)
mainTitle.BackgroundTransparency = 1
mainTitle.Font = UITheme.Fonts.Heading
mainTitle.Text = "DON'T LET THE FIRE DIE"
mainTitle.TextColor3 = UITheme.Colors.TextPrimary
mainTitle.TextScaled = true
mainTitle.TextWrapped = true
mainTitle.TextSize = 25
mainTitle.TextXAlignment = Enum.TextXAlignment.Left
mainTitle.TextStrokeColor3 = Color3.fromRGB(15, 8, 6)
mainTitle.TextStrokeTransparency = 0.25
mainTitle.ZIndex = 8
mainTitle.Parent = titleContainer

local mainTitleConstraint = Instance.new("UITextSizeConstraint")
mainTitleConstraint.MaxTextSize = 28
mainTitleConstraint.MinTextSize = 16
mainTitleConstraint.Parent = mainTitle

local subTitle = Instance.new("TextLabel")
subTitle.Name = "SubTitle"
subTitle.Size = UDim2.new(1, 0, 0, 18)
subTitle.BackgroundTransparency = 1
subTitle.Font = UITheme.Fonts.Heading
subTitle.Text = '"THE NIGHT WILL CLAIM YOU"'
subTitle.TextColor3 = UITheme.Colors.EmberCrimson
subTitle.TextSize = 13
subTitle.TextXAlignment = Enum.TextXAlignment.Left
subTitle.TextStrokeColor3 = Color3.fromRGB(12, 6, 6)
subTitle.TextStrokeTransparency = 0.3
subTitle.ZIndex = 8
subTitle.Parent = titleContainer

-- 2. Middle Navigation Actions Container
local navContainer = Instance.new("Frame")
navContainer.Name = "NavContainer"
navContainer.Size = UDim2.new(0, 300, 0, 190)
navContainer.Position = UDim2.new(0, 6, 0.46, 0)
navContainer.AnchorPoint = Vector2.new(0, 0.5)
navContainer.BackgroundTransparency = 1
navContainer.ZIndex = 9
navContainer.Parent = leftArea

local navLayout = Instance.new("UIListLayout")
navLayout.FillDirection = Enum.FillDirection.Vertical
navLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
navLayout.VerticalAlignment = Enum.VerticalAlignment.Center
navLayout.SortOrder = Enum.SortOrder.LayoutOrder -- CRITICAL: Strict LayoutOrder so PLAY is on top!
navLayout.Padding = UDim.new(0, 14)
navLayout.Parent = navContainer

-- 3. Bottom-Left Party / Co-op Slots (Anchored to exact bottom of LeftArea)
local partyContainer = Instance.new("Frame")
partyContainer.Name = "PartyContainer"
partyContainer.Size = UDim2.new(1, 0, 0, 70)
partyContainer.Position = UDim2.new(0, 0, 1, 0)
partyContainer.AnchorPoint = Vector2.new(0, 1) -- Anchored at bottom!
partyContainer.BackgroundTransparency = 1
partyContainer.ZIndex = 14
partyContainer.Parent = leftArea

local partyLayout = Instance.new("UIListLayout")
partyLayout.FillDirection = Enum.FillDirection.Horizontal
partyLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
partyLayout.VerticalAlignment = Enum.VerticalAlignment.Bottom
partyLayout.Padding = UDim.new(0, 12)
partyLayout.Parent = partyContainer

-- Slot 1: YOU (Player Avatar)
UIComponents.CreatePartySlot({
    Index = 1,
    IsPlayer = true,
    Player = player,
    Parent = partyContainer,
})

-- Slots 2, 3, 4: EMPTY [+] Slots
for i = 2, 4 do
    UIComponents.CreatePartySlot({
        Index = i,
        IsPlayer = false,
        Player = nil,
        Parent = partyContainer,
    })
end

--------------------------------------------------------------------------------
-- RIGHT AREA: SHOWCASE / ANNOUNCEMENT CARDS (Image 2 Style)
--------------------------------------------------------------------------------
local rightArea = Instance.new("Frame")
rightArea.Name = "RightArea"
rightArea.Size = UDim2.new(0, 340, 0, 370)
rightArea.Position = UDim2.new(1, 0, 0.5, 0)
rightArea.AnchorPoint = Vector2.new(1, 0.5) -- Anchored at right edge of safe area!
rightArea.BackgroundTransparency = 1
rightArea.Visible = false
rightArea.ZIndex = 14
rightArea.Parent = safeArea

local rightLayout = Instance.new("UIListLayout")
rightLayout.FillDirection = Enum.FillDirection.Vertical
rightLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
rightLayout.VerticalAlignment = Enum.VerticalAlignment.Center
rightLayout.Padding = UDim.new(0, 16)
rightLayout.Parent = rightArea

-- Card 1: Official Release / Day 0 Prologue
UIComponents.CreateFeatureCard({
    Title = "DAY 0: THE LONG NIGHT",
    Subtitle = "Survive the blizzard. Keep the fire burning.",
    BadgeText = "ALPHA RELEASE",
    BannerGradientColors = {
        ColorSequenceKeypoint.new(0, Color3.fromRGB(48, 22, 16)),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(86, 38, 22)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(18, 14, 20)),
    },
    Parent = rightArea,
})

-- Card 2: The Hollow Monster Stalker Lore
UIComponents.CreateFeatureCard({
    Title = "BEWARE THE HOLLOW",
    Subtitle = "When light fades, the shadows hunt.",
    BadgeText = "SURVIVAL INTEL",
    BannerGradientColors = {
        ColorSequenceKeypoint.new(0, Color3.fromRGB(22, 16, 28)),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(38, 22, 32)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(12, 10, 14)),
    },
    Parent = rightArea,
})

--------------------------------------------------------------------------------
-- PRODUCTION-GRADE RESPONSIVE ADAPTATION ENGINE
--------------------------------------------------------------------------------
local function updateLayoutResponsiveness()
    if not camera then return end
    local viewport = camera.ViewportSize
    if viewport.X == 0 or viewport.Y == 0 then return end

    local topInset, bottomInset = GuiService:GetGuiInset()
    local sidePad = math.clamp(math.round(viewport.X * 0.04), 24, 52)
    local topPad = math.max(topInset.Y, 44) + 14
    local botPad = math.max(bottomInset.Y, 16) + 16

    safePadding.PaddingTop = UDim.new(0, topPad)
    safePadding.PaddingBottom = UDim.new(0, botPad)
    safePadding.PaddingLeft = UDim.new(0, sidePad)
    safePadding.PaddingRight = UDim.new(0, sidePad)

    -- Dynamic vertical adapting for short screens (laptops / mobile landscape)
    if viewport.Y < 580 then
        brandingHeader.Size = UDim2.new(1, 0, 0, 75)
        emblem.Root.Size = UDim2.fromOffset(60, 60)
        emblem.Root.Position = UDim2.new(0, 30, 0, 30)
        titleContainer.Position = UDim2.new(0, 75, 0, 0)
        mainTitle.TextSize = 20
        subTitle.TextSize = 11
        partyContainer.Size = UDim2.new(1, 0, 0, 56)
        navContainer.Size = UDim2.new(0, 260, 0, 160)
        rightArea.Size = UDim2.new(0, 290, 0, 310)
    else
        brandingHeader.Size = UDim2.new(1, 0, 0, 100)
        emblem.Root.Size = UDim2.fromOffset(80, 80)
        emblem.Root.Position = UDim2.new(0, 40, 0, 40)
        titleContainer.Position = UDim2.new(0, 95, 0, 0)
        mainTitle.TextSize = 25
        subTitle.TextSize = 13
        partyContainer.Size = UDim2.new(1, 0, 0, 70)
        navContainer.Size = UDim2.new(0, 300, 0, 190)
        rightArea.Size = UDim2.new(0, 340, 0, 370)
    end

    -- Width adapting (Hide right column on narrow/phone screens < 820px)
    if viewport.X < 820 then
        rightArea.Visible = false
        leftArea.Size = UDim2.new(1, 0, 1, 0)
    else
        if hasIntroCompleted then
            rightArea.Visible = true
        end
        leftArea.Size = UDim2.new(0.52, 0, 1, 0)
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
    CategoryTag = "[ CONFIGURATION ]",
    Width = 440,
    Height = 390,
    Parent = screenGui,
})

local settingsLayout = Instance.new("UIListLayout")
settingsLayout.FillDirection = Enum.FillDirection.Vertical
settingsLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
settingsLayout.Padding = UDim.new(0, 18)
settingsLayout.Parent = settingsModal.Content

UIComponents.CreateSlider({
    Label = "MASTER VOLUME",
    Description = "Controls game-wide sound effects & ambience",
    InitialValue = UITheme.GetMasterVolume(),
    Parent = settingsModal.Content,
    OnChanged = function(val: number)
        UITheme.SetMasterVolume(val)
    end,
})

UIComponents.CreateDivider(settingsModal.Content)

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
UIComponents.CreateNavAction({
    Text = "PLAY",
    IsPrimary = true,
    LayoutOrder = 1, -- Strictly on top!
    Parent = navContainer,
    OnClick = function()
        if isBusy then return end
        isBusy = true

        local fadeTime = reducedMotionEnabled and 0.25 or 0.4
        local fadeInfo = TweenInfo.new(fadeTime, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

        -- 1. Smoothly fade out menu navigation & columns
        local leftSlide = TweenService:Create(leftArea, fadeInfo, {
            Position = UDim2.new(-0.06, 0, 0, 0),
        })
        local rightSlide = TweenService:Create(rightArea, fadeInfo, {
            Position = UDim2.new(1.06, 0, 0.5, 0),
        })
        leftSlide:Play()
        rightSlide:Play()

        for _, desc in ipairs(safeArea:GetDescendants()) do
            if desc:IsA("TextLabel") then
                TweenService:Create(desc, fadeInfo, { TextTransparency = 1 }):Play()
            elseif desc:IsA("UIStroke") then
                TweenService:Create(desc, fadeInfo, { Transparency = 1 }):Play()
            elseif desc:IsA("Frame") or desc:IsA("TextButton") then
                TweenService:Create(desc, fadeInfo, { BackgroundTransparency = 1 }):Play()
            end
        end

        -- 2. Fade in Cinematic Loading Screen with Bottom-Right Spinner & Survival Tip
        loadingScreen.Show({
            Status = "CONNECTING TO FOREST SECTOR...",
            Tip = "The campfire is your only safe haven. When it dies, the forest takes you.",
        })

        -- 3. Request server to spawn character into the world
        local sharedFolder = ReplicatedStorage:WaitForChild("FluenosityShared", 3)
        if sharedFolder then
            local spawnEvent = sharedFolder:WaitForChild("RequestSpawnCharacter", 3) :: RemoteEvent?
            if spawnEvent then
                spawnEvent:FireServer()
            end
        end

        task.spawn(function()
            -- Wait for character to spawn & physics to settle
            local character = player.Character
            if not character then
                character = player.CharacterAdded:Wait()
            end

            local humanoid = character:WaitForChild("Humanoid", 10) :: Humanoid?
            local rootPart = character:WaitForChild("HumanoidRootPart", 10)

            -- Update loading spinner status
            loadingScreen.SetStatus("WARMING CABIN...")

            -- Attach camera to character
            if camera and humanoid then
                camera.CameraType = Enum.CameraType.Custom
                camera.CameraSubject = humanoid
            end

            -- Allow world streaming to settle
            task.wait(0.6)

            -- Enable player controls
            setCharacterControlsEnabled(true)
            hasIntroCompleted = true

            -- Smoothly dissolve loading screen to reveal the world
            loadingScreen.Hide(function()
                emberSystem:Destroy()
                emblem:Destroy()
                screenGui:Destroy()
            end)
        end)
    end,
})

-- 2. SETTINGS Action (LayoutOrder = 2)
UIComponents.CreateNavAction({
    Text = "SETTINGS",
    IsPrimary = false,
    LayoutOrder = 2, -- Second
    Parent = navContainer,
    OnClick = function()
        settingsModal.Open()
    end,
})

-- 3. CREDITS Action (LayoutOrder = 3)
UIComponents.CreateNavAction({
    Text = "CREDITS",
    IsPrimary = false,
    LayoutOrder = 3, -- Third
    Parent = navContainer,
    OnClick = function()
        creditsModal.Open()
    end,
})

--------------------------------------------------------------------------------
-- CINEMATIC INTRO SEQUENCE (SPLASH -> DARKNESS -> EMBERS -> REVEAL)
--------------------------------------------------------------------------------
local function runCinematicIntro()
    isBusy = true

    ----------------------------------------------------------------------------
    -- PHASE 1: Pure White Studio Splash Screen (~2.0s)
    ----------------------------------------------------------------------------
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

    ----------------------------------------------------------------------------
    -- PHASE 2: Transition into Darkness & Spark Ignition
    ----------------------------------------------------------------------------
    local darkTransition = TweenService:Create(splashScreen, TweenInfo.new(0.7, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut), {
        BackgroundTransparency = 1,
    })
    darkTransition:Play()
    darkTransition.Completed:Wait()
    splashScreen:Destroy()

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
    -- PHASE 3: Center Reveal
    ----------------------------------------------------------------------------
    leftArea.Visible = true
    leftArea.Position = UDim2.new(0.25, 0, 0, 0)
    
    emblem:SetTransparency(1)
    emblem:AnimateFade(0, UITheme.Tweens.Smooth)

    mainTitle.TextTransparency = 1
    subTitle.TextTransparency = 1

    TweenService:Create(mainTitle, UITheme.Tweens.Normal, { TextTransparency = 0 }):Play()
    task.wait(0.15)
    TweenService:Create(subTitle, UITheme.Tweens.Normal, { TextTransparency = 0 }):Play()

    task.wait(0.9)

    ----------------------------------------------------------------------------
    -- PHASE 4: Glide into Safe Layout Position
    ----------------------------------------------------------------------------
    local leftGlide = TweenService:Create(leftArea, UITheme.Tweens.Smooth, {
        Position = UDim2.new(0, 0, 0, 0),
    })
    leftGlide:Play()

    task.wait(0.2)

    local viewport = camera and camera.ViewportSize or Vector2.new(1280, 720)
    if viewport.X >= 820 then
        rightArea.Visible = true
        rightArea.Position = UDim2.new(1.06, 0, 0.5, 0)
        TweenService:Create(rightArea, UITheme.Tweens.Normal, {
            Position = UDim2.new(1, 0, 0.5, 0),
        }):Play()
    end

    leftGlide.Completed:Wait()
    hasIntroCompleted = true
    isBusy = false
end

task.spawn(runCinematicIntro)
