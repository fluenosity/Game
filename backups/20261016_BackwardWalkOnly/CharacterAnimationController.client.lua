--!strict
--[[
    CharacterAnimationController.client.lua
    Production-Grade Procedural First-Person Perspective (FPP) Animation Controller
    for "Don't Let the Fire Die". Developed for Fluenosity Studio.

    Features:
    - Combat keeps its existing hit, damage, and guard logic without character action poses
    - Locomotion & Body Awareness:
      * FPP Natural Idle: Breathing cycle with relaxed hands visible in peripheral view
      * FPP Walk Cycle (WalkSpeed = 16): Rhythmic arm swing & synchronized footsteps
      * FPP Sprint Cycle (WalkSpeed = 26): Forward lean, high-energy arm pump, dynamic camera sway
      * Lightweight airborne movement with the default R15 jump/fall animation
      * Soft landing feedback without a landing pose or movement lock
      * FPP Crouch / Sneak [C] / [LeftCtrl]: Low-profile sneak posture & lowered camera
    - Interaction and combat actions do not replace the character movement animations
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local ProximityPromptService = game:GetService("ProximityPromptService")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

local sharedFolder = ReplicatedStorage:WaitForChild("FluenosityShared")
local AudioManager = require(script.Parent:WaitForChild("AudioManager"))
local ModalManager = require(script.Parent:WaitForChild("ModalManager"))
local SurvivorRigConfig = require(sharedFolder:WaitForChild("SurvivorRigConfig"))
local SurvivorBoneSync = require(sharedFolder:WaitForChild("SurvivorBoneSync"))

-- -----------------------------------------------------------------------------
-- 1. REMOTE COMMUNICATION
-- -----------------------------------------------------------------------------
local meleeAttackEvent = sharedFolder:FindFirstChild("MeleeAttackRequest") :: RemoteEvent?
if not meleeAttackEvent then
    meleeAttackEvent = Instance.new("RemoteEvent")
    meleeAttackEvent.Name = "MeleeAttackRequest"
    meleeAttackEvent.Parent = sharedFolder
end

local meleeHitReplicatedEvent = sharedFolder:FindFirstChild("MeleeHitReplicated") :: RemoteEvent?
if not meleeHitReplicatedEvent then
    meleeHitReplicatedEvent = Instance.new("RemoteEvent")
    meleeHitReplicatedEvent.Name = "MeleeHitReplicated"
    meleeHitReplicatedEvent.Parent = sharedFolder
end
local meleeBlockRequestEvent = sharedFolder:WaitForChild("MeleeBlockRequest") :: RemoteEvent
local meleeBlockStateEvent = sharedFolder:WaitForChild("MeleeBlockState") :: RemoteEvent

-- -----------------------------------------------------------------------------
-- 2. SPRING DAMPER SYSTEM (Euler-Maruyama Integration)
-- -----------------------------------------------------------------------------
type Spring = {
    Position: Vector3,
    Velocity: Vector3,
    Target: Vector3,
    Stiffness: number,
    Damping: number,
    Update: (self: Spring, dt: number) -> Vector3,
    Reset: (self: Spring, pos: Vector3) -> (),
}

local function createSpring(stiffness: number, damping: number, initialPos: Vector3?): Spring
    local self: Spring = {
        Position = initialPos or Vector3.zero,
        Velocity = Vector3.zero,
        Target = initialPos or Vector3.zero,
        Stiffness = stiffness,
        Damping = damping,
        Update = function(s, dt: number): Vector3
            local d = math.clamp(dt, 0, 0.05)
            local force = (s.Target - s.Position) * s.Stiffness
            s.Velocity = (s.Velocity + force * d) * math.clamp(1 - s.Damping * d, 0, 1)
            s.Position = s.Position + s.Velocity * d
            return s.Position
        end,
        Reset = function(s, pos: Vector3)
            s.Position = pos
            s.Velocity = Vector3.zero
            s.Target = pos
        end,
    }
    return self
end

-- Camera Springs for visceral recoil and procedural bob
local camRecoilSpring = createSpring(280, 26) -- Weapon impact recoil (Pitch, Yaw, Roll)
local camSwaySpring = createSpring(140, 16)   -- Horizontal locomotion sway

-- Euphoria-Level Physical Springs
local landingSpring = createSpring(130, 15)   -- Y-compression impulse on touchdown
local leanSpring = createSpring(95, 14)       -- X = forward lean, Z = centrifugal turn banking
local sprintSpring = createSpring(120, 16)    -- 0 = walk/idle, 1 = full sprint
local currentSprintAlpha = 0
local currentAirborneAlpha = 0
local currentHeadPostureAlpha = 0
local lastYaw = 0

-- -----------------------------------------------------------------------------
-- 3. ANIMATION STATE MACHINE
-- -----------------------------------------------------------------------------
type CombatAction = "None" | "WeaponLightA" | "WeaponLightB" | "WeaponHeavy" | "Block"
type SpecialAction = "None" | "GroundPickup" | "CampfireLight" | "ItemThrow" | "GuardBreak" | "Died"

local state = {
    IsSprinting = false,
    IsGrounded = true,
    IsAirborne = false,
    IsDead = false,

    -- Combat
    CombatAction = "None" :: CombatAction,
    LastHeavyAttackTime = 0,
    NextLightSwing = 1,
    IsFHeld = false,

    -- Action timings
    ActionStartTime = 0,
    ActionDuration = 0,
    SpecialAction = "None" :: SpecialAction,
    SpecialStartTime = 0,
    SpecialDuration = 0,

    -- Locomotion phase
    WalkCycleClock = 0,
    LastFootstepClock = 0,
    LastVerticalVelocity = 0,
}
local attackToken = 0

-- -----------------------------------------------------------------------------
-- ANIMATION-SYNCHRONIZED MASTER LOCOMOTION CYCLE & MULTIPLAYER 3D AUDIO
-- -----------------------------------------------------------------------------
local STEP_STRIDE_WALK = 2.70   -- Studs per walk step (~0.45s at WalkSpeed = 6)
local STEP_STRIDE_SPRINT = 4.30 -- Studs per sprint step (~0.27s at WalkSpeed = 16)

-- Skeletal forward-kinematic contact timestamps (measured across all keyframes in Studio):
-- Female Walk (0.967s): Right foot touchdown @ 0.167s (0.17), Left foot touchdown @ 0.567s (0.58)
-- Male Walk (1.033s):   Right foot touchdown @ 0.200s (0.19), Left foot touchdown @ 0.680s (0.66)
-- Main Run (0.633s):    Right foot touchdown @ 0.033s (0.05), Left foot touchdown @ 0.333s (0.52)
local ANIM_FOOTSTEP_TIMELINES: { [string]: { Right: number, Left: number, IsRun: boolean } } = {
    ["115531053004010"] = { Right = 0.17, Left = 0.58, IsRun = false },
    ["70412449762831"]  = { Right = 0.19, Left = 0.66, IsRun = false },
    ["99676638771528"]  = { Right = 0.05, Left = 0.52, IsRun = true },
}

type FootstepTracker = {
    IsActive: boolean,
    StepTimer: number,
    NextIsLeft: boolean,
    StepInterval: number,
    StopGraceTime: number,
    LastTrack: AnimationTrack?,
    LastHRPPos: Vector3?,
    LastFloorMaterial: Enum.Material?,
}

local characterTrackers: { [Model]: FootstepTracker } = setmetatable({}, { __mode = "k" })

local function getCharacterTracker(char: Model): FootstepTracker
    local tracker = characterTrackers[char]
    if not tracker then
        tracker = {
            IsActive = false,
            StepTimer = 0,
            NextIsLeft = false,
            StepInterval = 0.28,
            StopGraceTime = 0,
            LastTrack = nil,
            LastHRPPos = nil,
            LastFloorMaterial = nil,
        }
        characterTrackers[char] = tracker
    end
    return tracker
end

local function findLocomotionTrack(animator: Animator, wantsSprint: boolean?): (AnimationTrack?, boolean, { Right: number, Left: number, IsRun: boolean }?)
    local bestTrack: AnimationTrack? = nil
    local isRun = false
    local matchedTimeline: { Right: number, Left: number, IsRun: boolean }? = nil

    local playingTracks = animator:GetPlayingAnimationTracks()

    -- 1. Lock strictly to the preferred track based on sprint intent (prevents weight-jitter flip-flopping)
    for _, track in ipairs(playingTracks) do
        if track.IsPlaying then
            local aId = track.Animation and track.Animation.AnimationId or ""
            local cleanId = string.match(aId, "%d+") or ""
            local timeline = ANIM_FOOTSTEP_TIMELINES[cleanId]

            if wantsSprint == true then
                if (timeline and timeline.IsRun) or string.find(string.lower(track.Name), "run") then
                    return track, true, timeline or { Right = 0.05, Left = 0.52, IsRun = true }
                end
            else
                if (timeline and not timeline.IsRun) or string.find(string.lower(track.Name), "walk") then
                    return track, false, timeline or { Right = 0.17, Left = 0.58, IsRun = false }
                end
            end
        end
    end

    -- 2. Fallback: select whichever locomotion track has highest current weight
    local bestWeight = 0.01
    for _, track in ipairs(playingTracks) do
        local w = track.WeightCurrent
        if track.IsPlaying and w > bestWeight then
            local aId = track.Animation and track.Animation.AnimationId or ""
            local cleanId = string.match(aId, "%d+") or ""
            local timeline = ANIM_FOOTSTEP_TIMELINES[cleanId]
            local tName = track.Name

            if timeline then
                bestTrack = track
                bestWeight = w
                isRun = timeline.IsRun
                matchedTimeline = timeline
            elseif string.find(string.lower(tName), "run") then
                bestTrack = track
                bestWeight = w
                isRun = true
                matchedTimeline = { Right = 0.05, Left = 0.52, IsRun = true }
            elseif string.find(string.lower(tName), "walk") then
                bestTrack = track
                bestWeight = w
                isRun = false
                matchedTimeline = { Right = 0.17, Left = 0.58, IsRun = false }
            end
        end
    end

    return bestTrack, isRun, matchedTimeline
end

local function evaluateCharacterFootsteps(
    char: Model,
    isLocal: boolean,
    dt: number,
    isMovingLocal: boolean?,
    wantsSprintLocal: boolean?
)
    local hum = if isLocal then (activeHumanoid or char:FindFirstChildOfClass("Humanoid")) else char:FindFirstChildOfClass("Humanoid")
    local hrp = if isLocal then (activeHRP or (char:FindFirstChild("HumanoidRootPart") :: BasePart?)) else (char:FindFirstChild("HumanoidRootPart") :: BasePart?)
    if not hum or not hrp or hum.Health <= 0 then return end

    local tracker = getCharacterTracker(char)

    if not isLocal then
        -- Co-op Audio Culling: Skip remote players beyond audible range (60 studs)
        if not camera or (hrp.Position - camera.CFrame.Position).Magnitude > 60 then
            tracker.IsActive = false
            tracker.StepTimer = 0
            tracker.LastTrack = nil
            tracker.LastHRPPos = nil
            return
        end
    end

    local isMoving = false
    local isGrounded = false
    local isSprinting = false
    local detectedFloorMat: Enum.Material? = hum.FloorMaterial
    local isDeliberateJump = (hum:GetState() == Enum.HumanoidStateType.Jumping)

    if isLocal then
        isMoving = isMovingLocal == true
        isSprinting = wantsSprintLocal == true
    else
        local moveVel = hrp.AssemblyLinearVelocity * Vector3.new(1, 0, 1)
        local moveSpeed = moveVel.Magnitude
        isMoving = (moveSpeed > 1.2) or (hum.MoveDirection.Magnitude > 0.05)
        isSprinting = (moveSpeed > 12)
    end

    -- Deep Ground and Floor Material Detection (Rock-solid across terrain boundaries):
    if detectedFloorMat ~= Enum.Material.Air and detectedFloorMat ~= nil then
        isGrounded = true
    elseif hum:GetState() == Enum.HumanoidStateType.Running or hum:GetState() == Enum.HumanoidStateType.RunningNoPhysics then
        isGrounded = true
    end

    -- Downward raycast (6.0 studs) provides seamless resilience across terrain seams/elevation ruts
    if hrp then
        local rayParams = RaycastParams.new()
        rayParams.FilterDescendantsInstances = { char }
        rayParams.FilterType = Enum.RaycastFilterType.Exclude
        local hit = workspace:Raycast(hrp.Position, Vector3.new(0, -6.0, 0), rayParams)
        if hit then
            if not isDeliberateJump then
                isGrounded = true
            end
            if detectedFloorMat == Enum.Material.Air or detectedFloorMat == nil then
                detectedFloorMat = hit.Material
            end
        end
    end

    -- Locomotion Cadence Discontinuation Check:
    -- Footsteps and stride cadence ONLY stop when:
    -- 1. Character has actually stopped moving (no input, zero horizontal speed)
    -- 2. Character is in a deliberate high jump (Jumping state) or freefalling fast (> 15 studs/s down)
    local isAirborneJump = isDeliberateJump or (not isGrounded and hrp.AssemblyLinearVelocity.Y < -15)

    local isSwimming = (hum:GetState() == Enum.HumanoidStateType.Swimming)

    if not isMoving or isAirborneJump or isSwimming then
        tracker.StopGraceTime = tracker.StopGraceTime + dt
        if tracker.StopGraceTime > 0.16 or isSwimming then
            tracker.IsActive = false
            tracker.StepTimer = 0
            tracker.LastTrack = nil
        end
        if isLocal then
            state.WalkCycleClock = state.WalkCycleClock + dt * 1.8 -- Idle breathing cadence
        end
        return
    else
        tracker.StopGraceTime = 0
    end

    local animator = if isLocal then (activeAnimator or hum:FindFirstChildOfClass("Animator")) else hum:FindFirstChildOfClass("Animator")
    local activeTrack: AnimationTrack? = nil
    local isRunTrack = isSprinting

    if animator then
        activeTrack, isRunTrack = findLocomotionTrack(animator, isSprinting)
    end

    -- Derive exact cadence interval per single step:
    -- Athletic sprint: ~3.4 to 3.7 steps/sec -> interval ~ 0.26s - 0.28s (rapid!)
    -- Walk: calibrated to normalWalkSpeed (6) -> interval ~ 0.50s - 0.64s
    local targetInterval: number
    if activeTrack and activeTrack.Length > 0.1 then
        local animSpeed = math.max(0.65, math.abs(activeTrack.Speed))
        local halfCycle = (activeTrack.Length / animSpeed) * 0.5
        if isRunTrack then
            targetInterval = math.clamp(halfCycle, 0.25, 0.29)
        else
            targetInterval = math.clamp(halfCycle, 0.50, 0.64)
        end
    else
        targetInterval = if isRunTrack then 0.28 else 0.58
    end
    -- Smoothly adapt interval without abrupt jumps:
    tracker.StepInterval = tracker.StepInterval + (targetInterval - tracker.StepInterval) * math.clamp(dt * 8, 0, 1)

    local stepTriggered = false
    local triggeredIsLeft = false

    if not tracker.IsActive then
        -- Initial takeoff detection: check active animation track phase at movement start
        local initialIsLeft = false
        if activeTrack and activeTrack.Length > 0.1 then
            local normPos = (activeTrack.TimePosition % activeTrack.Length) / activeTrack.Length
            initialIsLeft = (normPos >= 0.28 and normPos < 0.78)
        end

        tracker.IsActive = true
        tracker.StepTimer = 0
        stepTriggered = true
        triggeredIsLeft = initialIsLeft
        tracker.NextIsLeft = not initialIsLeft -- Next step alternates to opposite foot
    else
        -- Continuous Cadence Stride Engine (Pure rock-solid metronome):
        tracker.StepTimer = tracker.StepTimer + dt

        -- Check if next footstep in the pair is due
        if tracker.StepTimer >= tracker.StepInterval then
            tracker.StepTimer = tracker.StepTimer - tracker.StepInterval
            if tracker.StepTimer > tracker.StepInterval * 0.5 then
                tracker.StepTimer = 0
            end
            stepTriggered = true
            triggeredIsLeft = tracker.NextIsLeft
            tracker.NextIsLeft = not tracker.NextIsLeft -- Alternate foot: R -> L -> R -> L -> R -> L
        end
    end

    if isLocal then
        -- Phase-lock local FPP viewmodel arm swing and camera motion to the exact cadence:
        local strideFreq = (math.pi * 2) / (tracker.StepInterval * 2)
        state.WalkCycleClock = state.WalkCycleClock + dt * strideFreq
    end

    if stepTriggered then
        local floorMat = (detectedFloorMat ~= Enum.Material.Air and detectedFloorMat ~= nil) and detectedFloorMat or tracker.LastFloorMaterial or Enum.Material.Grass
        tracker.LastFloorMaterial = floorMat

        AudioManager.PlayFootstep(floorMat, isRunTrack, triggeredIsLeft, hrp)
    end
end

-- -----------------------------------------------------------------------------
-- 4. CHARACTER JOINTS & VISIBILITY REGISTRY
-- -----------------------------------------------------------------------------
local activeCharacter: Model? = nil
local activeHumanoid: Humanoid? = nil
local activeHRP: BasePart? = nil
local activeAnimator: Animator? = nil
local activeBoneSyncPairs: { { Source: Bone, Target: Bone } } = {}

type JointSet = {
    RightShoulder: Instance?,
    RightElbow: Instance?,
    RightWrist: Instance?,
    LeftShoulder: Instance?,
    LeftElbow: Instance?,
    LeftWrist: Instance?,
    Waist: Instance?,
    Neck: Instance?,
    Root: Instance?,
    RightHip: Instance?,
    LeftHip: Instance?,
    RightKnee: Instance?,
    LeftKnee: Instance?,
    RightAnkle: Instance?,
    LeftAnkle: Instance?,
    HipsBone: Instance?,
    HeadBone: Instance?,
    LeftUpLeg: Instance?,
    RightUpLeg: Instance?,
}

local joints: JointSet = {
    RightShoulder = nil,
    RightElbow = nil,
    RightWrist = nil,
    LeftShoulder = nil,
    LeftElbow = nil,
    LeftWrist = nil,
    Waist = nil,
    Neck = nil,
    Root = nil,
    RightHip = nil,
    LeftHip = nil,
    RightKnee = nil,
    LeftKnee = nil,
    RightAnkle = nil,
    LeftAnkle = nil,
    HipsBone = nil,
    HeadBone = nil,
    LeftUpLeg = nil,
    RightUpLeg = nil,
}

local LIGHT_ATTACK_DURATION = 0.50
local HEAVY_ATTACK_DURATION = 0.52
local HEAVY_ATTACK_COOLDOWN = 0.85
local GUARD_BREAK_DURATION = 1.25
local function getEquippedCombatWeapon(character: Model): Tool?
    for _, child in ipairs(character:GetChildren()) do
        if child:IsA("Tool") and child:GetAttribute("CombatWeapon") == true then
            return child
        end
    end
    return nil
end

local function playWeaponSound(character: Model?, soundName: string): boolean
    if not character then return false end
    local tool = getEquippedCombatWeapon(character)
    local handle = tool and tool:FindFirstChild("Handle")
    local sound = handle and handle:FindFirstChild(soundName)
    if sound and sound:IsA("Sound") then
        sound:Play()
        return true
    end
    return false
end

local armParts: { BasePart } = {}
local headParts: { BasePart } = {}
local characterConnections: { RBXScriptConnection } = {}
local defaultHipHeight = 2.0
local locomotionTracks: { [string]: AnimationTrack } = {}
local activeLocomotionName: string? = nil
local currentLeanZ = 0

local function getLocomotionTrack(trackName: string?): AnimationTrack?
    if not trackName then return nil end
    return locomotionTracks[trackName]
end

local function transitionLocomotion(trackName: string?, fadeTime: number?)
    if activeLocomotionName == trackName then return end

    local fade = fadeTime or 0.14
    local previousTrack = getLocomotionTrack(activeLocomotionName)
    if previousTrack and previousTrack.IsPlaying then
        previousTrack:Stop(fade)
    end

    activeLocomotionName = trackName
    local nextTrack = getLocomotionTrack(trackName)
    if nextTrack then
        nextTrack:Play(fade)
    end
end

-- Safely set Transform on either AnimationConstraint or Motor6D
local function setJointTransform(joint: Instance?, cf: CFrame)
    if not joint then return end
    pcall(function()
        (joint :: any).Transform = cf
    end)
end

-- Safely multiply Transform on top of base animation pose
local function applyJointOffset(joint: Instance?, offset: CFrame)
    if not joint then return end
    pcall(function()
        (joint :: any).Transform = (joint :: any).Transform * offset
    end)
end

local function cacheCharacterJoints(char: Model)
    for _, connection in ipairs(characterConnections) do
        connection:Disconnect()
    end
    table.clear(characterConnections)

    state.IsSprinting = false
    state.IsGrounded = true
    state.IsAirborne = false
    state.IsDead = false
    state.CombatAction = "None"
    state.LastHeavyAttackTime = 0
    state.NextLightSwing = 1
    state.SpecialAction = "None"
    state.ActionStartTime = 0
    state.ActionDuration = 0
    attackToken += 1
    for _, track in pairs(locomotionTracks) do
        if track.IsPlaying then track:Stop(0) end
        track:Destroy()
    end
    table.clear(locomotionTracks)
    activeLocomotionName = nil
    sprintSpring:Reset(Vector3.zero)
    landingSpring:Reset(Vector3.zero)
    characterTrackers[char] = nil

    activeCharacter = char
    activeHumanoid = char:WaitForChild("Humanoid", 10) :: Humanoid?
    activeHRP = char:WaitForChild("HumanoidRootPart", 10) :: BasePart?
    activeAnimator = (activeHumanoid and activeHumanoid:WaitForChild("Animator", 10) :: Animator?)
        or (char:FindFirstChildWhichIsA("Animator", true) :: Animator?)

    table.insert(characterConnections, char:GetAttributeChangedSignal("IsGuardBroken"):Connect(function()
        if char:GetAttribute("IsGuardBroken") == true then
            state.CombatAction = "None"
            state.SpecialAction = "GuardBreak"
            state.SpecialStartTime = os.clock()
            state.SpecialDuration = GUARD_BREAK_DURATION
        elseif state.SpecialAction == "GuardBreak" then
            state.SpecialAction = "None"
        end
    end))

    table.clear(armParts)
    table.clear(headParts)

    -- Discover R15 joints
    joints.RightShoulder = char:FindFirstChild("RightShoulder", true)
    joints.RightElbow = char:FindFirstChild("RightElbow", true)
    joints.RightWrist = char:FindFirstChild("RightWrist", true)
    joints.LeftShoulder = char:FindFirstChild("LeftShoulder", true)
    joints.LeftElbow = char:FindFirstChild("LeftElbow", true)
    joints.LeftWrist = char:FindFirstChild("LeftWrist", true)
    joints.Waist = char:FindFirstChild("Waist", true)
    joints.Neck = char:FindFirstChild("Neck", true)
    joints.Root = char:FindFirstChild("Root", true)
    joints.RightHip = char:FindFirstChild("RightHip", true)
    joints.LeftHip = char:FindFirstChild("LeftHip", true)
    joints.RightKnee = char:FindFirstChild("RightKnee", true)
    joints.LeftKnee = char:FindFirstChild("LeftKnee", true)
    joints.RightAnkle = char:FindFirstChild("RightAnkle", true)
    joints.HipsBone = char:FindFirstChild("mixamorig:Hips", true)
    joints.NeckBone = char:FindFirstChild("mixamorig:Neck", true)
    joints.HeadBone = char:FindFirstChild("mixamorig:Head", true)
    joints.LeftUpLeg = char:FindFirstChild("mixamorig:LeftUpLeg", true)
    joints.RightUpLeg = char:FindFirstChild("mixamorig:RightUpLeg", true)

    -- Discover secondary deformer bones (e.g. mixamorig6 for Jody)
    table.clear(activeBoneSyncPairs)
    for _, d in ipairs(char:GetDescendants()) do
        if d:IsA("Bone") and string.find(d.Name, "^mixamorig6:") then
            local baseName = string.gsub(d.Name, "^mixamorig6:", "mixamorig:")
            local sourceBone = char:FindFirstChild(baseName, true)
            if sourceBone and sourceBone:IsA("Bone") then
                table.insert(activeBoneSyncPairs, { Source = sourceBone, Target = d })
            end
        end
    end

    -- Cache arms for FPP viewmodel unmasking
    for _, partName in ipairs({ "LeftUpperArm", "LeftLowerArm", "LeftHand", "RightUpperArm", "RightLowerArm", "RightHand" }) do
        local p = char:FindFirstChild(partName)
        if p and p:IsA("BasePart") then
            table.insert(armParts, p)
        end
    end

    -- Cache head and head accessories for clipping prevention
    local head = char:FindFirstChild("Head")
    if head and head:IsA("BasePart") then
        table.insert(headParts, head)
    end
    for _, item in ipairs(char:GetChildren()) do
        if item:IsA("Accessory") then
            local handle = item:FindFirstChild("Handle")
            if handle and handle:IsA("BasePart") then
                table.insert(headParts, handle)
            end
        end
    end

    -- Humanoid state listeners
    if activeHumanoid then
        defaultHipHeight = activeHumanoid.HipHeight > 0 and activeHumanoid.HipHeight or 2.0

        -- Permanently silence default Roblox character sounds (plastic running, jump, land)
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if hrp then
            local function silenceDefaultSound(s: Instance)
                if s:IsA("Sound") then
                    local sName = s.Name
                    if sName == "Running" or sName == "Climbing" or sName == "Jumping" or sName == "Landing" then
                        s.Volume = 0
                        s.SoundId = ""
                        s:Stop()
                    end
                end
            end

            for _, c in ipairs(hrp:GetChildren()) do
                silenceDefaultSound(c)
            end
            table.insert(characterConnections, hrp.ChildAdded:Connect(silenceDefaultSound))
            AudioManager.PrewarmFootsteps(hrp)
        end

        -- Ensure natural human skin tone on skin mesh parts
        local skinTone = Color3.fromRGB(222, 178, 148)
        for _, name in ipairs({ "Head", "LeftHand", "RightHand", "LeftUpperArm", "RightUpperArm", "LeftLowerArm", "RightLowerArm" }) do
            local p = char:FindFirstChild(name)
            if p and p:IsA("BasePart") then
                p.Color = skinTone
            end
        end
        table.insert(characterConnections, activeHumanoid.Died:Connect(function()
            state.IsDead = true
            state.SpecialAction = "Died"
            state.SpecialStartTime = os.clock()
            state.SpecialDuration = 999
            AudioManager.Play("HeavyLanding")
        end))

        local jumpInitiated = false
        local freefallStartTime = 0

        table.insert(characterConnections, activeHumanoid.StateChanged:Connect(function(oldState, newState)
            if newState == Enum.HumanoidStateType.Jumping then
                state.IsAirborne = true
                state.IsGrounded = false
                jumpInitiated = true
            elseif newState == Enum.HumanoidStateType.Freefall then
                freefallStartTime = os.clock()
                if activeHumanoid.FloorMaterial == Enum.Material.Air then
                    state.IsAirborne = true
                    state.IsGrounded = false
                else
                    state.IsAirborne = false
                    state.IsGrounded = true
                end
            elseif newState == Enum.HumanoidStateType.Running or newState == Enum.HumanoidStateType.RunningNoPhysics or newState == Enum.HumanoidStateType.Landed then
                state.IsAirborne = false
                state.IsGrounded = true
            end

            -- When jump finishes (touchdown on the ground):
            local hasLanded = (newState == Enum.HumanoidStateType.Landed)
                or (oldState == Enum.HumanoidStateType.Freefall and (newState == Enum.HumanoidStateType.Running or newState == Enum.HumanoidStateType.RunningNoPhysics))

            if hasLanded then
                local fallDuration = os.clock() - freefallStartTime
                local shouldPlayLanding = jumpInitiated or (fallDuration > 0.35)

                if shouldPlayLanding then
                    jumpInitiated = false
                    freefallStartTime = 0

                    landingSpring.Velocity = Vector3.new(0, 1.8, 0)
                    local floorMat = activeHumanoid.FloorMaterial
                    if (floorMat == Enum.Material.Air or floorMat == nil) and hrp then
                        local rayParams = RaycastParams.new()
                        rayParams.FilterDescendantsInstances = { char }
                        rayParams.FilterType = Enum.RaycastFilterType.Exclude
                        local rayResult = workspace:Raycast(hrp.Position, Vector3.new(0, -6.0, 0), rayParams)
                        if rayResult then
                            floorMat = rayResult.Material
                        end
                    end
                    AudioManager.PlayLanding(floorMat, nil, hrp)
                end
            end
        end))
    end
end

if player.Character then
    cacheCharacterJoints(player.Character)
end
player.CharacterAdded:Connect(cacheCharacterJoints)

-- -----------------------------------------------------------------------------
-- MULTIPLAYER CO-OP: REMOTE PLAYER JUMP & LAND 3D AUDIO HOOKS
-- -----------------------------------------------------------------------------
local remotePlayerConnections: { [Player]: { RBXScriptConnection } } = {}

local function hookRemotePlayer(otherPlayer: Player)
    if otherPlayer == player then return end

    local function onCharacterAdded(char: Model)
        local hum = char:WaitForChild("Humanoid", 10) :: Humanoid?
        local hrp = char:WaitForChild("HumanoidRootPart", 10) :: BasePart?
        if not hum or not hrp then return end

        local lastYVel = 0
        local conns = remotePlayerConnections[otherPlayer] or {}
        remotePlayerConnections[otherPlayer] = conns

        local remoteJumpInitiated = false
        local remoteFreefallStartTime = 0

        local stateConn = hum.StateChanged:Connect(function(oldState, newState)
            if not camera or not hrp.Parent then return end
            if (hrp.Position - camera.CFrame.Position).Magnitude > 60 then return end

            if newState == Enum.HumanoidStateType.Jumping then
                remoteJumpInitiated = true
            elseif newState == Enum.HumanoidStateType.Freefall then
                remoteFreefallStartTime = os.clock()
            end

            local hasLanded = (newState == Enum.HumanoidStateType.Landed)
                or (oldState == Enum.HumanoidStateType.Freefall and (newState == Enum.HumanoidStateType.Running or newState == Enum.HumanoidStateType.RunningNoPhysics))

            if hasLanded then
                local fallDuration = os.clock() - remoteFreefallStartTime
                local shouldPlayLanding = remoteJumpInitiated or (fallDuration > 0.35)

                if shouldPlayLanding then
                    remoteJumpInitiated = false
                    remoteFreefallStartTime = 0

                    local floorMat = hum.FloorMaterial
                    if (floorMat == Enum.Material.Air or floorMat == nil) and hrp then
                        local rayParams = RaycastParams.new()
                        rayParams.FilterDescendantsInstances = { char }
                        rayParams.FilterType = Enum.RaycastFilterType.Exclude
                        local hit = workspace:Raycast(hrp.Position, Vector3.new(0, -6.0, 0), rayParams)
                        if hit then floorMat = hit.Material end
                    end
                    AudioManager.PlayLanding(floorMat, nil, hrp)
                end
            end
        end)
        table.insert(conns, stateConn)

        local velConn = RunService.Heartbeat:Connect(function()
            if hrp and hrp.Parent then
                lastYVel = hrp.AssemblyLinearVelocity.Y
            end
        end)
        table.insert(conns, velConn)
    end

    if otherPlayer.Character then
        onCharacterAdded(otherPlayer.Character)
    end
    otherPlayer.CharacterAdded:Connect(onCharacterAdded)
end

for _, p in ipairs(Players:GetPlayers()) do
    hookRemotePlayer(p)
end
Players.PlayerAdded:Connect(hookRemotePlayer)
Players.PlayerRemoving:Connect(function(leavingPlayer)
    local conns = remotePlayerConnections[leavingPlayer]
    if conns then
        for _, c in ipairs(conns) do
            c:Disconnect()
        end
        remotePlayerConnections[leavingPlayer] = nil
    end
end)

-- -----------------------------------------------------------------------------
-- 5. HIT DETECTION & ATTACK DISPATCHER
-- -----------------------------------------------------------------------------
-- Sync sound when any melee attack connects (peaceful, no screen flinch)
if meleeHitReplicatedEvent then
    meleeHitReplicatedEvent.OnClientEvent:Connect(function(attacker, targetChar, attackType, hitPos, soundName, isBlocked)
        if attacker == player then
            -- Attacker feedback
            local hasToolHitSound = playWeaponSound(attacker.Character, if isBlocked then "Block" else "Hit")
            if hasToolHitSound then
                return
            elseif soundName and soundName ~= "" then
                AudioManager.Play(soundName)
            else
                AudioManager.Play(isBlocked and "BlockImpact" or "PunchImpact")
            end
        elseif targetChar == activeCharacter then
            if not playWeaponSound(attacker.Character, if isBlocked then "Block" else "Hit") then
                AudioManager.Play(isBlocked and "BlockImpact" or "PunchImpact")
            end
        end
    end)
end

-- -----------------------------------------------------------------------------
-- 6. PUBLIC INTERACTION TRIGGERS (Campfire, Pickup, Throw)
-- -----------------------------------------------------------------------------
local CharacterAnimationController = {}

function CharacterAnimationController.TriggerCampfireLighting()
    if state.IsDead then return end
    state.SpecialAction = "CampfireLight"
    state.SpecialStartTime = os.clock()
    state.SpecialDuration = 1.6
    AudioManager.Play("Matchbox")
end

function CharacterAnimationController.TriggerGroundPickup()
    if state.IsDead then return end
    state.SpecialAction = "GroundPickup"
    state.SpecialStartTime = os.clock()
    state.SpecialDuration = 0.42
    AudioManager.Play("WoodGather")
end

function CharacterAnimationController.TriggerItemThrow()
    if state.IsDead then return end
    state.SpecialAction = "ItemThrow"
    state.SpecialStartTime = os.clock()
    state.SpecialDuration = 0.45
    AudioManager.Play("ItemDrop")
end

-- Export globally into FluenosityShared so HUD and server scripts can invoke cleanly
_G.FluenosityAnimController = CharacterAnimationController

-- Listen to ProximityPrompts for natural world action triggers
ProximityPromptService.PromptTriggered:Connect(function(prompt: ProximityPrompt, triggeringPlayer: Player)
    if triggeringPlayer ~= player then return end

    if prompt.Name == "CampfireTogglePrompt" or prompt.ActionText == "Light Campfire" or prompt.ActionText == "Fuel Fire" then
        CharacterAnimationController.TriggerCampfireLighting()
    elseif prompt.Name == "WoodGatherPrompt" or prompt.Name == "ItemPickupPrompt" or prompt.ActionText == "Gather Wood" or prompt.ActionText == "Pick Up" then
        CharacterAnimationController.TriggerGroundPickup()
    end
end)

-- -----------------------------------------------------------------------------
-- 7. INPUT HANDLING (M1 Combo, Heavy [E], Block [F]/Right Mouse, Crouch [C])
-- -----------------------------------------------------------------------------
local function isInputEligible(): boolean
    if player:GetAttribute("IsInGameplay") ~= true then return false end
    if state.IsDead then return false end
    if state.SpecialAction ~= "None" then return false end
    if state.CombatAction == "Block" then return false end
    if ModalManager.IsAnyModalOpen() then return false end
    if UserInputService:GetFocusedTextBox() ~= nil then return false end
    return true
end

local function setBlocking(isBlocking: boolean)
    if activeCharacter then
        activeCharacter:SetAttribute("IsBlocking", isBlocking)
    end
    meleeBlockRequestEvent:FireServer(isBlocking)
    if isBlocking then
        state.CombatAction = "Block"
    elseif state.CombatAction == "Block" then
        state.CombatAction = "None"
    end
end

local function executeAttack(attackType: string, duration: number)
    if not activeCharacter or not getEquippedCombatWeapon(activeCharacter) or not camera or not activeHumanoid then return end
    local hrp = activeCharacter:FindFirstChild("HumanoidRootPart") :: BasePart?
    if not hrp then return end

    -- Flag as attacking (Animate script reads this to prevent idle snap)
    activeCharacter:SetAttribute("IsAttacking", true)
    -- Keep movement free; the weapon swing animation blends over locomotion.

    attackToken += 1
    local currentToken = attackToken
    task.delay(duration, function()
        if attackToken == currentToken and activeHumanoid and not state.IsDead then
            if activeCharacter then
                activeCharacter:SetAttribute("IsAttacking", false)
            end
            if state.CombatAction == "WeaponLightA" or state.CombatAction == "WeaponLightB"
                or state.CombatAction == "WeaponHeavy" then
                state.CombatAction = "None"
            end
        end
    end)

    -- Use equipped tool swing audio when present, with a quiet fallback.
    if not playWeaponSound(activeCharacter, "Swing") then
        AudioManager.Play("PunchSwing")
    end

    -- Spatial raycast forward to find target instance and impact point (for open-world hitting)
    local rayParams = RaycastParams.new()
    rayParams.FilterDescendantsInstances = { activeCharacter }
    rayParams.FilterType = Enum.RaycastFilterType.Exclude

    local reach = 7.5
    local rayResult = workspace:Raycast(camera.CFrame.Position, camera.CFrame.LookVector * (reach + 3.0), rayParams)

    local targetInstance: Instance? = rayResult and rayResult.Instance or nil
    local hitPos: Vector3 = rayResult and rayResult.Position or (hrp.Position + camera.CFrame.LookVector * reach)
    local hitNormal: Vector3 = rayResult and rayResult.Normal or Vector3.new(0, 1, 0)

    -- Fire server validation (if hitting dummy, entity, or open world)
    if meleeAttackEvent then
        meleeAttackEvent:FireServer(attackType, targetInstance, hitPos, hitNormal)
    end
end

local function triggerLightAttack()
    if not isInputEligible() or not activeCharacter or not getEquippedCombatWeapon(activeCharacter) then return end
    local now = os.clock()
    local attackType = if state.NextLightSwing == 1 then "WeaponLightA" else "WeaponLightB"
    state.NextLightSwing = if state.NextLightSwing == 1 then 2 else 1
    state.CombatAction = attackType
    state.ActionStartTime = now
    state.ActionDuration = LIGHT_ATTACK_DURATION
    executeAttack(attackType, LIGHT_ATTACK_DURATION)
end

local function triggerHeavyAttack()
    if not isInputEligible() or not activeCharacter or not getEquippedCombatWeapon(activeCharacter) then return end
    local now = os.clock()
    if now - state.LastHeavyAttackTime < HEAVY_ATTACK_COOLDOWN then return end

    state.CombatAction = "WeaponHeavy"
    state.ActionStartTime = now
    state.ActionDuration = HEAVY_ATTACK_DURATION
    state.LastHeavyAttackTime = now
    executeAttack("WeaponHeavy", HEAVY_ATTACK_DURATION)
end

UserInputService.InputBegan:Connect(function(input: InputObject, gameProcessed: boolean)
    if not isInputEligible() then return end
    if gameProcessed
        and input.UserInputType ~= Enum.UserInputType.MouseButton1
        and input.UserInputType ~= Enum.UserInputType.MouseButton2 then
        return
    end

    -- Guard / Block [F] or right mouse button.
    if input.KeyCode == Enum.KeyCode.F or input.UserInputType == Enum.UserInputType.MouseButton2 then
        state.IsFHeld = true
        setBlocking(true)
        return
    end

    -- Heavy weapon swing uses E so right mouse remains available for blocking.
    if input.KeyCode == Enum.KeyCode.E then
        triggerHeavyAttack()
        return
    end

    -- M1: one quick, equipped weapon swing while movement continues.
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        triggerLightAttack()
        return
    end
end)

UserInputService.InputEnded:Connect(function(input: InputObject)
    -- Guard / Block [F] or right mouse release.
    if input.KeyCode == Enum.KeyCode.F or input.UserInputType == Enum.UserInputType.MouseButton2 then
        state.IsFHeld = false
        if state.CombatAction == "Block" then
            setBlocking(false)
        end
        return
    end
end)

meleeBlockStateEvent.OnClientEvent:Connect(function(acceptedBlocking: boolean)
    if acceptedBlocking or state.CombatAction ~= "Block" then return end
    state.CombatAction = "None"
    if activeCharacter then
        activeCharacter:SetAttribute("IsBlocking", false)
    end
end)

-- -----------------------------------------------------------------------------
-- 8. PROCEDURAL KINEMATICS ENGINE (Stepped & RenderStepped)
-- -----------------------------------------------------------------------------
-- Helper for smooth hermite curve easing
local function easeOutCubic(t: number): number
    return 1 - math.pow(1 - t, 3)
end

local function easeInOutQuad(t: number): number
    if t < 0.5 then
        return 2 * t * t
    else
        return 1 - math.pow(-2 * t + 2, 2) / 2
    end
end

-- Motor6D/AnimationConstraint.Transform is overwritten by Animator before PreSimulation.
-- Compose the game's original procedural movement layer over its locomotion tracks.
RunService.PreSimulation:Connect(function(dt: number)
    if not activeCharacter or not activeHumanoid or not activeHRP then return end

    local now = os.clock()
    local profileId = (activeCharacter:GetAttribute("SurvivorProfileId") or activeCharacter.Name) :: string
    local profile = SurvivorRigConfig.GetProfile(profileId, activeCharacter)

    -- In-Place Pelvic Root Stabilizer:
    -- Mixamo animations without 'In Place' checked (FemaleWalk, MaleWalk, RunningJumpMain)
    -- translate -5.1 to -14.1 studs forward along Z on mixamorig:Hips.
    -- Locking Z = 0 keeps the pelvis anchored to HumanoidRootPart, producing clean,
    -- perfect in-place locomotion without forward-and-back rubberbanding or forward jump throw.
    if not joints.HipsBone and activeCharacter then
        joints.HipsBone = activeCharacter:FindFirstChild("mixamorig:Hips", true)
    end
    if joints.HipsBone and joints.HipsBone:IsA("Bone") then
        local hipsBone = joints.HipsBone :: Bone
        local t = hipsBone.Transform
        if math.abs(t.Position.Z) > 0.001 then
            hipsBone.Transform = CFrame.new(t.Position.X, t.Position.Y, 0) * t.Rotation
        end
    end

    -- Leg Stance Clearance:
    -- Prevents catwalk scissor-crossing (X-legs) on feminine walk animations by applying
    -- subtle outward flare (-5.5°) to LeftUpLeg / RightUpLeg so feet step parallel with natural clearance.
    if not joints.LeftUpLeg and activeCharacter then
        joints.LeftUpLeg = activeCharacter:FindFirstChild("mixamorig:LeftUpLeg", true)
        joints.RightUpLeg = activeCharacter:FindFirstChild("mixamorig:RightUpLeg", true)
    end
    if joints.LeftUpLeg and joints.RightUpLeg then
        local flare = profile.LegClearanceAngleDeg or 0
        if flare ~= 0 then
            joints.LeftUpLeg.Transform = joints.LeftUpLeg.Transform * CFrame.Angles(0, 0, math.rad(flare))
            joints.RightUpLeg.Transform = joints.RightUpLeg.Transform * CFrame.Angles(0, 0, math.rad(-flare))
        end
    end

    -- Step secondary deformer bone sync & remote character root stabilizers
    for _, otherPlayer in ipairs(Players:GetPlayers()) do
        if otherPlayer ~= player and otherPlayer.Character then
            SurvivorBoneSync.RegisterCharacter(otherPlayer.Character)
        end
    end
    SurvivorBoneSync.StepAll()

    local moveVel = activeHRP.AssemblyLinearVelocity
    local horizontalSpeed = Vector3.new(moveVel.X, 0, moveVel.Z).Magnitude
    state.LastVerticalVelocity = moveVel.Y

    local isMovingIntent = activeHumanoid.MoveDirection.Magnitude > 0.05
    local isLocomoting = (horizontalSpeed > 1.0 or isMovingIntent)
    local isMoving = isLocomoting and (state.IsGrounded or state.IsAirborne)
    local wantsSprint = (activeHumanoid.WalkSpeed >= 12 or UserInputService:IsKeyDown(Enum.KeyCode.LeftShift)) and isMoving
    state.IsSprinting = wantsSprint

    -- Smooth spring for walk <-> sprint transitions
    sprintSpring.Target = Vector3.new(wantsSprint and 1 or 0, 0, 0)
    currentSprintAlpha = math.clamp(sprintSpring:Update(dt).X, 0, 1)

    local effectiveSprintAlpha = currentSprintAlpha

    -- Smooth airborne easing for procedural viewmodel arm stabilization during jumps
    local targetAirborne = (state.IsAirborne and not state.IsGrounded) and 1 or 0
    currentAirborneAlpha = currentAirborneAlpha + (targetAirborne - currentAirborneAlpha) * math.clamp(dt * 10, 0, 1)

    -- Main Idle Detection (StaticIDLEMAIND only):
    -- Head posture correction is ONLY applied in the main idle animation.
    -- During walk and running, posture remains 100% normal (0 deg offset).
    local isMainIdle = false
    if not isMoving and state.IsGrounded and activeAnimator then
        for _, track in ipairs(activeAnimator:GetPlayingAnimationTracks()) do
            if track.IsPlaying and track.Animation and track.Animation.AnimationId then
                if string.find(track.Animation.AnimationId, "103828063959982") then
                    isMainIdle = true
                    break
                end
            end
        end
    end

    local targetHeadAlpha = (isMainIdle and 1 or 0)
    currentHeadPostureAlpha = currentHeadPostureAlpha + (targetHeadAlpha - currentHeadPostureAlpha) * math.clamp(dt * 12, 0, 1)

    -- Upright Head & Neck Posture Alignment (Active ONLY in Main Idle):
    if not joints.NeckBone and activeCharacter then
        joints.NeckBone = activeCharacter:FindFirstChild("mixamorig:Neck", true)
    end
    if not joints.HeadBone and activeCharacter then
        joints.HeadBone = activeCharacter:FindFirstChild("mixamorig:Head", true)
    end

    local neckBack = (profile.Facial and profile.Facial.NeckPostureBackDeg or 11.0) * currentHeadPostureAlpha
    local headBack = (profile.Facial and profile.Facial.HeadPostureBackDeg or 14.5) * currentHeadPostureAlpha

    if joints.NeckBone and joints.NeckBone:IsA("Bone") and neckBack > 0.05 then
        local neckBone = joints.NeckBone :: Bone
        neckBone.Transform = neckBone.Transform * CFrame.Angles(math.rad(neckBack), 0, 0)
    end

    if joints.HeadBone and joints.HeadBone:IsA("Bone") then
        local headBone = joints.HeadBone :: Bone
        local gazeRange = profile.Facial and profile.Facial.MicroGazeRangeDeg or 1.0
        local restTilt = (profile.Facial and profile.Facial.HeadRestTiltDeg or 0.0) * currentHeadPostureAlpha

        local saccadeClock = now * 0.42
        local gazeYaw = math.sin(saccadeClock * 0.75 + math.sin(saccadeClock * 1.4)) * math.rad(gazeRange) * currentHeadPostureAlpha
        local gazePitch = math.cos(saccadeClock * 0.85) * math.rad(gazeRange * 0.6) * currentHeadPostureAlpha
        local friendlyTilt = math.rad(restTilt)

        if headBack > 0.05 or gazeYaw ~= 0 or gazePitch ~= 0 then
            local totalPitch = math.rad(headBack) + gazePitch
            local gazeOffset = CFrame.Angles(totalPitch, gazeYaw, friendlyTilt)
            headBone.Transform = headBone.Transform * gazeOffset
        end
    end

    -- 1. Local Player Locomotion & Master Cycle Synchronization
    if activeCharacter then
        evaluateCharacterFootsteps(activeCharacter, true, dt, isMoving, wantsSprint)
    end

    -- 2. Nearby Co-op Players 3D Proximity Locomotion & Audio
    for _, otherPlayer in ipairs(Players:GetPlayers()) do
        if otherPlayer ~= player then
            local otherChar = otherPlayer.Character
            if otherChar then
                evaluateCharacterFootsteps(otherChar, false, dt)
            end
        end
    end

    -- Evaluate active Combat Action expiration
    if state.CombatAction ~= "None" and state.CombatAction ~= "Block" then
        if now - state.ActionStartTime > state.ActionDuration then
            state.CombatAction = "None"
        end
    end

    -- Evaluate Special Action expiration
    if state.SpecialAction ~= "None" and state.SpecialAction ~= "Died" then
        if now - state.SpecialStartTime > state.SpecialDuration then
            state.SpecialAction = "None"
        end
    end

    local isTPP = player:GetAttribute("IsTPP") == true

    ----------------------------------------------------------------------------
    -- EUPHORIA-LEVEL PHYSICAL SPRINGS EVALUATION
    ----------------------------------------------------------------------------
    local landingVal = landingSpring:Update(dt).Y
    local landingComp = math.clamp(landingVal * 0.08, 0, 0.85)

    -- Centripetal banking into turns (lean)
    local currentLook = activeHRP.CFrame.LookVector
    local currentYaw = math.atan2(currentLook.X, currentLook.Z)
    local yawDelta = (currentYaw - lastYaw + math.pi) % (2 * math.pi) - math.pi
    lastYaw = currentYaw

    local bankTarget = 0
    if isTPP and isMoving and horizontalSpeed > 3 then
        -- Ultra-mild, subtle visual-only banking in TPP (under 1.5 degrees, zero motion fatigue)
        local bankFactor = math.clamp(horizontalSpeed / 20, 0.2, 0.8)
        bankTarget = math.clamp(-yawDelta * bankFactor * 0.8, -math.rad(1.5), math.rad(1.5))
    end

    -- Forward lean: only apply in TPP so FPP camera horizon stays rock-steady
    local forwardLeanTarget = isTPP and math.rad(2 + effectiveSprintAlpha * 4) or 0
    if not isMoving then forwardLeanTarget = 0 end
    if isTPP then
        forwardLeanTarget = forwardLeanTarget + math.rad(landingComp * 2)
    end

    leanSpring.Target = Vector3.new(forwardLeanTarget, 0, bankTarget)
    local leanPos = leanSpring:Update(dt)
    currentLeanZ = isTPP and leanPos.Z or 0

    -- The original movement set is used regardless of equipped tools.
    local humanoidState = activeHumanoid:GetState()
    local nextLocomotion: string? = nil
    local usesDefaultStateAnimation = humanoidState == Enum.HumanoidStateType.Climbing
        or humanoidState == Enum.HumanoidStateType.Swimming
        or humanoidState == Enum.HumanoidStateType.Seated
        or humanoidState == Enum.HumanoidStateType.Dead

    if not usesDefaultStateAnimation then
        if humanoidState == Enum.HumanoidStateType.Jumping or humanoidState == Enum.HumanoidStateType.Freefall then
            -- Let the character's original Animate script handle the air states.
            nextLocomotion = nil
        elseif isMoving then
            nextLocomotion = (wantsSprint or horizontalSpeed >= 9.5) and "Run" or "Walk"
        else
            nextLocomotion = nil
        end
    end

    local selectedLocomotionTrack = getLocomotionTrack(nextLocomotion)
    if selectedLocomotionTrack and selectedLocomotionTrack.Length <= 0 then
        selectedLocomotionTrack = nil
    end
    local authoredLocomotionActive = selectedLocomotionTrack ~= nil
    if authoredLocomotionActive then
        transitionLocomotion(nextLocomotion)
        local activeTrack = selectedLocomotionTrack :: AnimationTrack
        local playbackSpeed = 1
        if nextLocomotion == "Walk" then
            playbackSpeed = math.clamp(horizontalSpeed / 6.0, 0.70, 1.35)
        elseif nextLocomotion == "Run" then
            playbackSpeed = math.clamp(horizontalSpeed / 12.0, 0.75, 1.35)
        end
        activeTrack:AdjustSpeed(playbackSpeed)
    else
        transitionLocomotion(nil)
    end

    local leftTurnTrack = locomotionTracks["leftTurn60fps"] or locomotionTracks["LeftTurn"]
    local rightTurnTrack = locomotionTracks["RightTurn60fps"] or locomotionTracks["RightTurn"]

    if leftTurnTrack then
        if isMoving and yawDelta > 0.04 then
            if not leftTurnTrack.IsPlaying then
                leftTurnTrack:Play(0.12)
            end
            leftTurnTrack:AdjustWeight(math.clamp(yawDelta * 8, 0.2, 1.0))
        else
            if leftTurnTrack.IsPlaying then
                leftTurnTrack:Stop(0.18)
            end
        end
    end

    if rightTurnTrack then
        if isMoving and yawDelta < -0.04 then
            if not rightTurnTrack.IsPlaying then
                rightTurnTrack:Play(0.12)
            end
            rightTurnTrack:AdjustWeight(math.clamp(-yawDelta * 8, 0.2, 1.0))
        else
            if rightTurnTrack.IsPlaying then
                rightTurnTrack:Stop(0.18)
            end
        end
    end

    ----------------------------------------------------------------------------
    -- PROCEDURAL LOWER BODY & SPINE KINEMATICS
    ----------------------------------------------------------------------------
    local rootOffset = CFrame.identity
    local rHipOffset = CFrame.identity
    local lHipOffset = CFrame.identity
    local rKneeOffset = CFrame.identity
    local lKneeOffset = CFrame.identity
    local rAnkleOffset = CFrame.identity
    local lAnkleOffset = CFrame.identity
    local waistOffset = isTPP and CFrame.Angles(leanPos.X, 0, leanPos.Z) or CFrame.identity

    -- 1. Soft landing compression; continuous attenuation with speed so there is zero boolean snapping.
    local moveCompFactor = math.clamp(1 - (horizontalSpeed / 2.5), 0, 1)
    local effectiveLandingComp = landingComp * moveCompFactor
    if effectiveLandingComp > 0.001 then
        rootOffset = rootOffset * CFrame.new(0, -effectiveLandingComp * 0.06, 0)
        rKneeOffset = rKneeOffset * CFrame.Angles(math.rad(-effectiveLandingComp * 2.0), 0, 0)
        lKneeOffset = lKneeOffset * CFrame.Angles(math.rad(-effectiveLandingComp * 2.0), 0, 0)
        waistOffset = waistOffset * CFrame.Angles(math.rad(effectiveLandingComp * 1.0), 0, 0)
    end

    -- 4. Dynamic turn banking applied to root (TPP only, ultra-mild)
    if isTPP and math.abs(leanPos.Z) > 0.0001 then
        rootOffset = rootOffset * CFrame.Angles(0, 0, leanPos.Z * 0.3)
    end

    applyJointOffset(joints.Root, rootOffset)
    applyJointOffset(joints.RightHip, rHipOffset)
    applyJointOffset(joints.LeftHip, lHipOffset)
    applyJointOffset(joints.RightKnee, rKneeOffset)
    applyJointOffset(joints.LeftKnee, lKneeOffset)
    applyJointOffset(joints.RightAnkle, rAnkleOffset)
    applyJointOffset(joints.LeftAnkle, lAnkleOffset)
    applyJointOffset(joints.Waist, waistOffset)

    ----------------------------------------------------------------------------
    -- BASE POSE BLENDING (Idle Breathing & Locomotion)
    ----------------------------------------------------------------------------
    local idleBreath = math.sin(state.WalkCycleClock * (isMoving and 1.0 or 1.2))
    local walkStride = math.sin(state.WalkCycleClock)
    local walkBob = math.abs(math.cos(state.WalkCycleClock))

    local rShoulderBase: CFrame = CFrame.identity
    local lShoulderBase: CFrame = CFrame.identity
    local rElbowBase: CFrame = CFrame.identity
    local lElbowBase: CFrame = CFrame.identity
    local rWristBase: CFrame = CFrame.identity
    local lWristBase: CFrame = CFrame.identity

    if isTPP then
        -- In TPP: Base animation swings arms naturally; we only override during actions
        if state.IsCrouching then
            rShoulderBase = CFrame.Angles(math.rad(14), math.rad(-10), math.rad(12))
            lShoulderBase = CFrame.Angles(math.rad(14), math.rad(10), math.rad(-12))
            rElbowBase = CFrame.Angles(math.rad(28), 0, 0)
            lElbowBase = CFrame.Angles(math.rad(28), 0, 0)
        end
    else
        -- FIRST-PERSON PERSPECTIVE (FPP): Viewmodel ready posture visible in camera
        rShoulderBase = CFrame.Angles(math.rad(68), math.rad(-26), math.rad(14))
        rElbowBase = CFrame.Angles(math.rad(-78), math.rad(12), 0)
        rWristBase = CFrame.Angles(math.rad(-14), math.rad(10), 0)

        lShoulderBase = CFrame.Angles(math.rad(68), math.rad(26), math.rad(-14))
        lElbowBase = CFrame.Angles(math.rad(-78), math.rad(-12), 0)
        lWristBase = CFrame.Angles(math.rad(-14), math.rad(-10), 0)

        if state.IsCrouching then
            rShoulderBase = CFrame.Angles(math.rad(82), math.rad(-34), math.rad(24))
            lShoulderBase = CFrame.Angles(math.rad(82), math.rad(34), math.rad(-24))
            rElbowBase = CFrame.Angles(math.rad(-112), math.rad(20), 0)
            lElbowBase = CFrame.Angles(math.rad(-112), math.rad(-20), 0)
        elseif isMoving then
            local swingAmp = (16 + (effectiveSprintAlpha * 14)) * (1 - currentAirborneAlpha * 0.7)
            local armSwing = math.rad(walkStride * swingAmp)
            local forwardLean = math.rad(4 + effectiveSprintAlpha * 6)

            rShoulderBase = rShoulderBase * CFrame.Angles(armSwing + forwardLean, 0, math.rad(-armSwing * 0.2))
            lShoulderBase = lShoulderBase * CFrame.Angles(-armSwing + forwardLean, 0, math.rad(-armSwing * 0.2))
            rElbowBase = rElbowBase * CFrame.Angles(math.rad(walkBob * (8 + effectiveSprintAlpha * 8)), 0, 0)
            lElbowBase = lElbowBase * CFrame.Angles(math.rad(walkBob * (8 + effectiveSprintAlpha * 8)), 0, 0)
        else
            local breathPitch = math.rad(idleBreath * 1.8)
            rShoulderBase = rShoulderBase * CFrame.Angles(breathPitch, 0, math.rad(idleBreath * 0.8))
            lShoulderBase = lShoulderBase * CFrame.Angles(breathPitch, 0, math.rad(-idleBreath * 0.8))
        end
    end

    ----------------------------------------------------------------------------
    -- APPLY PROCEDURAL ARM TRANSFORMS
    ----------------------------------------------------------------------------
    if not isTPP then
        setJointTransform(joints.RightShoulder, rShoulderBase)
        setJointTransform(joints.RightElbow, rElbowBase)
        setJointTransform(joints.RightWrist, rWristBase)
        setJointTransform(joints.LeftShoulder, lShoulderBase)
        setJointTransform(joints.LeftElbow, lElbowBase)
        setJointTransform(joints.LeftWrist, lWristBase)
    end
end)

-- -----------------------------------------------------------------------------
-- 9. CAMERA KINEMATICS & VIEWMODEL RENDERING (RenderStepped)
-- -----------------------------------------------------------------------------
RunService.RenderStepped:Connect(function(dt: number)
    if not camera or not activeCharacter then return end

    -- 1. Unmask First-Person arms and prevent head clipping (or keep all visible in TPP)
    local isTPP = player:GetAttribute("IsTPP") == true
    for _, part in ipairs(armParts) do
        part.LocalTransparencyModifier = 0
    end
    for _, headPart in ipairs(headParts) do
        headPart.LocalTransparencyModifier = isTPP and 0 or 1
    end
    if isTPP then
        for _, acc in ipairs(activeCharacter:GetChildren()) do
            if acc:IsA("Accessory") then
                local h = acc:FindFirstChild("Handle")
                if h and h:IsA("BasePart") then
                    h.LocalTransparencyModifier = 0
                end
            end
        end
    end

    -- 2. Update Spring Dampers
    local recoil = camRecoilSpring:Update(dt)
    local sway = camSwaySpring:Update(dt)

    -- Dynamic sprint FOV expansion (smoothly ramp from 70 up to 76 for speed sensation)
    if not isTPP then
        camera.FieldOfView = 70 + (currentSprintAlpha * 6)
    end

    -- 3. Camera Offset adjustments (Death & Campfire)
    if activeHumanoid then
        local targetYOffset = 0.0
        if state.SpecialAction == "Died" then
            targetYOffset = -2.8 -- Collapse into snow
        elseif state.SpecialAction == "CampfireLight" then
            targetYOffset = -1.6 -- Kneel at campfire
        end

        local currentOffset = activeHumanoid.CameraOffset
        local newY = currentOffset.Y + (targetYOffset - currentOffset.Y) * math.clamp(dt * 12, 0, 1)
        activeHumanoid.CameraOffset = Vector3.new(0, newY, 0)
    end

    -- 4. Apply Stable Horizon to Camera CFrame (Zero screen bending / roll in FPP)
    if player:GetAttribute("IsInGameplay") == true and not ModalManager.IsAnyModalOpen() then
        local recoilCF = CFrame.Angles(recoil.X, recoil.Y, recoil.Z)
        if state.SpecialAction == "Died" then
            recoilCF = recoilCF * CFrame.Angles(math.rad(48), 0, math.rad(18)) -- Head planted into snow
        end
        -- In FPP: Zero camera roll (flat, rock-steady horizon, zero motion fatigue)
        -- In TPP: Ultra-mild bank roll
        local bankRollCF = isTPP and CFrame.Angles(0, 0, -currentLeanZ * 0.2) or CFrame.identity
        camera.CFrame = camera.CFrame * recoilCF * bankRollCF
    end

    -- 5. Camera-Driven Player Rotation (Main player body rotates with camera look)
    if player:GetAttribute("IsInGameplay") == true and not ModalManager.IsAnyModalOpen() then
        if activeHRP and activeHumanoid and activeHumanoid.Health > 0 and state.SpecialAction == "None" then
            activeHumanoid.AutoRotate = false
            local isSwimming = (activeHumanoid:GetState() == Enum.HumanoidStateType.Swimming)

            if isSwimming then
                -- In water / swimming: full 3D aim rotation (pitch and yaw)
                local camLook = camera.CFrame.LookVector
                if camLook.Magnitude > 0.001 then
                    local p = activeHRP.Position
                    activeHRP.CFrame = CFrame.lookAt(p, p + camLook)
                end
            else
                -- On land: horizontal yaw rotation (chest & arms always face crosshair)
                local camLook = camera.CFrame.LookVector
                local horizLook = Vector3.new(camLook.X, 0, camLook.Z)
                if horizLook.Magnitude > 0.001 then
                    horizLook = horizLook.Unit
                    local p = activeHRP.Position
                    activeHRP.CFrame = CFrame.lookAt(p, p + horizLook)
                end
            end
        end
    else
        if activeHumanoid and activeHumanoid.AutoRotate == false then
            activeHumanoid.AutoRotate = true
        end
    end

end)

return CharacterAnimationController
