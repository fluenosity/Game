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
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local SocialService = game:GetService("SocialService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UITheme = require(script.Parent:WaitForChild("UITheme"))
local sharedFolder = ReplicatedStorage:WaitForChild("FluenosityShared")
local IconPack = require(sharedFolder:WaitForChild("IconPack"))
local AudioManager = require(script.Parent:WaitForChild("AudioManager"))

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

    -- Large Oswald / Gothic Bold Text Label
    local textLabel = Instance.new("TextLabel")
    textLabel.Name = "Label"
    textLabel.Size = UDim2.new(1, 0, 0, isPrimary and 38 or 30)
    textLabel.Position = UDim2.new(0, 0, 0, 0)
    textLabel.BackgroundTransparency = 1
    textLabel.Font = Enum.Font.Oswald
    textLabel.Text = config.Text
    textLabel.TextColor3 = isPrimary and Color3.fromRGB(255, 175, 65) or Color3.fromRGB(215, 218, 225)
    textLabel.TextSize = isPrimary and 38 or 28
    textLabel.TextXAlignment = Enum.TextXAlignment.Center
    textLabel.TextYAlignment = Enum.TextYAlignment.Center
    textLabel.TextStrokeColor3 = Color3.fromRGB(10, 8, 6)
    textLabel.TextStrokeTransparency = 0.35
    textLabel.ZIndex = 13
    textLabel.Parent = contentFrame

    -- Horizontal Glowing Flare Underline (Primary has it visible by default; others reveal on hover)
    local flareLine = Instance.new("Frame")
    flareLine.Name = "GlowFlare"
    flareLine.Size = UDim2.new(0, isPrimary and 240 or 200, 0, 2)
    flareLine.Position = UDim2.new(0.5, 0, 1, -2)
    flareLine.AnchorPoint = Vector2.new(0.5, 0)
    flareLine.BackgroundColor3 = Color3.fromRGB(255, 185, 75)
    flareLine.BorderSizePixel = 0
    flareLine.BackgroundTransparency = isPrimary and 0 or 1
    flareLine.ZIndex = 12
    flareLine.Parent = contentFrame

    local flareGrad = Instance.new("UIGradient")
    flareGrad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(200, 100, 20)),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 245, 190)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(200, 100, 20)),
    })
    flareGrad.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 1),
        NumberSequenceKeypoint.new(0.25, 0.45),
        NumberSequenceKeypoint.new(0.5, 0),
        NumberSequenceKeypoint.new(0.75, 0.45),
        NumberSequenceKeypoint.new(1, 1),
    })
    flareGrad.Parent = flareLine

    -- Center light flare pip
    local flarePip = Instance.new("Frame")
    flarePip.Name = "CenterPip"
    flarePip.Size = UDim2.fromOffset(6, 6)
    flarePip.Position = UDim2.fromScale(0.5, 0.5)
    flarePip.AnchorPoint = Vector2.new(0.5, 0.5)
    flarePip.BackgroundColor3 = Color3.fromRGB(255, 250, 230)
    flarePip.BackgroundTransparency = isPrimary and 0 or 1
    flarePip.BorderSizePixel = 0
    flarePip.ZIndex = 13
    flarePip.Parent = flareLine

    local pipCorner = Instance.new("UICorner")
    pipCorner.CornerRadius = UDim.new(1, 0)
    pipCorner.Parent = flarePip

    local pipAura = Instance.new("Frame")
    pipAura.Name = "PipAura"
    pipAura.Size = UDim2.fromOffset(20, 10)
    pipAura.Position = UDim2.fromScale(0.5, 0.5)
    pipAura.AnchorPoint = Vector2.new(0.5, 0.5)
    pipAura.BackgroundColor3 = Color3.fromRGB(255, 180, 50)
    pipAura.BackgroundTransparency = isPrimary and 0.55 or 1
    pipAura.BorderSizePixel = 0
    pipAura.ZIndex = 12
    pipAura.Parent = flareLine

    local auraCorner = Instance.new("UICorner")
    auraCorner.CornerRadius = UDim.new(1, 0)
    auraCorner.Parent = pipAura

    -- Interactive Hover & Press Animations
    button.MouseEnter:Connect(function()
        AudioManager.Play("Hover")
        TweenService:Create(textLabel, UITheme.Tweens.Fast, {
            TextColor3 = Color3.fromRGB(255, 195, 80),
            TextSize = isPrimary and 40 or 30,
        }):Play()

        TweenService:Create(flareLine, UITheme.Tweens.Fast, {
            BackgroundTransparency = 0,
            Size = UDim2.new(0, 240, 0, 2),
        }):Play()
        TweenService:Create(flarePip, UITheme.Tweens.Fast, { BackgroundTransparency = 0 }):Play()
        TweenService:Create(pipAura, UITheme.Tweens.Fast, { BackgroundTransparency = 0.5 }):Play()
    end)

    button.MouseLeave:Connect(function()
        TweenService:Create(textLabel, UITheme.Tweens.Fast, {
            TextColor3 = isPrimary and Color3.fromRGB(255, 175, 65) or Color3.fromRGB(215, 218, 225),
            TextSize = isPrimary and 38 or 28,
        }):Play()

        if not isPrimary then
            TweenService:Create(flareLine, UITheme.Tweens.Fast, {
                BackgroundTransparency = 1,
                Size = UDim2.new(0, 200, 0, 2),
            }):Play()
            TweenService:Create(flarePip, UITheme.Tweens.Fast, { BackgroundTransparency = 1 }):Play()
            TweenService:Create(pipAura, UITheme.Tweens.Fast, { BackgroundTransparency = 1 }):Play()
        else
            TweenService:Create(flareLine, UITheme.Tweens.Fast, {
                BackgroundTransparency = 0,
                Size = UDim2.new(0, 240, 0, 2),
            }):Play()
        end
    end)

    button.Activated:Connect(function()
        AudioManager.Play("Click")
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
        AudioManager.Play("Hover")
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

    btnBack.MouseEnter:Connect(function()
        AudioManager.Play("Hover")
    end)

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
        AudioManager.Play("Click")
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
        AudioManager.Play("Click")
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
    MinValue: number?,
    MaxValue: number?,
    Step: number?,
    ValueFormat: ((value: number) -> string)?,
    Parent: Instance,
    OnChanged: (value: number) -> (),
}

