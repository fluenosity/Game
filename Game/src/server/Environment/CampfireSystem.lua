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

    -- Stylized Flame Particle Emitter (Avoids legacy Fire engine wav lookup)
    local flameEmitter = Instance.new("ParticleEmitter")
    flameEmitter.Name = "Flame"
    flameEmitter.Texture = "rbxasset://textures/particles/fire_main.dds"
    flameEmitter.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0.0, Color3.fromRGB(255, 230, 110)),
        ColorSequenceKeypoint.new(0.4, Color3.fromRGB(255, 140, 32)),
        ColorSequenceKeypoint.new(1.0, Color3.fromRGB(215, 45, 14)),
    })
    flameEmitter.Size = NumberSequence.new({
        NumberSequenceKeypoint.new(0.0, 1.2),
        NumberSequenceKeypoint.new(0.5, 2.2),
        NumberSequenceKeypoint.new(1.0, 0.4),
    })
    flameEmitter.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0.0, 0.1),
        NumberSequenceKeypoint.new(0.7, 0.3),
        NumberSequenceKeypoint.new(1.0, 1.0),
    })
    flameEmitter.Lifetime = NumberRange.new(0.6, 1.1)
    flameEmitter.Rate = 28
    flameEmitter.Speed = NumberRange.new(2.8, 5.2)
    flameEmitter.SpreadAngle = Vector2.new(15, 15)
    flameEmitter.Acceleration = Vector3.new(0, 4.0, 0)
    flameEmitter.LightEmission = 0.9
    flameEmitter.Enabled = true
    flameEmitter.Parent = firePart
    campfireState.Fire = flameEmitter

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
    crackle.SoundId = "rbxassetid://150367086"
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
    igniteSound.SoundId = "rbxassetid://9114446852"
    igniteSound.Volume = 0.85
    igniteSound.Parent = firePart
    campfireState.IgniteAudio = igniteSound

    -- Douse Sound
    local douseSound = Instance.new("Sound")
    douseSound.Name = "DouseSound"
    douseSound.SoundId = "rbxassetid://9114446852"
    douseSound.Volume = 0.70
    douseSound.Parent = firePart
    campfireState.DouseAudio = douseSound

    -- 6. SINGLE CLEAN INTERACTIVE PROXIMITY PROMPT
    local prompt = Instance.new("ProximityPrompt")
    prompt.Name = "CampfireTogglePrompt"
    prompt.ActionText = "Extinguish Fire"
    prompt.ObjectText = "CAMPFIRE"
    prompt.KeyboardKeyCode = Enum.KeyCode.F
    prompt.GamepadKeyCode = Enum.KeyCode.ButtonY
    prompt.HoldDuration = 0.35
    prompt.MaxActivationDistance = 8.5
    prompt.RequiresLineOfSight = false
    prompt.ClickablePrompt = false
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
    local firePos = Vector3.new(3.0, 10.50, -430.0)
    local trunkSpecs = {
        {
            Name = "NorthTrunk",
            Center = Vector3.new(3.0, 11.55, -440.0),
            AngleY = 0,
            SeatAxis = "X",
            SeatOffsets = { -1.8, 1.8 },
            Size = Vector3.new(10.0, 2.3, 2.5),
        },
        {
            Name = "SouthTrunk",
            Center = Vector3.new(3.0, 11.55, -420.0),
            AngleY = 180,
            SeatAxis = "X",
            SeatOffsets = { -1.8, 1.8 },
            Size = Vector3.new(10.2, 2.3, 2.5),
        },
        {
            Name = "EastTrunk",
            Center = Vector3.new(13.0, 11.60, -430.0),
            AngleY = 90,
            SeatAxis = "Z",
            SeatOffsets = { -1.8, 1.8 },
            Size = Vector3.new(10.0, 2.4, 2.6),
        },
        {
            Name = "WestTrunk",
            Center = Vector3.new(-7.0, 11.60, -430.0),
            AngleY = 270,
            SeatAxis = "Z",
            SeatOffsets = { -1.8, 1.8 },
            Size = Vector3.new(10.2, 2.4, 2.6),
        },
    }

    local existingFolder = Workspace:FindFirstChild("CampfireSeats")
    if existingFolder and existingFolder:IsA("Folder") then
        for _, spec in ipairs(trunkSpecs) do
            local trunk = existingFolder:FindFirstChild(spec.Name)
            if trunk then
                local log = trunk:FindFirstChild("Log")
                if log and log:IsA("BasePart") then
                    log.CFrame = CFrame.new(spec.Center) * CFrame.Angles(0, math.rad(spec.AngleY), 0)
                    log.Anchored = true
                end

                local topOfLogY = spec.Center.Y + (spec.Size.Y * 0.50)
                local seatSurfaceY = topOfLogY + 1.415 -- Elevated so avatar hips in StandToSit rest naturally on top of log bark
                local fireOffset = 0.15
                local inwardLook = (spec.SeatAxis == "X")
                    and ((firePos.Z > spec.Center.Z) and Vector3.new(0, 0, 1) or Vector3.new(0, 0, -1))
                    or  ((firePos.X > spec.Center.X) and Vector3.new(1, 0, 0) or Vector3.new(-1, 0, 0))

                for sIdx, sOffset in ipairs(spec.SeatOffsets) do
                    local seat = trunk:FindFirstChild("Seat_" .. sIdx)
                    if seat and seat:IsA("BasePart") then
                        local seatPos: Vector3
                        if spec.SeatAxis == "X" then
                            local zDir = (firePos.Z > spec.Center.Z) and 1 or -1
                            seatPos = Vector3.new(spec.Center.X + sOffset, seatSurfaceY, spec.Center.Z + (fireOffset * zDir))
                        else
                            local xDir = (firePos.X > spec.Center.X) and 1 or -1
                            seatPos = Vector3.new(spec.Center.X + (fireOffset * xDir), seatSurfaceY, spec.Center.Z + sOffset)
                        end
                        seat.CFrame = CFrame.lookAt(seatPos, seatPos + inwardLook)
                        seat.Anchored = true
                        seat.CanCollide = false
                        seat.Disabled = true
                        seat.CanTouch = false
                        CollectionService:AddTag(seat, "CampfireSeat")

                        local prompt = seat:FindFirstChild("SitPrompt")
                        if prompt and prompt:IsA("ProximityPrompt") then
                            prompt.KeyboardKeyCode = Enum.KeyCode.E
                            CollectionService:AddTag(prompt, "CampfireSitPrompt")
                        end
                    end
                end
            end
        end
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

    -- 2. Four Photorealistic Tree-Pack Timber Logs (FallenTree & FallenTreeMossyVar01 from Deadwood_Logs)
    local assets = ReplicatedStorage:FindFirstChild("DontLetTheFireDieAssets") or ServerStorage:FindFirstChild("DontLetTheFireDieAssets")
    local deadwoodFolder = assets and assets:FindFirstChild("Environment") and assets.Environment:FindFirstChild("Deadwood_Logs")
    local templateClean = deadwoodFolder and deadwoodFolder:FindFirstChild("FallenTree")
    local templateMossy = deadwoodFolder and deadwoodFolder:FindFirstChild("FallenTreeMossyVar01")

    local trunkSpecs = {
        {
            Name = "NorthTrunk",
            Template = templateClean,
            Size = Vector3.new(10.0, 2.3, 2.5),
            Center = Vector3.new(3.0, 11.55, -440.0),
            AngleY = 0,
            SeatAxis = "X",
            SeatOffsets = { -1.8, 1.8 },
        },
        {
            Name = "SouthTrunk",
            Template = templateClean,
            Size = Vector3.new(10.2, 2.3, 2.5),
            Center = Vector3.new(3.0, 11.55, -420.0),
            AngleY = 180,
            SeatAxis = "X",
            SeatOffsets = { -1.8, 1.8 },
        },
        {
            Name = "EastTrunk",
            Template = templateMossy,
            Size = Vector3.new(10.0, 2.4, 2.6),
            Center = Vector3.new(13.0, 11.60, -430.0),
            AngleY = 90,
            SeatAxis = "Z",
            SeatOffsets = { -1.8, 1.8 },
        },
        {
            Name = "WestTrunk",
            Template = templateMossy,
            Size = Vector3.new(10.2, 2.4, 2.6),
            Center = Vector3.new(-7.0, 11.60, -430.0),
            AngleY = 270,
            SeatAxis = "Z",
            SeatOffsets = { -1.8, 1.8 },
        },
    }

    local firePos = Vector3.new(3.0, 10.50, -430.0)

    for _, spec in ipairs(trunkSpecs) do
        local trunkModel = Instance.new("Model")
        trunkModel.Name = spec.Name
        CollectionService:AddTag(trunkModel, "IgnoreWoodScanner")

        local logPart: BasePart
        if spec.Template then
            local sourceMesh = spec.Template:FindFirstChildWhichIsA("MeshPart")
            if sourceMesh then
                local cloneMesh = sourceMesh:Clone()
                cloneMesh.Name = "Log"
                cloneMesh.Size = spec.Size
                cloneMesh.CFrame = CFrame.new(spec.Center) * CFrame.Angles(0, math.rad(spec.AngleY), 0)
                cloneMesh.Anchored = true
                cloneMesh.CanCollide = true
                cloneMesh.CastShadow = true
                cloneMesh.Parent = trunkModel
                logPart = cloneMesh
            end
        end

        if not logPart then
            -- Fallback cylinder
            local fallback = Instance.new("Part")
            fallback.Name = "Log"
            fallback.Shape = Enum.PartType.Cylinder
            fallback.Size = spec.Size
            fallback.CFrame = CFrame.new(spec.Center) * CFrame.Angles(0, math.rad(spec.AngleY), 0)
            fallback.Color = Color3.fromRGB(60, 46, 36)
            fallback.Material = Enum.Material.Wood
            fallback.Anchored = true
            fallback.CanCollide = true
            fallback.Parent = trunkModel
            logPart = fallback
        end

        -- 2 Seats per Trunk (8 seats total)
        -- Seats placed flush on top of log bark along upper crest
        local topOfLogY = spec.Center.Y + (spec.Size.Y * 0.50)
        local seatSurfaceY = topOfLogY + 1.415 -- Elevated so avatar hips in StandToSit rest naturally on top of log bark
        local fireOffset = 0.15 -- Centered along upper crest of log
        local inwardLook = (spec.SeatAxis == "X")
            and ((firePos.Z > spec.Center.Z) and Vector3.new(0, 0, 1) or Vector3.new(0, 0, -1))
            or  ((firePos.X > spec.Center.X) and Vector3.new(1, 0, 0) or Vector3.new(-1, 0, 0))

        for sIdx, sOffset in ipairs(spec.SeatOffsets) do
            local seatPos: Vector3
            if spec.SeatAxis == "X" then
                local zDir = (firePos.Z > spec.Center.Z) and 1 or -1
                seatPos = Vector3.new(spec.Center.X + sOffset, seatSurfaceY, spec.Center.Z + (fireOffset * zDir))
            else
                local xDir = (firePos.X > spec.Center.X) and 1 or -1
                seatPos = Vector3.new(spec.Center.X + (fireOffset * xDir), seatSurfaceY, spec.Center.Z + sOffset)
            end

            -- Strict inward facing direction (perpendicular to log bench, directly facing campfire)
            local seatCF = CFrame.lookAt(seatPos, seatPos + inwardLook)

            local seat = Instance.new("Seat")
            seat.Name = "Seat_" .. sIdx
            seat.Size = Vector3.new(1.4, 0.05, 1.4)
            seat.CFrame = seatCF
            seat.Transparency = 1
            seat.CanCollide = false
            seat.Anchored = true
            seat.Disabled = true       -- Suppress native Roblox touch-to-sit!
            seat.CanTouch = false       -- Suppress touch event triggers!
            CollectionService:AddTag(seat, "CampfireSeat")

            local sitPrompt = Instance.new("ProximityPrompt")
            sitPrompt.Name = "SitPrompt"
            sitPrompt.ActionText = "Sit"
            sitPrompt.ObjectText = "Log Bench"
            sitPrompt.KeyboardKeyCode = Enum.KeyCode.E
            sitPrompt.GamepadKeyCode = Enum.KeyCode.ButtonX
            sitPrompt.HoldDuration = 0
            sitPrompt.MaxActivationDistance = 5.5
            sitPrompt.RequiresLineOfSight = false
            sitPrompt.ClickablePrompt = false
            sitPrompt.Parent = seat
            CollectionService:AddTag(sitPrompt, "CampfireSitPrompt")

            if RunService:IsRunning() then
                sitPrompt.Triggered:Connect(function(player: Player)
                    local char = player.Character
                    local hum = char and char:FindFirstChildOfClass("Humanoid")
                    local hrp = char and char:FindFirstChild("HumanoidRootPart")
                    if hum and hum.Health > 0 and seat.Occupant == nil then
                        seat.Disabled = false
                        if hrp then
                            hrp.CFrame = seat.CFrame * CFrame.new(0, seat.Size.Y / 2, 0)
                        end
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
                existingPrompt.KeyboardKeyCode = Enum.KeyCode.F
                existingPrompt.GamepadKeyCode = Enum.KeyCode.ButtonY
                existingPrompt.HoldDuration = 0.35
                existingPrompt.MaxActivationDistance = 8.5
                existingPrompt.RequiresLineOfSight = false
                existingPrompt.ClickablePrompt = false
                existingPrompt.Parent = campfireState.FirePart
            end
            campfireState.MainPrompt = existingPrompt
        end

        campfireState.EmbersCoals = existingCampfire:FindFirstChild("EmbersBed") :: BasePart?
    end

    if existingSeats then
        local trunkConfigs = {
            NorthTrunk = {
                seatSurfaceY = 13.18,
                inwardLook = Vector3.new(0, 0, 1),
                offsets = { -1.8, 1.8 },
                axis = "X",
                center = Vector3.new(3.0, 11.55, -437.4),
                forwardOffset = Vector3.new(0, 0, 0.48),
            },
            SouthTrunk = {
                seatSurfaceY = 13.18,
                inwardLook = Vector3.new(0, 0, -1),
                offsets = { -1.8, 1.8 },
                axis = "X",
                center = Vector3.new(3.0, 11.55, -422.6),
                forwardOffset = Vector3.new(0, 0, -0.48),
            },
            EastTrunk = {
                seatSurfaceY = 13.28,
                inwardLook = Vector3.new(-1, 0, 0),
                offsets = { -1.8, 1.8 },
                axis = "Z",
                center = Vector3.new(10.4, 11.60, -430.0),
                forwardOffset = Vector3.new(-0.48, 0, 0),
            },
            WestTrunk = {
                seatSurfaceY = 13.28,
                inwardLook = Vector3.new(1, 0, 0),
                offsets = { -1.8, 1.8 },
                axis = "Z",
                center = Vector3.new(-4.4, 11.60, -430.0),
                forwardOffset = Vector3.new(0.48, 0, 0),
            },
        }

        for trunkName, cfg in pairs(trunkConfigs) do
            local trunk = existingSeats:FindFirstChild(trunkName)
            if trunk then
                for sIdx, sOffset in ipairs(cfg.offsets) do
                    local child = trunk:FindFirstChild("Seat_" .. sIdx)
                    if child and child:IsA("Seat") then
                        child.Size = Vector3.new(1.4, 0.05, 1.4)
                        local seatPos: Vector3
                        if cfg.axis == "X" then
                            seatPos = Vector3.new(cfg.center.X + sOffset, cfg.seatSurfaceY, cfg.center.Z) + cfg.forwardOffset
                        else
                            seatPos = Vector3.new(cfg.center.X, cfg.seatSurfaceY, cfg.center.Z + sOffset) + cfg.forwardOffset
                        end
                        child.CFrame = CFrame.lookAt(seatPos, seatPos + cfg.inwardLook)
                    end
                end
            end
        end

        for _, trunk in ipairs(existingSeats:GetChildren()) do
            for _, child in ipairs(trunk:GetChildren()) do
                if child:IsA("Seat") then
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
                        prompt.ClickablePrompt = false
                        prompt.Parent = child
                    end

                    if RunService:IsRunning() and not wiredSeats[child] then
                        wiredSeats[child] = true
                        prompt.Triggered:Connect(function(player: Player)
                            local char = player.Character
                            local hum = char and char:FindFirstChildOfClass("Humanoid")
                            local hrp = char and char:FindFirstChild("HumanoidRootPart")
                            if hum and hum.Health > 0 and child.Occupant == nil then
                                child.Disabled = false
                                if hrp then
                                    hrp.CFrame = child.CFrame * CFrame.new(0, child.Size.Y / 2, 0)
                                end
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
