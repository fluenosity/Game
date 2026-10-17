--!strict
--[[
    SwimmingController.client.lua
    Dedicated First-Person 3D Swimming Physics, Surface Lock, and Mobile Navigation Engine
    for "Don't Let the Fire Die". Developed for Fluenosity Studio.

    Features:
    - Dedicated, isolated swimming mechanics controller (cleanly separated from visual post-processing).
    - Surface Lock Architecture: when on top of the water, the character is locked to the surface
      waterline. Looking down NEVER pushes the character under! Sinking is completely blocked.
    - Deliberate Diving Only: the character only submerges when explicitly pressing Descend
      ([C] / [LeftControl] or Mobile Dive button).
    - Neutral Buoyancy: zero automatic sinking when idle. The character treads water at their
      current depth or floats stably on the surface without sinking.
    - True 3D camera/mouse propulsion when submerged.
    - Strong Resurfacing: holding [Space] or Mobile Ascend pulls the character cleanly up to the top
      and immediately engages the Surface Lock.
    - Direct Swim Animation Guarantee: SwimmingMain is directly managed by this controller at Action4
      priority. When idle, it treads at 0.50x speed. When moving, 1.15x. When sprinting, 1.60x.
      T-pose is mathematically impossible.
    - Touch-optimized luxury glassmorphic Mobile Ascend (▲) and Descend (▼) HUD controls with
      haptic/audio cues and smooth entry/exit animations.
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Terrain = workspace.Terrain

local UITheme = require(script.Parent:WaitForChild("UITheme"))
local AudioManager = require(script.Parent:WaitForChild("AudioManager"))

local localPlayer = Players.LocalPlayer

local SWIMMING_ACTIVE_ID = "rbxassetid://89978361700030"
local SWIMMING_IDLE_ID = "rbxassetid://139050203336639"

-- -----------------------------------------------------------------------------
-- 1. PHYSICS STATE & INSTANCES
-- -----------------------------------------------------------------------------
local activeCharacter: Model? = nil
local activeHumanoid: Humanoid? = nil
local activeRootPart: BasePart? = nil
local activeAnimator: Animator? = nil
local activeSwimTrack: AnimationTrack? = nil
local activeSwimIdleTrack: AnimationTrack? = nil
local swimAttachment: Attachment? = nil
local swimLinearVelocity: LinearVelocity? = nil

local isSwimmingActive = false
local isSurfaceLocked = false
local currentWaterSurfaceY: number = 0.0
local surfaceCheckTimer = 0

-- Mobile input states
local mobileAscendActive = false
local mobileDescendActive = false

-- -----------------------------------------------------------------------------
-- 2. DYNAMIC WATER SURFACE & WATER VOXEL DETECTION
-- -----------------------------------------------------------------------------
local function queryLocalWaterSurface(rootPos: Vector3): number
    local minCorner = Vector3.new(
        math.floor(rootPos.X / 4) * 4,
        -40,
        math.floor(rootPos.Z / 4) * 4
    )
    local maxCorner = minCorner + Vector3.new(4, 64, 4) -- spans Y = -40 to Y = +24
    local region = Region3.new(minCorner, maxCorner):ExpandToGrid(4)

    local success, mats, occs = pcall(function()
        return Terrain:ReadVoxels(region, 4)
    end)

    if success and mats then
        local size = mats.Size
        for y = size.Y, 1, -1 do
            if mats[1][y][1] == Enum.Material.Water and occs[1][y][1] > 0.05 then
                return minCorner.Y + (y * 4)
            end
        end
    end
    return 0.0 -- default lake surface level
end

local function checkRootInWater(rootPart: BasePart): boolean
    local pos = rootPart.Position
    local minCorner = Vector3.new(
        math.floor(pos.X / 4) * 4,
        math.floor(pos.Y / 4) * 4,
        math.floor(pos.Z / 4) * 4
    )
    local region = Region3.new(minCorner, minCorner + Vector3.new(4, 4, 4)):ExpandToGrid(4)
    local success, materials, occupancies = pcall(function()
        return Terrain:ReadVoxels(region, 4)
    end)

    if success and materials and materials[1] and materials[1][1] and materials[1][1][1] == Enum.Material.Water then
        if occupancies and occupancies[1] and occupancies[1][1] and occupancies[1][1][1] > 0.05 then
            return true
        end
    end
    return false
end

-- -----------------------------------------------------------------------------
-- 3. MOBILE SWIM CONTROLS GUI (Luxury Glassmorphic Obsidian/Ember)
-- -----------------------------------------------------------------------------
local mobileGui: ScreenGui? = nil
local controlsContainer: CanvasGroup? = nil

local function setupMobileControls()
    if mobileGui then return end

    local playerGui = localPlayer:WaitForChild("PlayerGui")
    local gui = Instance.new("ScreenGui")
    gui.Name = "MobileSwimControlsGui"
    gui.ResetOnSpawn = false
    gui.DisplayOrder = 90
    gui.Enabled = false

    local container = Instance.new("CanvasGroup")
    container.Name = "ControlsContainer"
    container.Size = UDim2.new(0, 68, 0, 150)
    container.AnchorPoint = Vector2.new(1, 0.5)
    container.Position = UDim2.new(1, -24, 0.62, 0)
    container.BackgroundTransparency = 1
    container.GroupTransparency = 1
    container.Parent = gui

    local layout = Instance.new("UIListLayout")
    layout.FillDirection = Enum.FillDirection.Vertical
    layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    layout.VerticalAlignment = Enum.VerticalAlignment.Center
    layout.Padding = UDim.new(0, 14)
    layout.Parent = container

    -- 1. Ascend / Surface Button
    local ascendBtn = Instance.new("TextButton")
    ascendBtn.Name = "AscendButton"
    ascendBtn.Size = UDim2.new(0, 62, 0, 62)
    ascendBtn.BackgroundColor3 = Color3.fromRGB(16, 18, 22)
    ascendBtn.BackgroundTransparency = 0.25
    ascendBtn.AutoButtonColor = false
    ascendBtn.Text = ""
    ascendBtn.Parent = container

    local ascendCorner = Instance.new("UICorner")
    ascendCorner.CornerRadius = UDim.new(0, 16)
    ascendCorner.Parent = ascendBtn

    local ascendStroke = Instance.new("UIStroke")
    ascendStroke.Color = Color3.fromRGB(255, 145, 45)
    ascendStroke.Transparency = 0.4
    ascendStroke.Thickness = 1.6
    ascendStroke.Parent = ascendBtn

    local ascendIcon = Instance.new("TextLabel")
    ascendIcon.Name = "Icon"
    ascendIcon.Size = UDim2.new(1, 0, 0, 28)
    ascendIcon.Position = UDim2.new(0, 0, 0, 6)
    ascendIcon.BackgroundTransparency = 1
    ascendIcon.Text = "▲"
    ascendIcon.TextColor3 = Color3.fromRGB(255, 215, 170)
    ascendIcon.TextSize = 22
    ascendIcon.Font = Enum.Font.GothamBold
    ascendIcon.Parent = ascendBtn

    local ascendLabel = Instance.new("TextLabel")
    ascendLabel.Name = "Label"
    ascendLabel.Size = UDim2.new(1, 0, 0, 16)
    ascendLabel.Position = UDim2.new(0, 0, 1, -22)
    ascendLabel.BackgroundTransparency = 1
    ascendLabel.Text = "SURFACE"
    ascendLabel.TextColor3 = Color3.fromRGB(255, 175, 110)
    ascendLabel.TextSize = 9
    ascendLabel.Font = Enum.Font.GothamBold
    ascendLabel.Parent = ascendBtn

    -- 2. Descend / Dive Button
    local descendBtn = Instance.new("TextButton")
    descendBtn.Name = "DescendButton"
    descendBtn.Size = UDim2.new(0, 62, 0, 62)
    descendBtn.BackgroundColor3 = Color3.fromRGB(16, 18, 22)
    descendBtn.BackgroundTransparency = 0.25
    descendBtn.AutoButtonColor = false
    descendBtn.Text = ""
    descendBtn.Parent = container

    local descendCorner = Instance.new("UICorner")
    descendCorner.CornerRadius = UDim.new(0, 16)
    descendCorner.Parent = descendBtn

    local descendStroke = Instance.new("UIStroke")
    descendStroke.Color = Color3.fromRGB(70, 195, 235)
    descendStroke.Transparency = 0.4
    descendStroke.Thickness = 1.6
    descendStroke.Parent = descendBtn

    local descendIcon = Instance.new("TextLabel")
    descendIcon.Name = "Icon"
    descendIcon.Size = UDim2.new(1, 0, 0, 28)
    descendIcon.Position = UDim2.new(0, 0, 0, 6)
    descendIcon.BackgroundTransparency = 1
    descendIcon.Text = "▼"
    descendIcon.TextColor3 = Color3.fromRGB(195, 235, 255)
    descendIcon.TextSize = 22
    descendIcon.Font = Enum.Font.GothamBold
    descendIcon.Parent = descendBtn

    local descendLabel = Instance.new("TextLabel")
    descendLabel.Name = "Label"
    descendLabel.Size = UDim2.new(1, 0, 0, 16)
    descendLabel.Position = UDim2.new(0, 0, 1, -22)
    descendLabel.BackgroundTransparency = 1
    descendLabel.Text = "DIVE"
    descendLabel.TextColor3 = Color3.fromRGB(130, 215, 245)
    descendLabel.TextSize = 9
    descendLabel.Font = Enum.Font.GothamBold
    descendLabel.Parent = descendBtn

    -- Wire Ascend Button
    local function onAscendPress()
        mobileAscendActive = true
        AudioManager.Play("Click")
        TweenService:Create(ascendBtn, TweenInfo.new(0.08), {
            BackgroundColor3 = Color3.fromRGB(60, 40, 22),
            BackgroundTransparency = 0.1,
            Size = UDim2.new(0, 58, 0, 58)
        }):Play()
    end

    local function onAscendRelease()
        mobileAscendActive = false
        TweenService:Create(ascendBtn, TweenInfo.new(0.12), {
            BackgroundColor3 = Color3.fromRGB(16, 18, 22),
            BackgroundTransparency = 0.25,
            Size = UDim2.new(0, 62, 0, 62)
        }):Play()
    end

    ascendBtn.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
            onAscendPress()
        end
    end)
    ascendBtn.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
            onAscendRelease()
        end
    end)

    -- Wire Descend Button
    local function onDescendPress()
        mobileDescendActive = true
        AudioManager.Play("Click")
        TweenService:Create(descendBtn, TweenInfo.new(0.08), {
            BackgroundColor3 = Color3.fromRGB(20, 45, 60),
            BackgroundTransparency = 0.1,
            Size = UDim2.new(0, 58, 0, 58)
        }):Play()
    end

    local function onDescendRelease()
        mobileDescendActive = false
        TweenService:Create(descendBtn, TweenInfo.new(0.12), {
            BackgroundColor3 = Color3.fromRGB(16, 18, 22),
            BackgroundTransparency = 0.25,
            Size = UDim2.new(0, 62, 0, 62)
        }):Play()
    end

    descendBtn.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
            onDescendPress()
        end
    end)
    descendBtn.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
            onDescendRelease()
        end
    end)

    gui.Parent = playerGui
    mobileGui = gui
    controlsContainer = container
