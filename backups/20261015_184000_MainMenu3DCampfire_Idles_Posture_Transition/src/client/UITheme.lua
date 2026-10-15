--!strict
--[[
    UITheme.lua
    Single source of truth design system re-export.
    Delegates directly to modular FluenosityClient/UI/UITheme.lua.
]]

local UIModule = script.Parent:WaitForChild("UI")
local UITheme = require(UIModule:WaitForChild("UITheme"))

return UITheme
