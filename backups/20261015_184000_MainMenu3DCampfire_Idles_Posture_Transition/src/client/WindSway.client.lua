--!strict
--[[
    WindSway.client.lua
    Lightweight, organic mountain breeze tree-swaying engine for "Don't Let the Fire Die".
    Developed for Fluenosity Studio.
    
    Architecture:
    - Zero Physics / Zero Network Overhead: Runs 100% locally on the client.
    - Proximity LOD: Only updates trees within 150 studs of player camera (~15-25 trees).
    - Base Anchor Preservation: Pivots strictly around RootPivot at ground level (Y = 0),
      keeping trunk base planted on terrain while canopies and upper boughs sway organically.
]]

local RunService = game:GetService("RunService")
local CollectionService = game:GetService("CollectionService")
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")

local player = Players.LocalPlayer
local camera = Workspace.CurrentCamera or Workspace:WaitForChild("Camera")

type TreeData = {
    Model: Model,
    BaseCF: CFrame,
    Seed: number,
    IsActive: boolean,
}

local trackedTrees: { [Model]: TreeData } = {}
local MAX_SWAY_DIST_SQ = 150 * 150 -- 150 studs squared

local function registerTree(model: Model)
    if trackedTrees[model] then return end
    if not model:IsA("Model") then return end
    
    local primary = model.PrimaryPart or model:FindFirstChild("RootPivot") or model:FindFirstChildWhichIsA("BasePart")
    if not primary then return end
    
    local baseCF = model:GetPivot()
    local seed = model:GetAttribute("Seed") or math.random(1, 100000)
    
    trackedTrees[model] = {
        Model = model,
        BaseCF = baseCF,
        Seed = tonumber(seed) or 1337,
        IsActive = false,
    }
end

local function unregisterTree(model: Model)
    local data = trackedTrees[model]
    if data then
        pcall(function()
            data.Model:PivotTo(data.BaseCF)
        end)
        trackedTrees[model] = nil
    end
end

-- Listen for CollectionService tags
CollectionService:GetInstanceAddedSignal("WindSwayTree"):Connect(function(inst)
    if inst:IsA("Model") then
        registerTree(inst)
    end
end)

CollectionService:GetInstanceRemovedSignal("WindSwayTree"):Connect(function(inst)
    if inst:IsA("Model") then
        unregisterTree(inst)
    end
end)

-- Register existing tagged trees
for _, inst in ipairs(CollectionService:GetTagged("WindSwayTree")) do
    if inst:IsA("Model") then
        registerTree(inst)
    end
end

-- Fallback check for Workspace.ForestEnvironment.Trees
local function scanContainer()
    local container = Workspace:FindFirstChild("ForestEnvironment")
    if container then
        local treesFolder = container:FindFirstChild("Trees")
        if treesFolder then
            for _, child in ipairs(treesFolder:GetChildren()) do
                if child:IsA("Model") then
                    registerTree(child)
                end
            end
            treesFolder.ChildAdded:Connect(function(child)
                if child:IsA("Model") then
                    task.wait(0.1)
                    registerTree(child)
                end
            end)
        end
    end
end

task.spawn(scanContainer)
Workspace.ChildAdded:Connect(function(child)
    if child.Name == "ForestEnvironment" then
        task.wait(0.2)
        scanContainer()
    end
end)

-- Main Render/Heartbeat Sway Loop
local function updateWindSway()
    local camPos = if camera then camera.CFrame.Position else Vector3.zero
    local t = os.clock()
    
    for model, data in pairs(trackedTrees) do
        if not model.Parent then
            trackedTrees[model] = nil
            continue
        end
        
        local treePos = data.BaseCF.Position
        local distSq = (treePos.X - camPos.X) ^ 2 + (treePos.Z - camPos.Z) ^ 2
        
        if distSq <= MAX_SWAY_DIST_SQ then
            data.IsActive = true
            local seedOffset = data.Seed * 0.04
            
            -- Natural multi-harmonic mountain breeze math
            local swayX = (math.sin(t * 1.15 + seedOffset) * 0.014) + (math.sin(t * 2.3 + seedOffset * 1.5) * 0.005)
            local swayZ = (math.cos(t * 0.90 + seedOffset * 1.2) * 0.011) + (math.sin(t * 1.8 + seedOffset) * 0.004)
            
            model:PivotTo(data.BaseCF * CFrame.Angles(swayX, 0, swayZ))
        elseif data.IsActive then
            -- Smoothly reset to resting pivot when player walks away
            data.IsActive = false
            model:PivotTo(data.BaseCF)
        end
    end
end

RunService.Heartbeat:Connect(updateWindSway)
