--!strict
--[[
    MainMenu.client.lua
    Client-side intro sequence and interactive main menu for "Don't Let the Fire Die".
    Developed for Fluenosity Studio.
    
    Sequence:
    1. Pure White Studio Splash ("A FLUENOSITY STUDIO PRODUCTION", ~2s target)
    2. Transition into Darkness (warm ember ignition & floating sparks)
    3. Cinematic Game Logo Reveal ("DON'T LET THE FIRE DIE")
    4. Interactive Main Menu (PLAY, SETTINGS, CREDITS)
]]

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local SoundService = game:GetService("SoundService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui") :: PlayerGui

local MenuTheme = require(script.Parent:WaitForChild("MenuTheme"))
local EmberParticles = require(script.Parent:WaitForChild("EmberParticles"))
local CampfireEmblem = require(script.Parent:WaitForChild("CampfireEmblem"))

-- Initialize game audio routing to MasterSoundGroup
MenuTheme.InitAudioRouting()

--------------------------------------------------------------------------------
-- STATE VARIABLES
--------------------------------------------------------------------------------
local isBusy = false
local hasIntroCompleted = false
local reducedMotionEnabled = false
local currentMasterVolume = MenuTheme.GetMasterVolume()

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

    -- Fallback safety for humanoid movement
    local character = player.Character
    if character then
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        if humanoid then
            humanoid.WalkSpeed = enabled and 16 or 0
            humanoid.JumpPower = enabled and 50 or 0
        end
    end
end

-- Lock camera and controls during menu sequence
if camera then
    camera.CameraType = Enum.CameraType.Scriptable
end
setCharacterControlsEnabled(false)

-- Ensure character spawning during menu remains controlled
player.CharacterAdded:Connect(function(newCharacter)
    if not hasIntroCompleted then
        task.wait(0.1)
        setCharacterControlsEnabled(false)
        if camera then
            camera.CameraType = Enum.CameraType.Scriptable
        end
    else
        -- If player has already clicked play, camera attaches normally
        local humanoid = newCharacter:WaitForChild("Humanoid", 3)
        if humanoid and camera then
            camera.CameraSubject = humanoid
            camera.CameraType = Enum.CameraType.Custom
        end
    end
end)

--------------------------------------------------------------------------------
-- ROOT SCREEN GUI CREATION
--------------------------------------------------------------------------------
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "DontLetTheFireDie_MenuGui"
screenGui.ResetOnSpawn = false -- Intro never restarts unexpectedly on respawn
screenGui.IgnoreGuiInset = true -- True fullscreen aesthetic
screenGui.DisplayOrder = 100
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = playerGui

--------------------------------------------------------------------------------
-- BACKDROP & ATMOSPHERE LAYER
--------------------------------------------------------------------------------
local backgroundContainer = Instance.new("Frame")
backgroundContainer.Name = "BackgroundContainer"
backgroundContainer.Size = UDim2.fromScale(1, 1)
backgroundContainer.Position = UDim2.fromScale(0, 0)
backgroundContainer.BackgroundColor3 = MenuTheme.Colors.Background
backgroundContainer.BorderSizePixel = 0
backgroundContainer.ZIndex = 1
backgroundContainer.Parent = screenGui

-- Radial firelight warmth in the dark backdrop
local fireGlowGradientFrame = Instance.new("Frame")
fireGlowGradientFrame.Name = "FireGlowBackdrop"
fireGlowGradientFrame.Size = UDim2.fromScale(1, 1)
fireGlowGradientFrame.Position = UDim2.fromScale(0, 0)
fireGlowGradientFrame.BackgroundColor3 = MenuTheme.Colors.FireCrimson
fireGlowGradientFrame.BackgroundTransparency = 0.92
fireGlowGradientFrame.BorderSizePixel = 0
fireGlowGradientFrame.ZIndex = 2

local backdropGradient = Instance.new("UIGradient")
backdropGradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, MenuTheme.Colors.FireHot),
    ColorSequenceKeypoint.new(0.6, MenuTheme.Colors.FireCrimson),
    ColorSequenceKeypoint.new(1, MenuTheme.Colors.BackgroundDeep),
})
backdropGradient.Transparency = NumberSequence.new({
    NumberSequenceKeypoint.new(0, 0.85),
    NumberSequenceKeypoint.new(0.7, 0.96),
    NumberSequenceKeypoint.new(1, 1),
})
backdropGradient.Rotation = 90
backdropGradient.Parent = fireGlowGradientFrame
fireGlowGradientFrame.Parent = backgroundContainer

-- Floating embers particle container
local emberSystem = EmberParticles.new(backgroundContainer)

--------------------------------------------------------------------------------
-- MAIN INTERACTIVE MENU LAYOUT
--------------------------------------------------------------------------------
local mainContent = Instance.new("Frame")
mainContent.Name = "MainContent"
mainContent.Size = UDim2.new(1, 0, 1, 0)
mainContent.Position = UDim2.fromScale(0.5, 0.5)
mainContent.AnchorPoint = Vector2.new(0.5, 0.5)
mainContent.BackgroundTransparency = 1
mainContent.ZIndex = 5
mainContent.Parent = screenGui

