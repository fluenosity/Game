--!strict
--[[
    TreeFactory.lua
    High-Fidelity Procedural Conifer Tree Factory for "Don't Let the Fire Die".
    Developed for Fluenosity Studio.
    
    V2 Architecture:
    - 5 Distinct Architectural Tree Profiles (NO MORE IDENTICAL CONES!):
      1. Tall Ponderosa / Scots Pine: High bare trunk (50% clear), heavy irregular bough arms with foliage pads
      2. Dense Mountain Spruce: Narrow spire, downward-drooping tiered boughs with jagged radial gaps
      3. Alpine Fir: Balanced pyramidal conifer with broad lower skirts
      4. Woodland Sapling: Crooked slender trunk with delicate young evergreen tufts
      5. Dead Forest Snag: Weathered splintered trunk with bare broken branch stubs (Horror lore)
    - Zero Floating: Explicit RootPivot anchor at Y = 0 snaps flush to terrain
    - Mobile Performance: Trunks collidable, foliage CanCollide = false, CanTouch = false, CanQuery = false
    - Full Template Support: Clones Creator Store meshes if placed in ReplicatedStorage.EnvironmentTemplates
]]

local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")

local EnvironmentConfig = require(ReplicatedStorage:WaitForChild("FluenosityShared"):WaitForChild("EnvironmentConfig"))

local TreeFactory = {}

local function createRng(seed: number)
    local state = seed
    return function(min: number?, max: number?): number
        state = (state * 1664525 + 1013904223) % 4294967296
        local unit = state / 4294967296
        if min and max then
            return min + unit * (max - min)
        elseif min then
            return unit * min
        end
        return unit
    end
end

-- Helper to create the ground root base pivot anchor
local function createRootPivot(model: Model): Part
    local pivot = Instance.new("Part")
    pivot.Name = "RootPivot"
    pivot.Size = Vector3.new(0.2, 0.2, 0.2)
    pivot.Transparency = 1
    pivot.CanCollide = false
    pivot.CanTouch = false
    pivot.CanQuery = false
    pivot.Anchored = true
    pivot.CFrame = CFrame.new(0, 0, 0)
    pivot.Parent = model
    model.PrimaryPart = pivot
    model.WorldPivot = CFrame.new(0, 0, 0)
    return pivot
end

-- Helper to add surface roots snaking into soil
local function addExposedRoots(model: Model, trunkRadius: number, barkColor: Color3, rng: any)
    local count = math.floor(rng(3, 5))
    for r = 1, count do
        local angle = (r / count) * math.pi * 2 + rng(-0.3, 0.3)
        local len = trunkRadius * rng(2.0, 3.2)
        local thick = trunkRadius * rng(0.45, 0.7)
        
        local root = Instance.new("Part")
        root.Name = "ExposedRoot_" .. r
        root.Shape = Enum.PartType.Cylinder
        root.Material = Enum.Material.Wood
        root.Color = barkColor
        root.Size = Vector3.new(len, thick, thick)
        root.Anchored = true
        root.CanCollide = true
        root.CastShadow = false
        
        local cf = CFrame.new(
            math.cos(angle) * (trunkRadius * 0.75),
            thick * 0.15,
            math.sin(angle) * (trunkRadius * 0.75)
        ) * CFrame.Angles(0, -angle, math.rad(-14))
        
        root.CFrame = cf
        root.Parent = model
    end
end

