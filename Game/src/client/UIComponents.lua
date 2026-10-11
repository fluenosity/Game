--!strict
--[[
    UIComponents.lua
    Production-grade, modular, responsive UI component library for
    "Don't Let the Fire Die". Developed for Fluenosity Studio.
    
    Includes:
    - Interactive Dual-line Buttons with hover glow & indicator pills
    - Cinematic Modal Dialogs with smooth spring-scale animations
    - Interactive Audio & Value Sliders with drag/step control
    - Tactile Animated Toggle Switches
    - Hairline Gradient Dividers & Metadata Badges
]]

local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local UITheme = require(script.Parent:WaitForChild("UITheme"))

local UIComponents = {}

--------------------------------------------------------------------------------
-- 1. PRODUCTION-GRADE BUTTON COMPONENT
--------------------------------------------------------------------------------
export type ButtonConfig = {
    Text: string,
    Subtext: string?,
    Width: number?,
    Height: number?,
    IsPrimary: boolean?,
    Parent: Instance?,
    OnClick: () -> (),
}

function UIComponents.CreateButton(config: ButtonConfig): TextButton
    local isPrimary = config.IsPrimary or false
    local width = config.Width or 270
    local height = config.Height or 54

    local button = Instance.new("TextButton")
    button.Name = "Btn_" .. config.Text:gsub("%s+", "")
    button.Size = UDim2.new(0, width, 0, height)
    button.BackgroundColor3 = isPrimary and UITheme.Colors.ButtonPrimaryBg or UITheme.Colors.ButtonSecondaryBg
    button.AutoButtonColor = false
    button.BorderSizePixel = 0
    button.Text = ""
    button.ZIndex = 10

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = button

    local stroke = Instance.new("UIStroke")
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    stroke.Color = isPrimary and UITheme.Colors.ButtonPrimaryBorder or UITheme.Colors.ButtonSecondaryBorder
    stroke.Thickness = isPrimary and 1.4 or 1.0
    stroke.Transparency = 0.1
    stroke.Parent = button

    -- Left Ember Glow Indicator Bar
    local indicator = Instance.new("Frame")
    indicator.Name = "Indicator"
    indicator.Size = UDim2.new(0, 3, 0.38, 0)
    indicator.Position = UDim2.new(0, 10, 0.5, 0)
    indicator.AnchorPoint = Vector2.new(0, 0.5)
    indicator.BackgroundColor3 = isPrimary and UITheme.Colors.EmberPrimary or UITheme.Colors.BorderSubtle
    indicator.BorderSizePixel = 0
    indicator.ZIndex = 11

    local indCorner = Instance.new("UICorner")
    indCorner.CornerRadius = UDim.new(1, 0)
    indCorner.Parent = indicator
    indicator.Parent = button

    -- Text Layout Container
    local textContainer = Instance.new("Frame")
    textContainer.Name = "TextContainer"
    textContainer.Size = UDim2.new(1, -36, 1, 0)
    textContainer.Position = UDim2.new(0, 24, 0.5, 0)
    textContainer.AnchorPoint = Vector2.new(0, 0.5)
    textContainer.BackgroundTransparency = 1
    textContainer.ZIndex = 11
    textContainer.Parent = button

    local textLayout = Instance.new("UIListLayout")
    textLayout.FillDirection = Enum.FillDirection.Vertical
    textLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
    textLayout.VerticalAlignment = Enum.VerticalAlignment.Center
    textLayout.Padding = UDim.new(0, 2)
    textLayout.Parent = textContainer

    -- Primary Text Label
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Name = "Title"
    titleLabel.Size = UDim2.new(1, 0, 0, 20)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Font = UITheme.Fonts.Button
    titleLabel.Text = config.Text
    titleLabel.TextColor3 = UITheme.Colors.TextPrimary
    titleLabel.TextSize = 15
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.ZIndex = 12
    titleLabel.Parent = textContainer

    -- Subtext Label (if provided)
    if config.Subtext then
        local subLabel = Instance.new("TextLabel")
        subLabel.Name = "Subtext"
        subLabel.Size = UDim2.new(1, 0, 0, 13)
        subLabel.BackgroundTransparency = 1
        subLabel.Font = UITheme.Fonts.ButtonSub
        subLabel.Text = config.Subtext
        subLabel.TextColor3 = isPrimary and UITheme.Colors.EmberHot or UITheme.Colors.TextMuted
        subLabel.TextSize = 10
        subLabel.TextXAlignment = Enum.TextXAlignment.Left
        subLabel.ZIndex = 12
        subLabel.Parent = textContainer
    end

    -- Interactive States & Animations
    local normalBg = isPrimary and UITheme.Colors.ButtonPrimaryBg or UITheme.Colors.ButtonSecondaryBg
    local hoverBg = isPrimary and UITheme.Colors.ButtonPrimaryHover or UITheme.Colors.ButtonSecondaryHover
    local normalBorder = isPrimary and UITheme.Colors.ButtonPrimaryBorder or UITheme.Colors.ButtonSecondaryBorder
    local hoverBorder = UITheme.Colors.BorderActive

    button.MouseEnter:Connect(function()
        TweenService:Create(button, UITheme.Tweens.Fast, {
            BackgroundColor3 = hoverBg,
        }):Play()
        TweenService:Create(stroke, UITheme.Tweens.Fast, {
            Color = hoverBorder,
            Thickness = 1.6,
        }):Play()
        TweenService:Create(indicator, UITheme.Tweens.Fast, {
            Size = UDim2.new(0, 4, 0.72, 0),
            BackgroundColor3 = UITheme.Colors.EmberHot,
        }):Play()
        TweenService:Create(titleLabel, UITheme.Tweens.Fast, {
            TextColor3 = UITheme.Colors.EmberHot,
        }):Play()
    end)

    button.MouseLeave:Connect(function()
        TweenService:Create(button, UITheme.Tweens.Fast, {
            BackgroundColor3 = normalBg,
        }):Play()
        TweenService:Create(stroke, UITheme.Tweens.Fast, {
            Color = normalBorder,
            Thickness = isPrimary and 1.4 or 1.0,
        }):Play()
        TweenService:Create(indicator, UITheme.Tweens.Fast, {
            Size = UDim2.new(0, 3, 0.38, 0),
            BackgroundColor3 = isPrimary and UITheme.Colors.EmberPrimary or UITheme.Colors.BorderSubtle,
        }):Play()
        TweenService:Create(titleLabel, UITheme.Tweens.Fast, {
            TextColor3 = UITheme.Colors.TextPrimary,
        }):Play()
    end)

    button.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            TweenService:Create(button, UITheme.Tweens.Instant, {
                BackgroundColor3 = UITheme.Colors.ButtonPressed,
            }):Play()
        end
    end)

    button.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            TweenService:Create(button, UITheme.Tweens.Fast, {
                BackgroundColor3 = hoverBg,
            }):Play()
        end
    end)

    button.Activated:Connect(function()
        config.OnClick()
    end)

    if config.Parent then
        button.Parent = config.Parent
    end

    return button