-- Safe-area padding constraint for clean mobile notch & desktop presentation
local contentPadding = Instance.new("UIPadding")
contentPadding.PaddingTop = UDim.new(0.06, 0)
contentPadding.PaddingBottom = UDim.new(0.06, 0)
contentPadding.PaddingLeft = UDim.new(0.05, 0)
contentPadding.PaddingRight = UDim.new(0.05, 0)
contentPadding.Parent = mainContent

-- Centered CanvasGroup for Title & Logo (Smooth unified alpha fade)
local brandingContainer = Instance.new("CanvasGroup")
brandingContainer.Name = "BrandingContainer"
brandingContainer.Size = UDim2.new(0.9, 0, 0.44, 0)
brandingContainer.Position = UDim2.fromScale(0.5, 0.48) -- Initial centered position for reveal
brandingContainer.AnchorPoint = Vector2.new(0.5, 0.5)
brandingContainer.BackgroundTransparency = 1
brandingContainer.GroupTransparency = 1 -- Hidden initially until Phase 3
brandingContainer.ZIndex = 6
brandingContainer.Parent = mainContent

local brandingLayout = Instance.new("UIListLayout")
brandingLayout.FillDirection = Enum.FillDirection.Vertical
brandingLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
brandingLayout.VerticalAlignment = Enum.VerticalAlignment.Center
brandingLayout.Padding = UDim.new(0, 10)
brandingLayout.Parent = brandingContainer

-- Instantiate Campfire Emblem
local emblem = CampfireEmblem.new(UDim2.fromOffset(130, 130))
emblem.Root.Parent = brandingContainer

-- Title: DON'T LET THE FIRE DIE
local titleLabel = Instance.new("TextLabel")
titleLabel.Name = "GameTitle"
titleLabel.Size = UDim2.new(1, 0, 0, 48)
titleLabel.BackgroundTransparency = 1
titleLabel.Font = MenuTheme.Fonts.Title
titleLabel.Text = "DON'T LET THE FIRE DIE"
titleLabel.TextColor3 = MenuTheme.Colors.TextPrimary
titleLabel.TextSize = 34
titleLabel.TextStrokeColor3 = Color3.fromRGB(15, 8, 5)
titleLabel.TextStrokeTransparency = 0.35
titleLabel.ZIndex = 7
titleLabel.Parent = brandingContainer

-- Responsive Title Size Constraint
local titleSizeConstraint = Instance.new("UITextSizeConstraint")
titleSizeConstraint.MaxTextSize = 38
titleSizeConstraint.MinTextSize = 20
titleSizeConstraint.Parent = titleLabel

-- Subtitle Tagline
local subtitleLabel = Instance.new("TextLabel")
subtitleLabel.Name = "GameSubtitle"
subtitleLabel.Size = UDim2.new(1, 0, 0, 20)
subtitleLabel.BackgroundTransparency = 1
subtitleLabel.Font = MenuTheme.Fonts.Sub
subtitleLabel.Text = "S U R V I V A L   H O R R O R"
subtitleLabel.TextColor3 = MenuTheme.Colors.FireHot
subtitleLabel.TextSize = 13
subtitleLabel.ZIndex = 7
subtitleLabel.Parent = brandingContainer

-- Menu Buttons Group
local buttonsContainer = Instance.new("Frame")
buttonsContainer.Name = "ButtonsContainer"
buttonsContainer.Size = UDim2.new(0, 260, 0, 210)
buttonsContainer.Position = UDim2.fromScale(0.5, 0.78)
buttonsContainer.AnchorPoint = Vector2.new(0.5, 0.5)
buttonsContainer.BackgroundTransparency = 1
buttonsContainer.Visible = false
buttonsContainer.ZIndex = 8
buttonsContainer.Parent = mainContent

local buttonsLayout = Instance.new("UIListLayout")
buttonsLayout.FillDirection = Enum.FillDirection.Vertical
buttonsLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
buttonsLayout.VerticalAlignment = Enum.VerticalAlignment.Center
buttonsLayout.Padding = UDim.new(0, 14)
buttonsLayout.Parent = buttonsContainer

-- Footer Watermark Label
local footerLabel = Instance.new("TextLabel")
footerLabel.Name = "FooterInfo"
footerLabel.Size = UDim2.new(1, 0, 0, 20)
footerLabel.Position = UDim2.fromScale(0.5, 0.98)
footerLabel.AnchorPoint = Vector2.new(0.5, 1)
footerLabel.BackgroundTransparency = 1
footerLabel.Font = MenuTheme.Fonts.Body
footerLabel.Text = "v0.1.0-alpha • Fluenosity Studio"
footerLabel.TextColor3 = MenuTheme.Colors.TextSubdued
footerLabel.TextSize = 11
footerLabel.TextTransparency = 1
footerLabel.ZIndex = 6
footerLabel.Parent = mainContent