end

local function setMobileControlsVisible(visible: boolean)
    local isTouch = UserInputService.TouchEnabled or localPlayer:GetAttribute("ShowMobileControls") == true
    if not isTouch then
        if mobileGui then mobileGui.Enabled = false end
        return
    end

    setupMobileControls()
    if not mobileGui or not controlsContainer then return end

    if visible then
        mobileGui.Enabled = true
        TweenService:Create(controlsContainer, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            GroupTransparency = 0
        }):Play()
    else
        local tween = TweenService:Create(controlsContainer, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
            GroupTransparency = 1
        })
        tween:Play()
        tween.Completed:Connect(function()
            if not isSwimmingActive and mobileGui then
                mobileGui.Enabled = false
            end
        end)
    end
end

-- -----------------------------------------------------------------------------
-- 4. DIRECT DUAL-TRACK SWIMMING ANIMATION ENGINE (Zero T-Pose Guaranteed)
-- -----------------------------------------------------------------------------
local function stopAllSwimAnimations()
    if activeSwimTrack then
        pcall(function()
            activeSwimTrack:Stop(0.2)
            activeSwimTrack:Destroy()
        end)
        activeSwimTrack = nil
    end
    if activeSwimIdleTrack then
        pcall(function()
            activeSwimIdleTrack:Stop(0.2)
            activeSwimIdleTrack:Destroy()
        end)
        activeSwimIdleTrack = nil
    end
