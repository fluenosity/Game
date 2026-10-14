--!strict
-- BuildPermanentCampsite.lua
-- Standalone Studio Command Bar Runner to permanently settle the Campfire,
-- 4 Timber Benches (with lowered flush seats), Stone Pedestal, and Vintage Matchbox.
-- Run directly in Roblox Studio Command Bar (Edit Mode).

local Workspace = game:GetService("Workspace")
local CollectionService = game:GetService("CollectionService")

-- 1. Remove obsolete wood rack (as requested: "wood rack bro remove it")
local oldRack = Workspace:FindFirstChild("CampFirewoodStack")
if oldRack then
    oldRack:Destroy()
end

-- 2. Clear any prior temporary campsite instances
for _, name in ipairs({ "Campfire", "CampfireSeats", "CampMatchbox" }) do
    local existing = Workspace:FindFirstChild(name)
    if existing then
        existing:Destroy()
    end
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

local campGroundY = getGroundHeight(0, 0)

-- =============================================================================
-- A. PERMANENT CAMPFIRE
-- =============================================================================
local campModel = Instance.new("Model")
campModel.Name = "Campfire"
CollectionService:AddTag(campModel, "IgnoreWoodScanner")
campModel:SetAttribute("IsLit", true)
campModel:SetAttribute("Fuel", 120)
campModel:SetAttribute("MaxFuel", 240)

-- 1. Ash Bed
local ashBed = Instance.new("Part")
ashBed.Name = "AshBed"
ashBed.Shape = Enum.PartType.Cylinder
ashBed.Size = Vector3.new(0.4, 5.8, 5.8)
ashBed.CFrame = CFrame.new(0, campGroundY + 0.1, 0) * CFrame.Angles(0, 0, math.rad(90))
ashBed.Color = Color3.fromRGB(22, 18, 16)
ashBed.Material = Enum.Material.Mud
ashBed.Anchored = true
ashBed.CanCollide = true
ashBed.Parent = campModel

-- 2. Neon Embers Bed
local embers = Instance.new("Part")
embers.Name = "EmbersBed"
embers.Shape = Enum.PartType.Cylinder
embers.Size = Vector3.new(0.25, 3.2, 3.2)
embers.CFrame = CFrame.new(0, campGroundY + 0.18, 0) * CFrame.Angles(0, 0, math.rad(90))
embers.Color = Color3.fromRGB(220, 60, 14)
embers.Material = Enum.Material.Neon
embers.Anchored = true
embers.CanCollide = true
embers.Parent = campModel

