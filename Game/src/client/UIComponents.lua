--!strict
--[[
    UIComponents.lua
    Production-grade component library for "Don't Let the Fire Die".
    Developed for Fluenosity Studio.
    
    Components:
    - CreateNavAction: Left-aligned large typography menu actions (Image 2 style with amber rules)
    - CreatePartySlot: Bottom-left co-op lobby / invite slots (Image 2 style: YOU vs EMPTY [+])
    - CreateFeatureCard: Right-side showcase/announcement cards (Image 2 style)
    - CreateModal: Dark horror modal dialogs with smooth scaling
    - CreateSlider: Master volume slider with drag, step [-]/[+], and live % readouts
    - CreateToggle: Tactile animated capsule switches
    - CreateDivider: Gradient hairline dividers
]]

local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local SocialService = game:GetService("SocialService")
local UITheme = require(script.Parent:WaitForChild("UITheme"))

local UIComponents = {}

--------------------------------------------------------------------------------
-- 1. LEFT-ALIGNED HEROIC NAV ACTION (Image 2 Style)
--------------------------------------------------------------------------------
export type NavActionConfig = {
    Text: string,
    IsPrimary: boolean?,
    LayoutOrder: number?,
    Parent: Instance,
    OnClick: () -> (),
}

function UIComponents.CreateNavAction(config: NavActionConfig): TextButton
    local isPrimary = config.IsPrimary or false

    local button = Instance.new("TextButton")
    button.Name = "Nav_" .. config.Text:gsub("%s+", "")
    button.Size = UDim2.new(1, 0, 0, isPrimary and 56 or 46)
    button.BackgroundTransparency = 1
    button.AutoButtonColor = false
    button.Text = ""
    button.LayoutOrder = config.LayoutOrder or 0
    button.ZIndex = 10
    button.Parent = config.Parent

    -- Container for text & rules
    local contentFrame = Instance.new("Frame")
    contentFrame.Name = "Content"
    contentFrame.Size = UDim2.fromScale(1, 1)
    contentFrame.BackgroundTransparency = 1
    contentFrame.ZIndex = 11
    contentFrame.Parent = button

    -- Top Accent Rule Line (Primary only, like PLAY in Image 2)
    local topRule: Frame? = nil
    local bottomRule: Frame? = nil

    if isPrimary then
        topRule = Instance.new("Frame")
        topRule.Name = "TopRule"
        topRule.Size = UDim2.new(0, 180, 0, 2)
        topRule.Position = UDim2.new(0, 0, 0, 2)
        topRule.BackgroundColor3 = UITheme.Colors.BorderSubtle
        topRule.BorderSizePixel = 0
        topRule.ZIndex = 12
        topRule.Parent = contentFrame

        local topRuleGrad = Instance.new("UIGradient")
        topRuleGrad.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, UITheme.Colors.EmberHot),
            ColorSequenceKeypoint.new(0.6, UITheme.Colors.BorderSubtle),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(30, 26, 26)),
        })
        topRuleGrad.Parent = topRule

        bottomRule = Instance.new("Frame")
        bottomRule.Name = "BottomRule"
        bottomRule.Size = UDim2.new(0, 180, 0, 2)
        bottomRule.Position = UDim2.new(0, 0, 1, -4)
        bottomRule.BackgroundColor3 = UITheme.Colors.BorderSubtle
        bottomRule.BorderSizePixel = 0
        bottomRule.ZIndex = 12
        bottomRule.Parent = contentFrame

        local bottomRuleGrad = Instance.new("UIGradient")
        bottomRuleGrad.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, UITheme.Colors.EmberHot),
            ColorSequenceKeypoint.new(0.6, UITheme.Colors.BorderSubtle),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(30, 26, 26)),
        })
        bottomRuleGrad.Parent = bottomRule
    end

    -- Large Bold Text Label
    local textLabel = Instance.new("TextLabel")
    textLabel.Name = "Label"
    textLabel.Size = UDim2.fromScale(1, 1)
    textLabel.Position = UDim2.new(0, 0, 0, 0)
    textLabel.BackgroundTransparency = 1
    textLabel.Font = UITheme.Fonts.Heading
    textLabel.Text = config.Text
    textLabel.TextColor3 = isPrimary and UITheme.Colors.TextPrimary or UITheme.Colors.TextSecondary
    textLabel.TextSize = isPrimary and 32 or 26
    textLabel.TextXAlignment = Enum.TextXAlignment.Left
    textLabel.TextYAlignment = Enum.TextYAlignment.Center
    textLabel.TextStrokeColor3 = Color3.fromRGB(12, 8, 6)
    textLabel.TextStrokeTransparency = 0.3
    textLabel.ZIndex = 13
    textLabel.Parent = contentFrame

    -- Interactive Hover & Press Animations
    button.MouseEnter:Connect(function()
        TweenService:Create(textLabel, UITheme.Tweens.Fast, {
            TextColor3 = UITheme.Colors.EmberHot,
            Position = UDim2.new(0, 8, 0, 0),
        }):Play()

        if topRule and bottomRule then
            TweenService:Create(topRule, UITheme.Tweens.Fast, {
                Size = UDim2.new(0, 230, 0, 3),
                BackgroundColor3 = UITheme.Colors.EmberPrimary,
            }):Play()
            TweenService:Create(bottomRule, UITheme.Tweens.Fast, {
                Size = UDim2.new(0, 230, 0, 3),
                BackgroundColor3 = UITheme.Colors.EmberPrimary,
            }):Play()
        end
    end)

    button.MouseLeave:Connect(function()
        TweenService:Create(textLabel, UITheme.Tweens.Fast, {
            TextColor3 = isPrimary and UITheme.Colors.TextPrimary or UITheme.Colors.TextSecondary,
            Position = UDim2.new(0, 0, 0, 0),
        }):Play()

        if topRule and bottomRule then
            TweenService:Create(topRule, UITheme.Tweens.Fast, {
                Size = UDim2.new(0, 180, 0, 2),
                BackgroundColor3 = UITheme.Colors.BorderSubtle,
            }):Play()
            TweenService:Create(bottomRule, UITheme.Tweens.Fast, {
                Size = UDim2.new(0, 180, 0, 2),
                BackgroundColor3 = UITheme.Colors.BorderSubtle,
            }):Play()
        end
    end)

    button.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            TweenService:Create(textLabel, UITheme.Tweens.Instant, {
                Position = UDim2.new(0, 4, 0, 2),
                TextColor3 = UITheme.Colors.EmberGold,
            }):Play()
        end
    end)

    button.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            TweenService:Create(textLabel, UITheme.Tweens.Fast, {
                Position = UDim2.new(0, 8, 0, 0),
                TextColor3 = UITheme.Colors.EmberHot,
            }):Play()
        end
    end)

    button.Activated:Connect(function()
        config.OnClick()
    end)

    return button
end

--------------------------------------------------------------------------------
-- 2. BOTTOM-LEFT PARTY / CO-OP SLOT (Image 2 Style: EMPTY / [+] Box)
--------------------------------------------------------------------------------
export type PartySlotConfig = {
    Index: number,
    IsPlayer: boolean,
    Player: Player?,
    Parent: Instance,
}

