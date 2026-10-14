--!strict
--[[
    UIComponents.lua
    Production backward-compatibility facade forwarding to the modular UI library (src/client/UI/).
    Developed for Fluenosity Studio.
]]

local UI = require(script.Parent:WaitForChild("UI"))

local UIComponents = {
    UI = UI,
    Theme = UI.Theme,
    CreateModal = UI.Modal.Create,
    CreateSlider = UI.Slider.Create,
    CreateToggle = UI.Toggle.Create,
    CreateDivider = UI.Divider.Create,
    CreateLoadingScreen = UI.LoadingScreen.Create,
    CreateSystemMenu = UI.SystemMenu.Create,
    CreateButton = UI.Button.Create,
    CreateIconButton = UI.IconButton.Create,
    CreateTooltip = UI.Tooltip.Attach,
    CreateProgressBar = UI.ProgressBar.Create,
    CreateBadge = UI.Badge.Create,
    CreateTabs = UI.Tabs.Create,
    CreateDialogBox = UI.DialogBox.Create,
}

return UIComponents
