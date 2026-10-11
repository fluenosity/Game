--!strict
--[[
    InventoryConfig.lua
    Configuration and item registry for "Don't Let the Fire Die".
    Based on docs/systems/INVENTORY_AND_ITEM_RULES.md.
    Developed for Fluenosity Studio.
]]

export type ItemCategory = "Fuel" | "Tool" | "Medical" | "Scrap" | "Quest" | "Consumable"

export type ItemDefinition = {
    Id: string,
    Name: string,
    Category: ItemCategory,
    Description: string,
    MaxStack: number,
    IsEquippable: boolean,
    IsUsable: boolean,
    IconText: string, -- Procedural icon symbol
    AccentColor: Color3,
}

export type InventoryItem = {
    Id: string,
    Count: number,
}

local InventoryConfig = {}

InventoryConfig.MAX_HOTBAR_SLOTS = 3
InventoryConfig.MAX_BACKPACK_SLOTS = 6
InventoryConfig.TOTAL_PERSONAL_SLOTS = 9 -- 3 hotbar + 6 backpack

InventoryConfig.Items = {
    ["stone_hatchet"] = {
        Id = "stone_hatchet",
        Name = "STONE HATCHET",
        Category = "Tool",
        Description = "A hand-crafted stone axe. Chop trees to gather wood fuel before nightfall.",
        MaxStack = 1,
        IsEquippable = true,
        IsUsable = true,
        IconText = "🪓",
        AccentColor = Color3.fromRGB(220, 150, 70),
    },
    ["torch"] = {
        Id = "torch",
        Name = "FIREBRAND TORCH",
        Category = "Tool",
        Description = "A wrapped branch dipped in pine sap. Provides mobile warmth and light to ward off shadows.",
        MaxStack = 1,
        IsEquippable = true,
        IsUsable = true,
        IconText = "🔥",
        AccentColor = Color3.fromRGB(240, 110, 40),
    },
    ["standard_wood"] = {
        Id = "standard_wood",
        Name = "STANDARD WOOD",
        Category = "Fuel",
        Description = "Dense pine logs. Add to the campfire to prolong flame lifespan and expand the sanctuary.",
        MaxStack = 10,
        IsEquippable = true,
        IsUsable = true,
        IconText = "🪵",
        AccentColor = Color3.fromRGB(180, 120, 60),
    },
    ["dry_hardwood"] = {
        Id = "dry_hardwood",
        Name = "DRY HARDWOOD",
        Category = "Fuel",
        Description = "Seasoned oak timber. Burns hotter and longer than standard pine.",
        MaxStack = 10,
        IsEquippable = true,
        IsUsable = true,
        IconText = "🪵",
        AccentColor = Color3.fromRGB(210, 140, 70),
    },
    ["bandage"] = {
        Id = "bandage",
        Name = "CLEAN BANDAGE",
        Category = "Medical",
        Description = "Sterile linen wraps. Restores 30 HP and staunches blood loss.",
        MaxStack = 3,
        IsEquippable = false,
        IsUsable = true,
        IconText = "🩹",
        AccentColor = Color3.fromRGB(230, 210, 190),
    },
    ["matches"] = {
        Id = "matches",
        Name = "MATCHES",
        Category = "Consumable",
        Description = "Phosphorus matchsticks. Essential for reigniting dying embers in emergency winds.",
        MaxStack = 10,
        IsEquippable = false,
        IsUsable = true,
        IconText = "⚡",
        AccentColor = Color3.fromRGB(250, 190, 50),
    },
    ["metal_scrap"] = {
        Id = "metal_scrap",
        Name = "SCRAP METAL",
        Category = "Scrap",
        Description = "Twisted steel sheets from ruined city structures. Used to craft shelter defenses.",
        MaxStack = 8,
        IsEquippable = false,
        IsUsable = false,
        IconText = "🔩",
        AccentColor = Color3.fromRGB(160, 170, 185),
    },
    ["light_relay"] = {
        Id = "light_relay",
        Name = "LIGHT RELAY",
        Category = "Tool",
        Description = "Deployable solar lantern pole. Establishes illuminated corridors safe from the Hollow.",
        MaxStack = 2,
        IsEquippable = true,
        IsUsable = true,
        IconText = "💡",
        AccentColor = Color3.fromRGB(255, 230, 120),
    },
} :: { [string]: ItemDefinition }

-- Starting loadout for Day 1 prologue
InventoryConfig.StartingLoadout = {
    [1] = { Id = "stone_hatchet", Count = 1 },
    [2] = { Id = "torch", Count = 1 },
    [3] = { Id = "bandage", Count = 2 },
    [4] = { Id = "standard_wood", Count = 4 },
    [5] = { Id = "matches", Count = 5 },
    [6] = nil,
    [7] = nil,
    [8] = nil,
    [9] = nil,
} :: { [number]: InventoryItem? }

return InventoryConfig
