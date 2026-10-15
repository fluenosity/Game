--!strict
--[[
    UI/Tooltip.lua
    Modular Glassmorphic Floating Tooltip Component
    "Don't Let the Fire Die" — Fluenosity Studio

    Features:
    - Attach to any GuiObject with Tooltip.Attach(target, config)
    - Auto-clamps to screen viewport bounds (responsive across all devices)
    - Smart positioning:
      * Top zone (<40% screen / headers / topbars): displays BELOW anchor so it never covers buttons
      * Bottom zone (>=40% screen / hotbars / vitals): displays ABOVE anchor
      * Horizontal alignment: right-aligns for buttons on right, left-aligns for left, centers for middle
    - Dual styling:
      * Simple tooltips (title-only icon buttons like [X]): ultra-compact glass pill auto-sized to text
      * Rich tooltips (backpack/settings/hotbar): full glass card with category badge, description & hint
    - Smooth fade & micro-elevation ease
]]

local TweenService = game:GetService("TweenService")
local TextService = game:GetService("TextService")
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

        local isSimple = (config.Description == nil or config.Description == "")
            and (config.ActionHint == nil or config.ActionHint == "")
            and (config.Category == nil or config.Category == "")

        -- Determine exact dimensions
        local tipWidth: number
        local tipHeight: number

        if isSimple then
            local textBounds = TextService:GetTextSize(
                config.Title,
                11,
                UITheme.Fonts.Heading,
                Vector2.new(300, 30)
            )
            tipWidth = config.Width or math.clamp(math.ceil(textBounds.X) + 20, 60, 240)
            tipHeight = 26
        else
            tipWidth = config.Width or 220
            local descHeight = 0
            if config.Description and config.Description ~= "" then
                local descBounds = TextService:GetTextSize(
                    config.Description,
                    11,
                    UITheme.Fonts.Body,
                    Vector2.new(tipWidth - 24, 1000)
                )
                descHeight = math.ceil(descBounds.Y) + 4
            end
            local hintHeight = (config.ActionHint and config.ActionHint ~= "") and 18 or 0
            tipHeight = 20 + 18 + descHeight + hintHeight
        end

        -- Viewport & position calculations
        local targetPos = target.AbsolutePosition
        local targetSize = target.AbsoluteSize
        local camera = workspace.CurrentCamera
        local vpSize = camera and camera.ViewportSize or Vector2.new(1920, 1080)

        local SCREEN_MARGIN = 12
        local GAP = 8
        local GUI_INSET = 36 -- Topbar inset height

        -- Horizontal calculation:
        -- Right zone (>65%) -> right-align with target (prevents spilling left over adjacent buttons)
        -- Left zone (<35%) -> left-align with target
        -- Middle zone -> center-align on target
        local targetCenterX = targetPos.X + (targetSize.X / 2)
        local screenFractionX = targetCenterX / vpSize.X
        local posX: number

        if screenFractionX > 0.65 then
            posX = (targetPos.X + targetSize.X) - tipWidth
        elseif screenFractionX < 0.35 then
            posX = targetPos.X
        else
            posX = targetCenterX - (tipWidth / 2)
        end

        posX = math.clamp(posX, SCREEN_MARGIN, vpSize.X - tipWidth - SCREEN_MARGIN)

        -- Vertical calculation:
        -- Top zone (<40% screen, headers, top widgets): ALWAYS place BELOW anchor so it never covers buttons
        -- Lower zone (>=40% screen, hotbars, inventory): place ABOVE anchor
        local targetCenterY = targetPos.Y + (targetSize.Y / 2)
        local screenFractionY = targetCenterY / vpSize.Y
        local spaceAbove = targetPos.Y - GUI_INSET

        local placeBelow = (screenFractionY < 0.40) or (spaceAbove < (tipHeight + GAP))
        local posY: number
        local animOffsetY: number

        if placeBelow then
            posY = targetPos.Y + targetSize.Y + GAP
            animOffsetY = -4
        else
            posY = targetPos.Y - tipHeight - GAP
            animOffsetY = 4
            if posY < GUI_INSET then
                posY = targetPos.Y + targetSize.Y + GAP
                animOffsetY = -4
            end
        end

        posY = math.clamp(posY, GUI_INSET, vpSize.Y - tipHeight - SCREEN_MARGIN)

        -- Construct Floating Tooltip Frame
        local tip = Instance.new("Frame")
        tip.Name = "FloatingTooltip"
        tip.Size = UDim2.fromOffset(tipWidth, tipHeight)
        tip.BackgroundColor3 = Color3.fromRGB(12, 14, 18)
        tip.BackgroundTransparency = 0.15
        tip.BorderSizePixel = 0
        tip.ZIndex = 1000

        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, isSimple and 6 or 8)
        corner.Parent = tip

        local stroke = Instance.new("UIStroke")
        stroke.Color = Color3.fromRGB(255, 255, 255)
        stroke.Transparency = 0.84
        stroke.Thickness = 1
        stroke.Parent = tip

        if isSimple then
            local padding = Instance.new("UIPadding")
            padding.PaddingTop = UDim.new(0, 3)
            padding.PaddingBottom = UDim.new(0, 3)
            padding.PaddingLeft = UDim.new(0, 10)
            padding.PaddingRight = UDim.new(0, 10)
            padding.Parent = tip

            local title = Instance.new("TextLabel")
            title.Name = "Title"
            title.Size = UDim2.fromScale(1, 1)
            title.BackgroundTransparency = 1
            title.Font = UITheme.Fonts.Heading
            title.Text = config.Title
            title.TextColor3 = UITheme.Colors.TextPrimary
            title.TextSize = 11
            title.TextXAlignment = Enum.TextXAlignment.Center
            title.TextYAlignment = Enum.TextYAlignment.Center
            title.Parent = tip
        else
            local padding = Instance.new("UIPadding")
            padding.PaddingTop = UDim.new(0, 10)
            padding.PaddingBottom = UDim.new(0, 10)
            padding.PaddingLeft = UDim.new(0, 12)
            padding.PaddingRight = UDim.new(0, 12)
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
        end

        tip.Position = UDim2.new(0, posX, 0, posY + animOffsetY)
        tip.Parent = layer
        activeTooltipFrame = tip

        -- Smooth entrance
        tip.BackgroundTransparency = 1
        TweenService:Create(tip, UITheme.Tweens.Fast, {
            BackgroundTransparency = 0.15,
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
