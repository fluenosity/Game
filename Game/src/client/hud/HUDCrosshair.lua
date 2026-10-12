--!strict
--[[
    HUDCrosshair.lua
    GTA V Style Minimalist Center Dot Crosshair for First-Person Perspective.
    Developed for "Don't Let the Fire Die" (Fluenosity Studio).
]]

local TweenService = game:GetService("TweenService")

local HUDCrosshair = {}

export type CrosshairInstance = {
    SetVisible: (visible: boolean) -> (),
    SetHovering: (hovering: boolean) -> (),
    Destroy: () -> (),
}

function HUDCrosshair.Create(parentScreenGui: ScreenGui): CrosshairInstance
    local root = Instance.new("Frame")
    root.Name = "HUDCrosshair"
    root.Size = UDim2.fromOffset(24, 24)
    root.Position = UDim2.fromScale(0.5, 0.5)
    root.AnchorPoint = Vector2.new(0.5, 0.5)
    root.BackgroundTransparency = 1
    root.BorderSizePixel = 0
    root.ZIndex = 50
    root.Visible = false
    root.Parent = parentScreenGui

    -- Center GTA V Dot (5x5 px crisp circle)
    local dot = Instance.new("Frame")
    dot.Name = "ReticleDot"
    dot.Size = UDim2.fromOffset(5, 5)
    dot.Position = UDim2.fromScale(0.5, 0.5)
    dot.AnchorPoint = Vector2.new(0.5, 0.5)
    dot.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    dot.BackgroundTransparency = 0.05
    dot.BorderSizePixel = 0
    dot.ZIndex = 51
    dot.Parent = root

    local dotCorner = Instance.new("UICorner")
    dotCorner.CornerRadius = UDim.new(1, 0)
    dotCorner.Parent = dot

    -- 1px dark contrast border (ensures visibility against white snow, bright fire, and light sky)
    local dotStroke = Instance.new("UIStroke")
    dotStroke.Color = Color3.fromRGB(12, 12, 16)
    dotStroke.Transparency = 0.35
    dotStroke.Thickness = 1.0
    dotStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    dotStroke.Parent = dot

    -- Subtle outer target ring for interaction feedback (hidden by default)
    local interactRing = Instance.new("Frame")
    interactRing.Name = "InteractRing"
    interactRing.Size = UDim2.fromOffset(14, 14)
    interactRing.Position = UDim2.fromScale(0.5, 0.5)
    interactRing.AnchorPoint = Vector2.new(0.5, 0.5)
    interactRing.BackgroundTransparency = 1
    interactRing.BorderSizePixel = 0
    interactRing.ZIndex = 51
    interactRing.Visible = false
    interactRing.Parent = root

    local ringCorner = Instance.new("UICorner")
    ringCorner.CornerRadius = UDim.new(1, 0)
    ringCorner.Parent = interactRing

    local ringStroke = Instance.new("UIStroke")
    ringStroke.Color = Color3.fromRGB(245, 160, 40) -- Amber glowing cue
    ringStroke.Transparency = 0.3
    ringStroke.Thickness = 1.2
    ringStroke.Parent = interactRing

    local isVisible = false
    local isHovering = false

    local function setVisible(visible: boolean)
        isVisible = visible
        root.Visible = visible
    end

    local function setHovering(hovering: boolean)
        if isHovering == hovering then return end
        isHovering = hovering

        if hovering then
            interactRing.Visible = true
            TweenService:Create(dot, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                Size = UDim2.fromOffset(6, 6),
                BackgroundColor3 = Color3.fromRGB(255, 220, 150),
            }):Play()
            TweenService:Create(ringStroke, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                Transparency = 0.2,
            }):Play()
        else
            TweenService:Create(dot, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                Size = UDim2.fromOffset(5, 5),
                BackgroundColor3 = Color3.fromRGB(255, 255, 255),
            }):Play()
            TweenService:Create(ringStroke, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
                Transparency = 1,
            }):Play()
            task.delay(0.15, function()
                if not isHovering then
                    interactRing.Visible = false
                end
            end)
        end
    end

    return {
        SetVisible = setVisible,
        SetHovering = setHovering,
        Destroy = function()
            root:Destroy()
        end,
    }
end

return HUDCrosshair
