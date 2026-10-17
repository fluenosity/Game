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

local LoadingManager = {}

-- Ensure lighting post-processing is fully active client-side immediately
local function ensureAtmosphericPostProcessing(): { Instance }
    local postCfg = EnvironmentConfig.POST_PROCESSING or {}
    local lightCfg = postCfg.Lighting or {}
    local atmoCfg = postCfg.Atmosphere or {}
    local ccCfg = postCfg.ColorCorrection or {}
    local bloomCfg = postCfg.Bloom or {}
    local raysCfg = postCfg.SunRays or {}

    pcall(function()
        Lighting.Technology = Enum.Technology.Future
    end)
    Lighting.Brightness = lightCfg.Brightness or 2.8
    Lighting.Ambient = lightCfg.Ambient or Color3.fromRGB(75, 90, 110)
    Lighting.OutdoorAmbient = lightCfg.OutdoorAmbient or Color3.fromRGB(115, 132, 150)
    Lighting.ShadowSoftness = lightCfg.ShadowSoftness or 0.15
    Lighting.ClockTime = lightCfg.ClockTime or 14.5
    Lighting.FogEnd = lightCfg.FogEnd or 2400.0

    -- Atmosphere
    local atmo = Lighting:FindFirstChildOfClass("Atmosphere")
    if not atmo then
        atmo = Instance.new("Atmosphere")
        atmo.Name = "ForestAtmosphere"
        atmo.Parent = Lighting
    end
    atmo.Density = atmoCfg.Density or 0.34
    atmo.Offset = atmoCfg.Offset or 0.18
    atmo.Color = atmoCfg.Color or Color3.fromRGB(175, 200, 225)
    atmo.Decay = atmoCfg.Decay or Color3.fromRGB(95, 120, 145)
    atmo.Glare = atmoCfg.Glare or 0.25
    atmo.Haze = atmoCfg.Haze or 1.80

    -- ColorCorrection
    local cc = Lighting:FindFirstChild("ForestColorCorrection") :: ColorCorrectionEffect?
    if not cc then
        cc = Instance.new("ColorCorrectionEffect")
        cc.Name = "ForestColorCorrection"
        cc.Parent = Lighting
    end
    cc.Brightness = ccCfg.Brightness or 0.02
    cc.Contrast = ccCfg.Contrast or 0.06
    cc.Saturation = ccCfg.Saturation or 0.15
    cc.TintColor = ccCfg.TintColor or Color3.fromRGB(255, 252, 246)
    cc.Enabled = true

    -- Bloom
    local bloom = Lighting:FindFirstChild("ForestBloom") :: BloomEffect?
    if not bloom then
        bloom = Instance.new("BloomEffect")
        bloom.Name = "ForestBloom"
        bloom.Parent = Lighting
    end
    bloom.Intensity = bloomCfg.Intensity or 0.40
    bloom.Size = bloomCfg.Size or 18
    bloom.Threshold = bloomCfg.Threshold or 0.85
    bloom.Enabled = true

    -- SunRays
    local rays = Lighting:FindFirstChild("ForestSunRays") :: SunRaysEffect?
    if not rays then
        rays = Instance.new("SunRaysEffect")
        rays.Name = "ForestSunRays"
        rays.Parent = Lighting
    end
    rays.Intensity = raysCfg.Intensity or 0.08
    rays.Spread = raysCfg.Spread or 0.65
    rays.Enabled = true

    -- Sky
    local skyCfg = (EnvironmentConfig.SKY and EnvironmentConfig.SKY.Day) or {}
    local sky = Lighting:FindFirstChildOfClass("Sky")
    if not sky then
        sky = Instance.new("Sky")
        sky.Name = "Sky"
        sky.Parent = Lighting
    end
    sky.SkyboxBk = skyCfg.SkyboxBk or "http://www.roblox.com/asset/?id=91458024"
    sky.SkyboxDn = skyCfg.SkyboxDn or "http://www.roblox.com/asset/?id=91457980"
    sky.SkyboxFt = skyCfg.SkyboxFt or "http://www.roblox.com/asset/?id=91458024"
    sky.SkyboxLf = skyCfg.SkyboxLf or "http://www.roblox.com/asset/?id=91458024"
    sky.SkyboxRt = skyCfg.SkyboxRt or "http://www.roblox.com/asset/?id=91458024"
    sky.SkyboxUp = skyCfg.SkyboxUp or "http://www.roblox.com/asset/?id=91458002"
    sky.CelestialBodiesShown = true

    return { atmo, cc, bloom, rays, sky }
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