end

--------------------------------------------------------------------------------
-- 2. CINEMATIC MODAL COMPONENT
--------------------------------------------------------------------------------
export type ModalConfig = {
    Title: string,
    CategoryTag: string?,
    Width: number?,
    Height: number?,
    Parent: Instance,
    OnClose: (() -> ())?,
}

export type ModalInstance = {
    Backdrop: TextButton,
    Card: Frame,
    Content: Frame,
    Open: () -> (),
    Close: () -> (),
}

function UIComponents.CreateModal(config: ModalConfig): ModalInstance
    local width = config.Width or 430
    local height = config.Height or 400

    -- Fullscreen Dismissible Dim Backdrop
    local backdrop = Instance.new("TextButton")
    backdrop.Name = "ModalBackdrop_" .. config.Title:gsub("%s+", "")
    backdrop.Size = UDim2.fromScale(1, 1)
    backdrop.Position = UDim2.fromScale(0, 0)
    backdrop.BackgroundColor3 = UITheme.Colors.PureBlack
    backdrop.BackgroundTransparency = 1
    backdrop.AutoButtonColor = false
    backdrop.Text = ""
    backdrop.Visible = false
    backdrop.ZIndex = 30
    backdrop.Parent = config.Parent

    -- Modal Surface Card
    local card = Instance.new("Frame")
    card.Name = "ModalCard"
    card.Size = UDim2.new(0, width, 0, height)
    card.Position = UDim2.fromScale(0.5, 0.52)
    card.AnchorPoint = Vector2.new(0.5, 0.5)
    card.BackgroundColor3 = UITheme.Colors.SurfaceElevated
    card.BorderSizePixel = 0
    card.Visible = false
    card.ZIndex = 32
    card.Parent = backdrop

    local cardCorner = Instance.new("UICorner")
    cardCorner.CornerRadius = UDim.new(0, 12)
    cardCorner.Parent = card

    local cardStroke = Instance.new("UIStroke")
    cardStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    cardStroke.Color = UITheme.Colors.BorderSubtle
    cardStroke.Thickness = 1.4
    cardStroke.Parent = card

    local cardPadding = Instance.new("UIPadding")
    cardPadding.PaddingTop = UDim.new(0, 22)
    cardPadding.PaddingBottom = UDim.new(0, 22)
    cardPadding.PaddingLeft = UDim.new(0, 26)
    cardPadding.PaddingRight = UDim.new(0, 26)
    cardPadding.Parent = card

    -- Header Container
    local header = Instance.new("Frame")
    header.Name = "Header"
    header.Size = UDim2.new(1, 0, 0, 48)
    header.BackgroundTransparency = 1
    header.ZIndex = 33
    header.Parent = card

    if config.CategoryTag then
        local tagLabel = Instance.new("TextLabel")
        tagLabel.Name = "CategoryTag"
        tagLabel.Size = UDim2.new(0.8, 0, 0, 12)
        tagLabel.Position = UDim2.new(0, 0, 0, 0)
        tagLabel.BackgroundTransparency = 1
        tagLabel.Font = UITheme.Fonts.Tag
        tagLabel.Text = config.CategoryTag
        tagLabel.TextColor3 = UITheme.Colors.EmberHot
        tagLabel.TextSize = 10
        tagLabel.TextXAlignment = Enum.TextXAlignment.Left
        tagLabel.ZIndex = 34
        tagLabel.Parent = header
    end

    local titleLabel = Instance.new("TextLabel")
    titleLabel.Name = "Title"
    titleLabel.Size = UDim2.new(0.8, 0, 0, 26)
    titleLabel.Position = UDim2.new(0, 0, 0, config.CategoryTag and 14 or 6)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Font = UITheme.Fonts.Heading
    titleLabel.Text = config.Title
    titleLabel.TextColor3 = UITheme.Colors.TextPrimary
    titleLabel.TextSize = 22
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.ZIndex = 34
    titleLabel.Parent = header

    -- Close Button (X in corner)
    local btnClose = Instance.new("TextButton")
    btnClose.Name = "BtnClose"
    btnClose.Size = UDim2.fromOffset(30, 30)
    btnClose.Position = UDim2.fromScale(1, 0)
    btnClose.AnchorPoint = Vector2.new(1, 0)
    btnClose.BackgroundColor3 = UITheme.Colors.Surface
    btnClose.AutoButtonColor = false
    btnClose.Font = UITheme.Fonts.Heading
    btnClose.Text = "×"
    btnClose.TextColor3 = UITheme.Colors.TextMuted
    btnClose.TextSize = 20
    btnClose.ZIndex = 35
    btnClose.Parent = header

    local closeCorner = Instance.new("UICorner")
    closeCorner.CornerRadius = UDim.new(0, 6)
    closeCorner.Parent = btnClose

    btnClose.MouseEnter:Connect(function()
        TweenService:Create(btnClose, UITheme.Tweens.Fast, {
            TextColor3 = UITheme.Colors.EmberHot,
            BackgroundColor3 = UITheme.Colors.SurfaceHighlight,
        }):Play()
    end)
    btnClose.MouseLeave:Connect(function()
        TweenService:Create(btnClose, UITheme.Tweens.Fast, {
            TextColor3 = UITheme.Colors.TextMuted,
            BackgroundColor3 = UITheme.Colors.Surface,
        }):Play()
    end)

    -- Divider Line with glowing ember accent
    local divider = Instance.new("Frame")
    divider.Name = "Divider"
    divider.Size = UDim2.new(1, 0, 0, 1)
    divider.Position = UDim2.new(0, 0, 0, 52)
    divider.BackgroundColor3 = UITheme.Colors.BorderHairline
    divider.BorderSizePixel = 0
    divider.ZIndex = 33
    divider.Parent = card

    -- Content Body Container
    local content = Instance.new("Frame")
    content.Name = "Content"
    content.Size = UDim2.new(1, 0, 1, -114)
    content.Position = UDim2.new(0, 0, 0, 62)
    content.BackgroundTransparency = 1
    content.ZIndex = 33
    content.Parent = card

    -- Footer / Bottom Action Row
    local footer = Instance.new("Frame")
    footer.Name = "Footer"
    footer.Size = UDim2.new(1, 0, 0, 42)
    footer.Position = UDim2.fromScale(0, 1)
    footer.AnchorPoint = Vector2.new(0, 1)
    footer.BackgroundTransparency = 1
    footer.ZIndex = 33
    footer.Parent = card

    local isBusy = false

    local function closeModal()
        if isBusy then return end
        isBusy = true
        local tweenCard = TweenService:Create(card, UITheme.Tweens.Fast, {
            Position = UDim2.fromScale(0.5, 0.52),
        })
        TweenService:Create(backdrop, UITheme.Tweens.Fast, {
            BackgroundTransparency = 1,
        }):Play()

        tweenCard.Completed:Connect(function()
            card.Visible = false
            backdrop.Visible = false
            isBusy = false
            if config.OnClose then
                config.OnClose()
            end
        end)
        tweenCard:Play()
    end

    local function openModal()
        if isBusy then return end
        isBusy = true
        backdrop.Visible = true
        card.Visible = true
        card.Position = UDim2.fromScale(0.5, 0.53)

        TweenService:Create(backdrop, UITheme.Tweens.Fast, {
            BackgroundTransparency = 0.65,
        }):Play()

        local tweenCard = TweenService:Create(card, UITheme.Tweens.Normal, {
            Position = UDim2.fromScale(0.5, 0.5),
        })
        tweenCard.Completed:Connect(function()
            isBusy = false
        end)
        tweenCard:Play()
    end

    btnClose.Activated:Connect(closeModal)
    backdrop.Activated:Connect(closeModal)

    -- Back button in footer
    local btnBack = UIComponents.CreateButton({
        Text = "BACK",
        Subtext = "RETURN TO MENU",
        Width = width - 52,
        Height = 40,
        IsPrimary = false,
        Parent = footer,
        OnClick = closeModal,
    })
    btnBack.Size = UDim2.new(1, 0, 1, 0)
    btnBack.ZIndex = 35

    return {
        Backdrop = backdrop,
        Card = card,
        Content = content,
        Open = openModal,
        Close = closeModal,
    }
