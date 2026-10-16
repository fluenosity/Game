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

    -- Peaceful, subtle melee movement swish (very soft, non-intrusive)
    ["PunchSwing"] = {
        SoundId = "rbxassetid://15675075163",
        FallbackId = "rbxassetid://15675037413",
        Volume = 0.05,
        Pitch = 1.00,
        PitchVariation = 0.03,
        MinInterval = 0.12,
    },

    -- Soft, peaceful organic contact tap (muffled, zero gunshot pop)
    ["PunchImpact"] = {
        SoundId = "rbxassetid://10066914500",
        FallbackId = "rbxassetid://15675075163",
        Volume = 0.12,
        Pitch = 0.95,
        PitchVariation = 0.03,
        MinInterval = 0.08,
    },

    -- Gentle heavy impact (soft low organic thud)
    ["PunchHeavyImpact"] = {
        SoundId = "rbxassetid://10066914500",
        FallbackId = "rbxassetid://10066968815",
        Volume = 0.16,
        Pitch = 0.82,
        PitchVariation = 0.03,
        MinInterval = 0.10,
    },

    -- Soft defensive block tap
    ["BlockImpact"] = {
        SoundId = "rbxassetid://10066914500",
        FallbackId = "rbxassetid://15675075163",
        Volume = 0.14,
        Pitch = 0.78,
        PitchVariation = 0.03,
        MinInterval = 0.08,
    },

    -- Heavy impact landing from height
    ["HeavyLanding"] = {
        SoundId = "rbxassetid://9120914426",
        FallbackId = "rbxassetid://9120914426",
        Volume = 0.45,
        Pitch = 0.90,
        PitchVariation = 0.04,
        MinInterval = 0.15,
    },

    -- Rhythmic footstep crunch (legacy fallback)
    ["Footstep"] = {
        SoundId = "rbxassetid://137891923918460",
        FallbackId = "rbxassetid://10066968815",
        Volume = 0.22,
        Pitch = 1.0,
        PitchVariation = 0.05,
        MinInterval = 0.18,
    },
}

-- -----------------------------------------------------------------------------
-- MATERIAL FOOTSTEP SOUND POOLS & MAPPING (AAA PRODUCTION GRADE)
-- -----------------------------------------------------------------------------
local MATERIAL_MAP: { [Enum.Material]: string } = {
    [Enum.Material.Grass] = "Grass",
    [Enum.Material.LeafyGrass] = "Grass",
    [Enum.Material.Ground] = "Dirt",
    [Enum.Material.Mud] = "Dirt",
    [Enum.Material.Sand] = "Dirt",
    [Enum.Material.Rock] = "Stone",
    [Enum.Material.Slate] = "Stone",
    [Enum.Material.Basalt] = "Stone",
    [Enum.Material.Concrete] = "Stone",
    [Enum.Material.Brick] = "Stone",
    [Enum.Material.Cobblestone] = "Stone",
    [Enum.Material.Pavement] = "Stone",
    [Enum.Material.Wood] = "Wood",
    [Enum.Material.WoodPlanks] = "Wood",
    [Enum.Material.Metal] = "Metal",
    [Enum.Material.CorrodedMetal] = "Metal",
    [Enum.Material.DiamondPlate] = "Metal",
    [Enum.Material.Water] = "Water",
}

local MATERIAL_FOOTSTEPS: { [string]: { SoundIds: { string }, BasePitch: number, BaseVol: number } } = {
    ["Grass"] = {
        SoundIds = {
            "rbxassetid://129956418693357", -- Step A (Left foot, 0.35s)
            "rbxassetid://78534941650081",  -- Step B (Right foot, 0.42s)
        },
        BasePitch = 1.00,
        BaseVol = 0.22,
    },
    ["Dirt"] = {
        SoundIds = {
            "rbxassetid://140165597842270", -- Earthy step A
            "rbxassetid://138750508569819", -- Earthy step B
        },
        BasePitch = 1.00,
        BaseVol = 0.22,
    },
    ["Stone"] = {
        SoundIds = {
            "rbxassetid://8031019470", -- Solid stone step A
            "rbxassetid://8031020207", -- Solid stone step B
        },
        BasePitch = 1.02,
        BaseVol = 0.22,
    },
    ["Wood"] = {
        SoundIds = {
            "rbxassetid://139575423158758", -- Timber step A
            "rbxassetid://139561410113584", -- Timber step B
        },
        BasePitch = 1.00,
        BaseVol = 0.24,
    },
    ["Metal"] = {
        SoundIds = {
            "rbxassetid://15675037413", -- Metal contact A
            "rbxassetid://10066914500", -- Metal contact B
        },
        BasePitch = 1.05,
        BaseVol = 0.20,
    },
    ["Water"] = {
        SoundIds = {
            "rbxasset://sounds/impact_water.mp3",
        },
        BasePitch = 1.35,
        BaseVol = 0.26,
    },
}