--------------------------------------------------------------------------------
-- REUSABLE BUTTON CONSTRUCTOR
--------------------------------------------------------------------------------
local function createMenuButton(text: string, isPrimary: boolean): (TextButton, UIStroke)
    local button = Instance.new("TextButton")
    button.Name = "Btn_" .. text
    button.Size = UDim2.new(1, 0, 0, 48)
    button.BackgroundColor3 = isPrimary and Color3.fromRGB(30, 24, 23) or MenuTheme.Colors.ButtonNormal
    button.AutoButtonColor = false
    button.Font = MenuTheme.Fonts.Button
    button.Text = text
    button.TextColor3 = MenuTheme.Colors.TextPrimary
    button.TextSize = 15
    button.BorderSizePixel = 0
    button.ZIndex = 9

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = button

    local stroke = Instance.new("UIStroke")
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    stroke.Color = isPrimary and Color3.fromRGB(160, 65, 20) or MenuTheme.Colors.ButtonBorderNormal
    stroke.Thickness = 1.2
    stroke.Transparency = 0.2
    stroke.Parent = button

    -- Interactive Hover / Focus Animations
    button.MouseEnter:Connect(function()
        if isBusy then return end
        TweenService:Create(button, MenuTheme.Tweens.Fast, {
            BackgroundColor3 = MenuTheme.Colors.ButtonHover,
        }):Play()
        TweenService:Create(stroke, MenuTheme.Tweens.Fast, {
            Color = MenuTheme.Colors.ButtonBorderHover,
            Thickness = 1.8,
            Transparency = 0,
        }):Play()
        TweenService:Create(button, MenuTheme.Tweens.Fast, {
            TextColor3 = MenuTheme.Colors.FireHot,
        }):Play()
    end)

    button.MouseLeave:Connect(function()
        TweenService:Create(button, MenuTheme.Tweens.Fast, {
            BackgroundColor3 = isPrimary and Color3.fromRGB(30, 24, 23) or MenuTheme.Colors.ButtonNormal,
        }):Play()
        TweenService:Create(stroke, MenuTheme.Tweens.Fast, {
            Color = isPrimary and Color3.fromRGB(160, 65, 20) or MenuTheme.Colors.ButtonBorderNormal,
            Thickness = 1.2,
            Transparency = 0.2,
        }):Play()
        TweenService:Create(button, MenuTheme.Tweens.Fast, {
            TextColor3 = MenuTheme.Colors.TextPrimary,
        }):Play()
    end)

    button.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            TweenService:Create(button, MenuTheme.Tweens.Instant, {
                BackgroundColor3 = MenuTheme.Colors.ButtonPressed,
            }):Play()
        end
    end)

    button.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            TweenService:Create(button, MenuTheme.Tweens.Fast, {
                BackgroundColor3 = MenuTheme.Colors.ButtonHover,
            }):Play()
        end
    end)

    return button, stroke
end

local btnPlay, _ = createMenuButton("PLAY", true)
btnPlay.Parent = buttonsContainer

local btnSettings, _ = createMenuButton("SETTINGS", false)
btnSettings.Parent = buttonsContainer

local btnCredits, _ = createMenuButton("CREDITS", false)
btnCredits.Parent = buttonsContainer

--------------------------------------------------------------------------------
-- MODAL CONTAINER & OVERLAYS (SETTINGS & CREDITS)
--------------------------------------------------------------------------------
local modalBackdrop = Instance.new("TextButton")
modalBackdrop.Name = "ModalBackdrop"
modalBackdrop.Size = UDim2.fromScale(1, 1)
modalBackdrop.Position = UDim2.fromScale(0, 0)
modalBackdrop.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
modalBackdrop.BackgroundTransparency = 1
modalBackdrop.AutoButtonColor = false
modalBackdrop.Text = ""
modalBackdrop.Visible = false
modalBackdrop.ZIndex = 20
modalBackdrop.Parent = screenGui

local function createModalFrame(name: string, size: UDim2): Frame
    local frame = Instance.new("Frame")
    frame.Name = name
    frame.Size = size
    frame.Position = UDim2.fromScale(0.5, 0.5)
    frame.AnchorPoint = Vector2.new(0.5, 0.5)
    frame.BackgroundColor3 = MenuTheme.Colors.CardBackground
    frame.BorderSizePixel = 0
    frame.Visible = false
    frame.ZIndex = 22
    frame.Parent = modalBackdrop

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 12)
    corner.Parent = frame

    local stroke = Instance.new("UIStroke")
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    stroke.Color = MenuTheme.Colors.CardBorder
    stroke.Thickness = 1.4
    stroke.Parent = frame

    local padding = Instance.new("UIPadding")
    padding.PaddingTop = UDim.new(0, 24)
    padding.PaddingBottom = UDim.new(0, 24)
    padding.PaddingLeft = UDim.new(0, 26)
    padding.PaddingRight = UDim.new(0, 26)
    padding.Parent = frame

    return frame
end

--------------------------------------------------------------------------------
-- 1. SETTINGS PANEL
--------------------------------------------------------------------------------
local settingsFrame = createModalFrame("SettingsModal", UDim2.new(0, 390, 0, 360))

local settingsLayout = Instance.new("UIListLayout")
settingsLayout.FillDirection = Enum.FillDirection.Vertical
settingsLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
settingsLayout.Padding = UDim.new(0, 16)
settingsLayout.Parent = settingsFrame

