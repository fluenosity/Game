--!strict
--[[
    PathSystem.lua
    Production-Grade Woodland Trail & Corridor Mathematics Engine.
    Developed for "Don't Let the Fire Die" (Fluenosity Studio).
    
    Features:
    - Smooth Catmull-Rom sampled polyline trail curves
    - 2-Player width corridors (~10 studs) for clear running without collisions
    - Designated Gameplay Zones:
        1. "WatchtowerNorth" (Path to North Watchtower / Items)
        2. "NorthwestItems" (Path to Northwest cache)
        3. "WestTrail" (Path to West perimeter)
        4. "Day1Wood" (Path to South-Southwest Wood gathering zone & clearing)
        5. "TraderTrail" (Path to Southeast Trader compound & clearing)
        6. "NortheastTrail" (Path to Northeast wilderness)
    - Full Reveribility: When ENABLE_PATHS = false, all queries return 0 / false.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PathSystem = {}

export type PathDefinition = {
    Id: string,
    Name: string,
    Waypoints: { Vector2 },
    Width: number?,
    ClearingCenter: Vector2?,
    ClearingRadius: number?,
    MeanderPhase: number?,
    SeedOffset: number?,
}

-- ---------------------------------------------------------------------------
-- PRE-SAMPLED CURVE GENERATOR (Catmull-Rom Spline + Organic Serpentine Meandering)
-- ---------------------------------------------------------------------------
local function catmullRom(p0: Vector2, p1: Vector2, p2: Vector2, p3: Vector2, t: number): Vector2
    local t2 = t * t
    local t3 = t2 * t
    return 0.5 * (
        (2 * p1) +
        (-p0 + p2) * t +
        (2 * p0 - 5 * p1 + 4 * p2 - p3) * t2 +
        (-p0 + 3 * p1 - 3 * p2 + p3) * t3
    )
end

-- Generates dense polyline segments from waypoints with organic serpentine meandering curves
local function generateDenseSegments(def: PathDefinition, activeCfg: any, stepDist: number): { { a: Vector2, b: Vector2 } }
    local waypoints = def.Waypoints
    local segments: { { a: Vector2, b: Vector2 } } = {}
    local n = #waypoints
    if n < 2 then return segments end

    -- 1. Base Catmull-Rom sample
    local rawPoints: { Vector2 } = {}
    for i = 1, n - 1 do
        local p0 = (i == 1) and waypoints[1] or waypoints[i - 1]
        local p1 = waypoints[i]
        local p2 = waypoints[i + 1]
        local p3 = (i + 2 <= n) and waypoints[i + 2] or waypoints[n]

        local chordDist = (p2 - p1).Magnitude
        local steps = math.max(math.ceil(chordDist / stepDist), 6)
        
        for s = 0, steps - 1 do
            local t = s / steps
            table.insert(rawPoints, catmullRom(p0, p1, p2, p3, t))
        end
    end
    table.insert(rawPoints, waypoints[n])

    local totalCount = #rawPoints
    if totalCount < 2 then return segments end

    -- 2. Compute cumulative arc-length
    local cumulativeDist: { number } = { 0 }
    local totalLength = 0
    for i = 2, totalCount do
        local d = (rawPoints[i] - rawPoints[i - 1]).Magnitude
        totalLength = totalLength + d
        table.insert(cumulativeDist, totalLength)
    end

    if totalLength <= 0.001 then return segments end

    -- 3. Serpentine Meander & Curvature Calculation
    local meanderAmp = (def.MeanderAmplitude ~= nil and def.MeanderAmplitude) or (activeCfg.PATHS and activeCfg.PATHS.MeanderAmplitude) or 16.0
    local wavelength = (def.MeanderWavelength) or (activeCfg.PATHS and activeCfg.PATHS.MeanderWavelength) or 50.0
    local phase = def.MeanderPhase or 0.0
    local seedOffset = def.SeedOffset or 100

    local curvedPoints: { Vector2 } = {}

    for i = 1, totalCount do
        local p = rawPoints[i]
        local s = cumulativeDist[i]
        local progress = s / totalLength

        -- Compute local path tangent and normal
        local prevP = (i == 1) and rawPoints[1] or rawPoints[i - 1]
        local nextP = (i == totalCount) and rawPoints[totalCount] or rawPoints[i + 1]
        local tangent = (nextP - prevP)
        local normal = Vector2.new(0, 0)
        if tangent.Magnitude > 0.001 then
            local tUnit = tangent.Unit
            normal = Vector2.new(-tUnit.Y, tUnit.X)
        end

        -- Smooth hermite envelope: zero deflection at start (camp exit) and end (destination),
        -- full curving deflection throughout the forest trail!
        local envelope = 1.0
        if progress < 0.16 then
            local t = progress / 0.16
            envelope = t * t * (3 - 2 * t)
        elseif progress > 0.84 then
            local t = (1.0 - progress) / 0.16
            envelope = t * t * (3 - 2 * t)
        end

        -- Dual harmonic sinusoidal S-curves + Perlin wandering
        local wave1 = math.sin((s / wavelength) * (math.pi * 2) + phase)
        local wave2 = math.sin((s / (wavelength * 0.52)) * (math.pi * 2) + phase * 1.7) * 0.35
        local wanderNoise = math.noise(p.X * 0.03, p.Y * 0.03, 555 + seedOffset) * 0.55

        local totalLateralShift = (wave1 + wave2 + wanderNoise) * meanderAmp * envelope
        local curvedP = p + (normal * totalLateralShift)
        table.insert(curvedPoints, curvedP)
    end

    for i = 1, #curvedPoints - 1 do
        table.insert(segments, { a = curvedPoints[i], b = curvedPoints[i + 1] })
    end

    return segments
end

-- Calculates squared perpendicular distance from point P to segment AB
local function pointToSegmentDistSq(px: number, pz: number, ax: number, az: number, bx: number, bz: number): number
    local abx = bx - ax
    local abz = bz - az
    local apx = px - ax
    local apz = pz - az
    local abLenSq = abx * abx + abz * abz
    if abLenSq <= 0.0001 then
        return apx * apx + apz * apz
    end
    local t = math.clamp((apx * abx + apz * abz) / abLenSq, 0, 1)
    local projX = ax + t * abx
    local projZ = az + t * abz
    local dx = px - projX
    local dz = pz - projZ
    return dx * dx + dz * dz
end

-- Cached compiled segments
-- Cached compiled segments
local _lastCompiledConfig: any = nil
local _compiledPaths: { { Segments: { { a: Vector2, b: Vector2 } }, Def: PathDefinition } } = {}

local function compilePaths(activeCfg: any)
    _lastCompiledConfig = activeCfg
    if not activeCfg or not activeCfg.ENABLE_PATHS or not activeCfg.PATHS then
        _compiledPaths = {}
        return
    end

    local pathList = activeCfg.PATHS.Definitions or {}
    local defaultClearingRadius = (activeCfg.PATHS and activeCfg.PATHS.BuildClearingRadius) or 15.0
    _compiledPaths = {}

    for _, def in ipairs(pathList) do
        -- Auto-ensure a building space clearing at the terminus of every trail!
        if not def.ClearingCenter and def.Waypoints and #def.Waypoints > 0 then
            def.ClearingCenter = def.Waypoints[#def.Waypoints]
        end
        if not def.ClearingRadius then
            def.ClearingRadius = defaultClearingRadius
        end

        local dense = generateDenseSegments(def, activeCfg, 1.8)
        table.insert(_compiledPaths, {
            Segments = dense,
            Def = def,
        })
    end
end

-- ---------------------------------------------------------------------------
-- PUBLIC API
-- ---------------------------------------------------------------------------

function PathSystem.Compile(activeCfg: any)
    compilePaths(activeCfg)
end

-- Returns the minimum distance from point (x, z) to any path centerline or clearing
function PathSystem.GetMinDistanceToPath(x: number, z: number, activeCfg: any?): (number, boolean, string?)
    if not activeCfg or activeCfg.ENABLE_PATHS == false then
        return math.huge, false, nil
    end

    if _lastCompiledConfig ~= activeCfg or #_compiledPaths == 0 then
        compilePaths(activeCfg)
    end

    local minDist = math.huge
    local inClearing = false
    local matchedId: string? = nil

    for _, pathObj in ipairs(_compiledPaths) do
        local def = pathObj.Def

        -- Check building space clearing at end of path
        if def.ClearingCenter and def.ClearingRadius then
            local dx = x - def.ClearingCenter.X
            local dz = z - def.ClearingCenter.Y
            local distCenter = math.sqrt(dx * dx + dz * dz)
            local distToEdge = distCenter - def.ClearingRadius
            if distToEdge < minDist then
                minDist = math.max(distToEdge, 0)
                matchedId = def.Id
                if distCenter <= def.ClearingRadius then
                    inClearing = true
                end
            end
        end

        -- Check curved path segments
        for _, seg in ipairs(pathObj.Segments) do
            local dSq = pointToSegmentDistSq(x, z, seg.a.X, seg.a.Y, seg.b.X, seg.b.Y)
            if dSq < (minDist * minDist) then
                minDist = math.sqrt(dSq)
                matchedId = def.Id
            end
        end
    end

    return minDist, inClearing, matchedId
end

-- Determines whether a candidate point (x, z) falls within the open trail corridor
-- extraClearance adds a buffer zone (e.g. for tree trunks)
function PathSystem.IsOnPath(x: number, z: number, extraClearance: number?, activeCfg: any?): boolean
    if not activeCfg or activeCfg.ENABLE_PATHS == false then
        return false
    end

    local defaultWidth = (activeCfg.PATHS and activeCfg.PATHS.DefaultPathWidth) or 10.0
    local clearance = extraClearance or 0.0
    local threshold = (defaultWidth * 0.5) + clearance

    local dist, inClearing, _ = PathSystem.GetMinDistanceToPath(x, z, activeCfg)
    if inClearing then
        return true
    end

    return dist <= threshold
end

-- Computes terrain dirt blending weight: 1.0 at trail center, fading to 0.0 at outer edge
function PathSystem.GetPathTerrainWeight(x: number, z: number, activeCfg: any?): number
    if not activeCfg or activeCfg.ENABLE_PATHS == false then
        return 0.0
    end

    local defaultWidth = (activeCfg.PATHS and activeCfg.PATHS.DefaultPathWidth) or 10.0
    local blendMargin = (activeCfg.PATHS and activeCfg.PATHS.BlendMargin) or 3.5
    local coreRadius = defaultWidth * 0.5
    local outerRadius = coreRadius + blendMargin

    local dist, inClearing, _ = PathSystem.GetMinDistanceToPath(x, z, activeCfg)
    if inClearing then
        return 1.0
    end

    if dist <= coreRadius then
        return 1.0
    elseif dist <= outerRadius then
        local t = 1.0 - ((dist - coreRadius) / blendMargin)
        return t * t * (3 - 2 * t) -- Smooth hermite blend
    else
        return 0.0
    end
end

-- Forces recompilation of path curves (called when config reloads)
function PathSystem.InvalidateCache()
    _compiledPaths = {}
end

return PathSystem
