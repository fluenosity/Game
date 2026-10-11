--!strict
--[[
    IconPack.lua
    Unified AAA Vector Icon Pack System for "Don't Let the Fire Die".
    Powered by Lucide Icons (<https://lucide.dev>) via Lucide.lua.
    Replaces all emoji glyphs with clean, monochrome and duotone vector icons.
    Developed for Fluenosity Studio.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local sharedFolder = ReplicatedStorage:WaitForChild("FluenosityShared")
local Lucide = require(sharedFolder:WaitForChild("Lucide"))

export type IconAsset = {
    IconName: string,
    Id: number,
    Url: string,
    ImageRectSize: Vector2,
    ImageRectOffset: Vector2,
}

local IconPack = {}

-- Standard palette for UI icons
IconPack.Colors = {
    White = Color3.fromRGB(245, 248, 255),
    Silver = Color3.fromRGB(180, 185, 200),
    Muted = Color3.fromRGB(120, 125, 140),
    Amber = Color3.fromRGB(245, 160, 40),
    Gold = Color3.fromRGB(255, 205, 75),
    Coral = Color3.fromRGB(255, 95, 95),
    Emerald = Color3.fromRGB(100, 220, 140),
    Cyan = Color3.fromRGB(80, 200, 255),
    Blue = Color3.fromRGB(90, 150, 255),
    Danger = Color3.fromRGB(255, 70, 70),
}

-- Registry mapping for all items to Lucide icons & duotone accent colors
IconPack.ItemIcons = {
    ["stone_hatchet"]   = { Icon = "axe",          Color = Color3.fromRGB(245, 170, 70)  },
    ["torch"]           = { Icon = "flame",        Color = Color3.fromRGB(255, 120, 50)  },
    ["standard_wood"]   = { Icon = "tree-pine",    Color = Color3.fromRGB(170, 215, 120) },
    ["bandage"]         = { Icon = "heart-pulse",  Color = Color3.fromRGB(245, 110, 130) },
    ["flint_stones"]    = { Icon = "mountain",     Color = Color3.fromRGB(185, 195, 210) },
    ["wild_herbs"]      = { Icon = "leaf",         Color = Color3.fromRGB(130, 210, 110) },
    ["wild_berries"]    = { Icon = "cherry",       Color = Color3.fromRGB(250, 85, 100)  },
    ["hemp_rope"]       = { Icon = "link-2",       Color = Color3.fromRGB(225, 195, 135) },
    ["cured_leather"]   = { Icon = "package",      Color = Color3.fromRGB(200, 150, 105) },
    ["water_flask"]     = { Icon = "flask-conical",Color = Color3.fromRGB(90, 190, 255)  },
    ["raw_meat"]        = { Icon = "beef",         Color = Color3.fromRGB(245, 115, 115) },
    ["matches"]         = { Icon = "flame",        Color = Color3.fromRGB(255, 190, 60)  },
    ["matchbox"]        = { Icon = "flame",        Color = Color3.fromRGB(255, 190, 60)  },
    ["metal_scrap"]     = { Icon = "nut",          Color = Color3.fromRGB(190, 200, 215) },
    ["light_relay"]     = { Icon = "lightbulb",    Color = Color3.fromRGB(255, 235, 110) },
    ["dry_hardwood"]    = { Icon = "flame",        Color = Color3.fromRGB(240, 160, 50)  },
    ["emergency_flare"] = { Icon = "sparkles",     Color = Color3.fromRGB(255, 75, 75)   },
}

local function extractNumericSize(val: any, defaultSize: number): number
    if typeof(val) == "number" then
        return val
    elseif typeof(val) == "UDim2" then
        if val.X.Offset > 0 then
            return val.X.Offset
        elseif val.Y.Offset > 0 then
            return val.Y.Offset
        end
    elseif typeof(val) == "Vector2" then
        return math.max(val.X, val.Y)
    end
    return defaultSize
end

-- Retrieves asset metadata for an icon
function IconPack.GetAsset(iconName: string, size: (number | UDim2)?): IconAsset
    local numSize = extractNumericSize(size, 48)
    local asset = Lucide.GetAsset(iconName, numSize)
    return asset
end

-- Configures an existing ImageLabel or ImageButton with a Lucide icon
function IconPack.ApplyTo(
    imageInstance: ImageLabel | ImageButton,
    iconName: string,
    color: Color3?,
    transparency: number?,
    sizeHint: (number | UDim2)?
)
    local numSize = extractNumericSize(sizeHint, 48)
    local asset = Lucide.GetAsset(iconName, numSize)
    imageInstance.Image = asset.Url
    imageInstance.ImageRectOffset = asset.ImageRectOffset
    imageInstance.ImageRectSize = asset.ImageRectSize
    imageInstance.ScaleType = Enum.ScaleType.Fit
    imageInstance.BackgroundTransparency = 1

    if color then
        imageInstance.ImageColor3 = color
    end
    if transparency then
        imageInstance.ImageTransparency = transparency
    end
end

-- Creates a standalone vector ImageLabel
function IconPack.CreateIcon(
    iconName: string,
    sizeHint: (number | UDim2)?,
    color: Color3?,
    transparency: number?
): ImageLabel
    local numSize = extractNumericSize(sizeHint, 24)
    local targetSize = if typeof(sizeHint) == "UDim2" then sizeHint else UDim2.fromOffset(numSize, numSize)
    local col = color or IconPack.Colors.White
    local trans = transparency or 0

    local img = Lucide.ImageLabel(iconName, numSize, {
        Size = targetSize,
        ImageColor3 = col,
        ImageTransparency = trans,
        BackgroundTransparency = 1,
        ScaleType = Enum.ScaleType.Fit,
    })
    return img
end

-- Creates a sleek AAA duotone badge (subtle tinted background pill + sharp bright icon)
function IconPack.CreateDuotoneBadge(
    iconName: string,
    containerSize: number,
    iconSize: number,
    accentColor: Color3,
    isCircle: boolean?
): Frame
    local badge = Instance.new("Frame")
    badge.Name = "DuotoneBadge_" .. iconName
    badge.Size = UDim2.fromOffset(containerSize, containerSize)
    badge.BackgroundColor3 = accentColor
    badge.BackgroundTransparency = 0.82 -- Soft subtle tint
    badge.BorderSizePixel = 0

    local corner = Instance.new("UICorner")
    corner.CornerRadius = isCircle and UDim.new(1, 0) or UDim.new(0, math.floor(containerSize * 0.28))
    corner.Parent = badge

    local stroke = Instance.new("UIStroke")
    stroke.Color = accentColor
    stroke.Transparency = 0.72
    stroke.Thickness = 1
    stroke.Parent = badge

    local icon = IconPack.CreateIcon(iconName, iconSize, accentColor, 0.05)
    icon.Position = UDim2.fromScale(0.5, 0.5)
    icon.AnchorPoint = Vector2.new(0.5, 0.5)
    icon.Parent = badge

    return badge
end

-- Lookup icon and color for an inventory item (falls back cleanly if unknown)
function IconPack.GetItemInfo(itemId: string): (string, Color3)
    local info = IconPack.ItemIcons[itemId]
    if info then
        return info.Icon, info.Color
    end
    return "package", IconPack.Colors.Silver
end

return IconPack
