--!strict
--[[
    EnvironmentBootstrap.server.lua
    Master Server Orchestrator for "Don't Let the Fire Die" Realistic Forest.
    Developed for Fluenosity Studio.
]]

local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local sharedFolder = ReplicatedStorage:WaitForChild("FluenosityShared")
local EnvironmentConfig = require(sharedFolder:WaitForChild("EnvironmentConfig"))

local envModuleFolder = script.Parent:WaitForChild("Environment")
local AtmosphereSetup = require(envModuleFolder:WaitForChild("AtmosphereSetup"))

-- ---------------------------------------------------------------------------
-- SERVER STARTUP INITIALIZATION
-- ---------------------------------------------------------------------------
-- 1. Automatically ensure all world structures, houses, props, and furniture are Anchored
--    to prevent unanchored toolbox models (e.g. Trader House, cabins, sheds) from collapsing!
local function anchorWorldStructures()
    local Players = game:GetService("Players")
    for _, desc in ipairs(Workspace:GetDescendants()) do
        if desc:IsA("BasePart") and not desc:IsA("Terrain") then
            local model = desc:FindFirstAncestorOfClass("Model")
            local isCharacter = model and Players:GetPlayerFromCharacter(model)
            if not isCharacter then
                desc.Anchored = true
            end
        end
    end
end

pcall(anchorWorldStructures)

-- 2. Apply lighting & atmosphere safely on startup
pcall(function()
    AtmosphereSetup.Apply()
end)

-- Initialize interactive campfire & 4 sitting trunks at camp center
pcall(function()
    local campfireScript = envModuleFolder:WaitForChild("CampfireSystem")
    local CampfireSystem = require(campfireScript)
    CampfireSystem.Initialize()
end)

-- Procedural world generation is permanently disabled at runtime.
-- All environmental instances (Trees, Rocks, GroundCover, WorldBarrier, Cabins)
-- are saved directly in the place file for custom manual level design and editing.