local settingsTitle = Instance.new("TextLabel")
settingsTitle.Name = "Title"
settingsTitle.Size = UDim2.new(1, 0, 0, 32)
settingsTitle.BackgroundTransparency = 1
settingsTitle.Font = MenuTheme.Fonts.Heading
settingsTitle.Text = "SETTINGS"
settingsTitle.TextColor3 = MenuTheme.Colors.TextPrimary
settingsTitle.TextSize = 22
settingsTitle.ZIndex = 23
settingsTitle.Parent = settingsFrame

-- Divider accent line
local settingsDivider = Instance.new("Frame")
settingsDivider.Name = "Divider"
settingsDivider.Size = UDim2.new(1, 0, 0, 1)
settingsDivider.BackgroundColor3 = MenuTheme.Colors.CardBorder
settingsDivider.BorderSizePixel = 0
settingsDivider.ZIndex = 23
settingsDivider.Parent = settingsFrame

-- Volume Section Container
local volumeSection = Instance.new("Frame")
volumeSection.Name = "VolumeSection"
volumeSection.Size = UDim2.new(1, 0, 0, 72)
volumeSection.BackgroundTransparency = 1
volumeSection.ZIndex = 23
volumeSection.Parent = settingsFrame

local volumeHeader = Instance.new("Frame")
volumeHeader.Name = "Header"
volumeHeader.Size = UDim2.new(1, 0, 0, 22)
volumeHeader.BackgroundTransparency = 1
volumeHeader.Parent = volumeSection

local volumeTitle = Instance.new("TextLabel")
volumeTitle.Name = "Label"
volumeTitle.Size = UDim2.new(0.7, 0, 1, 0)
volumeTitle.BackgroundTransparency = 1
volumeTitle.Font = MenuTheme.Fonts.Button
volumeTitle.Text = "MASTER VOLUME"
volumeTitle.TextColor3 = MenuTheme.Colors.TextMuted
volumeTitle.TextSize = 14
volumeTitle.TextXAlignment = Enum.TextXAlignment.Left
volumeTitle.ZIndex = 23
volumeTitle.Parent = volumeHeader

local volumeValueLabel = Instance.new("TextLabel")
volumeValueLabel.Name = "Value"
volumeValueLabel.Size = UDim2.new(0.3, 0, 1, 0)
volumeValueLabel.Position = UDim2.fromScale(1, 0)
volumeValueLabel.AnchorPoint = Vector2.new(1, 0)
volumeValueLabel.BackgroundTransparency = 1
volumeValueLabel.Font = MenuTheme.Fonts.Button
volumeValueLabel.Text = string.format("%d%%", math.round(currentMasterVolume * 100))
volumeValueLabel.TextColor3 = MenuTheme.Colors.FireHot
volumeValueLabel.TextSize = 14
volumeValueLabel.TextXAlignment = Enum.TextXAlignment.Right
volumeValueLabel.ZIndex = 23
volumeValueLabel.Parent = volumeHeader

-- Slider Controls Row
local volumeControlRow = Instance.new("Frame")
volumeControlRow.Name = "ControlRow"
volumeControlRow.Size = UDim2.new(1, 0, 0, 36)
volumeControlRow.Position = UDim2.fromScale(0, 0.45)
volumeControlRow.BackgroundTransparency = 1
volumeControlRow.ZIndex = 23
volumeControlRow.Parent = volumeSection

local btnVolMinus = Instance.new("TextButton")
btnVolMinus.Name = "BtnMinus"
btnVolMinus.Size = UDim2.fromOffset(36, 32)
btnVolMinus.Position = UDim2.fromScale(0, 0.5)
btnVolMinus.AnchorPoint = Vector2.new(0, 0.5)
btnVolMinus.BackgroundColor3 = MenuTheme.Colors.ButtonNormal
btnVolMinus.Font = MenuTheme.Fonts.Button
btnVolMinus.Text = "-"
btnVolMinus.TextColor3 = MenuTheme.Colors.TextPrimary
btnVolMinus.TextSize = 18
btnVolMinus.ZIndex = 24
btnVolMinus.Parent = volumeControlRow

local btnVolMinusCorner = Instance.new("UICorner")
btnVolMinusCorner.CornerRadius = UDim.new(0, 6)
btnVolMinusCorner.Parent = btnVolMinus

local btnVolPlus = Instance.new("TextButton")
btnVolPlus.Name = "BtnPlus"
btnVolPlus.Size = UDim2.fromOffset(36, 32)
btnVolPlus.Position = UDim2.fromScale(1, 0.5)
btnVolPlus.AnchorPoint = Vector2.new(1, 0.5)
btnVolPlus.BackgroundColor3 = MenuTheme.Colors.ButtonNormal
btnVolPlus.Font = MenuTheme.Fonts.Button
btnVolPlus.Text = "+"
btnVolPlus.TextColor3 = MenuTheme.Colors.TextPrimary
btnVolPlus.TextSize = 18
btnVolPlus.ZIndex = 24
btnVolPlus.Parent = volumeControlRow

local btnVolPlusCorner = Instance.new("UICorner")
btnVolPlusCorner.CornerRadius = UDim.new(0, 6)
btnVolPlusCorner.Parent = btnVolPlus

