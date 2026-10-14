--!strict
--[[
    UI/Tooltip.lua
    Modular Glassmorphic Floating Tooltip Component
    "Don't Let the Fire Die" — Fluenosity Studio

    Features:
    - Attach to any GuiObject with Tooltip.Attach(target, config)
    - Auto-clamps to screen viewport bounds (responsive)
    - Luxury frosted glass with specular border and category badge
    - Smooth fade & micro-elevation ease
    - Smart placement: shows BELOW anchor when near top 25% of screen
      (fixes top-right widget tooltips stacking on the widget)
]]


local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local UITheme = require(script.Parent:WaitForChild("UITheme"))

export type TooltipConfig = {
    Title: string,
    Category: string?,
    Description: string?,
    ActionHint: string?,
    Width: number?,
}

local Tooltip = {}

local activeTooltipFrame: Frame? = nil
local activeScreenGui: ScreenGui? = nil

local function getTooltipLayer(): ScreenGui
    if activeScreenGui and activeScreenGui.Parent then
        return activeScreenGui
    end

    local player = Players.LocalPlayer
    local playerGui = player:WaitForChild("PlayerGui")
    local gui = playerGui:FindFirstChild("GlassTooltipGui") :: ScreenGui?

    if not gui then
        gui = Instance.new("ScreenGui")
        gui.Name = "GlassTooltipGui"
        gui.DisplayOrder = 999 -- Topmost UI layer
        gui.ResetOnSpawn = false
        gui.IgnoreGuiInset = true
        gui.Parent = playerGui
    end

    activeScreenGui = gui
    return gui
end

