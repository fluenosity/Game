--!strict
--[[
    UnderwaterController.client.lua
    Immersive underwater audiovisual and post-processing engine for "Don't Let the Fire Die".
    Developed for Fluenosity Studio.

    Features:
    - Real-time voxel-accurate camera water submersion detection with hysteresis.
    - Smooth aquatic color grading (translucent cyan-blue tint, contrast, depth saturation).
    - Optical water diffraction blur and natural depth fog attenuation.
    - AAA low-pass audio muffling via MasterSoundGroup Equalizer.
    - Floating micro-motes & rising bubble column visual juice.
    - Zero swim physics (delegated cleanly to dedicated SwimmingController.client.lua).
    - Zero jarring splash noise on water entry/exit.
]]

local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local SoundService = game:GetService("SoundService")
local Players = game:GetService("Players")

local UITheme = require(script.Parent:WaitForChild("UITheme"))

local localPlayer = Players.LocalPlayer

-- -----------------------------------------------------------------------------
-- 1. POST-PROCESSING INSTANCES SETUP
-- -----------------------------------------------------------------------------
local underwaterCC = Lighting:FindFirstChild("UnderwaterColorCorrection") :: ColorCorrectionEffect?
if not underwaterCC then
    underwaterCC = Instance.new("ColorCorrectionEffect")
    underwaterCC.Name = "UnderwaterColorCorrection"
    underwaterCC.TintColor = Color3.fromRGB(255, 255, 255)
    underwaterCC.Saturation = 0
    underwaterCC.Contrast = 0
    underwaterCC.Brightness = 0
    underwaterCC.Enabled = true
    underwaterCC.Parent = Lighting
end

local underwaterBlur = Lighting:FindFirstChild("UnderwaterBlur") :: BlurEffect?
if not underwaterBlur then
    underwaterBlur = Instance.new("BlurEffect")
    underwaterBlur.Name = "UnderwaterBlur"
    underwaterBlur.Size = 0
    underwaterBlur.Enabled = true
    underwaterBlur.Parent = Lighting
end

-- -----------------------------------------------------------------------------
-- 2. AUDIO MUFFLE (EQUALIZER) SETUP
-- -----------------------------------------------------------------------------
UITheme.InitAudioRouting()
local masterSoundGroup = UITheme.GetMasterSoundGroup()

local underwaterEQ = masterSoundGroup:FindFirstChild("UnderwaterEqualizer") :: EqualizerSoundEffect?
if not underwaterEQ then
    underwaterEQ = Instance.new("EqualizerSoundEffect")
    underwaterEQ.Name = "UnderwaterEqualizer"
    underwaterEQ.HighGain = 0
    underwaterEQ.MidGain = 0
    underwaterEQ.LowGain = 0
    underwaterEQ.Priority = 10
    underwaterEQ.Parent = masterSoundGroup
end

-- Clean up any obsolete/broken ambience loops from SoundService if previously created
local oldAmbience = SoundService:FindFirstChild("UnderwaterAmbienceLoop")
if oldAmbience then
    pcall(function() oldAmbience:Destroy() end)
end

-- -----------------------------------------------------------------------------
-- 3. UNDERWATER DRIFTING MOTES PARTICLE EMITTER
-- -----------------------------------------------------------------------------
local motePart = workspace.Terrain:FindFirstChild("UnderwaterMoteEmitter") :: Part?
if not motePart then
    motePart = Instance.new("Part")
    motePart.Name = "UnderwaterMoteEmitter"
    motePart.Size = Vector3.new(1, 1, 1)
    motePart.Transparency = 1
    motePart.CanCollide = false
    motePart.CanTouch = false
    motePart.CanQuery = false
    motePart.Anchored = true
    motePart.Parent = workspace.Terrain
end

local moteEmitter = motePart:FindFirstChild("Motes") :: ParticleEmitter?
if not moteEmitter then
    moteEmitter = Instance.new("ParticleEmitter")
    moteEmitter.Name = "Motes"
    moteEmitter.Texture = "rbxasset://textures/particles/sparkles_main.dds"
    moteEmitter.Size = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.08),
        NumberSequenceKeypoint.new(0.5, 0.16),
        NumberSequenceKeypoint.new(1, 0.05)
    })
    moteEmitter.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.9),
        NumberSequenceKeypoint.new(0.5, 0.45),
        NumberSequenceKeypoint.new(1, 1)
    })
    moteEmitter.Color = ColorSequence.new(Color3.fromRGB(180, 240, 255))
    moteEmitter.LightEmission = 0.5
    moteEmitter.Rate = 0 -- Controlled dynamically
    moteEmitter.Lifetime = NumberRange.new(1.8, 3.0)
    moteEmitter.Speed = NumberRange.new(0.4, 1.2)
    moteEmitter.SpreadAngle = Vector2.new(180, 180)
    moteEmitter.Acceleration = Vector3.new(0, 0.6, 0)
    moteEmitter.Drag = 0.8
    moteEmitter.Parent = motePart
end