-- Draggable Slider Bar Track
local sliderTrack = Instance.new("Frame")
sliderTrack.Name = "Track"
sliderTrack.Size = UDim2.new(1, -92, 0, 12)
sliderTrack.Position = UDim2.fromScale(0.5, 0.5)
sliderTrack.AnchorPoint = Vector2.new(0.5, 0.5)
sliderTrack.BackgroundColor3 = Color3.fromRGB(30, 26, 28)
sliderTrack.BorderSizePixel = 0
sliderTrack.ZIndex = 24
sliderTrack.Parent = volumeControlRow

local sliderTrackCorner = Instance.new("UICorner")
sliderTrackCorner.CornerRadius = UDim.new(1, 0)
sliderTrackCorner.Parent = sliderTrack

local sliderFill = Instance.new("Frame")
sliderFill.Name = "Fill"
sliderFill.Size = UDim2.fromScale(currentMasterVolume, 1)
sliderFill.BackgroundColor3 = MenuTheme.Colors.FireEmber
sliderFill.BorderSizePixel = 0
sliderFill.ZIndex = 25
sliderFill.Parent = sliderTrack

local sliderFillCorner = Instance.new("UICorner")
sliderFillCorner.CornerRadius = UDim.new(1, 0)
sliderFillCorner.Parent = sliderFill

local function updateVolume(newVol: number)
    currentMasterVolume = math.clamp(newVol, 0, 1)
    MenuTheme.SetMasterVolume(currentMasterVolume)
    sliderFill.Size = UDim2.fromScale(currentMasterVolume, 1)
    volumeValueLabel.Text = string.format("%d%%", math.round(currentMasterVolume * 100))
end

btnVolMinus.Activated:Connect(function()
    updateVolume(currentMasterVolume - 0.1)
end)

btnVolPlus.Activated:Connect(function()
    updateVolume(currentMasterVolume + 0.1)
end)

-- Track Click/Drag Interaction
local isDraggingSlider = false

sliderTrack.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        isDraggingSlider = true
        if sliderTrack.AbsoluteSize.X > 0 then
            local relativeX = math.clamp((input.Position.X - sliderTrack.AbsolutePosition.X) / sliderTrack.AbsoluteSize.X, 0, 1)
            updateVolume(relativeX)
        end
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if isDraggingSlider and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        if sliderTrack.AbsoluteSize.X > 0 then
            local relativeX = math.clamp((input.Position.X - sliderTrack.AbsolutePosition.X) / sliderTrack.AbsoluteSize.X, 0, 1)
            updateVolume(relativeX)
        end
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        isDraggingSlider = false
    end
end)

-- Reduced Motion Section
local motionSection = Instance.new("Frame")
motionSection.Name = "MotionSection"
motionSection.Size = UDim2.new(1, 0, 0, 60)
motionSection.BackgroundTransparency = 1
motionSection.ZIndex = 23
motionSection.Parent = settingsFrame

local motionTitle = Instance.new("TextLabel")
motionTitle.Name = "Label"
motionTitle.Size = UDim2.new(0.65, 0, 0, 20)
motionTitle.BackgroundTransparency = 1
motionTitle.Font = MenuTheme.Fonts.Button
motionTitle.Text = "REDUCED MOTION"
motionTitle.TextColor3 = MenuTheme.Colors.TextMuted
motionTitle.TextSize = 14
motionTitle.TextXAlignment = Enum.TextXAlignment.Left
motionTitle.ZIndex = 23
motionTitle.Parent = motionSection

local motionDesc = Instance.new("TextLabel")
motionDesc.Name = "Desc"
motionDesc.Size = UDim2.new(0.65, 0, 0, 18)
motionDesc.Position = UDim2.fromOffset(0, 22)
motionDesc.BackgroundTransparency = 1
motionDesc.Font = MenuTheme.Fonts.Body
motionDesc.Text = "Disables embers & pulse animations"
motionDesc.TextColor3 = MenuTheme.Colors.TextSubdued
motionDesc.TextSize = 11
motionDesc.TextXAlignment = Enum.TextXAlignment.Left
motionDesc.ZIndex = 23
motionDesc.Parent = motionSection

local btnMotionToggle = Instance.new("TextButton")
btnMotionToggle.Name = "BtnToggle"
btnMotionToggle.Size = UDim2.new(0.3, 0, 0, 34)
btnMotionToggle.Position = UDim2.fromScale(1, 0.5)
btnMotionToggle.AnchorPoint = Vector2.new(1, 0.5)
btnMotionToggle.BackgroundColor3 = MenuTheme.Colors.ButtonNormal
btnMotionToggle.Font = MenuTheme.Fonts.Button
btnMotionToggle.Text = "OFF"
btnMotionToggle.TextColor3 = MenuTheme.Colors.TextMuted
btnMotionToggle.TextSize = 13
btnMotionToggle.ZIndex = 24
btnMotionToggle.Parent = motionSection

local btnMotionCorner = Instance.new("UICorner")
btnMotionCorner.CornerRadius = UDim.new(0, 6)
btnMotionCorner.Parent = btnMotionToggle

local btnMotionStroke = Instance.new("UIStroke")
btnMotionStroke.Color = MenuTheme.Colors.ButtonBorderNormal
btnMotionStroke.Thickness = 1
btnMotionStroke.Parent = btnMotionToggle

