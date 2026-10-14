--!strict
--[[
    PlayerLifecycle.server.lua
    Server-side player initialization and character spawning control for
    "Don't Let the Fire Die". Developed for Fluenosity Studio.
    
    Prevents automatic character spawning on join so that the client-side
    studio splash screen and main menu display first (Unity / Unreal game flow).
    Spawns the player character into the world once "PLAY" is clicked on the main menu.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Disable automatic character loading on join
Players.CharacterAutoLoads = false

-- Ensure the shared communication folder and spawn RemoteEvent exist
local sharedFolder = ReplicatedStorage:WaitForChild("FluenosityShared")
local GameConfig = require(sharedFolder:WaitForChild("GameConfig"))
local spawnEvent = sharedFolder:FindFirstChild("RequestSpawnCharacter")
if not spawnEvent then
    local newEvent = Instance.new("RemoteEvent")
    newEvent.Name = "RequestSpawnCharacter"
    newEvent.Parent = sharedFolder
    spawnEvent = newEvent
end

local ServerStorage = game:GetService("ServerStorage")

-- Track players that have clicked Play and entered active gameplay
local playersInSession: { [Player]: boolean } = {}

-- Spawns the character into the world on demand
local function spawnCharacterForPlayer(player: Player, selectedGender: string?)
    if not player or not player.Parent then return end
    playersInSession[player] = true

    local gender = selectedGender or player:GetAttribute("SelectedGender") or "Male"
    player:SetAttribute("SelectedGender", gender)
    player:SetAttribute("CurrentCharacterGender", gender)

    local characterPack = ServerStorage:FindFirstChild("RealismCharacterPack")
    local template = characterPack and characterPack:FindFirstChild(gender)

    if template then
        -- Clean up previous character if present
        if player.Character then
            player.Character:Destroy()
        end

        local character = template:Clone()
        character.Name = player.Name

        local spawnLocation = workspace:FindFirstChildOfClass("SpawnLocation")
        local spawnCFrame = spawnLocation and (spawnLocation.CFrame + Vector3.new(0, 4, 0)) or CFrame.new(0, 10, 0)
        character:PivotTo(spawnCFrame)

        character.Parent = workspace
        player.Character = character

        local hrp = character:FindFirstChild("HumanoidRootPart") :: BasePart?
        if hrp then
            pcall(function()
                hrp:SetNetworkOwner(player)
            end)
        end
    else
        player:LoadCharacter()
    end
end

-- Client requests character spawn when clicking "PLAY" in the main menu
(spawnEvent :: RemoteEvent).OnServerEvent:Connect(function(player: Player, selectedGender: string?)
    if not playersInSession[player] or player:GetAttribute("CurrentCharacterGender") ~= selectedGender then
        spawnCharacterForPlayer(player, selectedGender)
    end
end)

-- Setup respawning mechanics for active players who die during gameplay
local function onPlayerAdded(player: Player)
    player.CharacterAdded:Connect(function(character: Model)
        local humanoid = character:WaitForChild("Humanoid", 10) :: Humanoid?
        if humanoid then
            humanoid.Died:Connect(function()
                task.wait(Players.RespawnTime)
                -- Only auto-respawn if the player has entered gameplay
                if player.Parent and playersInSession[player] then
                    local savedGender = player:GetAttribute("SelectedGender") :: string?
                    spawnCharacterForPlayer(player, savedGender)
                end
            end)
        end
    end)

    -- Direct spawn if enabled in GameConfig (skips manual Play button click)
    if GameConfig.ShouldDirectSpawn() then
        task.defer(function()
            if player.Parent and not playersInSession[player] then
                spawnCharacterForPlayer(player)
            end
        end)
    end
end

local function onPlayerRemoving(player: Player)
    playersInSession[player] = nil
end

Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(onPlayerRemoving)

-- Handle any players already present (e.g. in Studio Play Solo test mode)
for _, existingPlayer in ipairs(Players:GetPlayers()) do
    onPlayerAdded(existingPlayer)
end