end

--------------------------------------------------------------------------------
-- 3. INTERACTIVE SLIDER COMPONENT
--------------------------------------------------------------------------------
export type SliderConfig = {
    Label: string,
    Description: string?,
    InitialValue: number,
    Parent: Instance,
    OnChanged: (value: number) -> (),
}

function UIComponents.CreateSlider(config: SliderConfig): Frame
    local currentValue = math.clamp(config.InitialValue, 0, 1)

    local container = Instance.new("Frame")
    container.Name = "Slider_" .. config.Label:gsub("%s+", "")
    container.Size = UDim2.new(1, 0, 0, config.Description and 74 or 60)
    container.BackgroundTransparency = 1
    container.ZIndex = 34
    container.Parent = config.Parent

    -- Label and Percentage Pill Row
    local headerRow = Instance.new("Frame")
    headerRow.Name = "HeaderRow"
    headerRow.Size = UDim2.new(1, 0, 0, 20)
    headerRow.BackgroundTransparency = 1
    headerRow.ZIndex = 34
    headerRow.Parent = container

    local title = Instance.new("TextLabel")
    title.Name = "Title"
    title.Size = UDim2.new(0.7, 0, 1, 0)
    title.BackgroundTransparency = 1
    title.Font = UITheme.Fonts.Subheading
    title.Text = config.Label
    title.TextColor3 = UITheme.Colors.TextPrimary
    title.TextSize = 13
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.ZIndex = 34
    title.Parent = headerRow

    local valuePill = Instance.new("TextLabel")
    valuePill.Name = "ValuePill"
    valuePill.Size = UDim2.new(0.3, 0, 1, 0)
    valuePill.Position = UDim2.fromScale(1, 0)
    valuePill.AnchorPoint = Vector2.new(1, 0)
    valuePill.BackgroundTransparency = 1
    valuePill.Font = UITheme.Fonts.Tag
    valuePill.Text = string.format("%d%%", math.round(currentValue * 100))
    valuePill.TextColor3 = UITheme.Colors.EmberHot
    valuePill.TextSize = 13
    valuePill.TextXAlignment = Enum.TextXAlignment.Right
    valuePill.ZIndex = 34
    valuePill.Parent = headerRow

    -- Controls Row: [-] [------Track------] [+]
    local controlsRow = Instance.new("Frame")
    controlsRow.Name = "ControlsRow"
    controlsRow.Size = UDim2.new(1, 0, 0, 32)
    controlsRow.Position = UDim2.new(0, 0, 0, 26)
    controlsRow.BackgroundTransparency = 1
    controlsRow.ZIndex = 34
    controlsRow.Parent = container

    local btnMinus = Instance.new("TextButton")
    btnMinus.Name = "BtnMinus"
    btnMinus.Size = UDim2.fromOffset(32, 28)
    btnMinus.Position = UDim2.fromScale(0, 0.5)
    btnMinus.AnchorPoint = Vector2.new(0, 0.5)
    btnMinus.BackgroundColor3 = UITheme.Colors.Surface
    btnMinus.Font = UITheme.Fonts.Heading
    btnMinus.Text = "-"
    btnMinus.TextColor3 = UITheme.Colors.TextPrimary
    btnMinus.TextSize = 16
    btnMinus.ZIndex = 35
    btnMinus.Parent = controlsRow

    local minusCorner = Instance.new("UICorner")
    minusCorner.CornerRadius = UDim.new(0, 6)
    minusCorner.Parent = btnMinus

    local btnPlus = Instance.new("TextButton")
    btnPlus.Name = "BtnPlus"
    btnPlus.Size = UDim2.fromOffset(32, 28)
    btnPlus.Position = UDim2.fromScale(1, 0.5)
    btnPlus.AnchorPoint = Vector2.new(1, 0.5)
    btnPlus.BackgroundColor3 = UITheme.Colors.Surface
    btnPlus.Font = UITheme.Fonts.Heading
    btnPlus.Text = "+"
    btnPlus.TextColor3 = UITheme.Colors.TextPrimary
    btnPlus.TextSize = 16
    btnPlus.ZIndex = 35
    btnPlus.Parent = controlsRow

    local plusCorner = Instance.new("UICorner")
    plusCorner.CornerRadius = UDim.new(0, 6)
    plusCorner.Parent = btnPlus

    -- Track Frame
    local track = Instance.new("Frame")
    track.Name = "Track"
    track.Size = UDim2.new(1, -84, 0, 10)
    track.Position = UDim2.fromScale(0.5, 0.5)
    track.AnchorPoint = Vector2.new(0.5, 0.5)
    track.BackgroundColor3 = UITheme.Colors.Void
    track.BorderSizePixel = 0
    track.ZIndex = 35
    track.Parent = controlsRow

    local trackCorner = Instance.new("UICorner")
    trackCorner.CornerRadius = UDim.new(1, 0)
    trackCorner.Parent = track

    local trackStroke = Instance.new("UIStroke")
    trackStroke.Color = UITheme.Colors.BorderHairline
    trackStroke.Thickness = 1
    trackStroke.Parent = track

    -- Fill Bar with warm firelight gradient
    local fill = Instance.new("Frame")
    fill.Name = "Fill"
    fill.Size = UDim2.fromScale(currentValue, 1)
    fill.BackgroundColor3 = UITheme.Colors.EmberPrimary
    fill.BorderSizePixel = 0
    fill.ZIndex = 36
    fill.Parent = track

    local fillCorner = Instance.new("UICorner")
    fillCorner.CornerRadius = UDim.new(1, 0)
    fillCorner.Parent = fill

    local fillGrad = Instance.new("UIGradient")
    fillGrad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, UITheme.Colors.EmberCrimson),
        ColorSequenceKeypoint.new(0.7, UITheme.Colors.EmberPrimary),
        ColorSequenceKeypoint.new(1, UITheme.Colors.EmberGold),
    })
    fillGrad.Parent = fill

    local function setValue(val: number)
        currentValue = math.clamp(val, 0, 1)
        fill.Size = UDim2.fromScale(currentValue, 1)
        valuePill.Text = string.format("%d%%", math.round(currentValue * 100))
        config.OnChanged(currentValue)
    end

    btnMinus.Activated:Connect(function()
        setValue(currentValue - 0.05)
    end)

    btnPlus.Activated:Connect(function()
        setValue(currentValue + 0.05)
    end)

    -- Draggable interaction on track
    local isDragging = false

    track.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            isDragging = true
            if track.AbsoluteSize.X > 0 then
                local relative = math.clamp((input.Position.X - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
                setValue(relative)
            end
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if isDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            if track.AbsoluteSize.X > 0 then
                local relative = math.clamp((input.Position.X - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
                setValue(relative)
            end
        end
    end)

    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            isDragging = false
        end
    end)

    return container
end

--------------------------------------------------------------------------------
-- 4. TACTILE TOGGLE COMPONENT
--------------------------------------------------------------------------------
export type ToggleConfig = {
    Label: string,
    Description: string,
    InitialValue: boolean,
    Parent: Instance,
    OnChanged: (value: boolean) -> (),
}

function UIComponents.CreateToggle(config: ToggleConfig): Frame
    local isEnabled = config.InitialValue or false

    local container = Instance.new("Frame")
    container.Name = "Toggle_" .. config.Label:gsub("%s+", "")
    container.Size = UDim2.new(1, 0, 0, 56)
    container.BackgroundTransparency = 1
    container.ZIndex = 34
    container.Parent = config.Parent

    -- Left text container
    local textBlock = Instance.new("Frame")
    textBlock.Name = "TextBlock"
    textBlock.Size = UDim2.new(0.68, 0, 1, 0)
    textBlock.BackgroundTransparency = 1
    textBlock.ZIndex = 34
    textBlock.Parent = container

    local title = Instance.new("TextLabel")
    title.Name = "Title"
    title.Size = UDim2.new(1, 0, 0, 18)
    title.BackgroundTransparency = 1
    title.Font = UITheme.Fonts.Subheading
    title.Text = config.Label
    title.TextColor3 = UITheme.Colors.TextPrimary
    title.TextSize = 13
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.ZIndex = 34
    title.Parent = textBlock

    local desc = Instance.new("TextLabel")
    desc.Name = "Description"
    desc.Size = UDim2.new(1, 0, 0, 16)
    desc.Position = UDim2.new(0, 0, 0, 20)
    desc.BackgroundTransparency = 1
    desc.Font = UITheme.Fonts.Body
    desc.Text = config.Description
    desc.TextColor3 = UITheme.Colors.TextMuted
    desc.TextSize = 11
    desc.TextXAlignment = Enum.TextXAlignment.Left
    desc.ZIndex = 34
    desc.Parent = textBlock

    -- Right Animated Capsule Switch
    local switch = Instance.new("TextButton")
    switch.Name = "SwitchPill"
    switch.Size = UDim2.fromOffset(60, 30)
    switch.Position = UDim2.fromScale(1, 0.5)
    switch.AnchorPoint = Vector2.new(1, 0.5)
    switch.BackgroundColor3 = isEnabled and UITheme.Colors.EmberPrimary or UITheme.Colors.Surface
    switch.AutoButtonColor = false
    switch.Text = ""
    switch.ZIndex = 35
    switch.Parent = container

    local switchCorner = Instance.new("UICorner")
    switchCorner.CornerRadius = UDim.new(1, 0)
    switchCorner.Parent = switch

    local switchStroke = Instance.new("UIStroke")
    switchStroke.Color = isEnabled and UITheme.Colors.BorderActive or UITheme.Colors.BorderHairline
    switchStroke.Thickness = 1.2
    switchStroke.Parent = switch

    -- Knob (sliding circle inside switch)
    local knob = Instance.new("Frame")
    knob.Name = "Knob"
    knob.Size = UDim2.fromOffset(22, 22)
    knob.Position = isEnabled and UDim2.new(1, -26, 0.5, 0) or UDim2.new(0, 4, 0.5, 0)
    knob.AnchorPoint = Vector2.new(0, 0.5)
    knob.BackgroundColor3 = isEnabled and UITheme.Colors.PureWhite or UITheme.Colors.TextMuted
    knob.BorderSizePixel = 0
    knob.ZIndex = 36
    knob.Parent = switch

    local knobCorner = Instance.new("UICorner")
    knobCorner.CornerRadius = UDim.new(1, 0)
    knobCorner.Parent = knob

    local function updateState(newState: boolean)
        isEnabled = newState
        local targetKnobPos = isEnabled and UDim2.new(1, -26, 0.5, 0) or UDim2.new(0, 4, 0.5, 0)
        local targetSwitchBg = isEnabled and UITheme.Colors.EmberPrimary or UITheme.Colors.Surface
        local targetStrokeColor = isEnabled and UITheme.Colors.BorderActive or UITheme.Colors.BorderHairline
        local targetKnobColor = isEnabled and UITheme.Colors.PureWhite or UITheme.Colors.TextMuted

        TweenService:Create(knob, UITheme.Tweens.Fast, {
            Position = targetKnobPos,
            BackgroundColor3 = targetKnobColor,
        }):Play()
        TweenService:Create(switch, UITheme.Tweens.Fast, {
            BackgroundColor3 = targetSwitchBg,
        }):Play()
        TweenService:Create(switchStroke, UITheme.Tweens.Fast, {
            Color = targetStrokeColor,
        }):Play()

        config.OnChanged(isEnabled)
    end

    switch.Activated:Connect(function()
        updateState(not isEnabled)
    end)

    return container
end

--------------------------------------------------------------------------------
-- 5. HAIRLINE GRADIENT DIVIDER
--------------------------------------------------------------------------------
function UIComponents.CreateDivider(parent: Instance): Frame
    local divider = Instance.new("Frame")
    divider.Name = "Divider"
    divider.Size = UDim2.new(1, 0, 0, 1)
    divider.BackgroundColor3 = UITheme.Colors.BorderHairline
    divider.BorderSizePixel = 0
    divider.ZIndex = 30
    divider.Parent = parent

    local grad = Instance.new("UIGradient")
    grad.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 1),
        NumberSequenceKeypoint.new(0.2, 0),
        NumberSequenceKeypoint.new(0.8, 0),
        NumberSequenceKeypoint.new(1, 1),
    })
    grad.Parent = divider

    return divider
end

return UIComponents
