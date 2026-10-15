--!strict
--[[
    SystemMenu.lua
    Production-Grade Glassmorphic In-Game ESC / Settings Menu for "Don't Let the Fire Die".
    Part of the modular UI library (FluenosityClient/UI).
    
    Features:
    - Pure luxury glassmorphic cards with specular hairline borders
    - 2-Column layout: Left Tab Navigation + Right Scrollable Content Canvas
    - 4 Rich Tabs:
        1. SETTINGS: Audio Sliders (Master, SFX, Music, Environment), Look Sensitivity, Immersion Toggles
        2. CONTROLS: Complete keybinding cards with glass keycaps
        3. SURVIVAL: Tactical prologue objectives & hearth monitor
        4. INTEL: Hollow field notes & survival mechanics
    - Clean ModalManager coordinator integration (locks FPP camera, releases mouse)
    - Zero hover bouncing; crisp click compression and pleasant audio cues
]]

local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local UITheme = require(script.Parent:WaitForChild("UITheme"))
local Button = require(script.Parent:WaitForChild("Button"))
local IconButton = require(script.Parent:WaitForChild("IconButton"))
local Slider = require(script.Parent:WaitForChild("Slider"))
local Toggle = require(script.Parent:WaitForChild("Toggle"))
local Divider = require(script.Parent:WaitForChild("Divider"))
local GlassPanel = require(script.Parent:WaitForChild("GlassPanel"))

local sharedFolder = ReplicatedStorage:WaitForChild("FluenosityShared")
local IconPack = require(sharedFolder:WaitForChild("IconPack"))
local AudioManager = require(script.Parent.Parent:WaitForChild("AudioManager"))
local ModalManager = require(script.Parent.Parent:WaitForChild("ModalManager"))

export type SystemMenuCallbacks = {
    OnResume: () -> (),
    OnQuit: () -> (),
    OnClose: (() -> ())?,
}

export type SystemMenuInstance = {
    Container: Frame,
    Open: () -> (),
    Close: () -> (),
    IsOpen: () -> boolean,
    Destroy: () -> (),
}

local SystemMenu = {}

