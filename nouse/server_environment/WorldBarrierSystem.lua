--!strict
--[[
    WorldBarrierSystem.lua
    Interactive Elastic Multi-Point Perimeter Barrier System.
    Developed for "Don't Let the Fire Die" (Fluenosity Studio).
    
    Features:
    1. Multi-Point Elastic Polygon (Nodes 01..16):
       - 16 interactive, draggable control nodes around the perimeter
       - Some areas are boxed/straight (Camp, Village, Gas Station, Trader), some are curved (Lake, ridges)
       - The user can click ANY node with the Studio Move Tool (Ctrl+2) and drag it inward/outward!
       
    2. Real-Time Elastic Rubber Band Visualizer:
       - Every node connects to the next using glowing Neon Purple Beams & Rod segments
       - High-visibility from aerial view with numbered billboards ([1] Village, [10] Camp, etc.)
       - Stretches and follows live as you drag nodes in Studio
       
    3. Airtight Invisible Collision Walls:
       - 160-stud tall invisible barrier parts connecting between nodes
       - Transparency = 1, CanCollide = true, CastShadow = false
       - Guarantees players cannot jump, glitch, or walk past into the snowy mountains
       
    4. Auto-Snapping to Node Movements:
       - Run WorldBarrierSystem.UpdateFromNodes() anytime to snap walls to moved nodes
       - Attributes on WorldBarrier model:
         * WallHeight (default 160)
         * WallThickness (default 6)
         * ShowAerialGuide (default true)
         * GuideColor (default Color3.fromRGB(180, 50, 240))
]]

local Workspace = game:GetService("Workspace")
local CollectionService = game:GetService("CollectionService")

local WorldBarrierSystem = {}

-- 16 Default Perimeter Nodes (Balanced for boxed camp/village/trader & curved lake)
local DEFAULT_NODES = {
    { Name = "Node_01_North_VillageCenter",   Pos = Vector3.new(-10,  0, 510),  Label = "[1] North (Village)" },
    { Name = "Node_02_NorthEast_VillageEdge",  Pos = Vector3.new(160,  0, 500),  Label = "[2] North-East Edge" },
    { Name = "Node_03_NorthEast_Slope",        Pos = Vector3.new(310,  0, 410),  Label = "[3] North-East Ridge" },
    { Name = "Node_04_East_GasStationNorth",   Pos = Vector3.new(425,  0, 310),  Label = "[4] East (Gas Station N)" },
    { Name = "Node_05_East_GasStationCenter",  Pos = Vector3.new(435,  0, 170),  Label = "[5] East (Gas Station)" },
    { Name = "Node_06_East_GasStationSouth",   Pos = Vector3.new(430,  0,  30),  Label = "[6] East (Gas Station S)" },
    { Name = "Node_07_SouthEast_LakeRim",      Pos = Vector3.new(400,  0, -120), Label = "[7] South-East (Lake Rim)" },
    { Name = "Node_08_SouthEast_LakeBack",     Pos = Vector3.new(310,  0, -260), Label = "[8] South-East (Lake Back)" },
    { Name = "Node_09_South_CampEast",         Pos = Vector3.new(160,  0, -410), Label = "[9] South (Camp East)" },
    { Name = "Node_10_South_CampCenter",       Pos = Vector3.new(  0,  0, -460), Label = "[10] South (Camp)" },
    { Name = "Node_11_South_CampWest",         Pos = Vector3.new(-160, 0, -435), Label = "[11] South (Camp West)" },
    { Name = "Node_12_SouthWest_Slope",        Pos = Vector3.new(-310, 0, -310), Label = "[12] South-West Ridge" },
    { Name = "Node_13_West_TraderSouth",       Pos = Vector3.new(-415, 0, -100), Label = "[13] West (Trader S)" },
    { Name = "Node_14_West_TraderCenter",      Pos = Vector3.new(-430, 0, 130),  Label = "[14] West (Trader Silas)" },
    { Name = "Node_15_West_TraderNorth",       Pos = Vector3.new(-400, 0, 310),  Label = "[15] West (Trader N)" },
    { Name = "Node_16_NorthWest_Slope",        Pos = Vector3.new(-260, 0, 450),  Label = "[16] North-West Ridge" },
}

-- Raycast down to find ground elevation
local function getGroundElevation(x: number, z: number): number
    local rayOrigin = Vector3.new(x, 300, z)
    local rayDir = Vector3.new(0, -450, 0)
    
    local rayParams = RaycastParams.new()
    rayParams.FilterType = Enum.RaycastFilterType.Include
    rayParams.FilterDescendantsInstances = { Workspace.Terrain }
    
    local hit = Workspace:Raycast(rayOrigin, rayDir, rayParams)
    if hit then
        return hit.Position.Y
    end
    return 10.0
