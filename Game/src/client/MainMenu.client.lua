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
local ContextActionService = game:GetService("ContextActionService")
local GuiService = game:GetService("GuiService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local ProximityPromptService = game:GetService("ProximityPromptService")
local SoundService = game:GetService("SoundService")

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
local EnvironmentConfig = require(sharedFolder:WaitForChild("EnvironmentConfig"))
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
local skipMainMenu = GameConfig.ShouldSkipMainMenu()
local gameplayTransitionAuthorized = skipMainMenu
local MENU_MOVEMENT_LOCK = "DontLetTheFireDie_MenuMovementLock"
local hiddenMenuParts: { [BasePart]: number } = {}
local hideMenuCharacter: (Model?) -> () = function(_character: Model?) end

local camera = workspace.CurrentCamera
if not camera then
    camera = workspace:WaitForChild("Camera", 5) :: Camera
end

local function setMenuInputSink(_actionName: string, _inputState: Enum.UserInputState, _input: InputObject)
    return Enum.ContextActionResult.Sink
end

local function setMenuInputLocked(locked: boolean)
    if locked then
        ContextActionService:BindActionAtPriority(
            MENU_MOVEMENT_LOCK,
            setMenuInputSink,
            false,
            Enum.ContextActionPriority.High.Value + 100,
            Enum.KeyCode.W,
            Enum.KeyCode.A,
            Enum.KeyCode.S,
            Enum.KeyCode.D,
            Enum.KeyCode.Space,
            Enum.KeyCode.Thumbstick1
        )
    else
        ContextActionService:UnbindAction(MENU_MOVEMENT_LOCK)
    end
end

local function setCharacterControlsEnabled(enabled: boolean, targetCharacter: Model?)
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

    local character = targetCharacter or player.Character
    if character then
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        if humanoid then
            humanoid.WalkSpeed = enabled and 16 or 0
            humanoid.JumpPower = enabled and 38 or 0
        end
    end
end

local function holdMenuCharacter(character: Model?)
    if gameplayTransitionAuthorized or player:GetAttribute("IsInGameplay") == true then return end
    setMenuInputLocked(true)
    setCharacterControlsEnabled(false, character)
    if not character then return end

    task.defer(function()
        if gameplayTransitionAuthorized or player:GetAttribute("IsInGameplay") == true or not character.Parent then return end
        local humanoid = character:FindFirstChildOfClass("Humanoid") or character:WaitForChild("Humanoid", 5)
        if humanoid and humanoid:IsA("Humanoid") then
            humanoid.WalkSpeed = 0
            humanoid.UseJumpPower = true
            humanoid.JumpPower = 0
            humanoid.Jump = false
            humanoid:Move(Vector3.zero)
        end
    end)
end

local gameplayStateConnection = player:GetAttributeChangedSignal("IsInGameplay"):Connect(function()
    if gameplayTransitionAuthorized then return end
    if player:GetAttribute("IsInGameplay") == true then
        -- A stale gameplay state must never unlock movement behind either menu screen.
        player:SetAttribute("IsInGameplay", false)
        hideMenuCharacter(player.Character)
    end
    holdMenuCharacter(player.Character)
end)

-- =============================================================================
-- DEV CONFIG CHECK: SKIP MAIN MENU
-- =============================================================================
if skipMainMenu then
    if GameConfig.ShouldSkipLoadingScreen and GameConfig.ShouldSkipLoadingScreen() then
        gameplayTransitionAuthorized = true
        setMenuInputLocked(false)
        player:SetAttribute("IsInGameplay", true)
        setCharacterControlsEnabled(true)
        if camera then
            camera.CameraType = Enum.CameraType.Custom
        end
        print("[MainMenu] Direct Play: Zero loading screens active (instant spawn).")
        return
    end

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
        gameplayTransitionAuthorized = true
        setMenuInputLocked(false)
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
holdMenuCharacter(player.Character)
local menuPromptServiceWasEnabled = ProximityPromptService.Enabled
ProximityPromptService.Enabled = false
local watchedMenuModels: { [Model]: boolean } = {}
hideMenuCharacter = function(character: Model?)
    if not character then return end
    for _, descendant in ipairs(character:GetDescendants()) do
        if descendant:IsA("BasePart") and hiddenMenuParts[descendant] == nil then
            hiddenMenuParts[descendant] = descendant.LocalTransparencyModifier
            descendant.LocalTransparencyModifier = 1
        end
    end
end
local function hideMenuPart(part: BasePart)
    if hiddenMenuParts[part] == nil then
        hiddenMenuParts[part] = part.LocalTransparencyModifier
    end
    part.LocalTransparencyModifier = 1
end
local function watchMenuCharacter(character: Model)
    if watchedMenuModels[character] then return end
    watchedMenuModels[character] = true
    hideMenuCharacter(character)
    character.DescendantAdded:Connect(function(descendant)
        if player:GetAttribute("IsInGameplay") ~= true and descendant:IsA("BasePart") then
            hideMenuPart(descendant)
        end
    end)
end
local function restoreMenuCharacter()
    for part, transparency in pairs(hiddenMenuParts) do
        if part.Parent then
            part.LocalTransparencyModifier = transparency
        end
    end
    table.clear(hiddenMenuParts)
end
hideMenuCharacter(player.Character)
for _, object in ipairs(Workspace:GetChildren()) do
    if object:IsA("Model") and object:GetAttribute("IsCombatTestCharacter") == true then
        watchMenuCharacter(object)
    end
end
-- The campsite and its combat test rig may arrive after this LocalScript starts
-- because StreamingEnabled is on. Hide tagged rigs as they stream in too.
local menuDescendantAddedConnection = Workspace.DescendantAdded:Connect(function(descendant)
    if descendant:IsA("Model") and descendant:GetAttribute("IsCombatTestCharacter") == true then
        watchMenuCharacter(descendant)
    elseif descendant:IsA("BasePart") then
        local ancestor = descendant.Parent
        while ancestor and ancestor ~= Workspace do
            if ancestor:IsA("Model") and ancestor:GetAttribute("IsCombatTestCharacter") == true then
                hideMenuPart(descendant)
                break
            end
            ancestor = ancestor.Parent
        end
    end
end)
local menuCharacterAddedConnection = player.CharacterAdded:Connect(function(character)
    if player:GetAttribute("IsInGameplay") ~= true then
        task.defer(function()
            hideMenuCharacter(character)
            holdMenuCharacter(character)
        end)
    end
end)
holdMenuCharacter(player.Character)
UserInputService.MouseBehavior = Enum.MouseBehavior.Default
UserInputService.MouseIconEnabled = true

--------------------------------------------------------------------------------
-- LIVE 3D FOREST CAMPFIRE SIMULATION AT NIGHT (Reference Image Alignment)
--------------------------------------------------------------------------------
local function resolveMenuSceneCenter(): Vector3
    -- Use the actual campsite that exists in this place. The authored map has
    -- moved campsites over time, so fixed coordinates here can frame empty woods.
    local deadline = os.clock() + 8
    local campfire = Workspace:FindFirstChild("Campfire")
    while not campfire and os.clock() < deadline do
        campfire = Workspace:FindFirstChild("Campfire")
        if not campfire then task.wait(0.1) end
    end

    if campfire then
        local firePart = campfire:FindFirstChild("FirePart", true)
        if firePart and firePart:IsA("BasePart") then
            return firePart.Position
        end
        if campfire:IsA("Model") then
            return campfire:GetPivot().Position
        elseif campfire:IsA("BasePart") then
            return campfire.Position
        end
    end

    local configuredCamp = EnvironmentConfig.CAMP_CENTER
    if typeof(configuredCamp) == "Vector3" then
        return configuredCamp + Vector3.new(0, 8, 0)
    end

    local spawn = Workspace:FindFirstChildOfClass("SpawnLocation")
    if spawn then return spawn.Position end
    return Vector3.new(0, 8, 0)
end

local campCenter = resolveMenuSceneCenter()
local menuFireGlow: PointLight? = nil
local function ensureMenuFireGlow()
    if menuFireGlow and menuFireGlow.Parent then return end
    local campfireModel = Workspace:FindFirstChild("Campfire")
    local firePart = campfireModel and campfireModel:FindFirstChild("FirePart", true)
    if firePart and firePart:IsA("BasePart") then
        local existingGlow = firePart:FindFirstChild("MenuCampfireGlow")
        if existingGlow and existingGlow:IsA("PointLight") then
            menuFireGlow = existingGlow
            return
        end
        local glow = Instance.new("PointLight")
        glow.Name = "MenuCampfireGlow"
        glow.Color = Color3.fromRGB(255, 150, 72)
        glow.Brightness = 1.8
        glow.Range = 35
        glow.Shadows = false
        glow.Parent = firePart
        menuFireGlow = glow
    end
end
-- Match the user's authored Studio camera: a wide, elevated view with the
-- campsite on the right and breathing room for the menu on the left.
local menuCameraPositionOffset = Vector3.new(57, 43.63, 70)
local menuCameraTargetOffset = Vector3.new(-38, -1.37, 0)
local baseCamPos = campCenter + menuCameraPositionOffset
local baseCamTarget = campCenter + menuCameraTargetOffset
player:SetAttribute("MenuSceneReady", false)
task.spawn(function()
    -- The server requests the authored campsite region for this player.
    -- The client sends no position, so it cannot choose arbitrary world areas.
    local remote = sharedFolder:WaitForChild("RequestMenuSceneStream", 12)
    if remote and remote:IsA("RemoteFunction") then
        local ok, streamed, reason, serverCenter = pcall(function()
            return remote:InvokeServer()
        end)
        if not ok or streamed ~= true then
            warn("[MainMenu] Could not prefetch the menu scene: " .. tostring(reason or streamed))
        elseif typeof(serverCenter) == "Vector3" then
            campCenter = serverCenter
            baseCamPos = campCenter + menuCameraPositionOffset
            baseCamTarget = campCenter + menuCameraTargetOffset
            if camera then
                camera.CFrame = CFrame.lookAt(baseCamPos, baseCamTarget)
                camera.Focus = CFrame.new(campCenter)
            end
        end
    else
        warn("[MainMenu] Menu scene streaming request is unavailable; continuing with normal streaming.")
    end
    -- Instances under the campfire can stream after the camp model itself.
    -- Retry briefly so the local menu light is attached as soon as FirePart exists.
    for _ = 1, 30 do
        ensureMenuFireGlow()
        if menuFireGlow then break end
        task.wait(0.1)
    end
    for _, object in ipairs(Workspace:GetChildren()) do
        if object:IsA("Model") and object:GetAttribute("IsCombatTestCharacter") == true then
            watchMenuCharacter(object)
        end
    end
    for _ = 1, 6 do
        RunService.RenderStepped:Wait()
    end
    player:SetAttribute("MenuSceneReady", true)
end)
task.delay(12, function()
    if player:GetAttribute("MenuSceneReady") ~= true then
        warn("[MainMenu] Scene streaming is taking longer than expected; continuing with Roblox streaming.")
        player:SetAttribute("MenuSceneReady", true)
    end
end)
local menuCameraConn: RBXScriptConnection? = nil
local menuStartTime = os.clock()
local menuReturnCFrame: CFrame? = nil
local menuReturnFov = 70
local menuPausedElapsed = 0
local menuCameraTween: Tween? = nil
local menuCameraResumeToken = 0
local menuFlowState = "MainMenu"
local pickerTransitionGeneration = 0

if camera then
    camera.CameraType = Enum.CameraType.Scriptable
    camera.FieldOfView = 70
    camera.CFrame = CFrame.lookAt(baseCamPos, baseCamTarget)
    camera.Focus = CFrame.new(campCenter)
end

local function startMenuCameraSimulation(resumeElapsed: number?)
    if menuCameraConn then
        menuCameraConn:Disconnect()
    end
    if resumeElapsed ~= nil then
        menuStartTime = os.clock() - resumeElapsed
    else
        menuStartTime = os.clock()
    end
    menuCameraConn = RunService.RenderStepped:Connect(function()
        if player:GetAttribute("IsInGameplay") == true then
            if menuCameraConn then
                menuCameraConn:Disconnect()
                menuCameraConn = nil
            end
            return
        end

        camera = Workspace.CurrentCamera or camera
        if camera.CameraType ~= Enum.CameraType.Scriptable then
            camera.CameraType = Enum.CameraType.Scriptable
        end

        local elapsed = os.clock() - menuStartTime

        -- Gentle cinematic drone drift across the high 3/4 camp perspective
        local driftX = math.sin(elapsed * 0.22) * 2.2
        local driftY = math.cos(elapsed * 0.35) * 0.7
        local driftZ = math.sin(elapsed * 0.18) * 1.5

        local camPos = baseCamPos + Vector3.new(driftX, driftY, driftZ)
        local target = baseCamTarget + Vector3.new(math.sin(elapsed * 0.15) * 0.5, 0, 0)
        camera.CFrame = CFrame.lookAt(camPos, target)
        camera.Focus = CFrame.new(target)
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

local introBlackCover: Frame? = nil
if not GameConfig.ShouldSkipSplashScreen() then
    introBlackCover = Instance.new("Frame")
    introBlackCover.Name = "IntroBlackCover"
    introBlackCover.Size = UDim2.fromScale(1, 1)
    introBlackCover.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    introBlackCover.BorderSizePixel = 0
    introBlackCover.ZIndex = 80
    introBlackCover.Parent = screenGui
end

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

-- The actual streamed world remains visible beneath the menu UI.

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

-- Keep the text column legible while leaving the campsite and fire visible.
local leftShade = Instance.new("Frame")
leftShade.Name = "MenuLeftShade"
leftShade.Size = UDim2.new(0.56, 0, 1, 0)
leftShade.BackgroundColor3 = Color3.fromRGB(8, 12, 19)
leftShade.BackgroundTransparency = 0.12
leftShade.BorderSizePixel = 0
leftShade.ZIndex = 4
local leftShadeGradient = Instance.new("UIGradient")
leftShadeGradient.Rotation = 0
leftShadeGradient.Transparency = NumberSequence.new({
    NumberSequenceKeypoint.new(0, 0.12),
    NumberSequenceKeypoint.new(0.58, 0.38),
    NumberSequenceKeypoint.new(1, 1),
})
leftShadeGradient.Parent = leftShade
leftShade.Parent = background

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
leftArea.Size = UDim2.new(0, 400, 0, 490)
leftArea.Position = UDim2.new(0, 72, 0.44, 0)
leftArea.AnchorPoint = Vector2.new(0, 0.5)
leftArea.BackgroundTransparency = 1
leftArea.Visible = false
leftArea.ZIndex = 6
leftArea.Parent = safeArea

-- 1. Top Branding Group (2-Line Condensed Title only; emblem & subtitle removed per request)
local brandingHeader = Instance.new("Frame")
brandingHeader.Name = "BrandingHeader"
brandingHeader.Size = UDim2.new(1, 0, 0, 130)
brandingHeader.Position = UDim2.new(0, 0, 0, 0)
brandingHeader.BackgroundTransparency = 1
brandingHeader.ZIndex = 7
brandingHeader.Parent = leftArea

-- Campfire Emblem (Hidden per user request)
local emblem = CampfireEmblem.new(UDim2.fromOffset(76, 76))
emblem.Root.Visible = false

-- Title Stacked at Top
local titleContainer = Instance.new("Frame")
titleContainer.Name = "TitleContainer"
titleContainer.Size = UDim2.new(1, 0, 0, 120)
titleContainer.Position = UDim2.new(0, 0, 0, 0)
titleContainer.AnchorPoint = Vector2.new(0, 0)
titleContainer.BackgroundTransparency = 1
titleContainer.ZIndex = 7
titleContainer.Parent = brandingHeader

local titleLayout = Instance.new("UIListLayout")
titleLayout.FillDirection = Enum.FillDirection.Vertical
titleLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
titleLayout.VerticalAlignment = Enum.VerticalAlignment.Top
titleLayout.Padding = UDim.new(0, 8)
titleLayout.Parent = titleContainer

-- 2-Line High-Impact Oswald Bold Title ("DON'T LET \n THE FIRE DIE")
local mainTitle = Instance.new("TextLabel")
mainTitle.Name = "MainTitle"
mainTitle.Size = UDim2.new(1, 0, 0, 116)
mainTitle.BackgroundTransparency = 1
mainTitle.Font = Enum.Font.Oswald
mainTitle.Text = "DON'T LET\nTHE FIRE DIE"
mainTitle.TextColor3 = Color3.fromRGB(240, 235, 225) -- Off-white ivory parchment
mainTitle.TextSize = 64
mainTitle.LineHeight = 0.94
mainTitle.TextXAlignment = Enum.TextXAlignment.Left
mainTitle.TextStrokeColor3 = Color3.fromRGB(12, 10, 8)
mainTitle.TextStrokeTransparency = 0.35
mainTitle.ZIndex = 8
mainTitle.Parent = titleContainer

-- Subtitle ("THE NIGHT WILL CLAIM YOU" - Hidden per user request)
local subTitle = Instance.new("TextLabel")
subTitle.Name = "SubTitle"
subTitle.Size = UDim2.new(1, 0, 0, 0)
subTitle.BackgroundTransparency = 1
subTitle.Visible = false
subTitle.Parent = titleContainer

-- 2. Navigation Actions Container (PLAY, SETTINGS, CREDITS)
local navContainer = Instance.new("Frame")
navContainer.Name = "NavContainer"
navContainer.Size = UDim2.new(1, 0, 0, 180)
navContainer.Position = UDim2.new(0, 0, 0, 140)
navContainer.AnchorPoint = Vector2.new(0, 0)
navContainer.BackgroundTransparency = 1
navContainer.ZIndex = 9
navContainer.Parent = leftArea

local navLayout = Instance.new("UIListLayout")
navLayout.FillDirection = Enum.FillDirection.Vertical
navLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
navLayout.VerticalAlignment = Enum.VerticalAlignment.Top
navLayout.SortOrder = Enum.SortOrder.LayoutOrder
navLayout.Padding = UDim.new(0, 4)
navLayout.Parent = navContainer

-- 3. Bottom-Left Studio Watermark Stamp (Image reference: "A FLUENOSITY STUDIO GAME")
local studioStamp = Instance.new("TextLabel")
studioStamp.Name = "StudioStamp"
studioStamp.Size = UDim2.new(0, 320, 0, 20)
studioStamp.Position = UDim2.new(0, 4, 1, -8)
studioStamp.AnchorPoint = Vector2.new(0, 1)
studioStamp.BackgroundTransparency = 1
studioStamp.Font = Enum.Font.GothamMedium
studioStamp.Text = "A Fluenosity Studios production."
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
        leftArea.Size = UDim2.new(0, 320, 0, 360)
        brandingHeader.Size = UDim2.new(1, 0, 0, 90)
        titleContainer.Position = UDim2.new(0, 0, 0, 0)
        mainTitle.TextSize = 36
        navContainer.Size = UDim2.new(1, 0, 0, 150)
        navContainer.Position = UDim2.new(0, 0, 0, 100)
    else
        leftArea.Size = UDim2.new(0, 400, 0, 440)
        brandingHeader.Size = UDim2.new(1, 0, 0, 130)
        titleContainer.Position = UDim2.new(0, 0, 0, 0)
        mainTitle.TextSize = 64
        navContainer.Size = UDim2.new(1, 0, 0, 180)
        navContainer.Position = UDim2.new(0, 0, 0, 140)
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
        leftArea.Position = UDim2.new(0, 72, 0.44, 0)
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
    menuFlowState = "StartingGame"
    pickerTransitionGeneration += 1
    isBusy = true
    if menuCameraTween then
        menuCameraTween:Cancel()
        menuCameraTween = nil
    end
    if menuCameraConn then
        menuCameraConn:Disconnect()
        menuCameraConn = nil
    end

    local fadeTime = reducedMotionEnabled and 0.25 or 0.45
    local fadeInfo = TweenInfo.new(fadeTime, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

    -- Smooth cinematic camera glide down from high 3/4 crane into the campsite
    if camera then
        local glideTargetCFrame = CFrame.lookAt(campCenter + Vector3.new(0, 7, 15), campCenter)
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
        wardrobeScreen.Destroy()
        screenGui:Destroy()
        if menuFireGlow then
            menuFireGlow:Destroy()
            menuFireGlow = nil
        end
        menuCharacterAddedConnection:Disconnect()
        menuDescendantAddedConnection:Disconnect()
        restoreMenuCharacter()
        ProximityPromptService.Enabled = menuPromptServiceWasEnabled
        gameplayTransitionAuthorized = true
        setMenuInputLocked(false)
        player:SetAttribute("IsInGameplay", true)
        setCharacterControlsEnabled(true)
        if camera then
            camera.CameraType = Enum.CameraType.Custom
        end
    end, selection)
end

local function createMenuLink(
    name: string,
    label: string,
    order: number,
    primary: boolean,
    onActivated: () -> ()
): TextButton
    local button = Instance.new("TextButton")
    button.Name = name
    button.Size = UDim2.new(1, 0, 0, primary and 62 or 52)
    button.LayoutOrder = order
    button.BackgroundTransparency = 1
    button.BorderSizePixel = 0
    button.AutoButtonColor = false
    button.Active = true
    button.Selectable = true
    button.Text = label
    button.Font = Enum.Font.Oswald
    button.TextSize = primary and 38 or 29
    button.TextColor3 = primary and Color3.fromRGB(255, 184, 99) or Color3.fromRGB(227, 226, 217)
    button.TextXAlignment = Enum.TextXAlignment.Left
    button.TextYAlignment = Enum.TextYAlignment.Center
    button.TextTransparency = 1
    button.ZIndex = 10
    button.Parent = navContainer

    local rule = Instance.new("Frame")
    rule.Name = "ActiveRule"
    rule.AnchorPoint = Vector2.new(0, 1)
    rule.Position = UDim2.new(0, 0, 1, -5)
    rule.Size = UDim2.fromOffset(primary and 156 or 0, 2)
    rule.BackgroundColor3 = Color3.fromRGB(250, 153, 68)
    rule.BackgroundTransparency = primary and 0.08 or 1
    rule.BorderSizePixel = 0
    rule.ZIndex = 11
    rule.Parent = button

    local ruleGradient = Instance.new("UIGradient")
    ruleGradient.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.45),
        NumberSequenceKeypoint.new(0.45, 0),
        NumberSequenceKeypoint.new(1, 1),
    })
    ruleGradient.Parent = rule

    button.MouseEnter:Connect(function()
        if not primary then
            TweenService:Create(rule, UITheme.Tweens.Fast, {
                Size = UDim2.fromOffset(74, 2),
                BackgroundTransparency = 0.15,
            }):Play()
        end
        TweenService:Create(button, UITheme.Tweens.Fast, {
            TextColor3 = Color3.fromRGB(255, 190, 112),
        }):Play()
        pcall(function()
            AudioManager.Play("Hover")
        end)
    end)

    button.MouseLeave:Connect(function()
        if not primary then
            TweenService:Create(rule, UITheme.Tweens.Fast, {
                Size = UDim2.fromOffset(0, 2),
                BackgroundTransparency = 1,
            }):Play()
        end
        TweenService:Create(button, UITheme.Tweens.Fast, {
            TextColor3 = primary and Color3.fromRGB(255, 184, 99) or Color3.fromRGB(227, 226, 217),
        }):Play()
    end)

    button.Activated:Connect(function()
        UITheme.PlayClick()
        onActivated()
    end)

    return button
