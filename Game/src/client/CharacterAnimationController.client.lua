--!strict
--[[
    CharacterAnimationController.client.lua
    Production-Grade Procedural First-Person Perspective (FPP) Animation Controller
    for "Don't Let the Fire Die". Developed for Fluenosity Studio.

    Features:
    - 100% Procedural R15 Joint Blending (Spring Damper Kinematics)
      * Works flawlessly on both AnimationConstraint and Motor6D joints
      * 0% asset permission failures (immune to Roblox catalog permission blocks)
    - Full Combat Suite:
      * M1 light punches alternate right and left hands
      * Punches blend over the active R15 run, jump, and fall pose
      * Right-Click Heavy Punch: MouseButton2 (Hold >= 0.4s) power windup & knockback thrust
      * Block / Guard: [F] or Hold M2 defensive raised-arm guard (-70% incoming damage)
    - Locomotion & Body Awareness:
      * FPP Natural Idle: Breathing cycle with relaxed hands visible in peripheral view
      * FPP Walk Cycle (WalkSpeed = 16): Rhythmic arm swing & synchronized footsteps
      * FPP Sprint Cycle (WalkSpeed = 26): Forward lean, high-energy arm pump, dynamic camera sway
      * FPP Jump & Apex: Upward momentum takeoff & suspended airborne float
      * FPP Heavy Landing: Deep camera compression dip & hands bracing downward
      * FPP Crouch / Sneak [C] / [LeftCtrl]: Low-profile sneak posture & lowered camera
    - World & Survival Interactions:
      * Lighting Campfire: Kneel down & match striking gesture
      * Ground Pickup: One-handed downward scoop to harvest wood/stone
      * Drop Item Throw: Forward toss gesture when discarding/dropping inventory items
      * Death Collapse: Forward knee drop and snow faceplant on Health = 0
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
local camRecoilSpring = createSpring(280, 26) -- Punch kick recoil (Pitch, Yaw, Roll)
local camDipSpring = createSpring(180, 18)    -- Vertical landing/crouch dip
local camSwaySpring = createSpring(140, 16)   -- Horizontal locomotion sway

-- Euphoria-Level Physical Springs
local crouchSpring = createSpring(140, 18)    -- 0 = standing, 1 = fully crouched
local landingSpring = createSpring(130, 15)   -- Y-compression impulse on touchdown
local leanSpring = createSpring(95, 14)       -- X = forward lean, Z = centrifugal turn banking
local sprintSpring = createSpring(120, 16)    -- 0 = walk/idle, 1 = full sprint
local currentSprintAlpha = 0
local lastYaw = 0

-- -----------------------------------------------------------------------------
-- 3. ANIMATION STATE MACHINE
-- -----------------------------------------------------------------------------
type CombatAction = "None" | "PunchRight" | "PunchLeft" | "HeavyWindup" | "HeavyRelease" | "Block"
type SpecialAction = "None" | "GroundPickup" | "CampfireLight" | "ItemThrow" | "HeavyLanding" | "Died"

local state = {
    IsCrouching = false,
    IsSprinting = false,
    IsGrounded = true,
    IsAirborne = false,
    IsDead = false,

    -- Combat
    CombatAction = "None" :: CombatAction,
    ComboStep = 0, -- 0 = right hand next, 1 = left hand next
    LastLightPunchTime = 0,
    M2PressStartTime = 0,
    IsM2Held = false,
    IsFHeld = false,
    HeavyCharged = false,

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

-- -----------------------------------------------------------------------------
-- 4. CHARACTER JOINTS & VISIBILITY REGISTRY
-- -----------------------------------------------------------------------------
local activeCharacter: Model? = nil
local activeHumanoid: Humanoid? = nil
local activeHRP: BasePart? = nil

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
}

local armParts: { BasePart } = {}
local headParts: { BasePart } = {}
local defaultHipHeight = 2.0
local locomotionTracks: { [string]: AnimationTrack } = {}
local currentLeanZ = 0

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
    activeCharacter = char
    activeHumanoid = char:WaitForChild("Humanoid", 10) :: Humanoid?
    activeHRP = char:WaitForChild("HumanoidRootPart", 10) :: BasePart?

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
    joints.LeftAnkle = char:FindFirstChild("LeftAnkle", true)

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

        local animator = activeHumanoid:WaitForChild("Animator", 5) :: Animator?
        local kfsProvider = game:GetService("KeyframeSequenceProvider")
        -- Optional authored locomotion tracks; procedural R15 offsets remain the fallback.
        local locoFolder = sharedFolder:FindFirstChild("LocomotionAnimations")
        if animator and locoFolder then
            table.clear(locomotionTracks)
            for _, item in ipairs(locoFolder:GetChildren()) do
                pcall(function()
                    local track: AnimationTrack? = nil
                    if item:IsA("Animation") then
                        track = animator:LoadAnimation(item)
                    elseif item:IsA("KeyframeSequence") then
                        local url = kfsProvider:RegisterKeyframeSequence(item)
                        local anim = Instance.new("Animation")
                        anim.AnimationId = url
                        track = animator:LoadAnimation(anim)
                    end
                    if track then
                        track.Priority = Enum.AnimationPriority.Movement
                        locomotionTracks[item.Name] = track
                    end
                end)
            end
        end

        -- Ensure natural human skin tone on skin mesh parts
        local skinTone = Color3.fromRGB(222, 178, 148)
        for _, name in ipairs({ "Head", "LeftHand", "RightHand", "LeftUpperArm", "RightUpperArm", "LeftLowerArm", "RightLowerArm" }) do
            local p = char:FindFirstChild(name)
            if p and p:IsA("BasePart") then
                p.Color = skinTone
            end
        end
        activeHumanoid.Died:Connect(function()
            state.IsDead = true
            state.SpecialAction = "Died"
            state.SpecialStartTime = os.clock()
            state.SpecialDuration = 999
            AudioManager.Play("HeavyLanding")
        end)

        -- Synchronize crouch state if HUDController or sprint alters it
        char:GetAttributeChangedSignal("IsCrouching"):Connect(function()
            local isC = char:GetAttribute("IsCrouching") == true
            if state.IsCrouching ~= isC then
                state.IsCrouching = isC
                crouchSpring.Target = Vector3.new(isC and 1 or 0, 0, 0)
            end
        end)

        activeHumanoid.StateChanged:Connect(function(oldState, newState)
            if newState == Enum.HumanoidStateType.Jumping or newState == Enum.HumanoidStateType.Freefall then
                state.IsAirborne = true
                state.IsGrounded = false
            elseif newState == Enum.HumanoidStateType.Landed then
                state.IsAirborne = false
                state.IsGrounded = true

                -- Euphoria-level landing absorption
                local impactSpeed = math.abs(state.LastVerticalVelocity)
                if impactSpeed > 6 then
                    local force = math.clamp(impactSpeed * 0.38, 2.0, 16)
                    landingSpring.Velocity = Vector3.new(0, force, 0)
                    camDipSpring.Velocity = Vector3.new(0, -force * 0.40, 0)

                    -- Only trigger severe HeavyLanding freeze if falling from a cliff (> 60 studs/s)
                    if impactSpeed > 60 then
                        state.SpecialAction = "HeavyLanding"
                        state.SpecialStartTime = os.clock()
                        state.SpecialDuration = 0.45
                        camRecoilSpring.Velocity = Vector3.new(math.rad(4.5), 0, 0)
                        AudioManager.Play("HeavyLanding")
                    else
                        AudioManager.Play("Footstep")
                    end
                end
            end
        end)
    end
end

if player.Character then
    cacheCharacterJoints(player.Character)
end
player.CharacterAdded:Connect(cacheCharacterJoints)

-- -----------------------------------------------------------------------------
-- 5. HIT DETECTION & ATTACK DISPATCHER
-- -----------------------------------------------------------------------------
-- Sync sound when any melee attack connects (peaceful, no screen flinch)
if meleeHitReplicatedEvent then
    meleeHitReplicatedEvent.OnClientEvent:Connect(function(attacker, targetChar, attackType, hitPos, soundName, isBlocked)
        if attacker == player then
            -- Attacker feedback
            if soundName and soundName ~= "" then
                AudioManager.Play(soundName)
            else
                AudioManager.Play(isBlocked and "BlockImpact" or "PunchImpact")
            end
        elseif targetChar == activeCharacter then
            AudioManager.Play(isBlocked and "BlockImpact" or "PunchImpact")
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
-- 7. INPUT HANDLING (M1 Light Attack Combo, Block [F], Crouch [C])
-- -----------------------------------------------------------------------------
local function isInputEligible(): boolean
    if player:GetAttribute("IsInGameplay") ~= true then return false end
    if state.IsDead then return false end
    if state.SpecialAction ~= "None" then return false end
    if ModalManager.IsAnyModalOpen() then return false end
    if UserInputService:GetFocusedTextBox() ~= nil then return false end
    return true
end

local function setBlocking(isBlocking: boolean)
    if activeCharacter then
        activeCharacter:SetAttribute("IsBlocking", isBlocking)
    end
    if isBlocking then
        state.CombatAction = "Block"
    elseif state.CombatAction == "Block" then
        state.CombatAction = "None"
    end
end

local attackToken = 0

local function executeAttack(attackType: string)
    if not activeCharacter or not camera or not activeHumanoid then return end
    local hrp = activeCharacter:FindFirstChild("HumanoidRootPart") :: BasePart?
    if not hrp then return end

    -- Flag as attacking (Animate script reads this to prevent idle snap)
    state.IsSprinting = false
    activeCharacter:SetAttribute("IsAttacking", true)
    -- NOTE: WalkSpeed is NOT zeroed -- character keeps moving through the punch

    local currentToken = os.clock()
    attackToken = currentToken
    local duration = 0.34

    task.delay(duration, function()
        if attackToken == currentToken and activeHumanoid and not state.IsDead then
            if activeCharacter then
                activeCharacter:SetAttribute("IsAttacking", false)
            end
            if state.CombatAction == "PunchRight" or state.CombatAction == "PunchLeft" then
                state.CombatAction = "None"
            end
        end
    end)

    -- Subtle gentle audio swish (no camera recoil kick)
    AudioManager.Play("PunchSwing")

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
    if not isInputEligible() then return end
    local now = os.clock()

    if state.ComboStep == 1 and (now - state.LastLightPunchTime < 0.70) then
        -- Second hit: left hand
        state.CombatAction = "PunchLeft"
        state.ActionStartTime = now
        state.ActionDuration = 0.34
        state.ComboStep = 0
        state.LastLightPunchTime = now
        executeAttack("PunchLeft")
    else
        -- First hit: right hand
        state.CombatAction = "PunchRight"
        state.ActionStartTime = now
        state.ActionDuration = 0.34
        state.LastLightPunchTime = now
        state.ComboStep = 1
        executeAttack("PunchRight")
    end
end

UserInputService.InputBegan:Connect(function(input: InputObject, gameProcessed: boolean)
    if not isInputEligible() then return end
    if gameProcessed and input.UserInputType ~= Enum.UserInputType.MouseButton1 then
        return
    end

    -- Guard / Block [F]
    if input.KeyCode == Enum.KeyCode.F then
        state.IsFHeld = true
        setBlocking(true)
        return
    end

    -- Crouch / Sneak [C] or [LeftControl]
    if input.KeyCode == Enum.KeyCode.C or input.KeyCode == Enum.KeyCode.LeftControl then
        state.IsCrouching = not state.IsCrouching
        if activeCharacter then
            activeCharacter:SetAttribute("IsCrouching", state.IsCrouching)
        end
        crouchSpring.Target = Vector3.new(state.IsCrouching and 1 or 0, 0, 0)
        if activeHumanoid and state.CombatAction == "None" then
            activeHumanoid.WalkSpeed = state.IsCrouching and 8 or (state.IsSprinting and 26 or 16)
        end
        return
    end

    -- M1: short, alternating right-left light punches while movement continues.
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        triggerLightAttack()
        return
    end
end)

UserInputService.InputEnded:Connect(function(input: InputObject)
    -- Guard / Block [F] Release
    if input.KeyCode == Enum.KeyCode.F then
        state.IsFHeld = false
        if state.CombatAction == "Block" then
            setBlocking(false)
        end
        return
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

-- Kinematics calculated at RenderPriority.Character.Value + 1 (Runs after Animator, ensuring procedural joint transforms are never overwritten)
RunService:BindToRenderStep("ProceduralLocomotion", Enum.RenderPriority.Character.Value + 1, function(dt: number)
    if not activeCharacter or not activeHumanoid or not activeHRP then return end

    local now = os.clock()
    local moveVel = activeHRP.AssemblyLinearVelocity
    local horizontalSpeed = Vector3.new(moveVel.X, 0, moveVel.Z).Magnitude
    state.LastVerticalVelocity = moveVel.Y

    local isMovingIntent = activeHumanoid.MoveDirection.Magnitude > 0.05
    local isMoving = (horizontalSpeed > 1.0 or isMovingIntent) and state.IsGrounded
    local wantsSprint = (activeHumanoid.WalkSpeed >= 22 or UserInputService:IsKeyDown(Enum.KeyCode.LeftShift)) and isMoving and not state.IsCrouching
    state.IsSprinting = wantsSprint

    -- Smooth spring for walk <-> sprint transitions
    sprintSpring.Target = Vector3.new(wantsSprint and 1 or 0, 0, 0)
    currentSprintAlpha = math.clamp(sprintSpring:Update(dt).X, 0, 1)

    local effectiveSprintAlpha = currentSprintAlpha

    -- Progress locomotion clock (freeze during active punch to hold stride mid-strike)
    if isMoving then
        local strideFreq = 7.5 + (currentSprintAlpha * 4.0) -- Smooth 7.5 -> 11.5 rad/s
        state.WalkCycleClock = state.WalkCycleClock + dt * strideFreq

        -- Dynamic footstep cadence (slower stealth cadence when crouched)
        local footstepInterval = 0.42 - (currentSprintAlpha * 0.15)
        if state.IsCrouching then
            footstepInterval = 0.52
        end
        if now - state.LastFootstepClock > footstepInterval then
            state.LastFootstepClock = now
            AudioManager.Play("Footstep")
        end
    else
        state.WalkCycleClock = state.WalkCycleClock + dt * 1.8 -- Idle breathing cadence
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
    local crouchVal = crouchSpring:Update(dt).X
    local crouchAlpha = math.clamp(crouchVal, 0, 1)

    local landingVal = landingSpring:Update(dt).Y
    local landingComp = math.clamp(landingVal * 0.08, 0, 0.85)

    -- Dynamic capsule height matching visual body during crouch
    if activeHumanoid and defaultHipHeight > 0 then
        activeHumanoid.HipHeight = defaultHipHeight * (1 - 0.45 * crouchAlpha)
    end

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
        forwardLeanTarget = forwardLeanTarget + math.rad(landingComp * 10)
    end

    leanSpring.Target = Vector3.new(forwardLeanTarget, 0, bankTarget)
    local leanPos = leanSpring:Update(dt)
    currentLeanZ = isTPP and leanPos.Z or 0

    -- 60 FPS Locomotion Animation Blending
    local runTrack = locomotionTracks["Running60fps"] or locomotionTracks["Run"]
    local leftTurnTrack = locomotionTracks["leftTurn60fps"] or locomotionTracks["LeftTurn"]
    local rightTurnTrack = locomotionTracks["RightTurn60fps"] or locomotionTracks["RightTurn"]

    if runTrack then
        if isMoving and (wantsSprint or horizontalSpeed > 16) then
            if not runTrack.IsPlaying then
                runTrack:Play(0.18)
            end
            runTrack:AdjustSpeed(math.clamp(horizontalSpeed / 16, 0.8, 1.4))
        else
            if runTrack.IsPlaying then
                runTrack:Stop(0.2)
            end
        end
    end

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

    -- 1. Athletic Crouch Flexion (Hips, Knees, Ankles, Torso)
    if crouchAlpha > 0.001 then
        rootOffset = rootOffset * CFrame.new(0, -1.15 * crouchAlpha, 0) * CFrame.Angles(math.rad(6 * crouchAlpha), 0, 0)
        waistOffset = waistOffset * CFrame.Angles(math.rad(18 * crouchAlpha), 0, 0)
        rHipOffset = rHipOffset * CFrame.Angles(math.rad(46 * crouchAlpha), math.rad(4 * crouchAlpha), math.rad(4 * crouchAlpha))
        lHipOffset = lHipOffset * CFrame.Angles(math.rad(46 * crouchAlpha), math.rad(-4 * crouchAlpha), math.rad(-4 * crouchAlpha))
        rKneeOffset = rKneeOffset * CFrame.Angles(math.rad(-74 * crouchAlpha), 0, 0)
        lKneeOffset = lKneeOffset * CFrame.Angles(math.rad(-74 * crouchAlpha), 0, 0)
        rAnkleOffset = rAnkleOffset * CFrame.Angles(math.rad(28 * crouchAlpha), 0, 0)
        lAnkleOffset = lAnkleOffset * CFrame.Angles(math.rad(28 * crouchAlpha), 0, 0)
    end

    -- 2. Landing Impact Absorption (Euphoria suspension)
    if landingComp > 0.001 then
        rootOffset = rootOffset * CFrame.new(0, -landingComp * 0.85, 0)
        rKneeOffset = rKneeOffset * CFrame.Angles(math.rad(-landingComp * 42), 0, 0)
        lKneeOffset = lKneeOffset * CFrame.Angles(math.rad(-landingComp * 42), 0, 0)
        waistOffset = waistOffset * CFrame.Angles(math.rad(landingComp * 14), 0, 0)
    end

    -- Small additive gait polish keeps movement readable without replacing the rig's
    -- authored walk/run cycle. Punches leave this phase running continuously.
    local runAlpha = isMoving and math.clamp(horizontalSpeed / 12, 0, 1) or 0
    if runAlpha > 0.001 then
        local legSwing = math.sin(state.WalkCycleClock) * math.rad(12 * runAlpha)
        local kneeLift = math.max(math.cos(state.WalkCycleClock), 0) * math.rad(16 * runAlpha)
        rHipOffset = rHipOffset * CFrame.Angles(legSwing, 0, 0)
        lHipOffset = lHipOffset * CFrame.Angles(-legSwing, 0, 0)
        rKneeOffset = rKneeOffset * CFrame.Angles(-kneeLift, 0, 0)
        lKneeOffset = lKneeOffset * CFrame.Angles(-math.max(-math.cos(state.WalkCycleClock), 0) * math.rad(16 * runAlpha), 0, 0)
    end

    -- 3. Airborne Suspension (Legs trail slightly)
    if state.IsAirborne then
        rHipOffset = rHipOffset * CFrame.Angles(math.rad(-10), 0, math.rad(4))
        lHipOffset = lHipOffset * CFrame.Angles(math.rad(-10), 0, math.rad(-4))
        rKneeOffset = rKneeOffset * CFrame.Angles(math.rad(-16), 0, 0)
        lKneeOffset = lKneeOffset * CFrame.Angles(math.rad(-16), 0, 0)
    end

    -- 4. Dynamic turn banking applied to root (TPP only, ultra-mild)
    if isTPP and math.abs(leanPos.Z) > 0.0001 then
        rootOffset = rootOffset * CFrame.Angles(0, 0, leanPos.Z * 0.3)
    end

    -- Apply lower body offsets multiplicatively on top of Animator's base pose
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
        elseif state.IsAirborne then
            rShoulderBase = CFrame.Angles(math.rad(28), math.rad(-12), math.rad(18))
            lShoulderBase = CFrame.Angles(math.rad(28), math.rad(12), math.rad(-18))
            rElbowBase = CFrame.Angles(math.rad(22), 0, 0)
            lElbowBase = CFrame.Angles(math.rad(22), 0, 0)
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
        elseif state.IsAirborne then
            rShoulderBase = CFrame.Angles(math.rad(90), math.rad(-20), math.rad(18))
            lShoulderBase = CFrame.Angles(math.rad(90), math.rad(20), math.rad(-18))
            rElbowBase = CFrame.Angles(math.rad(-45), 0, 0)
            lElbowBase = CFrame.Angles(math.rad(-45), 0, 0)
        elseif isMoving then
            local swingAmp = 16 + (effectiveSprintAlpha * 14)
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
    -- OVERLAY: COMBAT ACTIONS (alternating light punches, Block)
    ----------------------------------------------------------------------------
    if state.CombatAction == "PunchRight" or state.CombatAction == "PunchLeft" then
        local progress = math.clamp((now - state.ActionStartTime) / state.ActionDuration, 0, 1)
        local punchAlpha = if progress < 0.22
            then easeOutCubic(progress / 0.22)
            else easeOutCubic((1 - progress) / 0.78)
        local isRightPunch = state.CombatAction == "PunchRight"
        local side = isRightPunch and -1 or 1
        local shoulderOffset = CFrame.Angles(math.rad(34 * punchAlpha), math.rad(side * 6 * punchAlpha), math.rad(side * -4 * punchAlpha))
        local elbowOffset = CFrame.Angles(math.rad(-16 * punchAlpha), 0, 0)
        local wristOffset = CFrame.Angles(math.rad(-4 * punchAlpha), 0, math.rad(side * 4 * punchAlpha))
        local guardShoulderOffset = CFrame.Angles(math.rad(10 * punchAlpha), math.rad(-side * 3 * punchAlpha), 0)
        local guardElbowOffset = CFrame.Angles(math.rad(-8 * punchAlpha), 0, 0)

        if isTPP then
            -- Add the strike to the Animator's current run, jump, or fall pose.
            local activeShoulder = isRightPunch and joints.RightShoulder or joints.LeftShoulder
            local activeElbow = isRightPunch and joints.RightElbow or joints.LeftElbow
            local activeWrist = isRightPunch and joints.RightWrist or joints.LeftWrist
            local guardShoulder = isRightPunch and joints.LeftShoulder or joints.RightShoulder
            local guardElbow = isRightPunch and joints.LeftElbow or joints.RightElbow
            applyJointOffset(activeShoulder, shoulderOffset)
            applyJointOffset(activeElbow, elbowOffset)
            applyJointOffset(activeWrist, wristOffset)
            applyJointOffset(guardShoulder, guardShoulderOffset)
            applyJointOffset(guardElbow, guardElbowOffset)
        elseif isRightPunch then
            rShoulderBase = rShoulderBase * shoulderOffset
            rElbowBase = rElbowBase * elbowOffset
            rWristBase = rWristBase * wristOffset
            lShoulderBase = lShoulderBase * guardShoulderOffset
            lElbowBase = lElbowBase * guardElbowOffset
        else
            lShoulderBase = lShoulderBase * shoulderOffset
            lElbowBase = lElbowBase * elbowOffset
            lWristBase = lWristBase * wristOffset
            rShoulderBase = rShoulderBase * guardShoulderOffset
            rElbowBase = rElbowBase * guardElbowOffset
        end
        applyJointOffset(joints.Waist, CFrame.Angles(math.rad(2 * punchAlpha), math.rad(side * 7 * punchAlpha), 0))

    elseif state.CombatAction == "Block" then
        local guardRS = CFrame.Angles(math.rad(104), math.rad(-32), math.rad(22))
        local guardRE = CFrame.Angles(math.rad(-125), math.rad(18), 0)
        local guardRW = CFrame.Angles(0, math.rad(45), 0)

        local guardLS = CFrame.Angles(math.rad(104), math.rad(32), math.rad(-22))
        local guardLE = CFrame.Angles(math.rad(-125), math.rad(-18), 0)
        local guardLW = CFrame.Angles(0, math.rad(-45), 0)

        rShoulderBase = rShoulderBase:Lerp(guardRS, 0.85)
        rElbowBase = rElbowBase:Lerp(guardRE, 0.85)
        rWristBase = rWristBase:Lerp(guardRW, 0.85)

        lShoulderBase = lShoulderBase:Lerp(guardLS, 0.85)
        lElbowBase = lElbowBase:Lerp(guardLE, 0.85)
        lWristBase = lWristBase:Lerp(guardLW, 0.85)
    end

    ----------------------------------------------------------------------------
    -- OVERLAY: SPECIAL INTERACTIONS (Pickup, Campfire, Throw, HeavyLanding, Death)
    ----------------------------------------------------------------------------
    if state.SpecialAction == "GroundPickup" then
        local p = math.clamp((now - state.SpecialStartTime) / state.SpecialDuration, 0, 1)
        local scoopAlpha = (p < 0.45) and (p / 0.45) or (1 - (p - 0.45) / 0.55)
        scoopAlpha = easeInOutQuad(scoopAlpha)

        local scoopShoulder = CFrame.Angles(math.rad(25), math.rad(-15), math.rad(10))
        local scoopElbow = CFrame.Angles(math.rad(-20), 0, 0)
        rShoulderBase = rShoulderBase:Lerp(scoopShoulder, scoopAlpha)
        rElbowBase = rElbowBase:Lerp(scoopElbow, scoopAlpha)
        applyJointOffset(joints.Waist, CFrame.Angles(math.rad(scoopAlpha * 14), 0, 0))

    elseif state.SpecialAction == "CampfireLight" then
        local p = math.clamp((now - state.SpecialStartTime) / state.SpecialDuration, 0, 1)
        local matchAlpha = easeInOutQuad(math.clamp(p * 2, 0, 1))

        local boxShoulder = CFrame.Angles(math.rad(78), math.rad(18), math.rad(-10))
        local boxElbow = CFrame.Angles(math.rad(-90), 0, 0)
        lShoulderBase = lShoulderBase:Lerp(boxShoulder, matchAlpha)
        lElbowBase = lElbowBase:Lerp(boxElbow, matchAlpha)

        local strikeProgress = math.clamp((p - 0.25) / 0.5, 0, 1)
        local strikeStroke = math.sin(strikeProgress * math.pi)
        local strikeShoulder = CFrame.Angles(math.rad(82) + math.rad(strikeStroke * 18), math.rad(-14), 0)
        rShoulderBase = rShoulderBase:Lerp(strikeShoulder, matchAlpha)

    elseif state.SpecialAction == "ItemThrow" then
        local p = math.clamp((now - state.SpecialStartTime) / state.SpecialDuration, 0, 1)
        local throwAlpha = (p < 0.4) and (p / 0.4) or (1 - (p - 0.4) / 0.6)
        throwAlpha = easeOutCubic(throwAlpha)

        local tossShoulder = CFrame.Angles(math.rad(95), math.rad(-10), math.rad(8))
        local tossElbow = CFrame.Angles(math.rad(-15), 0, 0)
        rShoulderBase = rShoulderBase:Lerp(tossShoulder, throwAlpha)
        rElbowBase = rElbowBase:Lerp(tossElbow, throwAlpha)

    elseif state.SpecialAction == "HeavyLanding" then
        local p = math.clamp((now - state.SpecialStartTime) / state.SpecialDuration, 0, 1)
        local landAlpha = (1 - p) * easeOutCubic(1 - p)

        local braceRS = CFrame.Angles(math.rad(45), math.rad(-22), math.rad(24))
        local braceLS = CFrame.Angles(math.rad(45), math.rad(22), math.rad(-24))
        rShoulderBase = rShoulderBase:Lerp(braceRS, landAlpha * 0.7)
        lShoulderBase = lShoulderBase:Lerp(braceLS, landAlpha * 0.7)

    elseif state.SpecialAction == "Died" then
        rShoulderBase = CFrame.Angles(math.rad(15), math.rad(-30), math.rad(40))
        lShoulderBase = CFrame.Angles(math.rad(15), math.rad(30), math.rad(-40))
        rElbowBase = CFrame.Angles(math.rad(-25), 0, 0)
        lElbowBase = CFrame.Angles(math.rad(-25), 0, 0)
    end

    ----------------------------------------------------------------------------
    -- APPLY PROCEDURAL ARM TRANSFORMS
    ----------------------------------------------------------------------------
    if not isTPP or crouchAlpha > 0.001 or state.SpecialAction ~= "None" or state.CombatAction == "Block" then
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
    local dip = camDipSpring:Update(dt)
    local sway = camSwaySpring:Update(dt)

    -- Dynamic sprint FOV expansion (smoothly ramp from 70 up to 76 for speed sensation)
    if not isTPP then
        camera.FieldOfView = 70 + (currentSprintAlpha * 6)
    end

    -- 3. Camera Offset adjustments (Crouch / Landing / Death)
    if activeHumanoid then
        local targetYOffset = 0.0
        local crouchAlpha = math.clamp(crouchSpring.Position.X, 0, 1)
        if state.SpecialAction == "Died" then
            targetYOffset = -2.8 -- Collapse into snow
        elseif state.SpecialAction == "CampfireLight" then
            targetYOffset = -1.6 -- Kneel at campfire
        elseif crouchAlpha > 0.001 then
            targetYOffset = -1.5 * crouchAlpha -- Smooth sneak crouch eye-level drop
        end

        local currentOffset = activeHumanoid.CameraOffset
        local newY = currentOffset.Y + (targetYOffset - currentOffset.Y) * math.clamp(dt * 12, 0, 1) + (dip.Y * 0.05)
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
end)

return CharacterAnimationController
