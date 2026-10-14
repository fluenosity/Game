--!strict
--[[
    GameConfig.lua
    Central Development & Game Configuration for "Don't Let the Fire Die".
    Developed for Fluenosity Studio.

    HOW TO USE:
    - In Development Mode (DEV_MODE = true):
      Fast iteration flags allow developers to skip intros, bypass menus,
      and spawn straight into active gameplay in Roblox Studio.
    - In Production Mode (DEV_MODE = false):
      The full AAA intro pipeline executes (Studio Splash Screen -> Main Menu -> Play transition).
    
    You can also toggle individual flags below independently!
]]

export type GameConfigType = {
    DEV_MODE: boolean,
    SKIP_SPLASH_SCREEN: boolean,
    SKIP_MAIN_MENU: boolean,
    DIRECT_SPAWN: boolean,
    FAST_LOADING_SCREEN: boolean,
}

local GameConfig = {
    -- Master Developer Switch
    -- Set to true during development/testing; set to false for full production game flow.
    DEV_MODE = true,

    -- 1. SKIP SPLASH SCREEN
    -- If true: Skips the white "A FLUENOSITY STUDIO PRODUCTION" intro screen entirely.
    -- If false: Displays the full cinematic white studio splash sequence.
    SKIP_SPLASH_SCREEN = false,

    -- 2. SKIP MAIN MENU
    -- If true: Bypasses the Main Menu screen and proceeds straight into the world with preloading.
    -- If false: Displays the interactive Main Menu until the player clicks "START GAME".
    SKIP_MAIN_MENU = true,

    -- 3. DIRECT SPAWN
    -- If true: The server automatically spawns the player character into the world immediately on join
    -- (Players.CharacterAutoLoads = true / instant LoadCharacter()).
    -- If false: The character only spawns when explicitly requested by clicking "PLAY".
    DIRECT_SPAWN = true,

    -- 4. FAST LOADING SCREEN
    -- If true: Skips or shortens artificial loading screen transitions for rapid testing.
    FAST_LOADING_SCREEN = true,
}

-- Safe query methods that take DEV_MODE into account
function GameConfig.ShouldSkipSplashScreen(): boolean
    return GameConfig.DEV_MODE and GameConfig.SKIP_SPLASH_SCREEN
end

function GameConfig.ShouldSkipMainMenu(): boolean
    return GameConfig.DEV_MODE and GameConfig.SKIP_MAIN_MENU
end

function GameConfig.ShouldDirectSpawn(): boolean
    return GameConfig.DEV_MODE and GameConfig.DIRECT_SPAWN
end

function GameConfig.ShouldFastLoad(): boolean
    return GameConfig.DEV_MODE and GameConfig.FAST_LOADING_SCREEN
end

return GameConfig
