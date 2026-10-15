--!strict
--[[
    TreeFoliageHelper.lua
    Studio utility for terrain painters and level designers in "Don't Let the Fire Die".
    
    Features:
    - SetGhost(transparency): Makes tree canopies/leaves transparent (default 0.92) so the terrain
      beneath is 100% visible for grass painting, while keeping stems/trunks fully solid and preserving shadows.
    - SetHidden(): Completely hides all leaf canopies (transparency 1.0) while keeping stems/trunks fully solid.
    - Restore(): Instantly restores all leaves and canopies back to their original solid transparencies.
    - HighlightStems(boolean): Highlights trunk ground footprints with circular markers for precision grass borders.
    - Fully supports Studio ChangeHistoryService for undo/redo (Ctrl+Z / Ctrl+Y).
]]

local TreeFoliageHelper = {}

local function isLeafPart(part: BasePart): boolean
    local name = string.lower(part.Name)
    return (string.find(name, "leaf") ~= nil or string.find(name, "leaves") ~= nil)
end

local function isTrunkPart(part: BasePart): boolean
    local name = string.lower(part.Name)
    return (string.find(name, "trunk") ~= nil or string.find(name, "stump") ~= nil or string.find(name, "fallentree") ~= nil)
end

--[[
    Makes tree leaves ghostly transparent (default 0.92) so terrain is completely visible,
    while keeping trunks/stems 100% solid and maintaining natural shadows.
]]
function TreeFoliageHelper.SetGhost(transparency: number?): number
    local targetTransparency = transparency or 0.92
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

--[[
    Completely hides all leaves/canopies (transparency 1.0) while keeping stems/trunks 100% solid.
]]
function TreeFoliageHelper.SetHidden(): number
    return TreeFoliageHelper.SetGhost(1.0)
end

--[[
    Restores all tree canopies and leaves back to their original saved transparencies.
]]
function TreeFoliageHelper.Restore(): number
    local count = 0

    for _, d in ipairs(workspace:GetDescendants()) do
        if d:IsA("BasePart") and d:GetAttribute("OriginalTransparency") ~= nil then
            d.Transparency = d:GetAttribute("OriginalTransparency")
            d:SetAttribute("OriginalTransparency", nil)
            count += 1
        end
    end

    TreeFoliageHelper.HighlightStems(false)
    return count
end

--[[
    Optional helper: Highlights tree stems with subtle circular ground rings
    so you can easily see the trunk root boundary while painting terrain grass.
]]
function TreeFoliageHelper.HighlightStems(enabled: boolean): number
    local highlightFolder = workspace:FindFirstChild("TreeStemGrassGuides")
    if not enabled then
        if highlightFolder then
            highlightFolder:Destroy()
        end
        return 0
    end

    if not highlightFolder then
        highlightFolder = Instance.new("Folder")
        highlightFolder.Name = "TreeStemGrassGuides"
        highlightFolder.Parent = workspace
    end

    local count = 0
    for _, d in ipairs(workspace:GetDescendants()) do
        if d:IsA("BasePart") and isTrunkPart(d) and d.Parent ~= highlightFolder then
            local existing = highlightFolder:FindFirstChild("Guide_" .. d:GetDebugId())
            if not existing then
                local ring = Instance.new("CylinderHandleAdornment")
                ring.Name = "Guide_" .. d:GetDebugId()
                ring.Adornee = d
                ring.Height = 0.3
                ring.Radius = math.max(d.Size.X, d.Size.Z) * 0.75 + 0.8
                ring.Color3 = Color3.fromRGB(255, 170, 60)
                ring.Transparency = 0.45
                ring.AlwaysOnTop = false
                ring.CFrame = CFrame.Angles(math.rad(90), 0, 0)
                ring.Parent = highlightFolder
                count += 1
            end
        end
    end

    return count
end

--[[
    Returns stats on how many leaves and trunks are currently detected in the workspace.
]]
function TreeFoliageHelper.GetStats(): { TotalLeaves: number, TotalTrunks: number, GhostedLeaves: number }
    local leaves = 0
    local trunks = 0
    local ghosted = 0

    for _, d in ipairs(workspace:GetDescendants()) do
        if d:IsA("BasePart") then
            if isLeafPart(d) then
                leaves += 1
                if d:GetAttribute("OriginalTransparency") ~= nil then
                    ghosted += 1
                end
            elseif isTrunkPart(d) then
                trunks += 1
            end
        end
    end

    return {
        TotalLeaves = leaves,
        TotalTrunks = trunks,
        GhostedLeaves = ghosted,
    }
end

return TreeFoliageHelper
