--!strict
--[[
    SittingController.client.lua
    Universal Dynamic Sitting, Directional Locking & Seated Freecam System for "Don't Let the Fire Die".
    Developed for Fluenosity Studio.

    Features:
    - Eliminates ugly Roblox default sit animation across all seats (campfires, logs, chairs, benches, vehicles).
    - Authentic 3-Phase Animation Pipeline:
        1. Stand to Sit: rbxassetid://84740804971115 (~2.23s natural lowering into seat)
        2. Sitting Idle: rbxassetid://111666571897686 (4.00s loop, relaxed seated breathing posture)
        3. Sit to Stand: rbxassetid://94330775048617 (~2.27s rising out of seat)
    - Strict Body Rotation Lock: Body stays 100% rigidly fixed in the seat's facing direction.
      Moving the camera/screen DOES NOT turn the character.
    - Decoupled Freecam Look: Player can look and orbit around freely while seated.
    - Walk, Jump & Footstep Audio Suppression: While seated, walk/jump are completely blocked
      and zero footstep audio can play.
    - Unified [E] Key Interaction:
        - Enter seat: [E] ProximityPrompt on the log bench
        - Leave seat: [E] key / ButtonX / On-screen luxury Glassmorphic button
    - Dynamic Movement-Cancel: Once unseating begins, pressing WASD seamlessly cancels the
      stand-up animation with a 0.1s crossfade into walking/running.
]]

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local ProximityPromptService = game:GetService("ProximityPromptService")

local localPlayer = Players.LocalPlayer

-- -----------------------------------------------------------------------------
-- 1. ANIMATION ASSET CONSTANTS & CALIBRATION
-- -----------------------------------------------------------------------------
local STAND_TO_SIT_ID = "rbxassetid://84740804971115"
local SIT_TO_STAND_ID = "rbxassetid://94330775048617"
local SEATED_HRP_OFFSET_Y = 1.415 -- Calibrated to align avatar hips directly with log surface bark

-- -----------------------------------------------------------------------------
-- 2. STATE & TRACK INSTANCES
-- -----------------------------------------------------------------------------
local activeCharacter: Model? = nil
local activeHumanoid: Humanoid? = nil
local activeRootPart: BasePart? = nil
local activeAnimator: Animator? = nil

local standToSitTrack: AnimationTrack? = nil
local sitToStandTrack: AnimationTrack? = nil

local isCurrentlySeated = false
local isStandingUp = false
local currentOccupiedSeat: (Seat | VehicleSeat)? = nil
local savedWalkSpeed = 6
local transitionToken = 0

local requestStandUp: (() -> ())? = nil

-- UI Reference
local promptGui: ScreenGui? = nil
local promptFrame: Frame? = nil

