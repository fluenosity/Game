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

local UI = require(script.Parent.Parent:WaitForChild("UI"))

export type HUDSettingsButtonInstance = {
    Button: GuiObject,
    SetOnClick: (callback: () -> ()) -> (),
    Destroy: () -> (),
}

local HUDSettingsButton = {}

function HUDSettingsButton.Create(parent: Instance): HUDSettingsButtonInstance
    local clickCallback: (() -> ())? = nil

    local btn = UI.IconButton.Create({
        IconName = "settings",
        IconSize = 18,
        Size = 38,
        Position = UDim2.new(1, -22, 0, 10),
        AnchorPoint = Vector2.new(1, 0),
        ZIndex = 50,
        Tooltip = "Settings (ESC)",
        Parent = parent,
        OnClick = function()
            if clickCallback then
                clickCallback()
            end
        end,
    })

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
