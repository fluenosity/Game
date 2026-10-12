--!strict
--[[
    HUDCompass.lua
    Ultra-sleek Glassmorphic Top-Aside Survival Compass for "Don't Let the Fire Die".
    Developed for Fluenosity Studio.
    
    Features:
    - Balanced placement at Top-Left (UDim2.new(0, 22, 0, 48)), mirroring HUDTopRightWidget
    - Rotating 2-tone survival needle (crimson North / silver South)
    - Bold cardinal direction badge (N glows crimson, others warm amber/white)
    - Exact 3-digit bearing readout (e.g., 045°)
    - Smooth continuous sliding horizon tape with cardinal points and ticks
    - Campfire Sanctuary beacon indicator with live distance (e.g., 38m)
    - Smooth camera yaw tracking with zero jitter on RenderStepped
]]

local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local sharedFolder = ReplicatedStorage:WaitForChild("FluenosityShared")
local IconPack = require(sharedFolder:WaitForChild("IconPack"))

export type HUDCompassInstance = {
    Container: Frame,
    SetCampfirePosition: (pos: Vector3) -> (),
    SetVisible: (visible: boolean) -> (),
    Destroy: () -> (),
}

local HUDCompass = {}

-- Cardinal direction lookup
local function getCardinalDirection(deg: number): (string, boolean)
    local normalized = (deg % 360 + 360) % 360
    if normalized >= 337.5 or normalized < 22.5 then
        return "N", true
    elseif normalized >= 22.5 and normalized < 67.5 then
        return "NE", false
    elseif normalized >= 67.5 and normalized < 112.5 then
        return "E", false
    elseif normalized >= 112.5 and normalized < 157.5 then
        return "SE", false
    elseif normalized >= 157.5 and normalized < 202.5 then
        return "S", false
    elseif normalized >= 202.5 and normalized < 247.5 then
        return "SW", false
    elseif normalized >= 247.5 and normalized < 292.5 then
        return "W", false
    else
        return "NW", false
    end
end