function UIComponents.CreatePartySlot(config: PartySlotConfig): Frame
    local slot = Instance.new("Frame")
    slot.Name = "PartySlot_" .. config.Index
    slot.Size = UDim2.fromOffset(54, 70)
    slot.BackgroundTransparency = 1
    slot.ZIndex = 15
    slot.Parent = config.Parent

    -- Label Above: "YOU" or "EMPTY"
    local tag = Instance.new("TextLabel")
    tag.Name = "Tag"
    tag.Size = UDim2.new(1, 0, 0, 14)
    tag.Position = UDim2.new(0, 0, 0, 0)
    tag.BackgroundTransparency = 1
    tag.Font = UITheme.Fonts.Tag
    tag.Text = config.IsPlayer and "YOU" or "EMPTY"
    tag.TextColor3 = config.IsPlayer and UITheme.Colors.EmberHot or UITheme.Colors.TextMuted
    tag.TextSize = 10
    tag.TextXAlignment = Enum.TextXAlignment.Center
    tag.ZIndex = 16
    tag.Parent = slot

    -- Square Frame Box Below
    local box = Instance.new("TextButton")
    box.Name = "Box"
    box.Size = UDim2.fromOffset(48, 48)
    box.Position = UDim2.new(0.5, 0, 0, 16)
    box.AnchorPoint = Vector2.new(0.5, 0)
    box.BackgroundColor3 = config.IsPlayer and UITheme.Colors.SurfaceElevated or UITheme.Colors.Surface
    box.AutoButtonColor = false
    box.Text = ""
    box.BorderSizePixel = 0
    box.ZIndex = 16
    box.Parent = slot

    local boxCorner = Instance.new("UICorner")
    boxCorner.CornerRadius = UDim.new(0, 6)
    boxCorner.Parent = box

    local boxStroke = Instance.new("UIStroke")
    boxStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    boxStroke.Color = config.IsPlayer and UITheme.Colors.BorderActive or UITheme.Colors.BorderSubtle
    boxStroke.Thickness = 1.2
    boxStroke.Parent = box

    if config.IsPlayer and config.Player then
        -- Player Avatar Thumbnail
        local avatarImg = Instance.new("ImageLabel")
        avatarImg.Name = "Avatar"
        avatarImg.Size = UDim2.fromScale(0.9, 0.9)
        avatarImg.Position = UDim2.fromScale(0.5, 0.5)
        avatarImg.AnchorPoint = Vector2.new(0.5, 0.5)
        avatarImg.BackgroundTransparency = 1
        avatarImg.ZIndex = 17
        avatarImg.Parent = box

        local avatarCorner = Instance.new("UICorner")
        avatarCorner.CornerRadius = UDim.new(0, 4)
        avatarCorner.Parent = avatarImg

        task.spawn(function()
            local p = config.Player
            if p then
                local success, content = pcall(function()
                    return Players:GetUserThumbnailAsync(
                        p.UserId,
                        Enum.ThumbnailType.HeadShot,
                        Enum.ThumbnailSize.Size100x100
                    )
                end)
                if success and content then
                    avatarImg.Image = content
                end
            end
        end)
    else
        -- Empty Slot: Plus (+) Icon
        local plusIcon = Instance.new("TextLabel")
        plusIcon.Name = "Plus"
        plusIcon.Size = UDim2.fromScale(1, 1)
        plusIcon.BackgroundTransparency = 1
        plusIcon.Font = UITheme.Fonts.Heading
        plusIcon.Text = "+"
        plusIcon.TextColor3 = UITheme.Colors.TextMuted
        plusIcon.TextSize = 22
        plusIcon.ZIndex = 17
        plusIcon.Parent = box

        box.MouseEnter:Connect(function()
            TweenService:Create(boxStroke, UITheme.Tweens.Fast, {
                Color = UITheme.Colors.EmberHot,
            }):Play()
            TweenService:Create(plusIcon, UITheme.Tweens.Fast, {
                TextColor3 = UITheme.Colors.EmberHot,
                TextSize = 24,
            }):Play()
        end)

        box.MouseLeave:Connect(function()
            TweenService:Create(boxStroke, UITheme.Tweens.Fast, {
                Color = UITheme.Colors.BorderSubtle,
            }):Play()
            TweenService:Create(plusIcon, UITheme.Tweens.Fast, {
                TextColor3 = UITheme.Colors.TextMuted,
                TextSize = 22,
            }):Play()
        end)

        local isPromptingInvite = false

        box.Activated:Connect(function()
            if isPromptingInvite then return end
            isPromptingInvite = true

            -- Tactile click feedback
            TweenService:Create(box, UITheme.Tweens.Fast, {
                BackgroundColor3 = UITheme.Colors.SurfaceHighlight,
            }):Play()

            task.spawn(function()
                local p = Players.LocalPlayer
                if p then
                    local canInvite = false
                    local checkSuccess, checkResult = pcall(function()
                        return SocialService:CanSendGameInviteAsync(p)
                    end)
                    if checkSuccess and checkResult == true then
                        pcall(function()
                            SocialService:PromptGameInvite(p)
                        end)
                    end
                end

                task.wait(1.5)
                TweenService:Create(box, UITheme.Tweens.Fast, {
                    BackgroundColor3 = UITheme.Colors.Surface,
                }):Play()
                isPromptingInvite = false
            end)
        end)
    end

    return slot
end

--------------------------------------------------------------------------------
-- 3. RIGHT-SIDE SHOWCASE / NEWS CARD (Image 2 Style)
--------------------------------------------------------------------------------
export type FeatureCardConfig = {
    Title: string,
    Subtitle: string,
    BadgeText: string?,
    BannerGradientColors: { ColorSequenceKeypoint },
    Parent: Instance,
    OnClick: (() -> ())?,
}

function UIComponents.CreateFeatureCard(config: FeatureCardConfig): Frame
    local card = Instance.new("Frame")
    card.Name = "Card_" .. config.Title:gsub("%s+", "")
    card.Size = UDim2.new(1, 0, 0, 185)
    card.BackgroundColor3 = UITheme.Colors.Surface
    card.BorderSizePixel = 0
    card.ZIndex = 15
    card.Parent = config.Parent

    local cardCorner = Instance.new("UICorner")
    cardCorner.CornerRadius = UDim.new(0, 10)
    cardCorner.Parent = card

    local cardStroke = Instance.new("UIStroke")
    cardStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    cardStroke.Color = UITheme.Colors.BorderHairline
    cardStroke.Thickness = 1.2
    cardStroke.Parent = card

    -- Card Top Visual Banner Container
    local banner = Instance.new("Frame")
    banner.Name = "Banner"
    banner.Size = UDim2.new(1, 0, 0.65, 0)
    banner.Position = UDim2.new(0, 0, 0, 0)
    banner.BackgroundColor3 = UITheme.Colors.SurfaceElevated
    banner.BorderSizePixel = 0
    banner.ZIndex = 16
    banner.Parent = card

    local bannerCorner = Instance.new("UICorner")
    bannerCorner.CornerRadius = UDim.new(0, 10)
    bannerCorner.Parent = banner

    local bannerGrad = Instance.new("UIGradient")
    bannerGrad.Color = ColorSequence.new(config.BannerGradientColors)
    bannerGrad.Rotation = 45
    bannerGrad.Parent = banner

    -- Dark fade over bottom of banner into content
    local bannerShadow = Instance.new("Frame")
    bannerShadow.Name = "Shadow"
    bannerShadow.Size = UDim2.fromScale(1, 1)
    bannerShadow.BackgroundColor3 = UITheme.Colors.Void
    bannerShadow.BorderSizePixel = 0
    bannerShadow.ZIndex = 17
    bannerShadow.Parent = banner

    local shadowGrad = Instance.new("UIGradient")
    shadowGrad.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.4),
        NumberSequenceKeypoint.new(0.65, 0.7),
        NumberSequenceKeypoint.new(1, 1),
    })
    shadowGrad.Rotation = -90
    shadowGrad.Parent = bannerShadow

    -- Optional Badge (e.g. "OFFICIAL UPDATE" or "LORE")
    if config.BadgeText then
        local badge = Instance.new("TextLabel")
        badge.Name = "Badge"
        badge.Size = UDim2.fromOffset(110, 20)
        badge.Position = UDim2.new(0, 12, 0, 10)
        badge.BackgroundColor3 = UITheme.Colors.Void
        badge.BackgroundTransparency = 0.3
        badge.Font = UITheme.Fonts.Tag
        badge.Text = config.BadgeText
        badge.TextColor3 = UITheme.Colors.EmberHot
        badge.TextSize = 9
        badge.ZIndex = 18
        badge.Parent = banner

        local badgeCorner = Instance.new("UICorner")
        badgeCorner.CornerRadius = UDim.new(0, 4)
        badgeCorner.Parent = badge
    end

    -- Card Text Container at Bottom
    local textBlock = Instance.new("Frame")
    textBlock.Name = "TextBlock"
    textBlock.Size = UDim2.new(1, -24, 0.35, 0)
    textBlock.Position = UDim2.new(0, 12, 0.65, 0)
    textBlock.BackgroundTransparency = 1
    textBlock.ZIndex = 18
    textBlock.Parent = card

    local titleLbl = Instance.new("TextLabel")
    titleLbl.Name = "Title"
    titleLbl.Size = UDim2.new(1, 0, 0, 22)
    titleLbl.Position = UDim2.new(0, 0, 0, 6)
    titleLbl.BackgroundTransparency = 1
    titleLbl.Font = UITheme.Fonts.Heading
    titleLbl.Text = config.Title
    titleLbl.TextColor3 = UITheme.Colors.TextPrimary
    titleLbl.TextSize = 14
    titleLbl.TextXAlignment = Enum.TextXAlignment.Left
    titleLbl.ZIndex = 19
    titleLbl.Parent = textBlock

    local subtitleLbl = Instance.new("TextLabel")
    subtitleLbl.Name = "Subtitle"
    subtitleLbl.Size = UDim2.new(1, 0, 0, 16)
    subtitleLbl.Position = UDim2.new(0, 0, 0, 28)
    subtitleLbl.BackgroundTransparency = 1
    subtitleLbl.Font = UITheme.Fonts.Body
    subtitleLbl.Text = config.Subtitle
    subtitleLbl.TextColor3 = UITheme.Colors.TextMuted
    subtitleLbl.TextSize = 11
    subtitleLbl.TextXAlignment = Enum.TextXAlignment.Left
    subtitleLbl.ZIndex = 19
    subtitleLbl.Parent = textBlock

    -- Clickable interactive behavior
    local clickOverlay = Instance.new("TextButton")
    clickOverlay.Name = "ClickOverlay"
    clickOverlay.Size = UDim2.fromScale(1, 1)
    clickOverlay.BackgroundTransparency = 1
    clickOverlay.Text = ""
    clickOverlay.ZIndex = 20
    clickOverlay.Parent = card

    clickOverlay.MouseEnter:Connect(function()
        TweenService:Create(cardStroke, UITheme.Tweens.Fast, {
            Color = UITheme.Colors.BorderActive,
            Thickness = 1.6,
        }):Play()
        TweenService:Create(titleLbl, UITheme.Tweens.Fast, {
            TextColor3 = UITheme.Colors.EmberHot,
        }):Play()
    end)

    clickOverlay.MouseLeave:Connect(function()
        TweenService:Create(cardStroke, UITheme.Tweens.Fast, {
            Color = UITheme.Colors.BorderHairline,
            Thickness = 1.2,
        }):Play()
        TweenService:Create(titleLbl, UITheme.Tweens.Fast, {
            TextColor3 = UITheme.Colors.TextPrimary,
        }):Play()
    end)

    if config.OnClick then
        clickOverlay.Activated:Connect(config.OnClick)
    end

    return card