end

local navPlay: TextButton
navPlay = createMenuLink("NavPlay", "PLAY", 1, true, function()
    if isBusy or menuFlowState ~= "MainMenu" then return end
    -- PLAY only opens survivor selection. The actual gameplay transition belongs
    -- to the picker's final confirmation button.

    -- Update UI state FIRST before any yielding calls (holdMenuCharacter yields
    -- internally via WaitForChild, so text feedback must come before it).
    isBusy = true
    menuFlowState = "Preparing"
    navPlay.Text = "PREPARING CAMP..."
    navPlay.TextTransparency = 0
    navPlay.Active = false
    navPlay.Selectable = false

    player:SetAttribute("IsInGameplay", false)
    holdMenuCharacter(player.Character)
    pickerTransitionGeneration += 1
    local transitionId = pickerTransitionGeneration
    -- Keep the main menu and its wide forest shot on screen while the lobby
    -- snapshot finishes. The label changes synchronously, so the click always
    -- has feedback even when matchmaking or the server takes a moment.
    task.spawn(function()
        local prepareStartedAt = os.clock()
        local prepareDeadline = prepareStartedAt + 2.5
        local minimumPrepareTime = 1.15
        while transitionId == pickerTransitionGeneration
            and menuFlowState == "Preparing"
            and os.clock() < prepareDeadline
            and ((os.clock() - prepareStartedAt) < minimumPrepareTime
                or (wardrobeScreen.IsLobbyReady and not wardrobeScreen.IsLobbyReady())) do
            task.wait(0.05)
        end
        if transitionId ~= pickerTransitionGeneration or menuFlowState ~= "Preparing" then
            return
        end

        menuFlowState = "OpeningPicker"
        navPlay.Text = "ENTERING CAMP..."
        navPlay.TextTransparency = 0
        -- Leave the second status on screen long enough to read before the
        -- main-menu layer clears for the camera glide.
        task.wait(0.55)
        if transitionId ~= pickerTransitionGeneration or menuFlowState ~= "OpeningPicker" then
            return
        end
        menuCameraResumeToken += 1
        camera = Workspace.CurrentCamera or camera
        if camera then
            camera.CameraType = Enum.CameraType.Scriptable
        end
        menuReturnCFrame = camera and camera.CFrame or CFrame.lookAt(baseCamPos, baseCamTarget)
        menuReturnFov = camera and camera.FieldOfView or 70
        menuPausedElapsed = os.clock() - menuStartTime
        if menuCameraConn then
            menuCameraConn:Disconnect()
            menuCameraConn = nil
        end
        -- Clear the main-menu screen before the glide. The survivor picker is
        -- mounted only after the camera reaches its camp framing.
        leftArea.Visible = false
        studioStamp.Visible = false
        if rightArea then rightArea.Visible = false end

        local function showSurvivorPicker()
            if transitionId ~= pickerTransitionGeneration or menuFlowState ~= "OpeningPicker" then
                return
            end
            menuFlowState = "Picker"
            navPlay.Text = "PLAY"
            navPlay.Active = true
            navPlay.Selectable = true
            isBusy = false
            wardrobeScreen.Open(function()
                if menuFlowState ~= "OpeningPicker" and menuFlowState ~= "Picker" then return end
                menuFlowState = "Returning"
                pickerTransitionGeneration += 1
                local returnTransitionId = pickerTransitionGeneration
                player:SetAttribute("IsInGameplay", false)

                -- holdMenuCharacter → setCharacterControlsEnabled → WaitForChild("PlayerScripts", 3)
                -- can yield for up to 3 seconds. Fire it async so it never blocks the
                -- camera tween or wardrobe fade from starting immediately on click.
                task.spawn(function()
                    holdMenuCharacter(player.Character)
                end)

                camera = Workspace.CurrentCamera or camera
                if menuCameraTween then
                    menuCameraTween:Cancel()
                    menuCameraTween = nil
                end
                local returnCFrame = menuReturnCFrame or CFrame.lookAt(baseCamPos, baseCamTarget)
                local resumeElapsed = menuPausedElapsed
                menuCameraResumeToken += 1
                local resumeToken = menuCameraResumeToken
                isBusy = true
                navPlay.Text = "LEAVING CAMP..."
                navPlay.Active = false
                navPlay.Selectable = false

                -- Delay the wardrobe fade so it begins near the END of the camera
                -- return flight, not at the start. Camera tween = 0.75s, scrim = 0.30s,
                -- so t=0.45s start means the dissolve finishes exactly as camera arrives.
                local hideToken = pickerTransitionGeneration
                task.delay(0.45, function()
                    if pickerTransitionGeneration == hideToken
                        and menuFlowState == "Returning"
                        and wardrobeScreen.HideForReturn then
                        wardrobeScreen.HideForReturn()
                    end
                end)


                local function finishReturn()
                    if returnTransitionId ~= pickerTransitionGeneration or menuFlowState ~= "Returning" then
                        return
                    end
                    menuCameraTween = nil
                    wardrobeScreen.Close()
                    leftArea.Visible = true
                    studioStamp.Visible = true
                    navPlay.Text = "PLAY"
                    navPlay.Active = true
                    navPlay.Selectable = true
                    menuFlowState = "MainMenu"
                    isBusy = false
                    startMenuCameraSimulation(resumeElapsed)
                    menuReturnCFrame = nil
                end

                if camera then
                    camera.CameraType = Enum.CameraType.Scriptable
                    menuCameraTween = TweenService:Create(camera, TweenInfo.new(0.75, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut), {
                        CFrame = returnCFrame,
                        FieldOfView = menuReturnFov,
                    })
                    menuCameraTween.Completed:Connect(function(playbackState)
                        if playbackState == Enum.PlaybackState.Completed
                            and resumeToken == menuCameraResumeToken then
                            finishReturn()
                        end
                    end)
                    menuCameraTween:Play()
                else
                    finishReturn()
                end
            end, function(selection)
                beginGame(selection)
            end)
        end

        if camera then
            if menuCameraTween then
                menuCameraTween:Cancel()
            end
            menuCameraTween = TweenService:Create(camera, TweenInfo.new(1.05, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut), {
                CFrame = CFrame.lookAt(campCenter + Vector3.new(-8, 10, 19), campCenter + Vector3.new(0, 3, 0)),
                FieldOfView = 48,
            })
            menuCameraTween.Completed:Connect(function(playbackState)
                if playbackState ~= Enum.PlaybackState.Completed
                    or transitionId ~= pickerTransitionGeneration
                    or menuFlowState ~= "OpeningPicker" then
                    return
                end
                menuCameraTween = nil
                showSurvivorPicker()
            end)
            menuCameraTween:Play()
        else
            showSurvivorPicker()
        end
    end)
end)

