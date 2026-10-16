--!strict
--[[
    UnderwaterController.client.lua
    Immersive underwater audiovisual and post-processing engine for "Don't Let the Fire Die".
    Developed for Fluenosity Studio.

    Features:
    - Real-time voxel-accurate camera water submersion detection.
    - Smooth aquatic color grading (translucent cyan-blue tint, contrast, depth saturation).
    - Optical water diffraction blur and natural depth fog attenuation.
    - AAA low-pass audio muffling via MasterSoundGroup Equalizer.
    - Submersion diving impact and surfacing breach splash audio cues.
    - Ambient underwater deep-column rumble loop.
    - Floating micro-motes & rising bubble column visual juice.
]]

local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")

local UITheme = require(script.Parent:WaitForChild("UITheme"))

local localPlayer = Players.LocalPlayer
local camera = workspace.CurrentCamera or workspace:WaitForChild("Camera")

-- -----------------------------------------------------------------------------
-- 0. 3D CAMERA/MOUSE AIMED SWIMMING PHYSICS STATE
-- -----------------------------------------------------------------------------
local activeCharacter: Model? = nil
local activeHumanoid: Humanoid? = nil
local activeRootPart: BasePart? = nil
local swimAttachment: Attachment? = nil
local swimLinearVelocity: LinearVelocity? = nil

local function cleanupSwimPhysics()
    if swimLinearVelocity then
        pcall(function() swimLinearVelocity:Destroy() end)
        swimLinearVelocity = nil
    end
    if swimAttachment then
        pcall(function() swimAttachment:Destroy() end)
        swimAttachment = nil
    end
end

local function setupSwimPhysics(char: Model)
    cleanupSwimPhysics()
    activeCharacter = char
    activeHumanoid = char:WaitForChild("Humanoid", 10) :: Humanoid?
    activeRootPart = char:WaitForChild("HumanoidRootPart", 10) :: BasePart?

    if not activeRootPart then return end

    local att = Instance.new("Attachment")
    att.Name = "SwimVelocityAttachment"
    att.Parent = activeRootPart
    swimAttachment = att

    local lv = Instance.new("LinearVelocity")
    lv.Name = "SwimLinearVelocity"
    lv.Attachment0 = att
    lv.RelativeTo = Enum.ActuatorRelativeTo.World
    lv.VelocityConstraintMode = Enum.VelocityConstraintMode.Vector
    lv.MaxForce = 45000
    lv.VectorVelocity = Vector3.zero
    lv.Enabled = false
    lv.Parent = activeRootPart
    swimLinearVelocity = lv
end

if localPlayer.Character then
    task.spawn(function()
        setupSwimPhysics(localPlayer.Character :: Model)
    end)
end

localPlayer.CharacterAdded:Connect(function(newChar)
    task.spawn(function()
        setupSwimPhysics(newChar)
    end)
end)

localPlayer.CharacterRemoving:Connect(function()
    cleanupSwimPhysics()
    activeCharacter = nil
    activeHumanoid = nil
    activeRootPart = nil
end)


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
-- 2. AUDIO MUFFLE (EQUALIZER) & UNDERWATER AMBIENCE SETUP
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

-- Underwater Deep Drone / Water Column Rumble
local underwaterAmbience = SoundService:FindFirstChild("UnderwaterAmbienceLoop") :: Sound?
if not underwaterAmbience then
    underwaterAmbience = Instance.new("Sound")
    underwaterAmbience.Name = "UnderwaterAmbienceLoop"
    underwaterAmbience.SoundId = "rbxasset://sounds/swimming.mp3"
    underwaterAmbience.Looped = true
    underwaterAmbience.Volume = 0
    underwaterAmbience.PlaybackSpeed = 0.75
    underwaterAmbience.SoundGroup = UITheme.GetEnvironmentSoundGroup()
    underwaterAmbience.Parent = SoundService
end

-- Surface Break / Dive Impact SFX
local function playSplashSound(pitch: number, volume: number)
    local splash = Instance.new("Sound")
    splash.Name = "WaterTransitionSplash"
    splash.SoundId = "rbxasset://sounds/impact_water.mp3"
    splash.Volume = volume
    splash.PlaybackSpeed = pitch
    splash.SoundGroup = UITheme.GetSFXSoundGroup()
    splash.Parent = SoundService
    splash:Play()
    task.delay(1.5, function()
        pcall(function() splash:Destroy() end)
    end)