-- -----------------------------------------------------------------------------
-- 4. SUBMERSION DETECTION WITH ACCURATE WATERLINE HYSTERESIS
-- -----------------------------------------------------------------------------
local isSubmerged = false
local submersionProgress = 0 -- 0 (above water) to 1 (fully submerged)
local cachedWaterSurfaceY = 0.0
local waterCheckTimer = 0

local function queryWaterSurfaceAt(pos: Vector3): number
    local minCorner = Vector3.new(
        math.floor(pos.X / 4) * 4,
        -40,
        math.floor(pos.Z / 4) * 4
    )
    local maxCorner = minCorner + Vector3.new(4, 64, 4)
    local region = Region3.new(minCorner, maxCorner):ExpandToGrid(4)

    local success, mats, occs = pcall(function()
        return workspace.Terrain:ReadVoxels(region, 4)
    end)

    if success and mats then
        for y = mats.Size.Y, 1, -1 do
            if mats[1][y][1] == Enum.Material.Water and occs[1][y][1] > 0.05 then
                return minCorner.Y + (y * 4)
            end
        end
    end
    return 0.0
end

local function checkCameraUnderwater(): boolean
    local currentCam = workspace.CurrentCamera
    if not currentCam then return false end

    local camPos = currentCam.CFrame.Position

    -- Periodically refresh local water surface elevation
    waterCheckTimer = waterCheckTimer + 0.016
    if waterCheckTimer > 0.30 then
        waterCheckTimer = 0
        cachedWaterSurfaceY = queryWaterSurfaceAt(camPos)
    end

    -- Camera is only underwater if clearly beneath the water surface level
    -- When submerged, camera stays submerged until it breaches surface (+0.05)
    -- When above water, camera stays above until it plunges below surface (-0.15)
    local thresholdY = cachedWaterSurfaceY + (isSubmerged and 0.05 or -0.15)
    if camPos.Y > thresholdY then
        return false
    end

    local minCorner = Vector3.new(
        math.floor(camPos.X / 4) * 4,
        math.floor(camPos.Y / 4) * 4,
        math.floor(camPos.Z / 4) * 4
    )
    local maxCorner = minCorner + Vector3.new(4, 4, 4)
    local region = Region3.new(minCorner, maxCorner):ExpandToGrid(4)

    local success, materials, occupancies = pcall(function()
        return workspace.Terrain:ReadVoxels(region, 4)
    end)

    if success and materials and materials[1] and materials[1][1] and materials[1][1][1] == Enum.Material.Water then
        local minOccupancy = isSubmerged and 0.08 or 0.35
        if occupancies and occupancies[1] and occupancies[1][1] and occupancies[1][1][1] > minOccupancy then
            return true
        end
    end

    return false
end

-- -----------------------------------------------------------------------------
-- 5. RENDER STEPPED ENGINE (Audiovisual Post-Processing)
-- -----------------------------------------------------------------------------
local TARGET_TINT = Color3.fromRGB(150, 220, 240)
local DEFAULT_TINT = Color3.fromRGB(255, 255, 255)

local TARGET_FOG_COLOR = Color3.fromRGB(25, 95, 125)
local DEFAULT_FOG_COLOR = Color3.fromRGB(192, 192, 192)

RunService.RenderStepped:Connect(function(dt: number)
    local currentlyUnderwater = checkCameraUnderwater()

    -- State transition with zero annoying audio spam
    if currentlyUnderwater ~= isSubmerged then
        isSubmerged = currentlyUnderwater
    end

    -- Smooth progress interpolation (clean 0.15s ease)
    local targetProgress = isSubmerged and 1.0 or 0.0
    local speed = isSubmerged and 9 or 7
    submersionProgress = submersionProgress + (targetProgress - submersionProgress) * math.clamp(dt * speed, 0, 1)

    -- 1. ColorCorrection
    underwaterCC.TintColor = DEFAULT_TINT:Lerp(TARGET_TINT, submersionProgress)
    underwaterCC.Saturation = 0.18 * submersionProgress
    underwaterCC.Contrast = 0.12 * submersionProgress
    underwaterCC.Brightness = -0.03 * submersionProgress

    -- 2. Optical Water Diffraction Blur
    underwaterBlur.Size = 2.5 * submersionProgress

    -- 3. Depth Fog Attenuation
    if submersionProgress > 0.02 then
        Lighting.FogStart = 0
        Lighting.FogEnd = 100000 - (100000 - 85) * submersionProgress
        Lighting.FogColor = DEFAULT_FOG_COLOR:Lerp(TARGET_FOG_COLOR, submersionProgress)
    else
        Lighting.FogEnd = 100000
    end

    -- 4. Audio Low-Pass Equalizer
    underwaterEQ.HighGain = -32 * submersionProgress
    underwaterEQ.MidGain = -8 * submersionProgress
    underwaterEQ.LowGain = 4 * submersionProgress

    -- 5. Motes Particle Emitter follow camera
    if submersionProgress > 0.4 then
        local currentCam = workspace.CurrentCamera
        if currentCam then
            motePart.CFrame = currentCam.CFrame * CFrame.new(0, 0, -4)
            moteEmitter.Rate = 12 * submersionProgress
        end
    else
        moteEmitter.Rate = 0
    end
end)