-- -----------------------------------------------------------------------------
-- 3. LUXURY GLASSMORHPIC STAND-UP PROMPT UI
-- -----------------------------------------------------------------------------
local function createStandPromptUI()
    if promptGui then return end

    local playerGui = localPlayer:WaitForChild("PlayerGui", 10)
    if not playerGui then return end

    promptGui = Instance.new("ScreenGui")
    promptGui.Name = "SeatedPromptGui"
    promptGui.ResetOnSpawn = false
    promptGui.DisplayOrder = 15
    promptGui.IgnoreGuiInset = true

    local frame = Instance.new("Frame")
    frame.Name = "StandPromptFrame"
    frame.Size = UDim2.new(0, 170, 0, 42)
    frame.Position = UDim2.new(0.5, -85, 0.86, 0)
    frame.BackgroundColor3 = Color3.fromRGB(15, 17, 21)
    frame.BackgroundTransparency = 1 -- Animate in
    frame.BorderSizePixel = 0
    frame.Visible = false

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 21)
    corner.Parent = frame

    local stroke = Instance.new("UIStroke")
    stroke.Name = "PromptStroke"
    stroke.Color = Color3.fromRGB(245, 158, 11)
    stroke.Transparency = 1
    stroke.Thickness = 1.2
    stroke.Parent = frame

    -- Subtle ember background gradient
    local gradient = Instance.new("UIGradient")
    gradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(24, 26, 32)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(13, 14, 18)),
    })
    gradient.Rotation = 90
    gradient.Parent = frame

    -- Keycap Badge [ E ]
    local keyBadge = Instance.new("Frame")
    keyBadge.Name = "KeyBadge"
    keyBadge.Size = UDim2.new(0, 28, 0, 28)
    keyBadge.Position = UDim2.new(0, 10, 0.5, -14)
    keyBadge.BackgroundColor3 = Color3.fromRGB(32, 35, 42)
    keyBadge.BorderSizePixel = 0
    keyBadge.Parent = frame

    local keyCorner = Instance.new("UICorner")
    keyCorner.CornerRadius = UDim.new(0, 7)
    keyCorner.Parent = keyBadge

    local keyStroke = Instance.new("UIStroke")
    keyStroke.Color = Color3.fromRGB(245, 158, 11)
    keyStroke.Transparency = 0.4
    keyStroke.Thickness = 1
    keyStroke.Parent = keyBadge

    local keyLabel = Instance.new("TextLabel")
    keyLabel.Name = "KeyLabel"
    keyLabel.Size = UDim2.new(1, 0, 1, 0)
    keyLabel.BackgroundTransparency = 1
    keyLabel.Font = Enum.Font.GothamBold
    keyLabel.Text = "E"
    keyLabel.TextColor3 = Color3.fromRGB(255, 230, 180)
    keyLabel.TextSize = 14
    keyLabel.Parent = keyBadge

    -- Action Text Label
    local actionLabel = Instance.new("TextLabel")
    actionLabel.Name = "ActionLabel"
    actionLabel.Size = UDim2.new(1, -50, 1, 0)
    actionLabel.Position = UDim2.new(0, 46, 0, 0)
    actionLabel.BackgroundTransparency = 1
    actionLabel.Font = Enum.Font.GothamMedium
    actionLabel.Text = "Stand Up"
    actionLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    actionLabel.TextSize = 13
    actionLabel.TextXAlignment = Enum.TextXAlignment.Left
    actionLabel.Parent = frame

    -- Interactive Click Button (Mobile / Mouse tap support)
    local clickBtn = Instance.new("TextButton")
    clickBtn.Name = "ClickButton"
    clickBtn.Size = UDim2.new(1, 0, 1, 0)
    clickBtn.BackgroundTransparency = 1
    clickBtn.Text = ""
    clickBtn.Parent = frame

    frame.Parent = promptGui
    promptFrame = frame
    promptGui.Parent = playerGui

    -- Forward declaration of stand up trigger
    clickBtn.MouseButton1Click:Connect(function()
        if isCurrentlySeated and not isStandingUp and requestStandUp then
            requestStandUp()
        end
    end)
end

local function showStandPrompt()
    createStandPromptUI()
    if not promptFrame then return end
    promptFrame.Visible = true

    local stroke = promptFrame:FindFirstChild("PromptStroke") :: UIStroke?
    local tweenInfo = TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

    TweenService:Create(promptFrame, tweenInfo, {
        BackgroundTransparency = 0.20,
        Position = UDim2.new(0.5, -85, 0.84, 0)
    }):Play()

    if stroke then
        TweenService:Create(stroke, tweenInfo, { Transparency = 0.45 }):Play()
    end
end

local function hideStandPrompt()
    if not promptFrame then return end
    promptFrame.Visible = false
end

-- -----------------------------------------------------------------------------
-- 4. TRACK FACTORY & SUPPRESSION
-- -----------------------------------------------------------------------------
local function getOrCreateTrack(animator: Animator, animId: string, trackName: string, looped: boolean): AnimationTrack?
    local anim = Instance.new("Animation")
    anim.Name = trackName
    anim.AnimationId = animId
    local success, track = pcall(function()
        return animator:LoadAnimation(anim)
    end)
    if success and track then
        track.Priority = Enum.AnimationPriority.Action4
        track.Looped = looped
        return track
    end
    return nil
end

local function stopTrack(track: AnimationTrack?, fadeTime: number)
    if track then
        pcall(function()
            track:Stop(fadeTime)
        end)
    end
end