end

--------------------------------------------------------------------------------
-- 4. MODAL DIALOG COMPONENT
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
    local width = config.Width or 440
    local height = config.Height or 400

    local backdrop = Instance.new("TextButton")
    backdrop.Name = "ModalBackdrop_" .. config.Title:gsub("%s+", "")
    backdrop.Size = UDim2.fromScale(1, 1)
    backdrop.Position = UDim2.fromScale(0, 0)
    backdrop.BackgroundColor3 = UITheme.Colors.PureBlack
    backdrop.BackgroundTransparency = 1
    backdrop.AutoButtonColor = false
    backdrop.Text = ""
    backdrop.Visible = false
    backdrop.ZIndex = 40
    backdrop.Parent = config.Parent

    local card = Instance.new("Frame")
    card.Name = "ModalCard"
    card.Size = UDim2.new(0.9, 0, 0.86, 0)
    card.Position = UDim2.fromScale(0.5, 0.52)
    card.AnchorPoint = Vector2.new(0.5, 0.5)
    card.BackgroundColor3 = UITheme.Colors.SurfaceElevated
    card.BorderSizePixel = 0
    card.Visible = false
    card.ZIndex = 42
    card.Parent = backdrop

    local cardSizeConstraint = Instance.new("UISizeConstraint")
    cardSizeConstraint.MaxSize = Vector2.new(width, height)
    cardSizeConstraint.MinSize = Vector2.new(280, 220)
    cardSizeConstraint.Parent = card

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

    local header = Instance.new("Frame")
    header.Name = "Header"
    header.Size = UDim2.new(1, 0, 0, 48)
    header.BackgroundTransparency = 1
    header.ZIndex = 43
    header.Parent = card

    if config.CategoryTag then
        local tagLabel = Instance.new("TextLabel")
        tagLabel.Name = "CategoryTag"
        tagLabel.Size = UDim2.new(0.8, 0, 0, 12)
        tagLabel.BackgroundTransparency = 1
        tagLabel.Font = UITheme.Fonts.Tag
        tagLabel.Text = config.CategoryTag
        tagLabel.TextColor3 = UITheme.Colors.EmberHot
        tagLabel.TextSize = 10
        tagLabel.TextXAlignment = Enum.TextXAlignment.Left
        tagLabel.ZIndex = 44
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
    titleLabel.ZIndex = 44
    titleLabel.Parent = header

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
    btnClose.ZIndex = 45
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

    local divider = Instance.new("Frame")
    divider.Name = "Divider"
    divider.Size = UDim2.new(1, 0, 0, 1)
    divider.Position = UDim2.new(0, 0, 0, 52)
    divider.BackgroundColor3 = UITheme.Colors.BorderHairline
    divider.BorderSizePixel = 0
    divider.ZIndex = 43
    divider.Parent = card

    local content = Instance.new("ScrollingFrame")
    content.Name = "Content"
    content.Size = UDim2.new(1, 0, 1, -114)
    content.Position = UDim2.new(0, 0, 0, 62)
    content.BackgroundTransparency = 1
    content.BorderSizePixel = 0
    content.ScrollBarThickness = 3
    content.ScrollBarImageColor3 = UITheme.Colors.EmberHot
    content.AutomaticCanvasSize = Enum.AutomaticSize.Y
    content.CanvasSize = UDim2.new(0, 0, 0, 0)
    content.ZIndex = 43
    content.Parent = card

    local footer = Instance.new("Frame")
    footer.Name = "Footer"
    footer.Size = UDim2.new(1, 0, 0, 42)
    footer.Position = UDim2.fromScale(0, 1)
    footer.AnchorPoint = Vector2.new(0, 1)
    footer.BackgroundTransparency = 1
    footer.ZIndex = 43
    footer.Parent = card

    local btnBack = Instance.new("TextButton")
    btnBack.Name = "BtnBack"
    btnBack.Size = UDim2.fromScale(1, 1)
    btnBack.BackgroundColor3 = UITheme.Colors.ButtonSecondaryBg
    btnBack.AutoButtonColor = false
    btnBack.Font = UITheme.Fonts.Button
    btnBack.Text = "BACK"
    btnBack.TextColor3 = UITheme.Colors.TextPrimary
    btnBack.TextSize = 14
    btnBack.ZIndex = 45
    btnBack.Parent = footer

    local backCorner = Instance.new("UICorner")
    backCorner.CornerRadius = UDim.new(0, 6)
    backCorner.Parent = btnBack

    local backStroke = Instance.new("UIStroke")
    backStroke.Color = UITheme.Colors.ButtonSecondaryBorder
    backStroke.Thickness = 1
    backStroke.Parent = btnBack

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
    btnBack.Activated:Connect(closeModal)

    return {
        Backdrop = backdrop,
        Card = card,
        Content = content,
        Open = openModal,
        Close = closeModal,
    }
end