end

-- -----------------------------------------------------------------------------
-- 3. UNDERWATER DRIFTING MOTES PARTICLE EMITTER
-- -----------------------------------------------------------------------------
local motePart = Instance.new("Part")
motePart.Name = "UnderwaterMoteEmitter"
motePart.Size = Vector3.new(1, 1, 1)
motePart.Transparency = 1
motePart.CanCollide = false
motePart.CanTouch = false
motePart.CanQuery = false
motePart.Anchored = true
motePart.Parent = workspace.Terrain

local moteEmitter = Instance.new("ParticleEmitter")
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

-- -----------------------------------------------------------------------------
-- 4. SUBMERSION DETECTION & DYNAMIC SMOOTHING STATE
-- -----------------------------------------------------------------------------
local isSubmerged = false
local submersionProgress = 0 -- 0 (above water) to 1 (fully submerged)

local function checkCameraUnderwater(): boolean
    local currentCam = workspace.CurrentCamera
    if not currentCam then return false end

    local camPos = currentCam.CFrame.Position
    -- Lake water surface level in place is Y = 1.0156
    if camPos.Y > 1.05 then
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
        if occupancies and occupancies[1] and occupancies[1][1] and occupancies[1][1][1] > 0.05 then
            return true
        end
    end

    return false
end

-- -----------------------------------------------------------------------------
-- 5. 3D CAMERA / MOUSE-AIMED SWIMMING ENGINE
-- -----------------------------------------------------------------------------
local function update3DSwimming(dt: number)
    if not activeCharacter or not activeHumanoid or not activeRootPart or not swimLinearVelocity then
        return
    end

    local humState = activeHumanoid:GetState()
    local isSwimmingState = (humState == Enum.HumanoidStateType.Swimming)
    local inWater = (activeRootPart.Position.Y < 1.05 and isSubmerged)
    local isSwimming = isSwimmingState or inWater

    if not isSwimming then
        if swimLinearVelocity.Enabled then
            swimLinearVelocity.Enabled = false
            swimLinearVelocity.VectorVelocity = Vector3.zero
        end
        return
    end

    local currentCam = workspace.CurrentCamera
    if not currentCam then return end

    local camCF = currentCam.CFrame
    local camLook = camCF.LookVector
    local camRight = camCF.RightVector

    -- Decompose 2D horizontal input from Humanoid.MoveDirection (W/A/S/D or Mobile Thumbstick)
    local horizLook = Vector3.new(camLook.X, 0, camLook.Z)
    if horizLook.Magnitude > 0.001 then
        horizLook = horizLook.Unit
    else
        horizLook = Vector3.new(0, 0, -1)
    end

    local horizRight = Vector3.new(camRight.X, 0, camRight.Z)
    if horizRight.Magnitude > 0.001 then
        horizRight = horizRight.Unit
    else
        horizRight = Vector3.new(1, 0, 0)
    end

    local moveDir = activeHumanoid.MoveDirection
    local forwardInput = moveDir:Dot(horizLook)
    local rightInput = moveDir:Dot(horizRight)

    -- Ascend / Descend key checks (Space / Mobile Jump and Ctrl / C)
    local isAscending = activeHumanoid.Jump or UserInputService:IsKeyDown(Enum.KeyCode.Space)
    local isDescending = UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) or UserInputService:IsKeyDown(Enum.KeyCode.C)

    local move3D = Vector3.zero
    local hasInput = false

    -- PRIMARY FEATURE: Wherever the mouse/screen aims, pressing W drives the player in that 3D direction!
    if math.abs(forwardInput) > 0.06 then
        move3D = move3D + (camLook * forwardInput)
        hasInput = true
    end

    -- Strafe A/D along camera RightVector
    if math.abs(rightInput) > 0.06 then
        move3D = move3D + (camRight * rightInput)
        hasInput = true
    end

    -- Vertical Ascend / Descend controls
    if isAscending then
        move3D = move3D + Vector3.new(0, 0.85, 0)
        hasInput = true
    elseif isDescending then
        move3D = move3D + Vector3.new(0, -0.85, 0)
        hasInput = true
    end

    -- Surface Breaching Protection: Lake surface level is Y = 1.0156
    local WATER_SURFACE_Y = 1.0156
    if activeRootPart.Position.Y >= (WATER_SURFACE_Y - 0.25) and move3D.Y > 0 then
        -- At surface, clamp upward vertical velocity so player skims the surface naturally
        move3D = Vector3.new(move3D.X, math.min(move3D.Y, 0.05), move3D.Z)
    end

    if hasInput and move3D.Magnitude > 0.04 then
        -- Sprint Swim vs Normal Swim
        local isSprinting = (activeHumanoid.WalkSpeed >= 12 or UserInputService:IsKeyDown(Enum.KeyCode.LeftShift))
        local swimSpeed = isSprinting and 22.0 or 14.0

        local targetVelocity = move3D.Unit * swimSpeed
        swimLinearVelocity.VectorVelocity = targetVelocity
        swimLinearVelocity.Enabled = true
    else
        -- Idle: smoothly damp linear velocity to zero so character treads water naturally and plays SwimIdle
        swimLinearVelocity.Enabled = false
        activeRootPart.AssemblyLinearVelocity = activeRootPart.AssemblyLinearVelocity * 0.90
    end