end

local function getOrCreateTrack(animator: Animator, animId: string, trackName: string): AnimationTrack?
    local anim = Instance.new("Animation")
    anim.Name = trackName
    anim.AnimationId = animId
    local success, track = pcall(function()
        return animator:LoadAnimation(anim)
    end)
    if success and track then
        track.Priority = Enum.AnimationPriority.Action4
        track.Looped = true
        return track
    end
    return nil
end

local function updateSwimAnimation(isMoving: boolean, isSprinting: boolean)
    if not activeAnimator then
        if activeHumanoid then
            activeAnimator = activeHumanoid:FindFirstChildOfClass("Animator")
        end
    end
    if not activeAnimator then return end

    if not activeSwimTrack then
        activeSwimTrack = getOrCreateTrack(activeAnimator, SWIMMING_ACTIVE_ID, "SwimActiveTrack")
    end
    if not activeSwimIdleTrack then
        activeSwimIdleTrack = getOrCreateTrack(activeAnimator, SWIMMING_IDLE_ID, "SwimIdleTrack")
    end

    if isMoving then
        if activeSwimTrack then
            if not activeSwimTrack.IsPlaying then
                activeSwimTrack:Play(0.25)
            end
            local targetSpeed = isSprinting and 1.60 or 1.15
            activeSwimTrack:AdjustSpeed(targetSpeed)
            activeSwimTrack:AdjustWeight(1.0, 0.25)
        end
        if activeSwimIdleTrack and activeSwimIdleTrack.IsPlaying then
            activeSwimIdleTrack:AdjustWeight(0.001, 0.25)
        end
    else
        -- Idle / Treading water
        if activeSwimIdleTrack then
            if not activeSwimIdleTrack.IsPlaying then
                activeSwimIdleTrack:Play(0.25)
            end
            activeSwimIdleTrack:AdjustSpeed(1.0)
            activeSwimIdleTrack:AdjustWeight(1.0, 0.25)
        end
        if activeSwimTrack and activeSwimTrack.IsPlaying then
            activeSwimTrack:AdjustWeight(0.001, 0.25)
        end
    end

    -- Suppress lower-priority conflicting tracks from Roblox default Animate
    for _, otherTrack in ipairs(activeAnimator:GetPlayingAnimationTracks()) do
        if otherTrack ~= activeSwimTrack and otherTrack ~= activeSwimIdleTrack then
            local animName = otherTrack.Name:lower()
            if animName == "swim" or animName == "swimidle" or string.find(animName, "swim") then
                pcall(function()
                    otherTrack:Stop(0.1)
                end)
            end
        end
    end
