--!strict
--[[
    InventoryConfig.lua
    Configuration and item registry for "Don't Let the Fire Die".
    Powered by vector icons via IconPack / Lucide.
    Developed for Fluenosity Studio.
]]

export type ItemCategory = "Fuel" | "Tool" | "Medical" | "Scrap" | "Quest" | "Consumable"

export type ItemDefinition = {
    Id: string,
    Name: string,
    Category: ItemCategory,
    Rarity: string?, -- "COMMON", "UNCOMMON", "RARE"
    Description: string,
    MaxStack: number,
    IsEquippable: boolean,
    IsUsable: boolean,
    IsProtected: boolean?,
    IconName: string, -- Lucide vector icon identifier
    AccentColor: Color3, -- Vector duotone tint color
    Stats: {
        Damage: number?,
        Speed: number?,
        Durability: number?,
    }?,
}

export type InventoryItem = {
    Id: string,
    Count: number,
}

local InventoryConfig = {}

InventoryConfig.MAX_HOTBAR_SLOTS = 3
InventoryConfig.MAX_BACKPACK_SLOTS = 12
InventoryConfig.TOTAL_PERSONAL_SLOTS = 12 -- 12-slot survival backpack grid (9 active + 3 locked)
InventoryConfig.UNLOCKED_SLOTS = 9        -- 9 slots unlocked initially (matches mockup 9 / 12)