local function setReducedMotion(enabled: boolean)
    reducedMotionEnabled = enabled
    btnMotionToggle.Text = enabled and "ON" or "OFF"
    btnMotionToggle.TextColor3 = enabled and Color3.fromRGB(15, 12, 10) or MenuTheme.Colors.TextMuted
    btnMotionToggle.BackgroundColor3 = enabled and MenuTheme.Colors.FireHot or MenuTheme.Colors.ButtonNormal
    btnMotionStroke.Color = enabled and MenuTheme.Colors.FireEmber or MenuTheme.Colors.ButtonBorderNormal
    
    emberSystem:SetReducedMotion(enabled)
    emblem:SetReducedMotion(enabled)
end

btnMotionToggle.Activated:Connect(function()
    setReducedMotion(not reducedMotionEnabled)
end)

-- Settings Back Button
local btnSettingsBack, _ = createMenuButton("BACK", false)
btnSettingsBack.Size = UDim2.new(1, 0, 0, 42)
btnSettingsBack.ZIndex = 24
btnSettingsBack.Parent = settingsFrame

--------------------------------------------------------------------------------
-- 2. CREDITS PANEL
--------------------------------------------------------------------------------
local creditsFrame = createModalFrame("CreditsModal", UDim2.new(0, 420, 0, 390))

local creditsLayout = Instance.new("UIListLayout")
creditsLayout.FillDirection = Enum.FillDirection.Vertical
creditsLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
creditsLayout.Padding = UDim.new(0, 14)
creditsLayout.Parent = creditsFrame

local creditsTitle = Instance.new("TextLabel")
creditsTitle.Name = "Title"
creditsTitle.Size = UDim2.new(1, 0, 0, 32)
creditsTitle.BackgroundTransparency = 1
creditsTitle.Font = MenuTheme.Fonts.Heading
creditsTitle.Text = "CREDITS"
creditsTitle.TextColor3 = MenuTheme.Colors.TextPrimary
creditsTitle.TextSize = 22
creditsTitle.ZIndex = 23
creditsTitle.Parent = creditsFrame

local creditsDivider = Instance.new("Frame")
creditsDivider.Name = "Divider"
creditsDivider.Size = UDim2.new(1, 0, 0, 1)
creditsDivider.BackgroundColor3 = MenuTheme.Colors.CardBorder
creditsDivider.BorderSizePixel = 0
creditsDivider.ZIndex = 23
creditsDivider.Parent = creditsFrame

local creditsBody = Instance.new("Frame")
creditsBody.Name = "Body"
creditsBody.Size = UDim2.new(1, 0, 0, 200)
creditsBody.BackgroundTransparency = 1
creditsBody.ZIndex = 23
creditsBody.Parent = creditsFrame

local creditsBodyLayout = Instance.new("UIListLayout")
creditsBodyLayout.FillDirection = Enum.FillDirection.Vertical
creditsBodyLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
creditsBodyLayout.Padding = UDim.new(0, 10)
creditsBodyLayout.Parent = creditsBody

local function addCreditLine(role: string, name: string, isHighlight: boolean)
    local line = Instance.new("Frame")
    line.Size = UDim2.new(1, 0, 0, 34)
    line.BackgroundTransparency = 1
    line.ZIndex = 23
    line.Parent = creditsBody

    local roleLbl = Instance.new("TextLabel")
    roleLbl.Size = UDim2.new(1, 0, 0, 14)
    roleLbl.BackgroundTransparency = 1
    roleLbl.Font = MenuTheme.Fonts.Body
    roleLbl.Text = role
    roleLbl.TextColor3 = MenuTheme.Colors.TextSubdued
    roleLbl.TextSize = 11
    roleLbl.ZIndex = 23
    roleLbl.Parent = line

    local nameLbl = Instance.new("TextLabel")
    nameLbl.Size = UDim2.new(1, 0, 0, 18)
    nameLbl.Position = UDim2.fromOffset(0, 15)
    nameLbl.BackgroundTransparency = 1
    nameLbl.Font = isHighlight and MenuTheme.Fonts.Heading or MenuTheme.Fonts.Button
    nameLbl.Text = name
    nameLbl.TextColor3 = isHighlight and MenuTheme.Colors.FireHot or MenuTheme.Colors.TextPrimary
    nameLbl.TextSize = isHighlight and 15 or 13
    nameLbl.ZIndex = 23
    nameLbl.Parent = line
end

addCreditLine("PRODUCED BY", "FLUENOSITY STUDIO", true)
addCreditLine("SURVIVAL HORROR EXPERIENCE", "Don't Let the Fire Die", false)
addCreditLine("SYSTEMS & ATMOSPHERIC ART", "Fluenosity Studio Engineering", false)

local studioQuote = Instance.new("TextLabel")
studioQuote.Name = "Quote"
studioQuote.Size = UDim2.new(1, 0, 0, 28)
studioQuote.BackgroundTransparency = 1
studioQuote.Font = MenuTheme.Fonts.Body
studioQuote.Text = '"The cold will whisper. Never turn your back on the fire."'
studioQuote.TextColor3 = MenuTheme.Colors.TextMuted
studioQuote.TextSize = 11
studioQuote.ZIndex = 23
studioQuote.Parent = creditsBody

