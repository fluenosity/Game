--!strict
--[[
    MenuTheme.lua
    Compatibility re-export forwarding to UITheme.lua.
]]

local UITheme = require(script.Parent:WaitForChild("UITheme"))
return UITheme
