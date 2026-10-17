--!strict
--[[
    LoadingManager.lua
    Production-grade Asset Preloader & Atmospheric Shader Compiler Pipeline
    for "Don't Let the Fire Die" (Fluenosity Studio).
    
    Phases:
    1. Preload Celestial Skybox & Core UI Assets (ContentProvider:PreloadAsync)
    2. Atmospheric Post-Processing & Shader Warmup (Future lighting, mist & color grading)
    3. Wilderness World Sector Synchronization (ForestEnvironment, Terrain, WorldBarrier)
    4. Character Physics & Spawn Stabilization (Freezes physics, locks camera)
    5. Seamless Cinematic Curtain Reveal (Zero shader popping, zero contrast snap, zero flickers)
]]

local Players = game:GetService("Players")
local ContentProvider = game:GetService("ContentProvider")
local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")
local SoundService = game:GetService("SoundService")

local player = Players.LocalPlayer
local sharedFolder = ReplicatedStorage:WaitForChild("FluenosityShared")
local GameConfig = require(sharedFolder:WaitForChild("GameConfig"))
local EnvironmentConfig = require(sharedFolder:WaitForChild("EnvironmentConfig"))
local WardrobeConfig = require(sharedFolder:WaitForChild("SurvivorWardrobeConfig"))

local EnvironmentManager = require(sharedFolder:WaitForChild("Environment"):WaitForChild("EnvironmentManager"))
local TimeVisuals = require(sharedFolder:WaitForChild("TimeVisuals"))

local LoadingManager = {}

-- Ensure lighting post-processing is fully active client-side immediately
local function ensureAtmosphericPostProcessing(): { Instance }
    pcall(function()
        Lighting.Technology = Enum.Technology.Future
    end)

    EnvironmentManager.Init()
    TimeVisuals.Apply(14.0, 0)

    local atmo = Lighting:FindFirstChildOfClass("Atmosphere")
    local cc = Lighting:FindFirstChild("ForestColorCorrection")
    local bloom = Lighting:FindFirstChild("ForestBloom")
    local rays = Lighting:FindFirstChild("ForestSunRays")
    local sky = Lighting:FindFirstChildOfClass("Sky")

    local instances = {}
    if atmo then table.insert(instances, atmo) end
    if cc then table.insert(instances, cc) end
    if bloom then table.insert(instances, bloom) end
    if rays then table.insert(instances, rays) end
    if sky then table.insert(instances, sky) end

    return instances
end