function Tooltip.Attach(target: GuiObject, config: TooltipConfig)
    local hoverConnection: RBXScriptConnection? = nil
    local leaveConnection: RBXScriptConnection? = nil
    local isHovered = false

    local function showTooltip()
        local layer = getTooltipLayer()

        if activeTooltipFrame then
            activeTooltipFrame:Destroy()
            activeTooltipFrame = nil
        end

        local tip = Instance.new("Frame")
        tip.Name = "FloatingTooltip"
        tip.Size = UDim2.new(0, config.Width or 240, 0, 0)
        tip.AutomaticSize = Enum.AutomaticSize.Y
        tip.BackgroundColor3 = UITheme.Colors.GlassModal
        tip.BackgroundTransparency = 0.20
        tip.BorderSizePixel = 0
        tip.ZIndex = 1000

        UITheme.ApplyGlass(tip, {
            CornerRadius = 10,
            StrokeColor = UITheme.Colors.BorderGlass,
            StrokeThickness = 1.2,
        })

        local padding = Instance.new("UIPadding")
        padding.PaddingTop = UDim.new(0, 10)
        padding.PaddingBottom = UDim.new(0, 10)
        padding.PaddingLeft = UDim.new(0, 14)
        padding.PaddingRight = UDim.new(0, 14)
        padding.Parent = tip

        local layout = Instance.new("UIListLayout")
        layout.FillDirection = Enum.FillDirection.Vertical
        layout.Padding = UDim.new(0, 4)
        layout.SortOrder = Enum.SortOrder.LayoutOrder
        layout.Parent = tip

        -- Header row (Title + Category Badge)
        local headerRow = Instance.new("Frame")
        headerRow.Name = "HeaderRow"
        headerRow.Size = UDim2.new(1, 0, 0, 18)
        headerRow.BackgroundTransparency = 1
        headerRow.LayoutOrder = 1
        headerRow.Parent = tip

        local title = Instance.new("TextLabel")
        title.Name = "Title"
        title.Size = UDim2.new(1, config.Category and -70 or 0, 1, 0)
        title.BackgroundTransparency = 1
        title.Font = UITheme.Fonts.Heading
        title.Text = config.Title
        title.TextColor3 = UITheme.Colors.TextPrimary
        title.TextSize = 13
        title.TextXAlignment = Enum.TextXAlignment.Left
        title.TextTruncate = Enum.TextTruncate.AtEnd
        title.Parent = headerRow

        if config.Category then
            local badge = Instance.new("TextLabel")
            badge.Name = "Category"
            badge.Size = UDim2.new(0, 65, 1, 0)
            badge.Position = UDim2.new(1, -65, 0, 0)
            badge.BackgroundTransparency = 1
            badge.Font = UITheme.Fonts.Heading
            badge.Text = config.Category
            badge.TextColor3 = UITheme.Colors.EmberHot
            badge.TextSize = 9
            badge.TextXAlignment = Enum.TextXAlignment.Right
            badge.Parent = headerRow
        end

        -- Description Body
        if config.Description and config.Description ~= "" then
            local desc = Instance.new("TextLabel")
            desc.Name = "Desc"
            desc.Size = UDim2.new(1, 0, 0, 0)
            desc.AutomaticSize = Enum.AutomaticSize.Y
            desc.BackgroundTransparency = 1
            desc.Font = UITheme.Fonts.Body
            desc.Text = config.Description
            desc.TextColor3 = UITheme.Colors.TextSecondary
            desc.TextSize = 11
            desc.TextWrapped = true
            desc.TextXAlignment = Enum.TextXAlignment.Left
            desc.LayoutOrder = 2
            desc.Parent = tip
        end

        -- Action Hint Footer
        if config.ActionHint and config.ActionHint ~= "" then
            local hint = Instance.new("TextLabel")
            hint.Name = "ActionHint"
            hint.Size = UDim2.new(1, 0, 0, 14)
            hint.BackgroundTransparency = 1
            hint.Font = UITheme.Fonts.Caption
            hint.Text = "⚡ " .. config.ActionHint
            hint.TextColor3 = UITheme.Colors.EmberGold
            hint.TextSize = 10
            hint.TextXAlignment = Enum.TextXAlignment.Left
            hint.LayoutOrder = 3
            hint.Parent = tip
        end

        -- Smart position calculation with viewport clamping
        local targetPos = target.AbsolutePosition
        local targetSize = target.AbsoluteSize
        local camera = workspace.CurrentCamera
        local vpSize = camera and camera.ViewportSize or Vector2.new(1920, 1080)

        local tipWidth = config.Width or 220
        local TOOLTIP_H_EST = 85
        local MARGIN = 10
        local SCREEN_MARGIN = 12

        -- Horizontal: center-align on target, clamped to screen edges
        local posX = targetPos.X + (targetSize.X / 2) - (tipWidth / 2)
        posX = math.clamp(posX, SCREEN_MARGIN, vpSize.X - tipWidth - SCREEN_MARGIN)

        -- Vertical: show BELOW when anchor is in top 25% of screen
        -- (fixes top-right widget tooltips covering buttons)
        local isNearTop = (targetPos.Y / vpSize.Y) < 0.25
        local posY: number
        local animOffsetY: number

        if isNearTop then
            posY = targetPos.Y + targetSize.Y + MARGIN
            animOffsetY = -4
        else
            posY = targetPos.Y - TOOLTIP_H_EST - MARGIN
            animOffsetY = 4
            if posY < SCREEN_MARGIN then
                posY = targetPos.Y + targetSize.Y + MARGIN
                animOffsetY = -4
            end
        end

        posY = math.clamp(posY, SCREEN_MARGIN, vpSize.Y - TOOLTIP_H_EST - SCREEN_MARGIN)

        tip.Position = UDim2.new(0, posX, 0, posY + animOffsetY)
        tip.Parent = layer
        activeTooltipFrame = tip

        -- Smooth entrance
        tip.BackgroundTransparency = 1
        TweenService:Create(tip, UITheme.Tweens.Fast, {
            BackgroundTransparency = 0.20,
            Position = UDim2.new(0, posX, 0, posY),
        }):Play()
    end

    local function hideTooltip()
        if activeTooltipFrame then
            local tip = activeTooltipFrame
            activeTooltipFrame = nil
            local t = TweenService:Create(tip, UITheme.Tweens.Snap, { BackgroundTransparency = 1 })
            t:Play()
            t.Completed:Once(function()
                tip:Destroy()
            end)
        end
    end

    -- Clean up any previous tooltip on this target
    if target:FindFirstChild("_TooltipCleanup") then
        local old = target:FindFirstChild("_TooltipCleanup")
        if old then old:Destroy() end
    end

    local cleanupFolder = Instance.new("Folder")
    cleanupFolder.Name = "_TooltipCleanup"
    cleanupFolder.Parent = target

    local function cleanup()
        if hoverConnection then
            hoverConnection:Disconnect()
            hoverConnection = nil
        end
        if leaveConnection then
            leaveConnection:Disconnect()
            leaveConnection = nil
        end
        if isHovered then
            hideTooltip()
        end
        if cleanupFolder.Parent then
            cleanupFolder:Destroy()
        end
    end

    hoverConnection = target.MouseEnter:Connect(function()
        isHovered = true
        task.delay(0.18, function()
            if isHovered then
                showTooltip()
            end
        end)
    end)

    leaveConnection = target.MouseLeave:Connect(function()
        isHovered = false
        hideTooltip()
    end)

    return cleanup
end

function Tooltip.Detach(target: GuiObject)
    local old = target:FindFirstChild("_TooltipCleanup")
    if old then
        old:Destroy()
    end
end

return Tooltip
