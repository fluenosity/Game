--!strict
--[[
    UI/Divider.lua
    Modular Hairline Glass Divider Component
    "Don't Let the Fire Die" — Fluenosity Studio
]]

local UITheme = require(script.Parent:WaitForChild("UITheme"))

export type DividerConfig = {
    Orientation: ("Horizontal" | "Vertical")?,
    Thickness: number?,
    Color: Color3?,
    Transparency: number?,
    Size: UDim2?,
    LayoutOrder: number?,
    ZIndex: number?,
    Parent: Instance?,
}

local Divider = {}

function Divider.Create(config: DividerConfig?): Frame
    local conf = config or {}
    local orientation = conf.Orientation or "Horizontal"
    local thickness = conf.Thickness or 1

    local div = Instance.new("Frame")
    div.Name = "Divider"
    if orientation == "Vertical" then
        div.Size = conf.Size or UDim2.new(0, thickness, 1, 0)
    else
        div.Size = conf.Size or UDim2.new(1, 0, 0, thickness)
    end
    div.BackgroundColor3 = conf.Color or UITheme.Colors.BorderSubtle
    div.BackgroundTransparency = conf.Transparency or 0.65
    div.BorderSizePixel = 0
    div.LayoutOrder = conf.LayoutOrder or 0
    div.ZIndex = conf.ZIndex or 5

    -- Specular fade gradient
    local grad = Instance.new("UIGradient")
    grad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(80, 100, 130)),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(200, 220, 255)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(80, 100, 130)),
    })
    grad.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.8),
        NumberSequenceKeypoint.new(0.5, 0.2),
        NumberSequenceKeypoint.new(1, 0.8),
    })
    grad.Parent = div

    if conf.Parent then
        div.Parent = conf.Parent
    end

    return div
end

return Divider
