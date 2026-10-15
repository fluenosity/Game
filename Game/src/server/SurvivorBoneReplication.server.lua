--!strict
--[[
    SurvivorBoneReplication.server.lua
    Server-side skeletal kinematic evaluator & secondary deformer synchronizer.

    Guarantees:
    - Eliminates all T-poses when viewing the game from the Server perspective in Roblox Studio.
    - Continuously synchronizes secondary deformer bones (e.g. mixamorig6 for Jody).
    - Applies calibrated posture and chest elaboration on all active survivor rigs.
    - Operates efficiently across all active player characters and NPC models in Workspace.
]]

local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local sharedFolder = ReplicatedStorage:WaitForChild("FluenosityShared")
local SurvivorBoneSync = require(sharedFolder:WaitForChild("SurvivorBoneSync"))

local function registerCharacter(char: Model)
    task.defer(function()
        if not char.Parent then return end
        -- Ensure character has hips or bone structure before registering
        local hasBones = char:FindFirstChild("mixamorig:Hips", true) ~= nil or char:FindFirstChild("mixamorig6:Hips", true) ~= nil
        if hasBones then
            SurvivorBoneSync.RegisterCharacter(char)
        end
    end)
end

local function onPlayerAdded(player: Player)
    if player.Character then
        registerCharacter(player.Character)
    end
    player.CharacterAdded:Connect(registerCharacter)
end

for _, player in ipairs(Players:GetPlayers()) do
    onPlayerAdded(player)
end
Players.PlayerAdded:Connect(onPlayerAdded)

-- Automatically track any non-player survivor models (e.g. CombatTestFemale, NPCs)
workspace.ChildAdded:Connect(function(child: Instance)
    if child:IsA("Model") then
        registerCharacter(child)
    end
end)

for _, child in ipairs(workspace:GetChildren()) do
    if child:IsA("Model") then
        registerCharacter(child)
    end
end

-- Server-side kinematic evaluation loop
RunService.PreSimulation:Connect(function()
    SurvivorBoneSync.StepAll()
end)