local navSettings = createMenuLink("NavSettings", "SETTINGS", 2, false, function()
    if menuFlowState ~= "MainMenu" or isBusy then return end
    settingsModal.Open()
end)

local navCredits = createMenuLink("NavCredits", "CREDITS", 3, false, function()
    if menuFlowState ~= "MainMenu" or isBusy then return end
    creditsModal.Open()
end)

--------------------------------------------------------------------------------
-- CINEMATIC INTRO SEQUENCE (STAGGERED: LEFT FROM LEFT, RIGHT FROM RIGHT)
--------------------------------------------------------------------------------
local function runCinematicIntro()
    isBusy = true

    ----------------------------------------------------------------------------
    -- PHASE 1: MODULAR INTRO SEQUENCE (WARNING -> SPLASH -> HEADPHONES)
    ----------------------------------------------------------------------------
    if not GameConfig.ShouldSkipSplashScreen() then
        -- Step 1: Warning Screen (Photosensitivity & Epilepsy + Psychological Disclaimer)
        UI.WarningScreen.Show(screenGui)

        -- Step 2: Studio Splash Screen ("A FLUENOSITY STUDIO PRODUCTION", Pure White)
        UI.SplashScreen.Show(screenGui)

        -- Step 3: Headphone Advisory Screen ("HEADPHONES RECOMMENDED", Spatial Audio)
        UI.HeadphoneAdvisory.Show(screenGui)
    end

    -- Smoothly dissolve the intro black cover to reveal the wide live campsite vista
    if introBlackCover and introBlackCover.Parent then
        local fadeCover = TweenService:Create(introBlackCover, TweenInfo.new(0.65, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            BackgroundTransparency = 1,
        })
        fadeCover:Play()
        fadeCover.Completed:Wait()
        introBlackCover:Destroy()
        introBlackCover = nil
    end

    -- Start gentle ambient embers
    emberSystem:Start()

    ----------------------------------------------------------------------------
    -- PHASE 2: "PRESS ANY KEY / TAP TO ENTER CAMP" GATEWAY
    -- Holds on the wide cinematic campsite vista with live music & drone camera.
    ----------------------------------------------------------------------------
    local gatewayContainer = Instance.new("Frame")
    gatewayContainer.Name = "GatewayContainer"
    gatewayContainer.Size = UDim2.fromScale(1, 1)
    gatewayContainer.BackgroundTransparency = 1
    gatewayContainer.ZIndex = 40
    gatewayContainer.Parent = screenGui

    local gatewayDetector = Instance.new("TextButton")
    gatewayDetector.Name = "GatewayDetector"
    gatewayDetector.Size = UDim2.fromScale(1, 1)
    gatewayDetector.BackgroundTransparency = 1
    gatewayDetector.Text = ""
    gatewayDetector.AutoButtonColor = false
    gatewayDetector.ZIndex = 41
    gatewayDetector.Parent = gatewayContainer

    local promptFrame = Instance.new("Frame")
    promptFrame.Name = "PromptFrame"
    promptFrame.AnchorPoint = Vector2.new(0.5, 0.5)
    promptFrame.Position = UDim2.new(0.5, 0, 0.88, 0)
    promptFrame.Size = UDim2.new(0.9, 0, 0, 60)
    promptFrame.BackgroundTransparency = 1
    promptFrame.ZIndex = 42
    promptFrame.Parent = gatewayContainer

    local promptLayout = Instance.new("UIListLayout")
    promptLayout.FillDirection = Enum.FillDirection.Vertical
    promptLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    promptLayout.VerticalAlignment = Enum.VerticalAlignment.Center
    promptLayout.Padding = UDim.new(0, 4)
    promptLayout.Parent = promptFrame

    local isTouchOnly = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled

    local mainPrompt = Instance.new("TextLabel")
    mainPrompt.Name = "MainPrompt"
    mainPrompt.Size = UDim2.new(1, 0, 0, 26)
    mainPrompt.BackgroundTransparency = 1
    mainPrompt.Font = Enum.Font.GothamBold
    mainPrompt.Text = if isTouchOnly then "TAP TO ENTER CAMP" else "PRESS ANY KEY TO ENTER CAMP"
    mainPrompt.TextColor3 = Color3.fromRGB(255, 255, 255)
    mainPrompt.TextSize = 18
    mainPrompt.TextStrokeTransparency = 0.55
    mainPrompt.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    mainPrompt.TextTransparency = 1
    mainPrompt.ZIndex = 43
    mainPrompt.Parent = promptFrame

    local subPrompt = Instance.new("TextLabel")
    subPrompt.Name = "SubPrompt"
    subPrompt.Size = UDim2.new(1, 0, 0, 18)
    subPrompt.BackgroundTransparency = 1
    subPrompt.Font = Enum.Font.GothamMedium
    subPrompt.Text = if isTouchOnly then "[ TAP SCREEN TO CONTINUE ]" else "[ CLICK ANYWHERE TO CONTINUE ]"
    subPrompt.TextColor3 = Color3.fromRGB(245, 140, 40)
    subPrompt.TextSize = 11
    subPrompt.TextStrokeTransparency = 0.6
    subPrompt.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    subPrompt.TextTransparency = 1
    subPrompt.ZIndex = 43
    subPrompt.Parent = promptFrame

    -- Fade in the gateway prompt
    local fadeInPrompt1 = TweenService:Create(mainPrompt, TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { TextTransparency = 0 })
    local fadeInPrompt2 = TweenService:Create(subPrompt, TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { TextTransparency = 0 })
    fadeInPrompt1:Play()
    fadeInPrompt2:Play()
    fadeInPrompt1.Completed:Wait()

    -- Pulsing glow breathing animation
    local isPulsingGateway = true
    task.spawn(function()
        while isPulsingGateway and promptFrame.Parent do
            local p1 = TweenService:Create(mainPrompt, TweenInfo.new(1.0, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), { TextTransparency = 0.45 })
            local p2 = TweenService:Create(subPrompt, TweenInfo.new(1.0, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), { TextTransparency = 0.55 })
            p1:Play()
            p2:Play()
            p1.Completed:Wait()
            if not isPulsingGateway or not promptFrame.Parent then break end
            local p3 = TweenService:Create(mainPrompt, TweenInfo.new(1.0, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), { TextTransparency = 0.0 })
            local p4 = TweenService:Create(subPrompt, TweenInfo.new(1.0, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), { TextTransparency = 0.0 })
            p3:Play()
            p4:Play()
            p3.Completed:Wait()
        end
    end)

    -- Wait for key press or click/tap
    local gatewayPassed = false
    local gatewayInputConn: RBXScriptConnection? = nil
    local gatewayClickConn: RBXScriptConnection? = nil
    local resumeGatewayThread = coroutine.running()

    local function triggerGateway()
        if gatewayPassed then return end
        gatewayPassed = true
        isPulsingGateway = false
        if gatewayInputConn then gatewayInputConn:Disconnect() gatewayInputConn = nil end
        if gatewayClickConn then gatewayClickConn:Disconnect() gatewayClickConn = nil end

        UITheme.PlayClick()

        -- Fade out the prompt quickly
        local fadeOut1 = TweenService:Create(mainPrompt, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { TextTransparency = 1 })
        local fadeOut2 = TweenService:Create(subPrompt, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { TextTransparency = 1 })
        fadeOut1:Play()
        fadeOut2:Play()
        fadeOut1.Completed:Wait()
        gatewayContainer:Destroy()

        task.spawn(resumeGatewayThread)
    end

    gatewayClickConn = gatewayDetector.MouseButton1Click:Connect(triggerGateway)
    gatewayInputConn = UserInputService.InputBegan:Connect(function(input, gpe)
        if not gpe and (
            input.UserInputType == Enum.UserInputType.Keyboard
            or input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch
            or input.UserInputType == Enum.UserInputType.Gamepad1
        ) then
            triggerGateway()
        end
    end)

    coroutine.yield()

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
    studioStamp.TextTransparency = 1

    local areaTween = TweenService:Create(leftArea, TweenInfo.new(0.55, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        Position = targetLeftPos,
    })
    areaTween:Play()

    local headerTween = TweenService:Create(brandingHeader, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        Position = UDim2.new(0, 0, 0, 0),
    })
    headerTween:Play()
    TweenService:Create(mainTitle, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { TextTransparency = 0 }):Play()
    TweenService:Create(studioStamp, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { TextTransparency = 0 }):Play()

    task.wait(0.12)

    -- Reveal the simple text menu links one at a time, with PLAY highlighted.
    local navItems = { navPlay, navSettings, navCredits }
    for i, button in ipairs(navItems) do
        local rule = button:FindFirstChild("ActiveRule") :: Frame?
        if rule then
            rule.Size = UDim2.fromOffset(0, 2)
            rule.BackgroundTransparency = 1
        end
        task.delay((i - 1) * 0.11, function()
            TweenService:Create(button, TweenInfo.new(0.34, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                TextTransparency = 0,
            }):Play()
            if rule then
                TweenService:Create(rule, TweenInfo.new(0.38, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                    Size = UDim2.fromOffset(i == 1 and 156 or 0, 2),
                    BackgroundTransparency = i == 1 and 0.08 or 1,
                }):Play()
            end
        end)
    end

    hasIntroCompleted = true
    isBusy = false
