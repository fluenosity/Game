--!strict
--[[
    MainMenu.client.lua
    Production-grade client intro sequence and interactive main menu for
    "Don't Let the Fire Die". Developed for Fluenosity Studio.
    
    Architecture:
    - Native vector rendering (NO CanvasGroup rasterization blur—100% crisp at 4K)
    - Dynamic responsive Viewport UIScale controller (Desktop, Tablet, Mobile)
    - Reusable UI component architecture via UIComponents & UITheme
    - Seamless Unreal/Unity game lifecycle (Frontend menu -> server character spawn on Play)
    - Fully accessible: Master Volume audio routing & Reduced Motion controls
]]

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local SoundService = game:GetService("SoundService")
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
-- STATE MACHINE
--------------------------------------------------------------------------------
local isBusy = false
local hasIntroCompleted = false
local reducedMotionEnabled = false

-- Camera reference
local camera = workspace.CurrentCamera
if not camera then
    camera = workspace:WaitForChild("Camera", 5) :: Camera
end

--------------------------------------------------------------------------------
-- PLAYER CONTROLS HELPER
--------------------------------------------------------------------------------
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

-- Lock camera and controls during frontend menu state
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

-- Master Responsive Scaler Container
local responsiveContainer = Instance.new("Frame")
responsiveContainer.Name = "ResponsiveContainer"
responsiveContainer.Size = UDim2.fromScale(1, 1)
responsiveContainer.Position = UDim2.fromScale(0, 0)
responsiveContainer.BackgroundTransparency = 1
responsiveContainer.Parent = screenGui

local uiScale = Instance.new("UIScale")
uiScale.Parent = responsiveContainer

local function updateResponsiveScale()
    if not camera then return end
    local viewport = camera.ViewportSize
    if viewport.X == 0 or viewport.Y == 0 then return end
    -- Reference resolution: 1280x720. Auto-scale smoothly for 4K down to phone screens
    local scaleX = viewport.X / 1280
    local scaleY = viewport.Y / 720
    local scale = math.clamp(math.min(scaleX, scaleY), 0.70, 1.25)
    uiScale.Scale = scale
end

updateResponsiveScale()
if camera then
    camera:GetPropertyChangedSignal("ViewportSize"):Connect(updateResponsiveScale)
end

--------------------------------------------------------------------------------
-- ATMOSPHERIC BACKGROUND & EMBER PARTICLES
--------------------------------------------------------------------------------
local background = Instance.new("Frame")
background.Name = "Background"
background.Size = UDim2.fromScale(1, 1)
background.BackgroundColor3 = UITheme.Colors.Void
background.BorderSizePixel = 0
background.ZIndex = 1
background.Parent = responsiveContainer

-- Ambient warm firelight radial gradient at center-bottom
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
    ColorSequenceKeypoint.new(0.65, UITheme.Colors.EmberCrimson),
    ColorSequenceKeypoint.new(1, UITheme.Colors.Void),
})
fireGrad.Transparency = NumberSequence.new({
    NumberSequenceKeypoint.new(0, 0.82),
    NumberSequenceKeypoint.new(0.65, 0.94),
    NumberSequenceKeypoint.new(1, 1),
})
fireGrad.Rotation = 90
fireGrad.Parent = ambientFirelight
ambientFirelight.Parent = background

-- Floating embers particle system
local emberSystem = EmberParticles.new(background)

--------------------------------------------------------------------------------
-- MAIN CONTENT CONTAINER
--------------------------------------------------------------------------------
local mainContent = Instance.new("Frame")
mainContent.Name = "MainContent"
mainContent.Size = UDim2.fromScale(1, 1)
mainContent.Position = UDim2.fromScale(0.5, 0.5)
mainContent.AnchorPoint = Vector2.new(0.5, 0.5)
mainContent.BackgroundTransparency = 1
mainContent.ZIndex = 5
mainContent.Parent = responsiveContainer

