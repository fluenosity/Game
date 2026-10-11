--!strict
--[[
    CampfireSystem.lua
    AAA Photorealistic Interactive Campfire & Log Seating System
    for "Don't Let the Fire Die" (Fluenosity Studio).
    
    Architecture:
    - Edit Mode & Play Mode Compatible: Can be generated in Studio Editor mode
      (via Command Bar) or auto-loaded instantly on server start with zero pop-in delay.
    - Central Campfire: Rounded slate river-stone hearth ring, charred ember ash bed,
      criss-crossed pine firewood logs, layered fire & spark particles, warm flickering light.
    - 4 Horizontal Log Trunks with 2 Seats each (8 seats total):
      Fallen pine timber logs lying flat on the earth.
      SEAT AUTO-SIT ELIMINATED: seat.Disabled = true & seat.CanTouch = false prevents
      accidental auto-sitting. Players ONLY sit when intentionally pressing [ E ]!
    - Clean Single-Prompt Toggle (Zero UI Glitch / Zero Overlap):
      * When UNLIT: "[ E ] Light Campfire" (requires Matchbox & Wood in inventory, consumes 1 Wood).
      * When LIT: "[ E ] Extinguish Fire" douses the flame, emits smoke puff, and stops audio.
      * Strictly ONE ProximityPrompt on the campfire so prompts never collide or stack!
    - Dedicated Camp Firewood Stack: (-8.5, 4.2)
      Authentic timber rack with 7 cut firewood logs where players can gather wood logs (max 5).
    - Dedicated Rustic Stone Pedestal: (9.2, -3.8)
      Keeps the Vintage Matchbox clear of bench seating paths and campfire prompts.
]]

local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")
local CollectionService = game:GetService("CollectionService")

local CampfireSystem = {}

local campfireState = {
    IsLit = true,
    Model = nil :: Model?,
    FirePart = nil :: BasePart?,
    Fire = nil :: Fire?,
    EmberParticles = nil :: ParticleEmitter?,
    SmokeParticles = nil :: ParticleEmitter?,
    GlowLight = nil :: PointLight?,
    EmbersCoals = nil :: BasePart?,
    CrackleAudio = nil :: Sound?,
    IgniteAudio = nil :: Sound?,
    DouseAudio = nil :: Sound?,
    MainPrompt = nil :: ProximityPrompt?,
}

-- Safe runtime notification helper
local function getNotificationEvent(): RemoteEvent?
    local sharedFolder = ReplicatedStorage:FindFirstChild("FluenosityShared")
    if not sharedFolder then return nil end
    local ev = sharedFolder:FindFirstChild("ShowNotification")
    if ev and ev:IsA("RemoteEvent") then
        return ev
    end
    if RunService:IsRunning() then
        local newEv = Instance.new("RemoteEvent")
        newEv.Name = "ShowNotification"
        newEv.Parent = sharedFolder
        return newEv
    end
    return nil
end

local function sendNotification(player: Player, message: string, iconName: string?, accentColor: Color3?)
    local ev = getNotificationEvent()
    if ev then
        ev:FireClient(
            player,
            message,
            iconName or "flame",
            accentColor or Color3.fromRGB(255, 160, 40)
        )
    end
end

-- Lazy, safe InventoryManager resolver (never crashes module load)
local function getInventoryManager(): any?
    local fluenosityServer = ServerScriptService:FindFirstChild("FluenosityServer")
    if fluenosityServer then
        local invMod = fluenosityServer:FindFirstChild("InventoryManager")
        if invMod and invMod:IsA("ModuleScript") then
            local ok, mod = pcall(require, invMod)
            if ok and typeof(mod) == "table" then
                return mod
            end
        end
    end
    return nil
end

-- Ground raycast helper
local function getGroundHeight(x: number, z: number): number
    local rayOrigin = Vector3.new(x, 150, z)
    local rayDir = Vector3.new(0, -250, 0)
    local rayParams = RaycastParams.new()
    rayParams.FilterType = Enum.RaycastFilterType.Include
    local terrain = Workspace:FindFirstChildOfClass("Terrain") or Workspace.Terrain
    if terrain then
        rayParams.FilterDescendantsInstances = { terrain }
    end
    local hit = Workspace:Raycast(rayOrigin, rayDir, rayParams)
    if hit then
        return hit.Position.Y
    end
    return 0.0
end

