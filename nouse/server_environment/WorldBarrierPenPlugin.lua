--!strict
--[[
    WorldBarrierPenPlugin.lua
    Interactive Click-to-Draw World Boundary Pen Tool for Roblox Studio.
    Developed for "Don't Let the Fire Die" (Fluenosity Studio).
]]

local Workspace = game:GetService("Workspace")
local ChangeHistoryService = game:GetService("ChangeHistoryService")
local CollectionService = game:GetService("CollectionService")

if not plugin then
    return
end

local toolbar = plugin:CreateToolbar("World Boundary")
local toggleBtn = toolbar:CreateButton(
    "Draw Barrier",
    "Click anywhere on the map to draw custom perimeter boundary points",
    "rbxassetid://16898612819"
)

local isDrawing = false
local mouseConnection: RBXScriptConnection? = nil
local pointsList: { Part } = {}

-- Create Floating DockWidget UI
local widgetInfo = DockWidgetPluginGuiInfo.new(
    Enum.InitialDockState.Float,
    false, -- initial enabled
    false, -- override previous state
    320,   -- width
    390,   -- height
    280,   -- min width
    340    -- min height
)

local widget = plugin:CreateDockWidgetPluginGui("WorldBarrierPenWidget_V2", widgetInfo)
widget.Title = "World Barrier Pen"

-- Build UI Frame
local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(1, 0, 1, 0)
mainFrame.BackgroundColor3 = Color3.fromRGB(24, 24, 30)
mainFrame.BorderSizePixel = 0
mainFrame.Parent = widget

local pad = Instance.new("UIPadding")
pad.PaddingTop = UDim.new(0, 12)
pad.PaddingBottom = UDim.new(0, 12)
pad.PaddingLeft = UDim.new(0, 14)
pad.PaddingRight = UDim.new(0, 14)
pad.Parent = mainFrame

local layout = Instance.new("UIListLayout")
layout.FillDirection = Enum.FillDirection.Vertical
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Padding = UDim.new(0, 10)
layout.Parent = mainFrame

-- Title
local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(1, 0, 0, 24)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "WORLD BARRIER PEN"
titleLabel.TextColor3 = Color3.fromRGB(200, 70, 255)
titleLabel.Font = Enum.Font.GothamBold
titleLabel.TextSize = 16
titleLabel.TextXAlignment = Enum.TextXAlignment.Left
titleLabel.LayoutOrder = 1
titleLabel.Parent = mainFrame

-- Status Label
local statusLabel = Instance.new("TextLabel")
statusLabel.Size = UDim2.new(1, 0, 0, 42)
statusLabel.BackgroundColor3 = Color3.fromRGB(34, 34, 42)
statusLabel.TextColor3 = Color3.fromRGB(220, 220, 230)
statusLabel.Font = Enum.Font.GothamMedium
statusLabel.TextSize = 12
statusLabel.TextWrapped = true
statusLabel.Text = "Click 'Start Drawing' then click around the map to drop points."
statusLabel.LayoutOrder = 2
local statusCorner = Instance.new("UICorner")
statusCorner.CornerRadius = UDim.new(0, 6)
statusCorner.Parent = statusLabel
statusLabel.Parent = mainFrame

-- Counter Label
local counterLabel = Instance.new("TextLabel")
counterLabel.Size = UDim2.new(1, 0, 0, 20)
counterLabel.BackgroundTransparency = 1
counterLabel.TextColor3 = Color3.fromRGB(255, 230, 40)
counterLabel.Font = Enum.Font.GothamBold
counterLabel.TextSize = 13
counterLabel.TextXAlignment = Enum.TextXAlignment.Left
counterLabel.Text = "Points Placed: 0"
counterLabel.LayoutOrder = 3
counterLabel.Parent = mainFrame

-- Helper button creator
local function makeButton(text: string, bgColor: Color3, order: number): TextButton
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 0, 38)
    btn.BackgroundColor3 = bgColor
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 13
    btn.Text = text
    btn.LayoutOrder = order
    btn.AutoButtonColor = true
    
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, 6)
    c.Parent = btn
    
    btn.Parent = mainFrame
    return btn
end

local drawBtn = makeButton("▶ Start Drawing Points", Color3.fromRGB(70, 140, 240), 4)
local closeBtn = makeButton("🔄 Close Loop & Build Walls", Color3.fromRGB(45, 175, 95), 5)
local undoBtn = makeButton("↩ Undo Last Point", Color3.fromRGB(220, 150, 40), 6)
local clearBtn = makeButton("🗑 Clear All", Color3.fromRGB(210, 60, 60), 7)

