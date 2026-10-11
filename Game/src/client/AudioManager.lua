--!strict
--[[
    AudioManager.lua
    Centralized Audio and Sound Effects Manager for "Don't Let the Fire Die".
    Developed for Fluenosity Studio.

    Features:
    - Subtle, organic, peaceful survival SFX (tactile wooden clicks, soft cloth rustles,
      crisp timber snaps, and gentle amber resonates)
    - Micro-pitch variance for natural acoustic responsiveness without ear fatigue
    - Smart debouncing to prevent audio stacking during fast mouse movements
    - Routed 100% through MasterSoundGroup (controlled by user settings slider)
    - Full button auto-attachment helper for one-line UI wiring
]]

local SoundService = game:GetService("SoundService")
local ContentProvider = game:GetService("ContentProvider")
local RunService = game:GetService("RunService")

local UITheme = require(script.Parent:WaitForChild("UITheme"))

export type SoundConfig = {
    SoundId: string,
    FallbackId: string?,
    Volume: number,
    Pitch: number,
    PitchVariation: number?,
    MinInterval: number?,
}

local AudioManager = {}

-- -----------------------------------------------------------------------------
-- 1. SOUND EFFECTS REGISTRY (Subtle, Organic, Peaceful Survival SFX)
-- -----------------------------------------------------------------------------
local SOUND_PRESETS: { [string]: SoundConfig } = {
    -- Soft, muted acoustic tick on hover (Roblox official UI Hover 01)
    ["Hover"] = {
        SoundId = "rbxassetid://10066931761",
        FallbackId = "rbxassetid://6895079853",
        Volume = 0.20,
        Pitch = 1.00,
        PitchVariation = 0.03,
        MinInterval = 0.045,
    },
    ["ButtonHover"] = {
        SoundId = "rbxassetid://10066931761",
        FallbackId = "rbxassetid://6895079853",
        Volume = 0.20,
        Pitch = 1.00,
        PitchVariation = 0.03,
        MinInterval = 0.045,
    },

    -- Crisp, subtle, tactile button click (Roblox official UI Small Click)
    ["Click"] = {
        SoundId = "rbxassetid://15675032796",
        FallbackId = "rbxassetid://6895079853",
        Volume = 0.32,
        Pitch = 1.00,
        PitchVariation = 0.03,
        MinInterval = 0.03,
    },
    ["ButtonClick"] = {
        SoundId = "rbxassetid://15675032796",
        FallbackId = "rbxassetid://6895079853",
        Volume = 0.32,
        Pitch = 1.00,
        PitchVariation = 0.03,
        MinInterval = 0.03,
    },

    -- Gentle paper/canvas backpack opening (Roblox official UI Paper Swipe)
    ["InventoryOpen"] = {
        SoundId = "rbxassetid://15675037413",
        FallbackId = "rbxassetid://10128766965",
        Volume = 0.30,
        Pitch = 1.00,
        PitchVariation = 0.02,
        MinInterval = 0.1,
    },

    -- Gentle backpack closing / back slide (Roblox official UI Back SFX)
    ["InventoryClose"] = {
        SoundId = "rbxassetid://10066914500",
        FallbackId = "rbxassetid://15675037413",
        Volume = 0.26,
        Pitch = 0.95,
        PitchVariation = 0.02,
        MinInterval = 0.1,
    },

    -- Satisfying organic item pick-up / pocketing (Roblox official UI Select 02)
    ["ItemPickup"] = {
        SoundId = "rbxassetid://10066968815",
        FallbackId = "rbxassetid://15675059323",
        Volume = 0.30,
        Pitch = 1.05,
        PitchVariation = 0.03,
        MinInterval = 0.05,
    },

    -- Natural wood plank / timber pickup (ProSoundEffects Wood Impacts Planks 0s)
    ["WoodGather"] = {
        SoundId = "rbxassetid://9120914426",
        FallbackId = "rbxassetid://10066968815",
        Volume = 0.35,
        Pitch = 1.00,
        PitchVariation = 0.03,
        MinInterval = 0.08,
    },

    -- Gentle ground placement / discard (Roblox official UI Delete SFX)
    ["ItemDrop"] = {
        SoundId = "rbxassetid://15675075163",
        FallbackId = "rbxassetid://10066914500",
        Volume = 0.26,
        Pitch = 0.90,
        PitchVariation = 0.03,
        MinInterval = 0.05,
    },

    -- Quick bright gear latch when equipping (Roblox official UI Bright Click)
    ["ItemEquip"] = {
        SoundId = "rbxassetid://15675059323",
        FallbackId = "rbxassetid://15675032796",
        Volume = 0.28,
        Pitch = 1.00,
        PitchVariation = 0.03,
        MinInterval = 0.04,
    },

    -- Item split / stack separation (Roblox official UI Small Click higher pitch)
    ["ItemSplit"] = {
        SoundId = "rbxassetid://15675032796",
        FallbackId = "rbxassetid://10066968815",
        Volume = 0.25,
        Pitch = 1.15,
        PitchVariation = 0.02,
        MinInterval = 0.04,
    },

    -- Matchbox drawer slide and crisp match strike
    ["Matchbox"] = {
        SoundId = "rbxassetid://4510176414",
        FallbackId = "rbxassetid://15675059323",
        Volume = 0.35,
        Pitch = 1.05,
        PitchVariation = 0.03,
        MinInterval = 0.1,
    },

    -- Warm firewood crackle flare & flame whoosh (ProSoundEffects Fire Whoosh 15)
    ["CampfireFuel"] = {
        SoundId = "rbxassetid://9114446852",
        FallbackId = "rbxassetid://9120914426",
        Volume = 0.35,
        Pitch = 1.00,
        PitchVariation = 0.03,
        MinInterval = 0.1,
    },

    -- Peaceful, soft warning / capacity full (Roblox official UI Back at low pitch)
    ["Warning"] = {
        SoundId = "rbxassetid://10066914500",
        FallbackId = "rbxassetid://15675075163",
        Volume = 0.30,
        Pitch = 0.72,
        PitchVariation = 0.02,
        MinInterval = 0.12,
    },

    -- Subtle amber chime on toast notifications (Roblox official UI Select 01)
    ["Notification"] = {
        SoundId = "rbxassetid://10128760939",
        FallbackId = "rbxassetid://15675059323",
        Volume = 0.28,
        Pitch = 1.10,
        PitchVariation = 0.03,
        MinInterval = 0.1,
    },
}