-- 3. Hearth Stones Ring
local stoneColors = {
    Color3.fromRGB(78, 76, 74),
    Color3.fromRGB(90, 87, 82),
    Color3.fromRGB(66, 64, 62),
    Color3.fromRGB(84, 80, 76),
}
local stoneCount = 14
local ringRadius = 2.65
for i = 1, stoneCount do
    local angle = math.rad((i - 1) * (360 / stoneCount))
    local sx = math.cos(angle) * ringRadius
    local sz = math.sin(angle) * ringRadius
    local stone = Instance.new("Part")
    stone.Name = "HearthStone_" .. i
    stone.Size = Vector3.new(1.15, 0.85, 1.15)
    stone.CFrame = CFrame.new(sx, campGroundY + 0.35, sz) * CFrame.Angles(0, angle, 0)
    stone.Color = stoneColors[(i % #stoneColors) + 1]
    stone.Material = Enum.Material.Slate
    stone.Anchored = true
    stone.CanCollide = true

    local mesh = Instance.new("SpecialMesh")
    mesh.MeshType = Enum.MeshType.Sphere
    mesh.Scale = Vector3.new(1.0, 0.75, 1.0)
    mesh.Parent = stone
    stone.Parent = campModel
end

-- 4. Firewood Logs in Hearth
local logLayers = {
    { Angle = 18,  Len = 3.6, Diam = 0.52, YOff = 0.32, Lean = 5,  Color = Color3.fromRGB(56, 42, 32) },
    { Angle = 74,  Len = 3.4, Diam = 0.48, YOff = 0.34, Lean = -4, Color = Color3.fromRGB(48, 36, 26) },
    { Angle = 138, Len = 3.7, Diam = 0.50, YOff = 0.36, Lean = 6,  Color = Color3.fromRGB(52, 38, 28) },
    { Angle = 42,  Len = 3.3, Diam = 0.46, YOff = 0.62, Lean = -7, Color = Color3.fromRGB(60, 44, 34) },
    { Angle = 106, Len = 3.5, Diam = 0.48, YOff = 0.64, Lean = 8,  Color = Color3.fromRGB(50, 36, 26) },
    { Angle = 162, Len = 3.2, Diam = 0.44, YOff = 0.66, Lean = -6, Color = Color3.fromRGB(54, 40, 30) },
}
for i, cfg in ipairs(logLayers) do
    local log = Instance.new("Part")
    log.Name = "CampfireLog_" .. i
    log.Shape = Enum.PartType.Cylinder
    log.Size = Vector3.new(cfg.Len, cfg.Diam, cfg.Diam)
    log.CFrame = CFrame.new(0, campGroundY + cfg.YOff, 0)
        * CFrame.Angles(0, math.rad(cfg.Angle), 0)
        * CFrame.Angles(math.rad(cfg.Lean), 0, math.rad(90))
    log.Color = cfg.Color
    log.Material = Enum.Material.Wood
    log.Anchored = true
    log.CanCollide = true
    log.Parent = campModel
end

-- 5. FirePart with Visuals, Light, Sound & Single Toggle Prompt
local firePart = Instance.new("Part")
firePart.Name = "FirePart"
firePart.Size = Vector3.new(1.8, 1.8, 1.8)
firePart.CFrame = CFrame.new(0, campGroundY + 1.25, 0)
firePart.Transparency = 1
firePart.CanCollide = false
firePart.Anchored = true
campModel.PrimaryPart = firePart

local flame = Instance.new("Fire")
flame.Name = "Flame"
flame.Color = Color3.fromRGB(255, 140, 25)
flame.SecondaryColor = Color3.fromRGB(200, 45, 10)
flame.Heat = 9
flame.Size = 7.5
flame.Enabled = true
flame.Parent = firePart

local embersEmitter = Instance.new("ParticleEmitter")
embersEmitter.Name = "EmberParticles"
embersEmitter.Color = ColorSequence.new(Color3.fromRGB(255, 180, 50))
embersEmitter.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.20), NumberSequenceKeypoint.new(1, 0.05) })
embersEmitter.Rate = 18
embersEmitter.Lifetime = NumberRange.new(1.6, 2.8)
embersEmitter.Speed = NumberRange.new(3.5, 6.0)
embersEmitter.SpreadAngle = Vector2.new(20, 20)
embersEmitter.EmissionDirection = Enum.NormalId.Top
embersEmitter.Enabled = true
embersEmitter.Parent = firePart

local smokeEmitter = Instance.new("ParticleEmitter")
smokeEmitter.Name = "SmokeParticles"
smokeEmitter.Color = ColorSequence.new(Color3.fromRGB(120, 115, 110))
smokeEmitter.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.4), NumberSequenceKeypoint.new(1, 3.2) })
smokeEmitter.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.7), NumberSequenceKeypoint.new(1, 1.0) })
smokeEmitter.Rate = 0
smokeEmitter.Lifetime = NumberRange.new(2.5, 4.0)
smokeEmitter.Speed = NumberRange.new(2.5, 4.5)
smokeEmitter.EmissionDirection = Enum.NormalId.Top
smokeEmitter.Enabled = true
smokeEmitter.Parent = firePart

local glowLight = Instance.new("PointLight")
glowLight.Name = "CampfireGlow"
glowLight.Color = Color3.fromRGB(255, 160, 60)
glowLight.Brightness = 1.25
glowLight.Range = 36.0
glowLight.Shadows = true
glowLight.Parent = firePart

local crackleAudio = Instance.new("Sound")
crackleAudio.Name = "CrackleLoop"
crackleAudio.SoundId = "rbxassetid://9114223171"
crackleAudio.Looped = true
crackleAudio.Volume = 0.65
crackleAudio.RollOffMode = Enum.RollOffMode.InverseTapered
crackleAudio.RollOffMinDistance = 6
crackleAudio.RollOffMaxDistance = 45
crackleAudio.Parent = firePart

local igniteAudio = Instance.new("Sound")
igniteAudio.Name = "IgniteSound"
igniteAudio.SoundId = "rbxassetid://9114223847"
igniteAudio.Looped = false
igniteAudio.Volume = 0.85
igniteAudio.Parent = firePart

local douseAudio = Instance.new("Sound")
douseAudio.Name = "DouseSound"
douseAudio.SoundId = "rbxassetid://9114224423"
douseAudio.Looped = false
douseAudio.Volume = 0.85
douseAudio.Parent = firePart