local MATERIAL_LANDINGS: { [string]: { SoundId: string, Pitch: number, Volume: number } } = {
    ["Grass"] = { SoundId = "rbxassetid://93258972585027", Pitch = 1.00, Volume = 0.30 },
    ["Dirt"]  = { SoundId = "rbxassetid://140165597842270", Pitch = 0.95, Volume = 0.32 },
    ["Stone"] = { SoundId = "rbxassetid://8031021863", Pitch = 0.95, Volume = 0.35 },
    ["Wood"]  = { SoundId = "rbxassetid://139575423158758", Pitch = 0.90, Volume = 0.36 },
    ["Metal"] = { SoundId = "rbxassetid://15675037413", Pitch = 0.85, Volume = 0.30 },
    ["Water"] = { SoundId = "rbxasset://sounds/impact_water.mp3", Pitch = 1.10, Volume = 0.40 },
}

local lastMaterialIndices: { [string]: number } = {}
local lastStepTimesByPart: { [Instance]: number } = setmetatable({}, { __mode = "k" })
local fallbackLastStepTime = 0

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

    local sfxGroup = UITheme.GetSFXSoundGroup()
    uiSoundGroup = sfxGroup
    return sfxGroup
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
    if hoverSound then
        button.MouseEnter:Connect(function()
            AudioManager.Play(hoverSound)
        end)
    end

    local clickSfx = clickSound or "Click"
    button.Activated:Connect(function()
        AudioManager.Play(clickSfx)
    end)
end

--- Resolve Enum.Material to human-readable sound archetype ("Grass", "Dirt", "Stone", "Wood", "Metal", "Water")
function AudioManager.GetMaterialName(material: Enum.Material?): string
    if not material then return "Grass" end
    return MATERIAL_MAP[material] or "Grass"
end

--- Play high-fidelity, material-reactive footstep with round-robin variation and left/right stereo/pitch cadence
function AudioManager.PlayFootstep(floorMaterial: Enum.Material?, isSprinting: boolean?, isLeftFoot: boolean?, attachPart: BasePart?): ()
    local now = os.clock()
    -- Fast debounce per character to allow crisp high-speed footfalls without skipping (0.10s sprint, 0.14s walk)
    local minGap = if isSprinting then 0.10 else 0.14
    local lastStepTime = if attachPart then (lastStepTimesByPart[attachPart] or 0) else fallbackLastStepTime
    if now - lastStepTime < minGap then
        return
    end
    if attachPart then
        lastStepTimesByPart[attachPart] = now
    else
        fallbackLastStepTime = now
    end

    local matName = AudioManager.GetMaterialName(floorMaterial)
    local pool = MATERIAL_FOOTSTEPS[matName] or MATERIAL_FOOTSTEPS["Grass"]
    local ids = pool.SoundIds
    if #ids == 0 then return end

    -- Pair strictly 1 or 2 sounds: Sound 1 = Left foot, Sound 2 = Right foot
    local soundId: string
    if #ids == 1 then
        soundId = ids[1]
    elseif isLeftFoot == true then
        soundId = ids[1]
    elseif isLeftFoot == false then
        soundId = ids[2]
    else
        local lastIdx = lastMaterialIndices[matName] or 0
        local nextIdx = if lastIdx == 1 then 2 else 1
        lastMaterialIndices[matName] = nextIdx
        soundId = ids[nextIdx]
    end

    local basePitch = pool.BasePitch
    local baseVol = pool.BaseVol

    -- Distinct Left vs Right foot acoustic signature (Left = slightly deeper, Right = slightly crisper)
    if isLeftFoot ~= nil then
        if isLeftFoot then
            basePitch = basePitch * 0.98
        else
            basePitch = basePitch * 1.02
        end
    end

    -- Sprinting: +20% volume, +3% energetic pitch
    if isSprinting then
        baseVol = baseVol * 1.20
        basePitch = basePitch * 1.03
    end

    -- Organic micro-pitch variance (+/- 2%)
    local pitchVariance = (math.random() - 0.5) * 0.04
    local finalPitch = math.clamp(basePitch + pitchVariance, 0.80, 1.40)

    local group = getUISoundGroup()
    local sound = Instance.new("Sound")
    sound.Name = "Footstep_" .. matName .. (if isLeftFoot == true then "_L" elseif isLeftFoot == false then "_R" else "")
    sound.SoundId = soundId
    sound.Volume = baseVol
    sound.PlaybackSpeed = finalPitch
    sound.SoundGroup = group
    sound.RollOffMode = Enum.RollOffMode.InverseTapered
    sound.RollOffMinDistance = 3
    sound.RollOffMaxDistance = 50

    if attachPart and attachPart:IsA("BasePart") then
        sound.Parent = attachPart
    else
        sound.Parent = group
    end
    sound:Play()

    sound.Ended:Once(function()
        sound:Destroy()
    end)
    task.delay(0.9, function()
        if sound and sound.Parent then
            sound:Destroy()
        end
    end)
