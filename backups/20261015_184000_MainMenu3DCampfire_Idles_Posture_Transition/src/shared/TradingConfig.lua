--!strict
--[[
    TradingConfig.lua
    Barter economy recipes and trader definitions for "Don't Let the Fire Die".
    Developed for Fluenosity Studio.
]]

export type BarterRecipe = {
    Id: string,
    Name: string,
    Subtitle: string,
    Description: string,
    InputItemId: string,
    InputCount: number,
    OutputItemId: string,
    OutputCount: number,
    Icon: string,
    AccentColor: Color3,
}

local TradingConfig = {}

TradingConfig.Recipes = {
    {
        Id = "trade_dry_hardwood",
        Name = "DRY HARDWOOD",
        Subtitle = "HIGH-CALORIE FUEL",
        Description = "Kiln-cured dense hardwood timber. Burns 2.5x longer in the campfire than standard wood.",
        InputItemId = "standard_wood",
        InputCount = 2,
        OutputItemId = "dry_hardwood",
        OutputCount = 1,
        Icon = "flame",
        AccentColor = Color3.fromRGB(245, 160, 50),
    },
    {
        Id = "trade_matchbox",
        Name = "SAFETY MATCHES",
        Subtitle = "FIRE STARTER",
        Description = "Sulfur strike matchbox. Essential for lighting or relighting the campfire.",
        InputItemId = "standard_wood",
        InputCount = 3,
        OutputItemId = "matchbox",
        OutputCount = 1,
        Icon = "flame",
        AccentColor = Color3.fromRGB(255, 190, 60),
    },
    {
        Id = "trade_emergency_flare",
        Name = "EMERGENCY FLARE",
        Subtitle = "DEFENSIVE ILLUMINATION",
        Description = "High-output magnesium flare. Keeps shadow predators and beasts at bay in the dark.",
        InputItemId = "standard_wood",
        InputCount = 4,
        OutputItemId = "emergency_flare",
        OutputCount = 1,
        Icon = "sparkles",
        AccentColor = Color3.fromRGB(255, 75, 75),
    },
    {
        Id = "trade_bandage",
        Name = "BANDAGE ROLL",
        Subtitle = "MEDICAL RECOVERY",
        Description = "Clean linen bandage rolls. Staunches bleeding and restores vital body health.",
        InputItemId = "standard_wood",
        InputCount = 3,
        OutputItemId = "bandage",
        OutputCount = 1,
        Icon = "heart-pulse",
        AccentColor = Color3.fromRGB(245, 110, 130),
    },
    {
        Id = "trade_metal_scrap",
        Name = "SCRAP METAL",
        Subtitle = "SCAVENGED MATERIAL",
        Description = "Sturdy salvaged steel sheets from ruined city buildings. Used for defense fortifications.",
        InputItemId = "standard_wood",
        InputCount = 2,
        OutputItemId = "metal_scrap",
        OutputCount = 1,
        Icon = "nut",
        AccentColor = Color3.fromRGB(190, 205, 225),
    },
    {
        Id = "trade_wood_from_scrap",
        Name = "WOOD BUNDLE",
        Subtitle = "EMERGENCY FUEL STOCK",
        Description = "Running dangerously low on timber? Trade spare metal scrap to obtain fresh wood logs.",
        InputItemId = "metal_scrap",
        InputCount = 1,
        OutputItemId = "standard_wood",
        OutputCount = 2,
        Icon = "tree-pine",
        AccentColor = Color3.fromRGB(170, 215, 120),
    },
} :: { BarterRecipe }

return TradingConfig