-- Root Container Helper
local function getOrCreateBarrierModel(): Model
    local existing = Workspace:FindFirstChild("WorldBarrier")
    if existing and existing:IsA("Model") then
        return existing
    end
    local model = Instance.new("Model")
    model.Name = "WorldBarrier"
    model:SetAttribute("WallHeight", 160.0)
    model:SetAttribute("WallThickness", 6.0)
    model:SetAttribute("ShowAerialGuide", true)
    model:SetAttribute("GuideColor", Color3.fromRGB(190, 45, 255))
    model.Parent = Workspace
    return model
end

local function getFolder(parent: Instance, name: string): Folder
    local f = parent:FindFirstChild(name)
    if not f or not f:IsA("Folder") then
        f = Instance.new("Folder")
        f.Name = name
        f.Parent = parent
    end
    return f :: Folder
end

local function updateUI()
    counterLabel.Text = string.format("Points Placed: %d", #pointsList)
    if isDrawing then
        statusLabel.Text = "🟢 PEN ACTIVE: Click on the terrain to drop boundary points."
        drawBtn.Text = "⏹ Pause Drawing"
        drawBtn.BackgroundColor3 = Color3.fromRGB(160, 80, 200)
    else
        statusLabel.Text = (#pointsList > 0)
            and "Drawing paused. Click 'Close Loop & Build Walls' to complete."
            or "Click 'Start Drawing' then click around the map to drop points."
        drawBtn.Text = "▶ Start Drawing Points"
        drawBtn.BackgroundColor3 = Color3.fromRGB(70, 140, 240)
    end
end

-- Refresh connecting rubber band visualizer
local function refreshRubberBand()
    local barrier = getOrCreateBarrierModel()
    local bandFolder = getFolder(barrier, "AerialRubberBand")
    bandFolder:ClearAllChildren()
    
    local guideColor = barrier:GetAttribute("GuideColor") or Color3.fromRGB(190, 45, 255)
    
    if #pointsList < 2 then return end
    
    for i = 1, #pointsList - 1 do
        local n1 = pointsList[i]
        local n2 = pointsList[i + 1]
        
        local p1 = n1.Position
        local p2 = n2.Position
        local dx = p2.X - p1.X
        local dz = p2.Z - p1.Z
        local length = math.sqrt(dx * dx + dz * dz)
        
        local forward = Vector3.new(dx, 0, dz).Unit
        local up = Vector3.new(0, 1, 0)
        local right = up:Cross(forward).Unit
        local mid = (p1 + p2) * 0.5
        
        local band = Instance.new("Part")
        band.Name = string.format("Band_%d_%d", i, i + 1)
        band.Size = Vector3.new(length, 6.0, 6.0)
        band.Material = Enum.Material.Neon
        band.Color = guideColor
        band.Anchored = true
        band.CanCollide = false
        band.CanTouch = false
        band.CanQuery = false
        band.CastShadow = false
        band.CFrame = CFrame.fromMatrix(mid, forward, up, -right)
        band.Parent = bandFolder
        
        -- Beam
        local a1 = n1:FindFirstChild("BandAttachment") :: Attachment?
        local a2 = n2:FindFirstChild("BandAttachment") :: Attachment?
        if a1 and a2 then
            local beam = Instance.new("Beam")
            beam.Name = string.format("Beam_%d_%d", i, i + 1)
            beam.Attachment0 = a1
            beam.Attachment1 = a2
            beam.Width0 = 8.0
            beam.Width1 = 8.0
            beam.Color = ColorSequence.new(guideColor)
            beam.FaceCamera = true
            beam.LightEmission = 1.0
            beam.LightInfluence = 0.0
            beam.Parent = bandFolder
        end
    end
end

-- Raycast ground elevation
local function getGroundElevation(x: number, z: number): number
    local rayOrigin = Vector3.new(x, 350, z)
    local rayDir = Vector3.new(0, -500, 0)
    local rayParams = RaycastParams.new()
    rayParams.FilterType = Enum.RaycastFilterType.Include
    rayParams.FilterDescendantsInstances = { Workspace.Terrain }
    local hit = Workspace:Raycast(rayOrigin, rayDir, rayParams)
    return hit and hit.Position.Y or 10.0
end

-- Add point at world position
local function addPoint(worldPos: Vector3)
    local barrier = getOrCreateBarrierModel()
    local nodesFolder = getFolder(barrier, "Nodes")
    
    local idx = #pointsList + 1
    local gy = getGroundElevation(worldPos.X, worldPos.Z)
    local floatY = gy + 22.0
    
    local node = Instance.new("Part")
    node.Name = string.format("Node_%02d", idx)
    node.Shape = Enum.PartType.Ball
    node.Size = Vector3.new(16, 16, 16)
    node.Material = Enum.Material.Neon
    node.Color = Color3.fromRGB(255, 230, 40)
    node.Anchored = true
    node.CanCollide = false
    node.CanTouch = false
    node.CanQuery = true
    node.CastShadow = false
    node.Position = Vector3.new(worldPos.X, floatY, worldPos.Z)
    
    -- Tether to ground
    local tether = Instance.new("Part")
    tether.Name = "Tether"
    tether.Size = Vector3.new(1.4, floatY - gy, 1.4)
    tether.Position = Vector3.new(worldPos.X, (floatY + gy) * 0.5, worldPos.Z)
    tether.Anchored = true
    tether.CanCollide = false
    tether.CanTouch = false
    tether.CanQuery = false
    tether.Color = Color3.fromRGB(255, 230, 40)
    tether.Material = Enum.Material.Neon
    tether.Transparency = 0.4
    tether.Parent = node
    
    -- Aerial Label
    local bb = Instance.new("BillboardGui")
    bb.Name = "AerialLabel"
    bb.Size = UDim2.new(0, 90, 0, 32)
    bb.StudsOffset = Vector3.new(0, 10, 0)
    bb.AlwaysOnTop = true
    bb.MaxDistance = 5000
    
    local txt = Instance.new("TextLabel")
    txt.Size = UDim2.new(1, 0, 1, 0)
    txt.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
    txt.BackgroundTransparency = 0.15
    txt.TextColor3 = Color3.fromRGB(255, 255, 255)
    txt.Font = Enum.Font.GothamBold
    txt.TextSize = 14
    txt.Text = string.format("[%d]", idx)
    txt.Parent = bb
    
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, 6)
    c.Parent = txt
    
    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(190, 45, 255)
    stroke.Thickness = 2
    stroke.Parent = txt
    
    bb.Parent = node
    
    local att = Instance.new("Attachment")
    att.Name = "BandAttachment"
    att.Parent = node
    
    node.Parent = nodesFolder
    table.insert(pointsList, node)
    
    refreshRubberBand()
    updateUI()
    print(string.format("[WorldBarrierPen] Placed Node_%02d at (%.1f, %.1f, %.1f)", idx, worldPos.X, floatY, worldPos.Z))
    ChangeHistoryService:SetWaypoint("Drop Boundary Point")
end

-- Close loop and generate collision barrier walls
local function closeLoopAndBuildWalls()
    if #pointsList < 3 then
        statusLabel.Text = "⚠️ Need at least 3 points to build a closed boundary!"
        return
    end
    
    local barrier = getOrCreateBarrierModel()
    local wallsFolder = getFolder(barrier, "CollisionWalls")
    local bandFolder = getFolder(barrier, "AerialRubberBand")
    wallsFolder:ClearAllChildren()
    bandFolder:ClearAllChildren()
    
    local wallHeight = barrier:GetAttribute("WallHeight") or 160.0
    local wallThickness = barrier:GetAttribute("WallThickness") or 6.0
    local guideColor = barrier:GetAttribute("GuideColor") or Color3.fromRGB(190, 45, 255)
    
    for i = 1, #pointsList do
        local n1 = pointsList[i]
        local nextIdx = (i % #pointsList) + 1
        local n2 = pointsList[nextIdx]
        
        local p1 = n1.Position
        local p2 = n2.Position
        
        local g1 = getGroundElevation(p1.X, p1.Z)
        local g2 = getGroundElevation(p2.X, p2.Z)
        
        local midX = (p1.X + p2.X) * 0.5
        local midZ = (p1.Z + p2.Z) * 0.5
        local groundMidY = (g1 + g2) * 0.5
        local midY = groundMidY + (wallHeight * 0.5) - 20.0
        
        local dx = p2.X - p1.X
        local dz = p2.Z - p1.Z
        local length = math.sqrt(dx * dx + dz * dz) + 2.0
        
        local forward = Vector3.new(dx, 0, dz).Unit
        local up = Vector3.new(0, 1, 0)
        local right = up:Cross(forward).Unit
        
        -- Invisible Collision Wall
        local wall = Instance.new("Part")
        wall.Name = string.format("Wall_%02d_to_%02d", i, nextIdx)
        wall.Size = Vector3.new(length, wallHeight, wallThickness)
        wall.Anchored = true
        wall.CanCollide = true
        wall.CanTouch = true
        wall.CanQuery = false
        wall.CastShadow = false
        wall.Transparency = 1.0
        wall.CFrame = CFrame.fromMatrix(Vector3.new(midX, midY, midZ), forward, up, -right)
        CollectionService:AddTag(wall, "WorldBarrierWall")
        wall.Parent = wallsFolder
        
        -- Aerial Rubber Band segment
        local bandY = (p1.Y + p2.Y) * 0.5
        local band = Instance.new("Part")
        band.Name = string.format("Band_%02d_to_%02d", i, nextIdx)
        band.Size = Vector3.new(length, 6.0, 6.0)
        band.Material = Enum.Material.Neon
        band.Color = guideColor
        band.Anchored = true
        band.CanCollide = false
        band.CanTouch = false
        band.CanQuery = false
        band.CastShadow = false
        band.CFrame = CFrame.fromMatrix(Vector3.new(midX, bandY, midZ), forward, up, -right)
        band.Parent = bandFolder
        
        -- Beam
        local a1 = n1:FindFirstChild("BandAttachment") :: Attachment?
        local a2 = n2:FindFirstChild("BandAttachment") :: Attachment?
        if a1 and a2 then
            local beam = Instance.new("Beam")
            beam.Name = string.format("Beam_%02d_to_%02d", i, nextIdx)
            beam.Attachment0 = a1
            beam.Attachment1 = a2
            beam.Width0 = 8.0
            beam.Width1 = 8.0
            beam.Color = ColorSequence.new(guideColor)
            beam.FaceCamera = true
            beam.LightEmission = 1.0
            beam.LightInfluence = 0.0
            beam.Parent = bandFolder
        end
    end
    
    isDrawing = false
    plugin:Deactivate()
    if mouseConnection then
        mouseConnection:Disconnect()
        mouseConnection = nil
    end
    statusLabel.Text = string.format("✅ Complete! Closed loop built with %d barrier walls.", #pointsList)
    updateUI()
    print(string.format("[WorldBarrierPen] Closed loop built with %d barrier walls!", #pointsList))
    ChangeHistoryService:SetWaypoint("Build Closed World Barrier")
end

-- Undo last point
local function undoLastPoint()
    if #pointsList == 0 then return end
    local lastNode = table.remove(pointsList)
    if lastNode then
        lastNode:Destroy()
    end
    refreshRubberBand()
    updateUI()
    ChangeHistoryService:SetWaypoint("Undo Boundary Point")
end

-- Clear all
local function clearAll()
    local barrier = Workspace:FindFirstChild("WorldBarrier")
    if barrier then
        barrier:Destroy()
    end
    pointsList = {}
    isDrawing = false
    plugin:Deactivate()
    if mouseConnection then
        mouseConnection:Disconnect()
        mouseConnection = nil
    end
    updateUI()
    statusLabel.Text = "Cleared all points. Ready to draw new boundary."
    ChangeHistoryService:SetWaypoint("Clear World Barrier")
end

-- Start / Toggle Drawing Mode
local function toggleDrawing()
    isDrawing = not isDrawing
    if isDrawing then
        -- CRITICAL: Activate plugin for exclusive 3D mouse capture!
        plugin:Activate(true)
        local mouse = plugin:GetMouse()
        mouse.TargetFilter = Workspace:FindFirstChild("WorldBarrier")
        
        if mouseConnection then mouseConnection:Disconnect() end
        mouseConnection = mouse.Button1Down:Connect(function()
            if not isDrawing then return end
            local hit = mouse.Hit
            if hit then
                addPoint(hit.Position)
            end
        end)
    else
        plugin:Deactivate()
        if mouseConnection then
            mouseConnection:Disconnect()
            mouseConnection = nil
        end
    end
    updateUI()
end

plugin.Deactivation:Connect(function()
    isDrawing = false
    if mouseConnection then
        mouseConnection:Disconnect()
        mouseConnection = nil
    end
    updateUI()
end)

drawBtn.MouseButton1Click:Connect(toggleDrawing)
closeBtn.MouseButton1Click:Connect(closeLoopAndBuildWalls)
undoBtn.MouseButton1Click:Connect(undoLastPoint)
clearBtn.MouseButton1Click:Connect(clearAll)

toggleBtn.Click:Connect(function()
    widget.Enabled = not widget.Enabled
end)

-- Load existing nodes if already present in workspace
local existingBarrier = Workspace:FindFirstChild("WorldBarrier")
if existingBarrier then
    local nf = existingBarrier:FindFirstChild("Nodes")
    if nf then
        for _, c in ipairs(nf:GetChildren()) do
            if c:IsA("Part") then
                table.insert(pointsList, c)
            end
        end
        table.sort(pointsList, function(a, b) return a.Name < b.Name end)
        updateUI()
    end
end
