--!strict
-- Server-owned survivor spawning and wardrobe application.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

Players.CharacterAutoLoads = false

local sharedFolder = ReplicatedStorage:WaitForChild("FluenosityShared")
local GameConfig = require(sharedFolder:WaitForChild("GameConfig"))
local WardrobeConfig = require(sharedFolder:WaitForChild("SurvivorWardrobeConfig"))
local WardrobeApplier = require(sharedFolder:WaitForChild("SurvivorWardrobeApplier"))
local roster = sharedFolder:WaitForChild("SurvivorRoster")

local spawnRequest = sharedFolder:FindFirstChild("RequestSpawnCharacter")
if spawnRequest and not spawnRequest:IsA("RemoteFunction") then
	spawnRequest:Destroy()
	spawnRequest = nil
end
if not spawnRequest then
	local remote = Instance.new("RemoteFunction")
	remote.Name = "RequestSpawnCharacter"
	remote.Parent = sharedFolder
	spawnRequest = remote
end

local playersInSession: { [Player]: boolean } = {}
local savedSelections: { [Player]: { [string]: string } } = {}
local lastSpawnRequest: { [Player]: number } = {}

local function spawnCharacterForPlayer(player: Player, requestedSelection: any): (boolean, string?)
	if not player.Parent then return false, "Player left before spawn" end

	local selection = WardrobeConfig.ValidateSelection(requestedSelection)
	if not selection then return false, "Invalid survivor or wardrobe selection" end
	local template = roster:FindFirstChild(selection.CharacterId)
	if not template or not template:IsA("Model") then
		return false, "Selected R15 survivor is missing from the roster"
	end
	local templateHumanoid = template:FindFirstChildOfClass("Humanoid")
	if not templateHumanoid or templateHumanoid.RigType ~= Enum.HumanoidRigType.R15 then
		return false, "Selected survivor is not a valid R15 character"
	end

	local character = template:Clone()
	character.Name = player.Name
	local applied, applyError = WardrobeApplier.Apply(character, selection, roster)
	if not applied then
		character:Destroy()
		return false, applyError
	end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local rootPart = character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not humanoid or not rootPart then
		character:Destroy()
		return false, "Selected R15 survivor is missing core rig parts"
	end

	local spawnLocation = workspace:FindFirstChildOfClass("SpawnLocation")
	local spawnCFrame = if spawnLocation then spawnLocation.CFrame + Vector3.new(0, 4, 0) else CFrame.new(0, 10, 0)
	character:PivotTo(spawnCFrame)

	local previousCharacter = player.Character
	character.Parent = workspace
	player.Character = character
	if previousCharacter and previousCharacter ~= character then
		previousCharacter:Destroy()
	end
	pcall(function()
		rootPart:SetNetworkOwner(player)
	end)

	local definition = WardrobeConfig.Characters[selection.CharacterId]
	humanoid.DisplayName = definition.DisplayName
	player:SetAttribute("SelectedGender", definition.Gender)
	player:SetAttribute("CurrentCharacterGender", definition.Gender)
	player:SetAttribute("SelectedCharacterId", selection.CharacterId)
	player:SetAttribute("CurrentCharacterId", selection.CharacterId)
	playersInSession[player] = true
	savedSelections[player] = selection
	return true, nil
end

local remoteFunction = spawnRequest :: RemoteFunction
remoteFunction.OnServerInvoke = function(player: Player, payload: any): (boolean, string?)
	local now = os.clock()
	local previousRequest = lastSpawnRequest[player]
	if previousRequest and now - previousRequest < 0.75 then
		return false, "Please wait before requesting another spawn"
	end
	lastSpawnRequest[player] = now
	if playersInSession[player] then
		return false, "Survivor selection is locked after entering the wilderness"
	end
	return spawnCharacterForPlayer(player, payload)
end

local function onPlayerAdded(player: Player)
	player.CharacterAdded:Connect(function(character: Model)
		local humanoid = character:WaitForChild("Humanoid", 10) :: Humanoid?
		if humanoid then
			humanoid.Died:Connect(function()
				task.wait(Players.RespawnTime)
				if player.Parent and playersInSession[player] then
					local selection = savedSelections[player] or WardrobeConfig.GetDefaultSelection("Leo")
					local ok, err = spawnCharacterForPlayer(player, selection)
					if not ok then warn("[PlayerLifecycle] Respawn failed: " .. tostring(err)) end
				end
			end)
		end
	end)

	if GameConfig.ShouldDirectSpawn() then
		task.defer(function()
			if player.Parent and not playersInSession[player] then
				local selection = WardrobeConfig.GetDefaultSelection("Leo")
				local ok, err = spawnCharacterForPlayer(player, selection)
				if not ok then warn("[PlayerLifecycle] Direct spawn failed: " .. tostring(err)) end
			end
		end)
	end
end

local function onPlayerRemoving(player: Player)
	playersInSession[player] = nil
	savedSelections[player] = nil
	lastSpawnRequest[player] = nil
end

Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(onPlayerRemoving)
for _, existingPlayer in ipairs(Players:GetPlayers()) do
	onPlayerAdded(existingPlayer)
end
