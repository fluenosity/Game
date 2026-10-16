--!strict
--[[
    AmbientAudio.client.lua
    Atmospheric woodland ambient audio engine for "Don't Let the Fire Die".
    Developed for Fluenosity Studio.
    
    Features:
    - Calm, peaceful natural crickets ("kirrr kirrr") looping audio.
    - Routed 100% through MasterSoundGroup (controlled by settings modal slider).
    - Starts at 50% default volume per user request.
]]

local SoundService = game:GetService("SoundService")
local UITheme = require(script.Parent:WaitForChild("UITheme"))

-- 1. Initialize Sound Groups & Audio Routing
UITheme.InitAudioRouting()
local envGroup = UITheme.GetEnvironmentSoundGroup()

local Lighting = game:GetService("Lighting")

-- 2. Create / Get Forest Crickets Ambient Sound (Nighttime only)
local CRICKETS_ASSET_ID = "rbxassetid://9112764546" -- Official Roblox Licenced Crickets Night SFX

local function setupCricketsSound(): Sound
    local existing = SoundService:FindFirstChild("ForestNightCrickets") :: Sound?
    if existing and existing:IsA("Sound") then
        existing.SoundGroup = envGroup
        return existing
    end
    
    local crickets = Instance.new("Sound")
    crickets.Name = "ForestNightCrickets"
    crickets.SoundId = CRICKETS_ASSET_ID
    crickets.Volume = 0
    crickets.Looped = true
    crickets.SoundGroup = envGroup
    crickets.Parent = SoundService
    
    return crickets
end

local cricketsSound = setupCricketsSound()

-- Dynamic Time-of-Day Ambient Audio:
-- Crickets only chirp during nighttime (ClockTime < 6.0 or ClockTime > 18.0).
-- During daytime (ClockTime 14:00 dev mode), night crickets are muted to eliminate high-frequency chirping/tinging.
local function updateAmbientCycle()
    local clock = Lighting.ClockTime
    local isNight = (clock < 6.0 or clock > 18.0)
    if isNight then
        if not cricketsSound.IsPlaying then
            pcall(function() cricketsSound:Play() end)
        end
        cricketsSound.Volume = 0.20
    else
        cricketsSound.Volume = 0
        if cricketsSound.IsPlaying then
            pcall(function() cricketsSound:Stop() end)
        end
    end
end

updateAmbientCycle()
Lighting:GetPropertyChangedSignal("ClockTime"):Connect(updateAmbientCycle)

task.spawn(function()
    while true do
        task.wait(4.0)
        updateAmbientCycle()
    end
end)
