--!strict
--[[
    UI/Badge.lua
    Modular Glassmorphic Badge & Status Pill Component
    "Don't Let the Fire Die" — Fluenosity Studio
]]

local UITheme = require(script.Parent:WaitForChild("UITheme"))

export type BadgeVariant = "Ember" | "Glass" | "Success" | "Danger" | "Gold"

export type BadgeConfig = {
    Text: string,
    Variant: BadgeVariant?,
    Size: UDim2?,
    Position: UDim2?,
    AnchorPoint: Vector2?,
    LayoutOrder: number?,
    ZIndex: number?,
    Parent: Instance?,
}

local Badge = {}

function Badge.Create(config: BadgeConfig): Frame
    local variant = config.Variant or "Ember"

    local badge = Instance.new("Frame")
    badge.Name = "Badge_" .. config.Text:gsub("%s+", "")
    badge.Size = config.Size or UDim2.new(0, 0, 0, 22)
    badge.AutomaticSize = Enum.AutomaticSize.X
    if config.Position then badge.Position = config.Position end
    if config.AnchorPoint then badge.AnchorPoint = config.AnchorPoint end
    badge.LayoutOrder = config.LayoutOrder or 0
    badge.ZIndex = config.ZIndex or 5

    local bgColor: Color3
    local strokeColor: Color3
    local textColor: Color3

    if variant == "Ember" then
        bgColor = Color3.fromRGB(48, 28, 18)
        strokeColor = UITheme.Colors.EmberHot
        textColor = UITheme.Colors.EmberGold
    elseif variant == "Success" then
        bgColor = Color3.fromRGB(18, 42, 28)
        strokeColor = UITheme.Colors.TextSuccess
        textColor = Color3.fromRGB(210, 255, 225)
    elseif variant == "Danger" then
        bgColor = Color3.fromRGB(48, 16, 20)
        strokeColor = UITheme.Colors.TextDanger
        textColor = Color3.fromRGB(255, 210, 210)
    elseif variant == "Gold" then
        bgColor = Color3.fromRGB(45, 36, 16)
        strokeColor = UITheme.Colors.EmberGold
        textColor = Color3.fromRGB(255, 240, 180)
    else -- Glass (default)
        bgColor = UITheme.Colors.GlassElevated
        strokeColor = UITheme.Colors.BorderGlass
        textColor = UITheme.Colors.TextPrimary
    end

    badge.BackgroundColor3 = bgColor
    badge.BackgroundTransparency = 0.25
    badge.BorderSizePixel = 0

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = badge

    local stroke = Instance.new("UIStroke")
    stroke.Thickness = 1.0
    stroke.Color = strokeColor
    stroke.Transparency = 0.35
    stroke.Parent = badge

    local padding = Instance.new("UIPadding")
    padding.PaddingLeft = UDim.new(0, 8)
    padding.PaddingRight = UDim.new(0, 8)
    padding.Parent = badge

    local label = Instance.new("TextLabel")
    label.Name = "Text"
    label.Size = UDim2.fromScale(1, 1)
    label.BackgroundTransparency = 1
    label.Font = UITheme.Fonts.Heading
    label.Text = config.Text
    label.TextColor3 = textColor
    label.TextSize = UITheme.FontSizes.Badge
    label.TextXAlignment = Enum.TextXAlignment.Center
    label.TextYAlignment = Enum.TextYAlignment.Center
    label.Parent = badge

    if config.Parent then
        badge.Parent = config.Parent
    end

    return badge
end

return Badge
