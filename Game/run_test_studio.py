import subprocess

with open("src/server/Environment/CampfireSystem.lua", "r", encoding="utf-8") as f:
    campfire_src = f.read()

mock_header = """
Vector3 = {
    new = function(x, y, z)
        return { X = x or 0, Y = y or 0, Z = z or 0 }
    end
}
Vector2 = {
    new = function(x, y)
        return { X = x or 0, Y = y or 0 }
    end
}
CFrame = {
    new = function(x, y, z)
        local t = { X = 0, Y = 0, Z = 0 }
        if type(x) == "table" then
            t = { X = x.X or 0, Y = x.Y or 0, Z = x.Z or 0 }
        elseif type(x) == "number" then
            t = { X = x, Y = y or 0, Z = z or 0 }
        end
        t.Position = Vector3.new(t.X, t.Y, t.Z)
        t.__mul = function(a, b) return CFrame.new(a.X + (b.X or 0), a.Y + (b.Y or 0), a.Z + (b.Z or 0)) end
        setmetatable(t, t)
        return t
    end,
    Angles = function(rx, ry, rz)
        local t = { X = 0, Y = 0, Z = 0 }
        t.__mul = function(a, b) return CFrame.new(0, 0, 0) end
        setmetatable(t, t)
        return t
    end,
    lookAt = function(at, look)
        return CFrame.new(at)
    end,
}
Color3 = {
    fromRGB = function(r, g, b) return { R = r, G = g, B = b } end
}
UDim = { new = function(s, o) return { Scale = s, Offset = o } end }
UDim2 = {
    new = function(sx, ox, sy, oy) return { X = { Scale = sx, Offset = ox }, Y = { Scale = sy, Offset = oy } } end,
    fromScale = function(sx, sy) return UDim2.new(sx, 0, sy, 0) end,
    fromOffset = function(ox, oy) return UDim2.new(0, ox, 0, oy) end,
}
NumberRange = { new = function(...) return {} end }
NumberSequence = { new = function(...) return {} end }
NumberSequenceKeypoint = { new = function(...) return {} end }
ColorSequence = { new = function(...) return {} end }
ColorSequenceKeypoint = { new = function(...) return {} end }
RaycastParams = {
    new = function()
        return { FilterType = 0, FilterDescendantsInstances = {} }
    end
}
Enum = {
    PartType = { Cylinder = 1, Ball = 2, Block = 0 },
    Material = { Slate = 1, Mud = 2, Wood = 3, WoodPlanks = 4, Granite = 5, Neon = 6, SmoothPlastic = 7 },
    SurfaceType = { Smooth = 0 },
    KeyCode = { E = 1, F = 2, ButtonX = 3, ButtonY = 4 },
    RaycastFilterType = { Include = 0, Exclude = 1 },
    RollOffMode = { InverseTapered = 1 },
    MeshType = { Sphere = 1, Brick = 2 },
}

local runService = {
    IsRunning = function() return false end,
    Heartbeat = { Connect = function() return { Disconnect = function() end } end },
}

local function createMockInstance(className)
    local obj = {
        ClassName = className,
        Name = className,
        Parent = nil,
        Children = {},
        Attributes = {},
        Position = Vector3.new(0, 0, 0),
        Size = Vector3.new(1, 1, 1),
        CFrame = CFrame.new(0, 0, 0),
        Disabled = false,
        CanTouch = true,
        Occupant = nil,
        Enabled = true,
    }
    
    function obj:GetChildren()
        return obj.Children
    end
    
    function obj:GetDescendants()
        local list = {}
        local function recurse(p)
            for _, c in ipairs(p.Children) do
                table.insert(list, c)
                recurse(c)
            end
        end
        recurse(obj)
        return list
    end
    
    function obj:FindFirstChild(name, recursive)
        for _, c in ipairs(obj.Children) do
            if c.Name == name then return c end
        end
        if recursive then
            for _, c in ipairs(obj:GetDescendants()) do
                if c.Name == name then return c end
            end
        end
        return nil
    end

    function obj:FindFirstChildOfClass(cls)
        for _, c in ipairs(obj.Children) do
            if c.ClassName == cls then return c end
        end
        return nil
    end

    function obj:FindFirstChildWhichIsA(cls, recursive)
        return obj:FindFirstChild(cls, recursive)
    end

    function obj:IsA(cls)
        return obj.ClassName == cls
    end

    function obj:IsDescendantOf(ancestor)
        local cur = obj.Parent
        while cur do
            if cur == ancestor then return true end
            cur = cur.Parent
        end
        return false
    end

    function obj:Destroy()
        if obj.Parent then
            for i, c in ipairs(obj.Parent.Children) do
                if c == obj then
                    table.remove(obj.Parent.Children, i)
                    break
                end
            end
            obj.Parent = nil
        end
    end

    function obj:SetAttribute(name, val)
        obj.Attributes[name] = val
    end

    function obj:GetAttribute(name)
        return obj.Attributes[name]
    end

    function obj:GetAttributeChangedSignal(name)
        return { Connect = function() return { Disconnect = function() end } end }
    end

    function obj:GetPropertyChangedSignal(name)
        return { Connect = function() return { Disconnect = function() end } end }
    end

    obj.Triggered = { Connect = function() return { Disconnect = function() end } end }

    setmetatable(obj, {
        __newindex = function(t, k, v)
            if k == "Parent" then
                if v and v.Children then
                    table.insert(v.Children, obj)
                end
            end
            rawset(t, k, v)
        end
    })

    return obj
end

local workspaceObj = createMockInstance("Workspace")
local terrainObj = createMockInstance("Terrain")
terrainObj.Parent = workspaceObj

local collectionService = {
    AddTag = function() end,
    HasTag = function() return false end,
    GetTagged = function() return {} end,
}

local serverScriptService = createMockInstance("ServerScriptService")
local replicatedStorage = createMockInstance("ReplicatedStorage")

game = {
    GetService = function(self, name)
        if name == "Workspace" then return workspaceObj end
        if name == "RunService" then return runService end
        if name == "CollectionService" then return collectionService end
        if name == "ServerScriptService" then return serverScriptService end
        if name == "ReplicatedStorage" then return replicatedStorage end
        return createMockInstance(name)
    end
}
Workspace = workspaceObj
workspace = workspaceObj

Instance = {
    new = function(className)
        return createMockInstance(className)
    end
}

function workspaceObj:Raycast(origin, dir, params)
    return { Position = Vector3.new(origin.X, 10.5, origin.Z) }
end

require = function(mod)
    return {}
end
"""

full_code = mock_header + "\n" + campfire_src + "\n" + """
print("MODULE CODE EVALUATING...")
local mod = CampfireSystem
local camp, seats, wood = mod.Initialize()
print("INITIALIZE SUCCESS!")
print("- Campfire:", tostring(camp.Name))
print("- Seats Folder:", tostring(seats.Name), "# seats children:", #seats.Children)
print("- Wood Stack:", tostring(wood.Name), "# wood children:", #wood.Children)
print("TOTAL WORKSPACE CHILDREN:", #workspaceObj.Children)
for _, c in ipairs(workspaceObj.Children) do
    print("  * " .. c.Name)
end
"""

with open("test_mock_studio.lua", "w", encoding="utf-8") as f:
    f.write(full_code)

res = subprocess.run(["luau", "test_mock_studio.lua"], capture_output=True, text=True)
print("STDOUT:\n" + res.stdout)
if res.stderr:
    print("STDERR:\n" + res.stderr)