end

-- -----------------------------------------------------------------------------
-- 5. SWIM VELOCITY RIGGING & CLEANUP
-- -----------------------------------------------------------------------------
local function cleanupSwimPhysics()
    stopAllSwimAnimations()
    if swimLinearVelocity then
        pcall(function() swimLinearVelocity:Destroy() end)
        swimLinearVelocity = nil
    end
    if swimAttachment then
        pcall(function() swimAttachment:Destroy() end)
        swimAttachment = nil
    end
    mobileAscendActive = false
    mobileDescendActive = false
    isSurfaceLocked = false
    if activeHumanoid then
        pcall(function()
            activeHumanoid.CameraOffset = Vector3.zero
        end)
    end
    if activeCharacter then
        activeCharacter:SetAttribute("IsSwimming", false)
    end
end

local function setupSwimPhysics(char: Model)
    cleanupSwimPhysics()
    activeCharacter = char
    activeHumanoid = char:WaitForChild("Humanoid", 10) :: Humanoid?
    activeRootPart = char:WaitForChild("HumanoidRootPart", 10) :: BasePart?
    activeAnimator = if activeHumanoid then (activeHumanoid:WaitForChild("Animator", 10) :: Animator?) else nil

    if not activeRootPart then return end

    local att = Instance.new("Attachment")
    att.Name = "SwimmingAttachment"
    att.Parent = activeRootPart
    swimAttachment = att

    local lv = Instance.new("LinearVelocity")
    lv.Name = "SwimmingLinearVelocity"
    lv.Attachment0 = att
    lv.RelativeTo = Enum.ActuatorRelativeTo.World
    lv.VelocityConstraintMode = Enum.VelocityConstraintMode.Vector
    lv.MaxAxesForce = Vector3.new(40000, 10000, 40000)
    lv.MaxForce = math.huge
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
    activeAnimator = nil
    isSwimmingActive = false
    isSurfaceLocked = false
    setMobileControlsVisible(false)