function UIComponents.CreateSlider(config: SliderConfig): Frame
    local minVal = config.MinValue or 0
    local maxVal = config.MaxValue or 1
    local step = config.Step or ((maxVal - minVal) * 0.05)
    local currentValue = math.clamp(config.InitialValue, minVal, maxVal)

    local function getNormalized(val: number): number
        if maxVal <= minVal then return 0 end
        return math.clamp((val - minVal) / (maxVal - minVal), 0, 1)
    end

    local function formatVal(val: number): string
        if config.ValueFormat then
            return config.ValueFormat(val)
        elseif maxVal == 1 and minVal == 0 then
            return string.format("%d%%", math.round(val * 100))
        else
            return string.format("%.1f", val)
        end
    end

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
    valuePill.Text = formatVal(currentValue)
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
    fill.Size = UDim2.fromScale(getNormalized(currentValue), 1)
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
        currentValue = math.clamp(val, minVal, maxVal)
        fill.Size = UDim2.fromScale(getNormalized(currentValue), 1)
        valuePill.Text = formatVal(currentValue)
        config.OnChanged(currentValue)
    end

    btnMinus.Activated:Connect(function()
        setValue(currentValue - step)
    end)

    btnPlus.Activated:Connect(function()
        setValue(currentValue + step)
    end)

    local isDragging = false

    local function updateFromInput(input)
        if track.AbsoluteSize.X > 0 then
            local relative = math.clamp((input.Position.X - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
            setValue(minVal + (relative * (maxVal - minVal)))
        end
    end

    track.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            isDragging = true
            updateFromInput(input)
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if isDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            updateFromInput(input)
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
    container.Size = UDim2.fromOffset(280, 36)
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
    statusLabel.Size = UDim2.new(1, -38, 1, 0)
    statusLabel.Position = UDim2.new(0, 38, 0, 0)
    statusLabel.BackgroundTransparency = 1
    statusLabel.Font = UITheme.Fonts.Tag
    statusLabel.Text = initialStatus or "LOADING SECTOR..."
    statusLabel.TextColor3 = Color3.fromRGB(225, 230, 240)
    statusLabel.TextSize = 11
    statusLabel.TextXAlignment = Enum.TextXAlignment.Left
    statusLabel.ZIndex = 86
    statusLabel.Parent = container

    -- High-precision smooth continuous rotation via RenderStepped (avoids TweenService loop lock)
    local spinConn: RBXScriptConnection? = RunService.RenderStepped:Connect(function(dt: number)
        ring.Rotation = (ring.Rotation + dt * 240) % 360
    end)

    -- Subtle breathing pulse on the center dot
    local dotPulse = TweenService:Create(centerDot, TweenInfo.new(0.85, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {
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
            if spinConn then
                spinConn:Disconnect()
                spinConn = nil
            end
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
    -- Using native Frame (NEVER CanvasGroup, which downsamples & blurs fullscreen text/assets in Roblox!)
    local container = Instance.new("Frame")
    container.Name = "CinematicLoadingScreen"
    container.Size = UDim2.fromScale(1, 1)
    container.Position = UDim2.fromScale(0, 0)
    container.BackgroundColor3 = Color3.fromRGB(6, 7, 9)
    container.BorderSizePixel = 0
    container.Visible = false
    container.ZIndex = 80
    container.Parent = parent

    -- 1. Fullscreen Wallpaper Image (Identical to Main Menu art - native resolution)
    local bgImage = Instance.new("ImageLabel")
    bgImage.Name = "BackgroundImage"
    bgImage.Size = UDim2.fromScale(1, 1)
    bgImage.Position = UDim2.fromScale(0.5, 0.5)
    bgImage.AnchorPoint = Vector2.new(0.5, 0.5)
    bgImage.BackgroundTransparency = 1
    bgImage.Image = UITheme.GetBackgroundAsset()
    bgImage.ScaleType = Enum.ScaleType.Crop
    bgImage.ImageTransparency = 0.16 -- Crisp high-contrast art
    bgImage.ZIndex = 81
    bgImage.Parent = container

    -- 2. Dark Shading Overlay / Vignette
    local bgOverlay = Instance.new("Frame")
    bgOverlay.Name = "BgOverlay"
    bgOverlay.Size = UDim2.fromScale(1, 1)
    bgOverlay.BackgroundColor3 = Color3.fromRGB(6, 7, 10)
    bgOverlay.BackgroundTransparency = 0.32
    bgOverlay.BorderSizePixel = 0
    bgOverlay.ZIndex = 82
    bgOverlay.Parent = container

    local vigGrad = Instance.new("UIGradient")
    vigGrad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 0, 0)),
        ColorSequenceKeypoint.new(0.55, Color3.fromRGB(10, 12, 16)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(2, 3, 5)),
    })
    vigGrad.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.22),
        NumberSequenceKeypoint.new(0.5, 0.45),
        NumberSequenceKeypoint.new(1, 0.18),
    })
    vigGrad.Rotation = 90
    vigGrad.Parent = bgOverlay

    -- 3. Top-Right Content Banner with "Left Faded to Right" Gradient Background
    local topRightBanner = Instance.new("Frame")
    topRightBanner.Name = "TopRightBanner"
    topRightBanner.Size = UDim2.fromOffset(450, 86)
    topRightBanner.Position = UDim2.new(1, -32, 0, 32)
    topRightBanner.AnchorPoint = Vector2.new(1, 0)
    topRightBanner.BackgroundColor3 = Color3.fromRGB(8, 10, 14)
    topRightBanner.BorderSizePixel = 0
    topRightBanner.ZIndex = 83
    topRightBanner.Parent = container

    local bannerCorner = Instance.new("UICorner")
    bannerCorner.CornerRadius = UDim.new(0, 8)
    bannerCorner.Parent = topRightBanner

    -- "Left Faded to Right" Horizontal Gradient Background
    local bannerGrad = Instance.new("UIGradient")
    bannerGrad.Rotation = 0 -- Horizontal (left to right)
    bannerGrad.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 1.0),    -- Fully transparent on left
        NumberSequenceKeypoint.new(0.25, 0.45), -- Smooth soft fade
        NumberSequenceKeypoint.new(0.65, 0.15), -- Deep glass
        NumberSequenceKeypoint.new(1, 0.05),   -- Solid dark black on right edge
    })
    bannerGrad.Parent = topRightBanner

    local bannerStroke = Instance.new("UIStroke")
    bannerStroke.Color = Color3.fromRGB(255, 190, 80)
    bannerStroke.Transparency = 0.90
    bannerStroke.Thickness = 1
    bannerStroke.Parent = topRightBanner

    local strokeGrad = Instance.new("UIGradient")
    strokeGrad.Rotation = 0
    strokeGrad.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 1.0),
        NumberSequenceKeypoint.new(0.35, 0.95),
        NumberSequenceKeypoint.new(1, 0.82),
    })
    strokeGrad.Parent = bannerStroke

    local bannerPadding = Instance.new("UIPadding")
    bannerPadding.PaddingTop = UDim.new(0, 12)
    bannerPadding.PaddingBottom = UDim.new(0, 12)
    bannerPadding.PaddingLeft = UDim.new(0, 26)
    bannerPadding.PaddingRight = UDim.new(0, 22)
    bannerPadding.Parent = topRightBanner

    local headerRow = Instance.new("Frame")
    headerRow.Name = "TipHeaderRow"
    headerRow.Size = UDim2.new(1, 0, 0, 16)
    headerRow.BackgroundTransparency = 1
    headerRow.ZIndex = 84
    headerRow.Parent = topRightBanner

    local tipIcon = IconPack.CreateIcon("radio", 13, Color3.fromRGB(245, 160, 40), 0)
    tipIcon.Position = UDim2.fromOffset(0, 1)
    tipIcon.ZIndex = 85
    tipIcon.Parent = headerRow

    local tipHeader = Instance.new("TextLabel")
    tipHeader.Name = "TipHeader"
    tipHeader.Size = UDim2.new(1, -20, 1, 0)
    tipHeader.Position = UDim2.fromOffset(20, 0)
    tipHeader.BackgroundTransparency = 1
    tipHeader.Font = UITheme.Fonts.Heading
    tipHeader.Text = "SURVIVAL INTEL"
    tipHeader.TextColor3 = Color3.fromRGB(245, 160, 40) -- Luminous ember amber
    tipHeader.TextSize = 12
    tipHeader.TextXAlignment = Enum.TextXAlignment.Left
    tipHeader.ZIndex = 85
    tipHeader.Parent = headerRow

    local tipBody = Instance.new("TextLabel")
    tipBody.Name = "TipBody"
    tipBody.Size = UDim2.new(1, 0, 0, 44)
    tipBody.Position = UDim2.new(0, 0, 0, 20)
    tipBody.BackgroundTransparency = 1
    tipBody.Font = UITheme.Fonts.Body
    tipBody.Text = SURVIVAL_TIPS[math.random(1, #SURVIVAL_TIPS)]
    tipBody.TextColor3 = Color3.fromRGB(225, 230, 240)
    tipBody.TextSize = 13
    tipBody.TextWrapped = true
    tipBody.TextXAlignment = Enum.TextXAlignment.Left
    tipBody.ZIndex = 84
    tipBody.Parent = topRightBanner

    -- 4. Center-Bottom Glowing Progress Bar HUD (Production Grade)
    local progressHUD = Instance.new("Frame")
    progressHUD.Name = "ProgressHUD"
    progressHUD.Size = UDim2.new(0.68, 0, 0, 68)
    progressHUD.Position = UDim2.new(0.5, 0, 1, -48)
    progressHUD.AnchorPoint = Vector2.new(0.5, 1)
    progressHUD.BackgroundTransparency = 1
    progressHUD.ZIndex = 86
    progressHUD.Parent = container

    local hudConstraint = Instance.new("UISizeConstraint")
    hudConstraint.MaxSize = Vector2.new(720, 90)
    hudConstraint.MinSize = Vector2.new(280, 50)
    hudConstraint.Parent = progressHUD

    -- Top Row: Stage Name (Left) + Percentage (Right)
    local topRow = Instance.new("Frame")
    topRow.Name = "TopRow"
    topRow.Size = UDim2.new(1, 0, 0, 20)
    topRow.BackgroundTransparency = 1
    topRow.ZIndex = 87
    topRow.Parent = progressHUD

    local stageLabel = Instance.new("TextLabel")
    stageLabel.Name = "StageLabel"
    stageLabel.Size = UDim2.new(1, -70, 1, 0)
    stageLabel.Position = UDim2.new(0, 0, 0, 0)
    stageLabel.BackgroundTransparency = 1
    stageLabel.Font = UITheme.Fonts.Heading
    stageLabel.Text = "INITIALIZING WORLD..."
    stageLabel.TextColor3 = Color3.fromRGB(240, 244, 250)
    stageLabel.TextSize = 13
    stageLabel.TextXAlignment = Enum.TextXAlignment.Left
    stageLabel.ZIndex = 88
    stageLabel.Parent = topRow

    local percentLabel = Instance.new("TextLabel")
    percentLabel.Name = "PercentLabel"
    percentLabel.Size = UDim2.new(0, 60, 1, 0)
    percentLabel.Position = UDim2.new(1, 0, 0, 0)
    percentLabel.AnchorPoint = Vector2.new(1, 0)
    percentLabel.BackgroundTransparency = 1
    percentLabel.Font = UITheme.Fonts.Heading
    percentLabel.Text = "0%"
    percentLabel.TextColor3 = UITheme.Colors.EmberHot
    percentLabel.TextSize = 14
    percentLabel.TextXAlignment = Enum.TextXAlignment.Right
    percentLabel.ZIndex = 88
    percentLabel.Parent = topRow

    -- Progress Track Bar
    local trackBar = Instance.new("Frame")
    trackBar.Name = "TrackBar"
    trackBar.Size = UDim2.new(1, 0, 0, 8)
    trackBar.Position = UDim2.new(0, 0, 0, 25)
    trackBar.BackgroundColor3 = Color3.fromRGB(12, 14, 18)
    trackBar.BorderSizePixel = 0
    trackBar.ZIndex = 87
    trackBar.Parent = progressHUD

    local trackCorner = Instance.new("UICorner")
    trackCorner.CornerRadius = UDim.new(0, 4)
    trackCorner.Parent = trackBar

    local trackStroke = Instance.new("UIStroke")
    trackStroke.Color = Color3.fromRGB(245, 140, 40)
    trackStroke.Transparency = 0.82
    trackStroke.Thickness = 1
    trackStroke.Parent = trackBar

    -- Progress Fill Bar
    local fillBar = Instance.new("Frame")
    fillBar.Name = "FillBar"
    fillBar.Size = UDim2.new(0, 0, 1, 0)
    fillBar.BackgroundColor3 = Color3.fromRGB(255, 140, 30)
    fillBar.BorderSizePixel = 0
    fillBar.ZIndex = 88
    fillBar.Parent = trackBar

    local fillCorner = Instance.new("UICorner")
    fillCorner.CornerRadius = UDim.new(0, 4)
    fillCorner.Parent = fillBar

    local fillGrad = Instance.new("UIGradient")
    fillGrad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(180, 40, 15)),
        ColorSequenceKeypoint.new(0.65, Color3.fromRGB(255, 135, 25)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 235, 160)),
    })
    fillGrad.Parent = fillBar

    -- Leading edge glow head
    local glowHead = Instance.new("Frame")
    glowHead.Name = "GlowHead"
    glowHead.Size = UDim2.fromOffset(8, 8)
    glowHead.Position = UDim2.new(1, 0, 0.5, 0)
    glowHead.AnchorPoint = Vector2.new(0.5, 0.5)
    glowHead.BackgroundColor3 = Color3.fromRGB(255, 245, 210)
    glowHead.BorderSizePixel = 0
    glowHead.ZIndex = 89
    glowHead.Visible = false
    glowHead.Parent = fillBar

    local glowCorner = Instance.new("UICorner")
    glowCorner.CornerRadius = UDim.new(1, 0)
    glowCorner.Parent = glowHead

    -- Bottom Details Sub-Row
    local bottomRow = Instance.new("Frame")
    bottomRow.Name = "BottomRow"
    bottomRow.Size = UDim2.new(1, 0, 0, 18)
    bottomRow.Position = UDim2.new(0, 0, 0, 39)
    bottomRow.BackgroundTransparency = 1
    bottomRow.ZIndex = 87
    bottomRow.Parent = progressHUD

    local detailLabel = Instance.new("TextLabel")
    detailLabel.Name = "DetailLabel"
    detailLabel.Size = UDim2.new(0.65, 0, 1, 0)
    detailLabel.Position = UDim2.new(0, 0, 0, 0)
    detailLabel.BackgroundTransparency = 1
    detailLabel.Font = UITheme.Fonts.Body
    detailLabel.Text = "Synchronizing survival environment..."
    detailLabel.TextColor3 = Color3.fromRGB(150, 160, 175)
    detailLabel.TextSize = 11
    detailLabel.TextXAlignment = Enum.TextXAlignment.Left
    detailLabel.ZIndex = 88
    detailLabel.Parent = bottomRow

    local sectorLabel = Instance.new("TextLabel")
    sectorLabel.Name = "SectorLabel"
    sectorLabel.Size = UDim2.new(0.35, 0, 1, 0)
    sectorLabel.Position = UDim2.new(1, 0, 0, 0)
    sectorLabel.AnchorPoint = Vector2.new(1, 0)
    sectorLabel.BackgroundTransparency = 1
    sectorLabel.Font = UITheme.Fonts.Body
    sectorLabel.Text = "SECTOR // ALPINE WILDERNESS"
    sectorLabel.TextColor3 = Color3.fromRGB(120, 130, 145)
    sectorLabel.TextSize = 11
    sectorLabel.TextXAlignment = Enum.TextXAlignment.Right
    sectorLabel.ZIndex = 88
    sectorLabel.Parent = bottomRow

    -- 5. Bottom-Right Animated Spinner
    local spinnerHolder = Instance.new("Frame")
    spinnerHolder.Name = "SpinnerHolder"
    spinnerHolder.Size = UDim2.fromOffset(260, 38)
    spinnerHolder.Position = UDim2.new(1, -32, 1, -28)
    spinnerHolder.AnchorPoint = Vector2.new(1, 1)
    spinnerHolder.BackgroundTransparency = 1
    spinnerHolder.ZIndex = 85
    spinnerHolder.Parent = container

    local spinner = UIComponents.CreateLoadingSpinner(spinnerHolder, "INITIALIZING WORLD...")

    -- 6. Native Smooth Transition Curtain (Eliminates CanvasGroup downsample blur)
    local fadeCurtain = Instance.new("Frame")
    fadeCurtain.Name = "FadeCurtain"
    fadeCurtain.Size = UDim2.fromScale(1, 1)
    fadeCurtain.Position = UDim2.fromScale(0, 0)
    fadeCurtain.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    fadeCurtain.BackgroundTransparency = 0
    fadeCurtain.BorderSizePixel = 0
    fadeCurtain.ZIndex = 95
    fadeCurtain.Parent = container

    local isTransitioning = false
    local currentRatio = 0

    local function setProgress(ratio: number, statusText: string?, detailText: string?)
        currentRatio = math.clamp(ratio, 0, 1)
        glowHead.Visible = currentRatio > 0.01 and currentRatio < 0.99

        TweenService:Create(fillBar, TweenInfo.new(0.24, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            Size = UDim2.new(currentRatio, 0, 1, 0),
        }):Play()

        percentLabel.Text = string.format("%d%%", math.floor(currentRatio * 100))
        if statusText then
            stageLabel.Text = statusText:upper()
            spinner.SetStatus(statusText)
        end
        if detailText then
            detailLabel.Text = detailText
        end
    end

    local function showLoading(options: { Status: string?, Tip: string?, Progress: number?, Detail: string? }?)
        if isTransitioning then return end
        isTransitioning = true

        if options and options.Status then
            stageLabel.Text = options.Status:upper()
            spinner.SetStatus(options.Status)
        end
        if options and options.Detail then
            detailLabel.Text = options.Detail
        end
        if options and options.Progress then
            setProgress(options.Progress, options.Status, options.Detail)
        else
            setProgress(0, options and options.Status, options and options.Detail)
        end
        if options and options.Tip then
            tipBody.Text = options.Tip
        else
            tipBody.Text = SURVIVAL_TIPS[math.random(1, #SURVIVAL_TIPS)]
        end

        container.Visible = true
        fadeCurtain.BackgroundTransparency = 0

        local fadeTween = TweenService:Create(fadeCurtain, TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            BackgroundTransparency = 1,
        })
        fadeTween.Completed:Connect(function()
            isTransitioning = false
        end)
        fadeTween:Play()
    end

    local function hideLoading(onCompleted: (() -> ())?)
        if isTransitioning then return end
        isTransitioning = true

        local fadeTween = TweenService:Create(fadeCurtain, TweenInfo.new(0.45, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
            BackgroundTransparency = 0,
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
        SetProgress = setProgress,
        SetStatus = function(statusText: string)
            stageLabel.Text = statusText:upper()
            spinner.SetStatus(statusText)
        end,
        SetTip = function(tipText: string)
            tipBody.Text = tipText
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
    phaseText.Text = "DAY"
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

        local phaseNames = {
            Dawn = "DAWN",
            Day = "DAY",
            Dusk = "DUSK",
            Night = "NIGHT",
        }
        local phaseColors = {
            Dawn = Color3.fromRGB(240, 140, 80),
            Day = UITheme.Colors.EmberGold,
            Dusk = Color3.fromRGB(220, 70, 50),
            Night = Color3.fromRGB(130, 140, 190),
        }
        phaseText.Text = phaseNames[phase] or phase:upper()
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
-- 11. SPRINT STAMINA BAR (REMOVED / STUBBED)
--------------------------------------------------------------------------------
export type GenshinStaminaInstance = {
    SetStamina: (current: number, max: number, isConsuming: boolean) -> (),
    UpdateCameraAlignment: (cameraRight: Vector3?, cameraUp: Vector3?) -> (),
    Destroy: () -> (),
}

function UIComponents.CreateGenshinStaminaBar(_character: Model?): any
    return {
        SetStamina = function() end,
        UpdateCameraAlignment = function() end,
        Destroy = function() end,
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
-- 13. AAA FULLSCREEN GLASSMORPHIC SYSTEM / ESC MENU (Image 3 Style)
--------------------------------------------------------------------------------
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
function UIComponents.CreateSystemMenu(parent: Instance, callbacks: SystemMenuCallbacks): SystemMenuInstance
    local container = Instance.new("Frame")
    container.Name = "SettingsMenu"
    container.Size = UDim2.fromScale(1, 1)
    container.Position = UDim2.fromScale(0, 0)
    container.BackgroundColor3 = Color3.fromRGB(6, 6, 8)
    container.BackgroundTransparency = 1
    container.BorderSizePixel = 0
    container.Visible = false
    container.ZIndex = 90
    container.Parent = parent

    -- Invisible modal catch button to natively unlock cursor in Roblox engine
    local modalVeil = Instance.new("TextButton")
    modalVeil.Name = "ModalVeil"
    modalVeil.Size = UDim2.fromScale(1, 1)
    modalVeil.BackgroundTransparency = 1
    modalVeil.Text = ""
    modalVeil.AutoButtonColor = false
    modalVeil.Modal = false
    modalVeil.ZIndex = 89
    modalVeil.Parent = container

    -- Atmospheric Dark Vignette Overlay
    local vignette = Instance.new("Frame")
    vignette.Name = "Vignette"
    vignette.Size = UDim2.fromScale(1, 1)
    vignette.BackgroundColor3 = UITheme.Colors.PureBlack
    vignette.BackgroundTransparency = 0.4
    vignette.BorderSizePixel = 0
    vignette.ZIndex = 91
    vignette.Parent = container

    local vigGrad = Instance.new("UIGradient")
    vigGrad.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.35),
        NumberSequenceKeypoint.new(0.65, 0.70),
        NumberSequenceKeypoint.new(1, 0.92),
    })
    vigGrad.Parent = vignette

    ----------------------------------------------------------------------------
    -- TOP HEADER BAR (Positioned safely away from Roblox Core buttons)
    ----------------------------------------------------------------------------
    local headerBar = Instance.new("Frame")
    headerBar.Name = "HeaderBar"
    headerBar.Size = UDim2.new(1, -120, 0, 48)
    headerBar.Position = UDim2.new(0, 60, 0, 48)
    headerBar.BackgroundTransparency = 1
    headerBar.ZIndex = 92
    headerBar.Parent = container

    -- Left: Game Emblem & Title (Safe from Roblox core buttons)
    local titleFrame = Instance.new("Frame")
    titleFrame.Name = "TitleFrame"
    titleFrame.Size = UDim2.new(0, 380, 1, 0)
    titleFrame.BackgroundTransparency = 1
    titleFrame.ZIndex = 93
    titleFrame.Parent = headerBar

    local flameIcon = IconPack.CreateIcon("settings", 20, UITheme.Colors.EmberPrimary, 0)
    flameIcon.Position = UDim2.fromOffset(0, 4)
    flameIcon.ZIndex = 94
    flameIcon.Parent = titleFrame

    local logoText = Instance.new("TextLabel")
    logoText.Name = "LogoText"
    logoText.Size = UDim2.new(1, -30, 0, 22)
    logoText.Position = UDim2.fromOffset(30, 2)
    logoText.BackgroundTransparency = 1
    logoText.Font = UITheme.Fonts.Heading
    logoText.Text = "SETTINGS MENU"
    logoText.TextColor3 = UITheme.Colors.TextPrimary
    logoText.TextSize = 16
    logoText.TextXAlignment = Enum.TextXAlignment.Left
    logoText.ZIndex = 94
    logoText.Parent = titleFrame

    local statusDot = Instance.new("TextLabel")
    statusDot.Name = "StatusTag"
    statusDot.Size = UDim2.new(1, -30, 0, 16)
    statusDot.Position = UDim2.fromOffset(30, 24)
    statusDot.BackgroundTransparency = 1
    statusDot.Font = UITheme.Fonts.Tag
    statusDot.Text = "●  GAME CONFIGURATION & AUDIO PREFERENCES"
    statusDot.TextColor3 = UITheme.Colors.EmberHot
    statusDot.TextSize = 10
    statusDot.TextXAlignment = Enum.TextXAlignment.Left
    statusDot.ZIndex = 94
    statusDot.Parent = titleFrame
    statusDot.TextColor3 = UITheme.Colors.EmberHot
    statusDot.TextSize = 10
    statusDot.TextXAlignment = Enum.TextXAlignment.Left
    statusDot.ZIndex = 94
    statusDot.Parent = titleFrame

    -- Right: Minimal Clean [ ESC ] RESUME Button
    local btnResume = Instance.new("TextButton")
    btnResume.Name = "BtnResume"
    btnResume.Size = UDim2.fromOffset(140, 38)
    btnResume.Position = UDim2.new(1, 0, 0.5, 0)
    btnResume.AnchorPoint = Vector2.new(1, 0.5)
    btnResume.BackgroundColor3 = Color3.fromRGB(24, 20, 22)
    btnResume.BackgroundTransparency = 0.2
    btnResume.AutoButtonColor = false
    btnResume.Font = UITheme.Fonts.Heading
    btnResume.Text = "[ ESC ] RESUME"
    btnResume.TextColor3 = UITheme.Colors.PureWhite
    btnResume.TextSize = 12
    btnResume.ZIndex = 94
    btnResume.Parent = headerBar

    local resumeCorner = Instance.new("UICorner")
    resumeCorner.CornerRadius = UDim.new(0, 8)
    resumeCorner.Parent = btnResume

    local resumeStroke = Instance.new("UIStroke")
    resumeStroke.Color = UITheme.Colors.EmberPrimary
    resumeStroke.Thickness = 1
    resumeStroke.Transparency = 0.35
    resumeStroke.Parent = btnResume

    btnResume.MouseEnter:Connect(function()
        AudioManager.Play("Hover")
        TweenService:Create(btnResume, UITheme.Tweens.Fast, {
            BackgroundColor3 = UITheme.Colors.EmberPrimary,
            BackgroundTransparency = 0,
        }):Play()
        TweenService:Create(resumeStroke, UITheme.Tweens.Fast, {
            Transparency = 0,
            Color = UITheme.Colors.EmberHot,
        }):Play()
    end)
    btnResume.MouseLeave:Connect(function()
        TweenService:Create(btnResume, UITheme.Tweens.Fast, {
            BackgroundColor3 = Color3.fromRGB(24, 20, 22),
            BackgroundTransparency = 0.2,
        }):Play()
        TweenService:Create(resumeStroke, UITheme.Tweens.Fast, {
            Transparency = 0.35,
            Color = UITheme.Colors.EmberPrimary,
        }):Play()
    end)

    ----------------------------------------------------------------------------
    -- MAIN CONTENT WORKSPACE (Clean 2-Column: Left Nav + Right Canvas)
    ----------------------------------------------------------------------------
    local workspaceFrame = Instance.new("Frame")
    workspaceFrame.Name = "WorkspaceFrame"
    workspaceFrame.Size = UDim2.new(1, -120, 1, -150)
    workspaceFrame.Position = UDim2.new(0, 60, 0, 110)
    workspaceFrame.BackgroundTransparency = 1
    workspaceFrame.ZIndex = 92
    workspaceFrame.Parent = container

    -- LEFT NAVIGATION PANE (Clean typographic list, NO chunky boxes!)
    local leftNav = Instance.new("Frame")
    leftNav.Name = "LeftNav"
    leftNav.Size = UDim2.new(0, 240, 1, 0)
    leftNav.BackgroundTransparency = 1
    leftNav.ZIndex = 93
    leftNav.Parent = workspaceFrame

    local navLayout = Instance.new("UIListLayout")
    navLayout.FillDirection = Enum.FillDirection.Vertical
    navLayout.Padding = UDim.new(0, 6)
    navLayout.Parent = leftNav

    -- RIGHT CONTENT CANVAS (Single elegant frosted container, NO nested box panels!)
    local rightCanvas = Instance.new("Frame")
    rightCanvas.Name = "RightCanvas"
    rightCanvas.Size = UDim2.new(1, -264, 1, 0)
    rightCanvas.Position = UDim2.fromOffset(264, 0)
    rightCanvas.BackgroundColor3 = Color3.fromRGB(14, 12, 16)
    rightCanvas.BackgroundTransparency = 0.50
    rightCanvas.BorderSizePixel = 0
    rightCanvas.ZIndex = 93
    rightCanvas.Parent = workspaceFrame

    local canvasCorner = Instance.new("UICorner")
    canvasCorner.CornerRadius = UDim.new(0, 12)
    canvasCorner.Parent = rightCanvas

    local canvasStroke = Instance.new("UIStroke")
    canvasStroke.Color = Color3.fromRGB(56, 48, 52)
    canvasStroke.Thickness = 1
    canvasStroke.Transparency = 0.55
    canvasStroke.Parent = rightCanvas

    local canvasPadding = Instance.new("UIPadding")
    canvasPadding.PaddingTop = UDim.new(0, 26)
    canvasPadding.PaddingBottom = UDim.new(0, 26)
    canvasPadding.PaddingLeft = UDim.new(0, 32)
    canvasPadding.PaddingRight = UDim.new(0, 32)
    canvasPadding.Parent = rightCanvas

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
    local tabViews: { [string]: Frame } = {}

    local TAB_DEFS = {
        { Id = "SETTINGS", Name = "SETTINGS", Sub = "Audio, Sensitivity & Controls", Icon = "settings" },
        { Id = "CONTROLS", Name = "CONTROLS", Sub = "Keyboard & Shortcuts", Icon = "gamepad-2" },
        { Id = "SURVIVAL", Name = "SURVIVAL", Sub = "Objectives & Campfire", Icon = "compass" },
        { Id = "INTEL",    Name = "INTEL",    Sub = "Survival Guide & Lore", Icon = "book-open" },
    }

    local function switchTab(targetTab: string)
        currentTab = targetTab
        for tId, data in pairs(navButtons) do
            local isSel = (tId == currentTab)
            data.AccentBar.Visible = isSel
            data.TitleLabel.TextColor3 = isSel and UITheme.Colors.PureWhite or UITheme.Colors.TextSecondary
            data.Row.BackgroundColor3 = isSel and UITheme.Colors.SurfaceElevated or Color3.fromRGB(0, 0, 0)
            data.Row.BackgroundTransparency = isSel and 0.65 or 1
        end
        for tId, view in pairs(tabViews) do
            view.Visible = (tId == currentTab)
        end
    end

    for _, def in ipairs(TAB_DEFS) do
        -- Create Tab View Frame inside RightCanvas
        local viewFrame = Instance.new("Frame")
        viewFrame.Name = "View_" .. def.Id
        viewFrame.Size = UDim2.fromScale(1, 1)
        viewFrame.BackgroundTransparency = 1
        viewFrame.Visible = (def.Id == currentTab)
        viewFrame.ZIndex = 94
        viewFrame.Parent = rightCanvas
        tabViews[def.Id] = viewFrame

        -- Create Clean Nav Button in LeftNav
        local rowBtn = Instance.new("TextButton")
        rowBtn.Name = "Nav_" .. def.Id
        rowBtn.Size = UDim2.new(1, 0, 0, 48)
        rowBtn.BackgroundColor3 = (def.Id == currentTab) and UITheme.Colors.SurfaceElevated or Color3.fromRGB(0, 0, 0)
        rowBtn.BackgroundTransparency = (def.Id == currentTab) and 0.65 or 1
        rowBtn.AutoButtonColor = false
        rowBtn.Text = ""
        rowBtn.ZIndex = 94
        rowBtn.Parent = leftNav

        local rowCorner = Instance.new("UICorner")
        rowCorner.CornerRadius = UDim.new(0, 8)
        rowCorner.Parent = rowBtn

        -- Left Active Indicator Accent Bar
        local accentBar = Instance.new("Frame")
        accentBar.Name = "AccentBar"
        accentBar.Size = UDim2.new(0, 3, 0, 22)
        accentBar.Position = UDim2.new(0, 2, 0.5, 0)
        accentBar.AnchorPoint = Vector2.new(0, 0.5)
        accentBar.BackgroundColor3 = UITheme.Colors.EmberPrimary
        accentBar.BorderSizePixel = 0
        accentBar.Visible = (def.Id == currentTab)
        accentBar.ZIndex = 95
        accentBar.Parent = rowBtn

        local barCorner = Instance.new("UICorner")
        barCorner.CornerRadius = UDim.new(1, 0)
        barCorner.Parent = accentBar

        -- Icon
        local icon = IconPack.CreateIcon(def.Icon, 16, UITheme.Colors.EmberHot, 0)
        icon.Position = UDim2.new(0, 14, 0.5, 0)
        icon.AnchorPoint = Vector2.new(0, 0.5)
        icon.ZIndex = 95
        icon.Parent = rowBtn

        -- Title
        local tLabel = Instance.new("TextLabel")
        tLabel.Name = "Title"
        tLabel.Size = UDim2.new(1, -44, 0, 18)
        tLabel.Position = UDim2.fromOffset(40, 8)
        tLabel.BackgroundTransparency = 1
        tLabel.Font = UITheme.Fonts.Heading
        tLabel.Text = def.Name
        tLabel.TextColor3 = (def.Id == currentTab) and UITheme.Colors.PureWhite or UITheme.Colors.TextSecondary
        tLabel.TextSize = 13
        tLabel.TextXAlignment = Enum.TextXAlignment.Left
        tLabel.ZIndex = 95
        tLabel.Parent = rowBtn

        -- Sub
        local sLabel = Instance.new("TextLabel")
        sLabel.Name = "Sub"
        sLabel.Size = UDim2.new(1, -44, 0, 14)
        sLabel.Position = UDim2.fromOffset(40, 26)
        sLabel.BackgroundTransparency = 1
        sLabel.Font = UITheme.Fonts.Body
        sLabel.Text = def.Sub
        sLabel.TextColor3 = UITheme.Colors.TextMuted
        sLabel.TextSize = 10
        sLabel.TextXAlignment = Enum.TextXAlignment.Left
        sLabel.ZIndex = 95
        sLabel.Parent = rowBtn

        navButtons[def.Id] = {
            Row = rowBtn,
            AccentBar = accentBar,
            TitleLabel = tLabel,
            Icon = icon,
        }

        rowBtn.MouseEnter:Connect(function()
            AudioManager.Play("Hover")
            if currentTab ~= def.Id then
                TweenService:Create(rowBtn, UITheme.Tweens.Fast, { BackgroundTransparency = 0.85, BackgroundColor3 = UITheme.Colors.SurfaceElevated }):Play()
                tLabel.TextColor3 = UITheme.Colors.TextPrimary
            end
        end)
        rowBtn.MouseLeave:Connect(function()
            if currentTab ~= def.Id then
                TweenService:Create(rowBtn, UITheme.Tweens.Fast, { BackgroundTransparency = 1 }):Play()
                tLabel.TextColor3 = UITheme.Colors.TextSecondary
            end
        end)
        rowBtn.Activated:Connect(function()
            AudioManager.Play("Click")
            switchTab(def.Id)
        end)
    end

    -- Divider before Quit button
    local navDivider = UIComponents.CreateDivider(leftNav)
    navDivider.Size = UDim2.new(1, 0, 0, 1)

    -- QUIT TO MAIN MENU BUTTON (Clean text button with power icon)
    local btnQuit = Instance.new("TextButton")
    btnQuit.Name = "BtnQuit"
    btnQuit.Size = UDim2.new(1, 0, 0, 44)
    btnQuit.BackgroundTransparency = 1
    btnQuit.AutoButtonColor = false
    btnQuit.Text = ""
    btnQuit.ZIndex = 94
    btnQuit.Parent = leftNav

    local quitCorner = Instance.new("UICorner")
    quitCorner.CornerRadius = UDim.new(0, 8)
    quitCorner.Parent = btnQuit

    local quitIcon = IconPack.CreateIcon("power", 16, UITheme.Colors.EmberCrimson, 0)
    quitIcon.Position = UDim2.new(0, 14, 0.5, 0)
    quitIcon.AnchorPoint = Vector2.new(0, 0.5)
    quitIcon.ZIndex = 95
    quitIcon.Parent = btnQuit

    local quitLabel = Instance.new("TextLabel")
    quitLabel.Name = "Label"
    quitLabel.Size = UDim2.new(1, -44, 1, 0)
    quitLabel.Position = UDim2.fromOffset(40, 0)
    quitLabel.BackgroundTransparency = 1
    quitLabel.Font = UITheme.Fonts.Heading
    quitLabel.Text = "QUIT TO MAIN MENU"
    quitLabel.TextColor3 = UITheme.Colors.EmberCrimson
    quitLabel.TextSize = 12
    quitLabel.TextXAlignment = Enum.TextXAlignment.Left
    quitLabel.ZIndex = 95
    quitLabel.Parent = btnQuit

    btnQuit.MouseEnter:Connect(function()
        AudioManager.Play("Hover")
        TweenService:Create(btnQuit, UITheme.Tweens.Fast, {
            BackgroundColor3 = UITheme.Colors.SurfaceElevated,
            BackgroundTransparency = 0.75,
        }):Play()
    end)
    btnQuit.MouseLeave:Connect(function()
        TweenService:Create(btnQuit, UITheme.Tweens.Fast, { BackgroundTransparency = 1 }):Play()
    end)
    btnQuit.Activated:Connect(function()
        AudioManager.Play("Click")
        container.Visible = false
        callbacks.OnQuit()
    end)

    ----------------------------------------------------------------------------
    -- VIEW 1: SURVIVAL TAB (Objectives & Camp Status)
    ----------------------------------------------------------------------------
    local survView = tabViews["SURVIVAL"]
    local survLayout = Instance.new("UIListLayout")
    survLayout.FillDirection = Enum.FillDirection.Vertical
    survLayout.Padding = UDim.new(0, 16)
    survLayout.Parent = survView

    local survHeader = Instance.new("TextLabel")
    survHeader.Size = UDim2.new(1, 0, 0, 22)
    survHeader.BackgroundTransparency = 1
    survHeader.Font = UITheme.Fonts.Heading
    survHeader.Text = "CURRENT SURVIVAL OBJECTIVES"
    survHeader.TextColor3 = UITheme.Colors.TextPrimary
    survHeader.TextSize = 17
    survHeader.TextXAlignment = Enum.TextXAlignment.Left
    survHeader.Parent = survView

    local survBadge = Instance.new("TextLabel")
    survBadge.Size = UDim2.new(1, 0, 0, 16)
    survBadge.BackgroundTransparency = 1
    survBadge.Font = UITheme.Fonts.Tag
    survBadge.Text = "SECTOR 01: THE LONG NIGHT // PROLOGUE"
    survBadge.TextColor3 = UITheme.Colors.EmberHot
    survBadge.TextSize = 11
    survBadge.TextXAlignment = Enum.TextXAlignment.Left
    survBadge.Parent = survView

    UIComponents.CreateDivider(survView)

    local function addCheckItem(title: string, sub: string, isDone: boolean)
        local row = Instance.new("Frame")
        row.Size = UDim2.new(1, 0, 0, 42)
        row.BackgroundTransparency = 1
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
        s.Position = UDim2.fromOffset(30, 20)
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

    UIComponents.CreateDivider(survView)

    local statusStrip = Instance.new("Frame")
    statusStrip.Size = UDim2.new(1, 0, 0, 36)
    statusStrip.BackgroundTransparency = 1
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
    -- VIEW 2: SETTINGS TAB (Audio & Immersion)
    ----------------------------------------------------------------------------
    local settView = tabViews["SETTINGS"]
    local settLayout = Instance.new("UIListLayout")
    settLayout.FillDirection = Enum.FillDirection.Vertical
    settLayout.Padding = UDim.new(0, 16)
    settLayout.Parent = settView

    local settTitle = Instance.new("TextLabel")
    settTitle.Size = UDim2.new(1, 0, 0, 22)
    settTitle.BackgroundTransparency = 1
    settTitle.Font = UITheme.Fonts.Heading
    settTitle.Text = "AUDIO & PREFERENCES"
    settTitle.TextColor3 = UITheme.Colors.TextPrimary
    settTitle.TextSize = 17
    settTitle.TextXAlignment = Enum.TextXAlignment.Left
    settTitle.Parent = settView

    local settBadge = Instance.new("TextLabel")
    settBadge.Size = UDim2.new(1, 0, 0, 16)
    settBadge.BackgroundTransparency = 1
    settBadge.Font = UITheme.Fonts.Tag
    settBadge.Text = "MASTER SOUND LEVELS & VISUAL IMMERSION"
    settBadge.TextColor3 = UITheme.Colors.EmberHot
    settBadge.TextSize = 11
    settBadge.TextXAlignment = Enum.TextXAlignment.Left
    settBadge.Parent = settView

    UIComponents.CreateDivider(settView)

    UIComponents.CreateSlider({
        Label = "MASTER AUDIO VOLUME",
        Description = "Master sound level for the entire game",
        InitialValue = UITheme.GetMasterVolume(),
        Parent = settView,
        OnChanged = function(val: number)
            UITheme.SetMasterVolume(val)
        end,
    })

    UIComponents.CreateDivider(settView)

    UIComponents.CreateSlider({
        Label = "SFX VOLUME",
        Description = "UI clicks, item interaction, wood gathering & equipment sounds",
        InitialValue = UITheme.GetSFXVolume(),
        Parent = settView,
        OnChanged = function(val: number)
            UITheme.SetSFXVolume(val)
        end,
    })

    UIComponents.CreateDivider(settView)

    UIComponents.CreateSlider({
        Label = "MUSIC & SOUNDTRACK",
        Description = "Melodic scores & atmospheric background soundtrack",
        InitialValue = UITheme.GetMusicVolume(),
        Parent = settView,
        OnChanged = function(val: number)
            UITheme.SetMusicVolume(val)
        end,
    })

    UIComponents.CreateDivider(settView)

    UIComponents.CreateSlider({
        Label = "GAME NATIVE AUDIO",
        Description = "Campfire crackles, wind blowing, crickets & 3D nature sounds",
        InitialValue = UITheme.GetEnvironmentVolume(),
        Parent = settView,
        OnChanged = function(val: number)
            UITheme.SetEnvironmentVolume(val)
        end,
    })

    UIComponents.CreateDivider(settView)

    UIComponents.CreateSlider({
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

    UIComponents.CreateDivider(settView)

    UIComponents.CreateToggle({
        Label = "REDUCED MOTION",
        Description = "Limits intense camera shakes, screen blurs & particle speeds",
        InitialValue = false,
        Parent = settView,
        OnChanged = function(enabled: boolean)
        end,
    })

    UIComponents.CreateDivider(settView)

    UIComponents.CreateToggle({
        Label = "CAMERA HEAD BOBBING",
        Description = "Realistic first-person head bob while walking and sprinting",
        InitialValue = true,
        Parent = settView,
        OnChanged = function(enabled: boolean)
        end,
    })

    ----------------------------------------------------------------------------
    -- VIEW 3: CONTROLS TAB (Full Keybindings Cheat Sheet)
    ----------------------------------------------------------------------------
    local ctrlView = tabViews["CONTROLS"]
    local ctrlLayout = Instance.new("UIListLayout")
    ctrlLayout.FillDirection = Enum.FillDirection.Vertical
    ctrlLayout.Padding = UDim.new(0, 10)
    ctrlLayout.Parent = ctrlView

    local ctrlTitle = Instance.new("TextLabel")
    ctrlTitle.Size = UDim2.new(1, 0, 0, 22)
    ctrlTitle.BackgroundTransparency = 1
    ctrlTitle.Font = UITheme.Fonts.Heading
    ctrlTitle.Text = "SURVIVAL CONTROLS"
    ctrlTitle.TextColor3 = UITheme.Colors.TextPrimary
    ctrlTitle.TextSize = 17
    ctrlTitle.TextXAlignment = Enum.TextXAlignment.Left
    ctrlTitle.Parent = ctrlView

    local ctrlBadge = Instance.new("TextLabel")
    ctrlBadge.Size = UDim2.new(1, 0, 0, 16)
    ctrlBadge.BackgroundTransparency = 1
    ctrlBadge.Font = UITheme.Fonts.Tag
    ctrlBadge.Text = "KEYBOARD SHORTCUTS & INPUT ACTIONS"
    ctrlBadge.TextColor3 = UITheme.Colors.EmberHot
    ctrlBadge.TextSize = 11
    ctrlBadge.TextXAlignment = Enum.TextXAlignment.Left
    ctrlBadge.Parent = ctrlView

    UIComponents.CreateDivider(ctrlView)

    local function addKeyRow(actionName: string, pcKey: string)
        local row = Instance.new("Frame")
        row.Size = UDim2.new(1, 0, 0, 30)
        row.BackgroundTransparency = 1
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
        keyPill.Size = UDim2.new(0.35, 0, 0, 24)
        keyPill.Position = UDim2.new(1, 0, 0.5, 0)
        keyPill.AnchorPoint = Vector2.new(1, 0.5)
        keyPill.BackgroundColor3 = Color3.fromRGB(10, 9, 12)
        keyPill.BackgroundTransparency = 0.4
        keyPill.Font = UITheme.Fonts.Tag
        keyPill.Text = pcKey
        keyPill.TextColor3 = UITheme.Colors.EmberHot
        keyPill.TextSize = 11
        keyPill.Parent = row

        local pillCorner = Instance.new("UICorner")
        pillCorner.CornerRadius = UDim.new(0, 4)
        pillCorner.Parent = keyPill

        local pillStroke = Instance.new("UIStroke")
        pillStroke.Color = Color3.fromRGB(50, 44, 46)
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
    -- VIEW 4: INTEL TAB (Survival Knowledge & Hollow Lore)
    ----------------------------------------------------------------------------
    local intelView = tabViews["INTEL"]
    local intelLayout = Instance.new("UIListLayout")
    intelLayout.FillDirection = Enum.FillDirection.Vertical
    intelLayout.Padding = UDim.new(0, 14)
    intelLayout.Parent = intelView

    local intelTitle = Instance.new("TextLabel")
    intelTitle.Size = UDim2.new(1, 0, 0, 22)
    intelTitle.BackgroundTransparency = 1
    intelTitle.Font = UITheme.Fonts.Heading
    intelTitle.Text = "SURVIVAL INTELLIGENCE"
    intelTitle.TextColor3 = UITheme.Colors.TextPrimary
    intelTitle.TextSize = 17
    intelTitle.TextXAlignment = Enum.TextXAlignment.Left
    intelTitle.Parent = intelView

    local intelBadge = Instance.new("TextLabel")
    intelBadge.Size = UDim2.new(1, 0, 0, 16)
    intelBadge.BackgroundTransparency = 1
    intelBadge.Font = UITheme.Fonts.Tag
    intelBadge.Text = "TACTICAL FIELD NOTES & ESSENTIAL MECHANICS"
    intelBadge.TextColor3 = UITheme.Colors.EmberHot
    intelBadge.TextSize = 11
    intelBadge.TextXAlignment = Enum.TextXAlignment.Left
    intelBadge.Parent = intelView

    UIComponents.CreateDivider(intelView)

    local function addIntelItem(title: string, body: string)
        local row = Instance.new("Frame")
        row.Size = UDim2.new(1, 0, 0, 52)
        row.BackgroundTransparency = 1
        row.Parent = intelView

        local bullet = IconPack.CreateIcon("flame", 14, UITheme.Colors.EmberHot, 0)
        bullet.Position = UDim2.fromOffset(4, 2)
        bullet.Parent = row

        local t = Instance.new("TextLabel")
        t.Size = UDim2.new(1, -26, 0, 16)
        t.Position = UDim2.fromOffset(26, 0)
        t.BackgroundTransparency = 1
        t.Font = UITheme.Fonts.Heading
        t.Text = title
        t.TextColor3 = UITheme.Colors.EmberHot
        t.TextSize = 12
        t.TextXAlignment = Enum.TextXAlignment.Left
        t.Parent = row

        local b = Instance.new("TextLabel")
        b.Size = UDim2.new(1, -26, 0, 32)
        b.Position = UDim2.fromOffset(26, 18)
        b.BackgroundTransparency = 1
        b.Font = UITheme.Fonts.Body
        b.Text = body
        b.TextColor3 = UITheme.Colors.TextSecondary
        b.TextSize = 11
        b.TextWrapped = true
        b.TextXAlignment = Enum.TextXAlignment.Left
        b.Parent = row
    end

    addIntelItem("THE CAMPFIRE IS SANCTUARY", "Light from the campfire repels the hollow entity. Never let the embers extinguish completely.")
    addIntelItem("THE HOLLOW STALKS IN DARKNESS", "At 19:00 nightfall, the entity roams outside the illuminated perimeter. Stay close to the fire.")
    addIntelItem("WOOD RESOURCE MANAGEMENT", "You can carry a maximum of 5 wood logs. Gather from the campsite stack or fallen forest piles.")

    ----------------------------------------------------------------------------
    -- VISIBILITY & TRANSITION CONTROLLERS
    ----------------------------------------------------------------------------
    local isOpen = false

    local function openMenu()
        if isOpen then return end
        isOpen = true
        container.Visible = true
        modalVeil.Modal = true
        switchTab("SETTINGS")
        AudioManager.Play("Click")
        TweenService:Create(container, UITheme.Tweens.Fast, { BackgroundTransparency = 0.35 }):Play()
    end

    local function closeMenu()
        if not isOpen then return end
        isOpen = false
        modalVeil.Modal = false
        AudioManager.Play("Click")
        if callbacks.OnClose then
            callbacks.OnClose()
        end
        local fadeTween = TweenService:Create(container, UITheme.Tweens.Fast, { BackgroundTransparency = 1 })
        fadeTween.Completed:Connect(function()
            if not isOpen then
                container.Visible = false
                modalVeil.Modal = false
            end
        end)
        fadeTween:Play()
    end

    btnResume.Activated:Connect(function()
        closeMenu()
        callbacks.OnResume()
    end)

    return {
        Container = container,
        Open = openMenu,
        Close = closeMenu,
        IsOpen = function()
            return isOpen
        end,
        Destroy = function()
            container:Destroy()
        end,
    }
end

return UIComponents