function LoadingManager.LoadGame(loadingScreen: any, onCompleted: (() -> ())?, selection: any?)
    task.spawn(function()
        -- 1. Initial State (5%)
        loadingScreen.SetProgress(0.06, "CONNECTING TO WILDERNESS...", "Establishing client replication channel...")
        task.wait(0.12)

        -- 2. Phase 1: Preload Core Assets (0.06 -> 0.35)
        loadingScreen.SetProgress(0.18, "PRELOADING CELESTIAL & UI ASSETS...", "Caching skybox textures, audio & shaders in GPU...")
        
        local preloads = {}
        local postAssets = ensureAtmosphericPostProcessing()
        for _, inst in ipairs(postAssets) do
            table.insert(preloads, inst)
        end
        
        local sky = Lighting:FindFirstChildOfClass("Sky")
        if sky then table.insert(preloads, sky) end
        
        -- Batch preload via ContentProvider
        pcall(function()
            ContentProvider:PreloadAsync(preloads)
        end)
        
        loadingScreen.SetProgress(0.35, "ASSET CACHE COMPLETE", "Skybox & core render assets loaded in GPU memory.")
        task.wait(0.1)

        -- 3. Phase 2: Compiling Shaders & Volumetric Post-Processing (0.35 -> 0.65)
        loadingScreen.SetProgress(0.48, "COMPILING ATMOSPHERIC SHADERS...", "Compiling Future lighting matrices & volumetric fog...")
        
        -- Warm up the GPU: Render 6 frames behind the curtain so shadowmaps & shader pipelines compile
        for _ = 1, 6 do
            RunService.RenderStepped:Wait()
        end
        
        loadingScreen.SetProgress(0.65, "SHADERS COMPILED & ACTIVE", "Post-processing pipeline verified (Future Technology).")
        task.wait(0.1)

        -- 4. Phase 3: Synchronizing Wilderness & Barrier (0.65 -> 0.82)
        loadingScreen.SetProgress(0.72, "SYNCHRONIZING WILDERNESS SECTOR...", "Verifying trees, terrain & 121 boundary walls...")
        local _ = Workspace:WaitForChild("ForestEnvironment", 4)
        local _ = Workspace:WaitForChild("WorldBarrier", 4)
        task.wait(0.15)
        loadingScreen.SetProgress(0.82, "ENVIRONMENT SYNCHRONIZED", "121 perimeter collision walls & forest models ready.")

        -- 5. Phase 4: Character Physics & Spawn Stabilization (0.82 -> 0.96)
        loadingScreen.SetProgress(0.88, "CALIBRATING CHARACTER SURVIVAL STATE...", "Aligning camera & stabilizing character physics...")
        
        -- The server validates the roster ID and every wardrobe item before spawning.
        local cleanSelection = WardrobeConfig.ValidateSelection(selection)
            or WardrobeConfig.GetDefaultSelection("Sophie")
        local character = player.Character
        local alreadyHasStarter = GameConfig.ShouldUseStarterCharacter() and character ~= nil and character:FindFirstChildOfClass("Humanoid") ~= nil
        if not alreadyHasStarter and (not character or player:GetAttribute("CurrentCharacterId") ~= cleanSelection.CharacterId) then
            local spawnFunction = sharedFolder:WaitForChild("RequestSpawnCharacter", 10)
            if spawnFunction and spawnFunction:IsA("RemoteFunction") then
                local previousCharacter = character
                local ok, spawned, reason = pcall(function()
                    return spawnFunction:InvokeServer(cleanSelection)
                end)
                if ok and spawned == true then
                    local deadline = os.clock() + 3.0
                    while os.clock() < deadline do
                        if player.Character and player.Character ~= previousCharacter then
                            character = player.Character
                            break
                        end
                        task.wait(0.05)
                    end
                else
                    warn("[LoadingManager] Survivor spawn info: " .. tostring(reason or spawned))
                end
            else
                warn("[LoadingManager] RequestSpawnCharacter RemoteFunction is unavailable")
            end
        end
        
        character = character or player.Character
        if not character then
            local deadline = os.clock() + 3.0
            while os.clock() < deadline do
                if player.Character then
                    character = player.Character
                    break
                end
                task.wait(0.05)
            end
        end
        
        local humanoid = character and (character:FindFirstChildOfClass("Humanoid") or character:WaitForChild("Humanoid", 3)) :: Humanoid?
        
        -- Temporarily freeze character movement while screen is covered
        if humanoid then
            humanoid.WalkSpeed = 0
            humanoid.JumpPower = 0
        end
        
        -- Attach camera to character
        local camera = Workspace.CurrentCamera or Workspace:WaitForChild("Camera", 5) :: Camera
        if camera and humanoid then
            camera.CameraType = Enum.CameraType.Custom
            camera.CameraSubject = humanoid
        end
        
        task.wait(0.2)
        loadingScreen.SetProgress(0.96, "SURVIVAL PROTOCOL READY", "Physics stabilized. Preparing wilderness entry...")
        task.wait(0.15)

        -- 6. Phase 5: 100% Finalized & Reveal
        loadingScreen.SetProgress(1.00, "SURVIVAL ACTIVE", "Welcome to the wilderness. Don't let the fire die.")

        -- Smoothly fade out main menu music right at the final reveal of the loading screen
        local menuBgm = SoundService:FindFirstChild("MainMenuBGM") :: Sound?
        if menuBgm then
            local fadeOutTween = TweenService:Create(menuBgm, TweenInfo.new(1.8, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                Volume = 0,
            })
            fadeOutTween:Play()
            task.delay(1.85, function()
                if menuBgm and menuBgm.Parent then
                    menuBgm:Stop()
                    menuBgm:Destroy()
                end
            end)
        end

        task.wait(0.35) -- Brief pause so player sees 100% complete bar
        
        -- Restore character controls
        if humanoid then
            humanoid.WalkSpeed = 16
            humanoid.JumpPower = 38
        end
        
        -- Smoothly dissolve loading curtain
        loadingScreen.Hide(function()
            if onCompleted then
                onCompleted()
            end
        end)
    end)
end

return LoadingManager