local mainPrompt = Instance.new("ProximityPrompt")
mainPrompt.Name = "CampfireTogglePrompt"
mainPrompt.ActionText = "Extinguish Fire"
mainPrompt.ObjectText = "CAMPFIRE"
mainPrompt.KeyboardKeyCode = Enum.KeyCode.E
mainPrompt.GamepadKeyCode = Enum.KeyCode.ButtonX
mainPrompt.HoldDuration = 0.35
mainPrompt.MaxActivationDistance = 8.5
mainPrompt.RequiresLineOfSight = false
mainPrompt.Parent = firePart

firePart.Parent = campModel
campModel.Parent = Workspace

-- =============================================================================
-- B. PERMANENT 4 TIMBER BENCHES (FLUSH SEATS) & STONE PEDESTAL
-- =============================================================================
local seatsFolder = Instance.new("Folder")
seatsFolder.Name = "CampfireSeats"
CollectionService:AddTag(seatsFolder, "IgnoreWoodScanner")

-- 1. Stone Pedestal for Vintage Matchbox at (9.2, -3.8)
local pedGroundY = getGroundHeight(9.2, -3.8)
local pedCenter = Vector3.new(9.2, pedGroundY + 0.60, -3.8)
local pedModel = Instance.new("Model")
pedModel.Name = "MatchboxPedestalModel"
CollectionService:AddTag(pedModel, "IgnoreWoodScanner")

local pedBase = Instance.new("Part")
pedBase.Name = "PedestalBase"
pedBase.Size = Vector3.new(1.8, 1.2, 1.8)
pedBase.CFrame = CFrame.new(pedCenter)
pedBase.Color = Color3.fromRGB(62, 60, 58)
pedBase.Material = Enum.Material.Slate
pedBase.Anchored = true
pedBase.CanCollide = true
pedBase.Parent = pedModel

local pedSlab = Instance.new("Part")
pedSlab.Name = "PedestalSlab"
pedSlab.Size = Vector3.new(2.2, 0.22, 2.2)
pedSlab.CFrame = CFrame.new(pedCenter.X, pedCenter.Y + 0.65, pedCenter.Z)
pedSlab.Color = Color3.fromRGB(86, 82, 78)
pedSlab.Material = Enum.Material.Granite
pedSlab.Anchored = true
pedSlab.CanCollide = true
pedSlab.Parent = pedModel

pedModel.Parent = seatsFolder

-- 2. Four Timber Benches with Lowered Flush Seats
local trunkConfigs = {
    { Name = "NorthEastTrunk", Center = Vector3.new(1.4, 0, -7.2), AngleDeg = -7,  Length = 8.4, Diameter = 2.45, BarkColor = Color3.fromRGB(54, 40, 30) },
    { Name = "SouthEastTrunk", Center = Vector3.new(7.1, 0, 1.6),  AngleDeg = 97,  Length = 7.6, Diameter = 2.35, BarkColor = Color3.fromRGB(48, 36, 26) },
    { Name = "SouthWestTrunk", Center = Vector3.new(-1.2, 0, 7.3), AngleDeg = 173, Length = 8.8, Diameter = 2.50, BarkColor = Color3.fromRGB(56, 42, 32) },
    { Name = "NorthWestTrunk", Center = Vector3.new(-6.9, 0, -2.1),AngleDeg = 263, Length = 7.8, Diameter = 2.30, BarkColor = Color3.fromRGB(50, 38, 28) },
}