local function suppressDefaultRobloxSit()
    if not activeAnimator then return end
    for _, track in ipairs(activeAnimator:GetPlayingAnimationTracks()) do
        if track ~= standToSitTrack and track ~= sittingIdleTrack and track ~= sitToStandTrack then
            local animName = track.Name:lower()
            if animName == "sit" or string.find(animName, "sit") then
                pcall(function()
                    track:Stop(0.05)
                end)
            end
        end
    end
end

-- -----------------------------------------------------------------------------
-- 5. STAND UP & SEAT TRANSITION LOGIC
-- -----------------------------------------------------------------------------
local function hasActiveMoveIntent(): boolean
    if not activeHumanoid then return false end
    if activeHumanoid.MoveDirection.Magnitude > 0.08 then
        return true
    end
    return UserInputService:IsKeyDown(Enum.KeyCode.W)
        or UserInputService:IsKeyDown(Enum.KeyCode.A)
        or UserInputService:IsKeyDown(Enum.KeyCode.S)
        or UserInputService:IsKeyDown(Enum.KeyCode.D)
        or UserInputService:IsKeyDown(Enum.KeyCode.Up)
        or UserInputService:IsKeyDown(Enum.KeyCode.Down)
        or UserInputService:IsKeyDown(Enum.KeyCode.Left)
        or UserInputService:IsKeyDown(Enum.KeyCode.Right)
end

requestStandUp = function()
    if not isCurrentlySeated or isStandingUp then return end
    isStandingUp = true
    transitionToken = transitionToken + 1
    local currentToken = transitionToken

    hideStandPrompt()

    if not activeAnimator and activeHumanoid then
        activeAnimator = activeHumanoid:FindFirstChildOfClass("Animator")
    end

    if not sitToStandTrack and activeAnimator then
        sitToStandTrack = getOrCreateTrack(activeAnimator, SIT_TO_STAND_ID, "CustomSitToStand", false)
    end

    local moveConn: RBXScriptConnection? = nil
    local keyConn: RBXScriptConnection? = nil

    local function finishStandUp()
        if moveConn then moveConn:Disconnect() moveConn = nil end
        if keyConn then keyConn:Disconnect() keyConn = nil end
        if currentToken ~= transitionToken then return end

        isStandingUp = false
        isCurrentlySeated = false
        currentOccupiedSeat = nil
        localPlayer:SetAttribute("IsSeated", false)

        -- Re-enable sit prompts once fully stood up
        setSitPromptsVisible(true)
    end

    local function cancelForMovement()
        if sitToStandTrack and sitToStandTrack.IsPlaying then
            sitToStandTrack:Stop(0.15)
        end
        stopTrack(standToSitTrack, 0.10)
        if activeHumanoid then
            activeHumanoid.Sit = false
            activeHumanoid.WalkSpeed = (savedWalkSpeed and savedWalkSpeed > 0) and savedWalkSpeed or 6
            activeHumanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, true)
            activeHumanoid.AutoRotate = true
        end
        localPlayer.CameraMode = Enum.CameraMode.LockFirstPerson
        finishStandUp()
    end

    -- If player is already actively trying to move, instant-cancel stand animation into walk
    if hasActiveMoveIntent() then
        cancelForMovement()
        return
    end

    -- Play SitToStand rising directly from the held sitting pose:
    if sitToStandTrack then
        sitToStandTrack:Play(0.12)
        sitToStandTrack:AdjustSpeed(1.15) -- Natural rise
    end
    -- Fade out the held StandToSit pose smoothly as SitToStand begins
    stopTrack(standToSitTrack, 0.15)

    -- Movement-cancel listener during standing up
    keyConn = UserInputService.InputBegan:Connect(function(input, gpe)
        if gpe then return end
        if input.KeyCode == Enum.KeyCode.W or input.KeyCode == Enum.KeyCode.A
            or input.KeyCode == Enum.KeyCode.S or input.KeyCode == Enum.KeyCode.D then
            cancelForMovement()
        end
    end)

    if activeHumanoid then
        moveConn = activeHumanoid:GetPropertyChangedSignal("MoveDirection"):Connect(function()
            if hasActiveMoveIntent() then
                cancelForMovement()
            end
        end)
    end

    -- 1. At 1.70s, character is upright on both feet. Unseat in Roblox physics:
    -- This triggers Animate to transition into Idle, while SitToStand holds the standing pose!
    task.delay(1.70, function()
        if isStandingUp and currentToken == transitionToken then
            if activeHumanoid then
                activeHumanoid.Sit = false
                activeHumanoid.WalkSpeed = (savedWalkSpeed and savedWalkSpeed > 0) and savedWalkSpeed or 6
                activeHumanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, true)
                activeHumanoid.AutoRotate = true
            end
            localPlayer.CameraMode = Enum.CameraMode.LockFirstPerson
        end
    end)

    -- 2. At 1.85s (150ms after unseating), Animate is running idle underneath.
    -- Smoothly fade out SitToStand over 0.25s into the active idle animation:
    task.delay(1.85, function()
        if isStandingUp and currentToken == transitionToken then
            if sitToStandTrack and sitToStandTrack.IsPlaying then
                sitToStandTrack:Stop(0.25)
            end
        end
    end)

    -- 3. At 2.10s, finish cleanup cleanly
    task.delay(2.10, function()
        if isStandingUp and currentToken == transitionToken then
            finishStandUp()
        end
    end)
