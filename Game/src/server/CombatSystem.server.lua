--!strict
--[[
    CombatSystem.server.lua
    Server-side melee hit validation, damage arbitration, knockback physics,
    and campsite training dummy spawner for "Don't Let the Fire Die".
    Developed for Fluenosity Studio.

    Features:
    - Authoritative server validation for melee attacks (reach, cooldown, alive check)
    - Full damage calculations (Jab: 12 HP, Cross: 18 HP, Heavy Punch: 32 HP)
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

-- -----------------------------------------------------------------------------
-- 2. ATTACK CONFIGURATION & LIMITS
-- -----------------------------------------------------------------------------
local ATTACK_CONFIG = {
    ["PunchRight"] = {
        Damage = 12,
        MaxReach = 7.0,
        Cooldown = 0.22,
        KnockbackForce = 18.0,
        UpwardForce = 2.0,
        Sound = "PunchImpact",
    },
    ["PunchLeft"] = {
        Damage = 12,
        MaxReach = 7.0,
        Cooldown = 0.22,
        KnockbackForce = 18.0,
        UpwardForce = 2.0,
        Sound = "PunchImpact",
    },
    ["Heavy"] = {
        Damage = 32,
        MaxReach = 9.0,
        Cooldown = 0.55,
        KnockbackForce = 62.0,
        UpwardForce = 14.0,
        Sound = "PunchHeavyImpact",
    },
}

-- Rate-limiting table per player
local playerLastAttackTime: { [Player]: number } = {}

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

    local config = ATTACK_CONFIG[attackType]
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
    local lastAttack = playerLastAttackTime[player] or 0
    if now - lastAttack < config.Cooldown * 0.75 then
        return
    end
    playerLastAttackTime[player] = now

    -- Reach distance validation
    local dist = (hrp.Position - hitPos).Magnitude
    if dist > config.MaxReach + 3.0 then
        return
    end
    local attackDirection = hitPos - hrp.Position
    if attackDirection.Magnitude > 0.001 and hrp.CFrame.LookVector:Dot(attackDirection.Unit) < -0.65 then
        return
    end

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
        -- Missed / punched thin air or scenery: replicate whoosh/swing
        return
    end

    -- Check if target is actively Blocking / Guarding
    local isTargetBlocking = targetChar and targetChar:GetAttribute("IsBlocking") == true
    local damageDealt = config.Damage
    local soundToPlay = config.Sound

    if isTargetBlocking then
        damageDealt = math.max(1, math.floor(damageDealt * 0.30)) -- 70% damage reduction
        soundToPlay = "BlockImpact"
    end

    -- Deduct target health
    targetHum:TakeDamage(damageDealt)

    -- Apply physics knockback
    if targetHRP and not targetHRP.Anchored then
        local knockDir = (targetHRP.Position - hrp.Position).Unit
        if knockDir.Magnitude < 0.1 then
            knockDir = hrp.CFrame.LookVector
        end
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
        spawnDamagePopup(displayPart, damageDealt, isTargetBlocking, attackType == "Heavy")
    end
    spawnHitParticles(hitPos, hitNormal, attackType == "Heavy")

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

if meleeAttackEvent then
    meleeAttackEvent.OnServerEvent:Connect(onMeleeAttackRequest)
end

-- -----------------------------------------------------------------------------
-- 5. CAMPSITE TRAINING DUMMY SPAWNER
-- -----------------------------------------------------------------------------
local function createTrainingDummy()
    local existingDummy = workspace:FindFirstChild("CampsiteTrainingDummy")
    if existingDummy then return end

    local dummyModel = Instance.new("Model")
    dummyModel.Name = "CampsiteTrainingDummy"

    local dummyPos = Vector3.new(10, 10.5, -420) -- Clearing beside campfire

    -- Root Part
    local hrp = Instance.new("Part")
    hrp.Name = "HumanoidRootPart"
    hrp.Size = Vector3.new(2, 2, 1)
    hrp.CFrame = CFrame.new(dummyPos + Vector3.new(0, 3, 0)) * CFrame.Angles(0, math.rad(-75), 0)
    hrp.Transparency = 1
    hrp.CanCollide = false
    hrp.Anchored = false
    hrp.Parent = dummyModel
    dummyModel.PrimaryPart = hrp

    -- Torso (Burlap padded punch dummy)
    local torso = Instance.new("Part")
    torso.Name = "UpperTorso"
    torso.Size = Vector3.new(2.4, 2.8, 1.4)
    torso.CFrame = hrp.CFrame
    torso.Color = Color3.fromRGB(140, 115, 85) -- Coarse burlap canvas
    torso.Material = Enum.Material.Fabric
    torso.CanCollide = true
    torso.Parent = dummyModel

    local torsoWeld = Instance.new("WeldConstraint")
    torsoWeld.Part0 = hrp
    torsoWeld.Part1 = torso
    torsoWeld.Parent = hrp

    -- Head (Wooden carved post with straw band)
    local head = Instance.new("Part")
    head.Name = "Head"
    head.Size = Vector3.new(1.4, 1.4, 1.4)
    head.CFrame = hrp.CFrame * CFrame.new(0, 2.1, 0)
    head.Color = Color3.fromRGB(115, 85, 60)
    head.Material = Enum.Material.Wood
    head.CanCollide = true
    head.Parent = dummyModel

    local headWeld = Instance.new("WeldConstraint")
    headWeld.Part0 = hrp
    headWeld.Part1 = head
    headWeld.Parent = hrp

    -- Base Stand (Heavy timber post anchored into the snow)
    local standPost = Instance.new("Part")
    standPost.Name = "StandPost"
    standPost.Size = Vector3.new(0.8, 3.2, 0.8)
    standPost.CFrame = hrp.CFrame * CFrame.new(0, -2.4, 0)
    standPost.Color = Color3.fromRGB(70, 50, 35)
    standPost.Material = Enum.Material.WoodPlanks
    standPost.Anchored = true
    standPost.CanCollide = true
    standPost.Parent = dummyModel

    -- Spring constraint to let the dummy sway and recoil dynamically when punched!
    local attachment0 = Instance.new("Attachment")
    attachment0.Position = Vector3.new(0, 1.4, 0)
    attachment0.Parent = standPost

    local attachment1 = Instance.new("Attachment")
    attachment1.Position = Vector3.new(0, -1.0, 0)
    attachment1.Parent = hrp

    local spring = Instance.new("SpringConstraint")
    spring.Attachment0 = attachment0
    spring.Attachment1 = attachment1
    spring.Stiffness = 3000
    spring.Damping = 120
    spring.FreeLength = 0.5
    spring.LimitsEnabled = true
    spring.MaxLength = 1.2
    spring.Parent = hrp

    local ballSocket = Instance.new("BallSocketConstraint")
    ballSocket.Attachment0 = attachment0
    ballSocket.Attachment1 = attachment1
    ballSocket.LimitsEnabled = true
    ballSocket.UpperAngle = 35
    ballSocket.Parent = hrp

    -- Humanoid for damage reception
    local humanoid = Instance.new("Humanoid")
    humanoid.MaxHealth = 100
    humanoid.Health = 100
    humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
    humanoid.Parent = dummyModel

    -- Health Billboard
    local billboard = Instance.new("BillboardGui")
    billboard.Name = "DummyHealthBar"
    billboard.Size = UDim2.fromOffset(130, 24)
    billboard.StudsOffset = Vector3.new(0, 2.4, 0)
    billboard.AlwaysOnTop = true
    billboard.MaxDistance = 45
    billboard.Parent = head

    local bgBar = Instance.new("Frame")
    bgBar.Name = "BarBackground"
    bgBar.Size = UDim2.new(1, 0, 0, 10)
    bgBar.Position = UDim2.new(0, 0, 0.5, 0)
    bgBar.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
    bgBar.BackgroundTransparency = 0.3
    bgBar.BorderSizePixel = 0
    bgBar.Parent = billboard

    local bgCorner = Instance.new("UICorner")
    bgCorner.CornerRadius = UDim.new(1, 0)
    bgCorner.Parent = bgBar

    local bgStroke = Instance.new("UIStroke")
    bgStroke.Thickness = 1
    bgStroke.Color = Color3.fromRGB(255, 160, 50)
    bgStroke.Transparency = 0.5
    bgStroke.Parent = bgBar

    local fillBar = Instance.new("Frame")
    fillBar.Name = "FillBar"
    fillBar.Size = UDim2.new(1, 0, 1, 0)
    fillBar.BackgroundColor3 = Color3.fromRGB(220, 60, 50)
    fillBar.BorderSizePixel = 0
    fillBar.Parent = bgBar

    local fillCorner = Instance.new("UICorner")
    fillCorner.CornerRadius = UDim.new(1, 0)
    fillCorner.Parent = fillBar

    local nameLabel = Instance.new("TextLabel")
    nameLabel.Name = "DummyTitle"
    nameLabel.Size = UDim2.new(1, 0, 0, 12)
    nameLabel.Position = UDim2.new(0, 0, 0, -12)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Font = Enum.Font.GothamMedium
    nameLabel.TextSize = 10
    nameLabel.TextColor3 = Color3.fromRGB(255, 220, 180)
    nameLabel.Text = "SPARRING DUMMY"
    nameLabel.Parent = billboard

    -- Auto-Regen logic
    local lastHitTime = 0
    humanoid.HealthChanged:Connect(function(newHealth)
        lastHitTime = os.clock()
        local healthPct = math.clamp(newHealth / humanoid.MaxHealth, 0, 1)
        TweenService:Create(fillBar, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            Size = UDim2.new(healthPct, 0, 1, 0),
        }):Play()

        if newHealth <= 0 then
            task.delay(1.5, function()
                humanoid.Health = humanoid.MaxHealth
            end)
        end
    end)

    task.spawn(function()
        while dummyModel.Parent do
            task.wait(0.5)
            if humanoid.Health < humanoid.MaxHealth and os.clock() - lastHitTime > 3.0 then
                humanoid.Health = math.min(humanoid.MaxHealth, humanoid.Health + 15)
            end
        end
    end)

    dummyModel.Parent = workspace
end

-- Initialize dummy once world is ready
task.defer(createTrainingDummy)
