--!strict
--[[
    UI/IconButton.lua
    Modular Glassmorphic Icon Button (Close "X", Settings, Back, Tools)
    "Don't Let the Fire Die" — Fluenosity Studio
]]

local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local sharedFolder = ReplicatedStorage:WaitForChild("FluenosityShared")
local IconPack = require(sharedFolder:WaitForChild("IconPack"))
local UITheme = require(script.Parent:WaitForChild("UITheme"))

export type IconButtonConfig = {
    IconName: string,
    IconColor: Color3?,
    IconSize: number?,
    Size: (number | UDim2)?,
    Position: UDim2?,
    AnchorPoint: Vector2?,
    LayoutOrder: number?,
    ZIndex: number?,
    Parent: Instance?,
    IsCircle: boolean?,
    CornerRadius: number?,
    IsCloseButton: boolean?,
    Tooltip: string?,
    OnClick: (() -> ())?,
}

local IconButton = {}

function IconButton.Create(config: IconButtonConfig): ImageButton
    local btnSize: UDim2
    if typeof(config.Size) == "number" then
        local s = config.Size :: number
        btnSize = UDim2.new(0, s, 0, s)
    elseif typeof(config.Size) == "UDim2" then
        btnSize = config.Size :: UDim2
    else
        btnSize = UDim2.new(0, 36, 0, 36)
    end

    local button = Instance.new("ImageButton")
    button.Name = "IconBtn_" .. config.IconName:gsub("%s+", "")
    button.Size = btnSize
    if config.Position then button.Position = config.Position end
    if config.AnchorPoint then button.AnchorPoint = config.AnchorPoint end
    button.LayoutOrder = config.LayoutOrder or 0
    button.ZIndex = config.ZIndex or 10
    button.AutoButtonColor = false
    button.BackgroundColor3 = config.IsCloseButton and UITheme.Colors.GlassElevated or UITheme.Colors.GlassSurface
    button.BackgroundTransparency = UITheme.Transparency.Button
    button.BorderSizePixel = 0

    local cornerRadius = config.IsCircle and 999 or (config.CornerRadius or 8)
    UITheme.ApplyGlass(button, {
        CornerRadius = cornerRadius,
        StrokeColor = config.IsCloseButton and UITheme.Colors.BorderSubtle or UITheme.Colors.BorderGlass,
        StrokeThickness = 1.0,
    })

    local iconSize = config.IconSize or (math.floor(button.AbsoluteSize.Y * 0.45) > 0 and math.floor(button.AbsoluteSize.Y * 0.45) or 16)
    local iconColor = config.IconColor or (config.IsCloseButton and UITheme.Colors.TextSecondary or UITheme.Colors.TextPrimary)

    local icon = IconPack.CreateIcon(config.IconName, iconSize, iconColor, 0)
    icon.Name = "Icon"
    icon.AnchorPoint = Vector2.new(0.5, 0.5)
    icon.Position = UDim2.fromScale(0.5, 0.5)
    icon.ZIndex = button.ZIndex + 1
    icon.Parent = button

    -- Scale micro-compression on click
    local uiScale = Instance.new("UIScale")
    uiScale.Scale = 1.0
    uiScale.Parent = button

    local stroke = button:FindFirstChildOfClass("UIStroke")

    button.MouseButton1Down:Connect(function()
        TweenService:Create(uiScale, UITheme.Tweens.Snap, { Scale = 0.93 }):Play()
    end)

    button.MouseButton1Up:Connect(function()
        TweenService:Create(uiScale, UITheme.Tweens.Snap, { Scale = 1.0 }):Play()
    end)

    button.MouseEnter:Connect(function()
        TweenService:Create(button, UITheme.Tweens.Fast, {
            BackgroundTransparency = 0.15,
            BackgroundColor3 = config.IsCloseButton and Color3.fromRGB(45, 20, 22) or UITheme.Colors.GlassElevated,
        }):Play()
        if stroke then
            TweenService:Create(stroke, UITheme.Tweens.Fast, {
                Color = config.IsCloseButton and UITheme.Colors.BorderDanger or UITheme.Colors.BorderGlow,
                Transparency = 0.3,
            }):Play()
        end
    end)

    button.MouseLeave:Connect(function()
        TweenService:Create(uiScale, UITheme.Tweens.Snap, { Scale = 1.0 }):Play()
        TweenService:Create(button, UITheme.Tweens.Fast, {
            BackgroundTransparency = UITheme.Transparency.Button,
            BackgroundColor3 = config.IsCloseButton and UITheme.Colors.GlassElevated or UITheme.Colors.GlassSurface,
        }):Play()
        if stroke then
            TweenService:Create(stroke, UITheme.Tweens.Fast, {
                Color = config.IsCloseButton and UITheme.Colors.BorderSubtle or UITheme.Colors.BorderGlass,
                Transparency = UITheme.Transparency.Stroke,
            }):Play()
        end
    end)

    button.Activated:Connect(function()
        if config.IsCloseButton then
            UITheme.PlayClose()
        else
            UITheme.PlayClick()
        end
        if config.OnClick then
            config.OnClick()
        end
    end)

    if config.Tooltip and config.Tooltip ~= "" then
        local Tooltip = require(script.Parent:WaitForChild("Tooltip"))
        Tooltip.Attach(button, {
            Title = config.Tooltip,
            Width = 160,
        })
    end

    if config.Parent then
        button.Parent = config.Parent
    end

    return button
end

return IconButton