end

-- Get all node parts sorted by name
local function getSortedNodes(nodesFolder: Folder): { Part }
    local list: { Part } = {}
    for _, c in ipairs(nodesFolder:GetChildren()) do
        if c:IsA("Part") then
            table.insert(list, c)
        end
    end
    table.sort(list, function(a, b)
        return a.Name < b.Name
    end)
    return list
end

-- Build or Rebuild the World Barrier from Nodes
function WorldBarrierSystem.Build(customCfg: any?): Model
    local cfg = customCfg or {}
    local wallHeight = cfg.WallHeight or 160.0
    local wallThickness = cfg.WallThickness or 6.0
    local guideColor = cfg.GuideColor or Color3.fromRGB(190, 45, 255) -- Vivid Electric Purple
    local showGuide = (cfg.ShowAerialGuide ~= nil) and cfg.ShowAerialGuide or true
    
    local existing = Workspace:FindFirstChild("WorldBarrier")
    if existing and existing:IsA("Model") then
        existing:Destroy()
    end
    
    local barrierModel = Instance.new("Model")
    barrierModel.Name = "WorldBarrier"
    barrierModel:SetAttribute("WallHeight", wallHeight)
    barrierModel:SetAttribute("WallThickness", wallThickness)
    barrierModel:SetAttribute("ShowAerialGuide", showGuide)
    barrierModel:SetAttribute("GuideColor", guideColor)
    
    local nodesFolder = Instance.new("Folder")
    nodesFolder.Name = "Nodes"
    nodesFolder.Parent = barrierModel
    
    local wallsFolder = Instance.new("Folder")
    wallsFolder.Name = "CollisionWalls"
    wallsFolder.Parent = barrierModel
    
    local rubberBandFolder = Instance.new("Folder")
    rubberBandFolder.Name = "AerialRubberBand"
    rubberBandFolder.Parent = barrierModel
    
    -- 1. Create the Draggable Node Parts
    for i, info in ipairs(DEFAULT_NODES) do
        local gy = getGroundElevation(info.Pos.X, info.Pos.Z)
        local floatY = gy + 22.0 -- Elevated so it sits above tree canopies for aerial dragging
        
        local nodePart = Instance.new("Part")
        nodePart.Name = string.format("Node_%02d", i)
        nodePart.Shape = Enum.PartType.Ball
        nodePart.Size = Vector3.new(14, 14, 14)
        nodePart.Material = Enum.Material.Neon
        nodePart.Color = Color3.fromRGB(255, 230, 40) -- Bright Gold Handle
        nodePart.Anchored = true
        nodePart.CanCollide = false
        nodePart.CanTouch = false
        nodePart.CanQuery = true -- Selectable in Studio!
        nodePart.CastShadow = false
        nodePart.Position = Vector3.new(info.Pos.X, floatY, info.Pos.Z)
        
        -- Ground Anchor Line (Visual tether down to ground)
        local tether = Instance.new("Part")
        tether.Name = "GroundTether"
        tether.Size = Vector3.new(1.2, floatY - gy, 1.2)
        tether.Position = Vector3.new(info.Pos.X, (floatY + gy) * 0.5, info.Pos.Z)
        tether.Anchored = true
        tether.CanCollide = false
        tether.CanTouch = false
        tether.CanQuery = false
        tether.Color = Color3.fromRGB(255, 230, 40)
        tether.Material = Enum.Material.Neon
        tether.Transparency = 0.5
        tether.Parent = nodePart
        
        -- Aerial Billboard label
        local bb = Instance.new("BillboardGui")
        bb.Name = "AerialLabel"
        bb.Size = UDim2.new(0, 160, 0, 32)
        bb.StudsOffset = Vector3.new(0, 10, 0)
        bb.AlwaysOnTop = true
        bb.MaxDistance = 4500
        
        local txt = Instance.new("TextLabel")
        txt.Size = UDim2.new(1, 0, 1, 0)
        txt.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
        txt.BackgroundTransparency = 0.20
        txt.TextColor3 = Color3.fromRGB(255, 255, 255)
        txt.Font = Enum.Font.GothamBold
        txt.TextSize = 13
        txt.Text = info.Label
        txt.Parent = bb
        
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 6)
        corner.Parent = txt
        
        local stroke = Instance.new("UIStroke")
        stroke.Color = guideColor
        stroke.Thickness = 2
        stroke.Parent = txt
        
        bb.Parent = nodePart
        
        -- Attachment for elastic rubber band Beam
        local att = Instance.new("Attachment")
        att.Name = "BandAttachment"
        att.Parent = nodePart
        
        nodePart.Parent = nodesFolder
    end
    
    barrierModel.Parent = Workspace
    
    -- Build walls and rubber band between nodes
    WorldBarrierSystem.UpdateFromNodes(barrierModel)
    
    -- Attribute change listener
    barrierModel.AttributeChanged:Connect(function(attr: string)
        if attr == "WallHeight" or attr == "WallThickness" or attr == "GuideColor" then
            WorldBarrierSystem.UpdateFromNodes(barrierModel)
        elseif attr == "ShowAerialGuide" then
            local show = barrierModel:GetAttribute("ShowAerialGuide") == true
            for _, b in ipairs(rubberBandFolder:GetChildren()) do
                if b:IsA("BasePart") then b.Transparency = show and 0.05 or 1.0 end
            end
            for _, n in ipairs(nodesFolder:GetChildren()) do
                if n:IsA("BasePart") then
                    n.Transparency = show and 0.0 or 1.0
                    local bb = n:FindFirstChild("AerialLabel") :: BillboardGui?
                    if bb then bb.Enabled = show end
                end
            end
        end
    end)
    
    print("[WorldBarrierSystem] Built elastic 16-node barrier model in Workspace.WorldBarrier!")
    return barrierModel