end

--------------------------------------------------------------------------------
-- MAIN MENU MUSIC (Fades in when early curtain finishes, fades out at game entry)
--------------------------------------------------------------------------------
local function startMainMenuMusic()
    local existing = SoundService:FindFirstChild("MainMenuBGM") :: Sound?
    if existing then
        if not existing.IsPlaying then
            existing:Play()
        end
        return existing
    end

    local bgm = Instance.new("Sound")
    bgm.Name = "MainMenuBGM"
    bgm.SoundId = "rbxassetid://83951143649241"
    bgm.SoundGroup = UITheme.GetMusicSoundGroup()
    bgm.Looped = true
    bgm.Volume = 0
    bgm.Parent = SoundService

    bgm:Play()
    -- Gentle atmospheric fade in over 3.2s so players aren't startled
    local fadeInTween = TweenService:Create(bgm, TweenInfo.new(3.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        Volume = 0.55,
    })
    fadeInTween:Play()
    return bgm
end

task.spawn(function()
    local readyDeadline = os.clock() + 50
    while (player:GetAttribute("InitialMenuAssetsReady") ~= true or player:GetAttribute("MenuSceneReady") ~= true)
        and os.clock() < readyDeadline do
        task.wait(0.05)
    end

    -- Wait until the early curtain finishes fading out and destroys itself
    local curtainDeadline = os.clock() + 10
    while player:GetAttribute("EarlyCurtainFinished") ~= true and os.clock() < curtainDeadline do
        task.wait(0.05)
    end

    startMainMenuMusic()
    runCinematicIntro()
end)
