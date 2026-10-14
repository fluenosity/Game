--!strict
--[[
    UI/DialogBox.lua
    Modular Glassmorphic NPC Dialogue & Story Box Component
    "Don't Let the Fire Die" — Fluenosity Studio
]]

local TweenService = game:GetService("TweenService")
local UITheme = require(script.Parent:WaitForChild("UITheme"))
local Button = require(script.Parent:WaitForChild("Button"))
local IconButton = require(script.Parent:WaitForChild("IconButton"))

export type DialogOption = {
    Text: string,
    Subtext: string?,
    Variant: string?,
    OnSelect: () -> (),
}

export type DialogBoxConfig = {
    SpeakerName: string,
    SpeakerRole: string?,
    DialogueText: string,
    Options: { DialogOption },
    Parent: Instance,
    ZIndex: number?,
    OnClose: (() -> ())?,
}

export type DialogBoxInstance = {
    Frame: Frame,
    SetDialogue: (speaker: string, role: string?, text: string, options: { DialogOption }) -> (),
    Open: () -> (),
    Close: () -> (),
    Destroy: () -> (),
}

local DialogBox = {}

function DialogBox.Create(config: DialogBoxConfig): DialogBoxInstance
    local container = Instance.new("Frame")
    container.Name = "DialogBox_" .. config.SpeakerName:gsub("%s+", "")
    container.AnchorPoint = Vector2.new(0.5, 1)
    container.Position = UDim2.new(0.5, 0, 1, -28)
    container.Size = UDim2.new(0.68, 0, 0, 180)
    container.BackgroundColor3 = UITheme.Colors.GlassModal
    container.BackgroundTransparency = UITheme.Transparency.ModalSurface
    container.BorderSizePixel = 0
    container.ZIndex = config.ZIndex or 40
    container.Visible = false

    local constraint = Instance.new("UISizeConstraint")
    constraint.MinWidth = 360
    constraint.MaxWidth = 780
    constraint.MinHeight = 160
    constraint.MaxHeight = 260
    constraint.Parent = container

    UITheme.ApplyGlass(container, {
        CornerRadius = 14,
        StrokeColor = UITheme.Colors.BorderGlass,
        StrokeThickness = 1.4,
    })

    local pad = Instance.new("UIPadding")
    pad.PaddingTop = UDim.new(0, 16)
    pad.PaddingBottom = UDim.new(0, 16)
    pad.PaddingLeft = UDim.new(0, 20)
    pad.PaddingRight = UDim.new(0, 20)
    pad.Parent = container

    local vLayout = Instance.new("UIListLayout")
    vLayout.FillDirection = Enum.FillDirection.Vertical
    vLayout.Padding = UDim.new(0, 10)
    vLayout.Parent = container

    -- Top Header (Speaker Name, Role, Close Button)
    local header = Instance.new("Frame")
    header.Name = "Header"
    header.Size = UDim2.new(1, 0, 0, 24)
    header.BackgroundTransparency = 1
    header.Parent = container

    local nameStack = Instance.new("Frame")
    nameStack.Size = UDim2.new(1, -36, 1, 0)
    nameStack.BackgroundTransparency = 1
    nameStack.Parent = header

    local hLayout = Instance.new("UIListLayout")
    hLayout.FillDirection = Enum.FillDirection.Horizontal
    hLayout.VerticalAlignment = Enum.VerticalAlignment.Center
    hLayout.Padding = UDim.new(0, 10)
    hLayout.Parent = nameStack

    local nameLabel = Instance.new("TextLabel")
    nameLabel.Name = "SpeakerName"
    nameLabel.Size = UDim2.new(0, 0, 1, 0)
    nameLabel.AutomaticSize = Enum.AutomaticSize.X
    nameLabel.BackgroundTransparency = 1
    nameLabel.Font = UITheme.Fonts.Heading
    nameLabel.Text = config.SpeakerName
    nameLabel.TextColor3 = UITheme.Colors.EmberHot
    nameLabel.TextSize = 16
    nameLabel.Parent = nameStack

    if config.SpeakerRole then
        local roleBadge = Instance.new("TextLabel")
        roleBadge.Name = "SpeakerRole"
        roleBadge.Size = UDim2.new(0, 0, 1, 0)
        roleBadge.AutomaticSize = Enum.AutomaticSize.X
        roleBadge.BackgroundTransparency = 1
        roleBadge.Font = UITheme.Fonts.Caption
        roleBadge.Text = "[" .. config.SpeakerRole:upper() .. "]"
        roleBadge.TextColor3 = UITheme.Colors.TextMuted
        roleBadge.TextSize = 11
        roleBadge.Parent = nameStack
    end

    -- Close "X" button
    local closeBtn = IconButton.Create({
        IconName = "x",
        IconSize = 13,
        Size = 24,
        IsCloseButton = true,
        Position = UDim2.new(1, 0, 0.5, 0),
        AnchorPoint = Vector2.new(1, 0.5),
        Parent = header,
    })

    -- Dialogue Text Area
    local bodyLabel = Instance.new("TextLabel")
    bodyLabel.Name = "DialogueText"
    bodyLabel.Size = UDim2.new(1, 0, 0, 52)
    bodyLabel.BackgroundTransparency = 1
    bodyLabel.Font = UITheme.Fonts.Body
    bodyLabel.Text = config.DialogueText
    bodyLabel.TextColor3 = UITheme.Colors.TextPrimary
    bodyLabel.TextSize = 14
    bodyLabel.TextWrapped = true
    bodyLabel.TextXAlignment = Enum.TextXAlignment.Left
    bodyLabel.TextYAlignment = Enum.TextYAlignment.Top
    bodyLabel.Parent = container

    -- Response Options Button Grid / Row
    local optionsRow = Instance.new("Frame")
    optionsRow.Name = "OptionsRow"
    optionsRow.Size = UDim2.new(1, 0, 0, 42)
    optionsRow.BackgroundTransparency = 1
    optionsRow.Parent = container

    local optLayout = Instance.new("UIListLayout")
    optLayout.FillDirection = Enum.FillDirection.Horizontal
    optLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
    optLayout.Padding = UDim.new(0, 10)
    optLayout.Parent = optionsRow

    local function populateOptions(options: { DialogOption })
        for _, child in ipairs(optionsRow:GetChildren()) do
            if child:IsA("GuiObject") and not child:IsA("UIListLayout") then
                child:Destroy()
            end
        end

        for _, opt in ipairs(options) do
            Button.Create({
                Text = opt.Text,
                Subtext = opt.Subtext,
                Variant = (opt.Variant == "Primary") and "Primary" or "Secondary",
                Size = UDim2.new(0, 0, 0, 36),
                Parent = optionsRow,
                OnClick = opt.OnSelect,
            })
        end
    end

    populateOptions(config.Options)

    local function openDialog()
        container.Visible = true
        container.Position = UDim2.new(0.5, 0, 1, -16)
        container.BackgroundTransparency = 1
        TweenService:Create(container, UITheme.Tweens.Fast, {
            Position = UDim2.new(0.5, 0, 1, -28),
            BackgroundTransparency = UITheme.Transparency.ModalSurface,
        }):Play()

        pcall(function()
            local ModalManager = require(script.Parent.Parent:WaitForChild("ModalManager"))
            ModalManager.SetOpen("Dialog_" .. config.SpeakerName, true)
        end)
    end

    local function closeDialog()
        local t = TweenService:Create(container, UITheme.Tweens.Fast, {
            Position = UDim2.new(0.5, 0, 1, -16),
            BackgroundTransparency = 1,
        })
        t:Play()
        t.Completed:Once(function()
            container.Visible = false
        end)

        pcall(function()
            local ModalManager = require(script.Parent.Parent:WaitForChild("ModalManager"))
            ModalManager.SetOpen("Dialog_" .. config.SpeakerName, false)
        end)

        if config.OnClose then
            config.OnClose()
        end
    end

    closeBtn.Activated:Connect(closeDialog)

    local dialogInstance: DialogBoxInstance = {
        Frame = container,
        SetDialogue = function(speaker: string, role: string?, text: string, options: { DialogOption })
            nameLabel.Text = speaker
            bodyLabel.Text = text
            populateOptions(options)
        end,
        Open = openDialog,
        Close = closeDialog,
        Destroy = function()
            container:Destroy()
        end,
    }

    if config.Parent then
        container.Parent = config.Parent
    end

    return dialogInstance
end

return DialogBox