--------------------------------------------------------------------------------
-- 5. SLIDER COMPONENT
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
    container.ZIndex = 44
    container.Parent = config.Parent

    local headerRow = Instance.new("Frame")
    headerRow.Name = "HeaderRow"
    headerRow.Size = UDim2.new(1, 0, 0, 20)
    headerRow.BackgroundTransparency = 1
    headerRow.ZIndex = 44
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
    title.ZIndex = 44
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
    valuePill.ZIndex = 44
    valuePill.Parent = headerRow

    local controlsRow = Instance.new("Frame")
    controlsRow.Name = "ControlsRow"
    controlsRow.Size = UDim2.new(1, 0, 0, 32)
    controlsRow.Position = UDim2.new(0, 0, 0, 26)
    controlsRow.BackgroundTransparency = 1
    controlsRow.ZIndex = 44
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
    btnMinus.ZIndex = 45
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
    btnPlus.ZIndex = 45
    btnPlus.Parent = controlsRow

    local plusCorner = Instance.new("UICorner")
    plusCorner.CornerRadius = UDim.new(0, 6)
    plusCorner.Parent = btnPlus

    local track = Instance.new("Frame")
    track.Name = "Track"
    track.Size = UDim2.new(1, -84, 0, 10)
    track.Position = UDim2.fromScale(0.5, 0.5)
    track.AnchorPoint = Vector2.new(0.5, 0.5)
    track.BackgroundColor3 = UITheme.Colors.Void
    track.BorderSizePixel = 0
    track.ZIndex = 45
    track.Parent = controlsRow

    local trackCorner = Instance.new("UICorner")
    trackCorner.CornerRadius = UDim.new(1, 0)
    trackCorner.Parent = track

    local trackStroke = Instance.new("UIStroke")
    trackStroke.Color = UITheme.Colors.BorderHairline
    trackStroke.Thickness = 1
    trackStroke.Parent = track

    local fill = Instance.new("Frame")
    fill.Name = "Fill"
    fill.Size = UDim2.fromScale(currentValue, 1)
    fill.BackgroundColor3 = UITheme.Colors.EmberPrimary
    fill.BorderSizePixel = 0
    fill.ZIndex = 46
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
-- 6. TOGGLE COMPONENT
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
    container.ZIndex = 44
    container.Parent = config.Parent

    local textBlock = Instance.new("Frame")
    textBlock.Name = "TextBlock"
    textBlock.Size = UDim2.new(0.68, 0, 1, 0)
    textBlock.BackgroundTransparency = 1
    textBlock.ZIndex = 44
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
    title.ZIndex = 44
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
    desc.ZIndex = 44
    desc.Parent = textBlock

    local switch = Instance.new("TextButton")
    switch.Name = "SwitchPill"
    switch.Size = UDim2.fromOffset(60, 30)
    switch.Position = UDim2.fromScale(1, 0.5)
    switch.AnchorPoint = Vector2.new(1, 0.5)
    switch.BackgroundColor3 = isEnabled and UITheme.Colors.EmberPrimary or UITheme.Colors.Surface
    switch.AutoButtonColor = false
    switch.Text = ""
    switch.ZIndex = 45
    switch.Parent = container

    local switchCorner = Instance.new("UICorner")
    switchCorner.CornerRadius = UDim.new(1, 0)
    switchCorner.Parent = switch

    local switchStroke = Instance.new("UIStroke")
    switchStroke.Color = isEnabled and UITheme.Colors.BorderActive or UITheme.Colors.BorderHairline
    switchStroke.Thickness = 1.2
    switchStroke.Parent = switch

    local knob = Instance.new("Frame")
    knob.Name = "Knob"
    knob.Size = UDim2.fromOffset(22, 22)
    knob.Position = isEnabled and UDim2.new(1, -26, 0.5, 0) or UDim2.new(0, 4, 0.5, 0)
    knob.AnchorPoint = Vector2.new(0, 0.5)
    knob.BackgroundColor3 = isEnabled and UITheme.Colors.PureWhite or UITheme.Colors.TextMuted
    knob.BorderSizePixel = 0
    knob.ZIndex = 46
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
-- 7. DIVIDER COMPONENT
--------------------------------------------------------------------------------
function UIComponents.CreateDivider(parent: Instance): Frame
    local divider = Instance.new("Frame")
    divider.Name = "Divider"
    divider.Size = UDim2.new(1, 0, 0, 1)
    divider.BackgroundColor3 = UITheme.Colors.BorderHairline
    divider.BorderSizePixel = 0
    divider.ZIndex = 40
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

--------------------------------------------------------------------------------
-- 8. ANIMATED LOADING SPINNER COMPONENT (Bottom-Right Ember Loader)
--------------------------------------------------------------------------------
export type SpinnerInstance = {
    Container: Frame,
    SetStatus: (status: string) -> (),
    Destroy: () -> (),
}