end

_G.RequestStandUp = requestStandUp
shared.RequestStandUp = requestStandUp

localPlayer:GetAttributeChangedSignal("RequestStandUp"):Connect(function()
    if localPlayer:GetAttribute("RequestStandUp") == true then
        localPlayer:SetAttribute("RequestStandUp", false)
        if requestStandUp then
            requestStandUp()
        end
    end
end)

local function setSitPromptsVisible(visible: boolean)
    local cs = workspace:FindFirstChild("CampfireSeats")
    if cs then
        for _, desc in ipairs(cs:GetDescendants()) do
            if desc:IsA("ProximityPrompt") and (desc.Name == "SitPrompt" or desc:HasTag("CampfireSitPrompt")) then
                desc.Enabled = visible
            end
        end
    end
end

ProximityPromptService.PromptShown:Connect(function(prompt)
    if isCurrentlySeated and (prompt.Name == "SitPrompt" or prompt:HasTag("CampfireSitPrompt")) then
        prompt.Enabled = false
    end
end)

local function onEnterSeat(seat: Seat | VehicleSeat)
    if isCurrentlySeated then return end
    isCurrentlySeated = true
    isStandingUp = false
    currentOccupiedSeat = seat
    transitionToken = transitionToken + 1
    local currentToken = transitionToken

    -- Stop any lingering stand-up animation
    stopTrack(sitToStandTrack, 0.1)

    -- Hide all other sit prompts so player cannot see them or auto-teleport into them
    setSitPromptsVisible(false)

    -- Save WalkSpeed and lock movement, jumping, and auto-rotation
    if activeHumanoid then
        if activeHumanoid.WalkSpeed > 0 then
            savedWalkSpeed = activeHumanoid.WalkSpeed
        end
        activeHumanoid.WalkSpeed = 0
        activeHumanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, false)
        activeHumanoid.AutoRotate = false
    end

    -- Switch to Classic camera mode while seated for smooth freecam without body rotation
    localPlayer.CameraMode = Enum.CameraMode.Classic

    -- Signal HUD and camera controllers for decoupled freecam and reticle suppression
    localPlayer:SetAttribute("IsSeated", true)

    if not activeAnimator then return end

    -- Load StandToSit track
    if not standToSitTrack then
        standToSitTrack = getOrCreateTrack(activeAnimator, STAND_TO_SIT_ID, "CustomStandToSit", false)
    end

    -- Suppress default Roblox sit animation
    suppressDefaultRobloxSit()

    -- Play StandToSit transition
    if standToSitTrack then
        standToSitTrack:Play(0.12)
        standToSitTrack:AdjustSpeed(1.20) -- Natural ~1.85s descent
    end

    -- Show luxury on-screen Stand Up prompt
    showStandPrompt()

    -- Hold the final sitting pose when StandToSit completes:
    -- Keeps character resting naturally on the log with perfectly straight back and hands on thighs!
    task.delay(1.75, function()
        if currentToken == transitionToken and isCurrentlySeated and not isStandingUp then
            if standToSitTrack and standToSitTrack.IsPlaying then
                standToSitTrack:AdjustSpeed(0)
                standToSitTrack.TimePosition = math.max(0, standToSitTrack.Length - 0.05)
            end
        end
    end)
