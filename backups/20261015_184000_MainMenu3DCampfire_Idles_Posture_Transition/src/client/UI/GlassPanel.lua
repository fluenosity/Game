--!strict
--[[
    UI/GlassPanel.lua
    Modular Glassmorphic Card & Container Component
    "Don't Let the Fire Die" — Fluenosity Studio
]]

local UITheme = require(script.Parent:WaitForChild("UITheme"))

export type GlassPanelConfig = {
    Size: UDim2?,
    Position: UDim2?,
    AnchorPoint: Vector2?,
    Parent: Instance?,
    LayoutOrder: number?,
    ZIndex: number?,
    CornerRadius: number?,
    BackgroundTransparency: number?,
    BackgroundColor: Color3?,
    StrokeColor: Color3?,
    StrokeThickness: number?,
    IsActive: boolean?,
    Padding: (number | { Top: number?, Bottom: number?, Left: number?, Right: number? })?,
    ClipsDescendants: boolean?,
    Name: string?,
}

local GlassPanel = {}

function GlassPanel.Create(config: GlassPanelConfig): Frame
    local frame = Instance.new("Frame")
    frame.Name = config.Name or "GlassPanel"
    frame.Size = config.Size or UDim2.fromScale(1, 1)
    if config.Position then frame.Position = config.Position end
    if config.AnchorPoint then frame.AnchorPoint = config.AnchorPoint end
    frame.LayoutOrder = config.LayoutOrder or 0
    frame.ZIndex = config.ZIndex or 1
    frame.ClipsDescendants = config.ClipsDescendants or false

    -- Translucent obsidian glass base
    frame.BackgroundColor3 = config.BackgroundColor or UITheme.Colors.GlassSurface
    frame.BackgroundTransparency = config.BackgroundTransparency or (config.IsActive and 0.22 or UITheme.Transparency.Card)
    frame.BorderSizePixel = 0

    -- Apply luxury specular glass aesthetics
    UITheme.ApplyGlass(frame, {
        CornerRadius = config.CornerRadius or 12,
        StrokeColor = config.StrokeColor,
        StrokeThickness = config.StrokeThickness,
        IsActive = config.IsActive,
    })

    -- Optional padding
    if config.Padding then
        local pad = Instance.new("UIPadding")
        pad.Name = "PanelPadding"
        if type(config.Padding) == "number" then
            local p = config.Padding :: number
            pad.PaddingTop = UDim.new(0, p)
            pad.PaddingBottom = UDim.new(0, p)
            pad.PaddingLeft = UDim.new(0, p)
            pad.PaddingRight = UDim.new(0, p)
        elseif type(config.Padding) == "table" then
            local pt = config.Padding :: { Top: number?, Bottom: number?, Left: number?, Right: number? }
            pad.PaddingTop = UDim.new(0, pt.Top or 0)
            pad.PaddingBottom = UDim.new(0, pt.Bottom or 0)
            pad.PaddingLeft = UDim.new(0, pt.Left or 0)
            pad.PaddingRight = UDim.new(0, pt.Right or 0)
        end
        pad.Parent = frame
    end

    if config.Parent then
        frame.Parent = config.Parent
    end

    return frame
end

return GlassPanel