function UIComponents.CreateLoadingSpinner(parent: Instance, initialStatus: string?): SpinnerInstance
    local container = Instance.new("Frame")
    container.Name = "LoadingSpinnerContainer"
    container.Size = UDim2.fromOffset(190, 36)
    container.BackgroundTransparency = 1
    container.ZIndex = 85
    container.Parent = parent

    -- Rotating Outer Ring
    local ring = Instance.new("Frame")
    ring.Name = "SpinnerRing"
    ring.Size = UDim2.fromOffset(26, 26)
    ring.Position = UDim2.new(0, 0, 0.5, 0)
    ring.AnchorPoint = Vector2.new(0, 0.5)
    ring.BackgroundTransparency = 1
    ring.ZIndex = 86
    ring.Parent = container

    local ringCorner = Instance.new("UICorner")
    ringCorner.CornerRadius = UDim.new(1, 0)
    ringCorner.Parent = ring

    local ringStroke = Instance.new("UIStroke")
    ringStroke.Color = UITheme.Colors.EmberHot
    ringStroke.Thickness = 2.4
    ringStroke.Parent = ring

    local ringGrad = Instance.new("UIGradient")
    ringGrad.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0),
        NumberSequenceKeypoint.new(0.4, 0.2),
        NumberSequenceKeypoint.new(0.8, 0.85),
        NumberSequenceKeypoint.new(1, 1),
    })
    ringGrad.Parent = ringStroke

    -- Center Glowing Ember Dot
    local centerDot = Instance.new("Frame")
    centerDot.Name = "CenterEmber"
    centerDot.Size = UDim2.fromOffset(6, 6)
    centerDot.Position = UDim2.fromScale(0.5, 0.5)
    centerDot.AnchorPoint = Vector2.new(0.5, 0.5)
    centerDot.BackgroundColor3 = UITheme.Colors.EmberGold
    centerDot.BorderSizePixel = 0
    centerDot.ZIndex = 87
    centerDot.Parent = ring

    local dotCorner = Instance.new("UICorner")
    dotCorner.CornerRadius = UDim.new(1, 0)
    dotCorner.Parent = centerDot

    -- Status Text beside spinner
    local statusLabel = Instance.new("TextLabel")
    statusLabel.Name = "StatusLabel"
    statusLabel.Size = UDim2.new(1, -34, 1, 0)
    statusLabel.Position = UDim2.new(0, 34, 0, 0)
    statusLabel.BackgroundTransparency = 1
    statusLabel.Font = UITheme.Fonts.Tag
    statusLabel.Text = initialStatus or "LOADING SECTOR..."
    statusLabel.TextColor3 = UITheme.Colors.TextMuted
    statusLabel.TextSize = 11
    statusLabel.TextXAlignment = Enum.TextXAlignment.Left
    statusLabel.ZIndex = 86
    statusLabel.Parent = container

    -- Smooth Continuous Rotation Animation
    local rotateTween = TweenService:Create(ring, TweenInfo.new(1.1, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, -1), {
        Rotation = 360,
    })
    rotateTween:Play()

    -- Subtle breathing pulse on the center dot
    local dotPulse = TweenService:Create(centerDot, TweenInfo.new(0.8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {
        Size = UDim2.fromOffset(8, 8),
        BackgroundColor3 = UITheme.Colors.EmberPrimary,
    })
    dotPulse:Play()

    return {
        Container = container,
        SetStatus = function(status: string)
            statusLabel.Text = status
        end,
        Destroy = function()
            rotateTween:Cancel()
            dotPulse:Cancel()
            container:Destroy()
        end,
    }
end

--------------------------------------------------------------------------------
-- 9. PRODUCTION-GRADE REUSABLE LOADING SCREEN
--------------------------------------------------------------------------------
export type LoadingScreenInstance = {
    Container: Frame,
    Show: (options: { Status: string?, Tip: string? }?) -> (),
    SetStatus: (statusText: string) -> (),
    SetTip: (tipText: string) -> (),
    Hide: (onCompleted: (() -> ())?) -> (),
    Destroy: () -> (),
}

local SURVIVAL_TIPS = {
    "The campfire is your only safe haven. When it dies, the forest takes you.",
    "The Hollow avoids bright light, but tests the perimeter when embers dim.",
    "Wood is fuel and life. Scavenge nearby timber during the day.",
    "Never wander into the deep forest alone after dusk falls.",
    "Light Relays can be placed to carve safe corridors through the dark.",
    "Keep your ears open. Sound carries far in the frozen silence.",
}

function UIComponents.CreateLoadingScreen(parent: Instance): LoadingScreenInstance
    local container = Instance.new("Frame")
    container.Name = "CinematicLoadingScreen"
    container.Size = UDim2.fromScale(1, 1)
    container.Position = UDim2.fromScale(0, 0)
    container.BackgroundColor3 = UITheme.Colors.Void
    container.BackgroundTransparency = 1
    container.BorderSizePixel = 0
    container.Visible = false
    container.ZIndex = 80
    container.Parent = parent

    -- Center Ambient Warm Glow
    local centerGlow = Instance.new("Frame")
    centerGlow.Name = "CenterGlow"
    centerGlow.Size = UDim2.fromOffset(360, 360)
    centerGlow.Position = UDim2.fromScale(0.5, 0.45)
    centerGlow.AnchorPoint = Vector2.new(0.5, 0.5)
    centerGlow.BackgroundColor3 = UITheme.Colors.EmberCrimson
    centerGlow.BackgroundTransparency = 0.95
    centerGlow.BorderSizePixel = 0
    centerGlow.ZIndex = 81
    centerGlow.Parent = container

    local glowCorner = Instance.new("UICorner")
    glowCorner.CornerRadius = UDim.new(1, 0)
    glowCorner.Parent = centerGlow

    local glowGrad = Instance.new("UIGradient")
    glowGrad.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.7),
        NumberSequenceKeypoint.new(0.6, 0.9),
        NumberSequenceKeypoint.new(1, 1),
    })
    glowGrad.Parent = centerGlow

    -- Center Content Stack (Emblem icon, title, survival tip card)
    local centerStack = Instance.new("Frame")
    centerStack.Name = "CenterStack"
    centerStack.Size = UDim2.new(0.88, 0, 0, 220)
    centerStack.Position = UDim2.fromScale(0.5, 0.46)
    centerStack.AnchorPoint = Vector2.new(0.5, 0.5)
    centerStack.BackgroundTransparency = 1
    centerStack.ZIndex = 82
    centerStack.Parent = container

    local stackConstraint = Instance.new("UISizeConstraint")
    stackConstraint.MaxSize = Vector2.new(480, 240)
    stackConstraint.MinSize = Vector2.new(280, 160)
    stackConstraint.Parent = centerStack

    local stackLayout = Instance.new("UIListLayout")
    stackLayout.FillDirection = Enum.FillDirection.Vertical
    stackLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    stackLayout.VerticalAlignment = Enum.VerticalAlignment.Center
    stackLayout.Padding = UDim.new(0, 10)
    stackLayout.Parent = centerStack

    -- Title
    local titleLbl = Instance.new("TextLabel")
    titleLbl.Name = "Title"
    titleLbl.Size = UDim2.new(1, 0, 0, 28)
    titleLbl.BackgroundTransparency = 1
    titleLbl.Font = UITheme.Fonts.Heading
    titleLbl.Text = "DON'T LET THE FIRE DIE"
    titleLbl.TextColor3 = UITheme.Colors.TextPrimary
    titleLbl.TextScaled = true
    titleLbl.TextSize = 22
    titleLbl.TextStrokeColor3 = Color3.fromRGB(15, 8, 6)
    titleLbl.TextStrokeTransparency = 0.3
    titleLbl.ZIndex = 83
    titleLbl.Parent = centerStack

    local titleConstraint = Instance.new("UITextSizeConstraint")
    titleConstraint.MaxTextSize = 24
    titleConstraint.MinTextSize = 16
    titleConstraint.Parent = titleLbl

    -- Subtitle Badge
    local sessionBadge = Instance.new("TextLabel")
    sessionBadge.Name = "SessionBadge"
    sessionBadge.Size = UDim2.new(1, 0, 0, 16)
    sessionBadge.BackgroundTransparency = 1
    sessionBadge.Font = UITheme.Fonts.Tag
    sessionBadge.Text = "[ PREPARING SURVIVAL SECTOR ]"
    sessionBadge.TextColor3 = UITheme.Colors.EmberHot
    sessionBadge.TextSize = 10
    sessionBadge.ZIndex = 83
    sessionBadge.Parent = centerStack

    -- Tip Container Box
    local tipBox = Instance.new("Frame")
    tipBox.Name = "TipBox"
    tipBox.Size = UDim2.new(1, 0, 0, 72)
    tipBox.BackgroundColor3 = UITheme.Colors.SurfaceElevated
    tipBox.BorderSizePixel = 0
    tipBox.ZIndex = 83
    tipBox.Parent = centerStack

    local tipCorner = Instance.new("UICorner")
    tipCorner.CornerRadius = UDim.new(0, 8)
    tipCorner.Parent = tipBox

    local tipStroke = Instance.new("UIStroke")
    tipStroke.Color = UITheme.Colors.BorderHairline
    tipStroke.Thickness = 1
    tipStroke.Parent = tipBox

    local tipPadding = Instance.new("UIPadding")
    tipPadding.PaddingTop = UDim.new(0, 10)
    tipPadding.PaddingBottom = UDim.new(0, 10)
    tipPadding.PaddingLeft = UDim.new(0, 16)
    tipPadding.PaddingRight = UDim.new(0, 16)
    tipPadding.Parent = tipBox

    local tipHeader = Instance.new("TextLabel")
    tipHeader.Name = "TipHeader"
    tipHeader.Size = UDim2.new(1, 0, 0, 14)
    tipHeader.BackgroundTransparency = 1
    tipHeader.Font = UITheme.Fonts.Tag
    tipHeader.Text = "SURVIVAL INTEL"
    tipHeader.TextColor3 = UITheme.Colors.EmberPrimary
    tipHeader.TextSize = 10
    tipHeader.TextXAlignment = Enum.TextXAlignment.Left
    tipHeader.ZIndex = 84
    tipHeader.Parent = tipBox

    local tipBody = Instance.new("TextLabel")
    tipBody.Name = "TipBody"
    tipBody.Size = UDim2.new(1, 0, 0, 32)
    tipBody.Position = UDim2.new(0, 0, 0, 16)
    tipBody.BackgroundTransparency = 1
    tipBody.Font = UITheme.Fonts.Body
    tipBody.Text = SURVIVAL_TIPS[math.random(1, #SURVIVAL_TIPS)]
    tipBody.TextColor3 = UITheme.Colors.TextSecondary
    tipBody.TextSize = 11
    tipBody.TextWrapped = true
    tipBody.TextXAlignment = Enum.TextXAlignment.Left
    tipBody.ZIndex = 84
    tipBody.Parent = tipBox

    -- Bottom-Right Animated Spinner
    local spinnerHolder = Instance.new("Frame")
    spinnerHolder.Name = "SpinnerHolder"
    spinnerHolder.Size = UDim2.fromOffset(210, 36)
    spinnerHolder.Position = UDim2.new(1, -36, 1, -28)
    spinnerHolder.AnchorPoint = Vector2.new(1, 1)
    spinnerHolder.BackgroundTransparency = 1
    spinnerHolder.ZIndex = 85
    spinnerHolder.Parent = container

    local spinner = UIComponents.CreateLoadingSpinner(spinnerHolder, "INITIALIZING WORLD...")

    local isTransitioning = false

    local function showLoading(options: { Status: string?, Tip: string? }?)
        if isTransitioning then return end
        isTransitioning = true

        if options and options.Status then
            spinner.SetStatus(options.Status)
        end
        if options and options.Tip then
            tipBody.Text = options.Tip
        else
            tipBody.Text = SURVIVAL_TIPS[math.random(1, #SURVIVAL_TIPS)]
        end

        container.Visible = true
        container.BackgroundTransparency = 1

        local fadeTween = TweenService:Create(container, UITheme.Tweens.Fast, {
            BackgroundTransparency = 0,
        })
        fadeTween.Completed:Connect(function()
            isTransitioning = false
        end)
        fadeTween:Play()
    end

    local function hideLoading(onCompleted: (() -> ())?)
        if isTransitioning then return end
        isTransitioning = true

        local fadeTween = TweenService:Create(container, UITheme.Tweens.Smooth, {
            BackgroundTransparency = 1,
        })
        fadeTween.Completed:Connect(function()
            container.Visible = false
            isTransitioning = false
            if onCompleted then
                onCompleted()
            end
        end)
        fadeTween:Play()
    end

    return {
        Container = container,
        Show = showLoading,
        SetStatus = function(statusText: string)
            spinner.SetStatus(statusText)
        end,
        Hide = hideLoading,
        Destroy = function()
            spinner.Destroy()
            container:Destroy()
        end,
    }
end

--------------------------------------------------------------------------------
-- 10. IN-GAME HUD CLOCK COMPONENT (Day / Phase / Time)
--------------------------------------------------------------------------------
export type HUDClockInstance = {
    Container: Frame,
    SetDay: (day: number) -> (),
    SetTime: (hour: number, phase: string, progress: number) -> (),
    Destroy: () -> (),
}

function UIComponents.CreateHUDClock(parent: Instance): HUDClockInstance
    local container = Instance.new("Frame")
    container.Name = "HUDClock"
    container.Size = UDim2.fromOffset(260, 48)
    container.Position = UDim2.new(0.5, 0, 0, 16)
    container.AnchorPoint = Vector2.new(0.5, 0)
    container.BackgroundColor3 = UITheme.Colors.SurfaceElevated
    container.BackgroundTransparency = 0.15
    container.BorderSizePixel = 0
    container.ZIndex = 50
    container.Parent = parent

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 10)
    corner.Parent = container

    local stroke = Instance.new("UIStroke")
    stroke.Color = UITheme.Colors.BorderSubtle
    stroke.Thickness = 1.2
    stroke.Parent = container

    local topRow = Instance.new("Frame")
    topRow.Name = "TopRow"
    topRow.Size = UDim2.new(1, -20, 1, -8)
    topRow.Position = UDim2.fromOffset(10, 3)
    topRow.BackgroundTransparency = 1
    topRow.ZIndex = 51
    topRow.Parent = container

    local dayLabel = Instance.new("TextLabel")
    dayLabel.Name = "DayLabel"
    dayLabel.Size = UDim2.new(0.32, 0, 1, 0)
    dayLabel.BackgroundTransparency = 1
    dayLabel.Font = UITheme.Fonts.Heading
    dayLabel.Text = "DAY 0"
    dayLabel.TextColor3 = UITheme.Colors.TextPrimary
    dayLabel.TextSize = 13
    dayLabel.TextXAlignment = Enum.TextXAlignment.Left
    dayLabel.ZIndex = 52
    dayLabel.Parent = topRow

    local phasePill = Instance.new("Frame")
    phasePill.Name = "PhasePill"
    phasePill.Size = UDim2.fromOffset(96, 22)
    phasePill.Position = UDim2.fromScale(0.5, 0.5)
    phasePill.AnchorPoint = Vector2.new(0.5, 0.5)
    phasePill.BackgroundColor3 = UITheme.Colors.Void
    phasePill.BorderSizePixel = 0
    phasePill.ZIndex = 52
    phasePill.Parent = topRow

    local pillCorner = Instance.new("UICorner")
    pillCorner.CornerRadius = UDim.new(1, 0)
    pillCorner.Parent = phasePill

    local pillStroke = Instance.new("UIStroke")
    pillStroke.Color = UITheme.Colors.EmberHot
    pillStroke.Thickness = 1
    pillStroke.Parent = phasePill

    local phaseText = Instance.new("TextLabel")
    phaseText.Name = "PhaseText"
    phaseText.Size = UDim2.fromScale(1, 1)
    phaseText.BackgroundTransparency = 1
    phaseText.Font = UITheme.Fonts.Tag
    phaseText.Text = "☀️ DAY"
    phaseText.TextColor3 = UITheme.Colors.EmberGold
    phaseText.TextSize = 10
    phaseText.ZIndex = 53
    phaseText.Parent = phasePill

    local timeLabel = Instance.new("TextLabel")
    timeLabel.Name = "TimeLabel"
    timeLabel.Size = UDim2.new(0.32, 0, 1, 0)
    timeLabel.Position = UDim2.fromScale(1, 0)
    timeLabel.AnchorPoint = Vector2.new(1, 0)
    timeLabel.BackgroundTransparency = 1
    timeLabel.Font = UITheme.Fonts.Heading
    timeLabel.Text = "08:00"
    timeLabel.TextColor3 = UITheme.Colors.EmberHot
    timeLabel.TextSize = 13
    timeLabel.TextXAlignment = Enum.TextXAlignment.Right
    timeLabel.ZIndex = 52
    timeLabel.Parent = topRow

    local progressTrack = Instance.new("Frame")
    progressTrack.Name = "ProgressTrack"
    progressTrack.Size = UDim2.new(1, 0, 0, 3)
    progressTrack.Position = UDim2.fromScale(0, 1)
    progressTrack.AnchorPoint = Vector2.new(0, 1)
    progressTrack.BackgroundColor3 = UITheme.Colors.Void
    progressTrack.BorderSizePixel = 0
    progressTrack.ZIndex = 52
    progressTrack.Parent = container

    local progressFill = Instance.new("Frame")
    progressFill.Name = "ProgressFill"
    progressFill.Size = UDim2.fromScale(0, 1)
    progressFill.BackgroundColor3 = UITheme.Colors.EmberHot
    progressFill.BorderSizePixel = 0
    progressFill.ZIndex = 53
    progressFill.Parent = progressTrack

    local function setDay(day: number)
        dayLabel.Text = string.format("DAY %d", day)
    end

    local function setTime(hour: number, phase: string, progress: number)
        local h = math.floor(hour)
        local m = math.floor((hour - h) * 60)
        timeLabel.Text = string.format("%02d:%02d", h, m)

        local phaseIcons = {
            Dawn = "🌅 DAWN",
            Day = "☀️ DAY",
            Dusk = "🌆 DUSK",
            Night = "🌙 NIGHT",
        }
        local phaseColors = {
            Dawn = Color3.fromRGB(240, 140, 80),
            Day = UITheme.Colors.EmberGold,
            Dusk = Color3.fromRGB(220, 70, 50),
            Night = Color3.fromRGB(130, 140, 190),
        }
        phaseText.Text = phaseIcons[phase] or phase:upper()
        local color = phaseColors[phase] or UITheme.Colors.EmberHot
        phaseText.TextColor3 = color
        pillStroke.Color = color
        progressFill.BackgroundColor3 = color
        progressFill.Size = UDim2.fromScale(math.clamp(progress, 0, 1), 1)
    end

    return {
        Container = container,
        SetDay = setDay,
        SetTime = setTime,
        Destroy = function()
            container:Destroy()
        end,
    }
end

--------------------------------------------------------------------------------
-- 11. GENSHIN IMPACT STYLE STAMINA BAR (Right-Side Curved Arc)
--------------------------------------------------------------------------------
export type GenshinStaminaInstance = {
    Billboard: BillboardGui,
    SetStamina: (current: number, max: number, isSprinting: boolean) -> (),
    Destroy: () -> (),
}

function UIComponents.CreateGenshinStaminaBar(character: Model): GenshinStaminaInstance
    local rootPart = character:WaitForChild("HumanoidRootPart", 5) :: BasePart?
    local billboard = Instance.new("BillboardGui")
    billboard.Name = "GenshinStaminaBar"
    billboard.Size = UDim2.fromOffset(60, 130)
    billboard.StudsOffsetWorldSpace = Vector3.new(1.8, 0.4, 0)
    billboard.AlwaysOnTop = true
    billboard.ResetOnSpawn = false
    billboard.Enabled = false
    billboard.Parent = character

    if rootPart then
        billboard.Adornee = rootPart
    end

    local NUM_SEGMENTS = 6
    local segments: { { Box: Frame, Fill: Frame } } = {}

    -- Arc coordinates bending gently to the right like Genshin Impact
    local ARC_OFFSETS = {
        { X = 12, Y = 6, Rot = 18 },
        { X = 20, Y = 26, Rot = 10 },
        { X = 24, Y = 48, Rot = 0 },
        { X = 24, Y = 70, Rot = 0 },
        { X = 20, Y = 92, Rot = -10 },
        { X = 12, Y = 112, Rot = -18 },
    }

    for i = 1, NUM_SEGMENTS do
        local coord = ARC_OFFSETS[i]
        local box = Instance.new("Frame")
        box.Name = "Segment_" .. i
        box.Size = UDim2.fromOffset(8, 17)
        box.Position = UDim2.fromOffset(coord.X, coord.Y)
        box.Rotation = coord.Rot
        box.BackgroundColor3 = Color3.fromRGB(34, 26, 22) -- Dark Genshin track
        box.BorderSizePixel = 0
        box.ZIndex = 80
        box.Parent = billboard

        local boxCorner = Instance.new("UICorner")
        boxCorner.CornerRadius = UDim.new(0, 3)
        boxCorner.Parent = box

        local boxStroke = Instance.new("UIStroke")
        boxStroke.Color = Color3.fromRGB(18, 12, 10)
        boxStroke.Thickness = 1
        boxStroke.Parent = box

        local fill = Instance.new("Frame")
        fill.Name = "Fill"
        fill.Size = UDim2.fromScale(1, 1)
        fill.Position = UDim2.fromScale(0, 1)
        fill.AnchorPoint = Vector2.new(0, 1)
        fill.BackgroundColor3 = UITheme.Colors.EmberGold
        fill.BorderSizePixel = 0
        fill.ZIndex = 81
        fill.Parent = box

        local fillCorner = Instance.new("UICorner")
        fillCorner.CornerRadius = UDim.new(0, 3)
        fillCorner.Parent = fill

        local fillGrad = Instance.new("UIGradient")
        fillGrad.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 225, 120)),
            ColorSequenceKeypoint.new(1, UITheme.Colors.EmberGold),
        })
        fillGrad.Rotation = 90
        fillGrad.Parent = fill

        table.insert(segments, { Box = box, Fill = fill })
    end

    local isVisible = false
    local hideTimer: thread? = nil

    local function setStamina(current: number, max: number, isSprinting: boolean)
        local ratio = math.clamp(current / math.max(max, 1), 0, 1)

        -- Visibility logic: show while sprinting or stamina drained
        if ratio < 0.999 or isSprinting then
            if hideTimer then
                task.cancel(hideTimer)
                hideTimer = nil
            end
            if not isVisible then
                isVisible = true
                billboard.Enabled = true
            end
        else
            -- Fade out after full recovery
            if isVisible and not hideTimer then
                hideTimer = task.delay(0.5, function()
                    billboard.Enabled = false
                    isVisible = false
                    hideTimer = nil
                end)
            end
        end

        local fillColor = (ratio < 0.22) and UITheme.Colors.EmberCrimson or UITheme.Colors.EmberGold
        local segmentSpan = 1 / NUM_SEGMENTS

        -- Fill segments sequentially from bottom (segment 6) to top (segment 1)
        for i = 1, NUM_SEGMENTS do
            local segIndex = NUM_SEGMENTS - i + 1
            local segMin = (i - 1) * segmentSpan
            local segRatio = math.clamp((ratio - segMin) / segmentSpan, 0, 1)

            local seg = segments[segIndex]
            seg.Fill.Size = UDim2.fromScale(1, segRatio)
            seg.Fill.BackgroundColor3 = fillColor
        end
    end

    return {
        Billboard = billboard,
        SetStamina = setStamina,
        Destroy = function()
            if hideTimer then
                task.cancel(hideTimer)
            end
            billboard:Destroy()
        end,
    }
