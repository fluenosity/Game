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
-- Apply lighting & atmosphere safely on startup
pcall(function()
    AtmosphereSetup.Apply()
end)

-- Initialize interactive campfire & 4 sitting trunks at camp center
pcall(function()
    local campfireScript = envModuleFolder:WaitForChild("CampfireSystem")
    local CampfireSystem = require(campfireScript)
    CampfireSystem.Initialize()
end)

-- ONLY generate at runtime if explicitly requested by config (disabled by default so world is permanent)
if EnvironmentConfig.AUTO_GENERATE_ON_SERVER_START then
    local EnvironmentGenerator = require(envModuleFolder:WaitForChild("EnvironmentGenerator"))
    task.spawn(function()
        task.wait(0.5)
        EnvironmentGenerator.Generate()
    end)
end