end

--- Play responsive landing audio based on ground material and impact speed
function AudioManager.PlayLanding(floorMaterial: Enum.Material?, impactSpeed: number?, attachPart: BasePart?): ()
    local matName = AudioManager.GetMaterialName(floorMaterial)
    local landingCfg = MATERIAL_LANDINGS[matName] or MATERIAL_LANDINGS["Grass"]

    local spd = impactSpeed or 10
    local volMultiplier = math.clamp(spd / 12, 0.7, 1.5)

    local group = getUISoundGroup()
    local sound = Instance.new("Sound")
    sound.Name = "Landing_" .. matName
    sound.SoundId = landingCfg.SoundId
    sound.Volume = landingCfg.Volume * volMultiplier
    sound.PlaybackSpeed = landingCfg.Pitch + ((math.random() - 0.5) * 0.04)
    sound.SoundGroup = group
    sound.RollOffMode = Enum.RollOffMode.InverseTapered
    sound.RollOffMinDistance = 3
    sound.RollOffMaxDistance = 50

    if attachPart and attachPart:IsA("BasePart") then
        sound.Parent = attachPart
    else
        sound.Parent = group
    end
    sound:Play()

    sound.Ended:Once(function()
        sound:Destroy()
    end)
    task.delay(1.2, function()
        if sound and sound.Parent then
            sound:Destroy()
        end
    end)
end

--- Play athletic jump takeoff sound (soft clothing rustle, zero cartoon spring/ting)
function AudioManager.PlayJumpTakeoff(attachPart: BasePart?): ()
    local group = getUISoundGroup()
    local sound = Instance.new("Sound")
    sound.Name = "JumpTakeoff"
    sound.SoundId = "rbxassetid://15675075163"
    sound.Volume = 0.14
    sound.PlaybackSpeed = 1.00 + ((math.random() - 0.5) * 0.05)
    sound.SoundGroup = group
    sound.RollOffMode = Enum.RollOffMode.InverseTapered
    sound.RollOffMinDistance = 3
    sound.RollOffMaxDistance = 45

    if attachPart and attachPart:IsA("BasePart") then
        sound.Parent = attachPart
    else
        sound.Parent = group
    end
    sound:Play()

    sound.Ended:Once(function()
        sound:Destroy()
    end)
    task.delay(0.8, function()
        if sound and sound.Parent then
            sound:Destroy()
        end
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
    for _, pool in pairs(MATERIAL_FOOTSTEPS) do
        for _, id in ipairs(pool.SoundIds) do
            local snd = Instance.new("Sound")
            snd.SoundId = id
            table.insert(assetsToPreload, snd)
        end
    end

    pcall(function()
        ContentProvider:PreloadAsync(assetsToPreload)
    end)

    for _, s in ipairs(assetsToPreload) do
        s:Destroy()
    end
end)

return AudioManager