-- ---------------------------------------------------------------------------
-- ARCHETYPE 1: TALL PONDEROSA / SCOTS PINE
-- High bare trunk (lower 50% clear), heavy radiating branch arms with needle clouds
-- ---------------------------------------------------------------------------
local function buildTallPine(speciesCfg: any, seed: number, parentFolder: Instance): Model
    local rng = createRng(seed)
    local model = Instance.new("Model")
    model.Name = "TallPine_" .. tostring(seed)
    createRootPivot(model)
    
    local height = rng(speciesCfg.HeightMin, speciesCfg.HeightMax)
    local trunkRad = rng(speciesCfg.TrunkRadiusMin, speciesCfg.TrunkRadiusMax)
    local crownRad = rng(speciesCfg.CrownRadiusMin, speciesCfg.CrownRadiusMax)
    
    local barkBase = speciesCfg.BarkColors[math.floor(rng(1, #speciesCfg.BarkColors + 0.99))]
    local barkColor = Color3.new(barkBase.R + rng(-0.02, 0.02), barkBase.G + rng(-0.02, 0.02), barkBase.B + rng(-0.02, 0.02))
    
    local folBase = speciesCfg.FoliageColors[math.floor(rng(1, #speciesCfg.FoliageColors + 0.99))]
    local folColor = Color3.new(folBase.R + rng(-0.02, 0.02), folBase.G + rng(-0.02, 0.02), folBase.B + rng(-0.02, 0.02))
    
    -- Trunk: 4 tapered segments with subtle organic lean
    local segCount = 4
    local segH = height / segCount
    local curY = 0
    local curRad = trunkRad
    local leanX = math.rad(rng(-2.0, 2.0))
    local leanZ = math.rad(rng(-2.0, 2.0))
    
    for s = 1, segCount do
        local topRad = curRad * 0.75
        local trunk = Instance.new("Part")
        trunk.Name = "Trunk_" .. s
        trunk.Shape = Enum.PartType.Cylinder
        trunk.Material = Enum.Material.Wood
        trunk.Color = barkColor
        trunk.Size = Vector3.new(segH, curRad * 2, curRad * 2)
        trunk.Anchored = true
        trunk.CanCollide = true
        trunk.CastShadow = true
        
        local rotCF = CFrame.Angles(0, 0, math.rad(90)) * CFrame.Angles(leanX * (s / segCount), 0, leanZ * (s / segCount))
        trunk.CFrame = CFrame.new(0, curY + segH / 2, 0) * rotCF
        trunk.Parent = model
        
        curY = curY + segH
        curRad = topRad
    end
    
    addExposedRoots(model, trunkRad, barkColor, rng)
    
    -- Canopy starts right near the ground (lower 5%): completely conceals the trunk and creates dense backdrop
    local canopyStart = math.max(height * 0.05, 2.2)
    local canopySpan = height - canopyStart
    local tierCount = math.floor(rng(speciesCfg.BranchTiersMin, speciesCfg.BranchTiersMax) + 0.5)
    
    for tier = 1, tierCount do
        local t = (tier - 1) / math.max(tierCount - 1, 1)
        local tierY = canopyStart + (t * canopySpan)
        local tierRad = crownRad * (1 - (t * 0.52)) * rng(0.92, 1.12)
        local tierHeight = (canopySpan / tierCount) * 1.5
        
        -- Dense evergreen mantle around the trunk: buries the trunk inside needles
        local mantle = Instance.new("Part")
        mantle.Name = string.format("PineMantle_%d", tier)
        mantle.Shape = Enum.PartType.Cylinder
        mantle.Material = Enum.Material.LeafyGrass
        mantle.Color = folColor
        local mantleDiam = math.max(tierRad * 0.78, trunkRad * 4.2)
        mantle.Size = Vector3.new(tierHeight, mantleDiam, mantleDiam)
        mantle.Anchored = true
        mantle.CanCollide = false
        mantle.CanTouch = false
        mantle.CanQuery = false
        mantle.CastShadow = true
        mantle.CFrame = CFrame.new(0, tierY, 0) * CFrame.Angles(0, 0, math.rad(90))
        mantle.Parent = model
        
        -- 6 to 8 radiating bough arms spiraling around the trunk
        local boughsInTier = math.floor(rng(6, 8))
        local tierAngleOffset = (tier * 0.6180339887) * math.pi * 2 + rng(-0.15, 0.15)
        
        for b = 1, boughsInTier do
            local boughAngle = tierAngleOffset + (b * (math.pi * 2 / boughsInTier)) + rng(-0.12, 0.12)
            local boughLen = tierRad * rng(0.80, 1.15)
            local boughThickness = trunkRad * 0.38 * (1 - (t * 0.35))
            
            -- Wooden Bough Arm
            local boughArm = Instance.new("Part")
            boughArm.Name = string.format("BoughArm_%d_%d", tier, b)
            boughArm.Shape = Enum.PartType.Cylinder
            boughArm.Material = Enum.Material.Wood
            boughArm.Color = barkColor
            boughArm.Size = Vector3.new(boughLen, boughThickness * 2, boughThickness * 2)
            boughArm.Anchored = true
            boughArm.CanCollide = false
            boughArm.CastShadow = true
            
            local armPitch = math.rad(rng(8, 20))
            local armRot = CFrame.Angles(0, -boughAngle, armPitch)
            local armOrigin = Vector3.new(0, tierY, 0)
            boughArm.CFrame = CFrame.new(armOrigin + (armRot.LookVector * (boughLen * 0.5))) * armRot * CFrame.Angles(0, 0, math.rad(90))
            boughArm.Parent = model
            
            -- 3 Dense Overlapping Leaf Clusters per branch (Inner, Mid, Outer Tip)
            local leafFractions = { 0.38, 0.72, 1.02 }
            for lfIdx, frac in ipairs(leafFractions) do
                local leafPos = armOrigin + (armRot.LookVector * (boughLen * frac))
                local leafSpanX = (boughLen * rng(0.65, 0.95)) * (0.8 + (frac * 0.25))
                local leafSpanZ = (boughLen * rng(0.60, 0.88)) * (0.8 + (frac * 0.25))
                local leafThickness = rng(2.6, 4.2)
                
                local leaf = Instance.new("Part")
                leaf.Name = string.format("Leaves_%d_%d_%d", tier, b, lfIdx)
                leaf.Shape = Enum.PartType.Block
                leaf.Material = Enum.Material.LeafyGrass
                leaf.Color = folColor
                leaf.Size = Vector3.new(leafSpanX, leafThickness, leafSpanZ)
                leaf.Anchored = true
                leaf.CanCollide = false
                leaf.CanTouch = false
                leaf.CanQuery = false
                leaf.CastShadow = (lfIdx >= 2) -- Outer leaves cast shadows, inner saves performance
                
                local droop = math.rad(rng(-16, -6))
                leaf.CFrame = CFrame.new(leafPos) * CFrame.Angles(droop, -boughAngle + rng(-0.2, 0.2), rng(-0.1, 0.1))
                leaf.Parent = model
            end
        end
    end
    
    -- Top Crown Cap
    local topCrown = Instance.new("Part")
    topCrown.Name = "TopCrown"
    topCrown.Shape = Enum.PartType.Block
    topCrown.Material = Enum.Material.LeafyGrass
    topCrown.Color = folColor
    topCrown.Size = Vector3.new(crownRad * 1.3, 3.8, crownRad * 1.3)
    topCrown.Anchored = true
    topCrown.CanCollide = false
    topCrown.CastShadow = true
    topCrown.CFrame = CFrame.new(0, height + 0.9, 0) * CFrame.Angles(0, rng(-math.pi, math.pi), 0)
    topCrown.Parent = model
    
    model.Parent = parentFolder
    return model
end

-- ---------------------------------------------------------------------------
-- ARCHETYPE 2: DENSE MOUNTAIN SPRUCE
-- Narrow spire silhouette, layered downward drooping tiers with radial gaps
-- ---------------------------------------------------------------------------
local function buildSpruce(speciesCfg: any, seed: number, parentFolder: Instance): Model
    local rng = createRng(seed)
    local model = Instance.new("Model")
    model.Name = "MountainSpruce_" .. tostring(seed)
    createRootPivot(model)
    
    local height = rng(speciesCfg.HeightMin, speciesCfg.HeightMax)
    local trunkRad = rng(speciesCfg.TrunkRadiusMin, speciesCfg.TrunkRadiusMax)
    local crownRad = rng(speciesCfg.CrownRadiusMin, speciesCfg.CrownRadiusMax)
    local tiers = math.floor(rng(speciesCfg.BranchTiersMin, speciesCfg.BranchTiersMax) + 0.5)
    
    local barkBase = speciesCfg.BarkColors[math.floor(rng(1, #speciesCfg.BarkColors + 0.99))]
    local barkColor = Color3.new(barkBase.R + rng(-0.02, 0.02), barkBase.G + rng(-0.02, 0.02), barkBase.B + rng(-0.02, 0.02))
    
    local folBase = speciesCfg.FoliageColors[math.floor(rng(1, #speciesCfg.FoliageColors + 0.99))]
    local folColor = Color3.new(folBase.R + rng(-0.02, 0.02), folBase.G + rng(-0.02, 0.02), folBase.B + rng(-0.02, 0.02))
    
    -- Trunk
    local trunk = Instance.new("Part")
    trunk.Name = "SpruceTrunk"
    trunk.Shape = Enum.PartType.Cylinder
    trunk.Material = Enum.Material.Wood
    trunk.Color = barkColor
    trunk.Size = Vector3.new(height, trunkRad * 2, trunkRad * 2)
    trunk.Anchored = true
    trunk.CanCollide = true
    trunk.CastShadow = true
    trunk.CFrame = CFrame.new(0, height / 2, 0) * CFrame.Angles(0, 0, math.rad(90))
    trunk.Parent = model
    
    addExposedRoots(model, trunkRad, barkColor, rng)
    
    -- Spruces start 1.8 studs off the ground with dense sweeping skirts
    local startY = math.max(height * 0.04, 1.8)
    local spanY = height - startY
    
    for tier = 1, tiers do
        local t = (tier - 1) / math.max(tiers - 1, 1)
        local tierY = startY + (t * spanY)
        local tierRadius = crownRad * (1 - (t * 0.74))
        local tierHeight = (spanY / tiers) * 1.5
        
        -- Central foliage core column shielding the trunk
        local core = Instance.new("Part")
        core.Name = string.format("SpruceCore_%d", tier)
        core.Shape = Enum.PartType.Cylinder
        core.Material = Enum.Material.LeafyGrass
        core.Color = folColor
        local coreDiam = math.max(tierRadius * 0.80, trunkRad * 4.2)
        core.Size = Vector3.new(tierHeight, coreDiam, coreDiam)
        core.Anchored = true
        core.CanCollide = false
        core.CanTouch = false
        core.CanQuery = false
        core.CastShadow = true
        core.CFrame = CFrame.new(0, tierY, 0) * CFrame.Angles(0, 0, math.rad(90))
        core.Parent = model
        
        -- 7 to 9 radial sweeping evergreen lobes per tier
        local lobeCount = math.floor(rng(7, 9))
        local tierSpiral = (tier * 0.6180339887) * math.pi * 2
        
        for l = 1, lobeCount do
            local lobeAngle = tierSpiral + (l * (math.pi * 2 / lobeCount)) + rng(-0.15, 0.15)
            
            -- Dual inner + outer cascading leaf shelves
            local fractions = { 0.50, 0.90 }
            for lfIdx, frac in ipairs(fractions) do
                local lobeDist = tierRadius * frac * rng(0.90, 1.10)
                local lobeSizeX = tierRadius * rng(0.80, 1.15) * (0.8 + (frac * 0.25))
                local lobeSizeZ = tierRadius * rng(0.75, 1.05) * (0.8 + (frac * 0.25))
                local lobeHeight = rng(2.4, 3.8)
                
                local lobe = Instance.new("Part")
                lobe.Name = string.format("SpruceLeaves_%d_%d_%d", tier, l, lfIdx)
                lobe.Shape = Enum.PartType.Block
                lobe.Material = Enum.Material.LeafyGrass
                lobe.Color = folColor
                lobe.Size = Vector3.new(lobeSizeX, lobeHeight, lobeSizeZ)
                lobe.Anchored = true
                lobe.CanCollide = false
                lobe.CanTouch = false
                lobe.CanQuery = false
                lobe.CastShadow = (lfIdx == 2)
                
                local droopAngle = math.rad(rng(-18, -8))
                local lobePos = Vector3.new(math.cos(lobeAngle) * lobeDist, tierY, math.sin(lobeAngle) * lobeDist)
                lobe.CFrame = CFrame.new(lobePos) * CFrame.Angles(droopAngle, lobeAngle, 0)
                lobe.Parent = model
            end
        end
    end
    
    -- Sharp spire tip
    local apex = Instance.new("Part")
    apex.Name = "SpruceApex"
    apex.Shape = Enum.PartType.Block
    apex.Material = Enum.Material.LeafyGrass
    apex.Color = folColor
    apex.Size = Vector3.new(trunkRad * 2.4, height * 0.14, trunkRad * 2.4)
    apex.Anchored = true
    apex.CanCollide = false
    apex.CastShadow = true
    apex.CFrame = CFrame.new(0, height + (height * 0.07), 0)
    apex.Parent = model
    
    model.Parent = parentFolder
    return model
end

-- ---------------------------------------------------------------------------
-- ARCHETYPE 3: ALPINE FIR
-- Balanced pyramidal conifer with sweeping lower skirts
-- ---------------------------------------------------------------------------
local function buildAlpineFir(speciesCfg: any, seed: number, parentFolder: Instance): Model
    local rng = createRng(seed)
    local model = Instance.new("Model")
    model.Name = "AlpineFir_" .. tostring(seed)
    createRootPivot(model)
    
    local height = rng(speciesCfg.HeightMin, speciesCfg.HeightMax)
    local trunkRad = rng(speciesCfg.TrunkRadiusMin, speciesCfg.TrunkRadiusMax)
    local crownRad = rng(speciesCfg.CrownRadiusMin, speciesCfg.CrownRadiusMax)
    local tiers = math.floor(rng(speciesCfg.BranchTiersMin, speciesCfg.BranchTiersMax) + 0.5)
    
    local barkBase = speciesCfg.BarkColors[math.floor(rng(1, #speciesCfg.BarkColors + 0.99))]
    local barkColor = Color3.new(barkBase.R + rng(-0.02, 0.02), barkBase.G + rng(-0.02, 0.02), barkBase.B + rng(-0.02, 0.02))
    
    local folBase = speciesCfg.FoliageColors[math.floor(rng(1, #speciesCfg.FoliageColors + 0.99))]
    local folColor = Color3.new(folBase.R + rng(-0.02, 0.02), folBase.G + rng(-0.02, 0.02), folBase.B + rng(-0.02, 0.02))
    
    -- Trunk
    local trunk = Instance.new("Part")
    trunk.Name = "FirTrunk"
    trunk.Shape = Enum.PartType.Cylinder
    trunk.Material = Enum.Material.Wood
    trunk.Color = barkColor
    trunk.Size = Vector3.new(height, trunkRad * 2, trunkRad * 2)
    trunk.Anchored = true
    trunk.CanCollide = true
    trunk.CastShadow = true
    trunk.CFrame = CFrame.new(0, height / 2, 0) * CFrame.Angles(0, 0, math.rad(90))
    trunk.Parent = model
    
    addExposedRoots(model, trunkRad, barkColor, rng)
    
    local startY = math.max(height * 0.04, 1.8)
    local spanY = height - startY
    
    for tier = 1, tiers do
        local t = (tier - 1) / math.max(tiers - 1, 1)
        local tierY = startY + (t * spanY)
        local tierRadius = crownRad * (1 - (t * 0.66))
        local tierHeight = (spanY / tiers) * 1.5
        
        -- Central trunk foliage core shielding
        local core = Instance.new("Part")
        core.Name = string.format("FirCore_%d", tier)
        core.Shape = Enum.PartType.Cylinder
        core.Material = Enum.Material.LeafyGrass
        core.Color = folColor
        local coreDiam = math.max(tierRadius * 0.78, trunkRad * 4.0)
        core.Size = Vector3.new(tierHeight, coreDiam, coreDiam)
        core.Anchored = true
        core.CanCollide = false
        core.CanTouch = false
        core.CanQuery = false
        core.CastShadow = true
        core.CFrame = CFrame.new(0, tierY, 0) * CFrame.Angles(0, 0, math.rad(90))
        core.Parent = model
        
        local boughsInTier = math.floor(rng(6, 8))
        local tierAngleOffset = (tier * 0.6180339887) * math.pi * 2
        
        for b = 1, boughsInTier do
            local bAngle = tierAngleOffset + (b * (math.pi * 2 / boughsInTier)) + rng(-0.12, 0.12)
            local bLen = tierRadius * rng(0.85, 1.15)
            
            -- 3 Dense foliage pads per bough (Inner, Mid, Tip)
            local fractions = { 0.40, 0.75, 1.05 }
            for lfIdx, frac in ipairs(fractions) do
                local padDist = bLen * frac
                local padWidth = (tierRadius * rng(0.75, 1.05)) * (0.8 + (frac * 0.25))
                local padDepth = (tierRadius * rng(0.65, 0.95)) * (0.8 + (frac * 0.25))
                local padHeight = rng(2.4, 3.8)
                
                local boughPad = Instance.new("Part")
                boughPad.Name = string.format("FirLeaves_%d_%d_%d", tier, b, lfIdx)
                boughPad.Shape = Enum.PartType.Block
                boughPad.Material = Enum.Material.LeafyGrass
                boughPad.Color = folColor
                boughPad.Size = Vector3.new(padWidth, padHeight, padDepth)
                boughPad.Anchored = true
                boughPad.CanCollide = false
                boughPad.CanTouch = false
                boughPad.CanQuery = false
                boughPad.CastShadow = (lfIdx >= 2)
                
                local droop = math.rad(rng(-15, -6))
                local bPos = Vector3.new(math.cos(bAngle) * padDist, tierY, math.sin(bAngle) * padDist)
                boughPad.CFrame = CFrame.new(bPos) * CFrame.Angles(droop, -bAngle, 0)
                boughPad.Parent = model
            end
        end
    end
    
    -- Fir Spire Tip
    local spire = Instance.new("Part")
    spire.Name = "FirSpire"
    spire.Shape = Enum.PartType.Block
    spire.Material = Enum.Material.LeafyGrass
    spire.Color = folColor
    spire.Size = Vector3.new(trunkRad * 2.2, height * 0.14, trunkRad * 2.2)
    spire.Anchored = true
    spire.CanCollide = false
    spire.CastShadow = true
    spire.CFrame = CFrame.new(0, height + (height * 0.06), 0)
    spire.Parent = model
    
    model.Parent = parentFolder
    return model
end

-- ---------------------------------------------------------------------------
-- ARCHETYPE 4: UNDERSTORY CONIFER SAPLING
-- Slender crooked young evergreen
-- ---------------------------------------------------------------------------
local function buildSapling(speciesCfg: any, seed: number, parentFolder: Instance): Model
    local rng = createRng(seed)
    local model = Instance.new("Model")
    model.Name = "Sapling_" .. tostring(seed)
    createRootPivot(model)
    
    local height = rng(speciesCfg.HeightMin, speciesCfg.HeightMax)
    local trunkRad = rng(speciesCfg.TrunkRadiusMin, speciesCfg.TrunkRadiusMax)
    local crownRad = rng(speciesCfg.CrownRadiusMin, speciesCfg.CrownRadiusMax)
    
    local barkColor = speciesCfg.BarkColors[1]
    local folColor = speciesCfg.FoliageColors[1]
    
    local leanAngle = math.rad(rng(4, 8))
    local trunk = Instance.new("Part")
    trunk.Name = "SaplingTrunk"
    trunk.Shape = Enum.PartType.Cylinder
    trunk.Material = Enum.Material.Wood
    trunk.Color = barkColor
    trunk.Size = Vector3.new(height, trunkRad * 2, trunkRad * 2)
    trunk.Anchored = true
    trunk.CanCollide = true
    trunk.CastShadow = true
    trunk.CFrame = CFrame.new(0, height / 2, 0) * CFrame.Angles(0, rng(-3.14, 3.14), math.rad(90) + leanAngle)
    trunk.Parent = model
    
    -- 2-3 young foliage branch tufts
    for c = 1, 3 do
        local t = c / 3
        local clump = Instance.new("Part")
        clump.Name = "SaplingTuft_" .. c
        clump.Shape = Enum.PartType.Block
        clump.Material = Enum.Material.LeafyGrass
        clump.Color = folColor
        clump.Size = Vector3.new(crownRad * t * 1.8, 0.5, crownRad * t * 1.4)
        clump.Anchored = true
        clump.CanCollide = false
        clump.CastShadow = true
        clump.CFrame = CFrame.new(0, height * (0.35 + t * 0.65), 0) * CFrame.Angles(math.rad(rng(-8, 8)), rng(-math.pi, math.pi), math.rad(rng(-8, 8)))
        clump.Parent = model
    end
    
    model.Parent = parentFolder
    return model
end

-- ---------------------------------------------------------------------------
-- ARCHETYPE 5: DEAD FOREST SNAG
-- Weathered broken lightning-struck trunk with bare branch stubs (Horror Lore)
-- ---------------------------------------------------------------------------
local function buildDeadSnag(speciesCfg: any, seed: number, parentFolder: Instance): Model
    local rng = createRng(seed)
    local model = Instance.new("Model")
    model.Name = "DeadPineSnag_" .. tostring(seed)
    createRootPivot(model)
    
    local height = rng(speciesCfg.HeightMin, speciesCfg.HeightMax)
    local trunkRad = rng(speciesCfg.TrunkRadiusMin, speciesCfg.TrunkRadiusMax)
    local barkColor = speciesCfg.BarkColors[math.floor(rng(1, #speciesCfg.BarkColors + 0.99))]
    
    -- Main broken trunk
    local trunk = Instance.new("Part")
    trunk.Name = "SnagTrunk"
    trunk.Shape = Enum.PartType.Cylinder
    trunk.Material = Enum.Material.Wood
    trunk.Color = barkColor
    trunk.Size = Vector3.new(height, trunkRad * 2, trunkRad * 2)
    trunk.Anchored = true
    trunk.CanCollide = true
    trunk.CastShadow = true
    trunk.CFrame = CFrame.new(0, height / 2, 0) * CFrame.Angles(0, 0, math.rad(90))
    trunk.Parent = model
    
    addExposedRoots(model, trunkRad, barkColor, rng)
    
    -- 3-5 broken bare branch stubs (No leaves)
    local stubCount = math.floor(rng(3, 5))
    for s = 1, stubCount do
        local stubY = height * rng(0.35, 0.85)
        local stubAngle = (s * 2.1) + rng(-0.3, 0.3)
        local stubLen = trunkRad * rng(1.8, 3.2)
        local stubThick = trunkRad * rng(0.28, 0.45)
        
        local stub = Instance.new("Part")
        stub.Name = "BranchStub_" .. s
        stub.Shape = Enum.PartType.Cylinder
        stub.Material = Enum.Material.Wood
        stub.Color = barkColor
        stub.Size = Vector3.new(stubLen, stubThick * 2, stubThick * 2)
        stub.Anchored = true
        stub.CanCollide = false
        stub.CastShadow = true
        
        local rot = CFrame.Angles(0, -stubAngle, math.rad(rng(-18, 15)))
        stub.CFrame = CFrame.new(Vector3.new(0, stubY, 0) + rot.LookVector * (stubLen * 0.5)) * rot * CFrame.Angles(0, 0, math.rad(90))
        stub.Parent = model
    end
    
    model.Parent = parentFolder
    return model
end

-- ---------------------------------------------------------------------------
-- PUBLIC FACTORY METHODS
-- ---------------------------------------------------------------------------

function TreeFactory.CreateTree(
    speciesName: string?,
    treeSeed: number,
    parentFolder: Instance
): Model?
    local speciesTable = EnvironmentConfig.TREES.Species
    local speciesCfg = (speciesName and speciesTable[speciesName]) or speciesTable.TallPine
    
    -- 1. Check for external Creator Store MeshPart templates
    local templatesFolder = ReplicatedStorage:FindFirstChild("EnvironmentTemplates")
    if templatesFolder then
        local availableTreeTemplates = {}
        for _, child in ipairs(templatesFolder:GetChildren()) do
            if child:IsA("Model") and not child.Name:lower():find("rock") and not child.Name:lower():find("boulder") and not child.Name:lower():find("grass") and not child.Name:lower():find("log") then
                table.insert(availableTreeTemplates, child)
            end
        end
        
        if #availableTreeTemplates > 0 then
            local rng = createRng(treeSeed)
            -- Match specific species name or pick deterministically from available templates
            local meshTemplate = templatesFolder:FindFirstChild(speciesCfg.Name)
                or availableTreeTemplates[math.floor(rng(1, #availableTreeTemplates + 0.99))]
                
            if meshTemplate and meshTemplate:IsA("Model") then
                local clonedTree = meshTemplate:Clone()
                local scaleMul = rng(0.85, 1.25)
                clonedTree:ScaleTo(scaleMul)
                
                for _, descendant in ipairs(clonedTree:GetDescendants()) do
                    if descendant:IsA("BasePart") then
                        descendant.Anchored = true
                        if descendant.Name:lower():find("trunk") or descendant.Name:lower():find("wood") or descendant.Name:lower():find("bark") then
                            descendant.CanCollide = true
                        else
                            descendant.CanCollide = false
                            descendant.CanTouch = false
                            descendant.CanQuery = false
                        end
                    end
                end
                
                clonedTree.Parent = parentFolder
                CollectionService:AddTag(clonedTree, "ChoppableTree")
                return clonedTree
            end
        end
    end
    
    -- 2. Dispatch to specific architectural profile
    local treeModel: Model
    if speciesCfg.Archetype == "TallPine" then
        treeModel = buildTallPine(speciesCfg, treeSeed, parentFolder)
    elseif speciesCfg.Archetype == "Spruce" then
        treeModel = buildSpruce(speciesCfg, treeSeed, parentFolder)
    elseif speciesCfg.Archetype == "Fir" then
        treeModel = buildAlpineFir(speciesCfg, treeSeed, parentFolder)
    elseif speciesCfg.Archetype == "Sapling" then
        treeModel = buildSapling(speciesCfg, treeSeed, parentFolder)
    elseif speciesCfg.Archetype == "DeadSnag" then
        treeModel = buildDeadSnag(speciesCfg, treeSeed, parentFolder)
    else
        treeModel = buildTallPine(speciesCfg, treeSeed, parentFolder)
    end
    
    CollectionService:AddTag(treeModel, "ChoppableTree")
    CollectionService:AddTag(treeModel, "WindSwayTree")
    treeModel:SetAttribute("Seed", treeSeed)
    return treeModel
end

return TreeFactory