-- Credits Back Button
local btnCreditsBack, _ = createMenuButton("BACK", false)
btnCreditsBack.Size = UDim2.new(1, 0, 0, 42)
btnCreditsBack.ZIndex = 24
btnCreditsBack.Parent = creditsFrame

--------------------------------------------------------------------------------
-- MODAL NAVIGATION HANDLERS
--------------------------------------------------------------------------------
local activeModal: Frame? = nil

local function openModal(modal: Frame)
    if isBusy or activeModal then return end
    isBusy = true
    activeModal = modal

    modalBackdrop.Visible = true
    modal.Visible = true
    modal.Position = UDim2.fromScale(0.5, 0.53)

    TweenService:Create(modalBackdrop, MenuTheme.Tweens.Fast, {
        BackgroundTransparency = 0.55,
    }):Play()

    local tween = TweenService:Create(modal, MenuTheme.Tweens.Normal, {
        Position = UDim2.fromScale(0.5, 0.5),
    })
    tween.Completed:Connect(function()
        isBusy = false
    end)
    tween:Play()
end

local function closeModal()
    if isBusy or not activeModal then return end
    isBusy = true
    local modal = activeModal
    activeModal = nil

    local tween = TweenService:Create(modal, MenuTheme.Tweens.Fast, {
        Position = UDim2.fromScale(0.5, 0.53),
    })
    TweenService:Create(modalBackdrop, MenuTheme.Tweens.Fast, {
        BackgroundTransparency = 1,
    }):Play()

    tween.Completed:Connect(function()
        modal.Visible = false
        modalBackdrop.Visible = false
        isBusy = false
    end)
    tween:Play()
end

btnSettings.Activated:Connect(function()
    openModal(settingsFrame)
end)

btnCredits.Activated:Connect(function()
    openModal(creditsFrame)
end)

btnSettingsBack.Activated:Connect(function()
    closeModal()
end)

btnCreditsBack.Activated:Connect(function()
    closeModal()
end)

modalBackdrop.Activated:Connect(function()
    closeModal()
end)

--------------------------------------------------------------------------------
-- PLAY BUTTON HANDLER (MENU TO GAMEPLAY TRANSITION)
--------------------------------------------------------------------------------
btnPlay.Activated:Connect(function()
    if isBusy then return end
    isBusy = true

    local fadeInfo = reducedMotionEnabled and MenuTheme.Tweens.Fast or MenuTheme.Tweens.Smooth
    
    local fadeTween = TweenService:Create(mainContent, fadeInfo, {
        Position = UDim2.fromScale(0.5, 0.47),
    })
    fadeTween:Play()

    -- Fade canvas groups, text, frames, and strokes
    TweenService:Create(brandingContainer, fadeInfo, {
        GroupTransparency = 1,
    }):Play()

    for _, obj in ipairs(mainContent:GetDescendants()) do
        if obj:IsA("TextLabel") or obj:IsA("TextButton") then
            TweenService:Create(obj, fadeInfo, { TextTransparency = 1 }):Play()
        end
        if obj:IsA("Frame") or obj:IsA("TextButton") then
            TweenService:Create(obj, fadeInfo, { BackgroundTransparency = 1 }):Play()
        end
        if obj:IsA("UIStroke") then
            TweenService:Create(obj, fadeInfo, { Transparency = 1 }):Play()
        end
    end

    -- Fade out background and stop ember particles
    TweenService:Create(backgroundContainer, fadeInfo, {
        BackgroundTransparency = 1,
    }):Play()
    TweenService:Create(fireGlowGradientFrame, fadeInfo, {
        BackgroundTransparency = 1,
    }):Play()

    emberSystem:Stop()

    fadeTween.Completed:Connect(function()
        -- Restore Player Character Controls & Camera
        if camera then
            camera.CameraType = Enum.CameraType.Custom
            local character = player.Character
            if character then
                local humanoid = character:FindFirstChildOfClass("Humanoid")
                if humanoid then
                    camera.CameraSubject = humanoid
                end
            end
        end

        setCharacterControlsEnabled(true)

        -- Clean up menu GUI and particles
        emberSystem:Destroy()
        emblem:Destroy()
        screenGui:Destroy()
    end)
end)

