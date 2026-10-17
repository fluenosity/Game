--!strict
--[[
    AtmosphereSetup.lua
    Atmospheric Lighting, Horizon Depth Fog, and Post-Processing Engine.
    Developed for "Don't Let the Fire Die" (Fluenosity Studio).
    
    V2 Enhancements:
    - Lifted Ambient & OutdoorAmbient (Prevents tree canopies from becoming pitch black voids)
    - Volumetric Mountain Horizon Mist (Atmosphere Haze + Density naturally conceals world edges)
    - Low-contrast ColorCorrection (Preserves bark texture and foliage needle definition)
    - SunRays godbeams streaming through the conifer canopy
    - 100% resilient defaults to handle studio module cache transitions
]]

local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local sharedFolder = ReplicatedStorage:WaitForChild("FluenosityShared")
local EnvironmentConfig = require(sharedFolder:WaitForChild("EnvironmentConfig"))
local EnvironmentManager = require(sharedFolder:WaitForChild("Environment"):WaitForChild("EnvironmentManager"))
local TimeVisuals = require(sharedFolder:WaitForChild("TimeVisuals"))

local AtmosphereSetup = {}

function AtmosphereSetup.Apply()
    pcall(function()
        Lighting.Technology = Enum.Technology.Future
    end)

    -- 1. Initialize Master Environment Suite (Clouds, Volumetrics, Atmosphere, Celestial Sky)
    EnvironmentManager.Init()

    -- 2. Apply baseline visual truth (Day 0, Hour 14:00 - crystal clear matching Studio Editor)
    TimeVisuals.Apply(14.0, 0)
    
    -- 7. Controlled Campfire Warmth (Prevents multiple stacked lights and blinding over-illumination)
    pcall(function()
        local ws = game:GetService("Workspace")
        -- 1. Purge ALL existing CampfireGlow lights to prevent brightness stacking
        for _, obj in ipairs(ws:GetDescendants()) do
            if obj.Name == "CampfireGlow" and obj:IsA("PointLight") then
                obj:Destroy()
            end
        end
        
        -- 2. Find ONE primary fire part in the campsite
        local primaryFirePart: BasePart? = nil
        for _, obj in ipairs(ws:GetDescendants()) do
            if obj:IsA("Fire") and obj.Parent and obj.Parent:IsA("BasePart") then
                primaryFirePart = obj.Parent :: BasePart
                break
            end
        end
        if not primaryFirePart then
            for _, obj in ipairs(ws:GetDescendants()) do
                if obj:IsA("BasePart") and (obj.Name:lower() == "campfire" or obj.Name:lower() == "firepit") then
                    primaryFirePart = obj
                    break
                end
            end
        end
        
        -- 3. Create a single cozy, warm campfire light (not blinding!)
        if primaryFirePart then
            local light = Instance.new("PointLight")
            light.Name = "CampfireGlow"
            light.Color = Color3.fromRGB(255, 142, 42) -- Rich warm amber flame (Matching Reference Image 2)
            light.Range = 55.0                        -- Full campsite illumination
            light.Brightness = 3.5                    -- Warm radiant glow
            light.Shadows = true                      -- Real-time contact shadows on rocks & fence
            light.Parent = primaryFirePart
        end
    end)
    
    print("[AtmosphereSetup] Applied cozy campfire illumination, soft bloom, and balanced forest lighting.")
end

return AtmosphereSetup