function HUDCompass.Create(parent: Instance): HUDCompassInstance
    local campfireTarget = Vector3.new(3.0, 10.5, -430.0)

    -- 1. Root Container anchored at Top-Left, matching HUDTopRightWidget style
    local root = Instance.new("Frame")
    root.Name = "HUDCompass"
    root.Size = UDim2.fromOffset(290, 36)
    root.Position = UDim2.new(0, 22, 0, 48) -- Safe offset below Roblox Topbar, top-left aside
    root.AnchorPoint = Vector2.new(0, 0)
    root.BackgroundColor3 = Color3.fromRGB(14, 16, 20)
    root.BackgroundTransparency = 0.28
    root.BorderSizePixel = 0
    root.ZIndex = 50
    root.Parent = parent

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 18)
    corner.Parent = root

    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(255, 255, 255)
    stroke.Transparency = 0.86
    stroke.Thickness = 1
    stroke.Parent = root

    -- Layout
    local layout = Instance.new("UIListLayout")
    layout.FillDirection = Enum.FillDirection.Horizontal
    layout.HorizontalAlignment = Enum.HorizontalAlignment.Left
    layout.VerticalAlignment = Enum.VerticalAlignment.Center
    layout.Padding = UDim.new(0, 8)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Parent = root

    local padding = Instance.new("UIPadding")
    padding.PaddingLeft = UDim.new(0, 10)
    padding.PaddingRight = UDim.new(0, 10)
    padding.Parent = root

    local function createDivider(order: number): Frame
        local div = Instance.new("Frame")
        div.Name = "Divider"
        div.Size = UDim2.new(0, 1, 0, 16)
        div.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        div.BackgroundTransparency = 0.88
        div.BorderSizePixel = 0
        div.LayoutOrder = order
        div.Parent = root
        return div
    end

    -- -------------------------------------------------------------------------
    -- 2. Rotating Compass Rose / Dial Widget
    -- -------------------------------------------------------------------------
    local dialFrame = Instance.new("Frame")
    dialFrame.Name = "DialFrame"
    dialFrame.Size = UDim2.fromOffset(24, 24)
    dialFrame.BackgroundColor3 = Color3.fromRGB(24, 28, 36)
    dialFrame.BackgroundTransparency = 0.4
    dialFrame.BorderSizePixel = 0
    dialFrame.LayoutOrder = 1
    dialFrame.Parent = root

    local dialCorner = Instance.new("UICorner")
    dialCorner.CornerRadius = UDim.new(1, 0)
    dialCorner.Parent = dialFrame

    local dialStroke = Instance.new("UIStroke")
    dialStroke.Color = Color3.fromRGB(255, 255, 255)
    dialStroke.Transparency = 0.82
    dialStroke.Thickness = 1
    dialStroke.Parent = dialFrame

    -- Needle pivot container (rotates)
    local needlePivot = Instance.new("Frame")
    needlePivot.Name = "NeedlePivot"
    needlePivot.Size = UDim2.fromScale(1, 1)
    needlePivot.Position = UDim2.fromScale(0.5, 0.5)
    needlePivot.AnchorPoint = Vector2.new(0.5, 0.5)
    needlePivot.BackgroundTransparency = 1
    needlePivot.Parent = dialFrame

    -- North needle tip (Crimson red)
    local needleNorth = Instance.new("Frame")
    needleNorth.Name = "NorthTip"
    needleNorth.Size = UDim2.new(0, 3, 0, 9)
    needleNorth.Position = UDim2.new(0.5, 0, 0.5, -4)
    needleNorth.AnchorPoint = Vector2.new(0.5, 1)
    needleNorth.BackgroundColor3 = Color3.fromRGB(245, 65, 65)
    needleNorth.BorderSizePixel = 0
    needleNorth.Parent = needlePivot

    local nCorner = Instance.new("UICorner")
    nCorner.CornerRadius = UDim.new(0, 2)
    nCorner.Parent = needleNorth

    -- South needle tip (Silver white)
    local needleSouth = Instance.new("Frame")
    needleSouth.Name = "SouthTip"
    needleSouth.Size = UDim2.new(0, 3, 0, 9)
    needleSouth.Position = UDim2.new(0.5, 0, 0.5, 4)
    needleSouth.AnchorPoint = Vector2.new(0.5, 0)
    needleSouth.BackgroundColor3 = Color3.fromRGB(195, 205, 220)
    needleSouth.BorderSizePixel = 0
    needleSouth.Parent = needlePivot

    local sCorner = Instance.new("UICorner")
    sCorner.CornerRadius = UDim.new(0, 2)
    sCorner.Parent = needleSouth

    -- Center brass pivot pin
    local pivotPin = Instance.new("Frame")
    pivotPin.Name = "PivotPin"
    pivotPin.Size = UDim2.fromOffset(4, 4)
    pivotPin.Position = UDim2.fromScale(0.5, 0.5)
    pivotPin.AnchorPoint = Vector2.new(0.5, 0.5)
    pivotPin.BackgroundColor3 = Color3.fromRGB(255, 205, 80)
    pivotPin.BorderSizePixel = 0
    pivotPin.ZIndex = 5
    pivotPin.Parent = needlePivot

    local pinCorner = Instance.new("UICorner")
    pinCorner.CornerRadius = UDim.new(1, 0)
    pinCorner.Parent = pivotPin

    -- -------------------------------------------------------------------------
    -- 3. Digital Heading & Cardinal Badge
    -- -------------------------------------------------------------------------
    local headingBox = Instance.new("Frame")
    headingBox.Name = "HeadingBox"
    headingBox.Size = UDim2.fromOffset(62, 24)
    headingBox.BackgroundTransparency = 1
    headingBox.LayoutOrder = 2
    headingBox.Parent = root

    local lblCardinal = Instance.new("TextLabel")
    lblCardinal.Name = "LblCardinal"
    lblCardinal.Size = UDim2.new(0, 24, 1, 0)
    lblCardinal.Position = UDim2.new(0, 0, 0, 0)
    lblCardinal.BackgroundTransparency = 1
    lblCardinal.Font = Enum.Font.GothamBold
    lblCardinal.Text = "N"
    lblCardinal.TextColor3 = Color3.fromRGB(255, 80, 80)
    lblCardinal.TextSize = 13
    lblCardinal.TextXAlignment = Enum.TextXAlignment.Center
    lblCardinal.ZIndex = 52
    lblCardinal.Parent = headingBox

    local lblDegree = Instance.new("TextLabel")
    lblDegree.Name = "LblDegree"
    lblDegree.Size = UDim2.new(0, 36, 1, 0)
    lblDegree.Position = UDim2.new(0, 26, 0, 0)
    lblDegree.BackgroundTransparency = 1
    lblDegree.Font = Enum.Font.RobotoMono or Enum.Font.GothamMedium
    lblDegree.Text = "000°"
    lblDegree.TextColor3 = Color3.fromRGB(215, 222, 235)
    lblDegree.TextSize = 12
    lblDegree.TextXAlignment = Enum.TextXAlignment.Left
    lblDegree.ZIndex = 52
    lblDegree.Parent = headingBox

    createDivider(3)

    -- -------------------------------------------------------------------------
    -- 4. Sliding Horizon Compass Mini-Tape (Clipped Viewport)
    -- -------------------------------------------------------------------------
    local tapeViewport = Instance.new("Frame")
    tapeViewport.Name = "TapeViewport"
    tapeViewport.Size = UDim2.fromOffset(102, 22)
    tapeViewport.BackgroundColor3 = Color3.fromRGB(18, 20, 26)
    tapeViewport.BackgroundTransparency = 0.5
    tapeViewport.BorderSizePixel = 0
    tapeViewport.ClipsDescendants = true
    tapeViewport.LayoutOrder = 4
    tapeViewport.Parent = root

    local vpCorner = Instance.new("UICorner")
    vpCorner.CornerRadius = UDim.new(0, 11)
    vpCorner.Parent = tapeViewport

    -- Center reticle pointer tick (chevron down)
    local reticleTick = Instance.new("TextLabel")
    reticleTick.Name = "ReticleTick"
    reticleTick.Size = UDim2.fromOffset(12, 10)
    reticleTick.Position = UDim2.new(0.5, 0, 0, 0)
    reticleTick.AnchorPoint = Vector2.new(0.5, 0)
    reticleTick.BackgroundTransparency = 1
    reticleTick.Font = Enum.Font.GothamBold
    reticleTick.Text = "▼"
    reticleTick.TextColor3 = Color3.fromRGB(255, 185, 65)
    reticleTick.TextSize = 8
    reticleTick.ZIndex = 55
    reticleTick.Parent = tapeViewport

    -- Ribbon Tape Track
    -- Pixels per degree: 1.1 px/deg -> 360 deg = 396 px
    -- We instantiate two 360 cycles so it seamlessly wraps from 0 to 720
    local pixelsPerDeg = 1.1
    local cycleWidth = 360 * pixelsPerDeg

    local ribbonTrack = Instance.new("Frame")
    ribbonTrack.Name = "RibbonTrack"
    ribbonTrack.Size = UDim2.new(0, cycleWidth * 2, 1, 0)
    ribbonTrack.Position = UDim2.new(0.5, 0, 0.5, 0)
    ribbonTrack.AnchorPoint = Vector2.new(0, 0.5)
    ribbonTrack.BackgroundTransparency = 1
    ribbonTrack.ZIndex = 53
    ribbonTrack.Parent = tapeViewport

    -- Build cardinal & intercardinal marks on ribbon (2 cycles: 0 to 720 deg)
    local markings = {
        { deg = 0,   label = "N",  isCardinal = true, isNorth = true },
        { deg = 45,  label = "NE", isCardinal = false },
        { deg = 90,  label = "E",  isCardinal = true },
        { deg = 135, label = "SE", isCardinal = false },
        { deg = 180, label = "S",  isCardinal = true },
        { deg = 225, label = "SW", isCardinal = false },
        { deg = 270, label = "W",  isCardinal = true },
        { deg = 315, label = "NW", isCardinal = false },
    }

    for cycle = 0, 1 do
        local cycleOffset = cycle * 360
        -- Major cardinal points
        for _, m in ipairs(markings) do
            local totalDeg = m.deg + cycleOffset
            local xPos = totalDeg * pixelsPerDeg

            local markLbl = Instance.new("TextLabel")
            markLbl.Name = "Mark_" .. m.label .. "_" .. tostring(cycle)
            markLbl.Size = UDim2.fromOffset(26, 14)
            markLbl.Position = UDim2.new(0, xPos, 0.5, 2)
            markLbl.AnchorPoint = Vector2.new(0.5, 0.5)
            markLbl.BackgroundTransparency = 1
            markLbl.Font = m.isCardinal and Enum.Font.GothamBold or Enum.Font.GothamMedium
            markLbl.Text = m.label
            markLbl.TextColor3 = m.isNorth and Color3.fromRGB(255, 75, 75)
                or (m.isCardinal and Color3.fromRGB(240, 245, 255) or Color3.fromRGB(160, 170, 185))
            markLbl.TextSize = m.isCardinal and 10 or 9
            markLbl.ZIndex = 53
            markLbl.Parent = ribbonTrack

            -- Tick mark above text
            local tick = Instance.new("Frame")
            tick.Name = "Tick"
            tick.Size = UDim2.new(0, 1, 0, m.isCardinal and 5 or 3)
            tick.Position = UDim2.new(0, xPos, 0, 3)
            tick.AnchorPoint = Vector2.new(0.5, 0)
            tick.BackgroundColor3 = m.isNorth and Color3.fromRGB(255, 80, 80) or Color3.fromRGB(180, 190, 205)
            tick.BackgroundTransparency = 0.2
            tick.BorderSizePixel = 0
            tick.ZIndex = 53
            tick.Parent = ribbonTrack
        end

        -- Sub-ticks every 15 degrees
        for subDeg = 15, 345, 15 do
            if subDeg % 45 ~= 0 then
                local totalDeg = subDeg + cycleOffset
                local xPos = totalDeg * pixelsPerDeg
                local subTick = Instance.new("Frame")
                subTick.Name = "SubTick"
                subTick.Size = UDim2.new(0, 1, 0, 2)
                subTick.Position = UDim2.new(0, xPos, 0, 4)
                subTick.AnchorPoint = Vector2.new(0.5, 0)
                subTick.BackgroundColor3 = Color3.fromRGB(140, 150, 165)
                subTick.BackgroundTransparency = 0.5
                subTick.BorderSizePixel = 0
                subTick.ZIndex = 53
                subTick.Parent = ribbonTrack
            end
        end
    end

    createDivider(5)

    -- -------------------------------------------------------------------------
    -- 5. Campfire Sanctuary Beacon (Flame Icon + Distance)
    -- -------------------------------------------------------------------------
    local beaconFrame = Instance.new("Frame")
    beaconFrame.Name = "CampfireBeacon"
    beaconFrame.Size = UDim2.fromOffset(56, 24)
    beaconFrame.BackgroundTransparency = 1
    beaconFrame.LayoutOrder = 6
    beaconFrame.Parent = root

    local beaconLayout = Instance.new("UIListLayout")
    beaconLayout.FillDirection = Enum.FillDirection.Horizontal
    beaconLayout.VerticalAlignment = Enum.VerticalAlignment.Center
    beaconLayout.Padding = UDim.new(0, 4)
    beaconLayout.Parent = beaconFrame

    local flameIcon = IconPack.CreateIcon("flame", 14, Color3.fromRGB(255, 150, 45))
    flameIcon.Name = "BeaconFlame"
    flameIcon.LayoutOrder = 1
    flameIcon.Parent = beaconFrame

    local lblDist = Instance.new("TextLabel")
    lblDist.Name = "LblDist"
    lblDist.Size = UDim2.fromOffset(36, 20)
    lblDist.BackgroundTransparency = 1
    lblDist.Font = Enum.Font.GothamMedium
    lblDist.Text = "0m"
    lblDist.TextColor3 = Color3.fromRGB(255, 195, 110)
    lblDist.TextSize = 11
    lblDist.TextXAlignment = Enum.TextXAlignment.Left
    lblDist.LayoutOrder = 2
    lblDist.ZIndex = 52
    lblDist.Parent = beaconFrame

    -- -------------------------------------------------------------------------
    -- 6. Live RenderStepped Heading Alignment
    -- -------------------------------------------------------------------------
    local renderConn: RBXScriptConnection? = nil
    local smoothedHeading: number = 0.0

    renderConn = RunService.RenderStepped:Connect(function(deltaTime: number)
        local cam = workspace.CurrentCamera
        if not cam then return end

        local lookVector = cam.CFrame.LookVector
        -- Standard compass heading: North = -Z (0 deg), East = +X (90 deg), South = +Z (180 deg), West = -X (270 deg)
        local rad = math.atan2(lookVector.X, -lookVector.Z)
        local rawDeg = math.deg(rad)
        if rawDeg < 0 then
            rawDeg = rawDeg + 360
        end

        -- Smooth frame catch-up (eliminates camera jitter)
        local diff = rawDeg - smoothedHeading
        if diff < -180 then
            diff = diff + 360
        elseif diff > 180 then
            diff = diff - 360
        end
        local step = diff * math.clamp(deltaTime * 24.0, 0, 1.0)
        smoothedHeading = (smoothedHeading + step + 360) % 360

        local currentDegRound = math.floor(smoothedHeading + 0.5) % 360
        local cardinalStr, isNorth = getCardinalDirection(currentDegRound)

        -- Update text readouts
        lblCardinal.Text = cardinalStr
        lblCardinal.TextColor3 = isNorth and Color3.fromRGB(255, 75, 75) or Color3.fromRGB(245, 235, 215)
        lblDegree.Text = string.format("%03d°", currentDegRound)

        -- Rotate survival needle
        -- When facing heading H, North is at -H relative to the camera direction
        needlePivot.Rotation = -smoothedHeading

        -- Slide continuous ribbon track
        -- Center reticle is at 0 px relative to track center; ribbon moves by -heading * pxPerDeg
        local xOffset = -(smoothedHeading * pixelsPerDeg)
        ribbonTrack.Position = UDim2.new(0.5, math.round(xOffset), 0.5, 0)

        -- Update Campfire distance beacon
        local player = Players.LocalPlayer
        if player and player.Character and player.Character.PrimaryPart then
            local pPos = player.Character.PrimaryPart.Position
            local d = (Vector3.new(pPos.X, 0, pPos.Z) - Vector3.new(campfireTarget.X, 0, campfireTarget.Z)).Magnitude
            local distMeters = math.floor(d / 3.57) -- 1 meter ~ 3.57 studs in standard Roblox scale
            lblDist.Text = tostring(distMeters) .. "m"

            -- Subtle warmth glow intensity based on proximity
            if d <= 48 then
                lblDist.TextColor3 = Color3.fromRGB(120, 240, 140) -- Sanctuary green
                flameIcon.ImageColor3 = Color3.fromRGB(120, 240, 140)
            else
                lblDist.TextColor3 = Color3.fromRGB(255, 185, 95)
                flameIcon.ImageColor3 = Color3.fromRGB(255, 150, 45)
            end
        end
    end)

    local instance: HUDCompassInstance = {
        Container = root,
        SetCampfirePosition = function(pos: Vector3)
            campfireTarget = pos
        end,
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

    return instance
end

return HUDCompass
