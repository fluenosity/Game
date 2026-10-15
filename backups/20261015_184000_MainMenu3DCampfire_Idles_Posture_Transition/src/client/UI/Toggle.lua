--!strict
--[[
    Toggle.lua
    Luxury Glassmorphic Toggle Switch Component for "Don't Let the Fire Die".
    Part of the production UI library (FluenosityClient/UI).
    
    Features:
    - Frosted capsule switch track with specular stroke
    - Glowing amber thumb when ON, muted obsidian when OFF
    - Tactile micro-compression on click (Scale = 0.96)
    - Zero hover bounce; pleasant click audio
    - Responsive layout with Title, optional Description, and Switch pill
]]

local TweenService = game:GetService("TweenService")
local UITheme = require(script.Parent:WaitForChild("UITheme"))
local AudioManager = require(script.Parent.Parent:WaitForChild("AudioManager"))

export type ToggleConfig = {
    Label: string,
    Description: string?,
    InitialValue: boolean?,
    LayoutOrder: number?,
    Parent: Instance?,
    OnChanged: ((value: boolean) -> ())?,
}

export type ToggleInstance = {
    Container: Frame,
    GetValue: () -> boolean,
    SetValue: (value: boolean, fireCallback: boolean?) -> (),
    SetEnabled: (enabled: boolean) -> (),
    Destroy: () -> (),
}

local Toggle = {}