end

-- Update collision walls & elastic rubber band segments to match current node positions
function WorldBarrierSystem.UpdateFromNodes(model: Model)
    local nodesFolder = model:FindFirstChild("Nodes")
    local wallsFolder = model:FindFirstChild("CollisionWalls")
    local rubberBandFolder = model:FindFirstChild("AerialRubberBand")
    
    if not nodesFolder or not wallsFolder or not rubberBandFolder then return end
    
    local nodes = getSortedNodes(nodesFolder)
    if #nodes < 3 then
        warn("[WorldBarrierSystem] Need at least 3 nodes to form a barrier!")
        return
    end
    
    local wallHeight = model:GetAttribute("WallHeight") or 160.0
    local wallThickness = model:GetAttribute("WallThickness") or 6.0
    local guideColor = model:GetAttribute("GuideColor") or Color3.fromRGB(190, 45, 255)
    local showGuide = (model:GetAttribute("ShowAerialGuide") ~= false)
    
    -- Clean previous generated wall and band parts
    wallsFolder:ClearAllChildren()
    rubberBandFolder:ClearAllChildren()
    
    for i = 1, #nodes do
        local n1 = nodes[i]
        local nextIdx = (i % #nodes) + 1
        local n2 = nodes[nextIdx]
        
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
        local segLength = math.sqrt(dx * dx + dz * dz) + 2.0 -- 2-stud overlap to guarantee airtight seal
        
        local forward = Vector3.new(dx, 0, dz).Unit
        local up = Vector3.new(0, 1, 0)
        local right = up:Cross(forward).Unit
        
        -- 1. Collision Wall Part (Airtight invisible wall)
        local wallPart = Instance.new("Part")
        wallPart.Name = string.format("Wall_%s_to_%s", n1.Name, n2.Name)
        wallPart.Size = Vector3.new(segLength, wallHeight, wallThickness)
        wallPart.Anchored = true
        wallPart.CanCollide = true
        wallPart.CanTouch = true
        wallPart.CanQuery = false
        wallPart.CastShadow = false
        wallPart.Transparency = 1.0 -- Invisible in-game
        wallPart.CFrame = CFrame.fromMatrix(Vector3.new(midX, midY, midZ), forward, up, -right)
        CollectionService:AddTag(wallPart, "WorldBarrierWall")
        wallPart.Parent = wallsFolder
        
        -- 2. Rubber Band Segment (Glowing aerial neon band)
        local bandY = (p1.Y + p2.Y) * 0.5
        local bandPart = Instance.new("Part")
        bandPart.Name = string.format("Band_%s_to_%s", n1.Name, n2.Name)
        bandPart.Size = Vector3.new(segLength, 6.0, 6.0)
        bandPart.Material = Enum.Material.Neon
        bandPart.Color = guideColor
        bandPart.Anchored = true
        bandPart.CanCollide = false
        bandPart.CanTouch = false
        bandPart.CanQuery = false
        bandPart.CastShadow = false
        bandPart.Transparency = showGuide and 0.05 or 1.0
        bandPart.CFrame = CFrame.fromMatrix(Vector3.new(midX, bandY, midZ), forward, up, -right)
        bandPart.Parent = rubberBandFolder
        
        -- 3. Live Elastic Beam Connector (Stretches dynamically in Studio!)
        local att1 = n1:FindFirstChild("BandAttachment") :: Attachment?
        local att2 = n2:FindFirstChild("BandAttachment") :: Attachment?
        if att1 and att2 then
            local beam = Instance.new("Beam")
            beam.Name = string.format("Beam_%s_to_%s", n1.Name, n2.Name)
            beam.Attachment0 = att1
            beam.Attachment1 = att2
            beam.Width0 = 8.0
            beam.Width1 = 8.0
            beam.Color = ColorSequence.new(guideColor)
            beam.FaceCamera = true
            beam.LightEmission = 1.0
            beam.LightInfluence = 0.0
            beam.Transparency = NumberSequence.new(showGuide and 0.1 or 1.0)
            beam.Parent = rubberBandFolder
        end
    end
end

-- ---------------------------------------------------------------------------
-- Manual Click-To-Draw Helper Functions
-- ---------------------------------------------------------------------------
function WorldBarrierSystem.AddPoint(worldPos: Vector3): Part
    local barrier = Workspace:FindFirstChild("WorldBarrier")
    if not barrier then
        barrier = WorldBarrierSystem.Build()
    end
    local nodesFolder = barrier:FindFirstChild("Nodes")
    if not nodesFolder then
        nodesFolder = Instance.new("Folder")
        nodesFolder.Name = "Nodes"
        nodesFolder.Parent = barrier
    end
    
    local existingNodes = nodesFolder:GetChildren()
    local idx = #existingNodes + 1
    local gy = getGroundElevation(worldPos.X, worldPos.Z)
    local floatY = gy + 22.0
    
    local node = Instance.new("Part")
    node.Name = string.format("Node_%02d", idx)
    node.Shape = Enum.PartType.Ball
    node.Size = Vector3.new(14, 14, 14)
    node.Material = Enum.Material.Neon
    node.Color = Color3.fromRGB(255, 230, 40)
    node.Anchored = true
    node.CanCollide = false
    node.CanTouch = false
    node.CanQuery = true
    node.CastShadow = false
    node.Position = Vector3.new(worldPos.X, floatY, worldPos.Z)
    
    local tether = Instance.new("Part")
    tether.Name = "GroundTether"
    tether.Size = Vector3.new(1.2, floatY - gy, 1.2)
    tether.Position = Vector3.new(worldPos.X, (floatY + gy) * 0.5, worldPos.Z)
    tether.Anchored = true
    tether.CanCollide = false
    tether.CanTouch = false
    tether.CanQuery = false
    tether.Color = Color3.fromRGB(255, 230, 40)
    tether.Material = Enum.Material.Neon
    tether.Transparency = 0.5
    tether.Parent = node
    
    local bb = Instance.new("BillboardGui")
    bb.Name = "AerialLabel"
    bb.Size = UDim2.new(0, 80, 0, 28)
    bb.StudsOffset = Vector3.new(0, 8, 0)
    bb.AlwaysOnTop = true
    bb.MaxDistance = 4500
    
    local txt = Instance.new("TextLabel")
    txt.Size = UDim2.new(1, 0, 1, 0)
    txt.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
    txt.BackgroundTransparency = 0.2
    txt.TextColor3 = Color3.fromRGB(255, 255, 255)
    txt.Font = Enum.Font.GothamBold
    txt.TextSize = 13
    txt.Text = string.format("[%d]", idx)
    txt.Parent = bb
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = txt
    bb.Parent = node
    
    local att = Instance.new("Attachment")
    att.Name = "BandAttachment"
    att.Parent = node
    
    node.Parent = nodesFolder
    WorldBarrierSystem.UpdateFromNodes(barrier)
    return node
end

function WorldBarrierSystem.UndoPoint(): boolean
    local barrier = Workspace:FindFirstChild("WorldBarrier")
    if not barrier then return false end
    local nodesFolder = barrier:FindFirstChild("Nodes")
    if not nodesFolder then return false end
    local nodes = getSortedNodes(nodesFolder)
    if #nodes == 0 then return false end
    local lastNode = nodes[#nodes]
    lastNode:Destroy()
    WorldBarrierSystem.UpdateFromNodes(barrier)
    return true
end

function WorldBarrierSystem.ClearAll()
    local barrier = Workspace:FindFirstChild("WorldBarrier")
    if barrier then
        barrier:Destroy()
    end
end

return WorldBarrierSystem

