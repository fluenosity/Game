--!strict
--[[
    HUDCompass.lua
    Minimal Top-Center Horizon Tape Compass for "Don't Let the Fire Die".
    Developed for Fluenosity Studio. Matches PUBG / Squad minimal HUD reference.

    Features:
    - Anchored at top-center (UDim2.new(0.5, 0, 0, 10))
    - Completely transparent background (zero heavy boxes, zero background cards)
    - Center indicator chevron/tick (▼) with live digital degree bearing
    - Smooth continuous horizontal sliding tape with Cardinals (N, NE, E, SE, S, SW, W, NW)
    - Minor degree numbers (15, 30, 60, 75, etc.) and 5-degree sub-ticks
    - Soft horizontal edge-fade gradient (UIGradient transparency mask)
    - Pure camera yaw tracking with smooth interpolation on RenderStepped
    - Zero campfire distance indicator (clean minimal view)
]]

local RunService = game:GetService("RunService")

export type HUDCompassInstance = {
    Container: Frame,
    SetVisible: (visible: boolean) -> (),
    Destroy: () -> (),
}

local HUDCompass = {}

function HUDCompass.Create(parent: Instance): HUDCompassInstance
    local VIEWPORT_WIDTH = 440
    local PIXELS_PER_DEG = 1.8
    local CYCLE_WIDTH = 360 * PIXELS_PER_DEG -- 648 px per 360 deg

    -- 1. Root Container anchored at Top-Center (Completely Transparent)
    local root = Instance.new("Frame")
    root.Name = "HUDCompass"
    root.Size = UDim2.fromOffset(VIEWPORT_WIDTH, 36)
    root.Position = UDim2.new(0.5, 0, 0, 10)
    root.AnchorPoint = Vector2.new(0.5, 0)
    root.BackgroundTransparency = 1
    root.BorderSizePixel = 0
    root.ClipsDescendants = true
    root.ZIndex = 50
    root.Parent = parent

    -- Horizontal Edge-Fade Mask (soft fade-out at left and right edges)
    local edgeFade = Instance.new("UIGradient")
    edgeFade.Name = "EdgeFadeMask"
    edgeFade.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0.0, 1.0),
        NumberSequenceKeypoint.new(0.18, 0.0),
        NumberSequenceKeypoint.new(0.82, 0.0),
        NumberSequenceKeypoint.new(1.0, 1.0),
    })
    edgeFade.Parent = root

    -- 2. Center Indicator Reticle (Minimal White Chevron Pointer)
    local pointer = Instance.new("TextLabel")
    pointer.Name = "CenterPointer"
    pointer.Size = UDim2.fromOffset(12, 10)
    pointer.Position = UDim2.new(0.5, 0, 0, 0)
    pointer.AnchorPoint = Vector2.new(0.5, 0)
    pointer.BackgroundTransparency = 1
    pointer.Font = Enum.Font.GothamBold
    pointer.Text = "▼"
    pointer.TextColor3 = Color3.fromRGB(255, 255, 255)
    pointer.TextSize = 9
    pointer.ZIndex = 56
    pointer.Parent = root

    -- Degree readout removed (clean minimal compass, no number clutter)

    -- 3. Sliding Ribbon Track (3 Seamless 360-degree cycles: 0 to 1080 deg)
    local ribbonTrack = Instance.new("Frame")
    ribbonTrack.Name = "RibbonTrack"
    ribbonTrack.Size = UDim2.new(0, CYCLE_WIDTH * 3, 0, 18)
    ribbonTrack.Position = UDim2.new(0.5, 0, 0, 12) -- Shifted up since degree label removed
    ribbonTrack.AnchorPoint = Vector2.new(0, 0)
    ribbonTrack.BackgroundTransparency = 1
    ribbonTrack.ZIndex = 52
    ribbonTrack.Parent = root

    -- Cardinal definitions
    local majorMarkings: { [number]: { label: string, isNorth: boolean, isMajor: boolean } } = {
        [0]   = { label = "N",  isNorth = true,  isMajor = true },
        [45]  = { label = "NE", isNorth = false, isMajor = false },
        [90]  = { label = "E",  isNorth = false, isMajor = true },
        [135] = { label = "SE", isNorth = false, isMajor = false },
        [180] = { label = "S",  isNorth = false, isMajor = true },
        [225] = { label = "SW", isNorth = false, isMajor = false },
        [270] = { label = "W",  isNorth = false, isMajor = true },
        [315] = { label = "NW", isNorth = false, isMajor = false },
    }

    -- Build ribbon elements across 3 cycles (cycle 0, 1, 2)
    for cycle = 0, 2 do
        local cycleOffset = cycle * 360

        -- 1. Major Cardinals & Intercardinals (every 45 deg)
        for deg, data in pairs(majorMarkings) do
            local totalDeg = deg + cycleOffset
            local xPos = totalDeg * PIXELS_PER_DEG

            -- Tick line above text
            local tick = Instance.new("Frame")
            tick.Name = "Tick_" .. data.label .. "_" .. tostring(cycle)
            tick.Size = UDim2.new(0, 1, 0, data.isMajor and 6 or 4)
            tick.Position = UDim2.new(0, xPos, 0, 0)
            tick.AnchorPoint = Vector2.new(0.5, 0)
            tick.BackgroundColor3 = data.isNorth and Color3.fromRGB(255, 75, 75) or Color3.fromRGB(240, 245, 255)
            tick.BackgroundTransparency = data.isNorth and 0.0 or 0.15
            tick.BorderSizePixel = 0
            tick.ZIndex = 53
            tick.Parent = ribbonTrack

            -- Label
            local lbl = Instance.new("TextLabel")
            lbl.Name = "Lbl_" .. data.label .. "_" .. tostring(cycle)
            lbl.Size = UDim2.fromOffset(26, 12)
            lbl.Position = UDim2.new(0, xPos, 0, 6)
            lbl.AnchorPoint = Vector2.new(0.5, 0)
            lbl.BackgroundTransparency = 1
            lbl.Font = Enum.Font.GothamBold
            lbl.Text = data.label
            lbl.TextColor3 = data.isNorth and Color3.fromRGB(255, 75, 75)
                or (data.isMajor and Color3.fromRGB(248, 250, 255) or Color3.fromRGB(195, 205, 220))
            lbl.TextSize = data.isMajor and 11 or 9
            lbl.ZIndex = 53
            lbl.Parent = ribbonTrack
        end

        -- 2. Minor Degree Numbers (every 15 deg, excluding cardinal multiples of 45)
        for deg = 15, 345, 15 do
            if deg % 45 ~= 0 then
                local totalDeg = deg + cycleOffset
                local xPos = totalDeg * PIXELS_PER_DEG

                local tick = Instance.new("Frame")
                tick.Name = "Tick_" .. tostring(deg) .. "_" .. tostring(cycle)
                tick.Size = UDim2.new(0, 1, 0, 4)
                tick.Position = UDim2.new(0, xPos, 0, 0)
                tick.AnchorPoint = Vector2.new(0.5, 0)
                tick.BackgroundColor3 = Color3.fromRGB(175, 185, 200)
                tick.BackgroundTransparency = 0.3
                tick.BorderSizePixel = 0
                tick.ZIndex = 53
                tick.Parent = ribbonTrack

                local lbl = Instance.new("TextLabel")
                lbl.Name = "Num_" .. tostring(deg) .. "_" .. tostring(cycle)
                lbl.Size = UDim2.fromOffset(24, 11)
                lbl.Position = UDim2.new(0, xPos, 0, 5)
                lbl.AnchorPoint = Vector2.new(0.5, 0)
                lbl.BackgroundTransparency = 1
                lbl.Font = Enum.Font.GothamMedium
                lbl.Text = tostring(deg)
                lbl.TextColor3 = Color3.fromRGB(155, 168, 185)
                lbl.TextSize = 8
                lbl.ZIndex = 53
                lbl.Parent = ribbonTrack
            end
        end

        -- 3. Subtle sub-ticks every 5 degrees
        for deg = 5, 355, 5 do
            if deg % 15 ~= 0 then
                local totalDeg = deg + cycleOffset
                local xPos = totalDeg * PIXELS_PER_DEG

                local subTick = Instance.new("Frame")
                subTick.Name = "SubTick_" .. tostring(deg) .. "_" .. tostring(cycle)
                subTick.Size = UDim2.new(0, 1, 0, 2)
                subTick.Position = UDim2.new(0, xPos, 0, 1)
                subTick.AnchorPoint = Vector2.new(0.5, 0)
                subTick.BackgroundColor3 = Color3.fromRGB(130, 140, 155)
                subTick.BackgroundTransparency = 0.55
                subTick.BorderSizePixel = 0
                subTick.ZIndex = 53
                subTick.Parent = ribbonTrack
            end
        end
    end

    ----------------------------------------------------------------------------
    -- 5. SMOOTH CAMERA RUNTIME TRACKING (RenderStepped)
    ----------------------------------------------------------------------------
    local renderConn: RBXScriptConnection? = nil
    local smoothedHeading: number = 0.0

    renderConn = RunService.RenderStepped:Connect(function(deltaTime: number)
        local cam = workspace.CurrentCamera
        if not cam then return end

        local lookVector = cam.CFrame.LookVector
        -- Compass heading: North = -Z (0 deg), East = +X (90 deg), South = +Z (180 deg), West = -X (270 deg)
        local rad = math.atan2(lookVector.X, -lookVector.Z)
        local rawDeg = math.deg(rad)
        if rawDeg < 0 then
            rawDeg = rawDeg + 360
        end

        -- Smooth shortest-path angle catch-up
        local diff = rawDeg - smoothedHeading
        if diff < -180 then
            diff = diff + 360
        elseif diff > 180 then
            diff = diff - 360
        end
        local step = diff * math.clamp(deltaTime * 24.0, 0, 1.0)
        smoothedHeading = (smoothedHeading + step + 360) % 360

        local currentDegRound = math.floor(smoothedHeading + 0.5) % 360

        -- Center ribbon track at middle cycle (cycle 1 = 360 to 720 deg)
        local targetX = math.round((VIEWPORT_WIDTH / 2) - ((360 + smoothedHeading) * PIXELS_PER_DEG))
        ribbonTrack.Position = UDim2.new(0, targetX, 0, 12)
    end)

    return {
        Container = root,
        SetVisible = function(visible: boolean)
            root.Visible = visible
        end,
        Destroy = function()
            if renderConn then
                renderConn:Disconnect()
                renderConn = nil
            end
            root:Destroy()
        end,
    }
end

return HUDCompass