end

local function onLeaveSeat()
    if not isCurrentlySeated then return end
    if not isStandingUp then
        requestStandUp()
    end
end

-- -----------------------------------------------------------------------------
-- 6. CHARACTER RIGGING & SEATED MONITOR
-- -----------------------------------------------------------------------------
local function cleanupTracks()
    hideStandPrompt()
    stopTrack(standToSitTrack, 0.1)
    stopTrack(sitToStandTrack, 0.1)
    standToSitTrack = nil
    sitToStandTrack = nil
    isCurrentlySeated = false
    isStandingUp = false
    currentOccupiedSeat = nil
    localPlayer:SetAttribute("IsSeated", false)
    localPlayer.CameraMode = Enum.CameraMode.LockFirstPerson
    setSitPromptsVisible(true)
end

local function setupCharacter(char: Model)
    cleanupTracks()
    activeCharacter = char
    activeHumanoid = char:WaitForChild("Humanoid", 10) :: Humanoid?
    activeRootPart = char:WaitForChild("HumanoidRootPart", 10) :: BasePart?
    activeAnimator = if activeHumanoid then (activeHumanoid:WaitForChild("Animator", 10) :: Animator?) else nil

    if not activeHumanoid then return end

    -- Monitor Seated state
    activeHumanoid.Seated:Connect(function(active: boolean, currentSeat: Instance?)
        if active and currentSeat and (currentSeat:IsA("Seat") or currentSeat:IsA("VehicleSeat")) then
            onEnterSeat(currentSeat :: any)
        else
            if isCurrentlySeated and not isStandingUp then
                onLeaveSeat()
            end
        end
    end)

    -- Safety check for Humanoid.Sit property changes
    activeHumanoid:GetPropertyChangedSignal("Sit"):Connect(function()
        if not activeHumanoid then return end
        if not activeHumanoid.Sit and isCurrentlySeated and not isStandingUp then
            onLeaveSeat()
        end
    end)
end

if localPlayer.Character then
    setupCharacter(localPlayer.Character)
end

localPlayer.CharacterAdded:Connect(setupCharacter)
localPlayer.CharacterRemoving:Connect(function()
    cleanupTracks()
    activeCharacter = nil
    activeHumanoid = nil
    activeRootPart = nil
    activeAnimator = nil
end)

-- -----------------------------------------------------------------------------
-- 7. KEYBOARD & GAMEPAD INPUT LISTENER ([E] TO STAND UP)
-- -----------------------------------------------------------------------------
UserInputService.InputBegan:Connect(function(input: InputObject, gameProcessed: boolean)
    if gameProcessed then return end
    if isCurrentlySeated and not isStandingUp then
        if input.KeyCode == Enum.KeyCode.E or input.KeyCode == Enum.KeyCode.ButtonX then
            requestStandUp()
        end
    end
end)

-- -----------------------------------------------------------------------------
-- 8. CONTINUOUS SEATED ENFORCEMENT & DIRECTION LOCK (RenderStepped & Heartbeat)
-- -----------------------------------------------------------------------------
-- Enforces:
-- 1. HumanoidRootPart rotation & position is strictly locked to seat facing orientation (NO turning with camera)
-- 2. Humanoid.WalkSpeed = 0 (NO walking while seated)
-- 3. Humanoid.AutoRotate = false (NO auto-spin)
-- 4. Jumping is disabled (Spacebar DOES NOT jump or break sit)
-- 5. Default Roblox sit track is suppressed
RunService.Heartbeat:Connect(function()
    if isCurrentlySeated or isStandingUp then
        if activeHumanoid then
            if activeHumanoid.WalkSpeed ~= 0 then
                activeHumanoid.WalkSpeed = 0
            end
            if activeHumanoid.AutoRotate then
                activeHumanoid.AutoRotate = false
            end
            pcall(function()
                activeHumanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, false)
            end)
        end

        suppressDefaultRobloxSit()
    end
end)

local SittingController = {
    RequestStandUp = function()
        if requestStandUp then
            requestStandUp()
        end
    end,
    IsSeated = function(): boolean
        return isCurrentlySeated
    end,
}
_G.RequestStandUp = requestStandUp

return SittingController