InventoryConfig.Items = {
    ["stone_hatchet"] = {
        Id = "stone_hatchet",
        Name = "STONE HATCHET",
        Category = "Tool",
        Rarity = "COMMON",
        Description = "A hand-crafted stone axe. Chop trees to gather wood before nightfall.",
        MaxStack = 1,
        IsEquippable = true,
        IsUsable = true,
        IconName = "axe",
        AccentColor = Color3.fromRGB(245, 170, 70),
        Stats = {
            Damage = 0.65,
            Speed = 0.35,
            Durability = 0.78,
        },
    },
    ["torch"] = {
        Id = "torch",
        Name = "FIREBRAND TORCH",
        Category = "Tool",
        Rarity = "COMMON",
        Description = "A wrapped branch dipped in pine sap. Provides mobile warmth and light to ward off shadows.",
        MaxStack = 1,
        IsEquippable = true,
        IsUsable = true,
        IconName = "flame",
        AccentColor = Color3.fromRGB(255, 120, 50),
        Stats = {
            Damage = 0.25,
            Speed = 0.50,
            Durability = 0.45,
        },
    },
    ["standard_wood"] = {
        Id = "standard_wood",
        Name = "WOOD LOGS",
        Category = "Fuel",
        Rarity = "COMMON",
        Description = "Dense timber logs. Essential fuel for stoking the campfire and crafting shelter fortifications. (Max carry: 5)",
        MaxStack = 5,
        IsEquippable = true,
        IsUsable = true,
        IconName = "tree-pine",
        AccentColor = Color3.fromRGB(170, 215, 120),
    },
    ["bandage"] = {
        Id = "bandage",
        Name = "BANDAGE ROLL",
        Category = "Medical",
        Rarity = "COMMON",
        Description = "Sterile linen bandages. Restores health and staunches bleeding caused by freezing winds or beast attacks.",
        MaxStack = 10,
        IsEquippable = false,
        IsUsable = true,
        IconName = "heart-pulse",
        AccentColor = Color3.fromRGB(245, 110, 130),
    },
    ["flint_stones"] = {
        Id = "flint_stones",
        Name = "FLINT STONES",
        Category = "Scrap",
        Rarity = "COMMON",
        Description = "Rough mineral stones found along riverbanks. Vital for striking sparks, crafting axes, and reinforcing fire pits.",
        MaxStack = 20,
        IsEquippable = false,
        IsUsable = false,
        IconName = "mountain",
        AccentColor = Color3.fromRGB(185, 195, 210),
    },
    ["wild_herbs"] = {
        Id = "wild_herbs",
        Name = "WILD HERBS",
        Category = "Medical",
        Rarity = "COMMON",
        Description = "Mountain herbs rich in medicinal oils. Can be consumed raw for slight relief or brewed into warming poultices.",
        MaxStack = 15,
        IsEquippable = false,
        IsUsable = true,
        IconName = "leaf",
        AccentColor = Color3.fromRGB(130, 210, 110),
    },
    ["wild_berries"] = {
        Id = "wild_berries",
        Name = "WILD BERRIES",
        Category = "Consumable",
        Rarity = "COMMON",
        Description = "Tart mountain berries harvested from thorny shrubs. Quickly restores a small portion of hunger.",
        MaxStack = 20,
        IsEquippable = false,
        IsUsable = true,
        IconName = "cherry",
        AccentColor = Color3.fromRGB(250, 85, 100),
    },
    ["hemp_rope"] = {
        Id = "hemp_rope",
        Name = "HEMP ROPE",
        Category = "Scrap",
        Rarity = "COMMON",
        Description = "Braided tough plant cordage. Crucial for securing hatchet heads, binding bundles, and setting perimeter traps.",
        MaxStack = 10,
        IsEquippable = false,
        IsUsable = false,
        IconName = "link-2",
        AccentColor = Color3.fromRGB(225, 195, 135),
    },
    ["cured_leather"] = {
        Id = "cured_leather",
        Name = "CURED LEATHER",
        Category = "Scrap",
        Rarity = "COMMON",
        Description = "Tanned animal pelt scrap. Weatherproof material used to insulate clothing and expand bag capacity.",
        MaxStack = 10,
        IsEquippable = false,
        IsUsable = false,
        IconName = "package",
        AccentColor = Color3.fromRGB(200, 150, 105),
    },
    ["water_flask"] = {
        Id = "water_flask",
        Name = "PURIFIED WATER",
        Category = "Consumable",
        Rarity = "COMMON",
        Description = "Boiled mountain meltwater stored in a sealed glass vial. Quenches thirst and wards off fatigue.",
        MaxStack = 5,
        IsEquippable = false,
        IsUsable = true,
        IconName = "flask-conical",
        AccentColor = Color3.fromRGB(90, 190, 255),
    },
    ["raw_meat"] = {
        Id = "raw_meat",
        Name = "RAW MEAT",
        Category = "Consumable",
        Rarity = "COMMON",
        Description = "Fresh venison steak hunted from the woodland perimeter. Roast over the campfire to restore vital energy.",
        MaxStack = 10,
        IsEquippable = false,
        IsUsable = true,
        IconName = "beef",
        AccentColor = Color3.fromRGB(245, 115, 115),
    },
    ["matches"] = {
        Id = "matches",
        Name = "MATCHBOX",
        Category = "Tool",
        Rarity = "COMMON",
        Description = "A vintage cardboard matchbox with strike strip. Keep dry to ignite and sustain the campsite campfire.",
        MaxStack = 1,
        IsEquippable = true,
        IsUsable = true,
        IconName = "flame",
        AccentColor = Color3.fromRGB(255, 190, 60),
    },
    ["matchbox"] = {
        Id = "matchbox",
        Name = "MATCHBOX",
        Category = "Tool",
        Rarity = "COMMON",
        Description = "A vintage cardboard matchbox with strike strip. Keep dry to ignite and sustain the campsite campfire.",
        MaxStack = 1,
        IsEquippable = true,
        IsUsable = true,
        IconName = "flame",
        AccentColor = Color3.fromRGB(255, 190, 60),
    },
    ["metal_scrap"] = {
        Id = "metal_scrap",
        Name = "SCRAP METAL",
        Category = "Scrap",
        Rarity = "COMMON",
        Description = "Twisted steel sheets from ruined city structures. Used to craft shelter defenses.",
        MaxStack = 8,
        IsEquippable = false,
        IsUsable = false,
        IconName = "nut",
        AccentColor = Color3.fromRGB(190, 200, 215),
    },
    ["light_relay"] = {
        Id = "light_relay",
        Name = "LIGHT RELAY",
        Category = "Tool",
        Rarity = "RARE",
        Description = "Deployable solar lantern pole. Establishes illuminated corridors safe from the Hollow.",
        MaxStack = 2,
        IsEquippable = true,
        IsUsable = true,
        IconName = "lightbulb",
        AccentColor = Color3.fromRGB(255, 235, 110),
    },
    ["dry_hardwood"] = {
        Id = "dry_hardwood",
        Name = "DRY HARDWOOD",
        Category = "Fuel",
        Rarity = "UNCOMMON",
        Description = "Kiln-cured mountain hardwood timber. Burns 2.5x longer in the campfire than standard wood.",
        MaxStack = 5,
        IsEquippable = true,
        IsUsable = true,
        IconName = "flame",
        AccentColor = Color3.fromRGB(240, 160, 50),
    },
    ["emergency_flare"] = {
        Id = "emergency_flare",
        Name = "EMERGENCY FLARE",
        Category = "Tool",
        Rarity = "RARE",
        Description = "High-output magnesium emergency flare. Instantly lights dark paths and wards off roaming beasts.",
        MaxStack = 3,
        IsEquippable = true,
        IsUsable = true,
        IconName = "sparkles",
        AccentColor = Color3.fromRGB(255, 75, 75),
    },
} :: { [string]: ItemDefinition }

-- No signature weapon is granted; the survival loadout starts empty.
InventoryConfig.StartingLoadout = {} :: { [number]: InventoryItem? }

return InventoryConfig