-- ---------------------------------------------------------------------------
-- 1. BUILD REALISTIC CAMPFIRE MODEL & HEARTH
-- ---------------------------------------------------------------------------
function CampfireSystem.BuildCampfire(): Model
    -- Check if permanent campfire already exists in Workspace
    local existing = Workspace:FindFirstChild("Campfire")
    if existing and existing:IsA("Model") then
        campfireState.Model = existing
        return existing
    end

    local groundY = getGroundHeight(0, 0)
    local model = Instance.new("Model")
    model.Name = "Campfire"
    CollectionService:AddTag(model, "IgnoreWoodScanner")

    -- 1. Ash Bed Base (Dark charred circular disc flush in the earth)
    local ashBed = Instance.new("Part")
    ashBed.Name = "AshBed"
    ashBed.Shape = Enum.PartType.Cylinder
    ashBed.Size = Vector3.new(0.4, 5.8, 5.8)
    ashBed.CFrame = CFrame.new(0, groundY + 0.1, 0) * CFrame.Angles(0, 0, math.rad(90))
    ashBed.Color = Color3.fromRGB(22, 18, 16)
    ashBed.Material = Enum.Material.Mud
    ashBed.TopSurface = Enum.SurfaceType.Smooth
    ashBed.BottomSurface = Enum.SurfaceType.Smooth
    ashBed.Anchored = true
    ashBed.CanCollide = true
    ashBed.Parent = model

    -- 2. River Stone Hearth Ring (14 smooth rounded weathered stones forming a tight circular hearth)
    local stoneColors = {
        Color3.fromRGB(78, 76, 74),
        Color3.fromRGB(90, 87, 82),
        Color3.fromRGB(66, 64, 62),
        Color3.fromRGB(84, 80, 76),
    }

    local stoneCount = 14
    local ringRadius = 2.65
    for i = 1, stoneCount do
        local angle = (i / stoneCount) * (math.pi * 2)
        local rad = ringRadius + (((i % 3) - 1) * 0.12)
        local sx = math.cos(angle) * rad
        local sz = math.sin(angle) * rad

        local stone = Instance.new("Part")
        stone.Name = "HearthStone_" .. i
        stone.Size = Vector3.new(1.45, 0.85, 1.25)
        stone.CFrame = CFrame.new(sx, groundY + 0.35, sz)
            * CFrame.Angles(math.rad(((i * 7) % 16) - 8), angle + math.rad(90), math.rad(((i * 11) % 16) - 8))
        stone.Color = stoneColors[(i % #stoneColors) + 1]
        stone.Material = (i % 2 == 0) and Enum.Material.Slate or Enum.Material.Granite
        stone.TopSurface = Enum.SurfaceType.Smooth
        stone.BottomSurface = Enum.SurfaceType.Smooth
        stone.Anchored = true
        stone.CanCollide = true

        local mesh = Instance.new("SpecialMesh")
        mesh.MeshType = Enum.MeshType.Sphere
        mesh.Scale = Vector3.new(1.0, 1.0, 1.0)
        mesh.Parent = stone

        stone.Parent = model
    end

    -- 3. Glowing Embers Bed (Hot charcoal coals under the logs)
    local embersCoals = Instance.new("Part")
    embersCoals.Name = "EmbersBed"
    embersCoals.Shape = Enum.PartType.Cylinder
    embersCoals.Size = Vector3.new(0.3, 2.6, 2.6)
    embersCoals.CFrame = CFrame.new(0, groundY + 0.28, 0) * CFrame.Angles(0, 0, math.rad(90))
    embersCoals.Color = Color3.fromRGB(220, 60, 14)
    embersCoals.Material = Enum.Material.Neon
    embersCoals.Transparency = 0.35
    embersCoals.TopSurface = Enum.SurfaceType.Smooth
    embersCoals.BottomSurface = Enum.SurfaceType.Smooth
    embersCoals.Anchored = true
    embersCoals.CanCollide = false
    embersCoals.Parent = model
    campfireState.EmbersCoals = embersCoals

    -- 4. Crossed Firewood Logs (Criss-crossed pyramid campfire stack)
    local logAngles = { 0, 60, 120, 180, 240, 300 }
    for i, aDeg in ipairs(logAngles) do
        local aRad = math.rad(aDeg)
        local log = Instance.new("Part")
        log.Name = "FirewoodLog_" .. i
        log.Shape = Enum.PartType.Cylinder
        log.Size = Vector3.new(3.4, 0.75, 0.75)
        
        local radialDist = 1.05
        local px = math.cos(aRad) * radialDist
        local pz = math.sin(aRad) * radialDist
        local py = groundY + 0.55 + ((i % 3) * 0.12)

        local logCF = CFrame.new(px, py, pz)
            * CFrame.Angles(0, aRad + math.rad(90), 0)
            * CFrame.Angles(0, 0, math.rad(68 + ((i % 2) * 6)))

        log.CFrame = logCF
        log.Color = (i % 2 == 0) and Color3.fromRGB(76, 52, 36) or Color3.fromRGB(68, 44, 30)
        log.Material = Enum.Material.Wood
        log.TopSurface = Enum.SurfaceType.Smooth
        log.BottomSurface = Enum.SurfaceType.Smooth
        log.Anchored = true
        log.CanCollide = true
        log.Parent = model
    end

    -- 5. Primary Fire Control Anchor Part
    local firePart = Instance.new("Part")
    firePart.Name = "FirePart"
    firePart.Size = Vector3.new(2.2, 2.2, 2.2)
    firePart.CFrame = CFrame.new(0, groundY + 1.1, 0)
    firePart.Transparency = 1
    firePart.CanCollide = false
    firePart.Anchored = true
    firePart.Parent = model
    model.PrimaryPart = firePart
    campfireState.FirePart = firePart

    -- Fire Object
    local fire = Instance.new("Fire")
    fire.Name = "Flame"
    fire.Size = 5.8
    fire.Heat = 14
    fire.Color = Color3.fromRGB(255, 140, 32)
    fire.SecondaryColor = Color3.fromRGB(215, 45, 14)
    fire.Enabled = true
    fire.Parent = firePart
    campfireState.Fire = fire

    -- Ember Sparks Particle Emitter
    local embers = Instance.new("ParticleEmitter")
    embers.Name = "EmberParticles"
    embers.Texture = "rbxasset://textures/particles/sparkles_main.dds"
    embers.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0.0, Color3.fromRGB(255, 220, 60)),
        ColorSequenceKeypoint.new(0.6, Color3.fromRGB(255, 130, 25)),
        ColorSequenceKeypoint.new(1.0, Color3.fromRGB(190, 35, 10)),
    })
    embers.Size = NumberSequence.new({
        NumberSequenceKeypoint.new(0.0, 0.25),
        NumberSequenceKeypoint.new(0.7, 0.16),
        NumberSequenceKeypoint.new(1.0, 0.0),
    })
    embers.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0.0, 0.0),
        NumberSequenceKeypoint.new(0.8, 0.2),
        NumberSequenceKeypoint.new(1.0, 1.0),
    })
    embers.Lifetime = NumberRange.new(2.0, 3.6)
    embers.Rate = 16
    embers.Speed = NumberRange.new(4.5, 8.5)
    embers.SpreadAngle = Vector2.new(30, 30)
    embers.Acceleration = Vector3.new(0, 3.2, 0)
    embers.LightEmission = 1.0
    embers.LightInfluence = 0.0
    embers.Enabled = true
    embers.Parent = firePart
    campfireState.EmberParticles = embers

    -- Smoke Particle Emitter
    local smoke = Instance.new("ParticleEmitter")
    smoke.Name = "SmokeParticles"
    smoke.Texture = "rbxasset://textures/particles/smoke_main.dds"
    smoke.Color = ColorSequence.new(Color3.fromRGB(115, 110, 105))
    smoke.Size = NumberSequence.new({
        NumberSequenceKeypoint.new(0.0, 1.2),
        NumberSequenceKeypoint.new(0.5, 3.2),
        NumberSequenceKeypoint.new(1.0, 5.5),
    })
    smoke.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0.0, 0.84),
        NumberSequenceKeypoint.new(0.6, 0.95),
        NumberSequenceKeypoint.new(1.0, 1.0),
    })
    smoke.Lifetime = NumberRange.new(4.0, 6.5)
    smoke.Rate = 6
    smoke.Speed = NumberRange.new(2.5, 4.8)
    smoke.SpreadAngle = Vector2.new(16, 16)
    smoke.Acceleration = Vector3.new(0, 1.4, 0)
    smoke.Enabled = true
    smoke.Parent = firePart
    campfireState.SmokeParticles = smoke

    -- Campfire Glow PointLight
    local glow = Instance.new("PointLight")
    glow.Name = "CampfireGlow"
    glow.Color = Color3.fromRGB(255, 138, 48)
    glow.Range = 36.0
    glow.Brightness = 1.25
    glow.Shadows = true
    glow.Enabled = true
    glow.Parent = firePart
    campfireState.GlowLight = glow

    -- Crackling Audio Loop
    local crackle = Instance.new("Sound")
    crackle.Name = "CrackleLoop"
    crackle.SoundId = "rbxassetid://9114223171"
    crackle.Volume = 0.65
    crackle.Looped = true
    crackle.RollOffMode = Enum.RollOffMode.InverseTapered
    crackle.RollOffMinDistance = 6
    crackle.RollOffMaxDistance = 55
    crackle.Parent = firePart
    if RunService:IsRunning() then
        crackle:Play()
    end
    campfireState.CrackleAudio = crackle

    -- Ignition Sound
    local igniteSound = Instance.new("Sound")
    igniteSound.Name = "IgniteSound"
    igniteSound.SoundId = "rbxassetid://9114223171"
    igniteSound.Volume = 0.95
    igniteSound.Parent = firePart
    campfireState.IgniteAudio = igniteSound

    -- Douse Sound
    local douseSound = Instance.new("Sound")
    douseSound.Name = "DouseSound"
    douseSound.SoundId = "rbxassetid://9114223171"
    douseSound.Volume = 0.85
    douseSound.Parent = firePart
    campfireState.DouseAudio = douseSound

    -- 6. SINGLE CLEAN INTERACTIVE PROXIMITY PROMPT
    local prompt = Instance.new("ProximityPrompt")
    prompt.Name = "CampfireTogglePrompt"
    prompt.ActionText = "Extinguish Fire"
    prompt.ObjectText = "CAMPFIRE"
    prompt.KeyboardKeyCode = Enum.KeyCode.E
    prompt.GamepadKeyCode = Enum.KeyCode.ButtonX
    prompt.HoldDuration = 0.35
    prompt.MaxActivationDistance = 8.5
    prompt.RequiresLineOfSight = false
    prompt.Parent = firePart
    campfireState.MainPrompt = prompt

    model:SetAttribute("IsLit", true)
    model:SetAttribute("Fuel", 120)
    model:SetAttribute("MaxFuel", 240)
    model.Parent = Workspace
    campfireState.Model = model
    campfireState.IsLit = true

    return model