end

--------------------------------------------------------------------------------
-- 12. BOTTOM HOTBAR COMPONENT (3 QuickSlots)
--------------------------------------------------------------------------------
export type HotbarSlotData = {
    Id: string,
    Name: string,
    Count: number,
    IconText: string,
    Category: string,
}

export type HotbarInstance = {
    Container: Frame,
    SelectSlot: (slotIndex: number) -> (),
    SetSlotItem: (slotIndex: number, item: HotbarSlotData?) -> (),
    GetSelectedSlot: () -> number,
    Destroy: () -> (),
}

function UIComponents.CreateHotbar(parent: Instance, onSelected: ((slotIndex: number) -> ())?): HotbarInstance
    local container = Instance.new("Frame")
    container.Name = "HUDHotbar"
    container.Size = UDim2.fromOffset(230, 72)
    container.Position = UDim2.new(0.5, 0, 1, -22)
    container.AnchorPoint = Vector2.new(0.5, 1)
    container.BackgroundTransparency = 1
    container.ZIndex = 50
    container.Parent = parent

    local listLayout = Instance.new("UIListLayout")
    listLayout.FillDirection = Enum.FillDirection.Horizontal
    listLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    listLayout.VerticalAlignment = Enum.VerticalAlignment.Center
    listLayout.Padding = UDim.new(0, 10)
    listLayout.Parent = container

    local selectedSlot = 1
    local slotFrames: { [number]: { Box: TextButton, Stroke: UIStroke, Icon: TextLabel, Name: TextLabel, Count: TextLabel } } = {}

    for i = 1, 3 do
        local box = Instance.new("TextButton")
        box.Name = "Slot_" .. i
        box.Size = UDim2.fromOffset(64, 64)
        box.BackgroundColor3 = (i == selectedSlot) and UITheme.Colors.SurfaceHighlight or UITheme.Colors.SurfaceElevated
        box.BackgroundTransparency = 0.2
        box.AutoButtonColor = false
        box.Text = ""
        box.ZIndex = 51
        box.Parent = container

        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 8)
        corner.Parent = box

        local stroke = Instance.new("UIStroke")
        stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
        stroke.Color = (i == selectedSlot) and UITheme.Colors.EmberHot or UITheme.Colors.BorderSubtle
        stroke.Thickness = (i == selectedSlot) and 2.0 or 1.0
        stroke.Parent = box

        local keyTag = Instance.new("TextLabel")
        keyTag.Name = "KeyTag"
        keyTag.Size = UDim2.fromOffset(16, 14)
        keyTag.Position = UDim2.fromOffset(6, 4)
        keyTag.BackgroundTransparency = 1
        keyTag.Font = UITheme.Fonts.Tag
        keyTag.Text = tostring(i)
        keyTag.TextColor3 = UITheme.Colors.TextMuted
        keyTag.TextSize = 10
        keyTag.ZIndex = 52
        keyTag.Parent = box

        local icon = Instance.new("TextLabel")
        icon.Name = "Icon"
        icon.Size = UDim2.new(1, 0, 0, 28)
        icon.Position = UDim2.fromOffset(0, 12)
        icon.BackgroundTransparency = 1
        icon.Font = UITheme.Fonts.Heading
        icon.Text = ""
        icon.TextColor3 = UITheme.Colors.TextPrimary
        icon.TextSize = 22
        icon.ZIndex = 52
        icon.Parent = box

        local nameLbl = Instance.new("TextLabel")
        nameLbl.Name = "ItemName"
        nameLbl.Size = UDim2.new(1, -6, 0, 12)
        nameLbl.Position = UDim2.new(0, 3, 1, -16)
        nameLbl.BackgroundTransparency = 1
        nameLbl.Font = UITheme.Fonts.Body
        nameLbl.Text = ""
        nameLbl.TextColor3 = UITheme.Colors.TextSecondary
        nameLbl.TextSize = 8
        nameLbl.TextTruncate = Enum.TextTruncate.AtEnd
        nameLbl.ZIndex = 52
        nameLbl.Parent = box

        local countBadge = Instance.new("TextLabel")
        countBadge.Name = "CountBadge"
        countBadge.Size = UDim2.fromOffset(22, 14)
        countBadge.Position = UDim2.new(1, -4, 1, -4)
        countBadge.AnchorPoint = Vector2.new(1, 1)
        countBadge.BackgroundColor3 = UITheme.Colors.Void
        countBadge.BackgroundTransparency = 0.2
        countBadge.Font = UITheme.Fonts.Tag
        countBadge.Text = ""
        countBadge.TextColor3 = UITheme.Colors.EmberGold
        countBadge.TextSize = 9
        countBadge.Visible = false
        countBadge.ZIndex = 53
        countBadge.Parent = box

        local badgeCorner = Instance.new("UICorner")
        badgeCorner.CornerRadius = UDim.new(0, 4)
        badgeCorner.Parent = countBadge

        slotFrames[i] = {
            Box = box,
            Stroke = stroke,
            Icon = icon,
            Name = nameLbl,
            Count = countBadge,
        }

        box.Activated:Connect(function()
            selectedSlot = i
            for idx, sf in pairs(slotFrames) do
                local isCur = (idx == selectedSlot)
                TweenService:Create(sf.Stroke, UITheme.Tweens.Fast, {
                    Color = isCur and UITheme.Colors.EmberHot or UITheme.Colors.BorderSubtle,
                    Thickness = isCur and 2.0 or 1.0,
                }):Play()
                TweenService:Create(sf.Box, UITheme.Tweens.Fast, {
                    BackgroundColor3 = isCur and UITheme.Colors.SurfaceHighlight or UITheme.Colors.SurfaceElevated,
                }):Play()
            end
            if onSelected then
                onSelected(selectedSlot)
            end
        end)
    end

    local function selectSlot(index: number)
        if index < 1 or index > 3 then return end
        selectedSlot = index
        for idx, sf in pairs(slotFrames) do
            local isCur = (idx == selectedSlot)
            sf.Stroke.Color = isCur and UITheme.Colors.EmberHot or UITheme.Colors.BorderSubtle
            sf.Stroke.Thickness = isCur and 2.0 or 1.0
            sf.Box.BackgroundColor3 = isCur and UITheme.Colors.SurfaceHighlight or UITheme.Colors.SurfaceElevated
        end
        if onSelected then
            onSelected(selectedSlot)
        end
    end

    local function setSlotItem(index: number, item: HotbarSlotData?)
        local sf = slotFrames[index]
        if not sf then return end
        if item then
            sf.Icon.Text = item.IconText
            sf.Name.Text = item.Name
            if item.Count > 1 then
                sf.Count.Text = "x" .. item.Count
                sf.Count.Visible = true
            else
                sf.Count.Visible = false
            end
        else
            sf.Icon.Text = ""
            sf.Name.Text = ""
            sf.Count.Visible = false
        end
    end

    return {
        Container = container,
        SelectSlot = selectSlot,
        SetSlotItem = setSlotItem,
        GetSelectedSlot = function() return selectedSlot end,
        Destroy = function()
            container:Destroy()
        end,
    }
