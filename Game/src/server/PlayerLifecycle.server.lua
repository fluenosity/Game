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
local spawnEvent = sharedFolder:FindFirstChild("RequestSpawnCharacter")
if not spawnEvent then
    local newEvent = Instance.new("RemoteEvent")
    newEvent.Name = "RequestSpawnCharacter"
    newEvent.Parent = sharedFolder
    spawnEvent = newEvent
end

-- Track players that have clicked Play and entered active gameplay
local playersInSession: { [Player]: boolean } = {}

-- Spawns the character into the world on demand
local function spawnCharacterForPlayer(player: Player)
    if not player or not player.Parent then return end
    playersInSession[player] = true
    player:LoadCharacter()
end

-- Client requests character spawn when clicking "PLAY" in the main menu
(spawnEvent :: RemoteEvent).OnServerEvent:Connect(function(player: Player)
    if not playersInSession[player] then
        spawnCharacterForPlayer(player)
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
                    player:LoadCharacter()
                end
            end)
        end
    end)
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
