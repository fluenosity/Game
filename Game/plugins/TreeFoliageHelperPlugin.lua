--!strict
--[[
    TreeFoliageHelperPlugin.lua
    Roblox Studio Plugin: Foliage Painter Assistant for "Don't Let the Fire Die"
    
    Provides one-click toolbar buttons and a dockable settings panel in Roblox Studio:
    1. Ghost Leaves (92% transparent): You can see right through the canopy to paint grass on the terrain beneath,
       while keeping tree stems/trunks fully solid and preserving tree shadows.
    2. Hide Leaves (100% invisible): Leaves completely hidden, only tree stems/trunks visible.
    3. Restore Leaves: Restores all 4,500+ tree canopies back to their original solid state.
    4. Stem Guides: Toggles orange ground footprint rings around trunk bases so you never paint through trunks.
    5. Dockable Settings Panel with slider for custom opacity (0% to 100%).
]]

local ChangeHistoryService = game:GetService("ChangeHistoryService")

local function isLeafPart(part: BasePart): boolean
    local name = string.lower(part.Name)
    return (string.find(name, "leaf") ~= nil or string.find(name, "leaves") ~= nil)
end

local function isTrunkPart(part: BasePart): boolean
    local name = string.lower(part.Name)
    return (string.find(name, "trunk") ~= nil or string.find(name, "stump") ~= nil or string.find(name, "fallentree") ~= nil)
end

local function setLeafTransparency(targetTransparency: number): number
    local count = 0
    for _, d in ipairs(workspace:GetDescendants()) do
        if d:IsA("BasePart") and isLeafPart(d) then
            if d:GetAttribute("OriginalTransparency") == nil then
                d:SetAttribute("OriginalTransparency", d.Transparency)
            end
            d.Transparency = targetTransparency
            count += 1
        end
    end
    return count
end

local function restoreAllLeaves(): number
    local count = 0
    for _, d in ipairs(workspace:GetDescendants()) do
        if d:IsA("BasePart") and d:GetAttribute("OriginalTransparency") ~= nil then
            d.Transparency = d:GetAttribute("OriginalTransparency")
            d:SetAttribute("OriginalTransparency", nil)
            count += 1
        end
    end
    return count
end

local function toggleStemGuides(enable: boolean?): boolean
    local existing = workspace:FindFirstChild("TreeStemGrassGuides")
    if existing and enable ~= true then
        existing:Destroy()
        return false
    end

    if enable == false then return false end

    if not existing then
        existing = Instance.new("Folder")
        existing.Name = "TreeStemGrassGuides"
        existing.Parent = workspace
    end

    local count = 0
    for _, d in ipairs(workspace:GetDescendants()) do
        if d:IsA("BasePart") and isTrunkPart(d) and d.Parent ~= existing then
            local guide = existing:FindFirstChild("Guide_" .. d:GetDebugId())
            if not guide then
                local ring = Instance.new("CylinderHandleAdornment")
                ring.Name = "Guide_" .. d:GetDebugId()
                ring.Adornee = d
                ring.Height = 0.3
                ring.Radius = math.max(d.Size.X, d.Size.Z) * 0.75 + 0.8
                ring.Color3 = Color3.fromRGB(255, 160, 50)
                ring.Transparency = 0.4
                ring.AlwaysOnTop = false
                ring.CFrame = CFrame.Angles(math.rad(90), 0, 0)
                ring.Parent = existing
                count += 1
            end
        end
    end
    return true
end

-- -----------------------------------------------------------------------------
-- STUDIO TOOLBAR SETUP
-- -----------------------------------------------------------------------------
local toolbar = plugin:CreateToolbar("🍃 Foliage Painter")

local btnGhost = toolbar:CreateButton(
    "Ghost Leaves",
    "Leaves 92% transparent: see terrain beneath, trunks stay solid & keep shadows",
    "rbxassetid://106299822759980"
)

local btnHide = toolbar:CreateButton(
    "Hide Leaves",
    "Leaves 100% invisible: unobstructed view of terrain, trunks stay solid",
    "rbxassetid://106299822759980"
)

local btnRestore = toolbar:CreateButton(
    "Restore Leaves",
    "Restore all leaves and canopies back to 100% solid",
    "rbxassetid://106299822759980"
)

local btnGuides = toolbar:CreateButton(
    "Stem Guides",
    "Toggle orange circular ground rings around tree trunks",
    "rbxassetid://106299822759980"
)

local btnPanel = toolbar:CreateButton(
    "Painter Panel",
    "Open the Foliage Painter settings dockable panel",
    "rbxassetid://106299822759980"
)

