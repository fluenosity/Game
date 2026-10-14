--!strict
--[[
    CombatSystem.server.lua
    Server-side melee hit validation, damage arbitration, knockback physics,
    and campsite training dummy spawner for "Don't Let the Fire Die".
    Developed for Fluenosity Studio.

    Features:
    - Authoritative server validation for melee attacks (reach, cooldown, alive check)
    - Server-authoritative damage for equipped one-handed weapon attacks
    - Guard / Blocking mitigation: 70% damage reduction when target is blocking
    - Physics-based knockback impulse applied to target HumanoidRootPart
    - Visual impact effects and floating combat text replication
    - Campsite Training Dummy with interactive health bar & auto-regeneration
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local sharedFolder = ReplicatedStorage:WaitForChild("FluenosityShared")

-- -----------------------------------------------------------------------------
-- 1. REMOTE COMMUNICATION SETUP
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

local meleeBlockRequest = sharedFolder:FindFirstChild("MeleeBlockRequest") :: RemoteEvent?
if not meleeBlockRequest then
    meleeBlockRequest = Instance.new("RemoteEvent")
    meleeBlockRequest.Name = "MeleeBlockRequest"
    meleeBlockRequest.Parent = sharedFolder
end

local meleeBlockState = sharedFolder:FindFirstChild("MeleeBlockState") :: RemoteEvent?
if not meleeBlockState then
    meleeBlockState = Instance.new("RemoteEvent")
    meleeBlockState.Name = "MeleeBlockState"
    meleeBlockState.Parent = sharedFolder
end

-- -----------------------------------------------------------------------------
-- 2. WEAPON ATTACK CONFIGURATION & LIMITS
-- -----------------------------------------------------------------------------
type WeaponAttackConfig = {
    Damage: number,
    MaxReach: number,
    Cooldown: number,
    Duration: number,
    KnockbackForce: number,
    UpwardForce: number,
    GuardDrain: number,
    Sound: string,
}

local WEAPON_ATTACK_CONFIG: { [string]: { [string]: WeaponAttackConfig } } = {
}

-- Rate-limit each attack independently so a heavy does not consume an M1's window.
local playerLastAttackTime: { [Player]: { [string]: number } } = {}
local playerAttackToken: { [Player]: number } = {}
Players.PlayerRemoving:Connect(function(player)
    playerLastAttackTime[player] = nil
    playerAttackToken[player] = nil
end)

local DEFAULT_GUARD_STAMINA = 100
local GUARD_BREAK_DURATION = 1.25
local guardBreakToken: { [Model]: number } = {}

local function initializeCombatCharacter(character: Model)
    character:SetAttribute("IsBlocking", false)
    character:SetAttribute("IsGuardBroken", false)
    character:SetAttribute("GuardStamina", DEFAULT_GUARD_STAMINA)
end

local function breakGuard(character: Model)
    local token = (guardBreakToken[character] or 0) + 1
    guardBreakToken[character] = token
    character:SetAttribute("IsBlocking", false)
    character:SetAttribute("IsGuardBroken", true)
    task.delay(GUARD_BREAK_DURATION, function()
        if not character.Parent or guardBreakToken[character] ~= token then return end
        character:SetAttribute("IsGuardBroken", false)
        character:SetAttribute("GuardStamina", DEFAULT_GUARD_STAMINA)
        guardBreakToken[character] = nil
    end)
end

local function onPlayerAdded(player: Player)
    player.CharacterAdded:Connect(function(character: Model)
        initializeCombatCharacter(character)
    end)
    if player.Character then
        initializeCombatCharacter(player.Character)
    end
end

Players.PlayerAdded:Connect(onPlayerAdded)
for _, player in ipairs(Players:GetPlayers()) do
    onPlayerAdded(player)
end

-- -----------------------------------------------------------------------------
-- 3. FLOATING COMBAT TEXT & HIT EFFECTS
-- -----------------------------------------------------------------------------
local function spawnDamagePopup(targetPart: BasePart, amount: number, isBlocked: boolean, isHeavy: boolean)
    local billboard = Instance.new("BillboardGui")
    billboard.Name = "DamagePopup"
    billboard.Size = UDim2.fromOffset(120, 40)
    billboard.StudsOffset = Vector3.new(
        (math.random() - 0.5) * 1.5,
        1.5 + math.random() * 0.8,
        (math.random() - 0.5) * 1.5
    )
    billboard.AlwaysOnTop = true
    billboard.MaxDistance = 60

    local label = Instance.new("TextLabel")
    label.Size = UDim2.fromScale(1, 1)
    label.BackgroundTransparency = 1
    label.Font = Enum.Font.GothamBold
    label.TextSize = isHeavy and 24 or (isBlocked and 16 or 20)

    if isBlocked then
        label.TextColor3 = Color3.fromRGB(180, 200, 230)
        label.Text = string.format("-%d (GUARD)", math.floor(amount))
    elseif isHeavy then
        label.TextColor3 = Color3.fromRGB(255, 120, 40)
        label.Text = string.format("-%d CRIT!", math.floor(amount))
    else
        label.TextColor3 = Color3.fromRGB(255, 230, 210)
        label.Text = string.format("-%d", math.floor(amount))
    end

    local stroke = Instance.new("UIStroke")
    stroke.Thickness = 2
    stroke.Color = Color3.fromRGB(15, 15, 20)
    stroke.Parent = label

    label.Parent = billboard
    billboard.Parent = targetPart

    -- Animate upward and fade
    local tweenInfo = TweenInfo.new(0.75, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    local floatGoal = { StudsOffset = billboard.StudsOffset + Vector3.new(0, 2.0, 0) }
    local fadeGoal = { TextTransparency = 1 }

    TweenService:Create(billboard, tweenInfo, floatGoal):Play()
    local textTween = TweenService:Create(label, tweenInfo, fadeGoal)
    textTween:Play()
    textTween.Completed:Connect(function()
        billboard:Destroy()
    end)
end

local function spawnHitParticles(hitPos: Vector3, normal: Vector3, isHeavy: boolean)
    -- Kept completely peaceful and non-jarring (no explosive sparks)
end

-- -----------------------------------------------------------------------------
-- 4. SERVER MELEE HIT HANDLER
-- -----------------------------------------------------------------------------
local function onMeleeAttackRequest(
    player: Player,
    attackType: string,
    targetInstance: Instance?,
    hitPos: Vector3,
    hitNormal: Vector3
)
    local char = player.Character
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    local hrp = char:FindFirstChild("HumanoidRootPart") :: BasePart?
    if not hum or not hrp or hum.Health <= 0 then return end

    local equippedTool = char:FindFirstChildOfClass("Tool")
    if not equippedTool or equippedTool:GetAttribute("CombatWeapon") ~= true then return end

    local weaponId = equippedTool:GetAttribute("WeaponId")
    if typeof(weaponId) ~= "string" then return end
    local weaponConfig = WEAPON_ATTACK_CONFIG[weaponId]
    local config = weaponConfig and weaponConfig[attackType]
    if not config then return end
    if targetInstance ~= nil and typeof(targetInstance) ~= "Instance" then return end
    if typeof(hitPos) ~= "Vector3" or typeof(hitNormal) ~= "Vector3" then return end
    local function isFinite(value: number): boolean
        return value == value and math.abs(value) < math.huge
    end
    if not isFinite(hitPos.X) or not isFinite(hitPos.Y) or not isFinite(hitPos.Z)
        or not isFinite(hitNormal.X) or not isFinite(hitNormal.Y) or not isFinite(hitNormal.Z) then
        return
    end
    if targetInstance and not targetInstance:IsDescendantOf(workspace) then return end

    -- Anti-cheat rate limit validation
    local now = os.clock()
    local playerAttackTimes = playerLastAttackTime[player]
    if not playerAttackTimes then
        playerAttackTimes = {}
        playerLastAttackTime[player] = playerAttackTimes
    end
    local rateLimitKey = if attackType == "WeaponLightA" or attackType == "WeaponLightB" then "WeaponLight" else attackType
    local lastAttack = playerAttackTimes[rateLimitKey] or 0
    if now - lastAttack < config.Cooldown * 0.75 then
        return
    end
    playerAttackTimes[rateLimitKey] = now

    -- Reach distance validation
    local dist = (hrp.Position - hitPos).Magnitude
    if dist > config.MaxReach + 3.0 then
        return
    end
    local attackDirection = hitPos - hrp.Position
    if attackDirection.Magnitude > 0.001 and hrp.CFrame.LookVector:Dot(attackDirection.Unit) < -0.65 then
        return
    end

    -- Replicate only after the server accepts the attack type, timing, and reach.
    local token = (playerAttackToken[player] or 0) + 1
    playerAttackToken[player] = token
    char:SetAttribute("IsAttacking", true)
    task.delay(config.Duration, function()
        if player.Parent and player.Character == char and playerAttackToken[player] == token then
            char:SetAttribute("IsAttacking", false)
        end
    end)

    -- Identify target Humanoid
    local targetChar: Model? = nil
    local targetHum: Humanoid? = nil
    local targetHRP: BasePart? = nil

    if targetInstance then
        local current = targetInstance
        while current and current ~= workspace do
            if current:IsA("Model") then
                local foundHum = current:FindFirstChildOfClass("Humanoid")
                if foundHum and current ~= char then
                    targetChar = current
                    targetHum = foundHum
                    targetHRP = current:FindFirstChild("HumanoidRootPart") :: BasePart?
                        or current:FindFirstChildWhichIsA("BasePart")
                    break
                end
            end
            current = current.Parent
        end
    end

    if targetHRP then
        local targetOffset = targetHRP.Position - hrp.Position
        if targetOffset.Magnitude > config.MaxReach + 2.0 then return end
        if targetOffset.Magnitude > 0.001 and hrp.CFrame.LookVector:Dot(targetOffset.Unit) < -0.65 then return end
    end

    -- If direct click didn't yield a humanoid, do a spatial spherecast forward
    if not targetHum then
        local checkOrigin = hrp.Position
        local lookDir = hrp.CFrame.LookVector
        local rayParams = RaycastParams.new()
        rayParams.FilterDescendantsInstances = { char }
        rayParams.FilterType = Enum.RaycastFilterType.Exclude

        local sphereResult = workspace:Spherecast(checkOrigin, 2.5, lookDir * config.MaxReach, rayParams)
        if sphereResult and sphereResult.Instance then
            local hitModel = sphereResult.Instance:FindFirstAncestorOfClass("Model")
            if hitModel and hitModel ~= char then
                local foundHum = hitModel:FindFirstChildOfClass("Humanoid")
                if foundHum then
                    targetChar = hitModel
                    targetHum = foundHum
                    targetHRP = hitModel:FindFirstChild("HumanoidRootPart") :: BasePart?
                        or hitModel:FindFirstChildWhichIsA("BasePart")
                    hitPos = sphereResult.Position
                    hitNormal = sphereResult.Normal
                end
            end
        end
    end

    if not targetHum or targetHum.Health <= 0 then
        -- Missed the target or swung into scenery; the local swing animation remains visible.
        return
    end

    -- Check if target is actively Blocking / Guarding
    local isTargetBlocking = targetChar ~= nil
        and targetChar:GetAttribute("IsBlocking") == true
        and targetChar:GetAttribute("IsGuardBroken") ~= true
    local damageDealt = config.Damage
    local soundToPlay = config.Sound

    if isTargetBlocking and targetChar then
        local defenderRoot = targetHRP
        local facingAttacker = targetChar:GetAttribute("IsCombatTestCharacter") == true
        if defenderRoot then
            local defenderFacing = hrp.Position - defenderRoot.Position
            facingAttacker = facingAttacker or (defenderFacing.Magnitude > 0.001
                and defenderRoot.CFrame.LookVector:Dot(defenderFacing.Unit) > 0.15)
        end

        if facingAttacker then
            local guardStamina = targetChar:GetAttribute("GuardStamina")
            if typeof(guardStamina) ~= "number" then
                guardStamina = DEFAULT_GUARD_STAMINA
            end
            guardStamina = math.max(0, guardStamina - (config.GuardDrain or 25))
            targetChar:SetAttribute("GuardStamina", guardStamina)
            soundToPlay = "BlockImpact"

            if guardStamina <= 0 then
                breakGuard(targetChar)
            else
                damageDealt = math.max(1, math.floor(damageDealt * 0.30))
            end
        else
            isTargetBlocking = false
        end
    end

    -- Deduct target health
    targetHum:TakeDamage(damageDealt)

    -- Apply physics knockback
    if targetHRP and not targetHRP.Anchored then
        local knockOffset = targetHRP.Position - hrp.Position
        local knockDir = if knockOffset.Magnitude > 0.1 then knockOffset.Unit else hrp.CFrame.LookVector
        local force = (knockDir * config.KnockbackForce + Vector3.new(0, config.UpwardForce, 0))
        targetHRP:ApplyImpulse(force * targetHRP.AssemblyMass)
    end

    -- Visual floating damage text & hit sparks
    local displayPart = targetHRP
    if not displayPart and targetInstance and targetInstance:IsA("BasePart") then
        displayPart = targetInstance
    end
    displayPart = displayPart or hrp
    if displayPart and displayPart:IsA("BasePart") then
        spawnDamagePopup(displayPart, damageDealt, isTargetBlocking, attackType == "WeaponHeavy")
    end
    spawnHitParticles(hitPos, hitNormal, attackType == "WeaponHeavy")

    -- Broadcast hit replication event to clients for audio & camera shake sync
    if meleeHitReplicatedEvent then
        meleeHitReplicatedEvent:FireAllClients(
            player,
            targetChar,
            attackType,
            hitPos,
            soundToPlay,
            isTargetBlocking
        )
    end
end

if meleeBlockRequest then
    meleeBlockRequest.OnServerEvent:Connect(function(player: Player, requestedBlocking: boolean)
        if typeof(requestedBlocking) ~= "boolean" then return end
        local character = player.Character
        local humanoid = character and character:FindFirstChildOfClass("Humanoid")
        if not character or not humanoid or humanoid.Health <= 0 then return end

        if requestedBlocking then
            local canBlock = character:GetAttribute("IsGuardBroken") ~= true
                and character:GetAttribute("IsAttacking") ~= true
            if not canBlock then
                if meleeBlockState then meleeBlockState:FireClient(player, false) end
                return
            end
        end

        character:SetAttribute("IsBlocking", requestedBlocking)
        if meleeBlockState then
            meleeBlockState:FireClient(player, requestedBlocking)
        end
    end)
end

if meleeAttackEvent then
    meleeAttackEvent.OnServerEvent:Connect(onMeleeAttackRequest)
end

-- -----------------------------------------------------------------------------
-- 5. R15 FEMALE COMBAT TEST CHARACTER
-- -----------------------------------------------------------------------------
local function createCombatTestCharacter()
    if workspace:FindFirstChild("CombatTestFemale") then return end

    local roster = sharedFolder:FindFirstChild("SurvivorRoster")
    local femaleTemplate = roster and roster:FindFirstChild("Maya")
    if not femaleTemplate or not femaleTemplate:IsA("Model") then
        warn("Combat test character not spawned: SurvivorRoster.Maya is unavailable")
        return
    end

    local character = femaleTemplate:Clone()
    character.Name = "CombatTestFemale"
    local animateScript = character:FindFirstChild("Animate")
    if animateScript and animateScript:IsA("BaseScript") then
        animateScript:Destroy()
    end
    character:SetAttribute("IsCombatTestCharacter", true)
    character:SetAttribute("IsBlocking", true)
    character:SetAttribute("IsGuardBroken", false)
    character:SetAttribute("GuardStamina", DEFAULT_GUARD_STAMINA)

    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not humanoid then
        character:Destroy()
        warn("Combat test character not spawned: Maya has no Humanoid")
        return
    end

    humanoid.DisplayName = "Maya - Combat Test"
    humanoid.MaxHealth = 1000
    humanoid.Health = humanoid.MaxHealth
    humanoid.WalkSpeed = 0
    humanoid.JumpPower = 0
    humanoid.AutoRotate = false
    humanoid.BreakJointsOnDeath = false
    humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
    humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, false)

    character:PivotTo(CFrame.new(10, 13.5, -420) * CFrame.Angles(0, math.rad(-75), 0))
    character.Parent = workspace
end

task.defer(createCombatTestCharacter)