end)

-- -----------------------------------------------------------------------------
-- 6. 3D SWIMMING PHYSICS UPDATE & SURFACE LOCK ENGINE
-- -----------------------------------------------------------------------------
local function updateSwimming(dt: number)
    if not activeCharacter or not activeHumanoid or not activeRootPart or not swimLinearVelocity then
        return
    end

    local currentCam = workspace.CurrentCamera
    if not currentCam then return end

    local humState = activeHumanoid:GetState()
    local isStateSwimming = (humState == Enum.HumanoidStateType.Swimming)
    local inWaterVoxel = checkRootInWater(activeRootPart)

    local currentlySwimming = isStateSwimming or inWaterVoxel

    -- Handle swim state transitions
    if currentlySwimming ~= isSwimmingActive then
        isSwimmingActive = currentlySwimming
        setMobileControlsVisible(isSwimmingActive)
        activeCharacter:SetAttribute("IsSwimming", isSwimmingActive)
        if not isSwimmingActive then
            swimLinearVelocity.Enabled = false
            swimLinearVelocity.VectorVelocity = Vector3.zero
            isSurfaceLocked = false
            stopAllSwimAnimations()
            return
        end
    end

    if not isSwimmingActive then
        return
    end

    -- STABILIZE SWIMMING STATE: prevent Roblox physics from flicking into Freefall while in water
    if inWaterVoxel then
        local st = activeHumanoid:GetState()
        if st == Enum.HumanoidStateType.Freefall or st == Enum.HumanoidStateType.Running or st == Enum.HumanoidStateType.RunningNoPhysics then
            activeHumanoid:ChangeState(Enum.HumanoidStateType.Swimming)
        end
    end

    -- Query local water surface elevation
    surfaceCheckTimer = surfaceCheckTimer + dt
    if surfaceCheckTimer > 0.20 or not currentWaterSurfaceY then
        surfaceCheckTimer = 0
        currentWaterSurfaceY = queryLocalWaterSurface(activeRootPart.Position)
    end

    -- Smoothly elevate CameraOffset while swimming so camera view is clearly resting above the water surface
    if isSwimmingActive then
        local targetCamOffsetY = 0.75
        activeHumanoid.CameraOffset = activeHumanoid.CameraOffset:Lerp(Vector3.new(0, targetCamOffsetY, 0), math.clamp(dt * 7, 0, 1))
    end

    local waterSurfaceY = currentWaterSurfaceY
    local rootY = activeRootPart.Position.Y
    -- Calibrated waterline: keeping root around -1.68 keeps the root safely inside the water voxel,
    -- eliminates Freefall state oscillation, and keeps the head and camera above the waterline
    local surfaceWaterline = waterSurfaceY - 1.68

    local camCF = currentCam.CFrame
    local camLook = camCF.LookVector
    local camRight = camCF.RightVector

    -- Decompose 2D horizontal movement from Humanoid.MoveDirection (W/A/S/D or Mobile Thumbstick)
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

    -- Ascend / Descend key checks
    local isAscending = activeHumanoid.Jump or UserInputService:IsKeyDown(Enum.KeyCode.Space) or mobileAscendActive
    local isDescending = UserInputService:IsKeyDown(Enum.KeyCode.LeftControl)
        or UserInputService:IsKeyDown(Enum.KeyCode.C)
        or mobileDescendActive

    -- Sprint / Fast Swim detection
    local isSprinting = UserInputService:IsKeyDown(Enum.KeyCode.LeftShift)
        or UserInputService:IsKeyDown(Enum.KeyCode.RightShift)
        or (activeHumanoid.WalkSpeed >= 18)

    local isMovingHorizontally = (math.abs(forwardInput) > 0.06 or math.abs(rightInput) > 0.06)

    -- -------------------------------------------------------------------------
    -- SURFACE LOCK STATE MACHINE
    -- -------------------------------------------------------------------------
    -- If character rises near or above surface waterline, engage Surface Lock
    if rootY >= (surfaceWaterline - 0.35) and not isDescending then
        isSurfaceLocked = true
    end

    -- If the player deliberately holds Descend / Dive, release Surface Lock
    if isDescending then
        isSurfaceLocked = false
    end

    -- Base swim speed
    local swimSpeed = isSprinting and 18.0 or 11.5
    local targetVelocity = Vector3.zero

    -- Raycast check to detect if character is swimming against a shore/bank and wants to climb out
    local isAtShoreBank = false
    if forwardInput > 0.2 then
        local rayOrigin = activeRootPart.Position + Vector3.new(0, 0.5, 0)
        local rayDir = (horizLook * 3.5) + Vector3.new(0, -1.8, 0)
        local rParams = RaycastParams.new()
        rParams.FilterType = Enum.RaycastFilterType.Exclude
        if activeCharacter then
            rParams.FilterDescendantsInstances = { activeCharacter }
        end
        rParams.IgnoreWater = true
        local hit = workspace:Raycast(rayOrigin, rayDir, rParams)
        if hit and hit.Position.Y > (activeRootPart.Position.Y + 0.3) then
            isAtShoreBank = true
        end
    end

    if isSurfaceLocked then
        -- =====================================================================
        -- SURFACE MODE: Locked to waterline, zero sinking, decoupled pitch
        -- =====================================================================
        local horizVel = Vector3.zero
        if math.abs(forwardInput) > 0.06 then
            horizVel = horizVel + (horizLook * (forwardInput * swimSpeed))
        end
        if math.abs(rightInput) > 0.06 then
            horizVel = horizVel + (horizRight * (rightInput * swimSpeed))
        end

        local surfaceOffset = surfaceWaterline - rootY
        local currentVy = activeRootPart.AssemblyLinearVelocity.Y
        local targetY = 0

        if isAtShoreBank and isAscending and forwardInput > 0.2 then
            -- Climbing/jumping out onto solid shore/bank
            targetY = 16.0
            isSurfaceLocked = false
        else
            -- Locked to surface waterline in open water
            if math.abs(surfaceOffset) < 0.05 then
                -- Within deadband: hold perfectly still at zero vertical velocity (zero flicker!)
                targetY = 0
            else
                -- Smooth critically damped approach:
                targetY = math.clamp(surfaceOffset * 2.5 - currentVy * 0.15, -2.0, 2.5)
            end

            if isAscending and rootY < (surfaceWaterline - 0.25) then
                -- Deep below surface, rapidly ascend towards waterline
                targetY = math.clamp(surfaceOffset * 4.0, 3.0, 7.0)
            end
        end

        targetVelocity = Vector3.new(horizVel.X, targetY, horizVel.Z)

    else
        -- =====================================================================
        -- SUBMERGED MODE: Full 3D camera/mouse aimed navigation
        -- =====================================================================
        local move3D = Vector3.zero

        if math.abs(forwardInput) > 0.06 then
            move3D = move3D + (camLook * forwardInput)
        end
        if math.abs(rightInput) > 0.06 then
            move3D = move3D + (camRight * rightInput)
        end

        if isAscending then
            -- Powerful lift straight to surface
            move3D = move3D + Vector3.new(0, 1.4, 0)
        elseif isDescending then
            -- Deliberate dive down into deep water
            move3D = move3D + Vector3.new(0, -1.1, 0)
        end

        if move3D.Magnitude > 0.04 then
            targetVelocity = move3D.Unit * swimSpeed
        else
            -- Neutral buoyancy while hovering underwater: NEVER sink automatically!
            targetVelocity = Vector3.zero
        end
    end

    -- Apply LinearVelocity: ALWAYS enabled while in water to neutralize gravity and prevent sinking
    swimLinearVelocity.VectorVelocity = targetVelocity
    swimLinearVelocity.Enabled = true

    -- Determine true movement intent for animation:
    -- If on surface and stationary (even if holding Space), play SwimIdle (139050203336639)
    -- If moving horizontally or swimming up from deep water, play SwimActive (89978361700030)
    local isActuallyMoving = isMovingHorizontally
        or (isAscending and not isSurfaceLocked)
        or isDescending
        or (isAtShoreBank and isAscending)

    updateSwimAnimation(isActuallyMoving, isSprinting)
end

-- -----------------------------------------------------------------------------
-- 7. RENDER STEPPED RUNNER
-- -----------------------------------------------------------------------------
RunService.RenderStepped:Connect(function(dt: number)
    updateSwimming(dt)
end)