end

-- ---------------------------------------------------------------------------
-- 2. BUILD 4 ORGANIC FALLEN TIMBER BENCHES (8 SEATS) & DEDICATED PEDESTAL
-- ---------------------------------------------------------------------------
function CampfireSystem.BuildSittingTrunks(): Folder
    -- Check if permanent CampfireSeats already exists in Workspace
    local existingFolder = Workspace:FindFirstChild("CampfireSeats")
    if existingFolder and existingFolder:IsA("Folder") then
        return existingFolder
    end

    local seatsFolder = Instance.new("Folder")
    seatsFolder.Name = "CampfireSeats"
    CollectionService:AddTag(seatsFolder, "IgnoreWoodScanner")

    -- 1. Dedicated Rustic Matchbox Pedestal (Clear open clearing at 9.2, -3.8)
    local pedestalGroundY = getGroundHeight(9.2, -3.8)
    local pedestalCenter = Vector3.new(9.2, pedestalGroundY + 0.60, -3.8)
    local pedestalModel = Instance.new("Model")
    pedestalModel.Name = "MatchboxPedestalModel"
    CollectionService:AddTag(pedestalModel, "IgnoreWoodScanner")

    local basePillar = Instance.new("Part")
    basePillar.Name = "PedestalBase"
    basePillar.Size = Vector3.new(1.8, 1.2, 1.8)
    basePillar.CFrame = CFrame.new(pedestalCenter)
    basePillar.Color = Color3.fromRGB(62, 60, 58)
    basePillar.Material = Enum.Material.Slate
    basePillar.Anchored = true
    basePillar.CanCollide = true
    basePillar.Parent = pedestalModel

    local slab = Instance.new("Part")
    slab.Name = "PedestalSlab"
    slab.Size = Vector3.new(2.2, 0.22, 2.2)
    slab.CFrame = CFrame.new(pedestalCenter.X, pedestalCenter.Y + 0.65, pedestalCenter.Z)
    slab.Color = Color3.fromRGB(86, 82, 78)
    slab.Material = Enum.Material.Granite
    slab.Anchored = true
    slab.CanCollide = true
    slab.Parent = pedestalModel

    pedestalModel.Parent = seatsFolder

    -- 2. Four Organic Fallen Timber Logs (Varied sizes, angles, and distances)
    local trunkConfigs = {
        {
            Name = "NorthEastTrunk",
            Center = Vector3.new(1.4, 0, -7.2),
            AngleDeg = -7,
            Length = 8.4,
            Diameter = 2.45,
            BarkColor = Color3.fromRGB(54, 40, 30),
            HasKnot = true,
        },
        {
            Name = "SouthEastTrunk",
            Center = Vector3.new(7.1, 0, 1.6),
            AngleDeg = 97,
            Length = 7.6,
            Diameter = 2.35,
            BarkColor = Color3.fromRGB(48, 36, 26),
            HasKnot = false,
        },
        {
            Name = "SouthWestTrunk",
            Center = Vector3.new(-1.2, 0, 7.3),
            AngleDeg = 173,
            Length = 8.8,
            Diameter = 2.50,
            BarkColor = Color3.fromRGB(56, 42, 32),
            HasKnot = true,
        },
        {
            Name = "NorthWestTrunk",
            Center = Vector3.new(-6.9, 0, -2.1),
            AngleDeg = 263,
            Length = 7.8,
            Diameter = 2.30,
            BarkColor = Color3.fromRGB(50, 38, 28),
            HasKnot = false,
        },
    }

    for _, cfg in ipairs(trunkConfigs) do
        local trunkModel = Instance.new("Model")
        trunkModel.Name = cfg.Name
        CollectionService:AddTag(trunkModel, "IgnoreWoodScanner")

        local trunkGroundY = getGroundHeight(cfg.Center.X, cfg.Center.Z)
        local baseCenter = Vector3.new(cfg.Center.X, trunkGroundY + (cfg.Diameter * 0.44), cfg.Center.Z)
        local baseRotation = CFrame.Angles(0, math.rad(cfg.AngleDeg), 0)

        local logPart = Instance.new("Part")
        logPart.Name = "Log"
        logPart.Shape = Enum.PartType.Cylinder
        logPart.Size = Vector3.new(cfg.Length, cfg.Diameter, cfg.Diameter)
        logPart.CFrame = CFrame.new(baseCenter) * baseRotation
        logPart.Color = cfg.BarkColor
        logPart.Material = Enum.Material.Wood
        logPart.TopSurface = Enum.SurfaceType.Smooth
        logPart.BottomSurface = Enum.SurfaceType.Smooth
        logPart.Anchored = true
        logPart.CanCollide = true
        logPart.Parent = trunkModel

        for _, endSign in ipairs({ -1, 1 }) do
            local endCap = Instance.new("Part")
            endCap.Name = "HeartwoodEndCap"
            endCap.Shape = Enum.PartType.Cylinder
            endCap.Size = Vector3.new(0.06, cfg.Diameter * 0.95, cfg.Diameter * 0.95)
            endCap.CFrame = logPart.CFrame * CFrame.new((cfg.Length / 2) * endSign, 0, 0)
            endCap.Color = Color3.fromRGB(152, 118, 86)
            endCap.Material = Enum.Material.WoodPlanks
            endCap.TopSurface = Enum.SurfaceType.Smooth
            endCap.BottomSurface = Enum.SurfaceType.Smooth
            endCap.Anchored = true
            endCap.CanCollide = true
            endCap.Parent = trunkModel
        end

        if cfg.HasKnot then
            local knot = Instance.new("Part")
            knot.Name = "BranchKnot"
            knot.Shape = Enum.PartType.Cylinder
            knot.Size = Vector3.new(0.55, 0.45, 0.45)
            knot.CFrame = logPart.CFrame * CFrame.new(-0.8, (cfg.Diameter * 0.42), 0.3) * CFrame.Angles(0, 0, math.rad(45))
            knot.Color = cfg.BarkColor
            knot.Material = Enum.Material.Wood
            knot.Anchored = true
            knot.CanCollide = true
            knot.Parent = trunkModel
        end

        local chockOffset = (cfg.Length * 0.33)
        for _, offsetSign in ipairs({ -chockOffset, chockOffset }) do
            local chock = Instance.new("Part")
            chock.Name = "Chock"
            chock.Size = Vector3.new(1.1, 0.65, 1.1)
            local chockCF = logPart.CFrame * CFrame.new(offsetSign, -(cfg.Diameter * 0.35), 0.15)
            chock.CFrame = chockCF * CFrame.Angles(0, math.rad(offsetSign * 6), 0)
            chock.Color = Color3.fromRGB(68, 66, 64)
            chock.Material = Enum.Material.Slate
            chock.Anchored = true
            chock.CanCollide = true

            local chockMesh = Instance.new("SpecialMesh")
            chockMesh.MeshType = Enum.MeshType.Sphere
            chockMesh.Scale = Vector3.new(1.0, 0.6, 1.0)
            chockMesh.Parent = chock

            chock.Parent = trunkModel
        end

        -- 2 Seats per Trunk (8 seats total)
        -- seat.Disabled = true and seat.CanTouch = false prevents auto-sitting!
        local seatSpread = (cfg.Length * 0.24)
        local seatOffsets = { -seatSpread, seatSpread }
        for sIdx, sOffset in ipairs(seatOffsets) do
            -- Lowered seat position: sits flush on the exact timber bark surface without floating
            local seatSurfaceY = (cfg.Diameter * 0.50) - 0.22
            local seatPos = (logPart.CFrame * CFrame.new(sOffset, seatSurfaceY, 0)).Position
            local lookTarget = Vector3.new(0, seatPos.Y, 0)
            local seatCF = CFrame.lookAt(seatPos, lookTarget)

            local seat = Instance.new("Seat")
            seat.Name = "Seat_" .. sIdx
            seat.Size = Vector3.new(1.4, 0.05, 1.4)
            seat.CFrame = seatCF
            seat.Transparency = 1
            seat.CanCollide = false
            seat.Anchored = true
            seat.Disabled = true       -- Suppress native Roblox touch-to-sit!
            seat.CanTouch = false       -- Suppress touch event triggers!

            local sitPrompt = Instance.new("ProximityPrompt")
            sitPrompt.Name = "SitPrompt"
            sitPrompt.ActionText = "Sit"
            sitPrompt.ObjectText = "Log Bench"
            sitPrompt.KeyboardKeyCode = Enum.KeyCode.E
            sitPrompt.GamepadKeyCode = Enum.KeyCode.ButtonX
            sitPrompt.HoldDuration = 0
            sitPrompt.MaxActivationDistance = 5.5
            sitPrompt.RequiresLineOfSight = false
            sitPrompt.Parent = seat

            if RunService:IsRunning() then
                sitPrompt.Triggered:Connect(function(player: Player)
                    local char = player.Character
                    local hum = char and char:FindFirstChildOfClass("Humanoid")
                    if hum and hum.Health > 0 and seat.Occupant == nil then
                        seat.Disabled = false
                        seat:Sit(hum)
                        sitPrompt.Enabled = false
                    end
                end)

                seat:GetPropertyChangedSignal("Occupant"):Connect(function()
                    if seat.Occupant == nil then
                        seat.Disabled = true
                        sitPrompt.Enabled = true
                    else
                        sitPrompt.Enabled = false
                    end
                end)
            end

            seat.Parent = trunkModel
        end

        trunkModel.Parent = seatsFolder
    end

    seatsFolder.Parent = Workspace
    return seatsFolder
