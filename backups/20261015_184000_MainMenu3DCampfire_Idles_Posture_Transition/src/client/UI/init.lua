--!strict
--[[
    UI/init.lua
    Central Barrel Export for the Modular Glassmorphism Design System
    "Don't Let the Fire Die" — Fluenosity Studio
]]

local UI = {
    Theme       = require(script:WaitForChild("UITheme")),
    Panel       = require(script:WaitForChild("GlassPanel")),
    Button      = require(script:WaitForChild("Button")),
    IconButton  = require(script:WaitForChild("IconButton")),
    Modal       = require(script:WaitForChild("Modal")),
    Slider      = require(script:WaitForChild("Slider")),
    Tooltip     = require(script:WaitForChild("Tooltip")),
    ProgressBar = require(script:WaitForChild("ProgressBar")),
    Badge       = require(script:WaitForChild("Badge")),
    Tabs        = require(script:WaitForChild("Tabs")),
    DialogBox   = require(script:WaitForChild("DialogBox")),
    Divider     = require(script:WaitForChild("Divider")),
    Toggle      = require(script:WaitForChild("Toggle")),
    SystemMenu  = require(script:WaitForChild("SystemMenu")),
    LoadingScreen = require(script:WaitForChild("LoadingScreen")),
}

return UI
