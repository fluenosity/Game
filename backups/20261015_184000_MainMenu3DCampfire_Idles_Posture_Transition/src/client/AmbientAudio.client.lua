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

-- 2. Create / Get Forest Crickets Ambient Sound
local CRICKETS_ASSET_ID = "rbxassetid://9112764546" -- Official Roblox Licenced Crickets Night SFX

local function setupCricketsSound(): Sound
    local existing = SoundService:FindFirstChild("ForestNightCrickets") :: Sound?
    if existing and existing:IsA("Sound") then
        existing.SoundGroup = envGroup
        if not existing.IsPlaying then
            existing:Play()
        end
        return existing
    end
    
    local crickets = Instance.new("Sound")
    crickets.Name = "ForestNightCrickets"
    crickets.SoundId = CRICKETS_ASSET_ID
    crickets.Volume = 0.32 -- Gentle, relaxing background audio
    crickets.Looped = true
    crickets.SoundGroup = envGroup
    crickets.Parent = SoundService
    
    task.spawn(function()
        -- Wait for sound to load and start playback
        if not crickets.IsLoaded then
            crickets.Loaded:Wait()
        end
        crickets:Play()
    end)
    
    return crickets
end

local cricketsSound = setupCricketsSound()

-- Keep sound alive and playing smoothly across map changes
task.spawn(function()
    while true do
        task.wait(5.0)
        if cricketsSound and cricketsSound.Parent and not cricketsSound.IsPlaying then
            pcall(function()
                cricketsSound:Play()
            end)
        end
    end
end)
