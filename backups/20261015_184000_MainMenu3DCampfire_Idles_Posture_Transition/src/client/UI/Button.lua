--!strict
--[[
    UI/Button.lua
    Modular Glassmorphic Reusable Button Component
    "Don't Let the Fire Die" — Fluenosity Studio

    Features:
    - True glassmorphism aesthetic with specular border highlighting
    - Tactile click micro-compression (scale-down 0.97 on press)
    - Zero jarring hover bounce (calm, non-distracting visual ease)
    - Integrated pleasant click audio cue
    - Lucide icon support via IconPack
    - Variants: Primary, Secondary, Danger, Ghost, GlassAction
]]

local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local sharedFolder = ReplicatedStorage:WaitForChild("FluenosityShared")
local IconPack = require(sharedFolder:WaitForChild("IconPack"))
local UITheme = require(script.Parent:WaitForChild("UITheme"))

export type ButtonVariant = "Primary" | "Secondary" | "Danger" | "Ghost" | "GlassAction"

export type ButtonConfig = {
    Text: string,
    Subtext: string?,
    Variant: ButtonVariant?,
    IconName: string?,
    IconColor: Color3?,
    IconSize: number?,
    BadgeText: string?,
    BadgeColor: Color3?,
    Size: UDim2?,
    Position: UDim2?,
    AnchorPoint: Vector2?,
    LayoutOrder: number?,
    ZIndex: number?,
    Parent: Instance?,
    CornerRadius: number?,
    FontSize: number?,
    Disabled: boolean?,
    Tooltip: string?,
    OnClick: (() -> ())?,
}

local Button = {}