--------------------------------------------------------------------------------
-- BRANDING: LOGO & TITLE (Native Vector Primitives—Zero CanvasGroup Blur)
--------------------------------------------------------------------------------
local brandingGroup = Instance.new("Frame")
brandingGroup.Name = "BrandingGroup"
brandingGroup.Size = UDim2.new(0, 600, 0, 240)
brandingGroup.Position = UDim2.fromScale(0.5, 0.48) -- Initial centered position for reveal
brandingGroup.AnchorPoint = Vector2.new(0.5, 0.5)
brandingGroup.BackgroundTransparency = 1
brandingGroup.Visible = false
brandingGroup.ZIndex = 6
brandingGroup.Parent = mainContent

local brandingLayout = Instance.new("UIListLayout")
brandingLayout.FillDirection = Enum.FillDirection.Vertical
brandingLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
brandingLayout.VerticalAlignment = Enum.VerticalAlignment.Center
brandingLayout.Padding = UDim.new(0, 12)
brandingLayout.Parent = brandingGroup

-- Native Sharp Campfire Emblem
local emblem = CampfireEmblem.new(UDim2.fromOffset(130, 130))
emblem.Root.Parent = brandingGroup

-- Title Text: DON'T LET THE FIRE DIE (100% Vector Crispness)
local titleLabel = Instance.new("TextLabel")
titleLabel.Name = "Title"
titleLabel.Size = UDim2.new(1, 0, 0, 46)
titleLabel.BackgroundTransparency = 1
titleLabel.Font = UITheme.Fonts.Title
titleLabel.Text = "DON'T LET THE FIRE DIE"
titleLabel.TextColor3 = UITheme.Colors.TextPrimary
titleLabel.TextSize = 34
titleLabel.TextTransparency = 1
titleLabel.TextStrokeColor3 = Color3.fromRGB(16, 10, 8)
titleLabel.TextStrokeTransparency = 0.35
titleLabel.ZIndex = 7
titleLabel.Parent = brandingGroup

local titleConstraint = Instance.new("UITextSizeConstraint")
titleConstraint.MaxTextSize = 36
titleConstraint.MinTextSize = 22
titleConstraint.Parent = titleLabel

-- Subtitle Tagline
local subtitleLabel = Instance.new("TextLabel")
subtitleLabel.Name = "Subtitle"
subtitleLabel.Size = UDim2.new(1, 0, 0, 18)
subtitleLabel.BackgroundTransparency = 1
subtitleLabel.Font = UITheme.Fonts.Subheading
subtitleLabel.Text = "[ S U R V I V A L   H O R R O R   •   F L U E N O S I T Y   S T U D I O ]"
subtitleLabel.TextColor3 = UITheme.Colors.EmberHot
subtitleLabel.TextSize = 12
subtitleLabel.TextTransparency = 1
subtitleLabel.ZIndex = 7
subtitleLabel.Parent = brandingGroup

--------------------------------------------------------------------------------
-- MENU BUTTONS CONTAINER
--------------------------------------------------------------------------------
local buttonsContainer = Instance.new("Frame")
buttonsContainer.Name = "ButtonsContainer"
buttonsContainer.Size = UDim2.new(0, 290, 0, 210)
buttonsContainer.Position = UDim2.fromScale(0.5, 0.76)
buttonsContainer.AnchorPoint = Vector2.new(0.5, 0.5)
buttonsContainer.BackgroundTransparency = 1
buttonsContainer.Visible = false
buttonsContainer.ZIndex = 8
buttonsContainer.Parent = mainContent

local buttonsLayout = Instance.new("UIListLayout")
buttonsLayout.FillDirection = Enum.FillDirection.Vertical
buttonsLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
buttonsLayout.VerticalAlignment = Enum.VerticalAlignment.Center
buttonsLayout.Padding = UDim.new(0, 12)
buttonsLayout.Parent = buttonsContainer

-- Footer Watermark
local footer = Instance.new("TextLabel")
footer.Name = "Footer"
footer.Size = UDim2.new(1, 0, 0, 20)
footer.Position = UDim2.fromScale(0.5, 0.97)
footer.AnchorPoint = Vector2.new(0.5, 1)
footer.BackgroundTransparency = 1
footer.Font = UITheme.Fonts.Tag
footer.Text = "DON'T LET THE FIRE DIE • v0.1.0-ALPHA • ENGINE: ROBLOX LUAU • ROJO 7.7.1"
footer.TextColor3 = UITheme.Colors.TextSubdued
footer.TextSize = 10
footer.TextTransparency = 1
footer.ZIndex = 6
footer.Parent = mainContent

