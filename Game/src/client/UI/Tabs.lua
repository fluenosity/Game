--!strict
--[[
    UI/Tabs.lua
    Modular Glassmorphic Tab Switcher Component
    "Don't Let the Fire Die" — Fluenosity Studio
]]

local TweenService = game:GetService("TweenService")
local UITheme = require(script.Parent:WaitForChild("UITheme"))

export type TabItem = {
    Id: string,
    Label: string,
    IconName: string?,
}

export type TabsConfig = {
    Tabs: { TabItem },
    DefaultId: string?,
    Size: UDim2?,
    Position: UDim2?,
    AnchorPoint: Vector2?,
    LayoutOrder: number?,
    ZIndex: number?,
    Parent: Instance?,
    OnTabSelected: (tabId: string) -> (),
}

export type TabsInstance = {
    Frame: Frame,
    SelectTab: (tabId: string) -> (),
    GetCurrentTab: () -> string,
    Destroy: () -> (),
}

local Tabs = {}

function Tabs.Create(config: TabsConfig): TabsInstance
    local currentId = config.DefaultId or (config.Tabs[1] and config.Tabs[1].Id or "")
    local buttonNodes: { [string]: TextButton } = {}

    local container = Instance.new("Frame")
    container.Name = "TabStrip"
    container.Size = config.Size or UDim2.new(1, 0, 0, 38)
    if config.Position then container.Position = config.Position end
    if config.AnchorPoint then container.AnchorPoint = config.AnchorPoint end
    container.LayoutOrder = config.LayoutOrder or 0
    container.ZIndex = config.ZIndex or 5
    container.BackgroundColor3 = UITheme.Colors.GlassSurface
    container.BackgroundTransparency = UITheme.Transparency.Card
    container.BorderSizePixel = 0

    UITheme.ApplyGlass(container, {
        CornerRadius = 10,
        StrokeColor = UITheme.Colors.BorderSubtle,
        StrokeThickness = 1.0,
    })

    local padding = Instance.new("UIPadding")
    padding.PaddingTop = UDim.new(0, 4)
    padding.PaddingBottom = UDim.new(0, 4)
    padding.PaddingLeft = UDim.new(0, 4)
    padding.PaddingRight = UDim.new(0, 4)
    padding.Parent = container

    local layout = Instance.new("UIListLayout")
    layout.FillDirection = Enum.FillDirection.Horizontal
    layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    layout.VerticalAlignment = Enum.VerticalAlignment.Center
    layout.Padding = UDim.new(0, 6)
    layout.Parent = container

    local function updateVisuals()
        for tabId, btn in pairs(buttonNodes) do
            local isSelected = (tabId == currentId)
            local stroke = btn:FindFirstChildOfClass("UIStroke")
            local label = btn:FindFirstChild("TabLabel") :: TextLabel?

            TweenService:Create(btn, UITheme.Tweens.Fast, {
                BackgroundColor3 = isSelected and UITheme.Colors.GlassElevated or UITheme.Colors.GlassSurface,
                BackgroundTransparency = isSelected and 0.15 or 1,
            }):Play()

            if stroke then
                TweenService:Create(stroke, UITheme.Tweens.Fast, {
                    Color = isSelected and UITheme.Colors.EmberHot or UITheme.Colors.BorderSubtle,
                    Transparency = isSelected and 0.20 or 1,
                }):Play()
            end

            if label then
                label.TextColor3 = isSelected and UITheme.Colors.TextPrimary or UITheme.Colors.TextMuted
                label.Font = isSelected and UITheme.Fonts.Heading or UITheme.Fonts.Body
            end
        end
    end

    local tabCount = math.max(1, #config.Tabs)
    for i, tab in ipairs(config.Tabs) do
        local btn = Instance.new("TextButton")
        btn.Name = "Tab_" .. tab.Id
        btn.Size = UDim2.new(1 / tabCount, -6, 1, 0)
        btn.BackgroundColor3 = UITheme.Colors.GlassElevated
        btn.BackgroundTransparency = (tab.Id == currentId) and 0.15 or 1
        btn.BorderSizePixel = 0
        btn.AutoButtonColor = false
        btn.Text = ""

        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 8)
        corner.Parent = btn

        local stroke = Instance.new("UIStroke")
        stroke.Thickness = 1.0
        stroke.Color = (tab.Id == currentId) and UITheme.Colors.EmberHot or UITheme.Colors.BorderSubtle
        stroke.Transparency = (tab.Id == currentId) and 0.20 or 1
        stroke.Parent = btn

        local label = Instance.new("TextLabel")
        label.Name = "TabLabel"
        label.Size = UDim2.fromScale(1, 1)
        label.BackgroundTransparency = 1
        label.Font = (tab.Id == currentId) and UITheme.Fonts.Heading or UITheme.Fonts.Body
        label.Text = tab.Label
        label.TextColor3 = (tab.Id == currentId) and UITheme.Colors.TextPrimary or UITheme.Colors.TextMuted
        label.TextSize = UITheme.FontSizes.Body
        label.Parent = btn

        btn.Activated:Connect(function()
            if currentId ~= tab.Id then
                currentId = tab.Id
                UITheme.PlayClick()
                updateVisuals()
                config.OnTabSelected(tab.Id)
            end
        end)

        btn.Parent = container
        buttonNodes[tab.Id] = btn
    end

    local tabsObj: TabsInstance = {
        Frame = container,
        SelectTab = function(tabId: string)
            currentId = tabId
            updateVisuals()
            config.OnTabSelected(tabId)
        end,
        GetCurrentTab = function()
            return currentId
        end,
        Destroy = function()
            container:Destroy()
        end,
    }

    if config.Parent then
        container.Parent = config.Parent
    end

    return tabsObj
end

return Tabs