--------------------------------------------------------------------------------
-- CINEMATIC INTRO SEQUENCE (PHASE 1, PHASE 2, PHASE 3, PHASE 4)
--------------------------------------------------------------------------------
local function runCinematicIntro()
    isBusy = true

    ----------------------------------------------------------------------------
    -- PHASE 1: Pure White Studio Splash Screen
    ----------------------------------------------------------------------------
    local studioSplashFrame = Instance.new("Frame")
    studioSplashFrame.Name = "StudioSplashFrame"
    studioSplashFrame.Size = UDim2.fromScale(1, 1)
    studioSplashFrame.Position = UDim2.fromScale(0, 0)
    studioSplashFrame.BackgroundColor3 = MenuTheme.Colors.PureWhite
    studioSplashFrame.BackgroundTransparency = 0
    studioSplashFrame.BorderSizePixel = 0
    studioSplashFrame.ZIndex = 50
    studioSplashFrame.Parent = screenGui

    local studioText = Instance.new("TextLabel")
    studioText.Name = "StudioText"
    studioText.Size = UDim2.new(0.9, 0, 0, 40)
    studioText.Position = UDim2.fromScale(0.5, 0.5)
    studioText.AnchorPoint = Vector2.new(0.5, 0.5)
    studioText.BackgroundTransparency = 1
    studioText.Font = MenuTheme.Fonts.Studio
    studioText.Text = "A FLUENOSITY STUDIO PRODUCTION"
    studioText.TextColor3 = MenuTheme.Colors.StudioSplashText
    studioText.TextSize = 18
    studioText.TextTransparency = 1
    studioText.ZIndex = 51
    studioText.Parent = studioSplashFrame

    -- Text Size constraint for phone screens
    local studioTextConstraint = Instance.new("UITextSizeConstraint")
    studioTextConstraint.MaxTextSize = 20
    studioTextConstraint.MinTextSize = 12
    studioTextConstraint.Parent = studioText

    -- Timing: Fade in (0.5s), hold (~1.0s), fade out (0.5s) -> ~2.0s total target
    local fadeInText = TweenService:Create(studioText, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        TextTransparency = 0,
    })
    fadeInText:Play()
    fadeInText.Completed:Wait()

    task.wait(1.0)

    local fadeOutText = TweenService:Create(studioText, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
        TextTransparency = 1,
    })
    fadeOutText:Play()
    fadeOutText.Completed:Wait()

    ----------------------------------------------------------------------------
    -- PHASE 2: Transition into Darkness
    ----------------------------------------------------------------------------
    local darkTransitionTween = TweenService:Create(studioSplashFrame, TweenInfo.new(0.7, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut), {
        BackgroundTransparency = 1,
    })
    darkTransitionTween:Play()
    darkTransitionTween.Completed:Wait()
    studioSplashFrame:Destroy()

    -- Spark ignition: A small warm ember point in the center
    local emberIgnition = Instance.new("Frame")
    emberIgnition.Name = "EmberIgnition"
    emberIgnition.Size = UDim2.fromOffset(4, 4)
    emberIgnition.Position = UDim2.fromScale(0.5, 0.5)
    emberIgnition.AnchorPoint = Vector2.new(0.5, 0.5)
    emberIgnition.BackgroundColor3 = MenuTheme.Colors.FireHot
    emberIgnition.BackgroundTransparency = 0
    emberIgnition.BorderSizePixel = 0
    emberIgnition.ZIndex = 30
    emberIgnition.Parent = backgroundContainer

    local ignitionCorner = Instance.new("UICorner")
    ignitionCorner.CornerRadius = UDim.new(1, 0)
    ignitionCorner.Parent = emberIgnition

    local igniteGlow = TweenService:Create(emberIgnition, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        Size = UDim2.fromOffset(14, 14),
        BackgroundTransparency = 0.4,
    })
    igniteGlow:Play()
    igniteGlow.Completed:Wait()

    -- Start background floating embers
    emberSystem:Start()

    local fadeIgnition = TweenService:Create(emberIgnition, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        Size = UDim2.fromOffset(2, 2),
        BackgroundTransparency = 1,
    })
    fadeIgnition:Play()
    fadeIgnition.Completed:Wait()
    emberIgnition:Destroy()

    ----------------------------------------------------------------------------
    -- PHASE 3: Game Logo & Title Reveal
    ----------------------------------------------------------------------------
    -- Smoothly reveal the branding container (emblem, title, subtitle)
    emblem.Root.Size = UDim2.fromOffset(100, 100)
    TweenService:Create(emblem.Root, MenuTheme.Tweens.Smooth, {
        Size = UDim2.fromOffset(130, 130),
    }):Play()

    local brandingReveal = TweenService:Create(brandingContainer, MenuTheme.Tweens.Smooth, {
        GroupTransparency = 0,
    })
    brandingReveal:Play()
    brandingReveal.Completed:Wait()

    task.wait(1.0)

    ----------------------------------------------------------------------------
    -- PHASE 4: Transition into Main Menu
    ----------------------------------------------------------------------------
    -- Shift branding smoothly from center (0.48) to upper menu position (0.34)
    local brandingShift = TweenService:Create(brandingContainer, MenuTheme.Tweens.Smooth, {
        Position = UDim2.fromScale(0.5, 0.34),
    })
    brandingShift:Play()

    task.wait(0.2)

    -- Reveal Buttons Container with upward slide
    buttonsContainer.Visible = true
    buttonsContainer.Position = UDim2.fromScale(0.5, 0.78)

    local buttonsSlide = TweenService:Create(buttonsContainer, MenuTheme.Tweens.Normal, {
        Position = UDim2.fromScale(0.5, 0.72),
    })
    buttonsSlide:Play()

    -- Reveal Footer watermark
    TweenService:Create(footerLabel, MenuTheme.Tweens.Slow, {
        TextTransparency = 0,
    }):Play()

    brandingShift.Completed:Wait()

    hasIntroCompleted = true
    isBusy = false
end

-- Kick off the intro sequence
task.spawn(runCinematicIntro)
