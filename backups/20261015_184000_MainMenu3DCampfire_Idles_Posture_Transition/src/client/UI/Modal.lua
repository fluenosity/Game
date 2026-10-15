--!strict
--[[
    UI/Modal.lua
    Production-Grade Glassmorphic Modal Dialog Container
    "Don't Let the Fire Die" — Fluenosity Studio

    Features:
    - Fullscreen frosted backdrop
    - Responsive centered acrylic glass container with specular hairline borders
    - Header with Title, Subtitle, and Lucide "X" Close Icon Button
    - Integrated with ModalManager for FPP cursor lock/camera freeze safety
    - Smooth scale & fade tween lifecycles
]]

local TweenService = game:GetService("TweenService")
local UITheme = require(script.Parent:WaitForChild("UITheme"))
local IconButton = require(script.Parent:WaitForChild("IconButton"))

local Modal = {}

export type ModalConfig = {
    Id: string,
    Title: string,
    Subtitle: string?,
    Width: (number | UDim)?,
    Height: (number | UDim)?,
    MaxWidth: number?,
    MaxHeight: number?,
    Parent: Instance,
    ZIndex: number?,
    OnClose: (() -> ())?,
    OnOpen: (() -> ())?,
}

export type ModalInstance = {
    Backdrop: Frame,
    Card: Frame,
    Content: Frame,
    Header: Frame,
    Open: () -> (),
    Close: () -> (),
    Toggle: () -> (),
    IsOpen: () -> boolean,
    Destroy: () -> (),
}