end


-- ---------------------------------------------------------------------------
-- 4. INTERACTION CONTROLLER: TURN ON / TURN OFF
-- ---------------------------------------------------------------------------
function CampfireSystem.SetLit(lit: boolean, playerTriggering: Player?)
    campfireState.IsLit = lit

    if campfireState.Model then
        campfireState.Model:SetAttribute("IsLit", lit)
    end

    if lit then
        -- TURN ON
        if campfireState.Fire then campfireState.Fire.Enabled = true end
        if campfireState.EmberParticles then campfireState.EmberParticles.Enabled = true end
        if campfireState.EmbersCoals then
            campfireState.EmbersCoals.Material = Enum.Material.Neon
            campfireState.EmbersCoals.Color = Color3.fromRGB(220, 60, 14)
        end
        if campfireState.GlowLight then
            campfireState.GlowLight.Enabled = true
            campfireState.GlowLight.Brightness = 1.25
        end
        if RunService:IsRunning() then
            if campfireState.CrackleAudio then
                campfireState.CrackleAudio:Play()
            end
            if campfireState.IgniteAudio then
                campfireState.IgniteAudio:Play()
            end
        end
        if campfireState.MainPrompt then
            campfireState.MainPrompt.ActionText = "Extinguish Fire"
        end

        if playerTriggering then
            sendNotification(
                playerTriggering,
                "Ignited campfire with Matchbox & Wood Log! The sanctuary is safe.",
                "flame",
                Color3.fromRGB(255, 160, 40)
            )
        end
    else
        -- TURN OFF
        if campfireState.Fire then campfireState.Fire.Enabled = false end
        if campfireState.EmberParticles then campfireState.EmberParticles.Enabled = false end
        if campfireState.SmokeParticles then
            campfireState.SmokeParticles:Emit(25)
        end
        if campfireState.EmbersCoals then
            campfireState.EmbersCoals.Material = Enum.Material.Slate
            campfireState.EmbersCoals.Color = Color3.fromRGB(38, 32, 28)
        end
        if campfireState.GlowLight then
            campfireState.GlowLight.Enabled = false
        end
        if RunService:IsRunning() then
            if campfireState.CrackleAudio then
                campfireState.CrackleAudio:Stop()
            end
            if campfireState.DouseAudio then
                campfireState.DouseAudio:Play()
            end
        end
        if campfireState.MainPrompt then
            campfireState.MainPrompt.ActionText = "Light Campfire"
        end

        if playerTriggering then
            sendNotification(
                playerTriggering,
                "Campfire extinguished.",
                "flame",
                Color3.fromRGB(180, 185, 195)
            )
        end
    end