function Toggle.Create(config: ToggleConfig): ToggleInstance
    local isEnabled = config.InitialValue or false
    local isInteractable = true

    local container = Instance.new("Frame")
    container.Name = "Toggle_" .. config.Label:gsub("%s+", "")
    container.Size = UDim2.new(1, 0, 0, config.Description and 48 or 36)
    container.BackgroundTransparency = 1
    container.BorderSizePixel = 0
    container.LayoutOrder = config.LayoutOrder or 0
    container.ZIndex = 10

    -- Left text block (Title + optional description)
    local textBlock = Instance.new("Frame")
    textBlock.Name = "TextBlock"
    textBlock.Size = UDim2.new(1, -70, 1, 0)
    textBlock.Position = UDim2.fromScale(0, 0)
    textBlock.BackgroundTransparency = 1
    textBlock.ZIndex = 11
    textBlock.Parent = container

    local title = Instance.new("TextLabel")
    title.Name = "Title"
    title.Size = UDim2.new(1, 0, 0, 18)
    title.Position = UDim2.fromOffset(0, config.Description and 2 or 9)
    title.BackgroundTransparency = 1
    title.Font = UITheme.Fonts.Subheading
    title.Text = config.Label
    title.TextColor3 = UITheme.Colors.TextPrimary
    title.TextSize = 13
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.ZIndex = 12
    title.Parent = textBlock

    if config.Description then
        local desc = Instance.new("TextLabel")
        desc.Name = "Description"
        desc.Size = UDim2.new(1, 0, 0, 16)
        desc.Position = UDim2.fromOffset(0, 22)
        desc.BackgroundTransparency = 1
        desc.Font = UITheme.Fonts.Body
        desc.Text = config.Description
        desc.TextColor3 = UITheme.Colors.TextMuted
        desc.TextSize = 11
        desc.TextXAlignment = Enum.TextXAlignment.Left
        desc.ZIndex = 12
        desc.Parent = textBlock
    end

    -- Switch Capsule Pill
    local switchBtn = Instance.new("TextButton")
    switchBtn.Name = "SwitchPill"
    switchBtn.Size = UDim2.fromOffset(50, 26)
    switchBtn.Position = UDim2.fromScale(1, 0.5)
    switchBtn.AnchorPoint = Vector2.new(1, 0.5)
    switchBtn.BackgroundColor3 = isEnabled and Color3.fromRGB(195, 115, 25) or Color3.fromRGB(22, 20, 26)
    switchBtn.BackgroundTransparency = isEnabled and 0.15 or 0.35
    switchBtn.BorderSizePixel = 0
    switchBtn.AutoButtonColor = false
    switchBtn.Text = ""
    switchBtn.ZIndex = 12
    switchBtn.Parent = container

    local switchCorner = Instance.new("UICorner")
    switchCorner.CornerRadius = UDim.new(1, 0)
    switchCorner.Parent = switchBtn

    local switchStroke = Instance.new("UIStroke")
    switchStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    switchStroke.Color = isEnabled and UITheme.Colors.EmberHot or Color3.fromRGB(255, 255, 255)
    switchStroke.Transparency = isEnabled and 0.3 or 0.85
    switchStroke.Thickness = 1
    switchStroke.Parent = switchBtn

    -- Scale constraint for tactile click compression
    local btnScale = Instance.new("UIScale")
    btnScale.Scale = 1
    btnScale.Parent = switchBtn

    -- Thumb / Knob
    local knob = Instance.new("Frame")
    knob.Name = "Knob"
    knob.Size = UDim2.fromOffset(20, 20)
    knob.Position = isEnabled and UDim2.new(1, -23, 0.5, 0) or UDim2.new(0, 3, 0.5, 0)
    knob.AnchorPoint = Vector2.new(0, 0.5)
    knob.BackgroundColor3 = isEnabled and Color3.fromRGB(255, 245, 230) or Color3.fromRGB(150, 155, 165)
    knob.BorderSizePixel = 0
    knob.ZIndex = 13
    knob.Parent = switchBtn

    local knobCorner = Instance.new("UICorner")
    knobCorner.CornerRadius = UDim.new(1, 0)
    knobCorner.Parent = knob

    local knobGlow = Instance.new("UIStroke")
    knobGlow.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    knobGlow.Color = isEnabled and UITheme.Colors.EmberGold or Color3.fromRGB(255, 255, 255)
    knobGlow.Transparency = isEnabled and 0.4 or 0.88
    knobGlow.Thickness = 1
    knobGlow.Parent = knob

    local function renderState(animated: boolean)
        local targetKnobPos = isEnabled and UDim2.new(1, -23, 0.5, 0) or UDim2.new(0, 3, 0.5, 0)
        local targetSwitchBg = isEnabled and Color3.fromRGB(195, 115, 25) or Color3.fromRGB(22, 20, 26)
        local targetSwitchTrans = isEnabled and 0.15 or 0.35
        local targetStrokeColor = isEnabled and UITheme.Colors.EmberHot or Color3.fromRGB(255, 255, 255)
        local targetStrokeTrans = isEnabled and 0.3 or 0.85
        local targetKnobColor = isEnabled and Color3.fromRGB(255, 245, 230) or Color3.fromRGB(150, 155, 165)
        local targetGlowColor = isEnabled and UITheme.Colors.EmberGold or Color3.fromRGB(255, 255, 255)

        if animated then
            local tweenInfo = TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
            TweenService:Create(knob, tweenInfo, {
                Position = targetKnobPos,
                BackgroundColor3 = targetKnobColor,
            }):Play()
            TweenService:Create(switchBtn, tweenInfo, {
                BackgroundColor3 = targetSwitchBg,
                BackgroundTransparency = targetSwitchTrans,
            }):Play()
            TweenService:Create(switchStroke, tweenInfo, {
                Color = targetStrokeColor,
                Transparency = targetStrokeTrans,
            }):Play()
            TweenService:Create(knobGlow, tweenInfo, {
                Color = targetGlowColor,
            }):Play()
        else
            knob.Position = targetKnobPos
            knob.BackgroundColor3 = targetKnobColor
            switchBtn.BackgroundColor3 = targetSwitchBg
            switchBtn.BackgroundTransparency = targetSwitchTrans
            switchStroke.Color = targetStrokeColor
            switchStroke.Transparency = targetStrokeTrans
            knobGlow.Color = targetGlowColor
        end
    end

    local function toggleValue(fireCallback: boolean?)
        if not isInteractable then return end
        isEnabled = not isEnabled

        -- Tactile compression
        btnScale.Scale = 0.94
        task.delay(0.08, function()
            TweenService:Create(btnScale, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                Scale = 1,
            }):Play()
        end)

        AudioManager.Play("Click")
        renderState(true)

        if fireCallback ~= false and config.OnChanged then
            config.OnChanged(isEnabled)
        end
    end

    switchBtn.Activated:Connect(function()
        toggleValue(true)
    end)

    if config.Parent then
        container.Parent = config.Parent
    end

    return {
        Container = container,
        GetValue = function(): boolean
            return isEnabled
        end,
        SetValue = function(val: boolean, fireCallback: boolean?)
            if isEnabled ~= val then
                isEnabled = val
                renderState(true)
                if fireCallback and config.OnChanged then
                    config.OnChanged(isEnabled)
                end
            end
        end,
        SetEnabled = function(enabled: boolean)
            isInteractable = enabled
            container.GroupTransparency = enabled and 0 or 0.5
        end,
        Destroy = function()
            container:Destroy()
        end,
    }
end

return Toggle