function SystemMenu.Create(parent: Instance, callbacks: SystemMenuCallbacks): SystemMenuInstance
    local isOpen = false
    local isTransitioning = false

    -- Fullscreen Backdrop Overlay
    local backdrop = Instance.new("TextButton")
    backdrop.Name = "SystemMenu"
    backdrop.Size = UDim2.fromScale(1, 1)
    backdrop.Position = UDim2.fromScale(0, 0)
    backdrop.BackgroundColor3 = Color3.fromRGB(6, 6, 8)
    backdrop.BackgroundTransparency = 1
    backdrop.BorderSizePixel = 0
    backdrop.Text = ""
    backdrop.AutoButtonColor = false
    backdrop.Visible = false
    backdrop.ZIndex = 90
    backdrop.Parent = parent

    -- Atmospheric Dark Vignette
    local vignette = Instance.new("Frame")
    vignette.Name = "Vignette"
    vignette.Size = UDim2.fromScale(1, 1)
    vignette.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    vignette.BackgroundTransparency = 0.45
    vignette.BorderSizePixel = 0
    vignette.ZIndex = 91
    vignette.Parent = backdrop

    local vigGrad = Instance.new("UIGradient")
    vigGrad.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.4),
        NumberSequenceKeypoint.new(0.65, 0.7),
        NumberSequenceKeypoint.new(1, 0.95),
    })
    vigGrad.Parent = vignette

    ----------------------------------------------------------------------------
    -- MAIN MODAL WINDOW (Centered Glass Card with Top Tabs)
    ----------------------------------------------------------------------------
    local windowFrame = Instance.new("Frame")
    windowFrame.Name = "WindowFrame"
    windowFrame.Size = UDim2.new(1, -120, 1, -120)
    windowFrame.Position = UDim2.new(0.5, 0, 0.5, 20)
    windowFrame.AnchorPoint = Vector2.new(0.5, 0.5)
    windowFrame.BackgroundTransparency = 1
    windowFrame.ZIndex = 92
    windowFrame.Parent = backdrop

    local wsConstraint = Instance.new("UISizeConstraint")
    wsConstraint.MaxSize = Vector2.new(1240, 760)
    wsConstraint.MinSize = Vector2.new(680, 480)
    wsConstraint.Parent = windowFrame

    ----------------------------------------------------------------------------
    -- TOP HEADER BAR (Title on Left, Horizontal Tabs in Center, Actions on Right)
    ----------------------------------------------------------------------------
    local headerBar = Instance.new("Frame")
    headerBar.Name = "HeaderBar"
    headerBar.Size = UDim2.new(1, 0, 0, 48)
    headerBar.Position = UDim2.fromOffset(0, 0)
    headerBar.BackgroundTransparency = 1
    headerBar.ZIndex = 93
    headerBar.Parent = windowFrame

    -- 1. Left of Header: Title with Ember Icon (subtext removed)
    local titleFrame = Instance.new("Frame")
    titleFrame.Name = "TitleFrame"
    titleFrame.Size = UDim2.new(0, 180, 1, 0)
    titleFrame.Position = UDim2.fromOffset(0, 0)
    titleFrame.BackgroundTransparency = 1
    titleFrame.ZIndex = 94
    titleFrame.Parent = headerBar

    local headerIcon = IconPack.CreateIcon("settings", 20, UITheme.Colors.EmberPrimary, 0)
    headerIcon.Position = UDim2.new(0, 0, 0.5, 0)
    headerIcon.AnchorPoint = Vector2.new(0, 0.5)
    headerIcon.ZIndex = 95
    headerIcon.Parent = titleFrame

    local logoText = Instance.new("TextLabel")
    logoText.Name = "LogoText"
    logoText.Size = UDim2.new(1, -28, 1, 0)
    logoText.Position = UDim2.new(0, 28, 0.5, 0)
    logoText.AnchorPoint = Vector2.new(0, 0.5)
    logoText.BackgroundTransparency = 1
    logoText.Font = UITheme.Fonts.Heading
    logoText.Text = "MENU"
    logoText.TextColor3 = UITheme.Colors.TextPrimary
    logoText.TextSize = 14
    logoText.TextXAlignment = Enum.TextXAlignment.Left
    logoText.TextYAlignment = Enum.TextYAlignment.Center
    logoText.ZIndex = 95
    logoText.Parent = titleFrame

    -- 2. Center of Header: Horizontal Navigation Tabs
    local tabsContainer = Instance.new("Frame")
    tabsContainer.Name = "TabsContainer"
    tabsContainer.Size = UDim2.new(1, -500, 1, 0)
    tabsContainer.Position = UDim2.fromOffset(190, 0)
    tabsContainer.BackgroundTransparency = 1
    tabsContainer.ZIndex = 94
    tabsContainer.Parent = headerBar

    local tabsLayout = Instance.new("UIListLayout")
    tabsLayout.FillDirection = Enum.FillDirection.Horizontal
    tabsLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
    tabsLayout.VerticalAlignment = Enum.VerticalAlignment.Center
    tabsLayout.Padding = UDim.new(0, 8)
    tabsLayout.Parent = tabsContainer

    -- 3. Right of Header: Action Buttons (QUIT + RESUME)
    local actionsContainer = Instance.new("Frame")
    actionsContainer.Name = "ActionsContainer"
    actionsContainer.Size = UDim2.new(0, 310, 1, 0)
    actionsContainer.Position = UDim2.new(1, 0, 0.5, 0)
    actionsContainer.AnchorPoint = Vector2.new(1, 0.5)
    actionsContainer.BackgroundTransparency = 1
    actionsContainer.ZIndex = 94
    actionsContainer.Parent = headerBar

    local actionsLayout = Instance.new("UIListLayout")
    actionsLayout.FillDirection = Enum.FillDirection.Horizontal
    actionsLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
    actionsLayout.VerticalAlignment = Enum.VerticalAlignment.Center
    actionsLayout.Padding = UDim.new(0, 8)
    actionsLayout.Parent = actionsContainer

    local quitBtn = Button.Create({
        Text = "QUIT",
        IconName = "power",
        Variant = "Danger",
        Size = UDim2.fromOffset(95, 36),
        ZIndex = 95,
        Parent = actionsContainer,
        OnClick = function()
            backdrop.Visible = false
            callbacks.OnQuit()
        end,
    })

    local closeBtn = IconButton.Create({
        IconName = "x",
        IconSize = 16,
        Size = 36,
        IsCloseButton = true,
        Tooltip = "Close Menu (ESC)",
        ZIndex = 95,
        Parent = actionsContainer,
        OnClick = function()
            if callbacks.OnResume then
                callbacks.OnResume()
            end
        end,
    })

    -- Divider below Header & Tabs
    local topDivider = Divider.Create({
        Parent = windowFrame,
        MarginVertical = 0,
        Position = UDim2.fromOffset(0, 56),
        Size = UDim2.new(1, 0, 0, 1),
    })

    ----------------------------------------------------------------------------
    -- FULL-WIDTH CONTENT CANVAS (Glass Container for active tab view)
    ----------------------------------------------------------------------------
    local rightCanvasPanel = GlassPanel.Create({
        Size = UDim2.new(1, 0, 1, -66),
        Position = UDim2.fromOffset(0, 66),
        Padding = 24,
        Parent = windowFrame,
    })
    local rightCanvas = rightCanvasPanel
    rightCanvas.ZIndex = 93

    ----------------------------------------------------------------------------
    -- NAVIGATION SYSTEM & TAB VIEWS
    ----------------------------------------------------------------------------
    local currentTab = "SETTINGS"
    local navButtons: { [string]: {
        Row: TextButton,
        AccentBar: Frame,
        TitleLabel: TextLabel,
        Icon: Instance,
    } } = {}
    local tabViews: { [string]: ScrollingFrame } = {}

    local TAB_DEFS = {
        { Id = "SETTINGS", Name = "SETTINGS", Icon = "settings" },
        { Id = "CONTROLS", Name = "CONTROLS", Icon = "gamepad-2" },
        { Id = "SURVIVAL", Name = "SURVIVAL", Icon = "compass" },
        { Id = "QUESTS",   Name = "QUESTS",   Icon = "map-pin" },
    }

    local function switchTab(targetTab: string)
        currentTab = targetTab
        for tId, data in pairs(navButtons) do
            local isSel = (tId == currentTab)
            data.AccentBar.Visible = isSel
            data.TitleLabel.TextColor3 = isSel and UITheme.Colors.PureWhite or UITheme.Colors.TextSecondary
            data.Row.BackgroundColor3 = isSel and UITheme.Colors.SurfaceElevated or UITheme.Colors.GlassSurface
            data.Row.BackgroundTransparency = isSel and 0.25 or 0.75
            local rowStroke = data.Row:FindFirstChildOfClass("UIStroke")
            if rowStroke then
                rowStroke.Color = isSel and UITheme.Colors.EmberPrimary or UITheme.Colors.BorderSubtle
                rowStroke.Transparency = isSel and 0.2 or 0.8
            end
        end
        for tId, view in pairs(tabViews) do
            view.Visible = (tId == currentTab)
        end
    end

    for _, def in ipairs(TAB_DEFS) do
        -- Create Scrollable Tab View Frame inside RightCanvas (Full-Width)
        local scroll = Instance.new("ScrollingFrame")
        scroll.Name = "View_" .. def.Id
        scroll.Size = UDim2.fromScale(1, 1)
        scroll.BackgroundTransparency = 1
        scroll.BorderSizePixel = 0
        scroll.ScrollBarThickness = 3
        scroll.ScrollBarImageColor3 = UITheme.Colors.EmberHot
        scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
        scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
        scroll.Visible = (def.Id == currentTab)
        scroll.ZIndex = 94
        scroll.Parent = rightCanvas
        tabViews[def.Id] = scroll

        local sPadding = Instance.new("UIPadding")
        sPadding.PaddingRight = UDim.new(0, 8)
        sPadding.Parent = scroll

        -- Create Horizontal Tab Button in tabsContainer
        local tabBtn = Instance.new("TextButton")
        tabBtn.Name = "Tab_" .. def.Id
        tabBtn.Size = UDim2.fromOffset(125, 38)
        tabBtn.BackgroundColor3 = (def.Id == currentTab) and UITheme.Colors.SurfaceElevated or UITheme.Colors.GlassSurface
        tabBtn.BackgroundTransparency = (def.Id == currentTab) and 0.25 or 0.75
        tabBtn.AutoButtonColor = false
        tabBtn.Text = ""
        tabBtn.ZIndex = 95
        tabBtn.Parent = tabsContainer

        local btnCorner = Instance.new("UICorner")
        btnCorner.CornerRadius = UDim.new(0, 8)
        btnCorner.Parent = tabBtn

        local btnStroke = Instance.new("UIStroke")
        btnStroke.Color = (def.Id == currentTab) and UITheme.Colors.EmberPrimary or UITheme.Colors.BorderSubtle
        btnStroke.Transparency = (def.Id == currentTab) and 0.2 or 0.8
        btnStroke.Thickness = 1.2
        btnStroke.Parent = tabBtn

        -- Bottom Active Indicator Accent Bar (Underline Pill)
        local accentBar = Instance.new("Frame")
        accentBar.Name = "AccentBar"
        accentBar.Size = UDim2.new(0.7, 0, 0, 2)
        accentBar.Position = UDim2.new(0.5, 0, 1, -2)
        accentBar.AnchorPoint = Vector2.new(0.5, 1)
        accentBar.BackgroundColor3 = UITheme.Colors.EmberPrimary
        accentBar.BorderSizePixel = 0
        accentBar.Visible = (def.Id == currentTab)
        accentBar.ZIndex = 96
        accentBar.Parent = tabBtn

        local barCorner = Instance.new("UICorner")
        barCorner.CornerRadius = UDim.new(1, 0)
        barCorner.Parent = accentBar

        -- Lucide Icon
        local icon = IconPack.CreateIcon(def.Icon, 15, UITheme.Colors.EmberHot, 0)
        icon.Position = UDim2.new(0, 12, 0.5, 0)
        icon.AnchorPoint = Vector2.new(0, 0.5)
        icon.ZIndex = 96
        icon.Parent = tabBtn

        -- Tab Label
        local tLabel = Instance.new("TextLabel")
        tLabel.Name = "Title"
        tLabel.Size = UDim2.new(1, -38, 1, 0)
        tLabel.Position = UDim2.fromOffset(34, 0)
        tLabel.BackgroundTransparency = 1
        tLabel.Font = UITheme.Fonts.Heading
        tLabel.Text = def.Name
        tLabel.TextColor3 = (def.Id == currentTab) and UITheme.Colors.PureWhite or UITheme.Colors.TextSecondary
        tLabel.TextSize = 12
        tLabel.TextXAlignment = Enum.TextXAlignment.Left
        tLabel.ZIndex = 96
        tLabel.Parent = tabBtn

        -- Micro-compression on click (0.96 scale)
        local btnScale = Instance.new("UIScale")
        btnScale.Scale = 1
        btnScale.Parent = tabBtn

        tabBtn.MouseButton1Down:Connect(function()
            TweenService:Create(btnScale, TweenInfo.new(0.08, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                Scale = 0.96,
            }):Play()
        end)

        tabBtn.MouseButton1Up:Connect(function()
            TweenService:Create(btnScale, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                Scale = 1,
            }):Play()
        end)

        navButtons[def.Id] = {
            Row = tabBtn,
            AccentBar = accentBar,
            TitleLabel = tLabel,
            Icon = icon,
        }

        tabBtn.Activated:Connect(function()
            AudioManager.Play("Click")
            switchTab(def.Id)
        end)
    end

    ----------------------------------------------------------------------------
    -- VIEW 1: SETTINGS TAB (Audio Sliders & Controls)
    ----------------------------------------------------------------------------
    local settView = tabViews["SETTINGS"]
    local settLayout = Instance.new("UIListLayout")
    settLayout.FillDirection = Enum.FillDirection.Vertical
    settLayout.SortOrder = Enum.SortOrder.LayoutOrder
    settLayout.Padding = UDim.new(0, 14)
    settLayout.Parent = settView

    local sOrder = 0
    local function nextSOrder(): number
        sOrder += 1
        return sOrder
    end

    local settTitle = Instance.new("TextLabel")
    settTitle.Size = UDim2.new(1, 0, 0, 22)
    settTitle.BackgroundTransparency = 1
    settTitle.Font = UITheme.Fonts.Heading
    settTitle.Text = "AUDIO & PREFERENCES"
    settTitle.TextColor3 = UITheme.Colors.TextPrimary
    settTitle.TextSize = 17
    settTitle.TextXAlignment = Enum.TextXAlignment.Left
    settTitle.LayoutOrder = nextSOrder()
    settTitle.Parent = settView

    local settBadge = Instance.new("TextLabel")
    settBadge.Size = UDim2.new(1, 0, 0, 16)
    settBadge.BackgroundTransparency = 1
    settBadge.Font = UITheme.Fonts.Tag
    settBadge.Text = "MASTER SOUND LEVELS & FIRST-PERSON SENSITIVITY"
    settBadge.TextColor3 = UITheme.Colors.EmberHot
    settBadge.TextSize = 11
    settBadge.TextXAlignment = Enum.TextXAlignment.Left
    settBadge.LayoutOrder = nextSOrder()
    settBadge.Parent = settView

    local sl1 = Slider.Create({
        Label = "MASTER AUDIO VOLUME",
        Description = "Master sound level for the entire game",
        InitialValue = UITheme.GetMasterVolume(),
        Parent = settView,
        OnChanged = function(val: number)
            UITheme.SetMasterVolume(val)
        end,
    })
    sl1.LayoutOrder = nextSOrder()

    local sl2 = Slider.Create({
        Label = "SFX VOLUME",
        Description = "UI clicks, item interactions, wood gathering & equipment sounds",
        InitialValue = UITheme.GetSFXVolume(),
        Parent = settView,
        OnChanged = function(val: number)
            UITheme.SetSFXVolume(val)
        end,
    })
    sl2.LayoutOrder = nextSOrder()

    local sl3 = Slider.Create({
        Label = "MUSIC & SOUNDTRACK",
        Description = "Melodic scores & atmospheric background soundtrack",
        InitialValue = UITheme.GetMusicVolume(),
        Parent = settView,
        OnChanged = function(val: number)
            UITheme.SetMusicVolume(val)
        end,
    })
    sl3.LayoutOrder = nextSOrder()

    local sl4 = Slider.Create({
        Label = "GAME NATIVE AUDIO",
        Description = "Campfire crackles, wind blowing, crickets & 3D nature sounds",
        InitialValue = UITheme.GetEnvironmentVolume(),
        Parent = settView,
        OnChanged = function(val: number)
            UITheme.SetEnvironmentVolume(val)
        end,
    })
    sl4.LayoutOrder = nextSOrder()

    local sl5 = Slider.Create({
        Label = "LOOK SENSITIVITY",
        Description = "First-person camera mouse sensitivity (0.2x to 3.0x)",
        InitialValue = UITheme.GetMouseSensitivity(),
        MinValue = 0.2,
        MaxValue = 3.0,
        Step = 0.1,
        ValueFormat = function(v: number)
            return string.format("%.1fx", v)
        end,
        Parent = settView,
        OnChanged = function(val: number)
            UITheme.SetMouseSensitivity(val)
        end,
    })
    sl5.LayoutOrder = nextSOrder()

    local tog1 = Toggle.Create({
        Label = "REDUCED MOTION",
        Description = "Limits intense camera shakes, screen blurs & particle speeds",
        InitialValue = false,
        Parent = settView,
        OnChanged = function(enabled: boolean)
        end,
    })
    tog1.LayoutOrder = nextSOrder()

    local tog2 = Toggle.Create({
        Label = "CAMERA HEAD BOBBING",
        Description = "Realistic first-person head bob while walking and sprinting",
        InitialValue = true,
        Parent = settView,
        OnChanged = function(enabled: boolean)
        end,
    })
    tog2.LayoutOrder = nextSOrder()


    ----------------------------------------------------------------------------
    -- VIEW 2: CONTROLS TAB (Keyboard & Input Shortcuts)
    ----------------------------------------------------------------------------
    local ctrlView = tabViews["CONTROLS"]
    local ctrlLayout = Instance.new("UIListLayout")
    ctrlLayout.FillDirection = Enum.FillDirection.Vertical
    ctrlLayout.SortOrder = Enum.SortOrder.LayoutOrder
    ctrlLayout.Padding = UDim.new(0, 10)
    ctrlLayout.Parent = ctrlView

    local cOrder = 0
    local function nextCOrder(): number
        cOrder += 1
        return cOrder
    end

    local ctrlTitle = Instance.new("TextLabel")
    ctrlTitle.Size = UDim2.new(1, 0, 0, 22)
    ctrlTitle.BackgroundTransparency = 1
    ctrlTitle.Font = UITheme.Fonts.Heading
    ctrlTitle.Text = "SURVIVAL CONTROLS"
    ctrlTitle.TextColor3 = UITheme.Colors.TextPrimary
    ctrlTitle.TextSize = 17
    ctrlTitle.TextXAlignment = Enum.TextXAlignment.Left
    ctrlTitle.LayoutOrder = nextCOrder()
    ctrlTitle.Parent = ctrlView

    local ctrlBadge = Instance.new("TextLabel")
    ctrlBadge.Size = UDim2.new(1, 0, 0, 16)
    ctrlBadge.BackgroundTransparency = 1
    ctrlBadge.Font = UITheme.Fonts.Tag
    ctrlBadge.Text = "KEYBOARD SHORTCUTS & INPUT ACTIONS"
    ctrlBadge.TextColor3 = UITheme.Colors.EmberHot
    ctrlBadge.TextSize = 11
    ctrlBadge.TextXAlignment = Enum.TextXAlignment.Left
    ctrlBadge.LayoutOrder = nextCOrder()
    ctrlBadge.Parent = ctrlView

    local function addKeyRow(actionName: string, pcKey: string)
        local row = Instance.new("Frame")
        row.Size = UDim2.new(1, 0, 0, 32)
        row.BackgroundTransparency = 1
        row.LayoutOrder = nextCOrder()
        row.Parent = ctrlView

        local actLbl = Instance.new("TextLabel")
        actLbl.Size = UDim2.new(0.6, 0, 1, 0)
        actLbl.Position = UDim2.fromOffset(4, 0)
        actLbl.BackgroundTransparency = 1
        actLbl.Font = UITheme.Fonts.Body
        actLbl.Text = actionName
        actLbl.TextColor3 = UITheme.Colors.TextPrimary
        actLbl.TextSize = 12
        actLbl.TextXAlignment = Enum.TextXAlignment.Left
        actLbl.Parent = row

        local keyPill = Instance.new("TextLabel")
        keyPill.Size = UDim2.new(0.38, 0, 0, 26)
        keyPill.Position = UDim2.new(1, 0, 0.5, 0)
        keyPill.AnchorPoint = Vector2.new(1, 0.5)
        keyPill.BackgroundColor3 = Color3.fromRGB(16, 14, 18)
        keyPill.BackgroundTransparency = 0.35
        keyPill.Font = UITheme.Fonts.Tag
        keyPill.Text = pcKey
        keyPill.TextColor3 = UITheme.Colors.EmberHot
        keyPill.TextSize = 11
        keyPill.Parent = row

        local pillCorner = Instance.new("UICorner")
        pillCorner.CornerRadius = UDim.new(0, 6)
        pillCorner.Parent = keyPill

        local pillStroke = Instance.new("UIStroke")
        pillStroke.Color = Color3.fromRGB(255, 255, 255)
        pillStroke.Transparency = 0.88
        pillStroke.Thickness = 1
        pillStroke.Parent = keyPill
    end

    addKeyRow("Movement", "[ W ] [ A ] [ S ] [ D ]")
    addKeyRow("Sprint (Consumes Stamina)", "[ Left Shift ]")
    addKeyRow("Jump", "[ Spacebar ]")
    addKeyRow("Select Hotbar Tool", "[ 1 ] [ 2 ] [ 3 ]")
    addKeyRow("Interact / Pick Up / Stoke", "[ E ]")
    addKeyRow("Drop Carried Item", "[ Q ]")
    addKeyRow("Open Backpack Inventory", "[ B ] or [ Tab ]")
    addKeyRow("Hold for Free Cursor / Mouse", "[ Left Alt ]")
    addKeyRow("In-Game Menu / Resume", "[ Esc ] or [ M ]")

    ----------------------------------------------------------------------------
    -- VIEW 3: SURVIVAL TAB (Objectives & Hearth Status)
    ----------------------------------------------------------------------------
    local survView = tabViews["SURVIVAL"]
    local survLayout = Instance.new("UIListLayout")
    survLayout.FillDirection = Enum.FillDirection.Vertical
    survLayout.SortOrder = Enum.SortOrder.LayoutOrder
    survLayout.Padding = UDim.new(0, 14)
    survLayout.Parent = survView

    local suOrder = 0
    local function nextSuOrder(): number
        suOrder += 1
        return suOrder
    end

    local survHeader = Instance.new("TextLabel")
    survHeader.Size = UDim2.new(1, 0, 0, 22)
    survHeader.BackgroundTransparency = 1
    survHeader.Font = UITheme.Fonts.Heading
    survHeader.Text = "CURRENT SURVIVAL OBJECTIVES"
    survHeader.TextColor3 = UITheme.Colors.TextPrimary
    survHeader.TextSize = 17
    survHeader.TextXAlignment = Enum.TextXAlignment.Left
    survHeader.LayoutOrder = nextSuOrder()
    survHeader.Parent = survView

    local survBadge = Instance.new("TextLabel")
    survBadge.Size = UDim2.new(1, 0, 0, 16)
    survBadge.BackgroundTransparency = 1
    survBadge.Font = UITheme.Fonts.Tag
    survBadge.Text = "SECTOR 01: THE LONG NIGHT // PROLOGUE"
    survBadge.TextColor3 = UITheme.Colors.EmberHot
    survBadge.TextSize = 11
    survBadge.TextXAlignment = Enum.TextXAlignment.Left
    survBadge.LayoutOrder = nextSuOrder()
    survBadge.Parent = survView

    local function addCheckItem(title: string, sub: string, isDone: boolean)
        local row = Instance.new("Frame")
        row.Size = UDim2.new(1, 0, 0, 44)
        row.BackgroundTransparency = 1
        row.LayoutOrder = nextSuOrder()
        row.Parent = survView

        local checkIcon = IconPack.CreateIcon(isDone and "check" or "circle", 16, isDone and UITheme.Colors.EmberHot or UITheme.Colors.TextMuted, 0)
        checkIcon.Position = UDim2.fromOffset(4, 4)
        checkIcon.ZIndex = 95
        checkIcon.Parent = row

        local t = Instance.new("TextLabel")
        t.Size = UDim2.new(1, -30, 0, 18)
        t.Position = UDim2.fromOffset(30, 2)
        t.BackgroundTransparency = 1
        t.Font = UITheme.Fonts.Subheading
        t.Text = title
        t.TextColor3 = isDone and UITheme.Colors.TextPrimary or UITheme.Colors.TextSecondary
        t.TextSize = 13
        t.TextXAlignment = Enum.TextXAlignment.Left
        t.Parent = row

        local s = Instance.new("TextLabel")
        s.Size = UDim2.new(1, -30, 0, 14)
        s.Position = UDim2.fromOffset(30, 22)
        s.BackgroundTransparency = 1
        s.Font = UITheme.Fonts.Body
        s.Text = sub
        s.TextColor3 = UITheme.Colors.TextMuted
        s.TextSize = 11
        s.TextXAlignment = Enum.TextXAlignment.Left
        s.Parent = row
    end

    addCheckItem("Locate Campsite Hearth", "Central stone sanctuary pit where fire protects from the dark", true)
    addCheckItem("Gather Wood Logs (Max 5)", "Collect firewood from the camp timber stack or forest piles", false)
    addCheckItem("Stoke Campfire Before 19:00", "Maintain flame health before nightfall arrives and the entity awakens", false)

    local statusStrip = Instance.new("Frame")
    statusStrip.Size = UDim2.new(1, 0, 0, 36)
    statusStrip.BackgroundTransparency = 1
    statusStrip.LayoutOrder = nextSuOrder()
    statusStrip.Parent = survView

    local sFlame = IconPack.CreateIcon("flame", 16, UITheme.Colors.EmberPrimary, 0)
    sFlame.Position = UDim2.fromOffset(4, 10)
    sFlame.Parent = statusStrip

    local sText = Instance.new("TextLabel")
    sText.Size = UDim2.new(1, -30, 1, 0)
    sText.Position = UDim2.fromOffset(30, 0)
    sText.BackgroundTransparency = 1
    sText.Font = UITheme.Fonts.Tag
    sText.Text = "CAMPFIRE SANCTUARY: BURNING  •  NIGHTFALL: 19:00 APPROACHING"
    sText.TextColor3 = UITheme.Colors.EmberHot
    sText.TextSize = 11
    sText.TextXAlignment = Enum.TextXAlignment.Left
    sText.Parent = statusStrip

    ----------------------------------------------------------------------------
    -- VIEW 4: QUESTS TAB (Active Objectives — Coming Soon)
    ----------------------------------------------------------------------------
    local questView = tabViews["QUESTS"]
    local questLayout = Instance.new("UIListLayout")
    questLayout.FillDirection = Enum.FillDirection.Vertical
    questLayout.SortOrder = Enum.SortOrder.LayoutOrder
    questLayout.Padding = UDim.new(0, 14)
    questLayout.Parent = questView

    local questTitle = Instance.new("TextLabel")
    questTitle.Size = UDim2.new(1, 0, 0, 22)
    questTitle.BackgroundTransparency = 1
    questTitle.Font = UITheme.Fonts.Heading
    questTitle.Text = "ACTIVE QUESTS"
    questTitle.TextColor3 = UITheme.Colors.TextPrimary
    questTitle.TextSize = 17
    questTitle.TextXAlignment = Enum.TextXAlignment.Left
    questTitle.LayoutOrder = 1
    questTitle.Parent = questView

    local questBadge = Instance.new("TextLabel")
    questBadge.Size = UDim2.new(1, 0, 0, 16)
    questBadge.BackgroundTransparency = 1
    questBadge.Font = UITheme.Fonts.Tag
    questBadge.Text = "QUEST MANAGER — COMING SOON"
    questBadge.TextColor3 = UITheme.Colors.EmberHot
    questBadge.TextSize = 11
    questBadge.TextXAlignment = Enum.TextXAlignment.Left
    questBadge.LayoutOrder = 2
    questBadge.Parent = questView

    local questPlaceholder = Instance.new("TextLabel")
    questPlaceholder.Size = UDim2.new(1, 0, 0, 80)
    questPlaceholder.BackgroundTransparency = 1
    questPlaceholder.Font = UITheme.Fonts.Body
    questPlaceholder.Text = "Quest tracking and objective management is being built.\nVisit the Survival tab to see current objectives."
    questPlaceholder.TextColor3 = UITheme.Colors.TextMuted
    questPlaceholder.TextSize = 12
    questPlaceholder.TextWrapped = true
    questPlaceholder.TextXAlignment = Enum.TextXAlignment.Left
    questPlaceholder.LayoutOrder = 3
    questPlaceholder.Parent = questView

    ----------------------------------------------------------------------------
    -- VISIBILITY & TRANSITION CONTROLLERS
    ----------------------------------------------------------------------------
    local function openMenu()
        if isOpen or isTransitioning then return end
        isOpen = true
        isTransitioning = true

        backdrop.Visible = true
        switchTab("SETTINGS")
        AudioManager.Play("Click")

        local tween = TweenService:Create(backdrop, UITheme.Tweens.Fast, { BackgroundTransparency = 0.35 })
        tween.Completed:Connect(function()
            isTransitioning = false
        end)
        tween:Play()
    end

    local function closeMenu()
        if not isOpen or isTransitioning then return end
        isOpen = false
        isTransitioning = true

        AudioManager.Play("Click")
        if callbacks.OnClose then
            callbacks.OnClose()
        end

        local fadeTween = TweenService:Create(backdrop, UITheme.Tweens.Fast, { BackgroundTransparency = 1 })
        fadeTween.Completed:Connect(function()
            if not isOpen then
                backdrop.Visible = false
            end
            isTransitioning = false
        end)
        fadeTween:Play()
    end

    backdrop.Activated:Connect(function()
        closeMenu()
        if callbacks.OnResume then
            callbacks.OnResume()
        end
    end)

    return {
        Container = backdrop,
        Open = openMenu,
        Close = closeMenu,
        IsOpen = function()
            return isOpen
        end,
        Destroy = function()
            backdrop:Destroy()
        end,
    }
end

return SystemMenu