end

-- -----------------------------------------------------------------------------
-- 6. RENDER STEPPED ENGINE
-- -----------------------------------------------------------------------------
local TARGET_TINT = Color3.fromRGB(150, 220, 240)
local DEFAULT_TINT = Color3.fromRGB(255, 255, 255)

local TARGET_FOG_COLOR = Color3.fromRGB(25, 95, 125)
local DEFAULT_FOG_COLOR = Color3.fromRGB(192, 192, 192)

RunService.RenderStepped:Connect(function(dt: number)
    local currentlyUnderwater = checkCameraUnderwater()

    -- State transition events
    if currentlyUnderwater ~= isSubmerged then
        isSubmerged = currentlyUnderwater
        if isSubmerged then
            -- Dove into water
            playSplashSound(0.88, 0.32)
            if not underwaterAmbience.IsPlaying then
                pcall(function() underwaterAmbience:Play() end)
            end
        else
            -- Surfaced from water
            playSplashSound(1.05, 0.36)
        end
    end

    -- Smooth progress interpolation (rapid 0.12s transition)
    local targetProgress = isSubmerged and 1.0 or 0.0
    local speed = isSubmerged and 10 or 8
    submersionProgress = submersionProgress + (targetProgress - submersionProgress) * math.clamp(dt * speed, 0, 1)

    -- 1. ColorCorrection
    underwaterCC.TintColor = DEFAULT_TINT:Lerp(TARGET_TINT, submersionProgress)
    underwaterCC.Saturation = 0.18 * submersionProgress
    underwaterCC.Contrast = 0.12 * submersionProgress
    underwaterCC.Brightness = -0.03 * submersionProgress

    -- 2. Optical Blur
    underwaterBlur.Size = 2.5 * submersionProgress

    -- 3. Depth Fog
    if submersionProgress > 0.02 then
        Lighting.FogStart = 0
        Lighting.FogEnd = 100000 - (100000 - 75) * submersionProgress
        Lighting.FogColor = DEFAULT_FOG_COLOR:Lerp(TARGET_FOG_COLOR, submersionProgress)
    else
        Lighting.FogEnd = 100000
    end

    -- 4. Audio Low-Pass Equalizer
    underwaterEQ.HighGain = -32 * submersionProgress
    underwaterEQ.MidGain = -8 * submersionProgress
    underwaterEQ.LowGain = 4 * submersionProgress

    -- 5. Ambient Loop Volume
    underwaterAmbience.Volume = 0.22 * submersionProgress
    if submersionProgress < 0.01 and underwaterAmbience.IsPlaying then
        pcall(function() underwaterAmbience:Stop() end)
    end

    -- 6. Motes Particle Emitter follow camera
    if submersionProgress > 0.4 then
        local currentCam = workspace.CurrentCamera
        if currentCam then
            motePart.CFrame = currentCam.CFrame * CFrame.new(0, 0, -4)
            moteEmitter.Rate = 12 * submersionProgress
        end
    else
        moteEmitter.Rate = 0
    end

    -- 7. 3D Camera / Mouse Aimed Swimming Physics Engine
    update3DSwimming(dt)
end)