end

function CampfireSystem.SetupInteractions()
    if not RunService:IsRunning() then return end

    local prompt = campfireState.MainPrompt
    if not prompt then return end

    prompt.Triggered:Connect(function(player: Player)
        local InventoryManager = getInventoryManager()

        if campfireState.IsLit then
            CampfireSystem.SetLit(false, player)
        else
            local hasMatches = false
            local hasWood = false
            local woodCount = 0

            if InventoryManager then
                hasMatches = InventoryManager.HasItem(player, "matchbox")
                hasWood, woodCount = InventoryManager.HasItem(player, "standard_wood")
            else
                hasMatches = true
                hasWood = true
                woodCount = 1
            end

            if hasMatches and hasWood and woodCount >= 1 then
                if InventoryManager then
                    InventoryManager.ConsumeItem(player, "standard_wood", 1)
                end
                CampfireSystem.SetLit(true, player)
                if campfireState.Model then
                    campfireState.Model:SetAttribute("Fuel", 120)
                end
            else
                local failMsg = "Requires Matchbox and Wood Logs to ignite!"
                if not hasMatches and not hasWood then
                    failMsg = "You need both a Matchbox and 1 Wood Log to light the campfire!"
                elseif not hasMatches then
                    failMsg = "You need a Matchbox to strike a flame! Grab one from the stone pedestal."
                elseif not hasWood then
                    failMsg = "You need at least 1 Wood Log to light the campfire!"
                end

                sendNotification(player, failMsg, "flame", Color3.fromRGB(255, 95, 75))

                prompt.ActionText = "Needs Matchbox & Wood!"
                task.delay(2.5, function()
                    if not campfireState.IsLit and campfireState.MainPrompt then
                        campfireState.MainPrompt.ActionText = "Light Campfire"
                    end
                end)
            end
        end
    end)