-- -----------------------------------------------------------------------------
-- 2. DEDICATED UI SOUNDGROUP & POOLING
-- -----------------------------------------------------------------------------
local uiSoundGroup: SoundGroup? = nil
local lastPlayTimes: { [string]: number } = {}
local soundPool: { [string]: { Sound } } = {}

local function getUISoundGroup(): SoundGroup
    if uiSoundGroup and uiSoundGroup.Parent then
        return uiSoundGroup
    end

    local master = UITheme.GetMasterSoundGroup()
    local existing = master:FindFirstChild("UIAudioGroup") :: SoundGroup?
    if existing then
        uiSoundGroup = existing
        return existing
    end

    local group = Instance.new("SoundGroup")
    group.Name = "UIAudioGroup"
    group.Volume = 1.0
    group.Parent = master
    uiSoundGroup = group
    return group
end

-- Retrieves or instantiates a pooled Sound instance for playback
local function getPooledSound(presetName: string, config: SoundConfig): Sound
    local group = getUISoundGroup()
    soundPool[presetName] = soundPool[presetName] or {}
    local pool = soundPool[presetName]

    -- Find an idle sound in pool
    for _, sound in ipairs(pool) do
        if not sound.IsPlaying then
            if sound.SoundId ~= config.SoundId then
                sound.SoundId = config.SoundId
            end
            return sound
        end
    end

    -- Create new pooled sound instance
    local sound = Instance.new("Sound")
    sound.Name = "SFX_" .. presetName
    sound.SoundId = config.SoundId
    sound.Volume = config.Volume
    sound.PlaybackSpeed = config.Pitch
    sound.SoundGroup = group
    sound.Parent = group

    table.insert(pool, sound)
    return sound
end

-- -----------------------------------------------------------------------------
-- 3. PUBLIC PLAYBACK METHODS
-- -----------------------------------------------------------------------------

--- Plays a registered sound effect by name with micro-pitch variance and debouncing
function AudioManager.Play(soundName: string, customPitch: number?, customVolume: number?): Sound?
    local config = SOUND_PRESETS[soundName]
    if not config then
        -- Fallback to default Click
        config = SOUND_PRESETS["Click"]
    end
    if not config then return nil end

    local now = os.clock()
    local minInterval = config.MinInterval or 0.04
    local lastTime = lastPlayTimes[soundName] or 0
    if (now - lastTime) < minInterval then
        return nil -- Debounced to prevent harsh audio clutter
    end
    lastPlayTimes[soundName] = now

    local sound = getPooledSound(soundName, config)

    -- Apply micro-pitch variance for organic realism
    local basePitch = customPitch or config.Pitch
    local variance = config.PitchVariation or 0
    local finalPitch = basePitch
    if variance > 0 then
        finalPitch = basePitch + ((math.random() - 0.5) * 2 * variance)
    end

    sound.PlaybackSpeed = math.clamp(finalPitch, 0.4, 2.5)
    sound.Volume = customVolume or config.Volume
    sound:Play()

    return sound
end

--- Convenience helper: Automatically attaches subtle hover and click audio to any GuiButton
function AudioManager.AttachButton(
    button: GuiButton,
    hoverSound: string?,
    clickSound: string?
): ()
    local hoverSfx = hoverSound or "Hover"
    local clickSfx = clickSound or "Click"

    button.MouseEnter:Connect(function()
        AudioManager.Play(hoverSfx)
    end)

    button.Activated:Connect(function()
        AudioManager.Play(clickSfx)
    end)
end

--- Scans a UI container and attaches hover and click SFX to all text and image buttons
function AudioManager.AttachContainerButtons(container: Instance)
    for _, desc in ipairs(container:GetDescendants()) do
        if desc:IsA("GuiButton") then
            AudioManager.AttachButton(desc)
        end
    end

    container.DescendantAdded:Connect(function(desc)
        if desc:IsA("GuiButton") then
            AudioManager.AttachButton(desc)
        end
    end)
end

-- -----------------------------------------------------------------------------
-- 4. BACKGROUND PRELOAD
-- -----------------------------------------------------------------------------
task.defer(function()
    local assetsToPreload = {}
    for _, cfg in pairs(SOUND_PRESETS) do
        local snd = Instance.new("Sound")
        snd.SoundId = cfg.SoundId
        table.insert(assetsToPreload, snd)
    end

    pcall(function()
        ContentProvider:PreloadAsync(assetsToPreload)
    end)

    for _, s in ipairs(assetsToPreload) do
        s:Destroy()
    end
end)

return AudioManager