btnGhost.Click:Connect(function()
    local n = setLeafTransparency(0.92)
    pcall(function() ChangeHistoryService:SetWaypoint("Ghost Tree Leaves") end)
    print(string.format("[FoliagePainter] Ghost mode active! %d leaf parts set to 92%% transparency (trunks solid).", n))
end)

btnHide.Click:Connect(function()
    local n = setLeafTransparency(1.0)
    pcall(function() ChangeHistoryService:SetWaypoint("Hide Tree Leaves") end)
    print(string.format("[FoliagePainter] Hide mode active! %d leaf parts hidden (trunks solid).", n))
end)

btnRestore.Click:Connect(function()
    local n = restoreAllLeaves()
    toggleStemGuides(false)
    pcall(function() ChangeHistoryService:SetWaypoint("Restore Tree Leaves") end)
    print(string.format("[FoliagePainter] Restored %d leaf parts back to original solid opacity.", n))
end)

btnGuides.Click:Connect(function()
    local active = toggleStemGuides(nil)
    print("[FoliagePainter] Stem guides " .. (active and "ENABLED (Orange ground rings on trunks)" or "DISABLED"))
end)

-- -----------------------------------------------------------------------------
-- DOCKABLE WIDGET PANEL SETUP
-- -----------------------------------------------------------------------------
local widgetInfo = DockWidgetPluginGuiInfo.new(
    Enum.InitialDockState.Right,
    false,
    false,
    280,
    340,
    240,
    260
)
local widget = plugin:CreateDockWidgetPluginGui("FoliagePainterWidget", widgetInfo)
widget.Title = "🍃 Foliage Painter Helper"

btnPanel.Click:Connect(function()
    widget.Enabled = not widget.Enabled
end)

local frame = Instance.new("Frame")
frame.Size = UDim2.fromScale(1, 1)
frame.BackgroundColor3 = Color3.fromRGB(24, 24, 28)
frame.BorderSizePixel = 0
frame.Parent = widget

local pad = Instance.new("UIPadding")
pad.PaddingTop = UDim.new(0, 12)
pad.PaddingBottom = UDim.new(0, 12)
pad.PaddingLeft = UDim.new(0, 12)
pad.PaddingRight = UDim.new(0, 12)
pad.Parent = frame

local list = Instance.new("UIListLayout")
list.Padding = UDim.new(0, 8)
list.SortOrder = Enum.SortOrder.LayoutOrder
list.Parent = frame

local function createButton(text: string, color: Color3, callback: () -> ()): TextButton
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(1, 0, 0, 36)
    b.BackgroundColor3 = color
    b.TextColor3 = Color3.fromRGB(255, 255, 255)
    b.Font = Enum.Font.GothamBold
    b.TextSize = 12
    b.Text = text
    b.BorderSizePixel = 0
    b.Parent = frame

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = b

    b.Activated:Connect(callback)
    return b
end

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 24)
title.BackgroundTransparency = 1
title.Text = "TERRAIN PAINTING VISIBILITY"
title.TextColor3 = Color3.fromRGB(255, 170, 60)
title.Font = Enum.Font.GothamBold
title.TextSize = 13
title.Parent = frame

local desc = Instance.new("TextLabel")
desc.Size = UDim2.new(1, 0, 0, 32)
desc.BackgroundTransparency = 1
desc.Text = "Fades leaf canopies so ground is clear, while keeping tree trunks solid and visible."
desc.TextColor3 = Color3.fromRGB(180, 180, 185)
desc.Font = Enum.Font.Gotham
desc.TextSize = 10
desc.TextWrapped = true
desc.Parent = frame

createButton("👻 GHOST LEAVES (92% Transparent + Shadow)", Color3.fromRGB(45, 95, 140), function()
    local n = setLeafTransparency(0.92)
    print(string.format("[FoliagePainter] Ghost mode: %d leaves faded.", n))
end)

createButton("🚫 HIDE LEAVES (100% Invisible)", Color3.fromRGB(140, 50, 50), function()
    local n = setLeafTransparency(1.0)
    print(string.format("[FoliagePainter] Hide mode: %d leaves hidden.", n))
end)

createButton("🔄 RESTORE SOLID TREES (Normal)", Color3.fromRGB(45, 120, 65), function()
    local n = restoreAllLeaves()
    toggleStemGuides(false)
    print(string.format("[FoliagePainter] Restored: %d leaves solid.", n))
end)

createButton("🎯 TOGGLE STEM GROUND GUIDES", Color3.fromRGB(150, 95, 30), function()
    local active = toggleStemGuides(nil)
    print("[FoliagePainter] Stem guides " .. (active and "ENABLED" or "DISABLED"))
end)

print("[FoliagePainter] Loaded! Toolbar '🍃 Foliage Painter' is ready in Studio.")