for _, cfg in ipairs(trunkConfigs) do
    local trunkModel = Instance.new("Model")
    trunkModel.Name = cfg.Name
    CollectionService:AddTag(trunkModel, "IgnoreWoodScanner")

    local tGroundY = getGroundHeight(cfg.Center.X, cfg.Center.Z)
    local baseCenter = Vector3.new(cfg.Center.X, tGroundY + (cfg.Diameter * 0.44), cfg.Center.Z)
    local baseRot = CFrame.Angles(0, math.rad(cfg.AngleDeg), 0)

    local logPart = Instance.new("Part")
    logPart.Name = "Log"
    logPart.Shape = Enum.PartType.Cylinder
    logPart.Size = Vector3.new(cfg.Length, cfg.Diameter, cfg.Diameter)
    logPart.CFrame = CFrame.new(baseCenter) * baseRot
    logPart.Color = cfg.BarkColor
    logPart.Material = Enum.Material.Wood
    logPart.Anchored = true
    logPart.CanCollide = true
    logPart.Parent = trunkModel

    for _, endSign in ipairs({ -1, 1 }) do
        local cap = Instance.new("Part")
        cap.Name = "LogEndCap"
        cap.Shape = Enum.PartType.Cylinder
        cap.Size = Vector3.new(0.06, cfg.Diameter * 0.94, cfg.Diameter * 0.94)
        cap.CFrame = logPart.CFrame * CFrame.new((cfg.Length / 2) * endSign, 0, 0)
        cap.Color = Color3.fromRGB(152, 118, 86)
        cap.Material = Enum.Material.WoodPlanks
        cap.Anchored = true
        cap.CanCollide = true
        cap.Parent = trunkModel
    end

    for _, offsetSign in ipairs({ -(cfg.Length * 0.32), cfg.Length * 0.32 }) do
        local chock = Instance.new("Part")
        chock.Name = "GroundChock"
        chock.Size = Vector3.new(1.2, 0.7, 1.2)
        chock.CFrame = logPart.CFrame * CFrame.new(offsetSign, -(cfg.Diameter * 0.35), 0.15)
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

    -- 2 Seats per log with LOWERED flush elevation
    local seatSpread = (cfg.Length * 0.24)
    local seatOffsets = { -seatSpread, seatSpread }
    for sIdx, sOffset in ipairs(seatOffsets) do
        -- Positioned directly flush on the top surface of the log
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
        seat.Disabled = true    -- Prevents auto-sitting!
        seat.CanTouch = false    -- Prevents touch-sit!

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

        seat.Parent = trunkModel
    end

    trunkModel.Parent = seatsFolder
end

seatsFolder.Parent = Workspace

-- =============================================================================
-- C. PERMANENT VINTAGE MATCHBOX ON PEDESTAL
-- =============================================================================
local matchboxModel = Instance.new("Model")
matchboxModel.Name = "CampMatchbox"
CollectionService:AddTag(matchboxModel, "IgnoreWoodScanner")

local boxTargetPos = pedSlab.Position + Vector3.new(0, (pedSlab.Size.Y / 2) + 0.20, 0)
local boxCFrame = CFrame.new(boxTargetPos) * CFrame.Angles(0, math.rad(38), 0)

local sleeve = Instance.new("Part")
sleeve.Name = "Sleeve"
sleeve.Size = Vector3.new(1.10, 0.40, 1.65)
sleeve.CFrame = boxCFrame
sleeve.Color = Color3.fromRGB(182, 42, 36)
sleeve.Material = Enum.Material.SmoothPlastic
sleeve.Anchored = true
sleeve.CanCollide = true
sleeve.TopSurface = Enum.SurfaceType.Smooth
sleeve.BottomSurface = Enum.SurfaceType.Smooth
sleeve.Parent = matchboxModel

local surfaceGui = Instance.new("SurfaceGui")
surfaceGui.Name = "VintageLabel"
surfaceGui.Face = Enum.NormalId.Top
surfaceGui.CanvasSize = Vector2.new(400, 600)
surfaceGui.LightInfluence = 0.35
surfaceGui.SizingMode = Enum.SurfaceGuiSizingMode.FixedSize
surfaceGui.Parent = sleeve

local cardFrame = Instance.new("Frame")
cardFrame.Name = "CardFrame"
cardFrame.Size = UDim2.fromScale(1, 1)
cardFrame.BackgroundColor3 = Color3.fromRGB(246, 240, 224)
cardFrame.BorderSizePixel = 0
cardFrame.Parent = surfaceGui

local innerBorder = Instance.new("UIStroke")
innerBorder.Color = Color3.fromRGB(48, 38, 30)
innerBorder.Thickness = 6
innerBorder.Parent = cardFrame

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0.04, 0)
corner.Parent = cardFrame

local titleLabel = Instance.new("TextLabel")
titleLabel.Name = "Title"
titleLabel.Size = UDim2.new(1, -24, 0, 70)
titleLabel.Position = UDim2.new(0, 12, 0, 28)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "★ SAFETY MATCHES ★"
titleLabel.TextColor3 = Color3.fromRGB(175, 35, 28)
titleLabel.Font = Enum.Font.Fondamento
titleLabel.TextSize = 26
titleLabel.TextScaled = true
titleLabel.Parent = cardFrame

local emblem = Instance.new("TextLabel")
emblem.Name = "Emblem"
emblem.Size = UDim2.new(0, 100, 0, 100)
emblem.Position = UDim2.new(0.5, -50, 0.30, 0)
emblem.BackgroundTransparency = 1
emblem.Text = "🔥"
emblem.TextSize = 72
emblem.Parent = cardFrame

