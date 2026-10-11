--!strict
--[[
    HUDSettingsButton.lua
    Top-right glassmorphic circular settings gear button.
    Developed for Fluenosity Studio. Matches mockup layout.
]]

local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local sharedFolder = ReplicatedStorage:WaitForChild("FluenosityShared")
local IconPack = require(sharedFolder:WaitForChild("IconPack"))

export type HUDSettingsButtonInstance = {
    Button: TextButton,
    SetOnClick: (callback: () -> ()) -> (),
    Destroy: () -> (),
}

local HUDSettingsButton = {}

function HUDSettingsButton.Create(parent: Instance): HUDSettingsButtonInstance
    local btn = Instance.new("TextButton")
    btn.Name = "HUDSettingsButton"
    btn.Size = UDim2.fromOffset(38, 38)
    btn.Position = UDim2.new(1, -22, 0, 10)
    btn.AnchorPoint = Vector2.new(1, 0)
    btn.BackgroundColor3 = Color3.fromRGB(16, 18, 22)
    btn.BackgroundTransparency = 0.32
    btn.BorderSizePixel = 0
    btn.Text = ""
    btn.AutoButtonColor = false
    btn.ZIndex = 50
    btn.Parent = parent

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(1, 0)
    corner.Parent = btn

    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(255, 255, 255)
    stroke.Transparency = 0.86
    stroke.Thickness = 1
    stroke.Parent = btn

    local icon = IconPack.CreateIcon("settings", 18, Color3.fromRGB(225, 230, 240))
    icon.Name = "GearIcon"
    icon.Position = UDim2.fromScale(0.5, 0.5)
    icon.AnchorPoint = Vector2.new(0.5, 0.5)
    icon.ZIndex = 51
    icon.Parent = btn

    local clickCallback: (() -> ())? = nil

    btn.MouseEnter:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            BackgroundTransparency = 0.18,
            Size = UDim2.fromOffset(41, 41),
        }):Play()
        TweenService:Create(stroke, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            Color = Color3.fromRGB(245, 170, 50),
            Transparency = 0.35,
        }):Play()
        TweenService:Create(icon, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
            Rotation = 45,
            ImageColor3 = Color3.fromRGB(255, 255, 255),
        }):Play()
    end)

    btn.MouseLeave:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            BackgroundTransparency = 0.32,
            Size = UDim2.fromOffset(38, 38),
        }):Play()
        TweenService:Create(stroke, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            Color = Color3.fromRGB(255, 255, 255),
            Transparency = 0.86,
        }):Play()
        TweenService:Create(icon, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            Rotation = 0,
            ImageColor3 = Color3.fromRGB(225, 230, 240),
        }):Play()
    end)

    btn.Activated:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.08, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            Size = UDim2.fromOffset(36, 36),
        }):Play()
        task.delay(0.08, function()
            TweenService:Create(btn, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                Size = UDim2.fromOffset(41, 41),
            }):Play()
        end)
        if clickCallback then
            clickCallback()
        end
    end)

    return {
        Button = btn,
        SetOnClick = function(callback: () -> ())
            clickCallback = callback
        end,
        Destroy = function()
            btn:Destroy()
        end,
    }
end

return HUDSettingsButton