function Button.Create(config: ButtonConfig): TextButton
    local variant = config.Variant or "Secondary"
    local cornerRadius = config.CornerRadius or 10

    local button = Instance.new("TextButton")
    button.Name = "Btn_" .. config.Text:gsub("%s+", "")
    button.Size = config.Size or UDim2.new(1, 0, 0, (variant == "GlassAction" or config.Subtext) and 52 or 42)
    if config.Position then button.Position = config.Position end
    if config.AnchorPoint then button.AnchorPoint = config.AnchorPoint end
    button.LayoutOrder = config.LayoutOrder or 0
    button.ZIndex = config.ZIndex or 5
    button.AutoButtonColor = false
    button.Text = ""
    button.ClipsDescendants = false

    -- Determine colors based on variant
    local baseBgColor: Color3
    local baseBgTrans: number
    local strokeColor: Color3
    local textColor: Color3

    if variant == "Primary" then
        baseBgColor = UITheme.Colors.ButtonPrimaryBg
        baseBgTrans = 0.22
        strokeColor = UITheme.Colors.ButtonPrimaryStroke
        textColor = UITheme.Colors.TextPrimary
    elseif variant == "Danger" then
        baseBgColor = UITheme.Colors.ButtonDangerBg
        baseBgTrans = 0.25
        strokeColor = UITheme.Colors.ButtonDangerStroke
        textColor = Color3.fromRGB(255, 210, 210)
    elseif variant == "Ghost" then
        baseBgColor = UITheme.Colors.ButtonGhostBg
        baseBgTrans = UITheme.Transparency.ButtonGhost
        strokeColor = UITheme.Colors.BorderSubtle
        textColor = UITheme.Colors.TextSecondary
    elseif variant == "GlassAction" then
        baseBgColor = UITheme.Colors.GlassSurface
        baseBgTrans = 0.28
        strokeColor = UITheme.Colors.BorderGlass
        textColor = UITheme.Colors.TextPrimary
    else -- Secondary (default)
        baseBgColor = UITheme.Colors.ButtonSecondaryBg
        baseBgTrans = UITheme.Transparency.Button
        strokeColor = UITheme.Colors.ButtonSecondaryStroke
        textColor = UITheme.Colors.TextPrimary
    end

    button.BackgroundColor3 = baseBgColor
    button.BackgroundTransparency = baseBgTrans
    button.BorderSizePixel = 0

    -- Apply glass styling
    UITheme.ApplyGlass(button, {
        CornerRadius = cornerRadius,
        StrokeColor = strokeColor,
        StrokeThickness = (variant == "Primary") and 1.5 or 1.2,
        IsActive = (variant == "Primary"),
    })

    -- Inner content container with horizontal layout
    local content = Instance.new("Frame")
    content.Name = "Content"
    content.Size = UDim2.fromScale(1, 1)
    content.BackgroundTransparency = 1
    content.ZIndex = button.ZIndex + 1
    content.Parent = button

    local contentLayout = Instance.new("UIListLayout")
    contentLayout.Name = "Layout"
    contentLayout.FillDirection = Enum.FillDirection.Horizontal
    contentLayout.HorizontalAlignment = (variant == "GlassAction") and Enum.HorizontalAlignment.Left or Enum.HorizontalAlignment.Center
    contentLayout.VerticalAlignment = Enum.VerticalAlignment.Center
    contentLayout.Padding = UDim.new(0, 10)
    contentLayout.SortOrder = Enum.SortOrder.LayoutOrder
    contentLayout.Parent = content

    local padding = Instance.new("UIPadding")
    padding.PaddingLeft = UDim.new(0, (variant == "GlassAction") and 18 or 12)
    padding.PaddingRight = UDim.new(0, 14)
    padding.PaddingTop = UDim.new(0, 4)
    padding.PaddingBottom = UDim.new(0, 4)
    padding.Parent = content

    -- Optional Lucide Icon
    if config.IconName then
        local iconColor = config.IconColor or (variant == "Primary" and UITheme.Colors.EmberHot or UITheme.Colors.TextSecondary)
        local icon = IconPack.CreateIcon(config.IconName, config.IconSize or 16, iconColor, 0)
        icon.Name = "ButtonIcon"
        icon.LayoutOrder = 1
        icon.ZIndex = content.ZIndex + 1
        icon.Parent = content
    end

    -- Text Stack container
    local textContainer = Instance.new("Frame")
    textContainer.Name = "TextStack"
    textContainer.Size = (variant == "GlassAction") and UDim2.new(1, -60, 1, 0) or UDim2.new(0, 0, 1, 0)
    textContainer.AutomaticSize = (variant == "GlassAction") and Enum.AutomaticSize.None or Enum.AutomaticSize.X
    textContainer.BackgroundTransparency = 1
    textContainer.LayoutOrder = 2
    textContainer.ZIndex = content.ZIndex + 1
    textContainer.Parent = content

    local textLayout = Instance.new("UIListLayout")
    textLayout.FillDirection = Enum.FillDirection.Vertical
    textLayout.HorizontalAlignment = (variant == "GlassAction") and Enum.HorizontalAlignment.Left or Enum.HorizontalAlignment.Center
    textLayout.VerticalAlignment = Enum.VerticalAlignment.Center
    textLayout.Padding = UDim.new(0, 2)
    textLayout.Parent = textContainer

    local mainLabel = Instance.new("TextLabel")
    mainLabel.Name = "MainLabel"
    mainLabel.Size = UDim2.new(0, 0, 0, config.FontSize or UITheme.FontSizes.Button)
    mainLabel.AutomaticSize = Enum.AutomaticSize.XY
    mainLabel.BackgroundTransparency = 1
    mainLabel.Font = UITheme.Fonts.Button
    mainLabel.Text = config.Text
    mainLabel.TextColor3 = textColor
    mainLabel.TextSize = config.FontSize or UITheme.FontSizes.Button
    mainLabel.TextXAlignment = (variant == "GlassAction") and Enum.TextXAlignment.Left or Enum.TextXAlignment.Center
    mainLabel.ZIndex = textContainer.ZIndex + 1
    mainLabel.Parent = textContainer

    if config.Subtext and config.Subtext ~= "" then
        local subLabel = Instance.new("TextLabel")
        subLabel.Name = "SubLabel"
        subLabel.Size = UDim2.new(0, 0, 0, UITheme.FontSizes.Caption)
        subLabel.AutomaticSize = Enum.AutomaticSize.XY
        subLabel.BackgroundTransparency = 1
        subLabel.Font = UITheme.Fonts.Body
        subLabel.Text = config.Subtext
        subLabel.TextColor3 = UITheme.Colors.TextMuted
        subLabel.TextSize = UITheme.FontSizes.Caption
        subLabel.TextXAlignment = (variant == "GlassAction") and Enum.TextXAlignment.Left or Enum.TextXAlignment.Center
        subLabel.ZIndex = textContainer.ZIndex + 1
        subLabel.Parent = textContainer
    end

    -- Optional Badge (e.g. "✔ ACTIVE", "KEY: [B]")
    if config.BadgeText then
        local badge = Instance.new("Frame")
        badge.Name = "Badge"
        badge.Size = UDim2.new(0, 0, 0, 20)
        badge.AutomaticSize = Enum.AutomaticSize.X
        badge.BackgroundColor3 = config.BadgeColor or (variant == "Primary" and UITheme.Colors.EmberPrimary or UITheme.Colors.GlassElevated)
        badge.BackgroundTransparency = 0.25
        badge.LayoutOrder = 3
        badge.ZIndex = content.ZIndex + 1

        local bCorner = Instance.new("UICorner")
        bCorner.CornerRadius = UDim.new(0, 6)
        bCorner.Parent = badge

        local bPad = Instance.new("UIPadding")
        bPad.PaddingLeft = UDim.new(0, 8)
        bPad.PaddingRight = UDim.new(0, 8)
        bPad.Parent = badge

        local bLabel = Instance.new("TextLabel")
        bLabel.Size = UDim2.fromScale(1, 1)
        bLabel.BackgroundTransparency = 1
        bLabel.Font = UITheme.Fonts.Heading
        bLabel.Text = config.BadgeText
        bLabel.TextColor3 = UITheme.Colors.TextPrimary
        bLabel.TextSize = UITheme.FontSizes.Badge
        bLabel.Parent = badge

        badge.Parent = content
    end

    -- Scale micro-compression on click (NO hover bounce!)
    local uiScale = Instance.new("UIScale")
    uiScale.Scale = 1.0
    uiScale.Parent = button

    local stroke = button:FindFirstChildOfClass("UIStroke")

    if not config.Disabled then
        button.MouseButton1Down:Connect(function()
            TweenService:Create(uiScale, UITheme.Tweens.Snap, { Scale = 0.97 }):Play()
        end)

        button.MouseButton1Up:Connect(function()
            TweenService:Create(uiScale, UITheme.Tweens.Snap, { Scale = 1.0 }):Play()
        end)

        button.MouseEnter:Connect(function()
            -- Gentle color ease only (no scale/movement)
            TweenService:Create(button, UITheme.Tweens.Fast, {
                BackgroundTransparency = math.max(0, baseBgTrans - 0.10),
            }):Play()
            if stroke then
                TweenService:Create(stroke, UITheme.Tweens.Fast, {
                    Color = (variant == "Primary") and UITheme.Colors.BorderGlow or UITheme.Colors.BorderGlass,
                    Transparency = 0.35,
                }):Play()
            end
        end)

        button.MouseLeave:Connect(function()
            TweenService:Create(uiScale, UITheme.Tweens.Snap, { Scale = 1.0 }):Play()
            TweenService:Create(button, UITheme.Tweens.Fast, {
                BackgroundTransparency = baseBgTrans,
            }):Play()
            if stroke then
                TweenService:Create(stroke, UITheme.Tweens.Fast, {
                    Color = strokeColor,
                    Transparency = (variant == "Primary") and UITheme.Transparency.StrokeActive or UITheme.Transparency.Stroke,
                }):Play()
            end
        end)

        button.Activated:Connect(function()
            UITheme.PlayClick()
            if config.OnClick then
                config.OnClick()
            end
        end)
    else
        button.BackgroundTransparency = 0.75
        mainLabel.TextColor3 = UITheme.Colors.TextMuted
        if stroke then stroke.Transparency = 0.85 end
    end

    if config.Tooltip and config.Tooltip ~= "" then
        local Tooltip = require(script.Parent:WaitForChild("Tooltip"))
        Tooltip.Attach(button, {
            Title = config.Tooltip,
            Width = 180,
        })
    end

    if config.Parent then
        button.Parent = config.Parent
    end

    return button
end

return Button