end

-- ---------------------------------------------------------------------------
-- 5. AMBIENT NATURAL LIGHT FLICKER LOOP
-- ---------------------------------------------------------------------------
local flickerConnection: RBXScriptConnection? = nil
local function startFlickerLoop()
    if not RunService:IsRunning() then return end
    if flickerConnection then flickerConnection:Disconnect() end
    flickerConnection = RunService.Heartbeat:Connect(function()
        if campfireState.IsLit and campfireState.GlowLight and campfireState.GlowLight.Enabled then
            local t = os.clock()
            local wave = math.sin(t * 7.5) * 0.08 + math.sin(t * 14.2) * 0.04 + math.cos(t * 22.0) * 0.03
            campfireState.GlowLight.Brightness = math.clamp(1.22 + wave, 1.05, 1.40)
            campfireState.GlowLight.Range = 36.0 + (wave * 3.5)
        end
    end)
end

local wiredSeats: { [Seat]: boolean } = {}
local interactionsWired = false

-- Wire up existing models (permanent editor campsite models)
local function wireExistingModels(): boolean
    -- Remove obsolete wood rack if present
    local obsoleteWoodStack = Workspace:FindFirstChild("CampFirewoodStack")
    if obsoleteWoodStack then
        obsoleteWoodStack:Destroy()
    end

    local existingCampfire = Workspace:FindFirstChild("Campfire") :: Model?
    local existingSeats = Workspace:FindFirstChild("CampfireSeats") :: Folder?

    if existingCampfire then
        campfireState.Model = existingCampfire
        campfireState.FirePart = existingCampfire.PrimaryPart or existingCampfire:FindFirstChild("FirePart") :: BasePart?

        if campfireState.FirePart then
            campfireState.Fire = campfireState.FirePart:FindFirstChild("Flame") :: Fire?
            campfireState.EmberParticles = campfireState.FirePart:FindFirstChild("EmberParticles") :: ParticleEmitter?
            campfireState.SmokeParticles = campfireState.FirePart:FindFirstChild("SmokeParticles") :: ParticleEmitter?
            campfireState.GlowLight = campfireState.FirePart:FindFirstChild("CampfireGlow") :: PointLight?
            campfireState.CrackleAudio = campfireState.FirePart:FindFirstChild("CrackleLoop") :: Sound?
            campfireState.IgniteAudio = campfireState.FirePart:FindFirstChild("IgniteSound") :: Sound?
            campfireState.DouseAudio = campfireState.FirePart:FindFirstChild("DouseSound") :: Sound?

            for _, child in ipairs(campfireState.FirePart:GetChildren()) do
                if child:IsA("ProximityPrompt") and child.Name ~= "CampfireTogglePrompt" then
                    child:Destroy()
                end
            end

            local existingPrompt = campfireState.FirePart:FindFirstChild("CampfireTogglePrompt") :: ProximityPrompt?
            if not existingPrompt then
                existingPrompt = Instance.new("ProximityPrompt")
                existingPrompt.Name = "CampfireTogglePrompt"
                existingPrompt.ActionText = existingCampfire:GetAttribute("IsLit") == false and "Light Campfire" or "Extinguish Fire"
                existingPrompt.ObjectText = "CAMPFIRE"
                existingPrompt.KeyboardKeyCode = Enum.KeyCode.E
                existingPrompt.GamepadKeyCode = Enum.KeyCode.ButtonX
                existingPrompt.HoldDuration = 0.35
                existingPrompt.MaxActivationDistance = 8.5
                existingPrompt.RequiresLineOfSight = false
                existingPrompt.Parent = campfireState.FirePart
            end
            campfireState.MainPrompt = existingPrompt
        end

        campfireState.EmbersCoals = existingCampfire:FindFirstChild("EmbersBed") :: BasePart?
    end

    if existingSeats then
        for _, trunk in ipairs(existingSeats:GetChildren()) do
            local logPart = trunk:FindFirstChild("Log") :: BasePart?
            local logDiameter = (logPart and logPart.Size.Y) or 2.4

            for _, child in ipairs(trunk:GetChildren()) do
                if child:IsA("Seat") then
                    -- Lower seat position and minimize height so avatar sits cleanly on log surface
                    child.Size = Vector3.new(1.4, 0.05, 1.4)
                    if logPart then
                        local sOffsetSign = (child.Name == "Seat_1") and -1 or 1
                        local seatSpread = (logPart.Size.X * 0.24)
                        local seatSurfaceY = (logDiameter * 0.50) - 0.22
                        local seatPos = (logPart.CFrame * CFrame.new(sOffsetSign * seatSpread, seatSurfaceY, 0)).Position
                        local lookTarget = Vector3.new(0, seatPos.Y, 0)
                        child.CFrame = CFrame.lookAt(seatPos, lookTarget)
                    end

                    child.Disabled = true
                    child.CanTouch = false

                    local prompt = child:FindFirstChild("SitPrompt") :: ProximityPrompt?
                    if not prompt then
                        prompt = Instance.new("ProximityPrompt")
                        prompt.Name = "SitPrompt"
                        prompt.ActionText = "Sit"
                        prompt.ObjectText = "Log Bench"
                        prompt.KeyboardKeyCode = Enum.KeyCode.E
                        prompt.GamepadKeyCode = Enum.KeyCode.ButtonX
                        prompt.HoldDuration = 0
                        prompt.MaxActivationDistance = 5.5
                        prompt.RequiresLineOfSight = false
                        prompt.Parent = child
                    end

                    if RunService:IsRunning() and not wiredSeats[child] then
                        wiredSeats[child] = true
                        prompt.Triggered:Connect(function(player: Player)
                            local char = player.Character
                            local hum = char and char:FindFirstChildOfClass("Humanoid")
                            if hum and hum.Health > 0 and child.Occupant == nil then
                                child.Disabled = false
                                child:Sit(hum)
                                prompt.Enabled = false
                            end
                        end)
                        child:GetPropertyChangedSignal("Occupant"):Connect(function()
                            if child.Occupant == nil then
                                child.Disabled = true
                                prompt.Enabled = true
                            else
                                prompt.Enabled = false
                            end
                        end)
                    end
                end
            end
        end
    end

    if RunService:IsRunning() then
        if not interactionsWired then
            interactionsWired = true
            CampfireSystem.SetupInteractions()
        end
        startFlickerLoop()
    end

    return (existingCampfire ~= nil and existingSeats ~= nil)
end

-- ---------------------------------------------------------------------------
-- 6. MASTER INITIALIZATION
-- ---------------------------------------------------------------------------
function CampfireSystem.Initialize(): (Model, Folder)
    -- 1. Obtain or fallback-build permanent campsite models (never destroy existing)
    local campModel = CampfireSystem.BuildCampfire()
    local seatsFolder = CampfireSystem.BuildSittingTrunks()

    -- 2. Clean up any obsolete wood stack model
    local obsoleteWoodStack = Workspace:FindFirstChild("CampFirewoodStack")
    if obsoleteWoodStack then
        obsoleteWoodStack:Destroy()
    end

    -- 3. Wire up all runtime interaction listeners, prompts, flicker loops
    wireExistingModels()

    print("[CampfireSystem] Initialized permanent campfire and seating.")
    return campModel, seatsFolder
end

return CampfireSystem