function Modal.Create(config: ModalConfig): ModalInstance
    local isOpen = false

    -- Fullscreen backdrop
    local backdrop = Instance.new("Frame")
    backdrop.Name = "ModalBackdrop_" .. config.Id
    backdrop.Size = UDim2.fromScale(1, 1)
    backdrop.Position = UDim2.fromScale(0, 0)
    backdrop.BackgroundColor3 = UITheme.Colors.GlassBackdrop
    backdrop.BackgroundTransparency = 1
    backdrop.BorderSizePixel = 0
    backdrop.Visible = false
    backdrop.ZIndex = config.ZIndex or 50
    backdrop.Parent = config.Parent

    -- Centered glass card
    local cardWidth = config.Width or UDim.new(0.52, 0)
    local cardHeight = config.Height or UDim.new(0.65, 0)

    local card = Instance.new("Frame")
    card.Name = "ModalCard"
    card.AnchorPoint = Vector2.new(0.5, 0.5)
    card.Position = UDim2.fromScale(0.5, 0.5)
    card.Size = UDim2.new(cardWidth, cardHeight)
    card.BackgroundColor3 = UITheme.Colors.GlassModal
    card.BackgroundTransparency = UITheme.Transparency.ModalSurface
    card.BorderSizePixel = 0
    card.ZIndex = backdrop.ZIndex + 1
    card.Parent = backdrop

    -- Size constraint for cross-screen responsiveness
    local sizeConstraint = Instance.new("UISizeConstraint")
    sizeConstraint.MinSize = Vector2.new(320, 240)
    sizeConstraint.MaxSize = Vector2.new(config.MaxWidth or 680, config.MaxHeight or 600)
    sizeConstraint.Parent = card

    UITheme.ApplyGlass(card, {
        CornerRadius = 14,
        StrokeColor = UITheme.Colors.BorderGlass,
        StrokeThickness = 1.2,
    })

    -- Inner Card Padding
    local cardPadding = Instance.new("UIPadding")
    cardPadding.PaddingTop = UDim.new(0, 18)
    cardPadding.PaddingBottom = UDim.new(0, 18)
    cardPadding.PaddingLeft = UDim.new(0, 22)
    cardPadding.PaddingRight = UDim.new(0, 22)
    cardPadding.Parent = card

    -- Vertical Card Layout
    local cardLayout = Instance.new("UIListLayout")
    cardLayout.FillDirection = Enum.FillDirection.Vertical
    cardLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    cardLayout.VerticalAlignment = Enum.VerticalAlignment.Top
    cardLayout.Padding = UDim.new(0, 14)
    cardLayout.SortOrder = Enum.SortOrder.LayoutOrder
    cardLayout.Parent = card

    -- Header container (Title + Subtitle on left, "X" close on right)
    local header = Instance.new("Frame")
    header.Name = "Header"
    header.Size = UDim2.new(1, 0, 0, config.Subtitle and 44 or 34)
    header.BackgroundTransparency = 1
    header.LayoutOrder = 1
    header.ZIndex = card.ZIndex + 1
    header.Parent = card

    local headerStack = Instance.new("Frame")
    headerStack.Name = "HeaderStack"
    headerStack.Size = UDim2.new(1, -44, 1, 0)
    headerStack.BackgroundTransparency = 1
    headerStack.ZIndex = header.ZIndex
    headerStack.Parent = header

    local stackLayout = Instance.new("UIListLayout")
    stackLayout.FillDirection = Enum.FillDirection.Vertical
    stackLayout.VerticalAlignment = Enum.VerticalAlignment.Center
    stackLayout.Padding = UDim.new(0, 3)
    stackLayout.Parent = headerStack

    local titleLabel = Instance.new("TextLabel")
    titleLabel.Name = "Title"
    titleLabel.Size = UDim2.new(1, 0, 0, UITheme.FontSizes.Title)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Font = UITheme.Fonts.Title
    titleLabel.Text = config.Title
    titleLabel.TextColor3 = UITheme.Colors.TextPrimary
    titleLabel.TextSize = UITheme.FontSizes.Title
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.ZIndex = header.ZIndex + 1
    titleLabel.Parent = headerStack

    if config.Subtitle then
        local subLabel = Instance.new("TextLabel")
        subLabel.Name = "Subtitle"
        subLabel.Size = UDim2.new(1, 0, 0, UITheme.FontSizes.Caption)
        subLabel.BackgroundTransparency = 1
        subLabel.Font = UITheme.Fonts.Body
        subLabel.Text = config.Subtitle
        subLabel.TextColor3 = UITheme.Colors.TextSecondary
        subLabel.TextSize = UITheme.FontSizes.Caption
        subLabel.TextXAlignment = Enum.TextXAlignment.Left
        subLabel.ZIndex = header.ZIndex + 1
        subLabel.Parent = headerStack
    end

    -- Top-Right Lucide "X" Close Icon Button
    local closeBtn = IconButton.Create({
        IconName = "x",
        IconSize = 14,
        Size = 32,
        IsCloseButton = true,
        Position = UDim2.new(1, 0, 0.5, 0),
        AnchorPoint = Vector2.new(1, 0.5),
        ZIndex = header.ZIndex + 2,
        Parent = header,
        OnClick = function()
            -- Will trigger modal:Close()
        end,
    })

    -- Hairline Divider below Header
    local divider = Instance.new("Frame")
    divider.Name = "Divider"
    divider.Size = UDim2.new(1, 0, 0, 1)
    divider.BackgroundColor3 = UITheme.Colors.BorderSubtle
    divider.BackgroundTransparency = 0.55
    divider.BorderSizePixel = 0
    divider.LayoutOrder = 2
    divider.ZIndex = card.ZIndex + 1
    divider.Parent = card

    -- Content Container (fills remaining vertical space)
    local content = Instance.new("Frame")
    content.Name = "Content"
    content.Size = UDim2.new(1, 0, 1, -(header.Size.Y.Offset + divider.Size.Y.Offset + 28))
    content.BackgroundTransparency = 1
    content.LayoutOrder = 3
    content.ZIndex = card.ZIndex + 1
    content.Parent = card

    -- Animation scale & position handles
    local cardScale = Instance.new("UIScale")
    cardScale.Scale = 0.95
    cardScale.Parent = card

    -- Forward declaration of modal object
    local modalObj: ModalInstance = {
        Backdrop = backdrop,
        Card = card,
        Content = content,
        Header = header,
        Open = function() end,
        Close = function() end,
        Toggle = function() end,
        IsOpen = function() return isOpen end,
        Destroy = function()
            backdrop:Destroy()
        end,
    }

    local function openModal()
        if isOpen then return end
        isOpen = true
        backdrop.Visible = true

        -- Audio cue
        UITheme.PlayClick()

        -- Inform ModalManager (frees cursor, freezes camera look)
        pcall(function()
            local ModalManager = require(script.Parent.Parent:WaitForChild("ModalManager"))
            ModalManager.SetOpen(config.Id, true)
        end)

        -- Animate backdrop fade and card zoom
        TweenService:Create(backdrop, UITheme.Tweens.Fast, {
            BackgroundTransparency = UITheme.Transparency.ModalBackdrop,
        }):Play()

        cardScale.Scale = 0.95
        card.BackgroundTransparency = 1
        TweenService:Create(cardScale, UITheme.Tweens.Modal, { Scale = 1.0 }):Play()
        TweenService:Create(card, UITheme.Tweens.Fast, {
            BackgroundTransparency = UITheme.Transparency.ModalSurface,
        }):Play()

        if config.OnOpen then
            config.OnOpen()
        end
    end

    local function closeModal()
        if not isOpen then return end
        isOpen = false

        -- Audio cue
        UITheme.PlayClose()

        -- Inform ModalManager (restores FPP locked cursor and reticle)
        pcall(function()
            local ModalManager = require(script.Parent.Parent:WaitForChild("ModalManager"))
            ModalManager.SetOpen(config.Id, false)
        end)

        TweenService:Create(cardScale, UITheme.Tweens.Fast, { Scale = 0.96 }):Play()
        TweenService:Create(card, UITheme.Tweens.Fast, { BackgroundTransparency = 1 }):Play()

        local fadeTween = TweenService:Create(backdrop, UITheme.Tweens.Fast, { BackgroundTransparency = 1 })
        fadeTween:Play()
        fadeTween.Completed:Once(function()
            if not isOpen then
                backdrop.Visible = false
            end
        end)

        if config.OnClose then
            config.OnClose()
        end
    end

    -- Wire close button and backdrop click-off
    closeBtn.Activated:Connect(closeModal)

    -- Click outside modal card to close
    backdrop.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            local mousePos = input.Position
            local cardPos = card.AbsolutePosition
            local cardSize = card.AbsoluteSize
            local inside = (mousePos.X >= cardPos.X and mousePos.X <= cardPos.X + cardSize.X) and
                           (mousePos.Y >= cardPos.Y and mousePos.Y <= cardPos.Y + cardSize.Y)
            if not inside then
                closeModal()
            end
        end
    end)

    modalObj.Open = openModal
    modalObj.Close = closeModal
    modalObj.Toggle = function()
        if isOpen then closeModal() else openModal() end
    end

    return modalObj
end

return Modal