end

--------------------------------------------------------------------------------
-- 13. IN-GAME PAUSE MENU COMPONENT (ESC / M)
--------------------------------------------------------------------------------
export type PauseMenuCallbacks = {
    OnResume: () -> (),
    OnSettings: () -> (),
    OnQuit: () -> (),
}

export type PauseMenuInstance = {
    Backdrop: TextButton,
    Open: () -> (),
    Close: () -> (),
    Destroy: () -> (),
}

function UIComponents.CreatePauseMenu(parent: Instance, callbacks: PauseMenuCallbacks): PauseMenuInstance
    local backdrop = Instance.new("TextButton")
    backdrop.Name = "InGamePauseBackdrop"
    backdrop.Size = UDim2.fromScale(1, 1)
    backdrop.BackgroundColor3 = UITheme.Colors.PureBlack
    backdrop.BackgroundTransparency = 1
    backdrop.AutoButtonColor = false
    backdrop.Text = ""
    backdrop.Visible = false
    backdrop.ZIndex = 90
    backdrop.Parent = parent

    local card = Instance.new("Frame")
    card.Name = "PauseCard"
    card.Size = UDim2.new(0.9, 0, 0.85, 0)
    card.Position = UDim2.fromScale(0.5, 0.52)
    card.AnchorPoint = Vector2.new(0.5, 0.5)
    card.BackgroundColor3 = UITheme.Colors.SurfaceElevated
    card.BorderSizePixel = 0
    card.ZIndex = 91
    card.Parent = backdrop

    local cardConstraint = Instance.new("UISizeConstraint")
    cardConstraint.MaxSize = Vector2.new(380, 420)
    cardConstraint.MinSize = Vector2.new(280, 320)
    cardConstraint.Parent = card

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 12)
    corner.Parent = card

    local stroke = Instance.new("UIStroke")
    stroke.Color = UITheme.Colors.BorderSubtle
    stroke.Thickness = 1.4
    stroke.Parent = card

    local cardPadding = Instance.new("UIPadding")
    cardPadding.PaddingTop = UDim.new(0, 24)
    cardPadding.PaddingBottom = UDim.new(0, 24)
    cardPadding.PaddingLeft = UDim.new(0, 28)
    cardPadding.PaddingRight = UDim.new(0, 28)
    cardPadding.Parent = card

    local titleLayout = Instance.new("UIListLayout")
    titleLayout.FillDirection = Enum.FillDirection.Vertical
    titleLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    titleLayout.Padding = UDim.new(0, 14)
    titleLayout.Parent = card

    local tagLbl = Instance.new("TextLabel")
    tagLbl.Name = "CategoryTag"
    tagLbl.Size = UDim2.new(1, 0, 0, 14)
    tagLbl.BackgroundTransparency = 1
    tagLbl.Font = UITheme.Fonts.Tag
    tagLbl.Text = "[ SURVIVAL SECTOR PAUSED ]"
    tagLbl.TextColor3 = UITheme.Colors.EmberHot
    tagLbl.TextSize = 10
    tagLbl.ZIndex = 92
    tagLbl.Parent = card

    local titleLbl = Instance.new("TextLabel")
    titleLbl.Name = "Title"
    titleLbl.Size = UDim2.new(1, 0, 0, 26)
    titleLbl.BackgroundTransparency = 1
    titleLbl.Font = UITheme.Fonts.Heading
    titleLbl.Text = "DON'T LET THE FIRE DIE"
    titleLbl.TextColor3 = UITheme.Colors.TextPrimary
    titleLbl.TextSize = 18
    titleLbl.ZIndex = 92
    titleLbl.Parent = card

    UIComponents.CreateDivider(card)

    local function createMenuBtn(text: string, isPrimary: boolean, onClick: () -> ())
        local btn = Instance.new("TextButton")
        btn.Name = "Btn_" .. text:gsub("%s+", "")
        btn.Size = UDim2.new(1, 0, 0, 44)
        btn.BackgroundColor3 = isPrimary and UITheme.Colors.EmberPrimary or UITheme.Colors.Surface
        btn.AutoButtonColor = false
        btn.Font = UITheme.Fonts.Heading
        btn.Text = text
        btn.TextColor3 = isPrimary and UITheme.Colors.PureWhite or UITheme.Colors.TextPrimary
        btn.TextSize = 13
        btn.ZIndex = 93
        btn.Parent = card

        local btnCorner = Instance.new("UICorner")
        btnCorner.CornerRadius = UDim.new(0, 8)
        btnCorner.Parent = btn

        local btnStroke = Instance.new("UIStroke")
        btnStroke.Color = isPrimary and UITheme.Colors.BorderActive or UITheme.Colors.BorderHairline
        btnStroke.Thickness = 1
        btnStroke.Parent = btn

        btn.MouseEnter:Connect(function()
            TweenService:Create(btn, UITheme.Tweens.Fast, {
                BackgroundColor3 = isPrimary and UITheme.Colors.EmberHot or UITheme.Colors.SurfaceHighlight,
            }):Play()
        end)
        btn.MouseLeave:Connect(function()
            TweenService:Create(btn, UITheme.Tweens.Fast, {
                BackgroundColor3 = isPrimary and UITheme.Colors.EmberPrimary or UITheme.Colors.Surface,
            }):Play()
        end)
        btn.Activated:Connect(onClick)
    end

    local isBusy = false

    local function openMenu()
        if isBusy then return end
        isBusy = true
        backdrop.Visible = true
        card.Position = UDim2.fromScale(0.5, 0.52)
        TweenService:Create(backdrop, UITheme.Tweens.Fast, { BackgroundTransparency = 0.55 }):Play()
        local cardTween = TweenService:Create(card, UITheme.Tweens.Fast, { Position = UDim2.fromScale(0.5, 0.5) })
        cardTween.Completed:Connect(function() isBusy = false end)
        cardTween:Play()
    end

    local function closeMenu()
        if isBusy then return end
        isBusy = true
        TweenService:Create(backdrop, UITheme.Tweens.Fast, { BackgroundTransparency = 1 }):Play()
        local cardTween = TweenService:Create(card, UITheme.Tweens.Fast, { Position = UDim2.fromScale(0.5, 0.52) })
        cardTween.Completed:Connect(function()
            backdrop.Visible = false
            isBusy = false
        end)
        cardTween:Play()
    end

    createMenuBtn("RESUME GAME", true, function()
        closeMenu()
        callbacks.OnResume()
    end)

    createMenuBtn("SETTINGS", false, function()
        callbacks.OnSettings()
    end)

    createMenuBtn("QUIT TO MAIN MENU", false, function()
        closeMenu()
        callbacks.OnQuit()
    end)

    return {
        Backdrop = backdrop,
        Open = openMenu,
        Close = closeMenu,
        Destroy = function()
            backdrop:Destroy()
        end,
    }
end

return UIComponents