local subLabel = Instance.new("TextLabel")
subLabel.Name = "Subtitle"
subLabel.Size = UDim2.new(1, -24, 0, 50)
subLabel.Position = UDim2.new(0, 12, 0.54, 0)
subLabel.BackgroundTransparency = 1
subLabel.Text = "THE SANCTUARY FLAME"
subLabel.TextColor3 = Color3.fromRGB(52, 42, 34)
subLabel.Font = Enum.Font.GothamBold
subLabel.TextSize = 20
subLabel.Parent = cardFrame

local footerLabel = Instance.new("TextLabel")
footerLabel.Name = "Footer"
footerLabel.Size = UDim2.new(1, -24, 0, 40)
footerLabel.Position = UDim2.new(0, 12, 0.84, 0)
footerLabel.BackgroundTransparency = 1
footerLabel.Text = "STRIKE ON BOX • FLUENOSITY"
footerLabel.TextColor3 = Color3.fromRGB(48, 38, 30)
footerLabel.Font = Enum.Font.GothamBold
footerLabel.TextSize = 16
footerLabel.Parent = cardFrame

for _, sideX in ipairs({ -0.56, 0.56 }) do
    local striker = Instance.new("Part")
    striker.Name = "StrikerStrip"
    striker.Size = Vector3.new(0.05, 0.34, 1.60)
    striker.CFrame = sleeve.CFrame * CFrame.new(sideX, 0, 0)
    striker.Color = Color3.fromRGB(46, 38, 34)
    striker.Material = Enum.Material.Slate
    striker.Anchored = true
    striker.CanCollide = false
    striker.Parent = matchboxModel
end

local drawer = Instance.new("Part")
drawer.Name = "Drawer"
drawer.Size = Vector3.new(0.96, 0.32, 0.65)
drawer.CFrame = sleeve.CFrame * CFrame.new(0, 0, 0.72)
drawer.Color = Color3.fromRGB(224, 210, 182)
drawer.Material = Enum.Material.SmoothPlastic
drawer.Anchored = true
drawer.CanCollide = false
drawer.Parent = matchboxModel

local stickOffsets = { -0.32, -0.11, 0.11, 0.32 }
for i, offX in ipairs(stickOffsets) do
    local stick = Instance.new("Part")
    stick.Name = "MatchstickStem_" .. i
    stick.Size = Vector3.new(0.07, 0.07, 0.48)
    stick.CFrame = drawer.CFrame * CFrame.new(offX, 0.05, 0.04)
    stick.Color = Color3.fromRGB(226, 204, 165)
    stick.Material = Enum.Material.Wood
    stick.Anchored = true
    stick.CanCollide = false
    stick.Parent = matchboxModel

    local head = Instance.new("Part")
    head.Name = "MatchHead_" .. i
    head.Shape = Enum.PartType.Ball
    head.Size = Vector3.new(0.13, 0.13, 0.13)
    head.CFrame = stick.CFrame * CFrame.new(0, 0, 0.25)
    head.Color = Color3.fromRGB(215, 34, 26)
    head.Material = Enum.Material.SmoothPlastic
    head.Anchored = true
    head.CanCollide = false
    head.Parent = matchboxModel
end

local matchGlow = Instance.new("PointLight")
matchGlow.Name = "MatchboxGlow"
matchGlow.Color = Color3.fromRGB(255, 195, 75)
matchGlow.Range = 5.5
matchGlow.Brightness = 0.85
matchGlow.Shadows = false
matchGlow.Parent = sleeve

local matchPrompt = Instance.new("ProximityPrompt")
matchPrompt.Name = "MatchboxPrompt"
matchPrompt.ActionText = "Take Matchbox"
matchPrompt.ObjectText = "SAFETY MATCHES"
matchPrompt.KeyboardKeyCode = Enum.KeyCode.E
matchPrompt.GamepadKeyCode = Enum.KeyCode.ButtonX
matchPrompt.HoldDuration = 0.15
matchPrompt.MaxActivationDistance = 4.8
matchPrompt.RequiresLineOfSight = true
matchPrompt.Parent = sleeve

matchboxModel.PrimaryPart = sleeve
matchboxModel.Parent = Workspace

print("[Fluenosity] Successfully settled permanent Campfire, Flush Timber Benches (8 seats), and Vintage Matchbox!")