--------------------------------------------------------------------------------
-- MODALS (SETTINGS & CREDITS)
--------------------------------------------------------------------------------
-- 1. SETTINGS MODAL
local settingsModal = UIComponents.CreateModal({
    Title = "SETTINGS",
    CategoryTag = "[ CONFIGURATION ]",
    Width = 430,
    Height = 390,
    Parent = responsiveContainer,
})

local settingsLayout = Instance.new("UIListLayout")
settingsLayout.FillDirection = Enum.FillDirection.Vertical
settingsLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
settingsLayout.Padding = UDim.new(0, 18)
settingsLayout.Parent = settingsModal.Content

-- Master Volume Slider
UIComponents.CreateSlider({
    Label = "MASTER VOLUME",
    Description = "Controls game-wide sound effects & ambience",
    InitialValue = UITheme.GetMasterVolume(),
    Parent = settingsModal.Content,
    OnChanged = function(val: number)
        UITheme.SetMasterVolume(val)
    end,
})

-- Hairline Divider
UIComponents.CreateDivider(settingsModal.Content)

-- Reduced Motion Toggle
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

-- 2. CREDITS MODAL
local creditsModal = UIComponents.CreateModal({
    Title = "CREDITS",
    CategoryTag = "[ PRODUCTION TEAM ]",
    Width = 450,
    Height = 410,
    Parent = responsiveContainer,
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
    row.ZIndex = 34
    row.Parent = creditsModal.Content

    local roleLbl = Instance.new("TextLabel")
    roleLbl.Size = UDim2.new(1, 0, 0, 14)
    roleLbl.BackgroundTransparency = 1
    roleLbl.Font = UITheme.Fonts.Tag
    roleLbl.Text = role
    roleLbl.TextColor3 = UITheme.Colors.TextMuted
    roleLbl.TextSize = 10
    roleLbl.TextXAlignment = Enum.TextXAlignment.Left
    roleLbl.ZIndex = 34
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
    nameLbl.ZIndex = 34
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
quoteBox.ZIndex = 34
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
quoteText.ZIndex = 35
quoteText.Parent = quoteBox

--------------------------------------------------------------------------------
-- INTERACTIVE BUTTONS
--------------------------------------------------------------------------------
-- 1. PLAY BUTTON (Primary Action)
UIComponents.CreateButton({
    Text = "PLAY",
    Subtext = "ENTER THE CABIN",
    Width = 280,
    Height = 54,
    IsPrimary = true,
    Parent = buttonsContainer,
    OnClick = function()
        if isBusy then return end
        isBusy = true

        local fadeTime = reducedMotionEnabled and 0.25 or 0.5
        local fadeInfo = TweenInfo.new(fadeTime, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

        -- Fade out branding & buttons
        TweenService:Create(titleLabel, fadeInfo, { TextTransparency = 1 }):Play()
        TweenService:Create(subtitleLabel, fadeInfo, { TextTransparency = 1 }):Play()
        TweenService:Create(footer, fadeInfo, { TextTransparency = 1 }):Play()
        emblem:AnimateFade(1, fadeInfo)

        for _, btn in ipairs(buttonsContainer:GetChildren()) do
            if btn:IsA("GuiObject") then
                for _, desc in ipairs(btn:GetDescendants()) do
                    if desc:IsA("TextLabel") then
                        TweenService:Create(desc, fadeInfo, { TextTransparency = 1 }):Play()
                    elseif desc:IsA("UIStroke") then
                        TweenService:Create(desc, fadeInfo, { Transparency = 1 }):Play()
                    elseif desc:IsA("Frame") or desc:IsA("TextButton") then
                        TweenService:Create(desc, fadeInfo, { BackgroundTransparency = 1 }):Play()
                    end
                end
            end
        end

        -- Fade out atmospheric background
        local bgFade = TweenService:Create(background, fadeInfo, { BackgroundTransparency = 1 })
        TweenService:Create(ambientFirelight, fadeInfo, { BackgroundTransparency = 1 }):Play()
        bgFade:Play()

        emberSystem:Stop()

        -- Signal server to spawn player character into the world
        local sharedFolder = ReplicatedStorage:WaitForChild("FluenosityShared", 3)
        if sharedFolder then
            local spawnEvent = sharedFolder:WaitForChild("RequestSpawnCharacter", 3) :: RemoteEvent?
            if spawnEvent then
                spawnEvent:FireServer()
            end
        end

        bgFade.Completed:Connect(function()
            -- Wait for character to spawn
            local character = player.Character
            if not character then
                character = player.CharacterAdded:Wait()
            end

            local humanoid = character:WaitForChild("Humanoid", 10) :: Humanoid?

            if camera then
                camera.CameraType = Enum.CameraType.Custom
                if humanoid then
                    camera.CameraSubject = humanoid
                end
            end

            setCharacterControlsEnabled(true)
            hasIntroCompleted = true

            emberSystem:Destroy()
            emblem:Destroy()
            screenGui:Destroy()
        end)
    end,
})

-- 2. SETTINGS BUTTON
UIComponents.CreateButton({
    Text = "SETTINGS",
    Subtext = "AUDIO & ACCESSIBILITY",
    Width = 280,
    Height = 50,
    IsPrimary = false,
    Parent = buttonsContainer,
    OnClick = function()
        settingsModal.Open()
    end,
})

-- 3. CREDITS BUTTON
UIComponents.CreateButton({
    Text = "CREDITS",
    Subtext = "DEVELOPMENT TEAM",
    Width = 280,
    Height = 50,
    IsPrimary = false,
    Parent = buttonsContainer,
    OnClick = function()
        creditsModal.Open()
    end,
})

--------------------------------------------------------------------------------
-- CINEMATIC INTRO SEQUENCE (SPLASH -> DARKNESS -> EMBERS -> LOGO -> MENU)
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
    studioTitle.TextSize = 18
    studioTitle.TextTransparency = 1
    studioTitle.ZIndex = 61
    studioTitle.Parent = splashScreen

    local studioConstraint = Instance.new("UITextSizeConstraint")
    studioConstraint.MaxTextSize = 20
    studioConstraint.MinTextSize = 13
    studioConstraint.Parent = studioTitle

    -- Fade in text
    local fadeInText = TweenService:Create(studioTitle, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        TextTransparency = 0,
    })
    fadeInText:Play()
    fadeInText.Completed:Wait()

    task.wait(1.0)

    -- Fade out text
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

    -- Center ember spark ignition
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
    -- PHASE 3: Crisp Logo & Title Reveal
    ----------------------------------------------------------------------------
    brandingGroup.Visible = true
    brandingGroup.Position = UDim2.fromScale(0.5, 0.48)
    emblem:SetTransparency(1)

    emblem:AnimateFade(0, UITheme.Tweens.Smooth)

    TweenService:Create(titleLabel, UITheme.Tweens.Normal, {
        TextTransparency = 0,
    }):Play()

    task.wait(0.15)
    TweenService:Create(subtitleLabel, UITheme.Tweens.Normal, {
        TextTransparency = 0,
    }):Play()

    task.wait(1.1)

    ----------------------------------------------------------------------------
    -- PHASE 4: Transition to Interactive Main Menu
    ----------------------------------------------------------------------------
    -- Glide branding smoothly to top header position
    local brandShift = TweenService:Create(brandingGroup, UITheme.Tweens.Smooth, {
        Position = UDim2.fromScale(0.5, 0.33),
    })
    brandShift:Play()

    task.wait(0.2)

    -- Present Buttons Container with upward slide
    buttonsContainer.Visible = true
    buttonsContainer.Position = UDim2.fromScale(0.5, 0.78)

    local buttonsSlide = TweenService:Create(buttonsContainer, UITheme.Tweens.Normal, {
        Position = UDim2.fromScale(0.5, 0.72),
    })
    buttonsSlide:Play()

    -- Fade in footer
    TweenService:Create(footer, UITheme.Tweens.Slow, {
        TextTransparency = 0,
    }):Play()

    brandShift.Completed:Wait()
    isBusy = false
end

task.spawn(runCinematicIntro)
